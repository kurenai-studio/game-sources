local Levels = {}

function Levels.get_level(dataset, index)
    return dataset.levels[index]
end

function Levels.count(dataset)
    return #(dataset.levels or {})
end

return Levels
