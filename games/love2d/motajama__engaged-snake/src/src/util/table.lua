local TableUtil = {}

function TableUtil.shallow_copy(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

function TableUtil.deep_copy(source)
    if type(source) ~= "table" then
        return source
    end

    local result = {}
    for key, value in pairs(source) do
        result[TableUtil.deep_copy(key)] = TableUtil.deep_copy(value)
    end
    return result
end

function TableUtil.merge(base, overrides)
    local result = TableUtil.shallow_copy(base)
    for key, value in pairs(overrides or {}) do
        result[key] = value
    end
    return result
end

function TableUtil.contains(list, needle)
    for _, value in ipairs(list or {}) do
        if value == needle then
            return true
        end
    end
    return false
end

return TableUtil
