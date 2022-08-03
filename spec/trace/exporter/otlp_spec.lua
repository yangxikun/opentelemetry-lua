local exporter = require "opentelemetry.trace.exporter.otlp"
local client = require "opentelemetry.trace.exporter.http_client"

describe("call_collector", function()
    it("invokes do_request when there are no failures", function()
        local client = client.new("http://localhost:8080", 10)
        local cb = exporter.new(client)
        client.do_request = function() return "ok", nil end
        spy.on(client, "do_request")
        cb:call_collector("ok")
        assert.spy(client.do_request).was_called_with(client, "ok")
    end)

    it("doesn't invoke protected_call when failures is equal to retry limit", function()
        local client = client.new("http://localhost:8080", 10)
        local cb = exporter.new(client, 10000)
        client.do_request = function() return nil, "there was a problem" end
        spy.on(client, "do_request")
        cb:call_collector("ok")
        assert.spy(client.do_request).was_called(5)
    end)

    it("doesn't invoke do_request when start time is more than timeout_ms ago", function()
        local client = client.new("http://localhost:8080", 10)
        -- Set default timeout to -1, so that we're already over the timeout
        local cb = exporter.new(client, -1)
        spy.on(client, "do_request")
        cb:call_collector("ok")
        assert.spy(client.do_request).was_not_called()
    end)
end)
