local http = require("resty.http")
local client = require "opentelemetry.trace.exporter.http_client"
local zlib = require("zlib")

describe("export_spans", function()
    it("invokes an HTTP request", function ()
        local httpc = http.new()
        spy.on(httpc, "request_uri")
        local c = client.new("http://localhost:8080", 10, nil, httpc)
        local expected_headers = {}
        expected_headers["Content-Type"] = "application/x-protobuf"

        c:do_request("Hello, World!")
        assert.spy(httpc.request_uri).was_called_with(
            match.is_truthy(), -- TODO(wperron) this *should* be the same ref, why is it not?
            match.is_equal("http://localhost:8080/v1/traces"),
            match.is_all_of(
                match.is_table(),
                match.is_same({
                    method = "POST",
                    headers = expected_headers,
                    body = "Hello, World!"
                })
            )
        )
    end)

    it("compresses the body when asked to", function ()
        local httpc = http.new()
        spy.on(httpc, "request_uri")
        local c = client.new("http://localhost:8080", 10, nil, httpc)
        local expected_headers = {}
        expected_headers["Content-Type"] = "application/x-protobuf"
        expected_headers["Content-Encoding"] = "gzip"
        local expected_body = string.fromhex("1F8B0800000000000203F348CDC9C9D75108CF2FCA49510400D0C34AEC0D000000")

        c:do_request("Hello, World!", true)
        assert.spy(httpc.request_uri).was_called_with(
            match.is_truthy(), -- TODO(wperron) this *should* be the same ref, why is it not?
            match.is_equal("http://localhost:8080/v1/traces"),
            match.is_all_of(
                match.is_table(),
                match.is_same({
                    method = "POST",
                    headers = expected_headers,
                    body = expected_body
                })
            )
        )
    end)
end)

function string.fromhex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end
