------------------------------------------------------------------------------------------------------------------------
--- A module for getting otel-related env var settings, specified here:
-- https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/sdk-environment-variables.md
--
-- @module api.utils.env_var_settings
------------------------------------------------------------------------------------------------------------------------
local function getenv_with_fallback(env_var, fallback)
    local value = os.getenv(env_var)
    if value == nil then
        return fallback
    end
    return value
end

local _M = { getenv_with_fallback = getenv_with_fallback, log_level = getenv_with_fallback("OTEL_LOG_LEVEL", "warn") }

return _M
