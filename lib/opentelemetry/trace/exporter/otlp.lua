local encoder = require("opentelemetry.trace.exporter.encoder")
local pb = require("opentelemetry.trace.exporter.pb")
local otel_global = require("opentelemetry.global")
local util = require("opentelemetry.util")
local BACKOFF_RETRY_LIMIT = 3
local DEFAULT_TIMEOUT_MS = 10000
local exporter_request_duration_metric = "otel.otlp_exporter.request_duration"
local circuit = require("opentelemetry.trace.exporter.circuit")

local _M = {
}

local mt = {
    __index = _M
}

function _M.new(http_client, timeout_ms, use_gzip, circuit_reset_timeout_ms, circuit_open_threshold)
    local self = {
        client = http_client,
        timeout_ms = timeout_ms or DEFAULT_TIMEOUT_MS,
        use_gzip = use_gzip or false,
        circuit = circuit.new({
            reset_timeout_ms = circuit_reset_timeout_ms,
            failure_threshold = circuit_open_threshold
        }),
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
local function call_collector(exporter, pb_encoded_body, use_gzip)
    local start_time_ms = util.gettimeofday_ms()
    local failures = 0
    local res
    local res_error

    while failures < BACKOFF_RETRY_LIMIT do
        local current_time = util.gettimeofday_ms()
        if current_time - start_time_ms > exporter.timeout_ms then
            local err_message = "Collector retries timed out (timeout " .. exporter.timeout_ms .. ")"
            ngx.log(ngx.WARN, err_message)
            return false, err_message
        end

        if not exporter.circuit:should_make_request() then
            ngx.log(ngx.INFO, "Circuit breaker is open")
            return false, "Circuit breaker is open"
        end

        if use_gzip then
            -- Compress (deflate) request body
            -- the compression should be set to Best Compression and window size
            -- should be set to 15+16, see reference below:
            -- https://github.com/brimworks/lua-zlib/issues/4#issuecomment-26383801
            local deflate_stream = zlib.deflate(zlib.BEST_COMPRESSION, 15+16)
            local compressed_body, _, _, bytes_out = deflate_stream(pb_encoded_body, "finish")

            otel_global.metrics_reporter:record_value(
                exporter_request_uncompressed_payload_size, string.len(pb_encoded_body))
            otel_global.metrics_reporter:record_value(
                exporter_request_compressed_payload_size, bytes_out)

            pb_encoded_body = compressed_body
        else
            otel_global.metrics_reporter:record_value(
                exporter_request_uncompressed_payload_size, string.len(pb_encoded_body))
        end

        -- Make request
        res, res_error = exporter.client:do_request(pb_encoded_body)
        local after_time = util.gettimeofday_ms()
        otel_global.metrics_reporter:record_value(
            exporter_request_duration_metric, after_time - current_time)

        if not res then
            exporter.circuit:record_failure()
            failures = failures + 1
            ngx.sleep(util.random_float(2 ^ failures))
            ngx.log(ngx.INFO, "Retrying call to collector (retry #" .. failures .. ")")
        else
            exporter.circuit:record_success()
            return true, nil
        end
    end

    return false, res_error or "unknown"
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
        table.insert(
            body.resource_spans[1].instrumentation_library_spans[1].spans,
            encoder.for_otlp(span))
    end
    return call_collector(self, pb.encode(body), self.use_gzip)
end

function _M.shutdown(self)

end

return _M
