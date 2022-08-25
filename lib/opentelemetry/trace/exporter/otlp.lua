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
            span:as_export_data())
    end
    call_collector(self, pb.encode(body))
end

function _M.shutdown(self)

end

return _M
