local logger = require("opentelemetry.api.utils.logger.base")

describe("new", function()
    it("honors valid log levels", function()
        package.path = package.path .. ';../?.lua'
        local l = logger:new("debug")
        assert.are.equal(l.log_level, 8)
    end)

    it("sets log level to error if not present in log_levels hash", function()
        local l = logger:new("foobar")
        assert.are.equal(l.log_level, 4)
    end)
end)
