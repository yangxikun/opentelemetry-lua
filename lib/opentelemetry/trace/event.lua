local util = require("opentelemetry.util")

local _M = {
}

local mt = {
    __index = _M
}

------------------------------------------------------------------
-- create a event.
--
-- @name            event name
-- @opts            [optional]
--                      opts.attributes: a list of attribute
-- @return          event
------------------------------------------------------------------
function _M.new(name, opts)
    local self = {
        name = name,
        attributes = opts.attributes,
        time_unix_nano = string.format("%d", util.time_nano())
    }
    return setmetatable(self, mt)
end

return _M
