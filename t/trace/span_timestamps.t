use Test::Nginx::Socket 'no_plan';

log_level('debug');
repeat_each(1);
no_long_string();
no_root_location();
run_tests();

__DATA__

=== TEST 1: span start and end timestamps can be set explicitly
--- config
location = /t {
    content_by_lua_block {
        local tracer_provider = require("opentelemetry.trace.tracer_provider").new()
        local context = require("opentelemetry.context").new()
        local span_context_new = require("opentelemetry.trace.span_context").new
        local span_kind = require("opentelemetry.trace.span_kind")
        local attr = require("opentelemetry.attribute")
        local tracer = tracer_provider:tracer("unit_test")
        local context, recording_span = tracer:start(context, "recording",
            {kind = span_kind.producer, attributes = {attr.string("key", "value")}}, 123456788)
        context.sp:finish(123456789)
        if context.sp.start_time ~= 123456788 then
            ngx.log(ngx.ERR, "start time should have been 123456788, was " .. context.sp.start_time)
        end
        if context.sp.end_time ~= 123456789 then
            ngx.log(ngx.ERR, "end time should have been 123456789, was " .. context.sp.end_time)
        end
    }
}
--- request
GET /t
--- no_error_log
123456789
