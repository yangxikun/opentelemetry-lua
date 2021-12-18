local _M = {
}

local mt = {
    __index = _M
}

function _M.new(headers)
    return setmetatable({headers = headers}, mt)
end

function _M.set(self, name, val)
    self.headers:add(name, val)
end

function _M.get(self, name)
    return self.headers:get(name)
end

return _M
