use Test::Nginx::Socket 'no_plan';

log_level('debug');
repeat_each(1);
no_long_string();
no_root_location();
run_tests();

__DATA__

=== TEST 1: batch_span_processor:on_end
--- config
location = /t {
    content_by_lua_block {
        local batch_span_processor_new = require("opentelemetry.trace.batch_span_processor").new
        local span_context_new = require("opentelemetry.trace.span_context").new
        local exporter = {
            export_spans = function(self, spans)
                if #spans == 10 then
                    ngx.say("export 10 spans")
                end
            end
        }

        ngx.say("test max_export_batch_size = 10")
        local batch_span_processor = batch_span_processor_new(exporter, {max_export_batch_size = 10})
        for i = 1, 10 do
            batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id", 0, "trace_state", false)
            })
            batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id", 1, "trace_state", false)
            })
        end

        ngx.say("done")
    }
}
--- request
GET /t
--- error_code: 200
--- response_body
test max_export_batch_size = 10
export 10 spans
done
--- no_error_log
[error]