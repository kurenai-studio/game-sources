-- A selection is a set of cards
--
-- All functions from this module do not modify
-- card properties!

local Selection = {}

function Selection:getOrigin (selection)
    local origin
    for card in pairs(selection) do
        if origin == nil then
            origin = card.origin
        elseif origin ~= card.origin then
            return
        end
    end
    return origin
end

function Selection:filter (selection, predicate)
    local filteredSelection = {}
    for card in pairs(selection) do
        if predicate(card) then
            filteredSelection[card] = true
        end
    end
    return filteredSelection
end

function Selection:minus (sel1, sel2)
    local newsel = {}
    for card in pairs(sel1) do
        if sel2[card] == nil then
            newsel[card] = true
        end
    end
    return newsel
end

function Selection:plus (sel1, sel2)
    local newsel = {}
    for card in pairs(sel1) do
        newsel[card] = true
    end
    for card in pairs(sel2) do
        newsel[card] = true
    end
    return newsel
end

return Selection
