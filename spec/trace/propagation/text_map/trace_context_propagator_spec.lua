local text_map_propagator = require "opentelemetry.trace.propagation.text_map.trace_context_propagator"
local tracer_provider = require "opentelemetry.trace.tracer_provider"
local context = require("opentelemetry.context")

-- We're setting these on ngx.req but we aren't running openresty in these
-- tests, so we'll mock that out (ngx.req supports get_headers() and set_header(header_name))
local function newCarrier(header, header_return)
    local r = { headers = {} }
    r.headers[header] = header_return
    r.get_headers = function() return r.headers end
    r.set_header = function(name, val) r.headers[name] = val end
    return r
end

describe("text map propagator", function()
    describe(".fields", function()
        local tmp = text_map_propagator.new()
        it("should return traceparent and traceheader", function()
            assert.are.same({ "traceparent", "tracestate" }, tmp.fields())
        end)
    end)

    describe(":inject", function()
        it("adds traceparent headers to carrier", function()
            local tmp             = text_map_propagator.new()
            local context         = context.new()
            local carrier         = newCarrier("ok", "alright")
            local tracer_provider = tracer_provider.new()
            local tracer          = tracer_provider:tracer("test tracer")
            -- start a trace
            local new_ctx         = tracer:start(context, "span", { kind = 1 })

            -- figure out what traceheader should look like
            local span_context = new_ctx.sp:context()
            local traceparent = string.format("00-%s-%s-%02x",
                span_context.trace_id, span_context.span_id, span_context.trace_flags)

            -- make sure we set_header in the setter
            spy.on(carrier, "set_header")
            tmp:inject(new_ctx, carrier)
            assert.spy(carrier.set_header).was.called_with("traceparent", traceparent)
        end)
    end)

    describe(":extract", function()
        it("does not override existing context when none is present in traceparent", function()
            local tmp      = text_map_propagator.new()
            local old_ctx  = context.new()
            local trace_id = "10f5b3bcfe3f0c2c5e1ef150fe0b5872"
            local carrier  = newCarrier("nottraceparent", "doesn't matter")

            local ctx = tmp:extract(old_ctx, carrier)
            assert.are.same(ctx, old_ctx)
        end)

        it("sets context when traceparent is valid", function()
            local tmp      = text_map_propagator.new()
            local context  = context.new()
            local trace_id = "10f5b3bcfe3f0c2c5e1ef150fe0b5872"
            local carrier  = newCarrier("traceparent", string.format("00-%s-172accbce5f048db-01", trace_id))

            local ctx = tmp:extract(context, carrier)
            assert.are.same(ctx.sp:context().trace_id, trace_id)
        end)
    end)
end)
