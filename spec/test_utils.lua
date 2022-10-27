local _M = {}

------------------------------------------------------------------
-- This is meant to mock out the ngx var, which responds to
-- ngx.req.get_headers()["headername"] and
-- ngx.req.set_headers("headername", "value")
-- See https://openresty-reference.readthedocs.io/en/latest/Lua_Nginx_API/#ngxheaderheader
------------------------------------------------------------------
function _M.new_carrier(headers_table)
    local r = {
        req = { headers = {} },
    }
    r.req.headers = headers_table
    r.req.get_headers = function() return r.req.headers end
    r.req.set_header = function(name, val) r.req.headers[name] = val end
    return r
end

return _M
