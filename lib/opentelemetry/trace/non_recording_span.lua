local _M = {
}

local mt = {
    __index = _M
}

function _M.new(tracer, ctx)
    local self = {
        tracer = tracer,
        ctx = ctx,
    }
    return setmetatable(self, mt)
end

function _M.context(self)
    return self.ctx
end

function _M.is_recording()
    return false
end

function _M.set_status()
end

function _M.set_attributes()
end

function _M.finish(_self, _end_timestamp)
end

function _M.record_error()
end

function _M.add_event()
end

function _M.set_name()
end

function _M.tracer_provider(self)
    return self.tracer.provider
end

function _M.plain(self)
    return {
        ctx = self.ctx
    }
end

return _M
