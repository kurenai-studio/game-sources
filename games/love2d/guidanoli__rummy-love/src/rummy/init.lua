local inspect = require "inspect"
local constants = require "rummy.constants"
local utils = require "rummy.utils"
local Game = require "rummy.game"
local Meld = require "rummy.meld"
local Selection = require "rummy.selection"

local rummy = {}

rummy.debug = os.getenv "DEBUG" ~= nil

function rummy:save ()
    local clone = self.game:clone()
    table.insert(self.history, clone)
end

function rummy:undo ()
    if #self.history > 0 then
        self.game = table.remove(self.history)
        self.updatePending = true
    else
        print("No previous state to restore")
    end
end

function rummy:clearHistory ()
    self.history = {}
end

function rummy:isPositionInsideCard (x, y, w, h, card)
    return (x >= card.x) and
           (x <= (card.x + w)) and
           (y >= card.y) and
           (y <= (card.y + h))
end

local function compareCardsByPosition (card1, card2)
    return card1.pos < card2.pos
end

function rummy:updateCardRenderingOrder ()
    local order = {}
    for card in self.game:iterCards() do
        table.insert(order, card)
    end
    table.sort(order, compareCardsByPosition)
    self.cardRenderingOrder = order
end

function rummy:getCardAtPosition (x, y)
    for i = #self.cardRenderingOrder, 1, -1 do
        local card = self.cardRenderingOrder[i]
        local w, h = self:getCardImage(card):getDimensions()
        if self:isPositionInsideCard(x, y, w, h, card) then
            return card
        end
    end
end

function rummy:moveMeldSmoothly (meld)
    for _, card in ipairs(meld) do
        self:moveCardSmoothly(card)
    end
end

function rummy:moveSelectionSmoothly (selection)
    for card in pairs(selection) do
        self:moveCardSmoothly(card)
    end
end

function rummy:moveCardSmoothly (card)
    card:setAnimation{
        name = 'smooth',
        time = 0,
        duration = 1,
        xi = card.x,
        yi = card.y,
    }
end

function rummy:onCardLeftClick (card)
    if card.origin == 'stock' then
        if self.game:IsValid() then
            local cards = self.game:getCards()
            local newHand = Meld:plus(cards.hand, {card})
            self.game:applyMeldOrder(newHand)
            self.game:setOrigin(newHand, 'hand')
            self:moveMeldSmoothly(newHand)
            self:clearHistory()
            self.updatePending = true
        end
    else
        if not card.animation then
            card.selected = not card.selected
            self.updatePending = true
        end
    end
end

function rummy:unselect (selection)
    if selection == nil then
        selection = self.game:getSelection()
    end
    for card in pairs(selection) do
        card:setSelected(false)
    end
end

function rummy:moveSelectionFromMeldToMeld (t)
    local selectionMeld = Meld:fromSelection(t.selection)
    for meldid, originMeld in pairs(t.selectionOriginExtra) do
        local selectionSubset = self:filterSelectionByMeldId(t.selection, meldid)
        local newOriginMeld = Meld:minus(originMeld, Meld:fromSelection(selectionSubset))
        self.game:applyMeldOrder(newOriginMeld)
    end
    local cards = self.game:getCards()
    self:moveMeldSmoothly(selectionMeld)
    for _, meld in pairs(cards.melds) do
        self:moveMeldSmoothly(meld)
    end
    local clickedMeld = cards.melds[t.card.meldid]
    local newClickedMeld = Meld:plus(clickedMeld, selectionMeld)
    self.game:applyMeldOrder(newClickedMeld)
    self.game:setMeldId(selectionMeld, t.card.meldid)
    self:unselect(t.selection)
    self.updatePending = true
end

function rummy:moveSelectionFromHandToMeld (t)
    local selectionMeld = Meld:fromSelection(t.selection)
    if #selectionMeld == 1 or #selectionMeld == 3 then
        self:moveMeldSmoothly(t.selectionOriginExtra)
        local newHand = Meld:minus(t.selectionOriginExtra, selectionMeld)
        self.game:applyMeldOrder(newHand)
        local cards = self.game:getCards()
        for _, meld in pairs(cards.melds) do
            self:moveMeldSmoothly(meld)
        end
        local clickedMeld = cards.melds[t.card.meldid]
        local newClickedMeld = Meld:plus(clickedMeld, selectionMeld)
        self.game:applyMeldOrder(newClickedMeld)
        self.game:setOrigin(selectionMeld, 'meld')
        self.game:setMeldId(selectionMeld, t.card.meldid)
        assert(self:isGameValid())
        self:unselect(t.selection)
        self.updatePending = true
    end
end

function rummy:onCardRightClick (t)
    if t.card.origin == 'meld' then
        if t.selectionOrigin == 'meld' then
            self:moveSelectionFromMeldToMeld(t)
        elseif t.selectionOrigin == 'hand' then
            self:moveSelectionFromHandToMeld(t)
        end
    end
end

function rummy:filterSelectionByMeldId (selection, meldid)
    local function predicate (card)
        return card.meldid == meldid
    end
    return Selection:filter(selection, predicate)
end

function rummy:moveSelectionFromMeldToTable (t)
    local selectionMeld = Meld:fromSelection(t.selection)
    for meldid, originMeld in pairs(t.selectionOriginExtra) do
        local selectionSubset = self:filterSelectionByMeldId(t.selection, meldid)
        local newOriginMeld = Meld:minus(originMeld, Meld:fromSelection(selectionSubset))
        self.game:applyMeldOrder(newOriginMeld)
    end
    local cards = self.game:getCards()
    self:moveMeldSmoothly(selectionMeld)
    for _, meld in pairs(cards.melds) do
        self:moveMeldSmoothly(meld)
    end
    self.game:applyMeldOrder(selectionMeld)
    local newMeldId = self.game:getNewMeldId()
    self.game:setMeldId(selectionMeld, newMeldId)
    self:unselect(t.selection)
    self.updatePending = true
end

function rummy:isGameValid()
    return self.game:IsValid(),
           "move cannot be applied because it would " ..
           "leave the game in an inconsistent state"
end

function rummy:moveSelectionFromHandToTable (t)
    local selectionMeld = Meld:fromSelection(t.selection)
    self:moveMeldSmoothly(t.selectionOriginExtra)
    local newHand = Meld:minus(t.selectionOriginExtra, selectionMeld)
    self.game:applyMeldOrder(newHand)
    self.game:applyMeldOrder(selectionMeld)
    self.game:setOrigin(selectionMeld, 'meld')
    local newMeldId = self.game:getNewMeldId()
    self.game:setMeldId(selectionMeld, newMeldId)
    assert(self:isGameValid())
    self:unselect(t.selection)
    self:clearHistory()
    self.updatePending = true
end

function rummy:onTableRightClick (t)
    if t.selectionOrigin == 'meld' then
        self:moveSelectionFromMeldToTable(t)
    elseif t.selectionOrigin == 'hand' then
        self:moveSelectionFromHandToTable(t)
    end
end

function rummy:onRightClick (t)
    if t.card == nil then
        self:onTableRightClick(t)
    else
        self:onCardRightClick(t)
    end
end

function rummy:getCardImageDimensions ()
    local anySuit = next(constants.suits)
    local anyRank = next(constants.ranks)
    local anyCardImage = self.images.card[anySuit][anyRank]
    return anyCardImage:getDimensions()
end

function rummy:updateCardPositions ()
    local W, H = love.graphics.getDimensions()
    local w, h = self:getCardImageDimensions()
    local margin = 10
    local stockX = margin
    local stockY = margin
    local selectionLift = h / 4
    local xCardDist = w / 4
    local xMeldDist = margin
    local yMeldDist = margin + selectionLift

    local function update (card, x, y)
        if card.selected then
            y = y - selectionLift
        end
        if card.animation then
            if card.animation.name == 'smooth' then
                card.animation.xf = x
                card.animation.yf = y
            end
        else
            card:setX(x)
            card:setY(y)
        end
    end

    local cards = self.game:getCards()

    for _, card in ipairs(cards.stock) do
        update(card, stockX, stockY)
    end

    do
        local x = stockX
        local y = stockY + self.images.stock:getHeight() + margin + selectionLift
        for _, meldkey in ipairs(utils:sortedKeys(cards.melds)) do
            local meld = cards.melds[meldkey]
            for i = 1, 2 do
                for _, card in ipairs(meld) do
                    update(card, x, y)
                    x = x + xCardDist
                end
                if x + (w - xCardDist) + margin > W then
                    x = stockX
                    y = y + h + yMeldDist
                else
                    break
                end
            end
            x = x + (w - xCardDist) + xMeldDist
        end
    end

    do
        local x = stockX
        local y = H - margin - h
        for _, card in ipairs(cards.hand) do
            update(card, x, y)
            x = x + xCardDist
        end
    end
end

function rummy:updateCardAnimations (dt)
    for card in self.game:iterCards() do
        if card.animation then
            if card.animation.time + dt >= card.animation.duration then
                card.animation.time = card.animation.duration
                self:updateCardAnimation(card)
                card:setAnimation(nil)
            else
                card.animation.time = card.animation.time + dt
                self:updateCardAnimation(card)
            end
        end
    end
end

function rummy:updateCardAnimation (card)
    if card.animation.name == 'smooth' then
        local xi = card.animation.xi
        local yi = card.animation.yi
        local xf = card.animation.xf
        local yf = card.animation.yf
        if xi and yi and xf and yf then
            if xi == xf and yi == yf then
                card:setAnimation(nil)
            else
                local t = card.animation.time / card.animation.duration
                local p = (math.sin((t - 0.5) * math.pi) + 1) / 2
                card:setX(xi * (1 - p) + xf * p)
                card:setY(yi * (1 - p) + yf * p)
            end
        end
    end
end

function rummy:getCardImage (card)
    if card.origin == 'stock' then
        return self.images.stock
    else
        return self.images.card[card.suit][card.rank]
    end
end

function rummy:load ()
    love.window.setMode(1280, 720)
    love.window.setTitle("Rummy")

    math.randomseed(os.time())
    self.game = Game:new()

    self.history = {}

    self.images = {}
    self.images.stock = love.graphics.newImage('images/vstock/red.png')
    self.images.card = {}
    for suit in pairs(constants.suits) do
        self.images.card[suit] = {}
        local folder = 'images/' .. suit
        for rank in pairs(constants.ranks) do
            local filename = folder .. '/' .. rank .. '.png'
            self.images.card[suit][rank] = love.graphics.newImage(filename)
        end
    end

    self.updatePending = true
end
 
function rummy:draw ()
    local drawnStock = false
    for _, card in ipairs(self.cardRenderingOrder) do
        if not (card.origin == 'stock' and drawnStock) then
            local img = self:getCardImage(card)
            love.graphics.draw(img, card.x, card.y)
            if card.origin == 'stock' then
                drawnStock = true
            end
        end
    end
end

function rummy:unsafemousepressed (x, y, button)
    if button == 1 then
        local card = self:getCardAtPosition(x, y)
        if card ~= nil then
            self:onCardLeftClick(card)
        end
    elseif button == 2 then
        local card = self:getCardAtPosition(x, y)
        local selection = self.game:getSelection()
        local selectionOrigin, selectionOriginExtra = self.game:getSelectionOrigin(selection)
        if selectionOrigin ~= nil then
            self:onRightClick{
                card = card,
                selection = selection,
                selectionOrigin = selectionOrigin,
                selectionOriginExtra = selectionOriginExtra,
            }
        end
    end
end

function rummy:mousepressed (...)
    self:save()
    local ok, err = pcall(self.unsafemousepressed, self, ...)
    if not ok then
        print(err)
        self:undo()
        self.updatePending = true
    end
end
 
function rummy:keypressed (key)
    if key == 'c' then
        self:unselect()
        self.updatePending = true
    elseif key == 'u' then
        self:undo()
    elseif key == 'i' then
        if self.debug then
            print(inspect(self.game))
        end
    end
end

function rummy:update (dt)
    if self.updatePending then
        self:updateCardPositions()
        self:updateCardRenderingOrder()
        self.updatePending = false
    end

    self:updateCardAnimations(dt)
end

return rummy
