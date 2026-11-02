--[[
Deck Builder Scene - Card Collection and Deck Construction

Demonstrates advanced UI layout, card filtering, drag-and-drop deck building,
and collection management. Shows how to extend the framework for complex
interaction patterns.

Features:
- Scrollable card collection with search/filter
- Drag-and-drop deck construction
- Real-time deck validation and statistics
- Save/load deck configurations
- Card preview with detailed information
--]]

local Layout = require('lib.layout')
local CardRenderer = require('lib.card_renderer')
local AnimationManager = require('lib.animation')
local Utils = require('lib.utils')
local Cards = require('data.cards')

local DeckBuilder = {}
DeckBuilder.__index = DeckBuilder

function DeckBuilder:new()
    local instance = {
        -- Scene state
        is_active = false,
        animation_manager = nil,
        card_renderer = nil,
        
        -- UI Layout (using direct positioning)
        controls_area = nil,
        collection_area = nil,
        deck_area = nil,
        preview_area = nil,
        back_button = nil,
        
        -- Card data
        all_cards = {},
        filtered_cards = {},
        current_deck = {},
        
        -- UI state
        selected_card = nil,
        hovered_card = nil,
        search_text = "",
        filter_type = "all", -- all, creature, spell, artifact
        filter_rarity = "all", -- all, common, uncommon, rare, epic, legendary
        
        -- Deck constraints
        max_deck_size = 30,
        min_deck_size = 20,
        max_copies_per_card = 3,
        
        -- Scroll state
        collection_scroll = 0,
        max_scroll = 0,
        
        -- Layout configuration
        card_scale = 1.2,  -- Larger cards
        cards_per_row = 5,
        collection_padding = 20
    }
    
    setmetatable(instance, DeckBuilder)
    return instance
end

function DeckBuilder:enter()
    self.is_active = true
    
    -- Initialize systems
    self.animation_manager = AnimationManager.AnimationManager:new()
    self.card_renderer = CardRenderer:new({
        card_width = 90 * self.card_scale,
        card_height = 126 * self.card_scale
    })
    
    -- Create UI first
    self:createUI()
    
    -- Load card collection
    self:loadCollection()
    
    -- Set up input handlers
    if Game and Game.input then
        Game.input:addEventListener("mouse_pressed", function(event) self:onMousePressed(event) end)
        Game.input:addEventListener("mouse_moved", function(event) self:onMouseMoved(event) end)
        Game.input:addEventListener("drag_start", function(event) self:onDragStart(event) end)
        Game.input:addEventListener("drag_end", function(event) self:onDragEnd(event) end)
    end
    
    print("Entered deck builder")
end

function DeckBuilder:exit()
    self.is_active = false
    
    if self.animation_manager then
        self.animation_manager:stopAll()
    end
    
    print("Exited deck builder")
end

function DeckBuilder:loadCollection()
    self.all_cards = Cards.getCollectibleCards()
    
    -- Add collection metadata to each card
    for _, card in ipairs(self.all_cards) do
        card.owned_count = self:getOwnedCount(card.id)
        card.deck_count = self:getDeckCount(card.id)
    end
    
    self:applyFilters()
end

function DeckBuilder:getOwnedCount(card_id)
    -- In a real game, this would query save data
    -- For demo, assume player owns 3 of each common, 2 of uncommon, 1 of rare+
    local card = Cards.getCardById(card_id)
    if not card then return 0 end
    
    if card.rarity == "common" then return 3
    elseif card.rarity == "uncommon" then return 2
    else return 1 end
end

function DeckBuilder:getDeckCount(card_id)
    local count = 0
    for _, deck_card in ipairs(self.current_deck) do
        if deck_card.id == card_id then
            count = count + 1
        end
    end
    return count
end

function DeckBuilder:createUI()
    local screen_width, screen_height = love.graphics.getDimensions()
    
    -- Use direct positioning for better control
    self.controls_area = {
        x = 20,
        y = 20,
        width = screen_width - 40,
        height = 80
    }
    
    self.collection_area = {
        x = 20,
        y = 120,
        width = screen_width * 0.65,
        height = screen_height - 240
    }
    
    self.deck_area = {
        x = screen_width * 0.65 + 40,
        y = 120,
        width = screen_width * 0.32,
        height = screen_height - 240
    }
    
    self.preview_area = {
        x = 20,
        y = screen_height - 100,
        width = screen_width - 40,
        height = 80
    }
    
    -- Back button
    self.back_button = {
        x = screen_width - 120,
        y = 30,
        width = 80,
        height = 40,
        text = "Back"
    }
    
    self:calculateCollectionLayout()
end

function DeckBuilder:calculateCollectionLayout()
    local card_w, card_h = self.card_renderer:getCardDimensions()
    local collection_w = self.collection_area.width
    local collection_h = self.collection_area.height
    
    -- Calculate grid layout with proper spacing
    local available_width = collection_w - (self.collection_padding * 2)
    local card_spacing = 15
    local total_card_width = card_w + card_spacing
    
    self.cards_per_row = math.max(1, math.floor(available_width / total_card_width))
    local rows_needed = math.ceil(#self.filtered_cards / self.cards_per_row)
    local total_height = rows_needed * (card_h + card_spacing)
    
    self.max_scroll = math.max(0, total_height - collection_h + (self.collection_padding * 2))
end

function DeckBuilder:applyFilters()
    self.filtered_cards = {}
    
    for _, card in ipairs(self.all_cards) do
        local matches = true
        
        -- Type filter
        if self.filter_type ~= "all" and card.type ~= self.filter_type then
            matches = false
        end
        
        -- Rarity filter
        if self.filter_rarity ~= "all" and card.rarity ~= self.filter_rarity then
            matches = false
        end
        
        -- Search text filter
        if self.search_text ~= "" then
            local search_lower = self.search_text:lower()
            local name_match = card.name:lower():find(search_lower)
            local desc_match = card.description and card.description:lower():find(search_lower)
            
            if not name_match and not desc_match then
                matches = false
            end
        end
        
        if matches then
            table.insert(self.filtered_cards, card)
        end
    end
    
    self:calculateCollectionLayout()
end

function DeckBuilder:getCardAtPosition(x, y)
    -- Check collection cards
    local collection_x, collection_y, collection_w, collection_h = self.collection_area.x, self.collection_area.y, self.collection_area.width, self.collection_area.height
    
    if x >= collection_x and x < collection_x + collection_w and
       y >= collection_y and y < collection_y + collection_h then
        
        local relative_x = x - collection_x - self.collection_padding
        local relative_y = y - collection_y - self.collection_padding + self.collection_scroll
        
        local card_w, card_h = self.card_renderer:getCardDimensions()
        local card_spacing = 15
        
        local col = math.floor(relative_x / (card_w + card_spacing))
        local row = math.floor(relative_y / (card_h + card_spacing))
        
        local card_index = row * self.cards_per_row + col + 1
        
        if card_index >= 1 and card_index <= #self.filtered_cards then
            return self.filtered_cards[card_index], "collection"
        end
    end
    
    -- Check deck cards
    local deck_x, deck_y, deck_w, deck_h = self.deck_area.x, self.deck_area.y, self.deck_area.width, self.deck_area.height
    
    if x >= deck_x and x < deck_x + deck_w and
       y >= deck_y and y < deck_y + deck_h then
        
        local card_w, card_h = self.card_renderer:getCardDimensions()
        local cards_per_row = math.floor((deck_w - 20) / (card_w + 5))
        
        local relative_x = x - deck_x - 10
        local relative_y = y - deck_y - 10
        
        local col = math.floor(relative_x / (card_w + 5))
        local row = math.floor(relative_y / (card_h + 5))
        local card_index = row * cards_per_row + col + 1
        
        if card_index >= 1 and card_index <= #self.current_deck then
            return self.current_deck[card_index], "deck"
        end
    end
    
    -- Check back button
    if x >= self.back_button.x and x < self.back_button.x + self.back_button.width and
       y >= self.back_button.y and y < self.back_button.y + self.back_button.height then
        return nil, "back_button"
    end
    
    return nil, nil
end

function DeckBuilder:onMousePressed(event)
    if not self.is_active then return end
    
    local card, area = self:getCardAtPosition(event.x, event.y)
    
    if area == "back_button" then
        self:goBack()
        return
    end
    
    if card then
        self.selected_card = card
        
        -- Different behavior based on area
        if area == "collection" and self:canAddToDeck(card) then
            -- Start drag from collection to deck
            if Game.input then
                Game.input:startDrag(card, {
                    source_area = "collection"
                })
            end
        elseif area == "deck" then
            -- Start drag to remove from deck
            if Game.input then
                Game.input:startDrag(card, {
                    source_area = "deck"
                })
            end
        end
        
        -- Play sound effect
        if Game.audio then
            Game.audio:playSound("card_hover")
        end
    else
        -- Check for UI interactions (search, filters, etc.)
        self:handleUIClick(event.x, event.y)
    end
end

function DeckBuilder:onMouseMoved(event)
    if not self.is_active then return end
    
    local new_hovered_card, area = self:getCardAtPosition(event.x, event.y)
    
    if new_hovered_card ~= self.hovered_card then
        self.hovered_card = new_hovered_card
        
        if new_hovered_card and Game.audio then
            Game.audio:playSound("card_hover")
        end
    end
    
    -- Handle collection scrolling
    if event.x >= self.collection_area.x and 
       event.x < self.collection_area.x + self.collection_area.width then
        -- Mouse wheel scrolling would be handled in love.wheelmoved
    end
end

function DeckBuilder:onDragStart(event)
    if not self.is_active then return end
    -- Drag start handled in onMousePressed
end

function DeckBuilder:onDragEnd(event)
    if not self.is_active or not event.object then return end
    
    local card = event.object
    local source_area = event.object.source_area or "unknown"
    
    -- Determine drop target
    local deck_x, deck_y, deck_w, deck_h = self.deck_area.x, self.deck_area.y, self.deck_area.width, self.deck_area.height
    local collection_x, collection_y, collection_w, collection_h = self.collection_area.x, self.collection_area.y, self.collection_area.width, self.collection_area.height
    
    if source_area == "collection" then
        -- Dragged from collection - check if dropped on deck
        if event.x >= deck_x and event.x < deck_x + deck_w and
           event.y >= deck_y and event.y < deck_y + deck_h then
            self:addCardToDeck(card)
        end
    elseif source_area == "deck" then
        -- Dragged from deck - check if dropped outside deck area
        if not (event.x >= deck_x and event.x < deck_x + deck_w and
                event.y >= deck_y and event.y < deck_y + deck_h) then
            self:removeCardFromDeck(card)
        end
    end
    
    self.selected_card = nil
end

function DeckBuilder:canAddToDeck(card)
    if #self.current_deck >= self.max_deck_size then
        return false
    end
    
    local count_in_deck = self:getDeckCount(card.id)
    if count_in_deck >= self.max_copies_per_card then
        return false
    end
    
    if count_in_deck >= card.owned_count then
        return false
    end
    
    return true
end

function DeckBuilder:addCardToDeck(card)
    if not self:canAddToDeck(card) then
        if Game.audio then
            Game.audio:playSound("button_click") -- Use available sound
        end
        return false
    end
    
    local deck_card = Cards.copyCard(card)
    table.insert(self.current_deck, deck_card)
    
    -- Update card counts
    card.deck_count = self:getDeckCount(card.id)
    
    -- Play success sound
    if Game.audio then
        Game.audio:playSound("card_hover") -- Use available sound
    end
    
    print("Added " .. card.name .. " to deck")
    return true
end

function DeckBuilder:removeCardFromDeck(card)
    for i, deck_card in ipairs(self.current_deck) do
        if deck_card.id == card.id then
            table.remove(self.current_deck, i)
            
            -- Update card counts
            for _, collection_card in ipairs(self.all_cards) do
                if collection_card.id == card.id then
                    collection_card.deck_count = self:getDeckCount(card.id)
                    break
                end
            end
            
            -- Play sound
            if Game.audio then
                Game.audio:playSound("card_hover") -- Use available sound
            end
            
            print("Removed " .. card.name .. " from deck")
            return true
        end
    end
    return false
end

function DeckBuilder:handleUIClick(x, y)
    -- Check control area for filter buttons, search, etc.
    local controls_x, controls_y, controls_w, controls_h = self.controls_area.x, self.controls_area.y, self.controls_area.width, self.controls_area.height
    
    if x >= controls_x and x < controls_x + controls_w and
       y >= controls_y and y < controls_y + controls_h then
        
        -- Simple filter button simulation (in real UI, these would be proper buttons)
        local button_width = 80
        local button_spacing = 10
        
        -- Type filter buttons
        local type_filters = {"all", "creature", "spell", "artifact"}
        for i, filter_type in ipairs(type_filters) do
            local button_x = controls_x + 20 + (i - 1) * (button_width + button_spacing)
            
            if x >= button_x and x < button_x + button_width then
                self.filter_type = filter_type
                self:applyFilters()
                
                if Game.audio then
                    Game.audio:playSound("button_click")
                end
                break
            end
        end
        
        -- Back button (top right)
        if x >= controls_x + controls_w - 100 and x < controls_x + controls_w - 20 then
            self:goBack()
        end
    end
end

function DeckBuilder:goBack()
    if Game and Game.scene_manager then
        Game.scene_manager:switchScene("menu_scene", {
            type = "slide",
            duration = 0.4
        })
    end
end

function DeckBuilder:getDeckStats()
    local stats = {
        total_cards = #self.current_deck,
        total_cost = 0,
        average_cost = 0,
        type_counts = {},
        rarity_counts = {}
    }
    
    for _, card in ipairs(self.current_deck) do
        stats.total_cost = stats.total_cost + card.cost
        
        stats.type_counts[card.type] = (stats.type_counts[card.type] or 0) + 1
        stats.rarity_counts[card.rarity] = (stats.rarity_counts[card.rarity] or 0) + 1
    end
    
    if stats.total_cards > 0 then
        stats.average_cost = stats.total_cost / stats.total_cards
    end
    
    return stats
end

function DeckBuilder:update(dt)
    if not self.is_active then return end
    
    -- Update animation system
    if self.animation_manager then
        self.animation_manager:update(dt)
    end
    
    -- Update card renderer
    if self.card_renderer then
        self.card_renderer:update(dt)
    end
    
    -- No UI containers to update (using direct positioning)
    
    -- Handle input
    if Game and Game.input then
        if Game.input:isActionJustPressed("back") then
            self:goBack()
        end
        
        -- Scroll collection with mouse wheel (would be in love.wheelmoved)
        if love.keyboard.isDown("up") then
            self.collection_scroll = math.max(0, self.collection_scroll - 100 * dt)
        elseif love.keyboard.isDown("down") then
            self.collection_scroll = math.min(self.max_scroll, self.collection_scroll + 100 * dt)
        end
    end
end

function DeckBuilder:draw()
    if not self.is_active then return end
    
    -- Draw backgrounds
    self:drawBackgrounds()
    
    -- Draw collection cards
    self:drawCollection()
    
    -- Draw deck cards
    self:drawDeck()
    
    -- Draw UI text and controls
    self:drawUI()
    
    -- Draw back button
    self:drawBackButton()
    
    -- Draw card preview
    if self.hovered_card then
        self:drawCardPreview()
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function DeckBuilder:drawBackgrounds()
    -- Draw controls background
    love.graphics.setColor(0.25, 0.25, 0.35, 0.9)
    love.graphics.rectangle("fill", self.controls_area.x, self.controls_area.y, self.controls_area.width, self.controls_area.height)
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    love.graphics.rectangle("line", self.controls_area.x, self.controls_area.y, self.controls_area.width, self.controls_area.height)
    
    -- Draw collection background
    love.graphics.setColor(0.15, 0.2, 0.15, 0.8)
    love.graphics.rectangle("fill", self.collection_area.x, self.collection_area.y, self.collection_area.width, self.collection_area.height)
    love.graphics.setColor(0.3, 0.4, 0.3, 1)
    love.graphics.rectangle("line", self.collection_area.x, self.collection_area.y, self.collection_area.width, self.collection_area.height)
    
    -- Draw deck background
    love.graphics.setColor(0.2, 0.15, 0.2, 0.8)
    love.graphics.rectangle("fill", self.deck_area.x, self.deck_area.y, self.deck_area.width, self.deck_area.height)
    love.graphics.setColor(0.4, 0.3, 0.4, 1)
    love.graphics.rectangle("line", self.deck_area.x, self.deck_area.y, self.deck_area.width, self.deck_area.height)
    
    -- Draw preview background
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.rectangle("fill", self.preview_area.x, self.preview_area.y, self.preview_area.width, self.preview_area.height)
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    love.graphics.rectangle("line", self.preview_area.x, self.preview_area.y, self.preview_area.width, self.preview_area.height)
end

function DeckBuilder:drawCollection()
    local collection_x, collection_y, collection_w, collection_h = self.collection_area.x, self.collection_area.y, self.collection_area.width, self.collection_area.height
    local card_w, card_h = self.card_renderer:getCardDimensions()
    local card_spacing = 15
    
    -- Set scissor for collection area
    love.graphics.setScissor(collection_x, collection_y, collection_w, collection_h)
    
    for i, card in ipairs(self.filtered_cards) do
        local row = math.floor((i - 1) / self.cards_per_row)
        local col = (i - 1) % self.cards_per_row
        
        local card_x = collection_x + self.collection_padding + col * (card_w + card_spacing)
        local card_y = collection_y + self.collection_padding + row * (card_h + card_spacing) - self.collection_scroll
        
        -- Skip cards that are off-screen
        if card_y + card_h >= collection_y and card_y <= collection_y + collection_h then
            -- Determine card state
            local state = CardRenderer.STATES.IDLE
            
            if card == self.hovered_card then
                state = CardRenderer.STATES.HOVER
            elseif card.deck_count >= card.owned_count then
                state = CardRenderer.STATES.DISABLED
            elseif card.deck_count > 0 then
                state = CardRenderer.STATES.SELECTED
            end
            
            -- Draw card
            self.card_renderer:drawCard(card, card_x, card_y, {
                state = state,
                scale = self.card_scale,
                alpha = (card.deck_count >= card.owned_count) and 0.5 or 1.0
            })
            
            -- Draw count indicators
            if card.deck_count > 0 then
                self:drawCardCount(card_x, card_y, card.deck_count, card.owned_count)
            end
        end
    end
    
    -- Reset scissor
    love.graphics.setScissor()
end

function DeckBuilder:drawDeck()
    local deck_x, deck_y, deck_w, deck_h = self.deck_area.x, self.deck_area.y, self.deck_area.width, self.deck_area.height
    local card_w, card_h = self.card_renderer:getCardDimensions()
    local cards_per_row = math.floor((deck_w - 20) / (card_w + 5))
    
    for i, card in ipairs(self.current_deck) do
        local row = math.floor((i - 1) / cards_per_row)
        local col = (i - 1) % cards_per_row
        
        local card_x = deck_x + 10 + col * (card_w + 5)
        local card_y = deck_y + 10 + row * (card_h + 5)
        
        local state = CardRenderer.STATES.IDLE
        if card == self.hovered_card then
            state = CardRenderer.STATES.HOVER
        end
        
        self.card_renderer:drawCard(card, card_x, card_y, {
            state = state,
            scale = self.card_scale
        })
    end
end

function DeckBuilder:drawCardCount(x, y, deck_count, owned_count)
    -- Draw count badge
    local badge_size = 20
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.circle("fill", x + badge_size/2, y + badge_size/2, badge_size/2)
    
    love.graphics.setColor(0.8, 0.8, 0.9, 1)
    love.graphics.circle("line", x + badge_size/2, y + badge_size/2, badge_size/2)
    
    -- Draw count text
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 1)
    
    local count_text = deck_count .. "/" .. owned_count
    local text_w = font:getWidth(count_text)
    love.graphics.print(count_text, x + badge_size/2 - text_w/2, y + badge_size/2 - font:getHeight()/2)
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function DeckBuilder:drawBackButton()
    local btn = self.back_button
    
    -- Button background
    love.graphics.setColor(0.3, 0.5, 0.3, 0.9)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
    
    -- Button border
    love.graphics.setColor(0.5, 0.7, 0.5, 1)
    love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height)
    
    -- Button text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    local text_width = love.graphics.getFont():getWidth(btn.text)
    local text_height = love.graphics.getFont():getHeight()
    love.graphics.print(btn.text, 
        btn.x + (btn.width - text_width) / 2,
        btn.y + (btn.height - text_height) / 2)
end

function DeckBuilder:drawUI()
    -- Draw controls
    local controls_x, controls_y, controls_w, controls_h = self.controls_area.x, self.controls_area.y, self.controls_area.width, self.controls_area.height
    local font = love.graphics.newFont(16)
    love.graphics.setFont(font)
    
    -- Filter buttons
    love.graphics.setColor(0.9, 0.9, 1, 1)
    love.graphics.print("Type: ", controls_x + 20, controls_y + 20)
    
    local type_filters = {"All", "Creature", "Spell", "Artifact"}
    for i, filter_name in ipairs(type_filters) do
        local button_x = controls_x + 70 + (i - 1) * 90
        local is_active = self.filter_type == filter_name:lower()
        
        if is_active then
            love.graphics.setColor(1, 1, 0.8, 1)
        else
            love.graphics.setColor(0.7, 0.7, 0.8, 1)
        end
        
        love.graphics.print(filter_name, button_x, controls_y + 20)
    end
    
    -- Back button
    love.graphics.setColor(0.8, 0.9, 1, 1)
    love.graphics.print("Back", controls_x + controls_w - 80, controls_y + 20)
    
    -- Deck stats
    local deck_stats = self:getDeckStats()
    local stats_text = string.format("Deck: %d/%d cards | Avg Cost: %.1f", 
                                    deck_stats.total_cards, self.max_deck_size, deck_stats.average_cost)
    
    local deck_x, deck_y = self.deck_area.x, self.deck_area.y
    love.graphics.setColor(0.9, 0.9, 1, 1)
    love.graphics.print(stats_text, deck_x, deck_y - 25)
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function DeckBuilder:drawCardPreview()
    if not self.hovered_card then return end
    
    local preview_x, preview_y, preview_w, preview_h = self.preview_area.x, self.preview_area.y, self.preview_area.width, self.preview_area.height
    
    -- Draw card name and description
    local font = love.graphics.newFont(16)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 0.8, 1)
    
    local name_text = self.hovered_card.name .. " (" .. self.hovered_card.cost .. " mana)"
    love.graphics.print(name_text, preview_x + 20, preview_y + 10)
    
    -- Description
    local desc_font = love.graphics.newFont(12)
    love.graphics.setFont(desc_font)
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.printf(self.hovered_card.description or "", preview_x + 20, preview_y + 35, preview_w - 40, "left")
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function DeckBuilder:onResize(width, height)
    -- Recreate layout with new dimensions
    self:createUI()
    self:calculateCollectionLayout()
end

return DeckBuilder
