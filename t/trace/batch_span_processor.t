use Test::Nginx::Socket 'no_plan';

log_level('debug');
repeat_each(1);
no_long_string();
no_root_location();
run_tests();

__DATA__

=== TEST 1: batch_span_processor:on_end, flush 3 batch spans, and drop 1 span
--- config
location = /t {
    content_by_lua_block {
        local batch_span_processor_new = require("opentelemetry.trace.batch_span_processor").new
        local span_context_new = require("opentelemetry.trace.span_context").new
        local exporter = {
            export_times = 0,
            export_spans = function(self, spans)
                if not (#spans == 2 and spans[1].ctx.span_id == "span_id#" .. (2*self.export_times+1) and
                    spans[2].ctx.span_id == "span_id#" .. (2*self.export_times+2)) then
                    ngx.log(ngx.ERR, "expect export 2 spans")
                end
                self.export_times = self.export_times + 1
            end
        }

        local batch_span_processor = batch_span_processor_new(exporter, {
            max_export_batch_size = 2, max_queue_size = 6, inactive_timeout = 1, batch_timeout = 2})
        for i = 1, 7 do
            batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id", 0, "trace_state", false)
            })
            batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id#" .. i, 1, "trace_state", false)
            })
        end

        ngx.sleep(4)

        if exporter.export_times ~= 3 then
            ngx.log(ngx.ERR, "expect export_times == 3")
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
--- grep_error_log eval
qr/queue is full, drop span: trace_id = trace_id span_id = span_id#7/
--- grep_error_log_out
queue is full, drop span: trace_id = trace_id span_id = span_id#7



=== TEST 2: batch_span_processor:on_end, force flush 3 batch spans, then flush 1 span
--- config
location = /t {
    content_by_lua_block {
        local batch_span_processor_new = require("opentelemetry.trace.batch_span_processor").new
        local span_context_new = require("opentelemetry.trace.span_context").new
        local exporter = {
            export_times = 0,
            export_spans = function(self, spans)
                if #spans == 1 then
                    if not (self.export_times == 3 and spans[1].ctx.span_id == "span_id#" .. (2*self.export_times+1)) then
                        ngx.log(ngx.ERR, "expect export 1 spans")
                    end
                    self.export_times = self.export_times + 1
                    return
                end
                if not (#spans == 2 and spans[1].ctx.span_id == "span_id#" .. (2*self.export_times+1) and
                    spans[2].ctx.span_id == "span_id#" .. (2*self.export_times+2)) then
                    ngx.log(ngx.ERR, "expect export 2 spans")
                end
                self.export_times = self.export_times + 1
            end
        }

        local batch_span_processor = batch_span_processor_new(exporter, {
            drop_on_queue_full = false,
            max_export_batch_size = 2, max_queue_size = 6, inactive_timeout = 1, batch_timeout = 2})
        for i = 1, 7 do
            batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id", 0, "trace_state", false)
            })
            batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id#" .. i, 1, "trace_state", false)
            })
        end

        ngx.sleep(4)

        if exporter.export_times ~= 4 then
            ngx.log(ngx.ERR, "expect export_times == 4")
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
--- grep_error_log eval
qr/queue is full/
--- grep_error_log_out



=== TEST 3: batch_span_processor:on_end, is_timer_running = false
--- config
location = /t {
    content_by_lua_block {
        local batch_span_processor_new = require("opentelemetry.trace.batch_span_processor").new
        local span_context_new = require("opentelemetry.trace.span_context").new
        local exporter = {
            export_times = 0,
            export_spans = function(self, spans)
                if not (#spans == 2 and spans[1].ctx.span_id == "span_id#" .. (2*self.export_times+1) and
                    spans[2].ctx.span_id == "span_id#" .. (2*self.export_times+2)) then
                    ngx.log(ngx.ERR, "expect export 2 spans")
                end
                self.export_times = self.export_times + 1
            end
        }

        local batch_span_processor = batch_span_processor_new(exporter, {
            max_export_batch_size = 2, max_queue_size = 6, inactive_timeout = 1, batch_timeout = 2})
        for i = 1, 4 do
            batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id", 0, "trace_state", false)
            })
            batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id#" .. i, 1, "trace_state", false)
            })
        end

        ngx.sleep(1);

        if exporter.export_times ~= 2 then
            ngx.log(ngx.ERR, "expect export_times == 2")
        end

        if batch_span_processor.is_timer_running ~= false then
            ngx.log(ngx.ERR, "expect batch_span_processor.is_timer_running == false")
        end

        ngx.say("done")
    }
}
--- request
GET /t
--- wait: 1
--- error_code: 200
--- response_body
done
--- no_error_log
[error]
--- grep_error_log eval
qr/queue is full/
--- grep_error_log_out



=== TEST 4: batch_span_processor:on_end, timeout batch and is_timer_running = false
--- config
location = /t {
    content_by_lua_block {
        local batch_span_processor_new = require("opentelemetry.trace.batch_span_processor").new
        local span_context_new = require("opentelemetry.trace.span_context").new
        local exporter = {
            export_times = 0,
            export_spans = function(self, spans)
                if not (#spans == 1 and spans[1].ctx.span_id == "span_id#1") then
                    ngx.log(ngx.ERR, "expect export 1 spans")
                end
                self.export_times = self.export_times + 1
            end
        }

        local batch_span_processor = batch_span_processor_new(exporter, {
            max_export_batch_size = 2, max_queue_size = 6, inactive_timeout = 1, batch_timeout = 2})
        batch_span_processor:on_end({
            ctx = span_context_new("trace_id", "span_id#1", 1, "trace_state", false)
        })

        ngx.sleep(3);

        if exporter.export_times ~= 1 then
            ngx.log(ngx.ERR, "expect export_times == 1")
        end

        if batch_span_processor.is_timer_running ~= false then
            ngx.log(ngx.ERR, "expect batch_span_processor.is_timer_running == false")
        end

        ngx.say("done")
    }
}
--- request
GET /t
--- timeout: 4
--- error_code: 200
--- response_body
done
--- no_error_log
[error]
--- grep_error_log eval
qr/queue is full/
--- grep_error_log_out


=== TEST 5: batch_span_processor:on_end, force flush
--- config
location = /t {
    content_by_lua_block {
        local batch_span_processor_new = require("opentelemetry.trace.batch_span_processor").new
        local span_context_new = require("opentelemetry.trace.span_context").new
        local exporter = {
            export_times = 0,
            export_spans = function(self, spans)
                if #spans == 1 then
                    if not (self.export_times == 2 and spans[1].ctx.span_id == "span_id#" .. (2*self.export_times+1)) then
                        ngx.log(ngx.ERR, "expect export 1 spans")
                    end
                    self.export_times = self.export_times + 1
                    return
                end
                if not (#spans == 2 and spans[1].ctx.span_id == "span_id#" .. (2*self.export_times+1) and
                    spans[2].ctx.span_id == "span_id#" .. (2*self.export_times+2)) then
                    ngx.log(ngx.ERR, "expect export 2 spans")
                end
                self.export_times = self.export_times + 1
            end
        }

        local batch_span_processor = batch_span_processor_new(exporter, {
            max_export_batch_size = 2, max_queue_size = 6, inactive_timeout = 10, batch_timeout = 20})
        for i = 1, 5 do
            batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id", 0, "trace_state", false)
            })
            batch_span_processor:on_end({
                ctx = span_context_new("trace_id", "span_id#" .. i, 1, "trace_state", false)
            })
        end
        batch_span_processor:force_flush()

        ngx.sleep(1);

        if exporter.export_times ~= 3 then
            ngx.log(ngx.ERR, "expect export_times == 3")
        end

        if batch_span_processor.is_timer_running ~= true then
            ngx.log(ngx.ERR, "expect batch_span_processor.is_timer_running == true")
        end

        if #batch_span_processor.batch_to_process ~=0 or #batch_span_processor.queue ~=0 then
            ngx.log(ngx.ERR, "expect export all spans")
        end

        ngx.say("done")
    }
}
--- request
GET /t
--- timeout: 4
--- error_code: 200
--- response_body
done
--- no_error_log
[error]
--- grep_error_log eval
qr/queue is full/
--- grep_error_log_out


=== TEST 6: batch_span_processor:on_end, batch timeout when queue is empty
--- ONLY
--- config
location = /t {
    content_by_lua_block {
        local batch_span_processor_new = require("opentelemetry.trace.batch_span_processor").new
        local span_context_new = require("opentelemetry.trace.span_context").new
        local exporter = {
            export_times = 0,
            export_spans = function(self, spans)
                if #spans ~= 2 then
                    ngx.log(ngx.ERR, "expect export 2 spans, got ", #spans)
                end
                self.export_times = self.export_times + 1
            end
        }

        local batch_span_processor = batch_span_processor_new(exporter, {
            max_export_batch_size = 2, max_queue_size = 6, inactive_timeout = 1, batch_timeout = 2})
        batch_span_processor:on_end({
            ctx = span_context_new("trace_id", "span_id#1", 1, "trace_state", false)
        })
        ngx.sleep(1);

        batch_span_processor:on_end({
            ctx = span_context_new("trace_id", "span_id#2", 1, "trace_state", false)
        })
        ngx.sleep(1);

        if exporter.export_times ~= 1 then
            ngx.log(ngx.ERR, "expect export_times == 1")
        end

        if #batch_span_processor.batch_to_process ~=0 or #batch_span_processor.queue ~=0 then
            ngx.log(ngx.ERR, "expect export all spans")
        end

        ngx.say("done")
    }
}
--- request
GET /t
--- timeout: 4
--- error_code: 200
--- response_body
done
--- no_error_log
[error]
--- grep_error_log eval
qr/queue is full/
--- grep_error_log_out
