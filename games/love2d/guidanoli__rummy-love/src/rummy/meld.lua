-- A meld is a list of cards
--
-- All functions from this module do not modify
-- card properties!

local Selection = require "rummy.selection"

local Meld = {}

function Meld:hasSameSuit (meld)
    local suit
    for _, card in pairs(meld) do
        if suit == nil then
            suit = card.suit
        elseif suit ~= card.suit then
            return false
        end
    end
    return true
end

function Meld:isSequential (meld)
    local prev
    for _, card in ipairs(meld) do
        if prev ~= nil then
            if not ((prev.rank == 13 and card.rank == 1) or
                    (card.rank == prev.rank + 1)) then
                return false
            end
        end
        prev = card
    end
    return true
end

function Meld:hasNoMiddleAce (meld)
    for pos = 2, #meld - 1 do
        local card = meld[pos]
        if card.rank == 1 then
            return false
        end
    end
    return true
end

function Meld:hasNoDuplicateAce (meld)
    local n = 0
    for _, card in pairs(meld) do
        if card.rank == 1 then
            n = n + 1
        end
    end
    return n <= 1
end

function Meld:isRun (meld)
    return #meld >= 3 and
           self:hasSameSuit(meld) and
           self:isSequential(meld) and
           self:hasNoMiddleAce(meld) and
           self:hasNoDuplicateAce(meld)
end

function Meld:hasSameRank (meld)
    local rank
    for _, card in pairs(meld) do
        if rank == nil then
            rank = card.rank
        elseif rank ~= card.rank then
            return false
        end
    end
    return true
end

function Meld:hasDifferentSuits (meld)
    local hasSuit = {}
    for _, card in pairs(meld) do
        if hasSuit[card.suit] then
            return false
        else
            hasSuit[card.suit] = true
        end
    end
    return true
end

function Meld:isSet (meld)
    return #meld >= 3 and
           self:hasSameRank(meld) and
           self:hasDifferentSuits(meld)
end

function Meld:isValid (meld)
    return self:isRun(meld) or
           self:isSet(meld)
end

local function orderWithStartingAce (card1, card2)
    if card1.rank == card2.rank then
        return card1.suit < card2.suit
    else
        return card1.rank < card2.rank
    end
end

local function orderWithEndingAce (card1, card2)
    if card1.rank == card2.rank then
        return card1.suit < card2.suit
    else
        return (card1.rank + 11) % 13 < (card2.rank + 11) % 13
    end
end

function Meld:containsCardOfRank (meld, rank)
    for _, card in pairs(meld) do
        if card.rank == rank then
            return true
        end
    end
    return false
end

function Meld:sort (meld)
    if self:containsCardOfRank(meld, 2) then
        table.sort(meld, orderWithStartingAce)
    else
        table.sort(meld, orderWithEndingAce)
    end
end

function Meld:fromSelection (sel)
    local meld = {}
    for card in pairs(sel) do
        table.insert(meld, card)
    end
    self:sort(meld)
    return meld
end

function Meld:toSelection (meld)
    local sel = {}
    for _, card in ipairs(meld) do
        sel[card] = true
    end
    return sel
end

function Meld:minus (meld1, meld2)
    local sel1 = self:toSelection(meld1)
    local sel2 = self:toSelection(meld2)
    local newsel = Selection:minus(sel1, sel2)
    return self:fromSelection(newsel)
end

function Meld:plus (meld1, meld2)
    local sel1 = self:toSelection(meld1)
    local sel2 = self:toSelection(meld2)
    local newsel = Selection:plus(sel1, sel2)
    return self:fromSelection(newsel)
end

return Meld
