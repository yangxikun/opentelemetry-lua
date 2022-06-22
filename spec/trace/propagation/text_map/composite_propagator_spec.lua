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
-- tests, so we'll mock that out (ngx.req supports get_headers and set_header)
local function newCarrier(header, header_return)
    local ret = {}
    ret.get_headers = {}
    ret.get_headers[header] = header_return

    -- Pretty gnarly mocking here. set_header has a reference to ret, so we can
    -- modify the state held in the get_headers field.
    ret.set_header = function(name, val) ret.get_headers[name] = val end
    return ret
end

-- We'll need to add more propagators to the repo (Jaeger, B3, etc), in order to
-- fully test this.
describe("composite propagator", function()
    describe(".composite_inject", function()
        local tmp = text_map_propagator.new()
        local np = noop_propagator.new()
        local cp = composite_propagator.new({ tmp, np })
        local ctx = context.new(context_storage)
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
                carrier.get_headers["traceparent"],
                traceparent
            )
        end)
    end)

    -- describe(".composite_extract", function()
    --     it("should extract headers for each propagator", function()
    --         cp:composite_extract(new_ctx, carrier)
    --         assert.are.same(
    --             carrier.get_headers["traceparent"],
    --             traceparent
    --         )
    --     end)
    -- end)
end)
