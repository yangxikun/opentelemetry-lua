local util = require "opentelemetry.util"
local bit = require 'bit'

local tohex = bit.tohex
local fmt = string.format
local random = util.random

local _M = {}

function _M.new_span_id()
    return fmt("%s%s",
        tohex(random(0, 0xFFFFFFFF), 8),
        tohex(random(0, 0xFFFFFFFF), 8))
end

function _M.new_ids()
    return fmt("%s%s%s%s",
        tohex(random(0, 0xFFFFFFFF), 8),
        tohex(random(0, 0xFFFFFFFF), 8),
        tohex(random(0, 0xFFFFFFFF), 8),
        tohex(random(0, 0xFFFFFFFF), 8)), _M.new_span_id()
end

return _M
