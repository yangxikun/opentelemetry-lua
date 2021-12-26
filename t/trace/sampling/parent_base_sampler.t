use Test::Nginx::Socket 'no_plan';

log_level('debug');
repeat_each(1);
no_long_string();
no_root_location();
run_tests();

__DATA__

=== TEST 1: parent_base_sampler:should_sample
--- config
location = /t {
    content_by_lua_block {
        local always_on_sampler = require("opentelemetry.trace.sampling.always_on_sampler").new()
        local parent_base_sampler = require("opentelemetry.trace.sampling.parent_base_sampler").new(always_on_sampler)
        local span_context_new = require("opentelemetry.trace.span_context").new

        ngx.say("test invalid parameters.parent_ctx")
        local result = parent_base_sampler:should_sample({
            parent_ctx = span_context_new()
        })
        if not result:is_sampled() then
            ngx.say("expect result:is_sampled() == true")
            return
        end

        ngx.say("test parameters.parent_ctx{remote = true}")
        local result = parent_base_sampler:should_sample({
            parent_ctx = span_context_new("trace_id", "span_id", 0, "trace_state", true)
        })
        if result:is_sampled() then
            ngx.say("expect result:is_sampled() == false")
            return
        end

        ngx.say("test parameters.parent_ctx{remote = true, sampled = true}")
        local result = parent_base_sampler:should_sample({
            parent_ctx = span_context_new("trace_id", "span_id", 1, "trace_state", true)
        })
        if not result:is_sampled() then
            ngx.say("expect result:is_sampled() == true")
            return
        end

        ngx.say("test parameters.parent_ctx{remote = false, sampled = true}")
        local result = parent_base_sampler:should_sample({
            parent_ctx = span_context_new("trace_id", "span_id", 1, "trace_state", true)
        })
        if not result:is_sampled() then
            ngx.say("expect result:is_sampled() == true")
            return
        end

        ngx.say("test parameters.parent_ctx{remote = false, sampled = false}")
        local result = parent_base_sampler:should_sample({
            parent_ctx = span_context_new("trace_id", "span_id", 0, "trace_state", false)
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
test invalid parameters.parent_ctx
test parameters.parent_ctx{remote = true}
test parameters.parent_ctx{remote = true, sampled = true}
test parameters.parent_ctx{remote = false, sampled = true}
test parameters.parent_ctx{remote = false, sampled = false}
done
--- no_error_log
[error]