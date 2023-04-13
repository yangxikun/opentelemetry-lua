local id_generator = require("opentelemetry.trace.id_generator")

describe("new_span_id", function()
    it("generates a 16 character hex string", function()
        for _ = 0, 100 do
            assert.is_equal(16, #id_generator.new_span_id())
        end
    end)
end)

describe("new_ids", function()
    it("generates a 16 character hex string and a 32 character string", function()
        for _ = 0, 100 do
            local trace_id, span_id = id_generator.new_ids()
            assert.is_equal(32, #trace_id)
            assert.is_equal(16, #span_id)
        end
    end)
end)
