--------------------------------------------------------------------------------
-- Contains circuit for use in exporters. For more on the circuit breaker
-- pattern, see https://martinfowler.com/bliki/CircuitBreaker.html.
--------------------------------------------------------------------------------
local util = require("opentelemetry.util")
local otel_global = require("opentelemetry.global")

local _M = {
    OPEN = "open",
    CLOSED = "closed",
    HALF_OPEN = "half-open"
}

local mt = {
    __index = _M
}

--------------------------------------------------------------------------------
-- Returns a new circuit. No more than 1 request should be in flight at a time,
-- when those requests are brokered by this circuit.
--
-- @param options Table containing two keys:
--   failure_threshold: number of failures before the circuit opens and requests
--      stop flowing
--   reset_timeout_ms: time in to wait im ms before setting circuit to half-open
--
-- @return circuit instance
--------------------------------------------------------------------------------
function _M.new(options)
    options = options or {}
    local self = {
        reset_timeout_ms = options["reset_timeout_ms"] or 5000,
        failure_threshold = options["failure_threshold"] or 5,
        failure_count = 0,
        open_start_time_ms = nil,
        state = "closed",
    }
    return setmetatable(self, mt)
end

--------------------------------------------------------------------------------
-- should_make_request determines if a request should be made or not. It assumes
-- that circuit state is either CLOSED or OPEN at beginning of method, since the
-- code assumes that the circuit only brokers one request at a time, and assumes
-- that we only ever make one request in HALF_OPEN state before setting to OPEN
-- or CLOSED.
--
-- @return boolean
--------------------------------------------------------------------------------
function _M.should_make_request(self)
    if self.state == self.CLOSED then
        return true
    end

    if self.state == self.OPEN then
        if (util.gettimeofday_ms() - self.open_start_time_ms) < self.reset_timeout_ms then
            return false
        else
            self.state = self.HALF_OPEN
            return true
        end
    end

    ngx.log(ngx.ERR, "Circuit breaker could not determine if request should be made (current state: " .. self.state)
end

--------------------------------------------------------------------------------
-- record_failure does internal book-keeping about failures and resets circuit
-- state accordingly.
--
-- @return nil
--------------------------------------------------------------------------------
function _M.record_failure(self)
    self.failure_count = self.failure_count + 1

    if self.state == self.CLOSED and self.failure_count >= self.failure_threshold then
        otel_global.metrics_reporter:add_to_counter(
            "otel.bsp.circuit_breaker_opened", 1)
        self.state = self.OPEN
        self.open_start_time_ms = util.gettimeofday_ms()
    end

    if self.state == self.HALF_OPEN then
        otel_global.metrics_reporter:add_to_counter(
            "otel.bsp.circuit_breaker_opened", 1)
        self.state = self.OPEN
        self.open_start_time_ms = util.gettimeofday_ms()
    end
end

--------------------------------------------------------------------------------
-- record_success does internal book-keeping about successful requests and
-- resets circuit state accordingly.
--
-- @return nil
--------------------------------------------------------------------------------
function _M.record_success(self)
    if self.state == self.CLOSED then
        return
    end

    if self.state == self.HALF_OPEN then
        otel_global.metrics_reporter:add_to_counter(
            "otel.bsp.circuit_breaker_closed", 1)
        self.failure_count = 0
        self.state = self.CLOSED
        return
    end
end

return _M
