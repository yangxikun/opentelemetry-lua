local _M = {
}

local mt = {
    __index = _M
}

------------------------------------------------------------------
-- create a resource.
--
-- @decision    attribute1, attribute2, attribute3, ...
-- @return      resource
------------------------------------------------------------------
function _M.new(...)
    local self = {
        attrs = {...}
    }
    return setmetatable(self, mt)
end

function _M.attributes()
    return _M.attrs
end

return _M