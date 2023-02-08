local logger = require("opentelemetry.utils.logger.nginx"):new("crit")

-- This test is just here to flex the logger and make sure that it doesn't
-- crash. It'll only fail if there are errors
describe("logging", function()
    it("logs out as expected", function()
        logger:debug("This should not show up in test output")
        logger:info("This should not show up in test output")
        logger:notice("This should not show up in test output")
        logger:warn("This should not show up in test output")
        logger:error("This should not show up in test output")
        logger:crit("This should show up in test output")
        logger:alert("This should show up in test output")
        logger:emerg("This should show up in test output")
    end)
end)
