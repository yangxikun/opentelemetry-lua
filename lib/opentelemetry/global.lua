local _M = {}

function _M.set_tracer_provider(tp)
    _M.tracer_provider = tp
end

function _M.get_tracer_provider()
    return _M.tracer_provider
end

function _M.tracer(name, opts)
    return _M.tracer_provider:tracer(name, opts)
end

return _M