--[[
Game Scene - Main Gameplay Scene

The core gameplay scene that handles card rendering, player interaction,
game state management, and visual effects. Demonstrates the integration
of all major systems working together.

Features:
- Card hand management with hover effects
- Drag and drop card playing
- Animated card movements and state changes
- UI layout with responsive containers
- Game state tracking and turn management
--]]

local Layout = require('lib.layout')
local CardRenderer = require('lib.card_renderer')
local AnimationManager = require('lib.animation')
local Utils = require('lib.utils')
local Cards = require('data.cards')

local GameScene = {}
GameScene.__index = GameScene

function GameScene:new()
    local instance = {
        -- Scene state
        is_initialized = false,
        is_active = false,
        
        -- UI Layout
        ui_container = nil,        -- Root UI container
        hand_container = nil,      -- Player's hand area
        play_area_container = nil, -- Main playing field
        ui_panel_container = nil,  -- UI controls and info
        
        -- Card system
        card_renderer = nil,
        player_hand = {},          -- Cards in player's hand
        cards_in_play = {},        -- Cards on the playing field
        
        -- Game state
        player_mana = 5,
        max_mana = 10,
        turn_number = 1,
        game_phase = "planning",   -- "planning", "action", "resolution"
        
        -- Animation state
        animation_manager = nil,
        card_animations = {},
        
        -- Input handling
        selected_card = nil,
        hovered_card = nil,
        dragged_card = nil,
        drag_start_pos = {x = 0, y = 0},
        
        -- Visual effects
        particles = {},
        
        -- Configuration
        hand_size = 7,
        card_spacing = 100,
        hand_y_position = 550,
        
        -- Debug
        debug_mode = false,
        
        -- Mana change indicator
        mana_change_text = "",
        mana_change_timer = 0,
        mana_change_duration = 2.0,
        
        -- Extra turn system
        extra_turn_pending = false,
        ai_extra_turn_pending = false
    }
    
    setmetatable(instance, GameScene)
    return instance
end

function GameScene:enter()
    if not self.is_initialized then
        self:initialize()
    end
    
    self.is_active = true
    
    -- Set up input handlers
    if Game and Game.input then
        Game.input:addEventListener("mouse_pressed", function(event) self:onMousePressed(event) end)
        Game.input:addEventListener("mouse_released", function(event) self:onMouseReleased(event) end)
        Game.input:addEventListener("mouse_moved", function(event) self:onMouseMoved(event) end)
        Game.input:addEventListener("drag_start", function(event) self:onDragStart(event) end)
        Game.input:addEventListener("drag_update", function(event) self:onDragUpdate(event) end)
        Game.input:addEventListener("drag_end", function(event) self:onDragEnd(event) end)
    end
    
    -- Start background music
    if Game and Game.audio then
        Game.audio:playMusic("game_ambient", {loop = true, volume = 0.4})
    end
    
    print("Entered game scene")
end

function GameScene:exit()
    self.is_active = false
    
    -- Clean up animations
    if self.animation_manager then
        self.animation_manager:stopAll()
    end
    
    print("Exited game scene")
end

function GameScene:initialize()
    -- Create UI layout
    self:createUI()
    
    -- Initialize card renderer
    self.card_renderer = CardRenderer:new({
        card_width = 80,
        card_height = 112
    })
    
    -- Initialize animation system
    self.animation_manager = AnimationManager.AnimationManager:new()
    
    -- Create initial hand
    self:createInitialHand()
    
    -- Set up game state
    -- Player stats
    self.player_mana = 1
    self.max_mana = 1
    self.player_health = 20
    self.max_health = 20
    
    -- AI stats  
    self.ai_mana = 1
    self.ai_max_mana = 1
    self.ai_health = 20
    self.ai_max_health = 20
    self.ai_hand_size = 7 -- Track AI hand size
    
    -- Turn system
    self.turn_number = 1
    self.is_player_turn = true
    
    -- Collections
    self.ai_cards_in_play = {}
    
    -- Game state
    self.game_over = false
    self.winner = nil
    
    -- Turn timing
    self.ai_turn_timer = 0
    self.ai_turn_duration = 2.0 -- AI turn lasts 2 seconds
    
    self.is_initialized = true
    print("Game scene initialized")
end

function GameScene:createUI()
    -- Get actual screen dimensions
    local screen_width, screen_height = love.graphics.getDimensions()
    print("Creating game UI with screen dimensions: " .. screen_width .. "x" .. screen_height)
    
    -- Simple direct positioning approach
    
    -- Hand area (bottom of screen)
    local hand_width = screen_width - 40
    local hand_height = 140
    local hand_x = 20
    local hand_y = screen_height - hand_height - 10
    self.hand_container = Layout.Container:new(hand_x, hand_y, hand_width, hand_height, {
        background_color = {0.2, 0.2, 0.3, 0.8},
        border_color = {0.4, 0.4, 0.5, 1},
        border_width = 2
    })
    
    -- Main play area (center) - make it scale with screen size  
    local play_area_width = math.min(screen_width - 40, 1000) -- Max width of 1000
    local play_area_height = math.min(screen_height * 0.4, 300) -- 40% of screen or max 300
    local play_area_x = (screen_width - play_area_width) / 2
    local play_area_y = (screen_height - play_area_height) / 2 - 30 -- Slightly above center
    self.play_area_container = Layout.Container:new(play_area_x, play_area_y, play_area_width, play_area_height, {
        background_color = {0.15, 0.2, 0.15, 0.6},
        border_color = {0.3, 0.4, 0.3, 1},
        border_width = 1
    })
    
    -- UI panel (top)
    local ui_panel_width = screen_width - 40
    local ui_panel_height = 80
    local ui_panel_x = 20
    local ui_panel_y = 10
    self.ui_panel_container = Layout.Container:new(ui_panel_x, ui_panel_y, ui_panel_width, ui_panel_height, {
        background_color = {0.25, 0.25, 0.35, 0.9},
        border_color = {0.4, 0.4, 0.5, 1},
        border_width = 2
    })
    
    -- End turn button (bottom right)
    local button_width, button_height = 120, 40
    self.end_turn_button = {
        x = screen_width - button_width - 30,
        y = screen_height - 200,
        width = button_width,
        height = button_height,
        text = "End Turn",
        enabled = true
    }
    
    print("Hand container at: " .. hand_x .. ", " .. hand_y .. " size: " .. hand_width .. "x" .. hand_height)
    print("Play area at: " .. play_area_x .. ", " .. play_area_y .. " size: " .. play_area_width .. "x" .. play_area_height)
    print("UI panel at: " .. ui_panel_x .. ", " .. ui_panel_y .. " size: " .. ui_panel_width .. "x" .. ui_panel_height)
    print("End turn button at: " .. self.end_turn_button.x .. ", " .. self.end_turn_button.y)
end

function GameScene:createInitialHand()
    local all_cards = Cards.getCollectibleCards()
    
    for i = 1, self.hand_size do
        local random_card = Utils.choice(all_cards)
        local card_instance = Cards.copyCard(random_card)
        
        -- Add instance-specific properties
        card_instance.hand_position = i
        card_instance.state = CardRenderer.STATES.IDLE
        card_instance.hover_scale = 1.0
        card_instance.x = 0
        card_instance.y = 0
        
        table.insert(self.player_hand, card_instance)
    end
    
    -- Arrange cards in hand
    self:arrangeHand()
end

function GameScene:arrangeHand(animate)
    animate = animate ~= false -- Default to true
    
    local hand_x, hand_y, hand_w, hand_h = self.hand_container.x, self.hand_container.y, self.hand_container.width, self.hand_container.height
    local card_width, card_height = self.card_renderer:getCardDimensions()
    
    -- Calculate positions for cards in hand
    local total_cards = #self.player_hand
    local available_width = hand_w - 40 -- Leave padding
    local max_card_width = card_width + 20 -- Include some spacing
    local card_spacing = math.min(max_card_width, available_width / total_cards)
    
    local start_x = hand_x + 20 + (available_width - (total_cards - 1) * card_spacing - card_width) / 2
    local card_y = hand_y + (hand_h - card_height) / 2
    
    for i, card in ipairs(self.player_hand) do
        local target_x = start_x + (i - 1) * card_spacing
        local target_y = card_y
        
        if animate and (card.x ~= target_x or card.y ~= target_y) then
            -- Animate to new position
            local move_tween = AnimationManager.Tween:new(card, 0.3, {
                x = target_x,
                y = target_y
            }, AnimationManager.Easing.outCubic)
            
            self.animation_manager:play(move_tween)
        else
            -- Set position immediately
            card.x = target_x
            card.y = target_y
        end
        
        card.hand_position = i
    end
end

function GameScene:arrangePlayedCards()
    local play_area_bounds = self:getPlayAreaBounds()
    local card_width, card_height = self.card_renderer:getCardDimensions()
    
    -- Calculate how many cards can fit per row
    local spacing_x = 15
    local spacing_y = 15
    local usable_width = play_area_bounds.width - (spacing_x * 2)
    local cards_per_row = math.max(1, math.floor(usable_width / (card_width + spacing_x)))
    
    for i, card in ipairs(self.cards_in_play) do
        local row = math.floor((i - 1) / cards_per_row)
        local col = (i - 1) % cards_per_row
        
        -- Center the cards in each row
        local cards_in_this_row = math.min(cards_per_row, #self.cards_in_play - row * cards_per_row)
        local row_width = cards_in_this_row * card_width + (cards_in_this_row - 1) * spacing_x
        local start_x = play_area_bounds.x + (play_area_bounds.width - row_width) / 2
        
        card.x = start_x + col * (card_width + spacing_x)
        card.y = play_area_bounds.y + spacing_y + row * (card_height + spacing_y)
    end
end

function GameScene:getCardAtPosition(x, y)
    -- Check cards in hand
    for _, card in ipairs(self.player_hand) do
        local card_w, card_h = self.card_renderer:getCardDimensions()
        local scale = card.hover_scale or 1.0
        local scaled_w = card_w * scale
        local scaled_h = card_h * scale
        local card_x = card.x - (scaled_w - card_w) / 2
        local card_y = card.y - (scaled_h - card_h) / 2
        
        if x >= card_x and x < card_x + scaled_w and 
           y >= card_y and y < card_y + scaled_h then
            return card
        end
    end
    
    -- Check cards in play
    for _, card in ipairs(self.cards_in_play) do
        local card_w, card_h = self.card_renderer:getCardDimensions()
        if x >= card.x and x < card.x + card_w and
           y >= card.y and y < card.y + card_h then
            return card
        end
    end
    
    return nil
end

function GameScene:getPlayAreaBounds()
    -- Get the play area container bounds directly
    if self.play_area_container then
        return {
            x = self.play_area_container.x,
            y = self.play_area_container.y,
            width = self.play_area_container.width,
            height = self.play_area_container.height
        }
    else
        -- Fallback to center area of screen
        local screen_width, screen_height = love.graphics.getDimensions()
        return {
            x = screen_width * 0.2,
            y = screen_height * 0.2,
            width = screen_width * 0.6,
            height = screen_height * 0.4
        }
    end
end

function GameScene:isPointInPlayArea(x, y, bounds)
    return x >= bounds.x and x <= bounds.x + bounds.width and
           y >= bounds.y and y <= bounds.y + bounds.height
end

function GameScene:isPointInEndTurnButton(x, y)
    local btn = self.end_turn_button
    if not btn then return false end
    return x >= btn.x and x <= btn.x + btn.width and
           y >= btn.y and y <= btn.y + btn.height
end

function GameScene:onEndTurnButtonClicked()
    if not self.is_player_turn or self.game_over then return end
    
    print("End turn button clicked")
    self:endPlayerTurn()
end

function GameScene:onMousePressed(event)
    if not self.is_active then return end
    
    -- Check if end turn button was clicked
    if self:isPointInEndTurnButton(event.x, event.y) then
        self:onEndTurnButtonClicked()
        return
    end
    
    local card = self:getCardAtPosition(event.x, event.y)
    if card then
        self.selected_card = card
        
        -- Start potential drag operation
        if Game.input then
            local screen_width, screen_height = love.graphics.getDimensions()
            Game.input:startDrag(card, {
                bounds = {x = 0, y = 0, width = screen_width, height = screen_height}
            })
        end
        
        -- Play sound effect
        if Game.audio then
            Game.audio:cardHover({volume = 0.6})
        end
    else
        -- No card selected
    end
end

function GameScene:onMouseReleased(event)
    if not self.is_active then return end
    
    -- Check if we were dragging a card and if it should be played
    if self.selected_card then
        local card = self.selected_card
        
        -- Use raw mouse coordinates instead of event coordinates which might be transformed
        local mouse_x, mouse_y = love.mouse.getPosition()
        
        -- Check if the card was dropped in the play area
        local play_area_bounds = self:getPlayAreaBounds()
        local in_play_area = self:isPointInPlayArea(mouse_x, mouse_y, play_area_bounds)
        
        if in_play_area then
            -- NOTE: Don't play the card here - let onDragEnd handle it to avoid double-playing
            print("DEBUG: Mouse released in play area - letting drag system handle card play")
        else
            -- Card wasn't dropped in play area, return to hand
            self:arrangeHand(true)
        end
        
        self.selected_card = nil
        
        -- Drag operation ends automatically when mouse is released
    end
end

function GameScene:onMouseMoved(event)
    if not self.is_active then return end
    
    local new_hovered_card = self:getCardAtPosition(event.x, event.y)
    
    -- Handle hover state changes
    if new_hovered_card ~= self.hovered_card then
        -- Remove hover from previous card
        if self.hovered_card then
            self.hovered_card.state = CardRenderer.STATES.IDLE
            self.card_renderer:playHoverAnimation(self.hovered_card, false)
        end
        
        -- Add hover to new card
        if new_hovered_card then
            new_hovered_card.state = CardRenderer.STATES.HOVER
            self.card_renderer:playHoverAnimation(new_hovered_card, true)
            
            -- Play hover sound
            if Game.audio then
                Game.audio:cardHover({volume = 0.3, pitch = 1.1})
            end
        end
        
        self.hovered_card = new_hovered_card
    end
end

function GameScene:onDragStart(event)
    if not self.is_active then return end
    
    self.dragged_card = event.object
    if self.dragged_card then
        self.dragged_card.state = CardRenderer.STATES.DRAGGING
        self.drag_start_pos.x = event.start_x
        self.drag_start_pos.y = event.start_y
        
        -- Store original position for potential return to hand
        self.dragged_card.original_x = self.dragged_card.x
        self.dragged_card.original_y = self.dragged_card.y
    end
end

function GameScene:onDragUpdate(event)
    if not self.is_active or not self.dragged_card then return end
    
    -- Update card position to follow mouse exactly
    local mouse_x, mouse_y = love.mouse.getPosition()
    local card_width, card_height = self.card_renderer:getCardDimensions()
    
    -- Center the card on the mouse cursor
    self.dragged_card.x = mouse_x - card_width / 2
    self.dragged_card.y = mouse_y - card_height / 2
    -- Update card visual state based on drag position
    local play_area_bounds = self:getPlayAreaBounds()
    
    if self:isPointInPlayArea(mouse_x, mouse_y, play_area_bounds) then
        -- Card is over play area
        self.dragged_card.state = CardRenderer.STATES.SELECTED
    else
        -- Card is not over a valid drop zone
        self.dragged_card.state = CardRenderer.STATES.DRAGGING
    end
end

function GameScene:onDragEnd(event)
    if not self.is_active or not event.object then return end
    
    local card = event.object
    local mouse_x, mouse_y = love.mouse.getPosition()
    local play_area_bounds = self:getPlayAreaBounds()
    local in_play_area = self:isPointInPlayArea(mouse_x, mouse_y, play_area_bounds)
    
    print("DEBUG: onDragEnd called for " .. card.name .. ", in_play_area: " .. tostring(in_play_area))
    
    if in_play_area and self:playCard(card) then
        -- Card was successfully played
        print("DEBUG: Card successfully played via drag system")
    else
        -- Return card to hand position
        print("DEBUG: Card not played, returning to hand")
        card.state = CardRenderer.STATES.IDLE
        if card.original_x and card.original_y then
            card.x = card.original_x
            card.y = card.original_y
            card.original_x = nil
            card.original_y = nil
        end
        self:arrangeHand(true)
    end
    
    self.dragged_card = nil
end

function GameScene:playCard(card)
    print("DEBUG: playCard() called for " .. card.name .. " (cost: " .. card.cost .. ")")
    print("DEBUG: Current mana before any checks: " .. self.player_mana)
    
    -- Check if player can afford the card
    if self.player_mana < card.cost then
        -- Not enough mana
        if Game.audio then
            Game.audio:errorSound()
        end
        
        -- Shake animation to indicate error
        -- Animation.shake(card, 5, 0.3) -- TODO: Fix animation reference
        print("Not enough mana to play " .. card.name .. " (cost: " .. card.cost .. ", have: " .. self.player_mana .. ")")
        self:arrangeHand(true)
        return false
    end
    
    -- Remove card from hand
    Utils.Table.remove(self.player_hand, card)
    
    -- Add card to play area, arranged in a grid
    table.insert(self.cards_in_play, card)
    self:arrangePlayedCards()
    
    card.state = CardRenderer.STATES.IDLE
    
    -- Spend mana
    local mana_before = self.player_mana
    local mana_after = self.player_mana - card.cost
    print("MANA: Spending " .. card.cost .. " mana. Before: " .. mana_before .. ", After: " .. mana_after)
    print("CARD: " .. card.name .. " costs " .. card.cost .. " mana")
    self.player_mana = mana_after
    
    -- Show mana change indicator
    self.mana_change_text = "-" .. card.cost .. " MANA"
    self.mana_change_timer = self.mana_change_duration
    
    -- Rearrange hand
    self:arrangeHand(true)
    
    -- Play card effects
    self:playCardEffects(card)
    
    -- Apply card effects based on card abilities
    print("DEBUG: Applying card effects for " .. card.name)
    print("DEBUG: Mana before applying effects: " .. self.player_mana)
    self:applyCardEffects(card, "player")
    print("DEBUG: Mana after applying effects: " .. self.player_mana)
    
    -- Play sound
    if Game.audio then
        Game.audio:cardPlace({volume = 0.7})
    end
    
    print("Played card: " .. card.name)
    print("DEBUG: Final mana after playing " .. card.name .. ": " .. self.player_mana)
    return true
end

function GameScene:playCardEffects(card)
    -- Entrance animation
    if self.animation_manager then
        local entrance_scale = AnimationManager.Tween:new(card, 0.2, {scale = 1.2}, AnimationManager.Easing.outBack)
        local settle_scale = AnimationManager.Tween:new(card, 0.15, {scale = 1.0}, AnimationManager.Easing.inCubic)
        entrance_scale:chain(settle_scale)
        self.animation_manager:play(entrance_scale)
    end
    
    -- Add card-specific effects here based on card abilities
    -- This would be expanded in a full implementation
end

function GameScene:applyCardEffects(card, owner)
    if not card.abilities then
        -- No special abilities, apply basic creature attack if applicable
        if card.type == "creature" and card.attack then
            if owner == "player" then
                self.ai_health = self.ai_health - card.attack
                print("ATTACK: " .. card.name .. " deals " .. card.attack .. " damage to AI")
            else
                self.player_health = self.player_health - card.attack
                print("ATTACK: AI " .. card.name .. " deals " .. card.attack .. " damage to Player")
            end
        end
        return
    end
    
    -- Apply each ability
    for _, ability in ipairs(card.abilities) do
        self:applyAbilityEffect(ability, card, owner)
    end
end

function GameScene:applyAbilityEffect(ability, card, owner)
    if ability == "direct_damage" then
        -- Lightning Bolt: Deal 3 damage
        local damage = 3
        if owner == "player" then
            self.ai_health = self.ai_health - damage
            print("LIGHTNING: " .. card.name .. " deals " .. damage .. " direct damage to AI")
        else
            self.player_health = self.player_health - damage
            print("LIGHTNING: AI " .. card.name .. " deals " .. damage .. " direct damage to Player")
        end
        
    elseif ability == "heal" then
        -- Healing Potion: Restore 5 health
        local healing = 5
        if owner == "player" then
            self.player_health = math.min(self.max_health, self.player_health + healing)
            print("HEAL: " .. card.name .. " heals Player for " .. healing .. " health")
        else
            self.ai_health = math.min(self.ai_max_health, self.ai_health + healing)
            print("HEAL: AI " .. card.name .. " heals AI for " .. healing .. " health")
        end
        
    elseif ability == "area_damage" then
        -- Fireball: Deal 4 damage to main target, 2 to secondary
        local main_damage = 4
        local splash_damage = 2
        if owner == "player" then
            self.ai_health = self.ai_health - main_damage
            print("FIREBALL: " .. card.name .. " deals " .. main_damage .. " area damage to AI")
        else
            self.player_health = self.player_health - main_damage
            print("FIREBALL: AI " .. card.name .. " deals " .. main_damage .. " area damage to Player")
        end
        
    elseif ability == "burn" then
        -- Fire Sprite: Deal damage plus burn effect
        local damage = card.attack or 1
        local burn_damage = 1
        if owner == "player" then
            self.ai_health = self.ai_health - (damage + burn_damage)
            print("BURN: " .. card.name .. " deals " .. damage .. " damage + " .. burn_damage .. " burn to AI")
        else
            self.player_health = self.player_health - (damage + burn_damage)
            print("BURN: AI " .. card.name .. " deals " .. damage .. " damage + " .. burn_damage .. " burn to Player")
        end
        
    elseif ability == "regenerate" then
        -- Water Elemental: Heal owner when played
        local healing = 2
        if owner == "player" then
            self.player_health = math.min(self.max_health, self.player_health + healing)
            print("REGEN: " .. card.name .. " regenerates " .. healing .. " health for Player")
            -- Also deal normal attack damage
            if card.attack then
                self.ai_health = self.ai_health - card.attack
                print("ATTACK: " .. card.name .. " also deals " .. card.attack .. " damage to AI")
            end
        else
            self.ai_health = math.min(self.ai_max_health, self.ai_health + healing)
            print("REGEN: AI " .. card.name .. " regenerates " .. healing .. " health for AI")
            if card.attack then
                self.player_health = self.player_health - card.attack
                print("ATTACK: AI " .. card.name .. " also deals " .. card.attack .. " damage to Player")
            end
        end
        
    elseif ability == "mana_boost" then
        -- Mana Crystal: Give extra mana
        local mana_gain = 1
        if owner == "player" then
            self.player_mana = self.player_mana + mana_gain
            print("MANA: " .. card.name .. " grants " .. mana_gain .. " bonus mana to Player")
        else
            self.ai_mana = self.ai_mana + mana_gain
            print("MANA: AI " .. card.name .. " grants " .. mana_gain .. " bonus mana to AI")
        end
        
    elseif ability == "taunt" or ability == "armor" then
        -- Earth Guardian: Stronger attack due to defensive abilities
        if card.attack then
            local damage = card.attack + 1 -- Bonus damage for defensive cards
            if owner == "player" then
                self.ai_health = self.ai_health - damage
                print("SHIELD: " .. card.name .. " deals " .. damage .. " reinforced damage to AI")
            else
                self.player_health = self.player_health - damage
                print("SHIELD: AI " .. card.name .. " deals " .. damage .. " reinforced damage to Player")
            end
        end
        
    elseif ability == "flying" or ability == "haste" then
        -- Air Wisp: Extra damage from speed/flight
        if card.attack then
            local damage = card.attack + 1 -- Bonus damage for evasive abilities
            if owner == "player" then
                self.ai_health = self.ai_health - damage
                print("SWIFT: " .. card.name .. " deals " .. damage .. " swift damage to AI")
            else
                self.player_health = self.player_health - damage
                print("SWIFT: AI " .. card.name .. " deals " .. damage .. " swift damage to Player")
            end
        end
        
    elseif ability == "extra_turn" then
        -- Time Warp: Give player an extra turn with full mana
        if owner == "player" then
            print("EXTRA TURN: " .. card.name .. " grants an extra turn!")
            -- Set flag to take extra turn after AI turn
            self.extra_turn_pending = true
        else
            print("EXTRA TURN: AI " .. card.name .. " grants AI an extra turn!")
            self.ai_extra_turn_pending = true
        end
        
    else
        -- Default: Apply base creature attack if it exists
        if card.attack then
            if owner == "player" then
                self.ai_health = self.ai_health - card.attack
                print("ATTACK: " .. card.name .. " deals " .. card.attack .. " damage to AI")
            else
                self.player_health = self.player_health - card.attack
                print("ATTACK: AI " .. card.name .. " deals " .. card.attack .. " damage to Player")
            end
        end
    end
end

function GameScene:checkWinConditions()
    if self.player_health <= 0 then
        self.game_over = true
        self.winner = "AI"
        print("AI WINS! Player health reached 0")
    elseif self.ai_health <= 0 then
        self.game_over = true
        self.winner = "Player"
        print("PLAYER WINS! AI health reached 0")
    elseif self.turn_number >= 25 then
        -- Game ends after 25 turns
        self.game_over = true
        if self.player_health > self.ai_health then
            self.winner = "Player"
            print("PLAYER WINS by health advantage!")
        elseif self.ai_health > self.player_health then
            self.winner = "AI"
            print("AI WINS by health advantage!")
        else
            self.winner = "Draw"
            print("GAME ENDS in a draw!")
        end
    end
end

function GameScene:endPlayerTurn()
    if not self.is_player_turn or self.game_over then return end
    
    print("TURN: Player turn ending... Current mana: " .. self.player_mana)
    
    -- Check if player has extra turn pending
    if self.extra_turn_pending then
        print("Player taking extra turn!")
        self.extra_turn_pending = false
        -- Give player full mana for extra turn
        self.player_mana = self.max_mana
        print("EXTRA TURN: Player mana restored to " .. self.player_mana)
        return -- Stay on player turn
    end
    
    self.is_player_turn = false
    self.ai_turn_timer = 0  -- Reset AI turn timer
    self.ai_cards_at_turn_start = #self.ai_cards_in_play  -- Track cards at start of AI turn
    
    -- Regenerate AI mana (mana increases each turn)  
    self.ai_max_mana = math.min(10, self.turn_number)
    self.ai_mana = self.ai_max_mana
    
    print("AI turn starting...")
    -- AI will play during update loop over time
end

function GameScene:startPlayerTurn()
    print("AI turn ending, player turn starting...")
    self.is_player_turn = true
    self.turn_number = self.turn_number + 1
    
    -- Regenerate player mana (mana increases each turn)
    self.max_mana = math.min(10, self.turn_number)
    print("MANA: Turn " .. self.turn_number .. " - Restoring player mana from " .. self.player_mana .. " to " .. self.max_mana)
    self.player_mana = self.max_mana
    
    -- Draw a new card
    self:drawCard()
    
    print("Turn " .. self.turn_number .. " - Player mana: " .. self.player_mana)
    
    -- Check win conditions
    self:checkWinConditions()
end

function GameScene:updateAITurn(dt)
    if self.is_player_turn or self.game_over then return end
    
    self.ai_turn_timer = self.ai_turn_timer + dt
    
    -- AI plays a card every 0.5 seconds during its turn
    local play_interval = 0.5
    local cards_to_play = math.floor(self.ai_turn_timer / play_interval)
    local cards_already_played = #self.ai_cards_in_play - self.ai_cards_at_turn_start
    
    if cards_to_play > cards_already_played and self.ai_mana > 0 then
        self:playAICard()
    end
    
    -- End AI turn after duration
    if self.ai_turn_timer >= self.ai_turn_duration then
        -- Check if AI has extra turn pending
        if self.ai_extra_turn_pending then
            print("AI taking extra turn!")
            self.ai_extra_turn_pending = false
            self.ai_turn_timer = 0 -- Reset timer for extra turn
            -- Give AI full mana for extra turn
            self.ai_mana = self.ai_max_mana
        else
            self:startPlayerTurn()
        end
    end
end

function GameScene:playAICard()
    -- Try to play one AI card
    local card_cost = math.random(1, math.min(3, self.ai_mana))
    
    if self.ai_mana >= card_cost then
        self.ai_mana = self.ai_mana - card_cost
        self.ai_hand_size = math.max(0, self.ai_hand_size - 1)
        
        -- Create AI card using real card data
        local all_cards = Cards.getCollectibleCards()
        local affordable_cards = {}
        for _, card_def in ipairs(all_cards) do
            if card_def.cost <= card_cost then
                table.insert(affordable_cards, card_def)
            end
        end
        
        -- Pick a random affordable card or create a basic one
        local ai_card
        if #affordable_cards > 0 then
            local card_template = affordable_cards[math.random(#affordable_cards)]
            ai_card = {
                id = card_template.id,
                name = card_template.name,
                description = card_template.description,
                cost = card_template.cost,
                type = card_template.type,
                attack = card_template.attack,
                health = card_template.health,
                abilities = card_template.abilities,
                x = 0,
                y = 0
            }
        else
            -- Fallback basic card
            ai_card = {
                name = "AI Basic " .. (#self.ai_cards_in_play + 1),
                cost = card_cost,
                type = "creature",
                attack = math.random(1, card_cost + 1),
                health = math.random(1, card_cost + 2),
                x = 0,
                y = 0
            }
        end
        table.insert(self.ai_cards_in_play, ai_card)
        
        -- Apply AI card effects
        self:applyCardEffects(ai_card, "ai")
        
        print("AI played: " .. ai_card.name .. " (" .. (ai_card.attack or "0") .. "/" .. (ai_card.health or "0") .. ")")
        
        self:arrangeAICards()
    end
end

function GameScene:arrangeAICards()
    -- Position AI cards above the play area in a neat grid
    local play_area_bounds = self:getPlayAreaBounds()
    local card_width, card_height = self.card_renderer:getCardDimensions()
    
    local spacing_x = 15
    local spacing_y = 15
    local usable_width = play_area_bounds.width - (spacing_x * 2)
    local cards_per_row = math.max(1, math.floor(usable_width / (card_width + spacing_x)))
    
    for i, card in ipairs(self.ai_cards_in_play) do
        local row = math.floor((i - 1) / cards_per_row)
        local col = (i - 1) % cards_per_row
        
        -- Center the cards in each row
        local cards_in_this_row = math.min(cards_per_row, #self.ai_cards_in_play - row * cards_per_row)
        local row_width = cards_in_this_row * card_width + (cards_in_this_row - 1) * spacing_x
        local start_x = play_area_bounds.x + (play_area_bounds.width - row_width) / 2
        
        card.x = start_x + col * (card_width + spacing_x)
        card.y = play_area_bounds.y - card_height - 30 - row * (card_height + spacing_y) -- Above play area
    end
end

function GameScene:drawCard()
    if #self.player_hand >= self.hand_size then
        return nil -- Hand is full
    end
    
    local all_cards = Cards.getCollectibleCards()
    local new_card = Cards.copyCard(Utils.choice(all_cards))
    
    -- Set up card instance
    local screen_width = love.graphics.getWidth()
    local card_width, card_height = self.card_renderer:getCardDimensions()
    new_card.state = CardRenderer.STATES.IDLE
    new_card.hover_scale = 1.0
    new_card.x = screen_width / 2
    new_card.y = -card_height
    
    table.insert(self.player_hand, new_card)
    
    -- Animate card draw
    self:arrangeHand(true)
    
    -- Play draw sound
    if Game.audio then
        Game.audio:drawCard()
    end
    
    return new_card
end

function GameScene:update(dt)
    if not self.is_active then return end
    
    -- Stop updating if game is over
    if self.game_over then
        -- Only update animations and UI for visual feedback
        if self.animation_manager then
            self.animation_manager:update(dt)
        end
        if self.ui_container then
            self.ui_container:update(dt)
        end
        
        -- Handle input to return to menu
        if Game and Game.input then
            if Game.input:isActionJustPressed("back") then
                Game.scene_manager:switchScene("menu_scene", {
                    type = "fade",
                    duration = 0.5
                })
            end
        end
        return -- Don't update game logic when game is over
    end
    
    -- Update AI turn if it's AI's turn
    self:updateAITurn(dt)
    
    -- Update animation system
    if self.animation_manager then
        self.animation_manager:update(dt)
    end
    
    -- Update card renderer animations
    if self.card_renderer then
        self.card_renderer:update(dt)
    end
    
    -- Update UI layout
    if self.ui_container then
        self.ui_container:update(dt)
    end
    
    -- Update mana change indicator
    if self.mana_change_timer > 0 then
        self.mana_change_timer = self.mana_change_timer - dt
        if self.mana_change_timer <= 0 then
            self.mana_change_text = ""
        end
    end
    
    -- Handle debug input
    if Game and Game.input then
        if Game.input:isActionJustPressed("pause") then
            -- Toggle pause or return to menu
            Game.scene_manager:pushScene("pause_menu", {
                type = "fade",
                duration = 0.2
            })
        end
        
        -- Debug: Draw card with 'D' key
        if love.keyboard.isDown("d") and #self.player_hand < self.hand_size then
            self:drawCard()
        end
        
        -- Debug: End turn with 'T' key
        -- Note: This might be causing the mana issue if pressed accidentally!
        if love.keyboard.isDown("t") then
            print("DEBUG: 'T' key pressed - ending player turn!")
            self:endPlayerTurn()
        end
    end
end

function GameScene:draw()
    if not self.is_active then return end
    
    -- Draw UI containers (backgrounds) individually
    if self.hand_container then
        self.hand_container:draw()
    end
    if self.play_area_container then
        self.play_area_container:draw()
    end
    if self.ui_panel_container then
        self.ui_panel_container:draw()
    end
    
    -- Draw cards in play area (player cards)
    for _, card in ipairs(self.cards_in_play) do
        local flip_progress = self.card_renderer:getCardAnimation(card)
        self.card_renderer:drawCard(card, card.x, card.y, {
            state = card.state,
            scale = card.scale or 1.0,
            flip_progress = flip_progress
        })
    end
    
    -- Draw AI cards (simple placeholder rectangles)
    for _, card in ipairs(self.ai_cards_in_play) do
        love.graphics.setColor(0.8, 0.3, 0.3, 0.9) -- Red for AI cards
        local card_width, card_height = self.card_renderer:getCardDimensions()
        love.graphics.rectangle("fill", card.x, card.y, card_width, card_height)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", card.x, card.y, card_width, card_height)
        
        -- Draw card info
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.print(card.name, card.x + 3, card.y + 3)
        love.graphics.print("ATK:" .. (card.attack or 1) .. " HP:" .. (card.health or 1), card.x + 3, card.y + 20)
        love.graphics.print("COST:" .. card.cost, card.x + 3, card.y + 35)
    end
    
    -- Draw cards in hand
    for _, card in ipairs(self.player_hand) do
        local flip_progress = self.card_renderer:getCardAnimation(card)
        self.card_renderer:drawCard(card, card.x, card.y, {
            state = card.state,
            scale = card.hover_scale or 1.0,
            flip_progress = flip_progress
        })
    end
    
    -- Draw UI elements
    self:drawUI()
    
    -- Draw end turn button
    self:drawEndTurnButton()
    
    -- Debug information
    if Game.debug_mode then
        self:drawDebugInfo()
    end
end

function GameScene:drawUI()
    -- Draw UI panel background
    love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
    local ui_x, ui_y, ui_w, ui_h = self.ui_panel_container.x, self.ui_panel_container.y, self.ui_panel_container.width, self.ui_panel_container.height
    love.graphics.rectangle("fill", ui_x, ui_y, ui_w, ui_h)
    
    -- Draw game stats
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.setColor(0.8, 0.9, 1, 1)
    
    -- Top row - Player stats (left) and AI stats (right)
    local turn_indicator = self.is_player_turn and "YOUR TURN" or "AI TURN"
    love.graphics.setColor(self.is_player_turn and {0.4, 1, 0.4, 1} or {1, 0.4, 0.4, 1})
    love.graphics.print(turn_indicator, ui_x + 20, ui_y + 15)
    
    love.graphics.setColor(0.8, 0.9, 1, 1)
    love.graphics.print("Turn: " .. self.turn_number, ui_x + 150, ui_y + 15)
    
    -- Player stats (left side)
    love.graphics.setColor(0.4, 1, 0.4, 1)
    love.graphics.print("HP: " .. self.player_health .. "/" .. self.max_health, ui_x + 250, ui_y + 15)
    love.graphics.print("MANA: " .. self.player_mana .. "/" .. self.max_mana, ui_x + 370, ui_y + 15)
    
    -- Mana change indicator
    if self.mana_change_timer > 0 then
        local alpha = math.min(1.0, self.mana_change_timer / 0.5) -- Fade out in last 0.5 seconds
        love.graphics.setColor(1, 0.3, 0.3, alpha) -- Red color for mana spent
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.print(self.mana_change_text, ui_x + 370, ui_y + 35)
        love.graphics.setFont(love.graphics.newFont(16)) -- Reset font
    end
    
    -- AI stats (right side)  
    love.graphics.setColor(1, 0.4, 0.4, 1)
    love.graphics.print("AI HP: " .. self.ai_health .. "/" .. self.ai_max_health, ui_x + ui_w - 200, ui_y + 15)
    love.graphics.print("MANA: " .. self.ai_mana .. "/" .. self.ai_max_mana, ui_x + ui_w - 100, ui_y + 15)
    
    -- Bottom row - instructions or game over message
    love.graphics.setFont(love.graphics.newFont(12))
    if self.game_over then
        love.graphics.setColor(1, 1, 0, 1) -- Yellow for game over
        local game_over_text = "*** GAME OVER - " .. (self.winner or "Unknown") .. " WINS! ***"
        if self.winner == "Draw" then
            game_over_text = "*** GAME OVER - It's a DRAW! ***"
        end
        love.graphics.print(game_over_text, ui_x + 20, ui_y + 45)
        
        -- Instructions to return to menu
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.print("Press ESC to return to menu", ui_x + 20, ui_y + 65)
    elseif self.is_player_turn then
        love.graphics.setColor(0.7, 0.8, 0.9, 1)
        love.graphics.print("Drag cards to play them, then click 'End Turn' to let the AI play.", ui_x + 20, ui_y + 40)
    else
        love.graphics.setColor(0.7, 0.8, 0.9, 1)
        love.graphics.print("AI is thinking and playing cards...", ui_x + 20, ui_y + 40)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function GameScene:drawEndTurnButton()
    local btn = self.end_turn_button
    if not btn then return end
    
    -- Button background
    if btn.enabled and self.is_player_turn and not self.game_over then
        love.graphics.setColor(0.3, 0.6, 0.3, 0.9)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    end
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
    
    -- Button border
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height)
    
    -- Button text
    love.graphics.setColor(1, 1, 1, btn.enabled and 1 or 0.5)
    love.graphics.setFont(love.graphics.newFont(14))
    local text_width = love.graphics.getFont():getWidth(btn.text)
    local text_height = love.graphics.getFont():getHeight()
    love.graphics.print(btn.text, 
        btn.x + (btn.width - text_width) / 2,
        btn.y + (btn.height - text_height) / 2)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function GameScene:drawDebugInfo()
    local debug_text = string.format(
        "Debug Mode\nCards in Hand: %d\nCards in Play: %d\nHovered: %s\nSelected: %s",
        #self.player_hand,
        #self.cards_in_play,
        self.hovered_card and self.hovered_card.name or "None",
        self.selected_card and self.selected_card.name or "None"
    )
    
    love.graphics.setColor(1, 1, 0, 0.8)
    love.graphics.print(debug_text, 10, 100)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameScene:onResize(width, height)
    if self.ui_container then
        self.ui_container:onResize(width, height)
        self:arrangeHand(false) -- Rearrange without animation
    end
end

return GameScene
