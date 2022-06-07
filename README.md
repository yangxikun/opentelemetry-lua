opentelemetry-lua
==========

OpenTelemetry-Lua is the lua implementation of [OpenTelemetry](https://opentelemetry.io/).
It provides a set of APIs to directly measure performance and behavior of your software and send this data to observability platforms.

# Project Status

This project currently lives in a alpha status.

# INSTALL

## Use luarocks

git clone this project, then run `luarocks make` in  project root directory.

# Develop

- set up environment: `make openresty-build && make openresty-dev`
- test e2e: `make openresty-test-e2e`
- test trace context: `openresty-test-e2e-trace-context`
- run unit test: `make openresty-unit-test`

# APIs

This lib is designed for Nginx+LUA/OpenResty ecosystems.

## util

Set the nano time func used by this lib to set span start/end time.

```lua
local util = require("opentelemetry.util")
-- default
util.time_nano = util.gettimeofday
-- ngx.now
util.time_nano = util.time_nano
```

## global

Set/Get the global tracer provider.

```lua
local global = require("opentelemetry.global")
-- tp is a tracer provider instance
global.set_tracer_provider(tp)
local tp2 = global.get_tracer_provider()
local tracer = global.tracer(name, opts)
```

## Context

Partially implement of specification: [https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/context/context.md](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/context/context.md).

### Create a Context

```lua
local context_storage = require("opentelemetry.context_storage")
-- context_storage is a centralized storage in request scope, so you can get current Context in different request phase.
local context = require("opentelemetry.context").new(context_storage)
```

### Attach/Detach Context

```lua
-- Associates a Context with the caller's current execution unit, so you can use context:current() to retrieve it.
context:attach()
-- Resets the Context associated with the caller's current execution unit to the value it had before attaching a specified Context.
context:detach()
```

### Get current Context

```lua
local cur_context = context:current()
```

### Get current span/span_context

```lua
local cur_span = context:span()
local cur_span_context = context:span_context()
```

## Attribute

```lua
local attr = require("opentelemetry.attribute")
-- string attribute
attr.string("service.name", "openresty")
-- int attribute
attr.int("attr_int", 100)
-- double attribute
attr.double("attr_double", 10.24)
-- bool attribute
attr.bool("attr_bool", true)
```

## Resource

Partially implement of specification: [https://github.com/open-telemetry/opentelemetry-specification/blob/01e62674c0ac23076736459efd0c05316f84cd6f/specification/resource/sdk.md](https://github.com/open-telemetry/opentelemetry-specification/blob/01e62674c0ac23076736459efd0c05316f84cd6f/specification/resource/sdk.md)

### Create a resource

```lua
local attr = require("opentelemetry.attribute")
local resource_new = require("opentelemetry.resource").new

local resource = resource_new(attr.string("service.name", "openresty"), attr.int("attr_int", 100),
        attr.double("attr_double", 10.24), attr.bool("attr_bool", true))
```

### Get attributes

```lua
resource:attributes()
```

## Trace

Partially implement of specification:

- [https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/sdk.md](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/sdk.md)
- [https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/api.md](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/api.md)

### TracerProvider

```lua
local attr = require("opentelemetry.attribute")
local resource_new = require("opentelemetry.resource").new
local always_on_sampler = require("opentelemetry.trace.sampling.always_on_sampler").new()
local tp_new = require("opentelemetry.trace.tracer_provider").new
------------------------------------------------------------------
-- create a tracer provider.
--
-- @span_processor      [optional] span_processor
-- @opts                [optional] config
--                          opts.sampler: opentelemetry.trace.sampling.*, default parent_base_sampler
--                          opts.resource
-- @return              tracer provider factory
------------------------------------------------------------------
local tp = tp_new(span_processor, {
    sampler = always_on_sampler,
    resource = resource_new(attr.string("service.name", "openresty"), attr.int("attr_int", 100)),
})

------------------------------------------------------------------
-- create a tracer.
--
-- @name            tracer name
-- @opts            [optional] config
--                      opts.version: specifies the version of the instrumentation library
--                      opts.schema_url: specifies the Schema URL that should be recorded in the emitted telemetry.
-- @return          tracer
------------------------------------------------------------------
local tracer = tp:tracer("opentelemetry-lua", opts)

-- force all processors export spans
tp:force_flush()

-- force all processors export spans and shutdown processors
tp:shutdown()

-- append processor
tp:register_span_processor(span_processor)

-- set processors
tp:set_span_processors(span_processor1, span_processor2)
```

### Span Processor

`opentelemetry.trace.batch_span_processor` will store spans in a queue, and start a background timer to export spans.

```lua
local batch_span_processor_new = require("opentelemetry.trace.batch_span_processor").new

------------------------------------------------------------------
-- create a batch span processor.
--
-- @exporter            opentelemetry.trace.exporter.oltp
-- @opts                [optional]
--                          opts.drop_on_queue_full: if true, drop span when queue is full, otherwise force process batches, default true
--                          opts.max_queue_size: maximum queue size to buffer spans for delayed processing, default 2048
--                          opts.batch_timeout: maximum duration for constructing a batch, default 5s
--                          opts.inactive_timeout: maximum duration for processing batches, default 2s
--                          opts.max_export_batch_size: maximum number of spans to process in a single batch, default 256
-- @return              processor
------------------------------------------------------------------
local batch_span_processor = batch_span_processor_new(exporter, {
    drop_on_queue_full = false, max_queue_size = 1024, batch_timeout = 3, inactive_timeout = 1, max_export_batch_size = 10
})
```

### Exporter

Send spans to opentelemetry collector in protobuf format.

```lua
local otlp_exporter_new = require("opentelemetry.trace.exporter.otlp").new
local http_client_new = require("opentelemetry.trace.exporter.http_client").new

------------------------------------------------------------------
-- create a http client used by exporter.
--
-- @address             opentelemetry collector: host:port
-- @timeout             export request timeout
-- @headers             export request headers
-- @return              http client
------------------------------------------------------------------
local client = http_client_new("127.0.0.1:4317", 3, {header_key = "header_val"})

local exporter = otlp_exporter_new(client)
```

### Sampling

```lua
-- sampling all spans
local always_on_sampler = require("opentelemetry.trace.sampling.always_on_sampler").new()

-- sampling non spans
local always_off_sampler = require("opentelemetry.trace.sampling.always_off_sampler").new()

------------------------------------------------------------------
-- a composite sampler which behaves differently,
-- based on the parent of the span. If the span has no parent,
-- the root(Sampler) is used to make sampling decision. If the span has
-- a parent, depending on whether the parent is sampled.
--
-- @root                sampler
-- @return              sampler
------------------------------------------------------------------
local parent_base_sampler = require("opentelemetry.trace.sampling.parent_base_sampler").new(always_on_sampler)

------------------------------------------------------------------
-- samples a given fraction of traces. Fractions >= 1 will
-- always sample. Fractions < 0 are treated as zero. To respect the
-- parent trace's sampled_flag, the trace_id_ratio_based sampler should be used
-- as a delegate of a parent base sampler.
--
-- @return              sampler
------------------------------------------------------------------
local trace_id_ratio_sampler = require("opentelemetry.trace.sampling.trace_id_ratio_sampler").new(0.5)
```

### Tracer

```lua
local span_kind = require("opentelemetry.trace.span_kind")
local attr = require("opentelemetry.attribute")

------------------------------------------------------------------
-- create a span.
--
-- @span_ctx            context with parent span
-- @span_name           span name
-- @span_start_config   [optional]
--                          span_start_config.kind: opentelemetry.trace.span_kind.*
--                          span_start_config.attributes: a list of attribute
-- @return              
--                      context: new context with span
--                      span
------------------------------------------------------------------
local context, span = tracer:start(context, name, {kind = span_kind.server, attributes = {attr.string("user", "foo")}})
```

### Trace Context

Implement of specification: [https://www.w3.org/TR/trace-context/](https://www.w3.org/TR/trace-context/)

```lua
local context_storage = require("opentelemetry.context_storage")
local context = require("opentelemetry.context").new(context_storage)
local trace_context = require("opentelemetry.trace.propagation.trace_context")
local carrier_new = require("opentelemetry.trace.propagation.carrier").new

------------------------------------------------------------------
-- extract span context from upstream request.
--
-- @context             current context
-- @carrier             get traceparent and tracestate
-- @return              new context
------------------------------------------------------------------
local context = trace_context.extract(context, carrier_new())
```

### Span

```lua
local span_kind = require("opentelemetry.trace.span_kind")
local attr = require("opentelemetry.attribute")
local span_status = require("opentelemetry.trace.span_status")
local context, span = tracer:start(context, name, {kind = span_kind.server, attributes = {attr.string("user", "foo")}})

-- get span context
local span_context = span:context()

-- is recording
local ok = span:is_recording()

------------------------------------------------------------------
-- set span status.
--
-- @code             see opentelemetry.trace.span_status.*
-- @message          error msg
------------------------------------------------------------------
span:set_status(span_status.error, "error msg")

-- set attributes
span:set_attributes(attr.string("comapny", "bar"))

-- add a error event
span:record_error("error msg")

------------------------------------------------------------------
-- add a custom event
--
-- @opts           [optional]
--                      opts.attributes: a list of attribute
------------------------------------------------------------------
span:add_event(name, {attributes = {attr.string("type", "job")}})

-- get tracer provider
local tp = span:tracer_provider()
```
