local baggage = require("opentelemetry.baggage")

describe("set_value and get_value", function()
    it("sets a value and returns baggage instance", function()
        local baggage = baggage.new({ oldkey = { value = "wat" } })
        local new_baggage = baggage:set_value("keyname", "val", "metadatastring")
        assert.are.equal(new_baggage:get_value("keyname"), "val")
        assert.are.equal(new_baggage:get_value("oldkey"), "wat")
    end)

    it("overwrites keys", function()
        local baggage = baggage.new({ oldkey = { value = "wat" } })
        local new_baggage = baggage:set_value("oldkey", "newvalue")
        assert.are.equal(new_baggage:get_value("oldkey"), "newvalue")
    end)
end)

describe("get__all_values", function()
    it("returns all values", function()
        local values = { key1 = { value = "wat", metadata = "ignore" }, key2 = { value = "wat2", metadata } }
        local baggage = baggage.new(values)
        assert.are.same(baggage:get_all_values(), values)
    end)
end)

describe("remove_value", function()
    it("returns new baggage instance without value", function()
        local values = { key1 = { value = "wat" }, key2 = { value = "wat2" } }
        local baggage = baggage.new(values)
        local new_baggage = baggage:remove_value("key1")
        assert.are.same(new_baggage:get_all_values(), { key2 = { value = "wat2" } })
    end)
end)
