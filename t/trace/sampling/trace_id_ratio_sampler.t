use Test::Nginx::Socket 'no_plan';

log_level('debug');
repeat_each(1);
no_long_string();
no_root_location();
run_tests();

__DATA__

=== TEST 1: trace_id_ratio_sampler:should_sample
--- config
location = /t {
    content_by_lua_block {
        local trace_id_ratio_sampler_new = require("opentelemetry.trace.sampling.trace_id_ratio_sampler").new
        local context_new = require("opentelemetry.context").new

        ngx.say("test fraction = 0")
        local result = trace_id_ratio_sampler_new(0):should_sample({
            parent_ctx = context_new(),
            trace_id = "00000000000000000000000000000000",
        })
        if result:is_sampled() then
            ngx.say("expect result:is_sampled() == false")
            return
        end

        ngx.say("test fraction = 1")
        local result = trace_id_ratio_sampler_new(1):should_sample({
            parent_ctx = context_new(),
            trace_id = "ffffffff000000000000000000000000",
        })
        if not result:is_sampled() then
            ngx.say("expect result:is_sampled() == true")
            return
        end

        ngx.say("test fraction = 0.5")
        local result = trace_id_ratio_sampler_new(0.5):should_sample({
            parent_ctx = context_new(),
            trace_id = "7fffffff000000000000000000000000",
        })
        if not result:is_sampled() then
            ngx.say("expect result:is_sampled() == true")
            return
        end

        ngx.say("test fraction = 0.5")
        local result = trace_id_ratio_sampler_new(0.5):should_sample({
            parent_ctx = context_new(),
            trace_id = "80000000000000000000000000000000",
        })
        if result:is_sampled() then
            ngx.say("expect result:is_sampled() == false")
            return
        end

        ngx.say("done")
    }
}
--- request
GET /t
--- error_code: 200
--- response_body
test fraction = 0
test fraction = 1
test fraction = 0.5
test fraction = 0.5
done
--- no_error_log
[error]
