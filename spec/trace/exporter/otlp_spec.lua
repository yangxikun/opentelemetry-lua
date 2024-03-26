local exporter = require "opentelemetry.trace.exporter.otlp"
local client = require "opentelemetry.trace.exporter.http_client"
local context = require "opentelemetry.context"
local tp = Global.get_tracer_provider()
local tracer_provider_new = require("opentelemetry.trace.tracer_provider").new
local tracer = tp:tracer("test")

describe("encode_spans", function()
    it("one resource span and one ils for one span", function()
        local span
        local ctx = context.new()
        ctx, span = tracer:start(ctx, "test span")
        span:finish()
        local cb = exporter.new(nil)
        local encoded = cb:encode_spans({span, other_spans})
        -- One resource, one il, one span
        assert(#encoded.resource_spans == 1)
        local resource = encoded.resource_spans[1]
        assert(#resource.instrumentation_library_spans == 1)
        assert(#resource.instrumentation_library_spans[1].spans == 1)
    end)

    it("one resource span and one ils for multiple span same tracer", function()
        local span
        local ctx = context.new()
        local spans = {}
        for i=10,1,-1 do
            ctx, span = tracer:start(ctx, "test span" .. i, {}, 123456788)
            span:finish(123456789)
            table.insert(spans, span)
        end
        local cb = exporter.new(nil)
        local encoded = cb:encode_spans(spans)
        -- One resource, one il, 10 spans
        assert(#encoded.resource_spans == 1)
        local resource = encoded.resource_spans[1]
        assert(#resource.instrumentation_library_spans == 1)
        assert(#resource.instrumentation_library_spans[1].spans == 10)
        assert(resource.instrumentation_library_spans[1].spans[1].start_time_unix_nano == "123456788")
        assert(resource.instrumentation_library_spans[1].spans[1].end_time_unix_nano == "123456789")
    end)

    it("one resource span and two ils for spans from distinct tracers", function()
        local span
        local ctx = context.new()
        local spans = {}
        ctx, span = tracer:start(ctx, "test span")
        span:finish()
        table.insert(spans, span)
        local other_tracer = tp:tracer("exam")
        ctx, other_span = other_tracer:start(ctx, "exam span")
        table.insert(spans, other_span)
        local cb = exporter.new(nil)
        local encoded = cb:encode_spans(spans)
        -- One resource, two il, 1 span each
        assert(#encoded.resource_spans == 1)
        local resource = encoded.resource_spans[1]
        assert(#resource.instrumentation_library_spans == 2)
        assert(#resource.instrumentation_library_spans[1].spans == 1)
        assert(#resource.instrumentation_library_spans[2].spans == 1)
    end)
    it("distinct trace providers provide distinct resources", function()
        local span
        local ctx = context.new()
        local spans = {}
        ctx, span = tracer:start(ctx, "test span")
        span:finish()
        table.insert(spans, span)
        local op = tracer_provider_new(nil, nil)
        local other_tracer = op:tracer("exam")
        ctx, other_span = other_tracer:start(ctx, "exam span")
        table.insert(spans, other_span)
        local cb = exporter.new(nil)
        local encoded = cb:encode_spans(spans)
        -- two resources with one il, 1 span each
        assert(#encoded.resource_spans == 2)
        local resource = encoded.resource_spans[1]
        assert(#resource.instrumentation_library_spans == 1)
        assert(#resource.instrumentation_library_spans[1].spans == 1)
        resource = encoded.resource_spans[2]
        assert(#resource.instrumentation_library_spans == 1)
        assert(#resource.instrumentation_library_spans[1].spans == 1)
    end)
end)

describe("export_spans", function()
    it("invokes do_request when there are no failures", function()
        local span
        local ctx = context.new()
        ctx, span = tracer:start(ctx, "test span")
        span:finish()
        local c = client.new("http://localhost:8080", 10)
        spy.on(c, "do_request")
        local cb = exporter.new(c)
        -- Supress log message, since we expect it
        stub(ngx, "log")
        cb:export_spans({ span })
        ngx.log:revert()
        assert.spy(c.do_request).was_called_with(c, match.is_string())
    end)

    it("doesn't invoke protected_call when failures is equal to retry limit", function()
        local span
        local ctx = context.new()
        ctx:attach()
        ctx, span = tracer:start(ctx, "test span")
        span:finish()
        local c = client.new("http://localhost:8080", 10)
        c.do_request = function() return nil, "there was a problem" end
        mock(c, "do_request")
        local cb = exporter.new(c, 10000)
        cb:export_spans({ span })
        assert.spy(c.do_request).was_called(3)
    end)

    it("doesn't invoke do_request when start time is more than timeout_ms ago", function()
        local span
        local ctx = context.new()
        ctx:attach()
        ctx, span = tracer:start(ctx, "test span")
        span:finish()
        local c= client.new("http://localhost:8080", 10)
        -- Set default timeout to -1, so that we're already over the timeout
        local cb = exporter.new(client, -1)
        spy.on(c, "do_request")
        stub(ngx, "log")
        cb:export_spans({ span})
        ngx.log:revert()
        assert.spy(c.do_request).was_not_called()
    end)
end)

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
        client.do_request = function(arg) return "hi", nil end
        spy.on(client, "do_request")
        ex:export_spans({ span})
        assert.spy(client.do_request).was_called(1)
    end)
end)
