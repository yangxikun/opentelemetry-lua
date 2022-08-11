use Test::Nginx::Socket 'no_plan';

log_level('debug');
repeat_each(1);
no_long_string();
no_root_location();
run_tests();

__DATA__

=== TEST 1: context
--- config
location = /t {
    content_by_lua_block {
        local span_context_new = require("opentelemetry.trace.span_context").new
        local context = require("opentelemetry.context").new()

        ngx.say("text context:with_span_context")
        context = context:with_span_context(span_context_new("trace_id", "span_id", 1, "trace_state", false))
        local span_context = context:span_context()
        if not (span_context.trace_id == "trace_id" and span_context.span_id == "span_id" and
            span_context.trace_flags == 1 and span_context.trace_state == "trace_state" and
            span_context.remote == false) then
            ngx.say("unexpected span_context")
        end
        if context:span():is_recording() then
            ngx.say("unexpected span")
        end

        ngx.say("test context attach & detach")
        local tracer_provider = require("opentelemetry.trace.tracer_provider").new()
        local tracer = tracer_provider:tracer("unit_test")
        local context, recording_span = tracer:start(context, "recording")
        if context:current() ~= nil then
            ngx.say("unexpected context:current()")
        end
        context:attach()
        if context:current():span().name ~= "recording" then
            ngx.say("unexpected context:current():span()")
        end
        context, recording_span = tracer:start(context, "recording2")
        context:attach()
        if context:current():span().name ~= "recording2" then
            ngx.say("unexpected context:current():span()")
        end
        context:detach(2)
        if context:current():span().name ~= "recording" then
            ngx.say("unexpected context:current():span()")
        end
        context:current():detach(1)
        if context:current() ~= nil then
            ngx.say("unexpected context:current()")
        end
        ngx.say("done")
    }
}
--- request
GET /t
--- error_code: 200
--- response_body
text context:with_span_context
test context attach & detach
done
--- no_error_log
[error]