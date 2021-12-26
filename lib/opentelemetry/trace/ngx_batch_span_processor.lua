local timer_at = ngx.timer.at
local now = ngx.now
local create_timer

local _M = {
}

local mt = {
    __index = _M
}

local function table_clear(t)
    for i=1, #t do
        t[i] = nil
    end
end

local function flush_batches(premature, self)
    if premature then
        return
    end

    if now() - self.first_queue_t >= self.batch_timeout then
        table.insert(self.batch_to_process, self.queue)
        self.queue = {}
        self.is_timer_running = false
    end

    for _, batch in ipairs(self.batch_to_process) do
        self.exporter:export_spans(batch)
    end
    table_clear(self.batch_to_process)

    if self.is_timer_running then
        create_timer(self)
    end
end

function create_timer(self)
    local hdl, err = timer_at(self.inactive_timeout, flush_batches, self)
    if not hdl then
        ngx.log(ngx.ERR, "failed to create timer: ", err)
        return
    end
    self.is_timer_running = true
end

------------------------------------------------------------------
-- create a batch span processor.
--
-- @exporter            see exporter dir
-- @opts                [optional]
--                          opts.block_on_queue_full: blocks on_end() method if the queue is full
--                          opts.max_queue_size: maximum queue size to buffer spans for delayed processing
--                          opts.batch_timeout: maximum duration for constructing a batch
--                          opts.inactive_timeout: maximum duration for processing batches
--                          opts.max_export_batch_size: maximum number of spans to process in a single batch
-- @return              processor
------------------------------------------------------------------
function _M.new(exporter, opts)
    if not opts then
        opts = {}
    end

    local block_on_queue_full = true
    if opts.block_on_queue_full ~= nil and not opts.block_on_queue_full then
        block_on_queue_full = false
    end

    local self = {
        exporter = exporter,
        block_on_queue_full = block_on_queue_full,
        max_queue_size = opts.max_queue_size or 2048,
        batch_timeout = opts.batch_timeout or 5,
        inactive_timeout = opts.inactive_timeout or 2,
        max_export_batch_size = opts.max_export_batch_size or 256,
        queue = {},
        first_queue_t = 0,
        batch_to_process = {},
        is_timer_running = false,
    }
    return setmetatable(self, mt)
end

function _M.on_end(self, span)
    if not span.ctx:is_sampled() then
        return
    end

    if #self.queue + #self.batch_to_process * self.max_export_batch_size >= self.max_queue_size then
        if self.block_on_queue_full then
            -- force flush some spans
            if #self.queue == 0 then
                self.exporter:export_spans(self.batch_to_process[#self.batch_to_process])
                table.remove(self.batch_to_process)
            else
                self.exporter:export_spans(self.queue)
                table_clear(self.queue)
            end
            table.insert(self.queue, span)
        end
        -- drop span
        return
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
        create_timer(self)
    end
end

function _M.force_flush(self)
    if not self.exporter then
        return
    end

    for _, batch in ipairs(self.batch_to_process) do
        self.exporter:export_spans(batch)
    end
    table_clear(self.batch_to_process)
    self.exporter:export_spans(self.queue)
    table_clear(self.queue)
end

function _M.shutdown(self)
    self:force_flush()
    self.exporter = nil
end

return _M