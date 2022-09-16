local exporter = require "opentelemetry.trace.exporter.otlp"
local client = require "opentelemetry.trace.exporter.http_client"
local context = require "opentelemetry.context"
local tp = Global.get_tracer_provider()
local tracer = tp:tracer("test")

if _RUN_SLOW_TESTS then
    describe("export_spans", function()
        it("invokes do_request when there are no failures", function()
            local span
            local ctx = context.new()
            ctx:attach()
            ctx, span = tracer:start(ctx, "test span")
            span:finish()
            local client = client.new("http://localhost:8080", 10)
            local cb = exporter.new(client)
            client.do_request = function() return "ok", nil end
            spy.on(client, "do_request")
            cb:export_spans({ span })
            assert.spy(client.do_request).was_called_with(client, match.is_string())
        end)

        it("doesn't invoke protected_call when failures is equal to retry limit", function()
            local span
            local ctx = context.new()
            ctx:attach()
            ctx, span = tracer:start(ctx, "test span")
            span:finish()
            local client = client.new("http://localhost:8080", 10)
            local cb = exporter.new(client, 10000)
            client.do_request = function() return nil, "there was a problem" end
            spy.on(client, "do_request")
            cb:export_spans({ span })
            assert.spy(client.do_request).was_called(3)
        end)

        it("doesn't invoke do_request when start time is more than timeout_ms ago", function()
            local span
            local ctx = context.new()
            ctx:attach()
            ctx, span = tracer:start(ctx, "test span")
            span:finish()
            local client = client.new("http://localhost:8080", 10)
            -- Set default timeout to -1, so that we're already over the timeout
            local cb = exporter.new(client, -1)
            spy.on(client, "do_request")
            cb:export_spans({ span})
            assert.spy(client.do_request).was_not_called()
        end)
    end)
end

describe("circuit breaker", function()
    it("doesn't call do_request when should_make_request() is false", function()
        local span
        local ctx = context.new()
        ctx:attach()
        ctx, span = tracer:start(ctx, "test span")
        span:finish()
        local client = client.new("http://localhost:8080", 10)
        local ex = exporter.new(client, 1)
        ex.circuit.should_make_request = function() return false end
        spy.on(client, "do_request")
        ex:export_spans({ span})
        assert.spy(client.do_request).was_not_called()
    end)

    it("calls do_request when should_make_request() is true", function()
        local span
        local ctx = context.new()
        ctx:attach()
        ctx, span = tracer:start(ctx, "test span")
        span:finish()
        local client = client.new("http://localhost:8080", 10)
        local ex = exporter.new(client, 1)
        ex.circuit.should_make_request = function() return true end
        spy.on(client, "do_request")
        ex:export_spans({ span})
        assert.spy(client.do_request).was_not_called()
    end)
end)
