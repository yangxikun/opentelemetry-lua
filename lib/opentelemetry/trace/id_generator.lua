local util = require "opentelemetry.util"
local bit = require 'bit'

local tohex = bit.tohex
local fmt = string.format
local random = util.random
local FFFFFFFF = 4294967295 -- FFFFFFFF in hexadecimal is 4294967295 in decimal

local _M = {}

function _M.new_span_id()
    return fmt("%s%s",
        tohex(random(0, FFFFFFFF), 8),
        tohex(random(0, FFFFFFFF), 8))
end

function _M.new_ids()
    return fmt("%s%s%s%s",
        tohex(random(0, FFFFFFFF), 8),
        tohex(random(0, FFFFFFFF), 8),
        tohex(random(0, FFFFFFFF), 8),
        tohex(random(0, FFFFFFFF), 8)), _M.new_span_id()
end

return _M
