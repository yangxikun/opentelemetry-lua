local span_context_new = require("opentelemetry.trace.span_context").new
local text_map_getter_new = require("opentelemetry.trace.propagation.text_map.getter").new()
local text_map_setter_new = require("opentelemetry.trace.propagation.text_map.setter").new()
local empty_span_context = span_context_new()


-- all descendants get same getter and setter to avoid extra allocations
local _M = {
    text_map_setter = text_map_setter_new,
    text_map_getter = text_map_getter_new
}

local mt = {
    __index = _M,
}

-- these should be constants, but they were not supported until Lua 5.4, and
-- LuaJIT (which openresty runs on) works up to Lua 5.2
local traceparent_header = "traceparent"
local tracestate_header  = "tracestate"

local invalid_trace_id = '00000000000000000000000000000000'
local invalid_span_id = '0000000000000000'

function _M.new()
    return setmetatable({}, mt)
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
        setter.set(tracestate_header, span_context.trace_state)
    end
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

local function validate_member_key(key)
    if #key > 256 then
        return nil
    end

    local valid_key = string.match(key, [[^%s*([a-z][_0-9a-z%-*/]*)$]])
    if not valid_key then
        local tenant_id, system_id = string.match(key, [[^%s*([a-z0-9][_0-9a-z%-*/]*)@([a-z][_0-9a-z%-*/]*)$]])
        if not tenant_id or not system_id then
            return nil
        end
        if #tenant_id > 241 or #system_id > 14 then
            return nil
        end
        return tenant_id .. "@" .. system_id
    end

    return valid_key
end

local function validate_member_value(value)
    if #value > 256 then
        return nil
    end
    return string.match(value, [[^([ !"#$%%&'()*+%-./0-9:;<>?@A-Z[\%]^_`a-z{|}~]*[!"#$%%&'()*+%-./0-9:;<>?@A-Z[\%]^_`a-z{|}~])%s*$]])
end

local function parse_trace_state(trace_state)
    if not trace_state then
        return ""
    end
    if type(trace_state) == "string" then
        trace_state = {trace_state}
    end

    local new_trace_state = {}
    local members_count = 0
    for _, item in ipairs(trace_state) do
        for member in string.gmatch(item, "([^,]+)") do
            if member ~= "" then
                local start_pos, end_pos = string.find (member, "=", 1, true)
                if not start_pos or start_pos == 1 then
                    return ""
                end
                local key = validate_member_key(string.sub(member, 1, start_pos-1))
                if not key then
                    return ""
                end

                local value = validate_member_value(string.sub(member, end_pos+1))
                if not value then
                    return ""
                end

                members_count = members_count + 1
                if members_count > 32 then
                    return ""
                end
                table.insert(new_trace_state, key .. "=" .. value)
            end
        end
    end

    return table.concat(new_trace_state, ",")
end

local function validate_trace_id(trace_id)
    return type(trace_id) == "string" and #trace_id == 32 and trace_id ~= invalid_trace_id
            and string.match(trace_id, "^[0-9a-f]+$")
end

local function validate_span_id(span_id)
    return type(span_id) == "string" and #span_id == 16 and span_id ~= invalid_span_id
            and string.match(span_id, "^[0-9a-f]+$")
end

local function trim(s)
    return s:match'^%s*(.*%S)' or ''
end

-- Traceparent: 00-982d663bad6540dece76baf15dd2aa7f-6827812babd449d1-01
--              version-trace-id-parent-id-trace-flags
local function parse_trace_parent(trace_parent)
    if type(trace_parent) ~= "string" or trace_parent == "" then
        return
    end
    local ret = split(trim(trace_parent), "-")
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
        return context:with_span_context(empty_span_context)
    end

    local trace_state = parse_trace_state(getter.get(carrier, tracestate_header))

    return context:with_span_context(span_context_new(trace_id, span_id, trace_flags, trace_state, true))
end

function _M.fields()
    return { "traceparent", "tracestate" }
end

return _M
