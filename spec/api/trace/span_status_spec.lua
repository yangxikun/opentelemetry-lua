local span_status = require("lib.opentelemetry.api.trace.span_status")

describe("new()", function()
    it("defaults to unset", function()
        local s = span_status:new()
        assert.are_same(s.code, span_status.UNSET)
    end)
end)
