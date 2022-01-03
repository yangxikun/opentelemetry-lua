local result_new = require("opentelemetry.trace.sampling.result").new

local _M = {
}

local mt = {
    __index = _M
}

------------------------------------------------------------------
-- a composite sampler which behaves differently,
-- based on the parent of the span. If the span has no parent,
-- the root(Sampler) is used to make sampling decision. If the span has
-- a parent, depending on whether the parent is sampled.
--
-- @root                sampler
-- @return              sampler
------------------------------------------------------------------
function _M.new(root)
    return setmetatable({root = root}, mt)
end

function _M.should_sample(self, parameters)
    local parent_ctx = parameters.parent_ctx
    if parent_ctx:is_valid() then
        if parent_ctx:is_remote() then
            if parent_ctx:is_sampled() then
                return result_new(2, parameters.parent_ctx.trace_state)
            end
            return result_new(0, parameters.parent_ctx.trace_state)
        end

        if parent_ctx:is_sampled() then
            return result_new(2, parameters.parent_ctx.trace_state)
        end
        return result_new(0, parameters.parent_ctx.trace_state)
    end

    return self.root:should_sample(parameters)
end

function _M.description(self)
    return string.format("ParentBased{root:%s}", self.root:description())
end

return _M
