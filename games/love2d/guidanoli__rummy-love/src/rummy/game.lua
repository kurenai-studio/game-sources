local constants = require "rummy.constants"
local utils = require "rummy.utils"
local Selection = require "rummy.selection"
local Card = require "rummy.card"
local Meld = require "rummy.meld"

local Game = {}
Game.__index = Game
Game.__name = 'Game'

-- Create a new game where player has 9 cards and
-- all the other cards are in the stock.
-- Uses the current random seed to shuffle the cards.
function Game:new ()
    local game = {
        cards = self:_newCards(),
    }
    setmetatable(game, self)
    game:_dealCards()
    return game
end

function Game:_newCards ()
    local cards = {}
    for suit in pairs(constants.suits) do
        for rank in pairs(constants.ranks) do
            local card = Card:new{
                suit = suit,
                rank = rank,
                origin = 'stock',
            }
            table.insert(cards, card)
        end
    end
    utils:shuffleInPlace(cards)
    local cardSet = {}
    for pos, card in ipairs(cards) do
        card.pos = pos
        cardSet[card] = true
    end
    return cardSet
end

function Game:applyMeldOrder (meld)
    for pos, card in ipairs(meld) do
        card:setPos(pos)
    end
end

function Game:_dealCards ()
    local cards = self:getCards()
    local handSelection = {}
    for i = 1, 9 do
        local card = table.remove(cards.stock)
        handSelection[card] = true
    end
    local hand = Meld:fromSelection(handSelection)
    self:applyMeldOrder(hand)
    self:setOrigin(hand, 'hand')
end

function Game:iterCards ()
    return pairs(self.cards)
end

function Game:getCards ()
    local stock = {}
    local hand = {}
    local melds = {}
    for card in self:iterCards() do
        if card.origin == 'stock' then
            stock[card.pos] = card
        elseif card.origin == 'hand' then
            hand[card.pos] = card
        elseif card.origin == 'meld' then
            local meld = melds[card.meldid]
            if meld == nil then
                meld = {}
                melds[card.meldid] = meld
            end
            meld[card.pos] = card
        else
            error("invalid origin")
        end
    end
    return {
        stock = stock,
        hand = hand,
        melds = melds,
    }
end

function Game:IsValid ()
    local cards = self:getCards()
    for _, meld in pairs(cards.melds) do
        if not Meld:isValid(meld) then
            return false
        end
    end
    return true
end

function Game:addCardToHand (card)
    local cards = self:getCards()
    local hand = cards.hand
    table.insert(hand, card)
    card:setOrigin('hand')
    Meld:sort(hand)
    self:applyMeldOrder(hand)
end

function Game:getSelection ()
    local sel = {}
    for card in self:iterCards() do
        if card.selected then
            sel[card] = true
        end
    end
    return sel
end

function Game:clone ()
    return utils:deepCopy(self)
end

function Game:getSelectionOrigin (sel)
    local origin = Selection:getOrigin(sel)
    local cards = self:getCards()

    local function extra ()
        if origin == 'meld' then
            local melds = {}
            for card in pairs(sel) do
                local meldid = card.meldid
                local meld = cards.melds[meldid]
                melds[meldid] = meld
            end
            return melds
        elseif origin == 'hand' then
            return cards.hand
        elseif origin == 'stock' then
            return cards.stock
        end
    end

    return origin, extra()
end

function Game:getNewMeldId ()
    local id
    for card in self:iterCards() do
        if card.origin == 'meld' and card.meldid ~= nil then
            if id == nil or card.meldid > id then
                id = card.meldid
            end
        end
    end
    return id and (id + 1) or 1
end

function Game:setMeldId (meld, meldid)
    for _, card in ipairs(meld) do
        card:setMeldId(meldid)
    end
end

function Game:setOrigin (meld, origin)
    for _, card in ipairs(meld) do
        card:setOrigin(origin)
    end
end

return Game
