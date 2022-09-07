--------------------------------------------------------------------------------
-- This defines an interface used for reporting metrics. It defaults to a noop.
-- Users can supply a module that satisfies this interface to actually generate
-- metrics.
--------------------------------------------------------------------------------

local _M = {}

--------------------------------------------------------------------------------
-- Adds an increment to a metric with the provided labels. This should be used
-- with counter metrics
--
-- @param metric The metric to increment
-- @param increment The amount to increment the metric by
-- @param labels The labels to use for the metric
-- return nil
--------------------------------------------------------------------------------
function _M:add_to_counter(metric, increment, labels)
    return nil
end

--------------------------------------------------------------------------------
-- Record a value for metric with provided labels. This should be used with
-- histogram or distribution metrics.
--
-- @param metric The metric to record a value for
-- @param value The value to set for the metric
-- @param labels The labels to use for the metric
-- return nil
--------------------------------------------------------------------------------
function _M:record_value(metric, value, labels)
    return nil
end

--------------------------------------------------------------------------------
-- Observe a value for a metric with provided labels. This corresponds to the
-- gauge metric type in datadog
--
-- @param metric The metric to record a value for
-- @param value The value to set for the metric
-- @param labels The labels to use for the metric
-- return nil
--------------------------------------------------------------------------------
function _M:observe_value(metric, value, labels)
    return nil
end

return _M
