package = "opentelemetry-lua"
version = "0.1-3"
source = {
   url = "git://github.com/yangxikun/opentelemetry-lua",
   tag = "v0.1.3"
}

description = {
   summary = "The OpenTelemetry Lua SDK",
   homepage = "https://github.com/yangxikun/opentelemetry-lua",
   license = "Apache License 2.0"
}

dependencies = {
    "lua-protobuf = 0.3.3",
    "api7-lua-resty-http = 0.2.0",
}

build = {
   type = "builtin",
   modules = {
       ["opentelemetry.global"] = "lib/opentelemetry/global.lua",
       ["opentelemetry.context"] = "lib/opentelemetry/context.lua",
       ["opentelemetry.context_storage"] = "lib/opentelemetry/context_storage.lua",
       ["opentelemetry.attribute"] = "lib/opentelemetry/attribute.lua",
       ["opentelemetry.instrumentation_library"] = "lib/opentelemetry/instrumentation_library.lua",
       ["opentelemetry.resource"] = "lib/opentelemetry/resource.lua",
       ["opentelemetry.trace.batch_span_processor"] = "lib/opentelemetry/trace/batch_span_processor.lua",
       ["opentelemetry.trace.event"] = "lib/opentelemetry/trace/event.lua",
       ["opentelemetry.trace.exporter.http_client"] = "lib/opentelemetry/trace/exporter/http_client.lua",
       ["opentelemetry.trace.exporter.otlp"] = "lib/opentelemetry/trace/exporter/otlp.lua",
       ["opentelemetry.trace.exporter.pb"] = "lib/opentelemetry/trace/exporter/pb.lua",
       ["opentelemetry.trace.id_generator"] = "lib/opentelemetry/trace/id_generator.lua",
       ["opentelemetry.trace.batch_span_processor"] = "lib/opentelemetry/trace/batch_span_processor.lua",
       ["opentelemetry.trace.non_recording_span"] = "lib/opentelemetry/trace/non_recording_span.lua",
       ["opentelemetry.trace.noop_span"] = "lib/opentelemetry/trace/noop_span.lua",
       ["opentelemetry.trace.propagation.carrier"] = "lib/opentelemetry/trace/propagation/carrier.lua",
       ["opentelemetry.trace.propagation.trace_context"] = "lib/opentelemetry/trace/propagation/trace_context.lua",
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
       ["opentelemetry.util"] = "lib/opentelemetry/util.lua"
   }
}