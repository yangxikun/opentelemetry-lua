local _M = {
}

local mt = {
    __index = _M
}

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
    return self.trace_id and self.span_id
end

function _M.is_remote(self)
    return self.remote
end

function _M.is_sampled(self)
    return bit.band(self.trace_flags, 1) == 1
end

return _M