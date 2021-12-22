use Test::Nginx::Socket 'no_plan';

log_level('debug');
repeat_each(1);
no_long_string();
no_root_location();
run_tests();

__DATA__

=== TEST 1: tracer provider force_flush and shutdown
This is just a simple demonstration of the
echo directive provided by ngx_http_echo_module.
--- config
location = /t {
    content_by_lua_block {
        local tracer_provider_new = require("opentelemetry.trace.tracer_provider").new
        local fake_processor = {
            force_flush = function()
                ngx.say("call span processor force_flush")
            end,
            shutdown = function()
                ngx.say("call span processor shutdown")
            end
        }
        local tracer_provider = tracer_provider_new({fake_processor})
        tracer_provider:force_flush()
        tracer_provider:shutdown()
        ngx.say("done")
    }
}
--- request
GET /t
--- error_code: 200
--- response_body
call span processor force_flush
call span processor shutdown
done
--- no_error_log
[error]