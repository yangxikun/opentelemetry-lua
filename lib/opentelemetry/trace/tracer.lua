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

------------------------------------------------------------------
-- create a tracer provider.
--
-- @span_ctx            current span context
-- @span_name           new span name
-- @span_start_config   [optional]
--                          span_start_config.kind: see span_kind.lua
--                          span_start_config.attributes: a list of attribute
-- @return              tracer provider factory
------------------------------------------------------------------
function _M.start(self, span_ctx, span_name, span_start_config)
    return self:_new_span(span_ctx, span_name, span_start_config)
end

function _M._new_span(self, ctx, name, config)
    if not config then
        config = {}
    end
    local trace_id = ctx.trace_id
    local span_id
    if trace_id then
        span_id = self.provider.id_generator.new_span_id(trace_id)
    else
        trace_id, span_id = self.provider.id_generator.new_ids()
    end

    local sampling_result = self.provider.sampler:should_sample({
        parent_ctx     = ctx,
        trace_id       = race_id,
        name           = name,
        kind           = span_kind.validate(config.kind),
        attributes     = config.attributes,
    })

    local trace_flags = ctx.trace_flags and ctx.trace_flags or 0
    if sampling_result:is_sampled() then
        trace_flags = bit.bor(trace_flags, 1)
    else
        trace_flags = bit.clear(trace_flags, 1)
    end
    local new_ctx = span_context_new(trace_id, span_id, trace_flags, sampling_result.trace_state, false)

    if not sampling_result:is_recording() then
        return non_recording_span_new(self, new_ctx)
    end

    return recording_span_new(self, ctx, new_ctx, name, config)
end

return _M