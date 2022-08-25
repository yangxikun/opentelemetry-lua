local span_kind   = require("opentelemetry.trace.span_kind")
local span_status = require("opentelemetry.trace.span_status")
local event_new   = require("opentelemetry.trace.event").new
local attribute   = require("opentelemetry.attribute")
local util        = require("opentelemetry.util")

local _M = {
}

local mt = {
    __index = _M
}

------------------------------------------------------------------
-- create a recording span.
--
-- @tracer
-- @parent_ctx          parent span context
-- @ctx                 current span context
-- @name                span name
-- @config              optional config
--                          config.kind: span kind
--                          config.attributes: span attributes
-- @return              span
------------------------------------------------------------------
function _M.new(tracer, parent_ctx, ctx, name, config)
    local self = {
        tracer = tracer,
        parent_ctx = parent_ctx,
        ctx = ctx,
        name = name,
        start_time = util.time_nano(),
        end_time = 0,
        kind = span_kind.validate(config.kind),
        attributes = config.attributes or {},
        events = {},
    }
    return setmetatable(self, mt)
end

function _M.context(self)
    return self.ctx
end

function _M.is_recording(self)
    return self.end_time == 0
end

------------------------------------------------------------------
-- set span status.
--
-- @code             see opentelemetry.trace.span_status.*
-- @message          error msg
------------------------------------------------------------------
function _M.set_status(self, code, message)
    if not self:is_recording() then
        return
    end

    code = span_status.validate(code)
    local status = {
        code = code,
        message = ""
    }
    if code == span_status.error then
        status.message = message
    end

    self.status = status
end

function _M.set_attributes(self, ...)
    if not self:is_recording() then
        return
    end

    for _, attr in ipairs({ ... }) do
        table.insert(self.attributes, attr)
    end
end

------------------------------------------------------------------
-- `end` is key word, so we use finish
------------------------------------------------------------------
function _M.finish(self)
    if not self:is_recording() then
        return
    end

    self.end_time = util.time_nano()
    for _, sp in ipairs(self.tracer.provider.span_processors) do
        sp:on_end(self)
    end
end

------------------------------------------------------------------
-- add a error event
--
-- @error           a string describe the error
------------------------------------------------------------------
function _M.record_error(self, error)
    if error == nil or (type(error) ~= "string") or (not self:is_recording()) then
        return
    end

    table.insert(self.events, event_new("exception", {
        attributes = { attribute.string("exception.message", error) },
    }))
end

------------------------------------------------------------------
-- add a custom event
--
-- @opts           [optional]
--                      opts.attributes: a list of attribute
------------------------------------------------------------------
function _M.add_event(self, name, opts)
    if not self:is_recording() then
        return
    end

    table.insert(self.events, event_new(name, {
        attributes = opts.attributes,
    }))
end

------------------------------------------------------------------
-- update span name
------------------------------------------------------------------
function _M.set_name(self, name)
    self.name = name
end

function _M.tracer_provider(self)
    return self.tracer.provider
end

local function hex2bytes(str)
    return (str:gsub('..', function(cc)
        local n = tonumber(cc, 16)
        if n then
            return string.char(n)
        end
    end))
end

function _M.for_otlp_export(self)
    return {
        trace_id = hex2bytes(self.ctx.trace_id),
        span_id = hex2bytes(self.ctx.span_id),
        trace_state = "",
        parent_span_id = self.parent_ctx.span_id and hex2bytes(self.parent_ctx.span_id) or "",
        name = self.name,
        kind = self.kind,
        start_time_unix_nano = string.format("%d", self.start_time),
        end_time_unix_nano = string.format("%d", self.end_time),
        attributes = self.attributes,
        dropped_attributes_count = 0,
        events = self.events,
        dropped_events_count = 0,
        links = {},
        dropped_links_count = 0,
        status = self.status
    }
end

function _M.plain(self)
    return {
        tracer = { il = self.tracer.il },
        parent_ctx = self.parent_ctx:plain(),
        ctx = self.ctx:plain(),
        name = self.name,
        start_time = self.start_time,
        end_time = self.end_time,
        kind = self.kind,
        attributes = self.attributes,
        events = self.events,
    }
end

return _M
