local baggage = require "opentelemetry.baggage"
local tracer_provider = require "opentelemetry.trace.tracer_provider"
local composite_propagator = require "opentelemetry.trace.propagation.text_map.composite_propagator"
local text_map_propagator = require "opentelemetry.trace.propagation.text_map.trace_context_propagator"
local baggage_propagator = require "opentelemetry.baggage.propagation.text_map.baggage_propagator"
local noop_propagator = require "opentelemetry.trace.propagation.text_map.noop_propagator"
local context = require("opentelemetry.context")
local test_utils = require("spec.test_utils")

-- We'll need to add more propagators to the repo (Jaeger, B3, etc), in order to
-- fully test this.
describe("composite propagator", function()
    describe(".inject", function()
        local tmp             = text_map_propagator.new()
        local bp              = baggage_propagator.new()
        local np              = noop_propagator.new()
        local cp              = composite_propagator.new({ tmp, bp, np })
        local ctx             = context.new()
        local tracer_provider = tracer_provider.new()
        local tracer          = tracer_provider:tracer("test tracer")

        -- start a trace
        local new_ctx = tracer:start(ctx, "span", { kind = 1 })
        local bgg = baggage.new({ foo = { value = "bar", metadata = "ok" } })
        new_ctx = new_ctx:inject_baggage(bgg)

        -- figure out what traceheader should look like
        local span_context = new_ctx.sp:context()
        local traceparent = string.format("00-%s-%s-%02x",
            span_context.trace_id,
            span_context.span_id,
            span_context.trace_flags)
        local carrier = test_utils.new_carrier({})

        it("should add headers for each propagator", function()
            cp:inject(new_ctx, carrier)
            assert.are.same(
                carrier.req.get_headers()["traceparent"],
                traceparent
            )
            assert.are.same(
                carrier.req.get_headers()["baggage"],
                "foo=bar;ok"
            )
        end)
    end)

    describe(".extract", function()
        it("should extract headers for each propagator", function()
            local tmp      = text_map_propagator.new()
            local bp       = baggage_propagator.new()
            local np       = noop_propagator.new()
            local cp       = composite_propagator.new({ tmp, bp, np })
            local trace_id = "10f5b3bcfe3f0c2c5e1ef150fe0b5872"
            local carrier  = test_utils.new_carrier(
                { traceparent = string.format("00-%s-172accbce5f048db-01", trace_id),
                    baggage = "foo=bar;ok" })
            local ctx      = context.new()
            local new_ctx  = cp:extract(ctx, carrier)
            assert.are.same(new_ctx.sp:context().trace_id, trace_id)
            assert.are.same(new_ctx:extract_baggage():get_value("foo"), "bar")
        end)
    end)
end)
