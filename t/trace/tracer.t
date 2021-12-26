use Test::Nginx::Socket 'no_plan';

log_level('debug');
repeat_each(1);
no_long_string();
no_root_location();
run_tests();

__DATA__

=== TEST 1: tracer:start
--- config
location = /t {
    content_by_lua_block {
        local tracer_provider = require("opentelemetry.trace.tracer_provider").new()
        local context = require("opentelemetry.context").new()
        local span_context_new = require("opentelemetry.trace.span_context").new
        local span_kind = require("opentelemetry.trace.span_kind")
        local attr = require("opentelemetry.attribute")
        local tracer = tracer_provider:tracer("unit_test")

        ngx.say("test start recording_span")
        local context, recording_span = tracer:start(context, "recording",
            {kind = span_kind.producer, attributes = {attr.string("key", "value")}})
        if not (recording_span.name == "recording" and recording_span.start_time > 0
            and recording_span.kind == span_kind.producer
            and #recording_span.attributes == 1
            and recording_span.attributes[1].key == "key"
            and recording_span.attributes[1].value.string_value == "value") then
            ngx.say("unexpected recording_span")
        end
        if not recording_span:is_recording() then
            ngx.say("expect recording")
        end

        ngx.say("test start non_recording_span")
        local always_off_sampler = require("opentelemetry.trace.sampling.always_off_sampler").new()
        tracer_provider.sampler = always_off_sampler
        local context, non_recording_span = tracer:start(context, "non_recording",
            {kind = span_kind.consumer, attributes = {attr.string("key", "value")}})
        if not (non_recording_span.name == nil and non_recording_span.start_time == nil
            and non_recording_span.kind == nil
            and non_recording_span.attributes == nil) then
            ngx.say("unexpected non_recording_span")
        end
        if non_recording_span:is_recording() then
            ngx.say("expect non_recording")
        end

        ngx.say("done")
    }
}
--- request
GET /t
--- error_code: 200
--- response_body
test start recording_span
test start non_recording_span
done
--- no_error_log
[error]