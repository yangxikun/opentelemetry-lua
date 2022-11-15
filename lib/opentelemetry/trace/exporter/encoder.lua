-------------------------------------------------------------------------------
-- The encoder is responsible for taking spans and serializing them into
-- different export formats.
-------------------------------------------------------------------------------

local util = require("opentelemetry.util")

local _M = {
}

local mt = {
    __index = _M
}

--------------------------------------------------------------------------------
-- hex2bytes converts a hex string into bytes (used for transit over OTLP).
--
-- @param str Hex string.
-- @return Table to be used as basis for more specific exporters.
--------------------------------------------------------------------------------
local function hex2bytes(str)
    return (str:gsub('..', function(cc)
        local n = tonumber(cc, 16)
        if n then
            return string.char(n)
        end
    end))
end

--------------------------------------------------------------------------------
-- for_export structures span data for export; used as basis for more specific
-- exporters.
--
-- @param span The span to export
-- @return Table to be used as basis for more specific exporters.
--------------------------------------------------------------------------------
function _M.for_export(span)
    return {
        trace_id = span.ctx.trace_id,
        span_id = span.ctx.span_id,
        trace_state = span.ctx.trace_state:as_string(),
        parent_span_id = span.parent_ctx.span_id or "",
        name = span.name,
        kind = span.kind,
        start_time_unix_nano = string.format("%d", span.start_time),
        end_time_unix_nano = string.format("%d", span.end_time),
        attributes = span.attributes,
        dropped_attributes_count = 0,
        events = span.events,
        dropped_events_count = 0,
        links = {},
        dropped_links_count = 0,
        status = span.status
    }
end

--------------------------------------------------------------------------------
-- for_otlp returns a table that can be protobuf-encoded for transmission over
-- OTLP.
--
-- @param span The span to export
-- @return Table to be protobuf-encoded
--------------------------------------------------------------------------------
function _M.for_otlp(span)
    local ret = _M.for_export(span)
    ret.trace_id = hex2bytes(ret.trace_id)
    ret.span_id = hex2bytes(ret.span_id)
    ret.parent_span_id = hex2bytes(ret.parent_span_id)
    return ret
end

--------------------------------------------------------------------------------
-- for_console renders a string representation of span for console output.
--
-- @param span The span to export
-- @return String representation of span.
--------------------------------------------------------------------------------
function _M.for_console(span)
    local ret = "\n---------------------------------------------------------\n"
    ret = ret .. util.table_as_string(_M.for_export(span), 2)
    ret = ret .. "---------------------------------------------------------\n"
    return ret
end

return _M
