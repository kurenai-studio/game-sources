local utils = {}

function utils:shuffleInPlace (t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function utils:orderOpenEnded (a, b)
    if a < b then
        return a + 1, b
    else
        return b, a - 1
    end
end

function utils:sortedKeys (t, cmp)
    local keys = {}
    for key in pairs(t) do
        table.insert(keys, key)
    end
    table.sort(keys, cmp)
    return keys
end

function utils:deepCopy (o)
    if type(o) == 'table' then
        local t = {}
        local mt = getmetatable(o)
        setmetatable(t, mt)
        for k, v in pairs(o) do
            local kcopy = self:deepCopy(k)
            local vcopy = self:deepCopy(v)
            t[kcopy] = vcopy
        end
        return t
    else
        return o
    end
end

return utils
