local chars = {"a", "b", "c", "d", "e", "f", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}

local _M = {}

local function gen_id(length)
    local randomString = ""
    for i = 1, length do
        randomString = randomString .. chars[math.random(1, #chars)]
    end
    return randomString
end

function _M.new_span_id()
    return gen_id(16)
end

function _M.new_ids()
    return gen_id(32), gen_id(16)
end

return _M