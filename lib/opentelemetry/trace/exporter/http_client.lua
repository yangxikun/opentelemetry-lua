local http = require("resty.http")
local zlib = require("zlib")
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

function _M.do_request(self, body, encode_gzip)
    self.httpc = self.httpc or http.new()

    encode_gzip = encode_gzip or false
    self.httpc:set_timeout(self.timeout * 1000)

    if encode_gzip then
        -- Compress (deflate) request body
        -- the compression should be set to Best Compression and window size
        -- should be set to 15+16, see reference below:
        -- https://github.com/brimworks/lua-zlib/issues/4#issuecomment-26383801
        self.headers["Content-Encoding"] = "gzip"
        local deflate_stream = zlib.deflate(zlib.BEST_COMPRESSION, 15+16)
        local compressed_body = deflate_stream(body, "finish")
        body = compressed_body
    end

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
