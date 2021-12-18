local _M = {
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
    return self.decision == 2
end

function _M.is_recording(self)
    return self.decision == 1 or self.decision == 2
end

return _M
