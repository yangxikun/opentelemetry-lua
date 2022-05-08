local timer_at = ngx.timer.at
local now = ngx.now
local create_timer
local cjson = require("cjson.safe")

local _M = {
}

local mt = {
    __index = _M
}

local function process_batches(premature, self, batches)
    if premature then
        return
    end

    for _, batch in ipairs(batches) do
        self.exporter:export_spans(batch)
    end
end

local function process_batches_timer(self, batches)
    local hdl, err = timer_at(0, process_batches, self, batches)
    if not hdl then
        ngx.log(ngx.ERR, "failed to create timer: ", err)
    end
end

local function flush_batches_from_queue(premature, self)
    if premature then
        ngx.log(ngx.ERR, "exiting: ", "batch_to_process size:", #self.batch_to_process, ",queue size:", #self.queue)
        return
    end

    local delay

    -- batch timeout
    if now() - self.first_queue_t >= self.batch_timeout and #self.queue > 0 then
        table.insert(self.batch_to_process, self.queue)
        self.queue = {}
    end

    -- copy batch_to_process, avoid conflict with on_end
    local batch_to_process = self.batch_to_process
    self.batch_to_process = {}

    process_batches(nil, self, batch_to_process)

    -- check if we still have work to do
    if #self.batch_to_process > 0 then
        delay = 0
    elseif #self.queue > 0 then
        delay = self.inactive_timeout
    end

    if delay then
        create_timer(self, delay, flush_batches_from_queue)
        return
    end
    self.is_timer_running = false
end

function create_timer(self, delay, flush_func, ...)
    local hdl, err = timer_at(delay, flush_func, self, ...)
    if not hdl then
        ngx.log(ngx.ERR, "failed to create timer: ", err)
        return err
    end
    self.is_timer_running = true
end

local function add_span_to_queue(self, span)
    if #self.queue + #self.batch_to_process * self.max_export_batch_size >= self.max_queue_size then
        -- drop span
        if self.drop_on_queue_full then
            ngx.log(ngx.WARN, "queue is full, drop span: trace_id = ", span.ctx.trace_id, " span_id = ", span.ctx.span_id)
            return
        end

        -- export spans
        process_batches_timer(self, self.batch_to_process)
        self.batch_to_process = {}
    end

    table.insert(self.queue, span)
    if #self.queue == 1 then
        self.first_queue_t = now()
    end

    if #self.queue >= self.max_export_batch_size then
        table.insert(self.batch_to_process, self.queue)
        self.queue = {}
    end

    if not self.is_timer_running then
        create_timer(self, self.inactive_timeout, flush_batches_from_queue)
    end
end

local function force_flush_queue(self)
    if #self.queue > 0 then
        table.insert(self.batch_to_process, self.queue)
        self.queue = {}
    end

    if #self.batch_to_process == 0 then
        return
    end

    process_batches_timer(self, self.batch_to_process)
    self.batch_to_process = {}
end

local shared_dict_queue_key = "queue"
local shared_dict_queue_timer_counter_key = "timer_state"

local function incr_flush_shared_dict_queue_timer_counter(self)
    local queue = ngx.shared[self.shared_dict_queue]
    return queue:incr(shared_dict_queue_timer_counter_key, 1, 0)
end

local function decr_flush_shared_dict_queue_timer_counter(self)
    local queue = ngx.shared[self.shared_dict_queue]
    return queue:incr(shared_dict_queue_timer_counter_key, -1, 0)
end

local function get_flush_shared_dict_queue_timer_counter(self)
    local queue = ngx.shared[self.shared_dict_queue]
    return queue:get(shared_dict_queue_timer_counter_key) or 0
end

local function flush_from_shared_dict_queue(premature, self, flush_all)
    if premature then
        decr_flush_shared_dict_queue_timer_counter(self)
        return
    end

    local queue = ngx.shared[self.shared_dict_queue]
    local span_count = queue:llen(shared_dict_queue_key)
    local batch = {}
    local is_queue_empty = false
    local span
    while (span_count >= self.max_export_batch_size or flush_all) and not is_queue_empty do
        span = cjson.decode(queue:lpop(shared_dict_queue_key))
        if span ~= nil then
            batch[1 + #batch] = span
            if #batch >= self.max_export_batch_size then
                self.exporter:export_spans(batch)
                span_count = queue:llen(shared_dict_queue_key)
                batch = {}
            end
        else
            is_queue_empty = true
        end
    end

    if #batch > 0 then
        self.exporter:export_spans(batch)
    end

    local delay
    if queue:llen(shared_dict_queue_key) >= self.max_export_batch_size then
        delay = 0
        flush_all = false
    else
        delay = self.batch_timeout
        flush_all = true
    end

    create_timer(self, delay, flush_from_shared_dict_queue, flush_all)
end

local function force_flush_shared_dict_queue(self)
    flush_from_shared_dict_queue(false, self, true)
end


local function add_span_to_shared_dict_queue(self, span)
    local queue = ngx.shared[self.shared_dict_queue]
    if queue == nil then
        ngx.log(ngx.ERR, "fail to get shared dict queue: ", self.shared_dict_queue)
        return
    end
    local span_json, err = cjson.encode(span:plain())
    if err ~= nil then
        ngx.log(ngx.ERR, "fail to encode span: ", err)
        return
    end

    _, err = queue:rpush(shared_dict_queue_key, span_json)
    if err ~= nil then
        ngx.log(ngx.ERR, "fail to push span to shared dict queue: ", err)
        return
    end

    if get_flush_shared_dict_queue_timer_counter(self) <= 0 then
        if incr_flush_shared_dict_queue_timer_counter(self) == 1 then
            create_timer(self, self.inactive_timeout, flush_from_shared_dict_queue)
        else
            decr_flush_shared_dict_queue_timer_counter(self)
        end
    end
end

------------------------------------------------------------------
-- create a batch span processor.
--
-- @exporter            opentelemetry.trace.exporter.oltp
-- @opts                [optional]
--                          opts.drop_on_queue_full: if true, drop span when queue is full, otherwise force process batches, default true
--                          opts.max_queue_size: maximum queue size to buffer spans for delayed processing, default 2048
--                          opts.batch_timeout: maximum duration for constructing a batch, default 5s
--                          opts.inactive_timeout: timer interval for processing batches, default 2s
--                          opts.max_export_batch_size: maximum number of spans to process in a single batch, default 256
--                          opts.shared_dict_queue: the shared dict name where spans are stored, when the option is set drop_on_queue_full and max_queue_size are ignored
-- @return              processor
------------------------------------------------------------------
function _M.new(exporter, opts)
    if not opts then
        opts = {}
    end

    local drop_on_queue_full = true
    if opts.drop_on_queue_full ~= nil and not opts.drop_on_queue_full then
        drop_on_queue_full = false
    end

    local self = {
        exporter = exporter,
        drop_on_queue_full = drop_on_queue_full,
        max_queue_size = opts.max_queue_size or 2048,
        batch_timeout = opts.batch_timeout or 5,
        inactive_timeout = opts.inactive_timeout or 2,
        max_export_batch_size = opts.max_export_batch_size or 256,
        shared_dict_queue = opts.shared_dict_queue,
        queue = {},
        first_queue_t = 0,
        batch_to_process = {},
        is_timer_running = false,
        closed = false,
    }

    assert(self.batch_timeout > 0)
    assert(self.inactive_timeout > 0)
    assert(self.max_export_batch_size > 0)
    assert(self.max_queue_size > self.max_export_batch_size)

    return setmetatable(self, mt)
end

function _M.on_end(self, span)
    if not span.ctx:is_sampled() or self.closed then
        return
    end
    if self.shared_dict_queue == nil then
        add_span_to_queue(self, span)
    else
        add_span_to_shared_dict_queue(self, span)
    end
end

function _M.force_flush(self)
    if self.closed then
        return
    end
    if self.shared_dict_queue == nil then
        force_flush_queue(self)
    else
        force_flush_shared_dict_queue(self)
    end
end

function _M.shutdown(self)
    self:force_flush()
    self.closed = true
end

return _M