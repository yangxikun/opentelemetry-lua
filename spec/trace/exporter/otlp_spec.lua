local exporter = require "opentelemetry.trace.exporter.otlp"
local client = require "opentelemetry.trace.exporter.http_client"
local context = require "opentelemetry.context"
local tp = Global.get_tracer_provider()
local tracer = tp:tracer("test")

local function is_gzip(_, _)
    return function(value)
        -- check that the value starts with the two magic bytes 0x1f, 0x8b and
        -- the compression method byte set to 0x08
        -- reference: https://www.ietf.org/rfc/rfc1952.txt
        return string.sub(value, 1, 3) == string.from_hex("1F8B08")
    end
end

assert:register("matcher", "gzip", is_gzip)

function string.from_hex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

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
        assert.spy(c.do_request).was_called_with(c, match.is_all_of(match.is_string(), match.is_not_gzip()))
    end)

    it("invokes do_request with gzip compression when configured", function()
        local span
        local ctx = context.new()
        ctx, span = tracer:start(ctx, "test span")
        span:finish()

        local headers = {}
        headers["Content-Encoding"] = "gzip"
        local c = client.new("http://localhost:8080", 10, headers)
        spy.on(c, "do_request")

        local cb = exporter.new(c, 10000, true)

        -- Supress log message, since we expect it
        stub(ngx, "log")

        cb:export_spans({ span })
        ngx.log:revert()
        assert.spy(c.do_request).was_called_with(c, match.is_all_of(match.is_string(), match.is_gzip()))
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
