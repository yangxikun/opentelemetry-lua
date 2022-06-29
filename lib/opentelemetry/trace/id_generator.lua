local bit = require 'bit'

local tohex = bit.tohex
local fmt = string.format
local random = math.random

local _M = {}

if (os.getenv("OTEL_LUA_RANDOMSEED") == "ostime") then
    math.randomseed(os.time(os.date("!*t")))
else
    math.randomseed(ngx.time() + ngx.worker.pid())
end

function _M.new_span_id()
    return fmt("%s%s%s%s%s%s%s%s",
                tohex(random(0, 255), 2),
                tohex(random(0, 255), 2),
                tohex(random(0, 255), 2),
                tohex(random(0, 255), 2),
                tohex(random(0, 255), 2),
                tohex(random(0, 255), 2),
                tohex(random(0, 255), 2),
                tohex(random(0, 255), 2))
end

function _M.new_ids()
    return fmt("%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s",
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2)), _M.new_span_id()
end

return _M
