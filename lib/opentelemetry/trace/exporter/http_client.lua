local http = require("resty.http")
local net_url = require("net.url")

local _M = {
}

local mt = {
    __index = _M
}

local function build_uri(address)
    local parsed_address = net_url.parse(address)
    if parsed_address.scheme ~= "http" and parsed_address.scheme ~= "https" then
        return build_uri("http://" .. address)
    end
    if parsed_address.path == "" or parsed_address.path == "/" then
        parsed_address.path = "/v1/traces"
    end
    return tostring(parsed_address)
end

------------------------------------------------------------------
-- create a http client used by exporter.
--
-- @address             opentelemetry collector: host:port
-- @timeout             export request timeout second
-- @headers             export request headers
-- @return              http client
------------------------------------------------------------------
function _M.new(address, timeout, headers)
    headers = headers or {}
    headers["Content-Type"] = "application/x-protobuf"

    local self = {
        uri = build_uri(address),
        timeout = timeout,
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

    if res.status ~= 200  then
        ngx.log(ngx.ERR, "request failed: ", res.body)
        httpc:close()
        return nil, "request failed: " .. res.status
    end

    return res, nil
end

return _M
