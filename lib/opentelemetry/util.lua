local _M = {}

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

_M.ngx_time_nano = ngx_time_nano
_M.gettimeofday = ffi_gettimeofday

-- Return current time in milliseconds nanoseconds (there are 1000 nanoseconds
-- in a microsecond)
--
-- @return current time in nanoseconds
--------------------------------------------------------------------------------
local function gettimeofday_ns()
    return ffi_gettimeofday() * 1000
end

-- default time function, will be used in this SDK
-- change it if needed
_M.time_nano = gettimeofday_ns

return _M