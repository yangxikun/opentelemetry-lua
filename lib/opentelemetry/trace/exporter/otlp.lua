local pb = require("opentelemetry.trace.exporter.pb")

local _M = {
}

local mt = {
    __index = _M
}

function _M.new(http_client)
    local self = {
        client = http_client,
    }
    return setmetatable(self, mt)
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
    self.client:do_request(pb.encode(body))
end

function _M.shutdown(self)

end

return _M