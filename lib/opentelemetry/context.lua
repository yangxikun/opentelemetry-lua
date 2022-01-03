local non_recording_span_new = require("opentelemetry.trace.non_recording_span").new
local noop_span = require("opentelemetry.trace.noop_span")

local _M = {
}

local mt = {
    __index = _M
}

local key = "opentelemetry-context"

function _M.new(storage)
    return setmetatable({storage = storage, sp = noop_span, is_attached = false}, mt)
end

function _M.attach(self)
    self.prev = self:current()
    self.storage:set(key, self)
    self.is_attached = true
end

function _M.detach(self)
    if self.is_attached then
        self.storage:set(key, self.prev)
        self.is_attached = false
    end
end

function _M.current(self)
    return self.storage:get(key)
end

function _M.with_span(self, span)
    return setmetatable({storage = self.storage, sp = span, is_attached = false}, mt)
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
