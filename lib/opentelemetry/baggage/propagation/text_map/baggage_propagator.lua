--------------------------------------------------------------------------------
--
-- See https://w3c.github.io/baggage/ for details.
--
--------------------------------------------------------------------------------

local baggage = require("opentelemetry.baggage")
local text_map_getter = require("opentelemetry.trace.propagation.text_map.getter")
local text_map_setter = require("opentelemetry.trace.propagation.text_map.setter")
local util = require("opentelemetry.util")

local _M = {
}

local mt = {
    __index = _M,
}

local baggage_header = "baggage"

function _M.new()
    return setmetatable(
        {
            text_map_setter = text_map_setter.new(),
            text_map_getter = text_map_getter.new()
        }, mt)
end

-------------=------------------------------------------------------------------
-- Set baggage header on outbound HTTP request header.
--
-- @param context       context storage
-- @param carrier       nginx request
-- @param setter        setter for interacting with carrier
-- @return nil
--------------------------------------------------------------------------------
function _M:inject(context, carrier, setter)
    setter = setter or self.text_map_setter
    local bgg = context:extract_baggage()
    local header_string = ""
    for k, v in pairs(bgg.values) do
        local element = k .. "=" .. v.value
        if v.metadata then
            element = element .. ";" .. v.metadata
        end
        element = element .. ","
        header_string = header_string .. element
    end

    -- trim trailing comma
    header_string = header_string:sub(0, -2)

    setter.set(
        carrier,
        baggage_header,
        util.percent_encode_baggage_string(header_string)
    )
end

--------------------------------------------------------------------------------
-- Extract baggage from HTTP request headers.
--
-- @context             current context
-- @carrier             ngx.req
-- @return              new context with baggage associated
--------------------------------------------------------------------------------
function _M:extract(context, carrier, getter)
    getter = getter or self.text_map_getter
    local baggage_string = getter.get(carrier, baggage_header)
    if not baggage_string then
        return context
    else
        baggage_string = util.decode_percent_encoded_string(baggage_string)
    end

    local baggage_entries = {}
    -- split apart string on comma and build up baggage entries
    for list_member in string.gmatch(baggage_string, "([^,]+)") do
        -- extract metadata from each list member
        local kv, metadata = string.match(list_member, "([^;]+);(.*)")

        -- If there's no semicolon in list member, then kv and metadata are nil
        -- and we need to correct that
        if not kv then
            kv = list_member
            metadata = ""
        end

        -- split apart k/v on equals sign
        for k, v in string.gmatch(kv, "(.+)=(.+)") do
            if self.validate_baggage(k, v) then
                baggage_entries[k] = { value = v, metadata = metadata }
            else
                ngx.log(ngx.WARN, "invalid baggage entry: " .. k .. "=" .. v)
            end
        end
    end

    local extracted_baggage = baggage.new(baggage_entries)
    return context:inject_baggage(extracted_baggage)
end

--------------------------------------------------------------------------------
-- Check to see if baggage has both key and value component
--
-- @key                 baggage key
-- @value               baggage value
-- @return              boolean
--------------------------------------------------------------------------------
function _M.validate_baggage(key, value)
    return (key and value) ~= nil
end

--------------------------------------------------------------------------------
-- Fields that will be used by the propagator
--
-- @return              table
--------------------------------------------------------------------------------
function _M.fields()
    return { "baggage" }
end

return _M
