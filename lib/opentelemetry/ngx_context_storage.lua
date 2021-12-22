local _M = {}

function _M.get(key)
    return ngx.ctx[key]
end

function _M.set(key, val)
    ngx.ctx[key] = val
end

return _M