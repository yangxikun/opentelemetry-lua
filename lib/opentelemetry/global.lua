_M = { context_storage = ngx.ctx }

function _M.set_tracer_provider(tp)
    _M.tracer_provider = tp
end

function _M.get_tracer_provider()
    return _M.tracer_provider
end

function _M.tracer(name, opts)
    return _M.tracer_provider:tracer(name, opts)
end

function _M.set_context_storage(context_storage)
    _M.context_storage = context_storage
end

function _M.context_storage()
    return _M.context_storage
end

return _M
