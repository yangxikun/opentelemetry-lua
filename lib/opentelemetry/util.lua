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
-- @return current time in nanoseconds
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

_M.ngx_time_nano = ngx_time_nano
_M.gettimeofday = ffi_gettimeofday
_M.gettimeofday_ms = gettimeofday_ms
_M.random = random
_M.random_float = random_float
_M.shallow_copy_table = shallow_copy_table

-- default time function, will be used in this SDK
-- change it if needed
_M.time_nano = gettimeofday_ns

return _M
