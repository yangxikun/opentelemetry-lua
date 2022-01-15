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

function _M.attributes(self)
    return self.attrs
end

function _M.merge(a, b)
    if a == nil then
        return b
    end

    local b_attr_keys = {}
    local new_attrs = {}
    for _, attr in ipairs(b.attrs) do
        table.insert(new_attrs, attr)
        b_attr_keys[attr.key] = true
    end
    for _, attr in ipairs(a.attrs) do
        if not b_attr_keys[attr.key] then
            table.insert(new_attrs, attr)
        end
    end

    return setmetatable({attrs = new_attrs}, mt)
end

return _M