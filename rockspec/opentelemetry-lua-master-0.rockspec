package = "opentelemetry-lua"
version = "master-0"
source = {
   url = "git://github.com/yangxikun/opentelemetry-lua",
   branch = "master",
}

description = {
   summary = "The OpenTelemetry Lua SDK. This is repo's default rockspec, which is used to test the HEAD commit.",
   homepage = "https://github.com/yangxikun/opentelemetry-lua",
   license = "Apache License 2.0"
}

dependencies = {
    "lua-protobuf = 0.3.3",
    "lua-resty-http = 0.16.1-0",
    "lua-zlib = 1.2",
}

build = {
   type = "builtin",
   modules = {
       ["opentelemetry.api.trace.span_status"] = "lib/opentelemetry/api/trace/span_status.lua",
       ["opentelemetry.global"] = "lib/opentelemetry/global.lua",
       ["opentelemetry.context"] = "lib/opentelemetry/context.lua",
       ["opentelemetry.attribute"] = "lib/opentelemetry/attribute.lua",
       ["opentelemetry.instrumentation_library"] = "lib/opentelemetry/instrumentation_library.lua",
       ["opentelemetry.resource"] = "lib/opentelemetry/resource.lua",
       ["opentelemetry.metrics_reporter"] = "lib/opentelemetry/metrics_reporter.lua",
       ["opentelemetry.semantic_conventions.trace.aws"] = "lib/opentelemetry/semantic_conventions/trace/aws.lua",
       ["opentelemetry.semantic_conventions.trace.cloudevents"] = "lib/opentelemetry/semantic_conventions/trace/cloudevents.lua",
       ["opentelemetry.semantic_conventions.trace.compatibility"] = "lib/opentelemetry/semantic_conventions/trace/compatibility.lua",
       ["opentelemetry.semantic_conventions.trace.database"] = "lib/opentelemetry/semantic_conventions/trace/database.lua",
       ["opentelemetry.semantic_conventions.trace.exporter"] = "lib/opentelemetry/semantic_conventions/trace/exporter.lua",
       ["opentelemetry.semantic_conventions.trace.faas"] = "lib/opentelemetry/semantic_conventions/trace/faas.lua",
       ["opentelemetry.semantic_conventions.trace.feature"] = "lib/opentelemetry/semantic_conventions/trace/feature.lua",
       ["opentelemetry.semantic_conventions.trace.general"] = "lib/opentelemetry/semantic_conventions/trace/general.lua",
       ["opentelemetry.semantic_conventions.trace.http"] = "lib/opentelemetry/semantic_conventions/trace/http.lua",
       ["opentelemetry.semantic_conventions.trace.messaging"] = "lib/opentelemetry/semantic_conventions/trace/messaging.lua",
       ["opentelemetry.semantic_conventions.trace.rpc"] = "lib/opentelemetry/semantic_conventions/trace/rpc.lua",
       ["opentelemetry.semantic_conventions.trace.trace"] = "lib/opentelemetry/semantic_conventions/trace/trace.lua",
       ["opentelemetry.trace.batch_span_processor"] = "lib/opentelemetry/trace/batch_span_processor.lua",
       ["opentelemetry.trace.event"] = "lib/opentelemetry/trace/event.lua",
       ["opentelemetry.trace.exporter.http_client"] = "lib/opentelemetry/trace/exporter/http_client.lua",
       ["opentelemetry.trace.exporter.circuit"] = "lib/opentelemetry/trace/exporter/circuit.lua",
       ["opentelemetry.trace.exporter.console"] = "lib/opentelemetry/trace/exporter/console.lua",
       ["opentelemetry.trace.exporter.encoder"] = "lib/opentelemetry/trace/exporter/encoder.lua",
       ["opentelemetry.trace.exporter.otlp"] = "lib/opentelemetry/trace/exporter/otlp.lua",
       ["opentelemetry.trace.exporter.pb"] = "lib/opentelemetry/trace/exporter/pb.lua",
       ["opentelemetry.trace.id_generator"] = "lib/opentelemetry/trace/id_generator.lua",
       ["opentelemetry.trace.batch_span_processor"] = "lib/opentelemetry/trace/batch_span_processor.lua",
       ["opentelemetry.trace.simple_span_processor"] = "lib/opentelemetry/trace/simple_span_processor.lua",
       ["opentelemetry.trace.non_recording_span"] = "lib/opentelemetry/trace/non_recording_span.lua",
       ["opentelemetry.trace.noop_span"] = "lib/opentelemetry/trace/noop_span.lua",
       ["opentelemetry.trace.propagation.text_map.trace_context_propagator"] = "lib/opentelemetry/trace/propagation/text_map/trace_context_propagator.lua",
       ["opentelemetry.trace.propagation.text_map.composite_propagator"] = "lib/opentelemetry/trace/propagation/text_map/composite_propagator.lua",
       ["opentelemetry.trace.propagation.text_map.getter"] = "lib/opentelemetry/trace/propagation/text_map/getter.lua",
       ["opentelemetry.trace.propagation.text_map.setter"] = "lib/opentelemetry/trace/propagation/text_map/setter.lua",
       ["opentelemetry.trace.propagation.text_map.noop_propagator"] = "lib/opentelemetry/trace/propagation/text_map/noop_propagator.lua",
       ["opentelemetry.trace.recording_span"] = "lib/opentelemetry/trace/recording_span.lua",
       ["opentelemetry.trace.sampling.always_off_sampler"] = "lib/opentelemetry/trace/sampling/always_off_sampler.lua",
       ["opentelemetry.trace.sampling.always_on_sampler"] = "lib/opentelemetry/trace/sampling/always_on_sampler.lua",
       ["opentelemetry.trace.sampling.parent_base_sampler"] = "lib/opentelemetry/trace/sampling/parent_base_sampler.lua",
       ["opentelemetry.trace.sampling.result"] = "lib/opentelemetry/trace/sampling/result.lua",
       ["opentelemetry.trace.sampling.trace_id_ratio_sampler"] = "lib/opentelemetry/trace/sampling/trace_id_ratio_sampler.lua",
       ["opentelemetry.trace.span_context"] = "lib/opentelemetry/trace/span_context.lua",
       ["opentelemetry.trace.span_kind"] = "lib/opentelemetry/trace/span_kind.lua",
       ["opentelemetry.trace.span_status"] = "lib/opentelemetry/trace/span_status.lua",
       ["opentelemetry.trace.tracer"] = "lib/opentelemetry/trace/tracer.lua",
       ["opentelemetry.trace.tracer_provider"] = "lib/opentelemetry/trace/tracer_provider.lua",
       ["opentelemetry.trace.tracestate"] = "lib/opentelemetry/trace/tracestate.lua",
       ["opentelemetry.baggage"] = "lib/opentelemetry/baggage.lua",
       ["opentelemetry.baggage.propagation.text_map.baggage_propagator"] = "lib/opentelemetry/baggage/propagation/text_map/baggage_propagator.lua",
       ["opentelemetry.util"] = "lib/opentelemetry/util.lua"
   }
}
