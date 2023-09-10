local _M = {}

function _M.string(key, value)
    return {
        key = key,
        value = {
            string_value = value,
        }
    }
end

function _M.string_array(key, values)
    local ret = {
        key = key,
        value = {
            array_value = {
                values = {}
            }
        }
    }
    for i = 1, #values do
        table.insert(ret.value.array_value.values, {string_value = values[i]})
    end
    return ret
end

function _M.int(key, value)
    return {
        key = key,
        value = {
            int_value = value,
        }
    }
end

function _M.int_array(key, values)
    local ret = {
        key = key,
        value = {
            array_value = {
                values = {}
            }
        }
    }
    for i = 1, #values do
        table.insert(ret.value.array_value.values, {int_value = values[i]})
    end
    return ret
end

function _M.bool(key, value)
    return {
        key = key,
        value = {
            bool_value = value,
        }
    }
end

function _M.bool_array(key, values)
    local ret = {
        key = key,
        value = {
            array_value = {
                values = {}
            }
        }
    }
    for i = 1, #values do
        table.insert(ret.value.array_value.values, {bool_value = values[i]})
    end
    return ret
end

function _M.double(key, value)
    return {
        key = key,
        value = {
            double_value = value,
        }
    }
end

function _M.double_array(key, values)
    local ret = {
        key = key,
        value = {
            array_value = {
                values = {}
            }
        }
    }
    for i = 1, #values do
        table.insert(ret.value.array_value.values, {double_value = values[i]})
    end
    return ret
end

return _M