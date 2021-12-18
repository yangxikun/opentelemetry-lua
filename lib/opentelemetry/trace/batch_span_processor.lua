local _M = {
}

local mt = {
    __index = _M
}

local queue = {}

local function table_clear(t)
    for i=1, #t do
        t[i] = nil
    end
end

------------------------------------------------------------------
-- create a batch span processor.
--
-- @exporter            see exporter dir
-- @opts                [optional]
--                          opts.max_export_batch_size: maximum number of spans to process in a single batch
-- @return              processor
------------------------------------------------------------------
function _M.new(exporter, opts)
    local self = {
        exporter = exporter,
        max_export_batch_size = opts.max_export_batch_size or 256,
    }
    return setmetatable(self, mt)
end

function _M.on_end(self, span)
    if (not self.exporter) or (not span.ctx:is_sampled()) then
        return
    end

    table.insert(queue, span)
    if #queue >= self.max_export_batch_size then
        self.exporter:export_spans(queue)
        table_clear(queue)
    end
end

function _M.force_flush(self)
    if not self.exporter then
        return
    end

    self.exporter:export_spans(queue)
end

function _M.shutdown(self)
    if not self.exporter then
        return
    end

    self.exporter:export_spans(queue)
    self.exporter = nil
end

return _M