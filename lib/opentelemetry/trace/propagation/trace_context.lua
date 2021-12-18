local span_context_new = require("opentelemetry.trace.span_context").new
local empty_span_context = span_context_new()


local _M = {}

local traceparent_header = "traceparent"
local tracestate_header  = "tracestate"

function _M.inject(ctx, carrier)
    local traceparent = string.format("00-%s-%s-%02x", ctx.trace_id, ctx.span_id, ctx.trace_flags)
    carrier:set(traceparent_header, traceparent)
    carrier:set(tracestate_header, ctx.trace_state)
end

local function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- Traceparent: 00-982d663bad6540dece76baf15dd2aa7f-6827812babd449d1-01
--              version-trace-id-parent-id-trace-flags
function _M.extract(carrier)
    local trace_parent = carrier:get(traceparent_header)
    if not trace_parent or trace_parent == "" then
        return empty_span_context
    end
    local ret = split(trace_parent, "-")
    if #ret ~= 4 then
        return empty_span_context
    end

    if #ret[1] ~= 2 then
        return empty_span_context
    end

    if #ret[2] ~= 32 then
        return empty_span_context
    end

    if #ret[3] ~= 16 then
        return empty_span_context
    end

    if #ret[4] ~= 2 then
        return empty_span_context
    end

    local version = tonumber(ret[1], 16)
    if version ~= 0 then
        return empty_span_context
    end

    local trace_flags = tonumber(ret[4], 16)
    if trace_flags > 2 then
        return empty_span_context
    end

    local trace_state = carrier:get(tracestate_header)

    return span_context_new(ret[2], ret[3], trace_flags, trace_state, true)
end

return _M
