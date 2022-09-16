local util = require("opentelemetry.util")
local otel_global =  require("lib.opentelemetry.global")

local _M = {
    OPEN = "open",
    CLOSED = "closed",
    HALF_OPEN = "half-open"
}

local mt = {
    __index = _M
}


function _M.new(options)
    options = options or {}
    local self = {
        circuit_reset_timeout_ms = options["circuit_reset_timeout_ms"] or 5000,
        failure_threshold = options["failure_threshold"] or 5,
        failure_count = 0,
        open_start_time_ms = nil,
        state = "closed",
        success_count = 0,
        trying_halfopen_request = false
    }
    return setmetatable(self, mt)
end

function _M:should_make_request()
    if self.state == self.CLOSED then
        return true
    end

    if self.state == self.OPEN then
        if (util.gettimeofday_ms() - self.open_start_time_ms) > self.circuit_reset_timeout_ms then
            self.state = self.HALF_OPEN
            self.open_start_time_ms = nil
        end
    end

    if self.state == self.HALF_OPEN then
        if self.trying_halfopen_request then
            return false
        else
            return true
        end
    end

    ngx.log(ngx.ERR, "should not have gotten here")
    return false
end

function _M.process_failed_request(self)
    self.success_count = 0
    self.failure_count = self.failure_count + 1

    if self.state == self.CLOSED and self.failure_count >= self.failure_threshold then
        otel_global.metrics_reporter:add_to_counter("otel.bsp.circuit_breaker_opened", 1)
        self.state = self.OPEN
        self.open_start_time_ms = util.gettimeofday_ms()
    end

    if self.state == self.HALF_OPEN then
        otel_global.metrics_reporter:add_to_counter("otel.bsp.circuit_breaker_opened", 1)
        self.trying_halfopen_request = false
        self.state = self.OPEN
        self.open_start_time_ms = util.gettimeofday_ms()
    end
end

function _M.process_succeeded_request(self)
    if self.state == self.CLOSED then
        return
    end

    if self.state == self.HALF_OPEN then
        otel_global.metrics_reporter:add_to_counter("otel.bsp.circuit_breaker_closed", 1)
        self.trying_halfopen_request = false
        self.state = self.CLOSED
        return
    end
end

return _M
