local _M = {
}

local mt = {
    __index = _M
}

function _M.new()
    return setmetatable({}, mt)
end

------------------------------------------------------------------
-- Add tracing information to nginx request as headers. Used when
-- proxying to another service.
--
-- @param carrier (should be ngx)
-- @param key HTTP header to set
-- @param val value of HTTP header
-- @return nil
------------------------------------------------------------------
function _M.set(carrier, name, val)
    carrier.req.set_header(name, val)
end

return _M
