local context = require("opentelemetry.context")
local util = require("opentelemetry.util")

local _M = {
}

local mt = {
    __index = _M
}

local BAGGAGE_KEY = "opentelemetry-baggage"

function _M.new(values)
    return setmetatable({ values = values or {} }, mt)
end

--------------------------------------------------------------------------------
-- Set a value in a baggage instance. Does _not_ inject into context
--
-- @name                name for which to set the value in baggage
-- @value               value to set must be string
-- @metadata            metadata to set in baggage (string)
-- @return              baggage
--------------------------------------------------------------------------------
function _M.set_value(self, name, value, metadata)
    local new_values = util.shallow_copy_table(self.values)
    new_values[name] = { value = value, metadata = metadata }
    return self.new(new_values)
end

--------------------------------------------------------------------------------
-- Get value stored at a specific name in a baggage instance
--
-- @name                name for which to set the value in baggage
-- @return              baggage
--------------------------------------------------------------------------------
function _M.get_value(self, name)
    if self.values[name] then
        return self.values[name].value
    else
        return nil
    end
end


--------------------------------------------------------------------------------
-- Remove value stored at a specific name in a baggage instance
--
-- @name                name to remove from baggage
-- @return              baggage
--------------------------------------------------------------------------------
function _M.remove_value(self, name)
    local new_values = util.shallow_copy_table(self.values)
    new_values[name] = nil
    return self.new(new_values)
end


--------------------------------------------------------------------------------
-- Get all values in a baggage instance
--
-- @context             context from which to access the baggage (defaults to current context)
-- @return              table like { keyname = { value = "value", metadata = "metadatastring"} }
--------------------------------------------------------------------------------
function _M.get_all_values(self)
    return self.values
end

local function baggage_for(ctx)
    ctx = ctx or context:current()
    local vals = ctx:get(BAGGAGE_KEY)
    _M.new(vals)
end

return _M
