local _M = {}

--- Set randomseed
math.randomseed(ngx.time() + ngx.worker.pid())

-- performance better, but may cause clock skew
local function ngx_time_nano()
  return ngx.now() * 1000000000
end

local ffi = require("ffi")
if not pcall(function() ffi.sizeof("timeval") end) then
  ffi.cdef [[
    typedef struct timeval {
      long tv_sec;
      long tv_usec;
    } timeval;
  ]]
end

ffi.cdef [[
  int gettimeofday(struct timeval* t, void* tzp);
]]

local gettimeofday_struct = ffi.new("timeval")

--------------------------------------------------------------------------------
-- Return current time in microseconds (via FFI call). This is the maximum
-- precision available from Linux's gettimeofday() function
--
-- @return current time in microseconds
--------------------------------------------------------------------------------
local function ffi_gettimeofday()
  ffi.C.gettimeofday(gettimeofday_struct, nil)
  return tonumber(gettimeofday_struct.tv_sec) * 1000000 +
      tonumber(gettimeofday_struct.tv_usec)
end

-- Return current time in nanoseconds (there are 1000 nanoseconds
-- in a microsecond)
--
-- @return current time in nanoseconds
--------------------------------------------------------------------------------
local function gettimeofday_ns()
  return ffi_gettimeofday() * 1000
end

-- Return current time in milliseconds (there are 1000 milliseconds in a
-- microsecond
--
-- @return current time in milliseconds
--------------------------------------------------------------------------------
local function gettimeofday_ms()
  return ffi_gettimeofday() / 1000
end

-- Localize math.random calls to this file so we don't have scattered
-- math.randomseed calls.
local function random(...)
  return math.random(...)
end

-- Lua's math.random won't generate random floats within a given range, so we
-- hack it together by subtracting math.random() from random integer.
local function random_float(max)
  return math.random(max) - math.random()
end

local function shallow_copy_table(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

local function hex_to_char(hex)
  return string.char(tonumber(hex, 16))
end

local function char_to_hex(c)
  return string.format("%%%02X", string.byte(c))
end

-- Baggage headers values can be percent encoded. We need to unescape them. The
-- regex is a bit weird-looking, so here's the relevant section on patterns in
-- the Lua manual (https://www.lua.org/manual/5.2/manual.html#6.4.1)
local function decode_percent_encoded_string(str)
  return str:gsub("%%(%x%x)", hex_to_char)
end

--------------------------------------------------------------------------------
-- Percent encode a baggage string. It's not generic for all percent encoding,
-- since we don't want to percent-encode equals signs, semicolons, or commas in
-- baggage strings.
--
-- @str                 string to be sent as baggage list item
-- @return              new context with baggage associated
--------------------------------------------------------------------------------
-- adapted from https://gist.github.com/liukun/f9ce7d6d14fa45fe9b924a3eed5c3d99
local function percent_encode_baggage_string(str)
  if str == nil then
    return
  end
  str = str:gsub("\n", "\r\n")
  str = str:gsub("([^%w ,;=_%%%-%.~])", char_to_hex)
  str = str:gsub(" ", "+")
  return str
end

--------------------------------------------------------------------------------
-- Recursively render a table as a string
-- Code from http://lua-users.org/wiki/TableSerialization
--------------------------------------------------------------------------------
local function table_as_string (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    local sb = {}
    for key, value in pairs (tt) do
      table.insert(sb, string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        table.insert(sb, key .. " = {\n");
        table.insert(sb, table_as_string (value, indent + 2, done))
        table.insert(sb, string.rep (" ", indent)) -- indent it
        table.insert(sb, "}\n");
      elseif "number" == type(key) then
        table.insert(sb, string.format("\"%s\"\n", tostring(value)))
      else
        table.insert(sb, string.format(
            "%s = \"%s\"\n", tostring (key), tostring(value)))
       end
    end
    return table.concat(sb)
  else
    return tt .. "\n"
  end
end

local function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end

local function trim(s)
  return s:match '^%s*(.*%S)' or ''
end

_M.ngx_time_nano = ngx_time_nano
_M.gettimeofday = ffi_gettimeofday
_M.gettimeofday_ms = gettimeofday_ms
_M.random = random
_M.random_float = random_float
_M.shallow_copy_table = shallow_copy_table
_M.decode_percent_encoded_string = decode_percent_encoded_string
_M.percent_encode_baggage_string = percent_encode_baggage_string
_M.split = split
_M.table_as_string = table_as_string
_M.trim = trim

-- default time function, will be used in this SDK
-- change it if needed
_M.time_nano = gettimeofday_ns

return _M
