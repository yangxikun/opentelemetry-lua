--------------------------------------------------------------------------------
-- The composite propagator bundles together multiple propagators and executes
-- them in sequence.
-- See: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/context/api-propagators.md#composite-propagator
--------------------------------------------------------------------------------

local _M = {
}

local mt = {
    __index = _M
}

--------------------------------------------------------------------------------
-- Returns a new composite propagator. Propagators must adhere to the API
-- defined in the spec
-- See: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/context/api-propagators.md
--
-- @param propagators
-- @return a new composite propagator
--------------------------------------------------------------------------------
function _M.new(propagators)
    return setmetatable({ propagators = propagators }, mt)
end

--------------------------------------------------------------------------------
-- Uses the propagators to inject context into carrier in sequence.
--
-- @param context      context module
-- @param carrier      carrier (e.g. ngx.req)
--------------------------------------------------------------------------------
function _M:inject(context, carrier)
    for i = 1, #self.propagators do
        self.propagators[i]:inject(context, carrier)
    end
end

--------------------------------------------------------------------------------
-- Uses the propagators to extract context into carrier in sequence.
--
-- @param context      context module
-- @param carrier      carrier (e.g. ngx.req)
--------------------------------------------------------------------------------
function _M:extract(context, carrier)
    local new_ctx = context
    for i = 1, #self.propagators do
        new_ctx = self.propagators[i]:extract(new_ctx, carrier)
    end
    return new_ctx
end

return _M
