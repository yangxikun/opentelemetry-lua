local pb = require("opentelemetry.trace.exporter.pb")
local util = require("opentelemetry.util")
local RETRY_LIMIT = 3
local DEFAULT_TIMEOUT_MS = 10000

local _M = {
}

local mt = {
    __index = _M
}

function _M.new(http_client, timeout_ms)
    local self = {
        client = http_client,
        timeout_ms = timeout_ms or DEFAULT_TIMEOUT_MS,
    }
    return setmetatable(self, mt)
end

local function call_collector(exporter, pb_encoded_body)
    local start_time_ms = util.gettimeofday_ms()
    local failures = 0

    while failures < RETRY_LIMIT do
        if util.gettimeofday_ms() - start_time_ms > exporter.timeout_ms then
            ngx.log(ngx.WARN, "Collector retries timed out (timeout " .. exporter.timeout_ms .. ")")
            break
        end

        local res, _ = exporter.client:do_request(pb_encoded_body)
        if not res then
            failures = failures + 1
            ngx.sleep(util.random_float(2 ^ failures))
            ngx.log(ngx.INFO, "Retrying call to collector (retry #" .. failures .. ")")
        else
            break
        end
    end
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
    call_collector(self, pb.encode(body))
end

function _M.shutdown(self)

end

if _TEST then
    _M.call_collector = call_collector
end

return _M
