use Test::Nginx::Socket 'no_plan';

our $HttpConfig = qq{
    lua_shared_dict queue 1m;
};

log_level('debug');
repeat_each(1);
no_long_string();
no_root_location();
run_tests();

__DATA__

=== TEST 1: batch_span_processor:on_end, flush 2 spans each time for the first three batch export, and 1 span in the last export
--- http_config eval: $::HttpConfig
--- config

location = /t {
    content_by_lua_block {
        local batch_span_processor_new = require("opentelemetry.trace.batch_span_processor").new
        local span_context_new = require("opentelemetry.trace.span_context").new
        local recording_span_new = require("opentelemetry.trace.recording_span").new
        local tp = require("opentelemetry.trace.tracer_provider").new()
        local tracer = tp:tracer("opentelemetry-lua")
        local exporter = {
            export_times = 0,
            export_spans = function(self, spans)
                self.export_times = self.export_times + 1
                local span_count = #spans
                if span_count ~= 2 and self.export_times ~= 4 then
                    ngx.log(ngx.ERR, "expect export 2 spans, actual: ", span_count, ", export_times: ", self.export_times)
                end
                if span_count ~= 1 and self.export_times == 4 then
                   ngx.log(ngx.ERR, "expect export 1 spans, actual: ", span_count, ", export_times: ", self.export_times)
                end
            end
        }

        local batch_span_processor = batch_span_processor_new(exporter, {
            max_export_batch_size = 2, inactive_timeout = 2, batch_timeout = 2, shared_dict_queue = "queue"})
        for i = 1, 7 do
            batch_span_processor:on_end(recording_span_new(
                tracer, span_context_new(),
                span_context_new("trace_id", "span_id", 0, "trace_state", false),
                nil, {}
            ))
            batch_span_processor:on_end(recording_span_new(
                tracer, span_context_new(),
                span_context_new("trace_id", "span_id#" .. i, 1, "trace_state", false),
                nil, {}
            ))
        end

        ngx.sleep(5)

        if exporter.export_times ~= 4 then
            ngx.log(ngx.ERR, "expect export_times == 4, actual: ", exporter.export_times)
        end

        ngx.say("done")
    }
}
--- request
GET /t
--- timeout: 6
--- error_code: 200
--- response_body
done
--- no_error_log
[error]
