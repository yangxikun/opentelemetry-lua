local instrumentation_library_new = require("opentelemetry.instrumentation_library").new
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
-- @span_processors     a list of span_processor
-- @opts                [optional] config
--                          opts.sampler: see sampler dir
--                          opts.resource
-- @return              tracer provider factory
------------------------------------------------------------------
function _M.new(span_processors, opts)
    local self = {
        span_processors = span_processors,
        sampler = opts.sampler and opts.sampler or parent_base_sampler_new(always_on_sampler_new()),
        resource = opts.resource,
        id_generator = id_generator,
        named_tracer = {},
    }
    return setmetatable(self, mt)
end

------------------------------------------------------------------
-- create a tracer.
--
-- @name     name
-- @opts                optional config
--                          opts.version, specifies the version of the instrumentation library
--                          opts.schema_url, specifies the Schema URL that should be recorded in the emitted telemetry.
-- @return              tracer
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

return _M