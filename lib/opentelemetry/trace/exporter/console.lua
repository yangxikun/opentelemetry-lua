-------------------------------------------------------------------------------
-- The console span exporter is used for debugging. It should not be used in
-- production contexts.
-------------------------------------------------------------------------------
local encoder = require("opentelemetry.trace.exporter.encoder")

local _M = {
}

local mt = {
    __index = _M
}

--------------------------------------------------------------------------------
-- Create a new console span exporter. If being run in an nginx context, will
-- log spans to ngx.log(ngx.INFO). Otherwise, will use Lua's print() method.
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

    -- Check if ngx variable is not nil; use ngx.log if ngx var is present.
    if ngx then
        ngx.log(ngx.INFO, "Export spans: ", span_string)
    else
        print("Export spans: ", span_string)
    end
end

function _M.force_flush(self)
end

function _M.shutdown(self)
end

return _M
