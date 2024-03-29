--- This file was automatically generated by utils/generate_semantic_conventions.lua
-- See: https://github.com/open-telemetry/opentelemetry-specification/tree/main/specification/trace/semantic_conventions
--
-- module @semantic_conventions.trace.http
local attribute   = require("opentelemetry.attribute")

local _M = {
    -- HTTP request method.
    HTTP_METHOD = "http.method",
    -- [HTTP response status code](https://tools.ietf.org/html/rfc7231#section-6).
    HTTP_STATUS_CODE = "http.status_code",
    -- Kind of HTTP protocol used.
    HTTP_FLAVOR = "http.flavor",
    -- Value of the [HTTP User-Agent](https://www.rfc-editor.org/rfc/rfc9110.html#field.user-agent) header sent by the client.
    HTTP_USER_AGENT = "http.user_agent",
    -- The size of the request payload body in bytes. This is the number of bytes transferred excluding headers and is often, but not always, present as the [Content-Length](https://www.rfc-editor.org/rfc/rfc9110.html#field.content-length) header. For requests using transport encoding, this should be the compressed size.
    HTTP_REQUEST_CONTENT_LENGTH = "http.request_content_length",
    -- The size of the response payload body in bytes. This is the number of bytes transferred excluding headers and is often, but not always, present as the [Content-Length](https://www.rfc-editor.org/rfc/rfc9110.html#field.content-length) header. For requests using transport encoding, this should be the compressed size.
    HTTP_RESPONSE_CONTENT_LENGTH = "http.response_content_length",
    -- Full HTTP request URL in the form `scheme://host[:port]/path?query[#fragment]`. Usually the fragment is not transmitted over HTTP, but if it is known, it should be included nevertheless.
    HTTP_URL = "http.url",
    -- The ordinal number of request resending attempt (for any reason, including redirects).
    HTTP_RESEND_COUNT = "http.resend_count",
    -- The URI scheme identifying the used protocol.
    HTTP_SCHEME = "http.scheme",
    -- The full request target as passed in a HTTP request line or equivalent.
    HTTP_TARGET = "http.target",
    -- The matched route (path template in the format used by the respective server framework). See note below
    HTTP_ROUTE = "http.route",
    -- The IP address of the original client behind all proxies, if known (e.g. from [X-Forwarded-For](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For)).
    HTTP_CLIENT_IP = "http.client_ip",
    -- The opentelemetry attribute key prefix for HTTP request headers
    HTTP_REQUEST_HEADER = "http.request.header",
    -- The opentelemetry attribute key prefix for HTTP response headers
    HTTP_RESPONSE_HEADER = "http.response.header",
}

------------------------------------------------------------------
-- returns the contents of headers as OpenTelemetry attributes.
--
-- @headers     a table of HTTP request headers
-- @return      a table of attribute
------------------------------------------------------------------
function _M.request_header(headers)
    local attributes = {}
    for k, v in pairs(headers) do
        k = _M.HTTP_REQUEST_HEADER .. '.' .. k
        if type(v) == "table" then
            table.insert(attributes, attribute.string_array(k, v))
        else
            table.insert(attributes, attribute.string(k, v))
        end
    end
    return attributes
end

------------------------------------------------------------------
-- returns the contents of headers as OpenTelemetry attributes.
--
-- @headers     a table of HTTP response headers
-- @return      a table of attribute
------------------------------------------------------------------
function _M.response_header(headers)
    local attributes = {}
    for k, v in pairs(headers) do
        k = _M.HTTP_RESPONSE_HEADER .. '.' .. k
        if type(v) == "table" then
            table.insert(attributes, attribute.string_array(k, v))
        else
            table.insert(attributes, attribute.string(k, v))
        end
    end
    return attributes
end

return _M
