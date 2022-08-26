local http_c = require("opentelemetry.trace.exporter.http_client")
local pb = require("opentelemetry.trace.exporter.pb")
local otel_global = require("opentelemetry.global")
local util = require("opentelemetry.util")
local RETRY_LIMIT = 3
local DEFAULT_TIMEOUT_MS = 10000
local exporter_request_duration_metric = "otel.otlp_exporter.request_duration"

local _M = {
}

local mt = {
    __index = _M
}

function _M.new(http_client, timeout_ms)
    local self = {
        client = http_client or http_c.new(),
        timeout_ms = timeout_ms or DEFAULT_TIMEOUT_MS,
    }
    return setmetatable(self, mt)
end

--------------------------------------------------------------------------------
-- Repeatedly make calls to collector until success, failure threshold or
-- timeout
--
-- @param exporter The exporter to use for the collector call
-- @param pb_encoded_body protobuf-encoded body to send to the collector
-- @return true if call succeeded; false if call failed
-- @return nil if call succeeded; error message string if call failed
--------------------------------------------------------------------------------
local function call_collector(exporter, pb_encoded_body)
    local start_time_ms = util.gettimeofday_ms()
    local failures = 0
    local res
    local res_error

    while failures < RETRY_LIMIT do
        if util.gettimeofday_ms() - start_time_ms > exporter.timeout_ms then
            local err_message = "Collector retries timed out (timeout " .. exporter.timeout_ms .. ")"
            ngx.log(ngx.WARN, err_message)
            return false, err_message
        end

        local before_time = util.gettimeofday_ms()
        res, res_error = exporter.client:do_request(pb_encoded_body)
        local after_time = util.gettimeofday_ms()
        otel_global.metrics_reporter:record_value(
            exporter_request_duration_metric, after_time - before_time)
        if not res then
            failures = failures + 1
            ngx.sleep(util.random_float(2 ^ failures))
            ngx.log(ngx.INFO, "Retrying call to collector (retry #" .. failures .. ")")
        else
            return true, nil
        end
    end
    return false, res_error or "unknown"
end

local function hex2bytes(str)
    return (str:gsub('..', function (cc)
        local n = tonumber(cc, 16)
        if n then
            return string.char(n)
        end
    end))
end

function _M.export_spans(self, spans)
    assert(spans[1])

    local body = {
        resource_spans = {
            {
                resource = {
                    attributes = spans[1].tracer.provider.resource.attrs,
                    dropped_attributes_count = 0,
                },
                instrumentation_library_spans = {
                    {
                        instrumentation_library = {
                            name = spans[1].tracer.il.name,
                            version = spans[1].tracer.il.version,
                        },
                        spans = {}
                    },
                },
            }
        }
    }
    for _, span in ipairs(spans) do
        table.insert(body.resource_spans[1].instrumentation_library_spans[1].spans, {
            trace_id = hex2bytes(span.ctx.trace_id),
            span_id = hex2bytes(span.ctx.span_id),
            trace_state = "",
            parent_span_id = span.parent_ctx.span_id and hex2bytes(span.parent_ctx.span_id) or "",
            name = span.name,
            kind = span.kind,
            start_time_unix_nano = string.format("%d", span.start_time),
            end_time_unix_nano = string.format("%d", span.end_time),
            attributes = span.attributes,
            dropped_attributes_count = 0,
            events = span.events,
            dropped_events_count = 0,
            links = {},
            dropped_links_count = 0,
            status = span.status,
        })
    end
    return call_collector(self, pb.encode(body))
end

function _M.shutdown(self)

end

return _M
