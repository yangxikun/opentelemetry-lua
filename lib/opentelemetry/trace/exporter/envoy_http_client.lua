local _M = {
}

local mt = {
    __index = _M
}

function _M.new(handle, authority, timeout)
    local self = {
        handle = handle,
        authority = authority,
        timeout = timeout,
    }
    return setmetatable(self, mt)
end

function _M.do_request(self, content_type, body)
    local headers = {}
    headers[":path"] = "/v1/traces"
    headers[":method"] = "POST"
    headers[":authority"] = self.authority
    headers["content-type"] = content_type

    -- async request
    self.handle:httpCall(self.authority, headers, body, self.timeout, true)
end

return _M
