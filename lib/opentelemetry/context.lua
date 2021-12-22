local non_recording_span_new = require("opentelemetry.trace.non_recording_span").new

local _M = {
}

local mt = {
    __index = _M
}

function _M.new(storage)
    return setmetatable({storage = storage}, mt)
end

function _M.attach(self)
    self.prev = self:current()
    self.storage.set("opentelemetry-context", self)
end

function _M.detach(self)
    self.storage.set("opentelemetry-context", self.prev)
end

function _M.current(self)
    return self.storage.get("opentelemetry-context")
end

function _M.with_span(self, span)
    return setmetatable({storage = self.storage, sp = span}, mt)
end

function _M.with_span_context(self, span_context)
    return self:with_span(non_recording_span_new(nil, span_context))
end

function _M.span_context(self)
    return self.sp:context()
end

function _M.span(self)
    return self.sp
end

return _M
