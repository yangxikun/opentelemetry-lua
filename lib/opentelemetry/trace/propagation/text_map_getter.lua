local _M = {
}

local mt = {
    __index = _M
}

function _M.new()
    return setmetatable({}, mt)
end

------------------------------------------------------------------
-- Add tracing information to nginx request as headers
--
-- @param carrier nginx request
-- @param key HTTP header to get
-- @return value of HTTP header
------------------------------------------------------------------
function _M.get(carrier, key)
    return carrier.get_headers[key]
end

return _M
