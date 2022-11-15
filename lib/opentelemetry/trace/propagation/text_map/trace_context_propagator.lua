local span_context = require("opentelemetry.trace.span_context")
local tracestate = require("opentelemetry.trace.tracestate")
local text_map_getter = require("opentelemetry.trace.propagation.text_map.getter")
local text_map_setter = require("opentelemetry.trace.propagation.text_map.setter")
local util = require("opentelemetry.util")

local _M = {
}

local mt = {
    __index = _M,
}

-- these should be constants, but they were not supported until Lua 5.4, and
-- LuaJIT (which openresty runs on) works up to Lua 5.2
local traceparent_header = "traceparent"
local tracestate_header  = "tracestate"

local invalid_trace_id = span_context.INVALID_TRACE_ID
local invalid_span_id = span_context.INVALID_SPAN_ID

function _M.new()
    return setmetatable(
        {
            text_map_setter = text_map_setter.new(),
            text_map_getter = text_map_getter.new()
        }, mt)
end

------------------------------------------------------------------
-- Add tracing information to nginx request as headers
--
-- @param context       context storage
-- @param carrier       nginx request
-- @param setter        setter for interacting with carrier
-- @return nil
------------------------------------------------------------------
function _M:inject(context, carrier, setter)
    setter = setter or self.text_map_setter
    local span_context = context:span_context()
    if not span_context:is_valid() then
        return
    end
    local traceparent = string.format("00-%s-%s-%02x",
        span_context.trace_id, span_context.span_id, span_context.trace_flags)
    setter.set(carrier, traceparent_header, traceparent)
    if span_context.trace_state then
        setter.set(carrier, tracestate_header, span_context.trace_state:as_string())
    end
end

local function validate_trace_id(trace_id)
    return type(trace_id) == "string" and #trace_id == 32 and trace_id ~= invalid_trace_id
        and string.match(trace_id, "^[0-9a-f]+$")
end

local function validate_span_id(span_id)
    return type(span_id) == "string" and #span_id == 16 and span_id ~= invalid_span_id
        and string.match(span_id, "^[0-9a-f]+$")
end

-- Traceparent: 00-982d663bad6540dece76baf15dd2aa7f-6827812babd449d1-01
--              version-trace-id-parent-id-trace-flags
local function parse_trace_parent(trace_parent)
    if type(trace_parent) ~= "string" or trace_parent == "" then
        return
    end
    local ret = util.split(util.trim(trace_parent), "-")
    if #ret < 4 then
        return
    end

    if #ret[1] ~= 2 then
        return
    end

    local version = tonumber(ret[1], 16)
    if not version or version > 254 then
        return
    end
    if version == 0 and #ret ~= 4 then
        return
    end

    if not validate_trace_id(ret[2]) then
        return
    end

    if not validate_span_id(ret[3]) then
        return
    end

    if #ret[4] ~= 2 then
        return
    end

    local trace_flags = tonumber(ret[4], 16)
    if not trace_flags or trace_flags > 2 then
        return
    end

    return ret[2], ret[3], trace_flags
end

------------------------------------------------------------------
-- extract span context from upstream request.
--
-- @context             current context
-- @carrier             get traceparent and tracestate
-- @return              new context
------------------------------------------------------------------
function _M:extract(context, carrier, getter)
    getter = getter or self.text_map_getter
    local trace_id, span_id, trace_flags = parse_trace_parent(getter.get(carrier, traceparent_header))
    if not trace_id or not span_id or not trace_flags then
        return context
    end

    local trace_state = tracestate.parse_tracestate(getter.get(carrier, tracestate_header))

    return context:with_span_context(span_context.new(trace_id, span_id, trace_flags, trace_state, true))
end

function _M.fields()
    return { "traceparent", "tracestate" }
end

return _M
