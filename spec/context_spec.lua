local context = require("opentelemetry.context")
local otel_global = require("opentelemetry.global")
local baggage = require("opentelemetry.baggage")

describe("get and set", function()
    it("stores and retrieves values at given key", function()
        local ctx = context.new()
        local new_ctx = ctx:set("key", "value")
        assert.are.equal(new_ctx:get("key"), "value")
        assert.are_not.equal(ctx, new_ctx)
    end)
end)

describe("current", function()
    it("returns last element stored in stack at context_key", function()
        local ctx_1 = context.new({ foo = "bar"})
        local ctx_2 = context.new({ foo = "baz"})
        local ctx_storage = { __opentelemetry_context__ = {ctx_1, ctx_2} }
        otel_global.set_context_storage(ctx_storage)
        assert.are.equal(ctx_2, context.current())
    end)

    it("instantiates different noop spans when no span provided", function()
        local ctx_1 = context.new()
        local ctx_2 = context.new()

        -- accessing span context on different contexts gives different object back
        assert.are_not.equal(ctx_1.sp:context(), ctx_2.sp:context())
        assert.are_not.equal(ctx_1.sp:context().trace_state, ctx_2.sp:context().trace_state)

        -- accessing span context on same context gives same object back
        assert.are.equal(ctx_1.sp:context(), ctx_1.sp:context())
    end)
end)

describe("with_span", function()
    it("sets supplied entries on new context", function()
        otel_global.set_context_storage({})
        local original_entries = { foo = "bar" }
        local old_ctx = context.new(original_entries, "oldspan")
        local ctx = old_ctx:with_span("myspan")
        assert.are.same(ctx.entries, original_entries)
    end)

    it("handles absence of entries arg gracefully", function()
        local fake_span = "hi"
        local ctx = context:with_span(fake_span)
        assert.are.same(ctx.entries, {})
    end)
end)

describe("attach", function()
    it("creates new table at context_key if no table present and returns token matching length of stack after adding element", function()
        local ctx_storage = {}
        otel_global.set_context_storage(ctx_storage)
        local ctx = context.new({ foo = "bar"})
        local token = ctx:attach()
        assert.are.equal(token, 1)
    end)

    it("appends to existing table at context_key", function()
        local ctx_storage = {}
        otel_global.set_context_storage(ctx_storage)
        local ctx_1 = context.new({ foo = "bar"})
        local ctx_2 = context.new({ foo = "baz"})
        local token_1 = ctx_1:attach()
        local token_2 = ctx_2:attach()
        assert.are.equal(token_1, 1)
        assert.are.equal(token_2, 2)
    end)
end)

describe("detach", function()
    it("removes final context from stack at context_key", function()
        local ctx_storage = {}
        otel_global.set_context_storage(ctx_storage)
        local ctx = context.new()
        local token = ctx:attach()
        local outcome, err = ctx:detach(token)
        assert.is_true(outcome)
        assert.is_nil(err)
    end)

    it("returns outcome of 'false' and error string if token does not match", function()
        -- Swallow logs since we are expecting them
        stub(ngx, "log")
        local ctx_storage = {}
        otel_global.set_context_storage(ctx_storage)
        local ctx = context.new()
        ctx:attach()
        local outcome, err = ctx:detach(2)
        ngx.log:revert()
        assert.is_false(outcome)
        assert.is_same("Token does not match (1 context entries in stack, token provided was 2).", err)
    end)
end)

describe("inject and extract baggage", function()
    it("adds baggage to context and extracts it", function()
        local ctx = context.new(storage)
        local baggage = baggage.new({ key1 = { value = "wat" } })
        local new_ctx = ctx:inject_baggage(baggage)
        assert.are.same(new_ctx:extract_baggage(), baggage)
    end)
end)
