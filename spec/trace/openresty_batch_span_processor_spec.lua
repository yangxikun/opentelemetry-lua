local bsp                = require("opentelemetry.trace.exporter.openresty_batch_span_processor")
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
            local _ctx_2, span_2 = tracer:start(context.current(), "ok")
            local _ctx_3, span_3 = tracer:start(context.current(), "ok")
            local test_bsp = bsp.new(otlpe, { max_queue_size = 2 })
            -- mark bsp as stopped so that no export takes place, allowing test
            -- of queue overflow.
            test_bsp.stopped = true
            test_bsp:on_end(span_1)
            test_bsp:on_end(span_2)
            test_bsp:on_end(span_3)
            assert.is_same(2, #test_bsp.queue)
            for _, v in ipairs(test_bsp.queue) do
                assert.are.same(v.name, "ok")
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
    end)

    describe("extract_batch", function()
        local test_bsp = bsp.new(otlpe, { max_queue_size = 1000 })
        it("returns empty tables when queue is empty", function()
            local queue, batch = bsp.extract_batch({}, 1)
            assert.are.same(queue, {})
            assert.are.same(batch, {})
        end)

        it("returns a batch-size table along and remainder of queue", function()
            local queue_arg = { 1, 2, 3, 4 }
            local queue, batch = bsp.extract_batch(queue_arg, 3)
            table.sort(queue)
            table.sort(batch)
            assert.are.same(queue, { 4 })
            assert.are.same(batch, { 1, 2, 3 })
        end)

        it("returns empty table and batch_sized batch if #queue == batch_size", function()
            local queue_arg = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
            local queue, batch = bsp.extract_batch(queue_arg, 10)
            table.sort(batch)
            assert.are.same(queue, {})
            assert.are.same(batch, queue_arg)
        end)

        it("returns empty table and batch encompassing entire queue when #queue < batch_size", function()
            local queue_arg = { 1, 2, 3 }
            local queue, batch = bsp.extract_batch(queue_arg, 10)
            table.sort(batch)
            assert.are.same(queue, {})
            assert.are.same(batch, queue_arg)
        end)
    end)

    describe("flush_all", function()
        it("calls export_batch once if queue length is max batch size", function()
            local test_bsp = bsp.new(otlpe, { max_queue_size = 2, max_export_batch_size = 2 })
            stub(test_bsp, "export_batch")
            local _ctx, span_1 = tracer:start(context.current(), "a")
            local _ctx_2, span_2 = tracer:start(context.current(), "b")
            test_bsp.queue = { span_1, span_2 }

            test_bsp:force_flush()
            assert.stub(test_bsp.export_batch).was.called(1)
        end)

        it("calls export_batch until queue is empty", function()
            local test_bsp = bsp.new(otlpe, { max_queue_size = 7, max_export_batch_size = 3 })
            stub(test_bsp, "export_batch")
            local _ctx, span_1 = tracer:start(context.current(), "a")
            local _ctx_2, span_2 = tracer:start(context.current(), "b")
            local _ctx_3, span_3 = tracer:start(context.current(), "c")
            local _ctx_4, span_4 = tracer:start(context.current(), "d")
            local _ctx_5, span_5 = tracer:start(context.current(), "e")
            local _ctx_6, span_6 = tracer:start(context.current(), "f")
            local _ctx_7, span_7 = tracer:start(context.current(), "g")
            test_bsp.queue = { span_1, span_2, span_3, span_4, span_5, span_6, span_7 }

            test_bsp:force_flush()
            assert.stub(test_bsp.export_batch).was.called(3)
        end)

        it("does not call export_batch if queue is empty", function()
            local test_bsp = bsp.new(otlpe, { max_queue_size = 7, max_export_batch_size = 3 })
            stub(test_bsp, "export_batch")
            test_bsp:force_flush()
            assert.stub(test_bsp.export_batch).was_not_called()
        end)

        it("does not call export_batch if .stopped is true", function()
            local test_bsp = bsp.new(otlpe, {})
            stub(test_bsp, "export_batch")
            test_bsp.stopped = true
            test_bsp:force_flush()
            assert.stub(test_bsp.export_batch).was_not_called()
        end)
    end)
end)
