local _M = {}

local function ngx_nano_time()
    return ngx.now() * 1000000000
end

local ffi = require("ffi")

ffi.cdef[[
  typedef long time_t;

  typedef struct timeval {
    time_t tv_sec;
    time_t tv_usec;
  } timeval;

  int gettimeofday(struct timeval* t, void* tzp);
]]

local gettimeofday_struct = ffi.new("timeval")
local function ffi_gettimeofday()
    ffi.C.gettimeofday(gettimeofday_struct, nil)
    return tonumber(gettimeofday_struct.tv_sec) * 1000000000 +
            tonumber(gettimeofday_struct.tv_usec) * 1000
end

_M.ngx_nano_time = ngx_nano_time
_M.ffi_gettimeofday = ffi_gettimeofday

-- default time function, will be used in this SDK
-- change it if needed
_M.nano_time = ngx_nano_time

return _M