--------------------------------------------------------------------------------
-- The noop propagator does nothing. It should be the default propagator for the
-- API
--------------------------------------------------------------------------------
local _M = {
}

local mt = {
    __index = _M,
}

function _M.new()
    return setmetatable({}, mt)
end

--------------------------------------------------------------------------------
-- noop injection
--
-- @param _context       context storage
-- @param _carrier       nginx request
-- @param _setter        setter for interacting with carrier
-- @return nil
--------------------------------------------------------------------------------
function _M:inject(_context, _carrier, _setter)
end

--------------------------------------------------------------------------------
-- noop extraction
--
-- @param context       context storage
-- @param _carrier       nginx request
-- @param _getter        getter for interacting with carrier
-- @return nil
--------------------------------------------------------------------------------
function _M:extract(context, _carrier, _getter)
    return context
end

return _M
