local evs = require("opentelemetry.api.utils.env_var_settings")

describe("getenv_with_fallback", function()
    it("uses env var value if set", function()
        stub(os, "getenv").returns("envvarvalue")
        assert.are_equal(evs.getenv_with_fallback("FOOBAR", "fallback"), "envvarvalue")
    end)

    it("uses fallback value if env var is nil", function()
        stub(os, "getenv").returns(nil)
        assert.are_equal(evs.getenv_with_fallback("FOOBAR", "fallback"), "fallback")
    end)
end)

describe("log_level", function()
    before_each(function()
        package.loaded["opentelemetry.api.utils.env_var_settings"] = nil
    end)

    it("defaults to warn", function()
        evs = require("opentelemetry.api.utils.env_var_settings")
        assert.are_equal(evs.log_level, "warn")
    end)

    it("respects OTEL_LOG_LEVEL variable", function()
        stub(os, "getenv").returns("debug")
        evs = require("opentelemetry.api.utils.env_var_settings")
        assert.are_equal(evs.log_level, "debug")
    end)
end)
