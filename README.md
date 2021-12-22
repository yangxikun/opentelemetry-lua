# opentelemetry-lua

OpenTelemetry-Lua is the lua implementation of [OpenTelemetry](https://opentelemetry.io/).
It provides a set of APIs to directly measure performance and behavior of your software and send this data to observability platforms.

## Project Status

This project currently lives in a dev status.

## Getting Started

```lua
    local tracer_provider_new = require("opentelemetry.trace.tracer_provider").new
    local ngx_batch_span_processor_new = require("opentelemetry.trace.ngx_batch_span_processor").new
    local span_kind = require("opentelemetry.trace.span_kind")
    local span_status = require("opentelemetry.trace.span_status")
    local otlp_exporter_new = require("opentelemetry.trace.exporter.otlp").new
    local resource_new = require("opentelemetry.resource").new
    local attr = require("opentelemetry.attribute")
    local context = require("opentelemetry.context").new(ngx_context_storage)
    local trace_context = require("opentelemetry.trace.propagation.trace_context")
    local carrier_new = require("opentelemetry.trace.propagation.ngx_carrier").new
    local exporter_client_new = require("opentelemetry.trace.exporter.ngx_http_client").new

    -- create exporter
    local otlp_exporter = otlp_exporter_new(exporter_client_new("192.168.8.211:4317", 3))
    -- create span processor
    local ngx_batch_span_processor = ngx_batch_span_processor_new(otlp_exporter)
    -- create tracer provider with resource
    local tp = tracer_provider_new({ngx_batch_span_processor},
            {resource = resource_new(attr.string("service.name", "openresty"), attr.int("attr_int", 100))})
    -- create tracer
    local tracer = tp:tracer("opentelemetry-lua")

    -- propagate upstream trace context, and start a span with attributes
    local context, span = tracer:start(trace_context.extract(context, carrier_new()), "access_by_lua_block", {
        kind = span_kind.internal,
        attributes = {attr.double("attr_double", 10.24), attr.bool("attr_bool", true)},
    })

    -- associates a Context with the caller's current execution unit
    context:attach()

    -- inject trace context
    trace_context.inject(context, carrier_new())

    -- start sub span
    local sub_context, sub_span = tracer:start(context, "sub-span")
    -- record error
    sub_span:record_error("this is err")
    -- set status
    sub_span:set_status(span_status.error, "set status err")
    -- add an event
    sub_span:add_event("event1", {attributes = {attr.string("attr_string", "header_filter_by_lua_block")}})

    sub_span:finish();
    span:finish()
```
