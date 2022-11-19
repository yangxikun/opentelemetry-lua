local instrumentation_library_new = require("opentelemetry.instrumentation_library").new
local resource = require("opentelemetry.resource")
local attr = require("opentelemetry.attribute")
local tracer_new = require("opentelemetry.trace.tracer").new
local id_generator = require("opentelemetry.trace.id_generator")
local always_on_sampler_new = require("opentelemetry.trace.sampling.always_on_sampler").new
local parent_base_sampler_new = require("opentelemetry.trace.sampling.parent_base_sampler").new

local _M = {
}

local mt = {
    __index = _M
}

------------------------------------------------------------------
-- create a tracer provider.
--
-- @span_processor      [optional] span_processors. Should be table
--                      but we allow for a single span_processor
--                      for backwards compatibility.
-- @opts                [optional] config
--                          opts.sampler: opentelemetry.trace.sampling.*, default parent_base_sampler
--                          opts.resource
-- @return              tracer provider factory
------------------------------------------------------------------
function _M.new(span_processors, opts)
    if not opts then
        opts = {}
    end

    -- Handle nil span processors and users that pass single
    -- span processor not wrapped in a table.
    if span_processors and #span_processors == 0 then
        span_processors = { span_processors }
    elseif span_processors == nil then
        span_processors = {}
    end

    local r = resource.new(attr.string("telemetry.sdk.language", "lua"),
        attr.string("telemetry.sdk.name", "opentelemetry-lua"),
        attr.string("telemetry.sdk.version", "0.1.1"))

    local self = {
        span_processors = span_processors,
        sampler = opts.sampler or parent_base_sampler_new(always_on_sampler_new()),
        resource = resource.merge(opts.resource, r),
        id_generator = id_generator,
        named_tracer = {},
    }
    return setmetatable(self, mt)
end

------------------------------------------------------------------
-- create a tracer.
--
-- @name            tracer name
-- @opts            [optional] config
--                      opts.version: specifies the version of the instrumentation library
--                      opts.schema_url: specifies the Schema URL that should be recorded in the emitted telemetry.
-- @return          tracer
------------------------------------------------------------------
function _M.tracer(self, name, opts)
    if not opts then
        opts = {
            version = "",
            schema_url = "",
        }
    end
    local key = name .. opts.version .. opts.schema_url
    local tracer = self.named_tracer[key]
    if tracer then
        return tracer
    end

    self.named_tracer[key] = tracer_new(self, instrumentation_library_new(name, opts.version, opts.schema_url))
    return self.named_tracer[key]
end

function _M.force_flush(self)
    for _, sp in ipairs(self.span_processors) do
        sp:force_flush()
    end
end

function _M.shutdown(self)
    for _, sp in ipairs(self.span_processors) do
        sp:shutdown()
    end
end

function _M.register_span_processor(self, sp)
    table.insert(self.span_processors, sp)
end

function _M.set_span_processors(self, ...)
    self.span_processors = { ... }
end

return _M
