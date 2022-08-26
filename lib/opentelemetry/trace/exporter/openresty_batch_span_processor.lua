--------------------------------------------------------------------------------
-- The Batch Span Processor is responsible for batching spans and passing them
-- off to an exporter. It is designed so that a single instance can be used for
-- multiple concurrent requests to a single NGINX worker.
-- See https://github.com/openresty/lua-nginx-module#data-sharing-within-an-nginx-worker
--------------------------------------------------------------------------------
local timer_at = ngx.timer.at
local otel_global = require("opentelemetry.global")
local batch_size_metric = "otel.bsp.batch_size"
local buffer_utilization_metric = "otel.bsp.buffer_utilization"
local dropped_spans_metric = "otel.bsp.dropped_spans"
local export_success_metric = "otel.bsp.export.success"
local exported_spans_metric = "otel.bsp.exported_spans"
local exporter_failure_metric = "otel.otlp_exporter.failure"

local _M = {
}

local mt = {
    __index = _M
}

--------------------------------------------------------------------------------
-- Create a batch span processor.
--
-- @param exporter_module A module whose .new() method returns an exporter.
-- @param opts Table with different BSP options
--          opts.max_queue_size: maximum queue size to buffer spans for delayed
--            processing, default 2048
--          opts.batch_timeout: maximum duration for constructing a batch,
--            default 5000ms
--          opts.export_timeout_ms: maximum duration for exporting a batch,
--            default 30000ms
--          opts.max_export_batch_size: maximum number of spans to process in a
--            single batch, default 512
-- @return openresty batch span processor
--------------------------------------------------------------------------------
function _M.new(exporter_module, opts)
    assert(exporter_module and exporter_module.new)
    opts = opts or {}
    return setmetatable(
        {
            exporter_module = exporter_module,
            max_queue_size = opts.max_queue_size or 2048,
            export_timeout_ms = opts.export_timeout_ms or 30000,
            max_export_batch_size = opts.max_export_batch_size or 512,
            queue = {},
            stopped = false,
        }, mt)
end

--------------------------------------------------------------------------------
-- Add to dropped_span_metrics counter with a reason.
--
-- @param count The number of spans dropped.
-- @param reason The reason the spans were dropped.
--------------------------------------------------------------------------------
local function report_dropped_spans(count, reason)
    otel_global.metrics_reporter:add_to_counter(
        dropped_spans_metric, count, { reason = reason })
end

--------------------------------------------------------------------------------
-- Increment counters for export success/failure and exported/dropped spans.
--
-- @param success whether or not the export succeeded.
-- @param count The number of spans dropped.
-- @param reason The reason the spans were dropped.
--------------------------------------------------------------------------------
local function report_export_result(success, err, batch_size)
    if success then
        otel_global.metrics_reporter:add_to_counter(
            export_success_metric, 1)
        otel_global.metrics_reporter:add_to_counter(
            exported_spans_metric, batch_size)
    else
        err = err or "unknown"
        otel_global.metrics_reporter:add_to_counter(
            exporter_failure_metric, 1, { reason = err })
        report_dropped_spans(batch_size, err)
    end
end

--------------------------------------------------------------------------------
-- Call exporter.export and report stats.
--
-- @param exporter The exporter instance to use for exporting the batch.
-- @param batch The batch of spans to export. Should be < max_export_batch_size.
--------------------------------------------------------------------------------
function _M.export_batch(exporter, batch)
    otel_global.metrics_reporter:record_value(batch_size_metric, #batch)
    local success, err = exporter:export_spans(batch)
    report_export_result(success, err, #batch)
end

--------------------------------------------------------------------------------
-- delayed_export_batch is a wrapper around export_batch, designed for use with
-- the ngx.timer.at function.
--
-- @param premature Argument indicating whether the method is being called
--   prematurely due to SIGHUP or shutdown (in which case it's true), or being
--   called after the requested delay (in which case it's false).
-- @param exporter_module A module whose .new() method returns an exporter.
-- @param batch The batch of spans to export.
--------------------------------------------------------------------------------
local function delayed_export_batch(premature, exporter, batch)
    if premature then
        ngx.log(ngx.WARN, "Exporting batch after ngx.timer.at callback was invoked prematurely (SIGHUP or shutdown")
    end

    _M.export_batch(exporter.new(), batch)
end

--------------------------------------------------------------------------------
-- on_start is called upon span initialization. Noop for the purposes of this
-- processor.
--
-- @param _span The span that's starting.
-- @param _parent_ctx The parent context of the span.
--------------------------------------------------------------------------------
function _M.on_start(self, _span, _parent_ctx) end

--------------------------------------------------------------------------------
-- on_end is called after a span is ended.
--
-- @param span The span that's ending.
--------------------------------------------------------------------------------
function _M.on_end(self, span)
    if not span.ctx:is_sampled() then
        return
    end

    if #self.queue >= self.max_queue_size then
        local dropped = table.remove(self.queue, 1)
        ngx.log(ngx.WARN,
            "Dropped span due to full queue: trace_id = " ..
            dropped.ctx.trace_id .. " span_id = " .. dropped.ctx.span_id)
        report_dropped_spans(1, "buffer-size")
    end
    table.insert(self.queue, span)

    -- Schedule a batch for export if queue >= max_export_batch_size
    if not self.stopped and #self.queue >= self.max_export_batch_size then
        otel_global.metrics_reporter:observe_value(
            buffer_utilization_metric,
            #self.queue / self.max_queue_size)
        -- Export the batch using ngx.timer.at, which runs in an OpenResty
        -- "light thread".  See
        -- https://github.com/openresty/lua-nginx-module#ngxtimerat. This
        -- hopefully _shouldn't_ lead to race conditions in lua-nginx-module
        -- since calling ngx.timer.at doesn't surrender control to the NGINX
        -- event loop, but rather schedules something for later execution.
        local batch
        self.queue, batch = _M.extract_batch(
            self.queue, self.max_export_batch_size)
        timer_at(0, delayed_export_batch, self.exporter_module, batch)
    end
end

--------------------------------------------------------------------------------
-- extract_batch takes in a table and a batch size and returns two tables: one
--   representing the remainder of the supplied table, and another representing
--   the batch.
--
-- @param queue The table to extract from.
-- @param batch_size How many elements to extract from the table.
-- @return remaining_queue, batch
--------------------------------------------------------------------------------
function _M.extract_batch(queue, batch_size)
    if #queue == 0 then
        return {}, {}
    end

    local end_of_batch_idx = #queue > batch_size and batch_size or #queue
    local ret_queue = {}
    local ret_batch = { unpack(queue, 1, end_of_batch_idx) }
    if end_of_batch_idx < #queue then
        ret_queue = { unpack(queue, end_of_batch_idx + 1) }
    end

    return ret_queue, ret_batch
end

--------------------------------------------------------------------------------
-- force_flush exports the entire queue. Does nothing if stopped is true.
--------------------------------------------------------------------------------
function _M.force_flush(self)
    if self.stopped then
        return
    end

    -- Execute the exports synchronously, since force_flush will be called in a
    -- shutdown or SIGHUP context.
    local exporter = self.exporter_module.new()
    for _i = 1, #self.queue, self.max_export_batch_size do
        local batch
        self.queue, batch = _M.extract_batch(
            self.queue, self.max_export_batch_size)

        self.export_batch(exporter, batch)
    end
end

--------------------------------------------------------------------------------
-- Shutdown invokes force_flush, which exports the entire queue.
--------------------------------------------------------------------------------
function _M.shutdown(self)
    self:force_flush()
    self.stopped = true
end

return _M
