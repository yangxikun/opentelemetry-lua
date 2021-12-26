local global  = require("opentelemetry.global")
local context = require("opentelemetry.context")
local tracer  = require("opentelemetry.trace.tracer")
local recording_span = require("opentelemetry.trace.recording_span")
local span_context   = require("opentelemetry.trace.span_context")

local _M = {}

local mt = {
    __index = _M
}

function _M.new(dynamic_metadata)
    return setmetatable({dynamic_metadata = dynamic_metadata}, mt)
end

function _M.get(self, key)
    local m = self.dynamic_metadata:get("opentelemetry-lua")
    if m then
        local plain_span = m[key]
        if plain_span then
            -- 恢复 table 的函数字段
            plain_span.tracer = setmetatable(plain_span.tracer, {__index = tracer})
            plain_span.tracer.provider = global.get_tracer_provider()
            if plain_span.parent_ctx then
                plain_span.parent_ctx = setmetatable(plain_span.parent_ctx, {__index = span_context})
            end
            plain_span.ctx = setmetatable(plain_span.ctx, {__index = span_context})
            local span = setmetatable(plain_span, {__index = recording_span})
            return setmetatable({sp = span}, {__index = context})
        end
    end
end

function _M.set(self, key, val)
    -- 移除 table 的函数字段
    local plain_span = val.sp:plain()
    self.dynamic_metadata:set("opentelemetry-lua", key, plain_span)
end

return _M