local _M = {}

function _M.string(key, value)
    return {
        key = key,
        value = {
            string_value = value,
        }
    }
end

function _M.int(key, value)
    return {
        key = key,
        value = {
            int_value = value,
        }
    }
end

function _M.bool(key, value)
    return {
        key = key,
        value = {
            bool_value = value,
        }
    }
end

function _M.double(key, value)
    return {
        key = key,
        value = {
            double_value = value,
        }
    }
end

return _M