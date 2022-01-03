local http = require("resty.http")

local _M = {
}

local mt = {
    __index = _M
}

------------------------------------------------------------------
-- create a http client used by exporter.
--
-- @address             opentelemetry collector: host:port
-- @timeout             export request timeout
-- @return              http client
------------------------------------------------------------------
function _M.new(address, timeout)
    local self = {
        uri = "http://" .. address .. "/v1/traces",
        timeout = timeout,
    }
    return setmetatable(self, mt)
end

function _M.do_request(self, content_type, body)
    local httpc = http.new()
    httpc:set_timeout(self.timeout * 1000)

    local res, err = httpc:request_uri(self.uri, {
        method = "POST",
        headers = {
            ["Content-Type"] = content_type,
        },
        body = body,
    })

    if not res then
        ngx.log(ngx.ERR, "request failed: ", err)
        httpc:close()
        return
    end
    if res.status ~= 200  then
        ngx.log(ngx.ERR, "request failed: ", res.body)
        httpc:close()
        return
    end
    httpc:close()
end

return _M
