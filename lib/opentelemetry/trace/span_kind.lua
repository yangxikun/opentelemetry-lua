local _M = {
    unspecified  = 0,
    internal = 1,
    server = 2,
    client = 3,
    producer = 4,
    consumer = 5,
}

-- returns a valid span kind value
function _M.validate(kind)
    if not kind or kind < 0 or kind > 5 then
        -- default internal
        return 1
    end
    return kind
end

return _M
