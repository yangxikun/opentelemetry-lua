local _M = {}

function _M.get(self, key)
    return ngx.ctx[key]
end

function _M.set(self, key, val)
    ngx.ctx[key] = val
end

return _M