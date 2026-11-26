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

        if #batch_span_processor.batches_to_process ~=0 or #batch_span_processor.queue ~=0 then
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

        if #batch_span_processor.batches_to_process ~=0 or #batch_span_processor.queue ~=0 then
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


=== TEST 7: export from a timer when spans end in restricted phases during worker exit
--- http_config
init_by_lua_block {
    local timer_at = ngx.timer.at
    ngx.timer.at = function(delay, ...)
        if delay > 0 then
            return nil, "process exiting"
        end
        return timer_at(delay, ...)
    end
    require("opentelemetry.trace.batch_span_processor")
    ngx.timer.at = timer_at
    ngx.worker.exiting = function() return true end
}
--- config
location = /t {
    content_by_lua_block {
        local processor = require("opentelemetry.trace.batch_span_processor")
        local span_context = require("opentelemetry.trace.span_context")
        local exporter = {
            export_spans = function(_, spans)
                ngx.socket.tcp()
                ngx.log(ngx.NOTICE, "exported ", spans[1].ctx.span_id, " in ", ngx.get_phase())
                return true
            end
        }
        ngx.ctx.processor = processor.new(exporter)
        ngx.ctx.body_span = { ctx = span_context.new("trace_id", "body_filter", 1) }
        ngx.ctx.log_span = { ctx = span_context.new("trace_id", "log", 1) }
        ngx.say("done")
    }
    body_filter_by_lua_block {
        if ngx.arg[2] then
            ngx.ctx.processor:on_end(ngx.ctx.body_span)
        end
    }
    log_by_lua_block {
        ngx.ctx.processor:on_end(ngx.ctx.log_span)
    }
}
--- request
GET /t
--- response_body
done
--- wait: 0.1
--- error_log
exported body_filter in timer
exported log in timer
--- no_error_log
[error]



=== TEST 8: account for full and partial batches when the exit timer cannot be created
--- config
location = /t {
    content_by_lua_block {
        local timer_at = ngx.timer.at
        ngx.timer.at = function(delay)
            if ngx.worker.exiting() and delay > 0 then
                return nil, "process exiting"
            end
            return nil, "too many pending timers"
        end
        local processor = require("opentelemetry.trace.batch_span_processor")
        ngx.timer.at = timer_at

        local global = require("opentelemetry.global")
        local metrics = global.metrics_reporter
        global.set_metrics_reporter(setmetatable({
            add_to_counter = function(_, metric, count, labels)
                ngx.log(ngx.NOTICE, metric, " ", count, " ", labels.reason)
            end,
        }, { __index = metrics }))
        local exporter = {
            export_spans = function()
                error("export called without a timer")
            end
        }
        local bsp = processor.new(exporter, { max_export_batch_size = 2 })
        local ctx = require("opentelemetry.trace.span_context")
        for i = 1, 2 do
            bsp:on_end({ ctx = ctx.new("trace_id", "span_id#" .. i, 1) })
        end
        assert(bsp:get_queue_size() == 2)
        ngx.ctx.processor = bsp
        ngx.ctx.last_span = { ctx = ctx.new("trace_id", "span_id#3", 1) }
        ngx.say("done")
    }
    log_by_lua_block {
        ngx.worker.exiting = function() return true end
        ngx.ctx.processor:on_end(ngx.ctx.last_span)
        assert(ngx.ctx.processor:get_queue_size() == 0)
    }
}
--- request
GET /t
--- response_body
done
--- error_log
dropping 3 unexported span(s): timer-creation-failed
otel.bsp.dropped_spans 3 timer-creation-failed
--- no_error_log
export called without a timer
failed to run log_by_lua



=== TEST 9: rearm the timer after a transient scheduling failure
--- config
location = /t {
    content_by_lua_block {
        local timer_at = ngx.timer.at
        local timer_calls = 0
        ngx.timer.at = function(delay, ...)
            timer_calls = timer_calls + 1
            if timer_calls == 2 then
                return nil, "too many pending timers"
            end
            return timer_at(delay, ...)
        end
        local processor = require("opentelemetry.trace.batch_span_processor")
        ngx.timer.at = timer_at

        local exported = 0
        local exporter = {
            export_spans = function(_, spans)
                exported = exported + #spans
                return true
            end
        }
        local bsp = processor.new(exporter, {
            max_export_batch_size = 2, inactive_timeout = 0.01, batch_timeout = 60,
        })
        local ctx = require("opentelemetry.trace.span_context")

        bsp:on_end({ ctx = ctx.new("trace_id", "span_id#1", 1) })
        for _ = 1, 50 do
            if timer_calls == 2 then
                break
            end
            ngx.sleep(0.01)
        end

        bsp:on_end({ ctx = ctx.new("trace_id", "span_id#2", 1) })
        for _ = 1, 50 do
            if exported > 0 then
                break
            end
            ngx.sleep(0.01)
        end
        ngx.say("exported: ", exported)
    }
}
--- request
GET /t
--- response_body
exported: 2
--- error_log
failed to create timer: too many pending timers
--- no_error_log
dropping
