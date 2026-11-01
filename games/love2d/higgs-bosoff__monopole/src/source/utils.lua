local Utils = {}

function Utils.axis(pos, neg)
    return (pos and 1 or 0) - (neg and 1 or 0)
end

function Utils.clip(x, min, max)
    x = math.min(x, max)
    x = math.max(x, min)

    return x
end

return Utils