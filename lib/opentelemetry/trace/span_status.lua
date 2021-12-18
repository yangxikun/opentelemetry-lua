local _M = {
    unset = 0,
    ok    = 1,
    error = 2,
}

-- returns a valid span status code
function _M.validate(code)
    if not code or code < 0 or code > 2 then
        -- default unset
        return 0
    end
    return code
end

return _M
