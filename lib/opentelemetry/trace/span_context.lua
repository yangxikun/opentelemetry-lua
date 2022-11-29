local tracestate = require("opentelemetry.trace.tracestate")
local _M = {
    INVALID_TRACE_ID = "00000000000000000000000000000000",
    INVALID_SPAN_ID = "0000000000000000"
}

local mt = {
    __index = _M
}

function _M.new(tid, sid, trace_flags, trace_state, remote)
    local self = {
        trace_id    = tid,
        span_id     = sid,
        trace_flags = trace_flags,
        trace_state = trace_state or tracestate.new({}),
        remote      = remote,
    }
    return setmetatable(self, mt)
end

function _M.is_valid(self)
    if self.trace_id == _M.INVALID_TRACE_ID or self.trace_id == nil then
        return false
    end

    if self.span_id == _M.INVALID_SPAN_ID or self.span_id == nil then
        return false
    end

    return true
end

function _M.is_remote(self)
    return self.remote
end

function _M.is_sampled(self)
    return bit.band(self.trace_flags, 1) == 1
end

function _M.plain(self)
    return {
        trace_id    = self.trace_id,
        span_id     = self.span_id,
        trace_flags = self.trace_flags,
        trace_state = self.trace_state,
        remote      = self.remote,
    }
end

return _M
