local util = require("lib.opentelemetry.util")
local circuit = require("opentelemetry.trace.exporter.circuit")

describe("should_make_request", function()
    it("returns true when circuit is closed", function()
        local c = circuit.new()
        c.state = c.CLOSED
        assert.is_true(c:should_make_request())
    end)

    it("returns false when circuit is open and halfopen_threshold not exceeded", function()
        local c = circuit.new({ reset_timeout_ms = 5000 })
        c.state = c.OPEN
        c.open_start_time_ms = util.gettimeofday_ms()
        assert.is_false(c:should_make_request())
    end)

    it("returns true when circuit is open and halfopen_threshold is exceeded", function()
        local c = circuit.new({ reset_timeout_ms = 5000 })
        c.state = c.OPEN
        c.open_start_time_ms = util.gettimeofday_ms() - 6000
        assert.is_true(c:should_make_request())
    end)
end)

describe("record_failure", function()
    it("opens circuit if failure count > self.failure_threshold", function()
        local c = circuit.new({ failure_threshold = 1 })
        assert.is_equal(c.state, c.CLOSED)
        assert.is_equal(c.open_start_time_ms, nil)
        c:record_failure()
        assert.is_equal(c.state, c.OPEN)
        assert.are_not.equals(c.open_start_time_ms, nil)
    end)

    it("opens circuit if half-open on entry", function()
        local c = circuit.new({ failure_threshold = 5 })
        c.state = c.HALF_OPEN
        c:record_failure()
        assert.is_equal(c.state, c.OPEN)
        assert.are_not.equals(c.open_start_time_ms, nil)
    end)
end)

describe("record_success", function()
    it("closes circuit if circuit was half-open", function()
        local c = circuit.new({ failure_threshold = 1 })
        c.state = c.HALF_OPEN
        c:record_success()
        assert.is_equal(c.state, c.CLOSED)
    end)
end)
