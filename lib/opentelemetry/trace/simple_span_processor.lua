--------------------------------------------------------------------------------
-- The simple span processor immediately exports spans as they finish. It does
-- not batch spans or process the spans in a background thread (as the batch
-- span processor does via ngx.timer.at). It is intended to be used for
-- debugging.
--------------------------------------------------------------------------------

local _M = {
}

local mt = {
    __index = _M
}

--------------------------------------------------------------------------------
-- create a simple span processor.
--
-- @param exporter      an exporter that will be used to send span data to its
--                      destination.
-- @return              processor
--------------------------------------------------------------------------------
function _M.new(exporter)
    return setmetatable({
        exporter = exporter,
    }, mt)
end

function _M.on_end(self, span)
    if not span.ctx:is_sampled() or self.closed then
        return
    end

    self.exporter:export_spans({ span })
end

function _M.shutdown(self)
    self.closed = true
    self.exporter:shutdown()
end

return _M
