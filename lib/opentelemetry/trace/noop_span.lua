local empty_span_context = require("opentelemetry.trace.span_context").new()

local _M = {
}

function _M.context(self)
    return empty_span_context
end

function _M.is_recording()
    return false
end

function _M.set_status()
end

function _M.set_attributes()
end

function _M.finish(_self, _end_timestamp)
end

function _M.record_error()
end

function _M.add_event()
end

function _M.set_name()
end

function _M.tracer_provider()
end

return _M
