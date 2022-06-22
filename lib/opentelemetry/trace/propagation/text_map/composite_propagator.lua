local _M = {
}

local mt = {
    __index = _M
}

function _M.new(propagators)
    return setmetatable({ propagators = propagators }, mt)
end

function _M:composite_inject(context, carrier)
    for i = 1, #self.propagators do
        self.propagators[i]:inject(context, carrier)
    end
end

function _M:composite_extract(context, carrier)
    return 2
end

function _M.fields()
    return { traceparent_key, tracestate_key }
end

return _M
