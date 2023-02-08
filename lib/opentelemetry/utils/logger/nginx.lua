------------------------------------------------------------------------------------------------------------------------
--- An NGINX logger. This logger will call ngx.log(loglevel, message), but if your NGINX config file doesn't allow the
-- specified log level, then the message will not be logged out. So if you configure this logger with a log level of
-- debug, you also need to set up your NGINX config along these lines:
--   error_log logs/error.log debug;
--
-- @module utils.logger.nginx
------------------------------------------------------------------------------------------------------------------------

local logger = require("opentelemetry.api.utils.logger.base")
local _M = logger:new()

--- Return name of module; useful for debugging.
--
-- @treturn string
function _M.module_name()
    return "api.utils.logger.nginx"
end

--- Return a table with all log levels.
--
-- @return A table of log levels ({ log_level_name = int, ... }).
function _M:log_levels()
    return { debug = ngx.DEBUG, info = ngx.INFO, notice = ngx.NOTICE, warn = ngx.WARN, error = ngx.ERR, crit = ngx.CRIT, alert = ngx.ALERT, emerg = ngx.EMERG }
end

--- Write out to nginx.log
--
-- @string message The message to write.
-- @param[type=number] configured_level The log level of the logger instance.
-- @param[type=number] callsite_level The log level at which the message was logged.
--
-- @return nil
function _M:write(message, configured_level, callsite_level)
    if configured_level >= self:log_levels()[callsite_level] then
        ngx.log(self:log_levels()[callsite_level], "OpenTelemetry: " .. message)
    end
end

return _M
