local bit = require 'bit'

local tohex = bit.tohex
local fmt = string.format
local random = math.random

local _M = {}

math.randomseed(os.time(os.date("!*t")))

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
