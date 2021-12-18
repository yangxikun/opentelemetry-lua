local _M = {
}

local mt = {
    __index = _M
}

local invalid_trace_id = '00000000000000000000000000000000'
local invalid_span_id = '0000000000000000'

function _M.new(tid, sid, trace_flags, trace_state, remote)
    local self = {
        trace_id = tid,
        span_id  = sid,
        trace_flags = trace_flags,
        trace_state = trace_state,
        remote = remote,
    }
    return setmetatable(self, mt)
end

function _M.is_valid(self)
    local valid_trace_id = type(self.trace_id) == "string" and #self.trace_id == 32 and self.trace_id ~= invalid_trace_id
            and string.match(self.trace_id, "^[0-9a-f]{32}$")
    local valid_span_id = type(self.span_id) == "string" and #self.span_id == 16 and self.span_id ~= invalid_span_id
            and string.match(self.span_id, "^[0-9a-f]{16}$")

    return valid_trace_id and valid_span_id
end

function _M.is_remote(self)
    return self.remote
end

function _M.is_sampled(self)
    return bit.band(self.trace_flags, 1) == 1
end

return _M