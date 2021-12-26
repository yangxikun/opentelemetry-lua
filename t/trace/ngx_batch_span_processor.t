use Test::Nginx::Socket 'no_plan';

log_level('debug');
repeat_each(1);
no_long_string();
no_root_location();
run_tests();

__DATA__

=== TEST 1: ngx_batch_span_processor:on_end
--- config
location = /t {
    content_by_lua_block {
        local ngx_batch_span_processor_new = require("opentelemetry.trace.ngx_batch_span_processor").new
        local span_context_new = require("opentelemetry.trace.span_context").new
        local exporter = {
            export_spans = function(self, spans)
                if #spans == 2 and spans[1].ctx.span_id == "span_id#5" and spans[2].ctx.span_id == "span_id#6" then
                    ngx.say("export 2 spans")
                end
            end
        }

        ngx.say("test opts{max_export_batch_size=2, max_queue_size=6, inactive_timeout=10}, force flush last batch spans")
        local ngx_batch_span_processor = ngx_batch_span_processor_new(exporter, {
            max_export_batch_size = 2, max_queue_size = 6, inactive_timeout = 10})
        for i = 1, 7 do
            ngx_batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id", 0, "trace_state", false)
            })
            ngx_batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id#" .. i, 1, "trace_state", false)
            })
        end

        exporter = {
            export_spans = function(self, spans)
                if #spans == 1 and spans[1].ctx.span_id == "span_id#7" then
                    ngx.say("export 1 spans")
                end
            end
        }
        ngx.say("test opts{max_export_batch_size=2, max_queue_size=7, inactive_timeout=10}, force flush queue")
        local ngx_batch_span_processor = ngx_batch_span_processor_new(exporter, {
            max_export_batch_size = 2, max_queue_size = 7, inactive_timeout = 10})
        for i = 1, 8 do
            ngx_batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id", 0, "trace_state", false)
            })
            ngx_batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id#" .. i, 1, "trace_state", false)
            })
        end

        exporter = {
            expected = {
                export_times = 1,
                spans = {
                    {
                        {span_id = "span_id#1"}, {span_id = "span_id#2"}
                    },
                    {
                        {span_id = "span_id#3"}, {span_id = "span_id#4"}
                    },
                    {
                        {span_id = "span_id#5"}, {span_id = "span_id#6"}
                    },
                }
            },
            export_spans = function(self, spans)
                if self.expected.export_times <= 3 then
                    local export_times = self.expected.export_times
                    if not (#spans == 2 and spans[1].ctx.span_id == self.expected.spans[export_times][1].span_id and
                        spans[2].ctx.span_id == self.expected.spans[export_times][2].span_id) then
                        ngx.log(ngx.ERR, "expect export 2 spans")
                    end
                    self.expected.export_times = export_times + 1
                    return
                end
                if not (#spans == 1 and spans[1].ctx.span_id == "span_id#7") then
                    ngx.log(ngx.ERR, "expect export 1 spans")
                end
            end
        }
        ngx.say("test opts{max_export_batch_size=2, max_queue_size=7, inactive_timeout=1, batch_timeout=5}, export all spans")
        local ngx_batch_span_processor = ngx_batch_span_processor_new(exporter, {
            max_export_batch_size = 2, max_queue_size = 7, inactive_timeout = 1, batch_timeout = 5})
        for i = 1, 7 do
            ngx_batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id", 0, "trace_state", false)
            })
            ngx_batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id#" .. i, 1, "trace_state", false)
            })
        end

        ngx.say("done")
    }
}
--- request
GET /t
--- wait: 6
--- error_code: 200
--- response_body
test opts{max_export_batch_size=2, max_queue_size=6, inactive_timeout=10}, force flush last batch spans
export 2 spans
test opts{max_export_batch_size=2, max_queue_size=7, inactive_timeout=10}, force flush queue
export 1 spans
test opts{max_export_batch_size=2, max_queue_size=7, inactive_timeout=1, batch_timeout=5}, export all spans
done
--- no_error_log
[error]