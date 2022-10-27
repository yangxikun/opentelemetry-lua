local baggage = require "opentelemetry.baggage"
local baggage_propagator = require "opentelemetry.baggage.propagation.text_map.baggage_propagator"
local context = require "opentelemetry.context"
local test_utils = require("spec.test_utils")

-- todo(plantfansam): handle multiple baggage headers
describe("baggage propagator", function()
    describe(".extract", function()
        it("handles absent header", function()
            local carrier = test_utils.new_carrier({ foo = "bar" })
            local ctx = context.new()
            local baggage_propagator = baggage_propagator.new()
            local new_ctx = baggage_propagator:extract(ctx, carrier)
            local baggage_from_ctx = new_ctx:extract_baggage()
            assert.is_same(baggage_from_ctx.values, {})
        end)

        it("handles empty string", function()
            local carrier = test_utils.new_carrier({ baggage = "" })
            local ctx = context.new()
            local baggage_propagator = baggage_propagator.new()
            local new_ctx = baggage_propagator:extract(ctx, carrier)
            local baggage_from_ctx = new_ctx:extract_baggage()
            assert.is_same(baggage_from_ctx.values, {})
        end)

        it("handles simplest case", function()
            local carrier = test_utils.new_carrier({ baggage = "userId=1" })
            local ctx = context.new()
            local baggage_propagator = baggage_propagator.new()
            local new_ctx = baggage_propagator:extract(ctx, carrier)
            local baggage_from_ctx = new_ctx:extract_baggage()
            assert.is_same(baggage_from_ctx:get_value("userId"), "1")
        end)

        it("handles unescaping percent encoding", function()
            local carrier = test_utils.new_carrier({ baggage = "userId=Am%C3%A9lie,serverNode=DF%2028,isProduction=false" })
            local ctx = context.new()
            local baggage_propagator = baggage_propagator.new()
            local new_ctx = baggage_propagator:extract(ctx, carrier)
            local baggage_from_ctx = new_ctx:extract_baggage()
            assert.is_same(baggage_from_ctx:get_value("userId"), "Amélie")
            assert.is_same(baggage_from_ctx:get_value("serverNode"), "DF 28")
            assert.is_same(baggage_from_ctx:get_value("isProduction"), "false")
        end)

        it("extracts metadata", function()
            local carrier = test_utils.new_carrier({ baggage = "userId=Am%C3%A9lie;motto=yolo;hi=mom,serverNode=DF%2028;motto=yolo2" })
            local ctx = context.new()
            local baggage_propagator = baggage_propagator.new()
            local new_ctx = baggage_propagator:extract(ctx, carrier)
            local baggage_from_ctx = new_ctx:extract_baggage()
            assert.is_same(baggage_from_ctx.values["userId"].metadata, "motto=yolo;hi=mom")
            assert.is_same(baggage_from_ctx.values["serverNode"].metadata, "motto=yolo2")
        end)

        it("handles malformed strings", function()
            local carrier = test_utils.new_carrier({ baggage = "oi;=un;unx;p;=aun" })
            local ctx = context.new()
            local baggage_propagator = baggage_propagator.new()
            local new_ctx = baggage_propagator:extract(ctx, carrier)
            local baggage_from_ctx = new_ctx:extract_baggage()
            assert.is_same(baggage_from_ctx.values, {})
        end)
    end)

    describe(".inject", function()
        it("does nothing when baggage has no entries", function()
            local carrier = test_utils.new_carrier({ foo = "bar" })
            local bgg = baggage.new({})
            local ctx = context.new():inject_baggage(bgg)
            local baggage_propagator = baggage_propagator.new()
            spy.on(carrier, "set_header")
            baggage_propagator:extract(ctx, carrier)
            assert.spy(carrier.set_header).was_not_called()
        end)

        it("injects baggage header", function()
            local carrier = test_utils.new_carrier({ foo = "bar" })
            local bgg = baggage.new({})
            bgg = bgg:set_value("userId", "Amélie", "mycoolmetadata;hi=mom")
            local ctx = context.new()
            ctx = ctx:inject_baggage(bgg)
            local baggage_propagator = baggage_propagator.new()
            baggage_propagator:inject(ctx, carrier)
            assert.is_same("userId=Am%C3%A9lie;mycoolmetadata;hi=mom", carrier.req.get_headers()["baggage"])
        end)

        it("injects multiple values into header", function()
            local carrier = test_utils.new_carrier({ foo = "bar" })
            local bgg = baggage.new({})
            bgg = bgg:set_value("foo", "bar")
            bgg = bgg:set_value("userId", "Amélie", "mycoolmetadata;hi=mom")
            local ctx = context.new()
            ctx = ctx:inject_baggage(bgg)
            local baggage_propagator = baggage_propagator.new()
            baggage_propagator:inject(ctx, carrier)

            -- This is ugly. Tables have no intrinsic order in Lua, and I don't
            -- want to add computational overhead to the :inject method to make
            -- the test deterministic, so we need to check for both valid
            -- headers.
            local match = false
            for k, v in pairs({ "userId=Am%C3%A9lie;mycoolmetadata;hi=mom,foo=bar",
                "foo=bar,userId=Am%C3%A9lie;mycoolmetadata;hi=mom" }) do
                if carrier.req.get_headers()["baggage"] == v then
                    match = true
                    break
                end
            end
            assert.is_true(match)
        end)
    end)
end)
