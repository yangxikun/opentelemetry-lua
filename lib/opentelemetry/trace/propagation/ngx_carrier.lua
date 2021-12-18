local get_headers = ngx.req.get_headers

local _M = {
}

local mt = {
    __index = _M
}

function _M.new()
    return setmetatable({headers = get_headers()}, mt)
end

function _M.set(self, name, val)
    ngx.req.set_header(name, val)
end

function _M.get(self, name)
    return self.headers[name]
end

return _M
