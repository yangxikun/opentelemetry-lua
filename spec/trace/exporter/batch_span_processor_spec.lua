local bsp                = require("opentelemetry.trace.batch_span_processor")
local otlpe              = require("opentelemetry.trace.exporter.otlp")
local context            = require("opentelemetry.context")
local span_ctx           = require("opentelemetry.trace.span_context")
local non_recording_span = require("opentelemetry.trace.non_recording_span")
local tracer             = Global.tracer("test", { version = "wat", schema_url = "ok" })

describe("batch span processor", function()
    describe("on_end", function()
        it("adds spans to queue", function()
            local ctx, span_1 = tracer:start(context.current(), "test")
            local _ctx_2, span_2 = tracer:start(ctx, "test")
            local test_bsp = bsp.new(otlpe)
            test_bsp:on_end(span_1)
            test_bsp:on_end(span_2)
            assert.is_same(2, #test_bsp.queue)
        end)

        it("drops spans when queue is full", function()
            local _ctx, span_1 = tracer:start(context.current(), "should be dropped")
            local test_bsp = bsp.new(otlpe, { max_queue_size = 2, max_export_batch_size = 1 })
            test_bsp.queue = { { name = "keepme" }, { name = "keepme" } }
            test_bsp:on_end(span_1)
            assert.is_same(2, #test_bsp.queue)
            for _, v in ipairs(test_bsp.queue) do
                assert.are.same(v.name, "keepme")
            end
        end)

        it("does not add unsampled spans to queue", function()
            local span_context = span_ctx.new(nil, nil, 0)
            local span = non_recording_span.new(tracer, span_context)
            assert.is_false(span.ctx:is_sampled())
            local test_bsp = bsp.new(otlpe, { max_queue_size = 1000 })
            test_bsp:on_end(span)
            assert.is_same(0, #test_bsp.queue)
        end)

        it("creates a batch if batch_timeout reached", function()
            local _ctx, span = tracer:start(context.current(), "should be dropped")
            local test_bsp = bsp.new(otlpe,
                { max_queue_size = 4, max_export_batch_size = 3 }
            )
            test_bsp.queue = { "foo" }
            -- tell bsp that the last span was created at unix time 0
            test_bsp.first_queue_t = 0
            -- tell bsp that timer is running so that it does not attempt export
            test_bsp.process_batches_timer_running = true
            test_bsp:on_end(span)
            assert.is_same(0, #test_bsp.queue)
            assert.is_same(1, #test_bsp.batches_to_process)
        end)

        it("creates a batch if batch_size reached", function()
            local _ctx, span = tracer:start(context.current(), "should be dropped")
            local test_bsp = bsp.new(otlpe,
                { max_queue_size = 4, max_export_batch_size = 2 }
            )
            test_bsp.queue = { 1 }
            -- tell bsp that timer is running so that it does not attempt export
            test_bsp.process_batches_timer_running = true
            test_bsp:on_end(span)
            assert.is_same(0, #test_bsp.queue)
            assert.is_same(1, #test_bsp.batches_to_process)
        end)
    end)
end)
