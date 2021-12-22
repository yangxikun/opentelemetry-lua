package = "opentelemetry-lua"
version = "master-0"
source = {
   url = "git://github.com/yangxikun/opentelemetry-lua",
   branch = "master",
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
       ["opentelemetry.context"] = "lib/opentelemetry/context.lua",
       ["opentelemetry.ngx_context_storage"] = "lib/opentelemetry/ngx_context_storage.lua",
       ["opentelemetry.attribute"] = "lib/opentelemetry/attribute.lua",
       ["opentelemetry.instrumentation_library"] = "lib/opentelemetry/instrumentation_library.lua",
       ["opentelemetry.resource"] = "lib/opentelemetry/resource.lua",
       ["opentelemetry.trace.batch_span_processor"] = "lib/opentelemetry/trace/batch_span_processor.lua",
       ["opentelemetry.trace.event"] = "lib/opentelemetry/trace/event.lua",
       ["opentelemetry.trace.exporter.envoy_http_client"] = "lib/opentelemetry/trace/exporter/envoy_http_client.lua",
       ["opentelemetry.trace.exporter.ngx_http_client"] = "lib/opentelemetry/trace/exporter/ngx_http_client.lua",
       ["opentelemetry.trace.exporter.otlp"] = "lib/opentelemetry/trace/exporter/otlp.lua",
       ["opentelemetry.trace.exporter.pb"] = "lib/opentelemetry/trace/exporter/pb.lua",
       ["opentelemetry.trace.id_generator"] = "lib/opentelemetry/trace/id_generator.lua",
       ["opentelemetry.trace.ngx_batch_span_processor"] = "lib/opentelemetry/trace/ngx_batch_span_processor.lua",
       ["opentelemetry.trace.non_recording_span"] = "lib/opentelemetry/trace/non_recording_span.lua",
       ["opentelemetry.trace.propagation.envoy_carrier"] = "lib/opentelemetry/trace/propagation/envoy_carrier.lua",
       ["opentelemetry.trace.propagation.ngx_carrier"] = "lib/opentelemetry/trace/propagation/ngx_carrier.lua",
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
