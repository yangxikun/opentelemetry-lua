-------------------------------------------------------------------------------
-- The console span exporter is used for debugging. It should not be used in
-- production contexts.
-------------------------------------------------------------------------------
local encoder = require("opentelemetry.trace.exporter.encoder")
local otel_global = require("opentelemetry.global")

local _M = {
}

local mt = {
    __index = _M
}

--------------------------------------------------------------------------------
-- Create a new console span exporter.
--
-- @return New console span exporter
--------------------------------------------------------------------------------
function _M.new()
    return setmetatable({}, mt)
end

function _M.export_spans(self, spans)
    local span_string = ""
    for _, span in ipairs(spans) do
        span_string = span_string .. encoder.for_console(span) .. "\n"
    end

    otel_global.logger:info("Export spans: " .. span_string)
end

function _M.force_flush(self)
end

function _M.shutdown(self)
end

return _M
