local http = require("resty.http")
local zlib = require("zlib")
local otel_global = require("opentelemetry.global")
local exporter_request_compressed_payload_size = "otel.otlp_exporter.request_compressed_payload_size"
local exporter_request_uncompressed_payload_size = "otel.otlp_exporter.request_uncompressed_payload_size"

local _M = {
}

local mt = {
    __index = _M
}

------------------------------------------------------------------
-- create a http client used by exporter.
--
-- @address             opentelemetry collector: host:port
-- @timeout             export request timeout second
-- @headers             export request headers
-- @httpc               openresty http client instance
-- @use_gzip            flag to enable gzip compression on request body
-- @return              http client
------------------------------------------------------------------
function _M.new(address, timeout, headers, httpc)
    headers = headers or {}
    headers["Content-Type"] = "application/x-protobuf"

    local uri = address .. "/v1/traces"
    if address:find("http", 1, true) ~= 1 then
        uri = "http://" .. uri
    end

    local self = {
        uri = uri,
        timeout = timeout,
        headers = headers,
        httpc = httpc,
    }

    return setmetatable(self, mt)
end

function _M.do_request(self, body)
    self.httpc = self.httpc or http.new()
    self.httpc:set_timeout(self.timeout * 1000)

    local res, err = self.httpc:request_uri(self.uri, {
        method = "POST",
        headers = self.headers,
        body = body,
    })

    if not res then
        ngx.log(ngx.ERR, "request failed: ", err)
        self.httpc:close()
        return nil, err
    end

    if res.status ~= 200  then
        ngx.log(ngx.ERR, "request failed: ", res.body)
        self.httpc:close()
        return nil, "request failed: " .. res.status
    end

    return res, nil
end

return _M
