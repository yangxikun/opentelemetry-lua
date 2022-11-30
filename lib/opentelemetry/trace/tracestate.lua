local _M = {
    MAX_KEY_LEN = 256,
    MAX_VAL_LEN = 256,
    MAX_ENTRIES = 32,
}

local mt = {
    __index = _M
}

local function validate_member_key(key)
    if #key > _M.MAX_KEY_LEN then
        return nil
    end

    local valid_key = string.match(key, [[^%s*([a-z][_0-9a-z%-*/]*)$]])
    if not valid_key then
        local tenant_id, system_id = string.match(key, [[^%s*([a-z0-9][_0-9a-z%-*/]*)@([a-z][_0-9a-z%-*/]*)$]])
        if not tenant_id or not system_id then
            return nil
        end
        if #tenant_id > 241 or #system_id > 14 then
            return nil
        end
        return tenant_id .. "@" .. system_id
    end

    return valid_key
end

local function validate_member_value(value)
    if #value > _M.MAX_VAL_LEN then
        return nil
    end
    return string.match(value,
        [[^([ !"#$%%&'()*+%-./0-9:;<>?@A-Z[\%]^_`a-z{|}~]*[!"#$%%&'()*+%-./0-9:;<>?@A-Z[\%]^_`a-z{|}~])%s*$]])
end

function _M.new(values)
    local self = { values = values }
    return setmetatable(self, mt)
end

--------------------------------------------------------------------------------
-- Parse tracestate header into a tracestate
--
-- @return              tracestate
--------------------------------------------------------------------------------
function _M.parse_tracestate(tracestate)
    if not tracestate then
        return _M.new({})
    end
    -- if there is only one tracestate header it comes in as a string, otherwise its a table
    if type(tracestate) == "string" then
        tracestate = { tracestate }
    end

    local new_tracestate = {}
    local members_count = 0
    local error_message = "failed to parse tracestate"
    for _, item in ipairs(tracestate) do
        for member in string.gmatch(item, "([^,]+)") do
            if member ~= "" then
                local start_pos, end_pos = string.find(member, "=", 1, true)
                if not start_pos or start_pos == 1 then
                    ngx.log(ngx.WARN, error_message)
                    return _M.new({})
                end
                local key = validate_member_key(string.sub(member, 1, start_pos - 1))
                if not key then
                    ngx.log(ngx.WARN, error_message)
                    return _M.new({})
                end
                local value = validate_member_value(string.sub(member, end_pos + 1))
                if not value then
                    ngx.log(ngx.WARN, error_message)
                    return _M.new({})
                end
                members_count = members_count + 1
                if members_count > _M.MAX_ENTRIES then
                    ngx.log(ngx.WARN, error_message)
                    return _M.new({})
                end
                table.insert(new_tracestate, {key, value})
            end
        end
    end

    return _M.new(new_tracestate)
end

--------------------------------------------------------------------------------
-- Set the key value pair for the tracestate
--
-- @return              tracestate
--------------------------------------------------------------------------------
function _M.set(self, key, value)
    if not validate_member_key(key) then
        return self
    end
    if not validate_member_value(value) then
        return self
    end
    self:del(key)
    if #self.values >= _M.MAX_ENTRIES then
        table.remove(self.values)
        ngx.log(ngx.WARN, "tracestate max values exceeded, removing rightmost entry")
    end
    table.insert(self.values, 1, {key, value})
    return self
end

--------------------------------------------------------------------------------
-- Get the value for the current key from the tracestate
--
-- @return              value
--------------------------------------------------------------------------------
function _M.get(self, key)
    for _, item in ipairs(self.values) do
        local ckey = item[1]
        if ckey == key then
            return item[2]
        end
    end
    return ""
end

--------------------------------------------------------------------------------
-- Delete the key from the tracestate
--
-- @return              tracestate
--------------------------------------------------------------------------------
function _M.del(self, key)
    local index = 0
    for i, item in ipairs(self.values) do
        local ckey = item[1]
        if ckey == key then
            index = i
            break
        end
    end
    if index ~= 0 then
        table.remove(self.values, index)
    end
    return self
end

--------------------------------------------------------------------------------
-- Return the header value of the tracestate
--
-- @return              string
--------------------------------------------------------------------------------
function _M.as_string(self)
    local output = {}
    for _, item in ipairs(self.values) do
        table.insert(output, item[1] .. "=" .. item[2])
    end
    return table.concat(output, ",")
end

return _M
