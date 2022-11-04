local bit = require("bit")
local span_context_new       = require("opentelemetry.trace.span_context").new
local non_recording_span_new = require("opentelemetry.trace.non_recording_span").new
local recording_span_new     = require("opentelemetry.trace.recording_span").new
local span_kind              = require("opentelemetry.trace.span_kind")

local _M = {
}

local mt = {
    __index = _M
}

function _M.new(provider, il)
    local self = {
        provider = provider,
        il = il
    }
    return setmetatable(self, mt)
end

local function new_span(self, context, name, config)
    local span_context = context:span_context()
    if not config then
        config = {}
    end
    local trace_id = span_context.trace_id
    local span_id
    if trace_id then
        span_id = self.provider.id_generator.new_span_id(trace_id)
    else
        trace_id, span_id = self.provider.id_generator.new_ids()
    end

    local sampling_result = self.provider.sampler:should_sample({
        parent_ctx     = context,
        trace_id       = trace_id,
        name           = name,
        kind           = span_kind.validate(config.kind),
        attributes     = config.attributes,
    })

    local trace_flags = span_context.trace_flags and span_context.trace_flags or 0
    if sampling_result:is_sampled() then
        trace_flags = bit.bor(trace_flags, 1)
    else
        trace_flags = bit.band(trace_flags, 0)
    end
    local new_span_context = span_context_new(trace_id, span_id, trace_flags, sampling_result.trace_state, false)

    local span
    if not sampling_result:is_recording() then
        span = non_recording_span_new(self, new_span_context)
    else
        span = recording_span_new(self, span_context, new_span_context, name, config)
    end

    return context:with_span(span), span
end

------------------------------------------------------------------
-- create a span.
--
-- @context             context with parent span
-- @span_name           span name
-- @span_start_config   [optional]
--                          span_start_config.kind: opentelemetry.trace.span_kind.*
--                          span_start_config.attributes: a list of attribute
-- @return
--                      context: new context with span
--                      span
------------------------------------------------------------------
function _M.start(self, context, span_name, span_start_config)
    return new_span(self, context, span_name, span_start_config)
end

return _M
