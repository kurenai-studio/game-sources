local constants = {}

do
    local ranks = {}
    for i = 1, 13 do
        ranks[i] = true
    end
    constants.ranks = ranks
end

do
    local suits = {
        "diamonds",
        "hearts",
        "clubs",
        "spades",
    }
    local suitSet = {}
    for _, suit in pairs(suits) do
        suitSet[suit] = true
    end
    constants.suits = suitSet
end

do
    local origins = {
        "stock",
        "hand",
        "meld",
    }
    local originSet = {}
    for _, origin in pairs(origins) do
        originSet[origin] = true
    end
    constants.origins = originSet
end

do
    local customRankNames = {
        [1] = "Ace",
        [11] = "Jack",
        [12] = "Queen",
        [13] = "King",
    }
    local rankNames = {}
    for rank in pairs(constants.ranks) do
        rankNames[rank] = customRankNames[rank] or tostring(rank)
    end
    constants.rankNames = rankNames
end

do
    local animations = {
        "smooth",
    }
    local animationSet = {}
    for _, animation in pairs(animations) do
        animationSet[animation] = true
    end
    constants.animations = animationSet
end

return constants
