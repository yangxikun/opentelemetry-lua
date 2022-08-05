local _M = {
    drop = 0,
    record_only = 1,
    record_and_sample = 2
}

local mt = {
    __index = _M
}

------------------------------------------------------------------
-- create a sample result.
--
-- @decision    0: do nothing
--              1: recording
--              2: recording and sampling
-- @return      sample result
------------------------------------------------------------------
function _M.new(decision, trace_state)
    return setmetatable({decision = decision, trace_state = trace_state}, mt)
end

function _M.is_sampled(self)
    return self.decision == self.record_and_sample
end

function _M.is_recording(self)
    return self.decision == self.record_only or self.decision == self.record_and_sample
end

return _M
