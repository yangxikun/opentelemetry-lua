------------------------------------------------------------------------------------------------------------------------
--- A simple logger that uses print(). All loggers must adhere to the same interface.
--
-- @module api.utils.logger
------------------------------------------------------------------------------------------------------------------------
local _M = {}

function _M.module_name()
    return "api.utils.logger.base"
end

--- Return a table with all log levels.
--
-- @return A table of log levels ({ log_level_name = int, ... }).
function _M:log_levels()
    return { debug = 8, info = 7, notice = 6, warn = 5, error = 4, crit = 3, alert = 2, emerg = 1 }
end

--- Return a new logger instance
--
-- @string log_level The log level to use. Defaults to 'error'.
-- @return A new logger instance
function _M:new(log_level)
    return setmetatable(
        { log_level = self:log_levels()[log_level] or self:log_levels().error },
        { __index = self })
end

--- Write message to stdout
--
-- @string message The message to write.
-- @param[type=number] configured_level The log level of the logger instance.
-- @param[type=number] callsite_level The log level at which the message was logged.
--
-- @return nil
function _M:write(message, configured_level, callsite_level)
    if configured_level >= self:log_levels()[callsite_level] then
        print("OpenTelemetry: " .. message)
    end
end

--- Write debug message
--
-- @string message The message to write.
--
-- @return nil
function _M:debug(message)
    self:write(message, self.log_level, "debug")
end

--- Write info message
--
-- @string message The message to write.
--
-- @return nil
function _M:info(message)
    self:write(message, self.log_level, "info")
end

--- Write notice message
--
-- @string message The message to write.
--
-- @return nil
function _M:notice(message)
    self:write(message, self.log_level, "notice")
end

--- Write warn message
--
-- @string message The message to write.
--
-- @return nil
function _M:warn(message)
    self:write(message, self.log_level, "warn")
end

--- Write error message
--
-- @string message The message to write.
--
-- @return nil
function _M:error(message)
    self:write(message, self.log_level, "error")
end

--- Write crit message
--
-- @string message The message to write.
--
-- @return nil
function _M:crit(message)
    self:write(message, self.log_level, "crit")
end

--- Write alert message
--
-- @string message The message to write.
--
-- @return nil
function _M:alert(message)
    self:write(message, self.log_level, "alert")
end

--- Write emerg message
--
-- @string message The message to write.
--
-- @return nil
function _M:emerg(message)
    self:write(message, self.log_level, "emerg")
end

return _M
