local tracer_provider = require "opentelemetry.trace.tracer_provider"
local composite_propagator = require "opentelemetry.trace.propagation.text_map.composite_propagator"
local text_map_propagator = require "opentelemetry.trace.propagation.text_map.trace_context_propagator"
local noop_propagator = require "opentelemetry.trace.propagation.text_map.noop_propagator"
local context = require("opentelemetry.context")

--We use ngx.ctx to store context, but don't want to instantiate everything here
local context_storage = {
    function() get(self, key) return "getvalue" end,
    function() set(self, key, val) return nil end
}

-- We're setting these on ngx.req but we aren't running openresty in these
-- tests, so we'll mock that out (ngx.req supports get_headers() and set_header(header_name))
local function newCarrier(header, header_return)
    local r = { headers = {} }
    r.headers[header] = header_return
    r.get_headers = function() return r.headers end
    r.set_header = function(name, val) r.headers[name] = val end
    return r
end

-- We'll need to add more propagators to the repo (Jaeger, B3, etc), in order to
-- fully test this.
describe("composite propagator", function()
    describe(".composite_inject", function()
        local tmp             = text_map_propagator.new()
        local np              = noop_propagator.new()
        local cp              = composite_propagator.new({ tmp, np })
        local ctx             = context.new(context_storage)
        local tracer_provider = tracer_provider.new()
        local tracer          = tracer_provider:tracer("test tracer")

        -- start a trace
        local new_ctx = tracer:start(ctx, "span", { kind = 1 })

        -- figure out what traceheader should look like
        local span_context = new_ctx.sp:context()
        local traceparent = string.format("00-%s-%s-%02x",
            span_context.trace_id,
            span_context.span_id,
            span_context.trace_flags)
        local carrier = newCarrier("header", "value")

        it("should add headers for each propagator", function()
            cp:composite_inject(new_ctx, carrier)
            assert.are.same(
                carrier.get_headers()["traceparent"],
                traceparent
            )
        end)
    end)

    describe(".composite_extract #focus", function()
        it("should extract headers for each propagator", function()
            local tmp      = text_map_propagator.new()
            local np       = noop_propagator.new()
            local cp       = composite_propagator.new({ tmp, np })
            local trace_id = "10f5b3bcfe3f0c2c5e1ef150fe0b5872"
            local carrier  = newCarrier("traceparent",
                string.format("00-%s-172accbce5f048db-01", trace_id))
            local ctx = context.new(context_storage)
            local new_ctx = cp:composite_extract(ctx, carrier)
            assert.are.same(new_ctx.sp:context().trace_id, trace_id)
        end)
    end)
end)
