local http = require("resty.http")
local otel_global = require("opentelemetry.global")

local _M = {
}

local mt = {
    __index = _M
}

--------------------------------------------------------------------------------
-- Create a http client used by exporter. Values default to settings in
-- opentelemetry.global.
--
-- @address             opentelemetry collector: host:port
-- @timeout             export request timeout second
-- @headers             export request headers
-- @return              http client
--------------------------------------------------------------------------------
function _M.new(address, timeout, headers)
    headers = headers or otel_global.settings.otel_exporter.otlp.headers
    headers["Content-Type"] = "application/x-protobuf"

    local self = {
        uri = address and "http://" .. address .. "/v1/traces" or
            otel_global.settings.otel_exporter.otlp.endpoint,
        timeout = timeout or otel_global.settings.otel_exporter.otlp.timeout,
        headers = headers,
    }
    return setmetatable(self, mt)
end

function _M.do_request(self, body)
    local httpc = http.new()
    httpc:set_timeout(self.timeout * 1000)

    local res, err = httpc:request_uri(self.uri, {
        method = "POST",
        headers = self.headers,
        body = body,
    })

    if not res then
        ngx.log(ngx.ERR, "request failed: ", err)
        httpc:close()
        return nil, err
    end

    if res.status ~= 200 then
        ngx.log(ngx.ERR, "request failed: ", res.body)
        httpc:close()
        return nil, "request failed: " .. res.status
    end

    return res, nil
end

return _M
