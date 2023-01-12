local baggage = require("opentelemetry.baggage")
local otel_global = require("opentelemetry.global")
local non_recording_span_new = require("opentelemetry.trace.non_recording_span").new
local noop_span = require("opentelemetry.trace.noop_span")
local util = require("opentelemetry.util")

local _M = {
}

local mt = {
    __index = _M
}

local context_key = "__opentelemetry_context__"
local baggage_context_key = "__opentelemetry_baggage__"

--------------------------------------------------------------------------------
-- Create new context with set of entries
--
-- @return              context
--------------------------------------------------------------------------------
function _M.new(entries, span)
    return setmetatable({ sp = span or noop_span, entries = entries or {} }, mt)
end

--------------------------------------------------------------------------------
-- Set this context as current by pushing it on stack stored at context_key.
--
-- @return              token to be used for detaching
--------------------------------------------------------------------------------
function _M.attach(self)
    if otel_global.get_context_storage()[context_key] then
        table.insert(otel_global.get_context_storage()[context_key], self)
    else
        otel_global.get_context_storage()[context_key] = { self }
    end

    -- the length of the stack is token used to detach context
    return #otel_global.get_context_storage()[context_key]
end

--------------------------------------------------------------------------------
-- Detach current context, setting current context to previous element in stack
-- If token does not match length of elements in stack, returns false and error
-- string.
--
-- @return            boolean, string
--------------------------------------------------------------------------------
function _M.detach(self, token)
    if #otel_global.get_context_storage()[context_key] == token then
        table.remove(otel_global.get_context_storage()[context_key])
        return true, nil
    else
        local error_message = "Token does not match (" ..
            #otel_global.get_context_storage()[context_key] ..
            " context entries in stack, token provided was " .. token .. ")."
        ngx.log(ngx.WARN, error_message)
        return false, error_message
    end
end

--------------------------------------------------------------------------------
-- Get current context, which is the final element in stack stored at
-- context_key.
--
-- @return            boolean, string
--------------------------------------------------------------------------------
function _M.current()
    if otel_global.get_context_storage()[context_key] then
        return otel_global.get_context_storage()[context_key][#otel_global.get_context_storage()[context_key]]
    else
        return _M.new()
    end
end

--------------------------------------------------------------------------------
-- Retrieve value for key in context.
--
-- @key                 key for which to set the value in context
-- @return              value stored at key
--------------------------------------------------------------------------------
function _M.get(self, key)
    return self.entries[key]
end

--------------------------------------------------------------------------------
-- Set value for key in context. This returns a new context object.
--
-- @key                 key for which to set the value in context
-- @value               value to set
-- @return              context
--------------------------------------------------------------------------------
function _M.set(self, key, value)
    local vals = util.shallow_copy_table(self.entries)
    vals[key] = value
    return self.new(vals, self.sp)
end

--------------------------------------------------------------------------------
-- Inject baggage into current context
--
-- @baggage             baggage instance to inject
-- @return              context
--------------------------------------------------------------------------------
function _M.inject_baggage(self, baggage)
    return self:set(baggage_context_key, baggage)
end

--------------------------------------------------------------------------------
-- Extract baggage from context
--
-- @return              baggage
--------------------------------------------------------------------------------
function _M.extract_baggage(self)
    return self:get(baggage_context_key) or baggage.new({})
end

function _M.with_span(self, span)
    return self.new(util.shallow_copy_table(self.entries or {}), span)
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
