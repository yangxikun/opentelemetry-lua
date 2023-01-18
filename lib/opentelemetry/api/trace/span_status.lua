------------------------------------------------------------------------------------------------------------------------
-- Span status represents the status of a span. Like an HTTP code, but for your span. It is either unset, ok, or error.
--
-- @module api.trace.span_status
------------------------------------------------------------------------------------------------------------------------
local _M = { UNSET = 0, OK = 1, ERROR = 2 }

------------------------------------------------------------------------------------------------------------------------
-- Returns a new span_status.
--
-- @param[type=int] code The status code. Defaults to UNSET.
------------------------------------------------------------------------------------------------------------------------
function _M.new(code)
    return { code = code or _M.UNSET, description = nil }
end

return _M
