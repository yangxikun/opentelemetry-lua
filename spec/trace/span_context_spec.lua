local span_context = require("opentelemetry.trace.span_context")

describe("is_valid", function()
    it("returns false when traceid == 00000000000000000000000000000000", function()
        local sp_ctx = span_context.new("00000000000000000000000000000000", "1234567890123456", 1, nil, false)
        assert.is_not_true(sp_ctx:is_valid())
    end)

    it("returns false when spanid == 0000000000000000", function()
        local sp_ctx = span_context.new("00000000000000000000000000000001", "0000000000000000", 1, nil, false)
        assert.is_not_true(sp_ctx:is_valid())
    end)
end)
