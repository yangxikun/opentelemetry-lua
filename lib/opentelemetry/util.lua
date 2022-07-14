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
local function ffi_gettimeofday()
    ffi.C.gettimeofday(gettimeofday_struct, nil)
    return tonumber(gettimeofday_struct.tv_sec) * 1000000000 +
            tonumber(gettimeofday_struct.tv_usec) * 1000
end

_M.ngx_time_nano = ngx_time_nano
_M.gettimeofday = ffi_gettimeofday

-- default time function, will be used in this SDK
-- change it if needed
_M.time_nano = ffi_gettimeofday

return _M