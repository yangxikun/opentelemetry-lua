local api_span_status = require("opentelemetry.api.trace.span_status")

local _M = api_span_status:new()

-- returns a valid span status code
function _M.validate(code)
    if not code or code < 0 or code > 2 then
        -- default unset
        return 0
    end
    return code
end

return _M
