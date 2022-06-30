local _M = {
}

local mt = {
    __index = _M
}

function _M.new()
    return setmetatable({}, mt)
end

------------------------------------------------------------------
-- Extract tracing header from nginx request
--
-- @param carrier (should be ngx.req)
-- @param key HTTP header to get
-- @return value of HTTP header
------------------------------------------------------------------
function _M.get(carrier, key)
    return carrier.get_headers()[key]
end

return _M
