local _M = {
}

function _M.new(name, version, schema_url)
    return {name=name, version=version, schema_url=schema_url}
end

return _M