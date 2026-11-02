local Snake = require("src.systems.snake")
local Food = require("src.systems.food")
local Levels = require("src.systems.levels")
local VirtualControls = require("src.systems.virtual_controls")
local HUDQuotes = require("src.systems.hud_quotes")

return function(game)
    local state = {
        level = nil,
        difficulty = nil,
        snake = nil,
        foods = nil,
        controls = VirtualControls.new(),
        quotes = HUDQuotes.new(),
        tick_timer = 0,
        tick_length = 0.17,
        speed = 6,
        speed_increment = 0.25,
        goal_good = 0,
        hud_height = 32,
        grid = {
            x = 0,
            y = 0,
            cell = 8,
        },
    }

    local function create_level_snake(level)
        local snake = Snake.new(2, 0)
        local width = math.max(1, level.grid_width or 1)
        local height = math.max(1, level.grid_height or 1)

        if width >= 3 then
            local head_x = math.max(2, math.min(width - 1, math.floor(width * 0.5)))
            local head_y = math.max(0, math.min(height - 1, math.floor(height * 0.5)))
            snake.body = {
                { x = head_x, y = head_y },
                { x = head_x - 1, y = head_y },
                { x = head_x - 2, y = head_y },
            }
            snake.direction = "right"
            snake.queued_direction = "right"
            return snake
        end

        if height >= 3 then
            local head_x = math.max(0, math.min(width - 1, math.floor(width * 0.5)))
            local head_y = math.max(2, math.min(height - 1, math.floor(height * 0.5)))
            snake.body = {
                { x = head_x, y = head_y },
                { x = head_x, y = head_y - 1 },
                { x = head_x, y = head_y - 2 },
            }
            snake.direction = "down"
            snake.queued_direction = "down"
            return snake
        end

        snake.body = {
            { x = math.max(0, math.min(width - 1, math.floor(width * 0.5))), y = math.max(0, math.min(height - 1, math.floor(height * 0.5))) },
        }
        snake.direction = width > 1 and "right" or "down"
        snake.queued_direction = snake.direction
        return snake
    end

    local function count_foods(foods, kind)
        local count = 0
        for _, food in ipairs(foods or {}) do
            if food.kind == kind then
                count = count + 1
            end
        end
        return count
    end

    local function apply_penalty()
        game.session.lives = game.session.lives - 1
        game.session.level_stats.bad_hits = game.session.level_stats.bad_hits + 1
        game.session.score = math.max(0, game.session.score - 25)
    end

    local function opacity_value(value, fallback)
        local opacity = tonumber(value)
        if not opacity then
            return fallback
        end
        if opacity > 1 then
            opacity = opacity / 100
        end
        return math.max(0, math.min(1, opacity))
    end

    local function theme_value(state_ref, key)
        if state_ref.theme and state_ref.theme[key] ~= nil then
            return state_ref.theme[key]
        end
        return state_ref.level and state_ref.level[key] or nil
    end

    local function get_food_def(kind)
        local level = state.level or {}
        local dataset_foods = game.dataset.foods or {}
        local level_food_id = kind == "good" and level.good_food_type or level.bad_food_type
        local fallback_id = kind
        return dataset_foods[level_food_id] or dataset_foods[fallback_id] or {
            id = fallback_id,
            name_key = kind == "good" and "food_good_name" or "food_bad_name",
            kind = kind,
        }
    end

    function state:enter()
        self.level = Levels.get_level(game.dataset, game.session.level_index)
        self.difficulty = game:get_difficulty_profile(game.settings.values.difficulty)
        self.theme = self.level.theme or {}
        self.good_food_def = get_food_def("good")
        self.bad_food_def = get_food_def("bad")
        self.snake = create_level_snake(self.level)
        self.food_counts = {
            good_count = math.max(1, math.floor(self.level.good_count * (self.difficulty.good_food_multiplier or 1) + 0.5)),
            bad_count = math.max(0, math.floor(self.level.bad_count * (self.difficulty.bad_food_multiplier or 1) + 0.5)),
        }
        self.foods, self.food_counts = Food.spawn_set(self.level, self.snake, self.food_counts)
        self.goal_good = count_foods(self.foods, "good")
        self.speed = self.difficulty.initial_speed or 6
        self.speed_increment = self.difficulty.speed_increment or 0.25
        self.tick_length = 1 / self.speed
        self.tick_timer = 0
        self:update_layout()
        self.quotes:reset(self.level, game.localization, game.assets:get_head_frame_count())
        game.session.level_stats = {
            good_collected = 0,
            bad_hits = 0,
            time = 0,
            level_name = game.localization:get(self.level.name_key),
            score = 0,
            bonus = 0,
        }
        game.audio:play_music(game:get_music_id(self.level.id, self.level.music))
    end

    function state:update_layout()
        local width = game.renderer.logical_width
        local height = game.renderer.logical_height
        local usable_width = width - 12
        local usable_height = height - self.hud_height - 12
        local cell = math.floor(math.min(usable_width / self.level.grid_width, usable_height / self.level.grid_height))
        self.grid.cell = math.max(8, cell)

        local grid_width = self.level.grid_width * self.grid.cell
        local grid_height = self.level.grid_height * self.grid.cell
        self.grid.x = math.floor((width - grid_width) * 0.5)
        self.grid.y = self.hud_height + math.floor((usable_height - grid_height) * 0.5) + 6
    end

    function state:update(dt)
        game.session.level_stats.time = game.session.level_stats.time + dt
        game.session.level_stats.score = game.session.score
        self.tick_timer = self.tick_timer + dt
        self.quotes:update(dt)

        local direction = game.input:get_direction_pressed()
        if direction then
            self.snake:set_direction(direction)
        end

        for _, tap in ipairs(game.input:get_taps()) do
            if game:should_show_touch_controls() then
                local touch_direction = self.controls:get_direction_at(
                    tap.x,
                    tap.y,
                    game.renderer.logical_width,
                    game.renderer.logical_height,
                    self.hud_height,
                    game.settings.values.control_layout
                )
                if touch_direction then
                    self.snake:set_direction(touch_direction)
                end
            end
        end

        if game.input:back_pressed() then
            game.state_machine:change("menu")
            return
        end

        while self.tick_timer >= self.tick_length do
            self.tick_timer = self.tick_timer - self.tick_length
            local head = self.snake:move()

            if head.x < 0 or head.y < 0 or head.x >= self.level.grid_width or head.y >= self.level.grid_height then
                apply_penalty()
                self:reset_snake()
            elseif self.snake:has_self_collision() then
                apply_penalty()
                self:reset_snake()
            else
                local food = Food.consume_at(self.foods, head.x, head.y)
                if food then
                    if food.kind == "good" then
                        self.snake:grow(1)
                        game.session.score = game.session.score + 100
                        game.session.level_stats.good_collected = game.session.level_stats.good_collected + 1
                        self.speed = self.speed + self.speed_increment
                        self.tick_length = math.max(0.05, 1 / self.speed)
                        game.audio:play_sfx(game:get_sfx_id("good_collect", "pickup_good"))
                    else
                        self.snake:shrink(1)
                        apply_penalty()
                        game.audio:play_sfx(game:get_sfx_id("bad_hit", "pickup_bad"))
                    end
                end
            end

            if game.session.lives <= 0 then
                game.audio:stop_music()
                game.state_machine:change("score_entry", { victory = false })
                return
            end

            if game.session.level_stats.good_collected >= self.goal_good then
                game.audio:stop_music()
                game.session.level_stats.score = game.session.score
                game.session.level_stats.bonus = math.max(0, math.floor(250 - game.session.level_stats.time * 8))
                game.session.score = game.session.score + game.session.level_stats.bonus
                game.state_machine:change("level_stats")
                return
            end
        end
    end

    function state:reset_snake()
        self.snake = create_level_snake(self.level)
    end

    function state:draw_grid()
        local play_panel = game.assets:get_palette_color(self.theme.play_panel, { 0.08, 0.12, 0.16, 1 })
        local border = game.assets:get_palette_color(self.theme.grid_border, { 0.12, 0.18, 0.14, 1 })
        local grid_a = game.assets:get_palette_color(self.theme.grid_a, { 0.06, 0.20, 0.08, 0.88 })
        local grid_b = game.assets:get_palette_color(self.theme.grid_b, { 0.06, 0.23, 0.08, 0.88 })
        local grid_opacity = opacity_value(theme_value(self, "grid_opacity") or theme_value(self, "playboard_opacity"), 0.78)
        local play_panel_opacity = theme_value(self, "play_panel_opacity")
        border[4] = opacity_value(theme_value(self, "grid_border_opacity"), grid_opacity)
        grid_a[4] = grid_opacity
        grid_b[4] = grid_opacity
        if play_panel_opacity ~= nil then
            play_panel[4] = opacity_value(play_panel_opacity, 0)
            love.graphics.setColor(play_panel)
            love.graphics.rectangle("fill", self.grid.x - 2, self.grid.y - 2, self.level.grid_width * self.grid.cell + 4, self.level.grid_height * self.grid.cell + 4)
        end
        love.graphics.setColor(border)
        love.graphics.rectangle("fill", self.grid.x - 2, self.grid.y - 2, self.level.grid_width * self.grid.cell + 4, self.level.grid_height * self.grid.cell + 4)

        for y = 0, self.level.grid_height - 1 do
            for x = 0, self.level.grid_width - 1 do
                love.graphics.setColor(((x + y) % 2 == 0) and grid_a or grid_b)
                love.graphics.rectangle("fill", self.grid.x + x * self.grid.cell, self.grid.y + y * self.grid.cell, self.grid.cell, self.grid.cell)
            end
        end
    end

    function state:draw_foods()
        for _, food in ipairs(self.foods) do
            local def = food.kind == "good" and self.good_food_def or self.bad_food_def
            local image = game.assets:get_food_icon(def.id, food.kind)
            local scale = self.grid.cell / 8
            local offset = (self.grid.cell - 8 * scale) * 0.5
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                image,
                self.grid.x + food.x * self.grid.cell + offset,
                self.grid.y + food.y * self.grid.cell + offset,
                0,
                scale,
                scale
            )
        end
    end

    function state:draw_snake()
        for index, segment in ipairs(self.snake.body) do
            if index == 1 then
                love.graphics.setColor(0.98, 0.78, 0.3, 1)
            else
                love.graphics.setColor(0.57, 0.82, 0.42, 1)
            end
            love.graphics.rectangle("fill", self.grid.x + segment.x * self.grid.cell, self.grid.y + segment.y * self.grid.cell, self.grid.cell, self.grid.cell)
        end
    end

    function state:draw_hud()
        love.graphics.setFont(game.assets:get_font("small"))
        local width = game.renderer.logical_width
        local quote = self.quotes:get_text()
        local head_frame = self.quotes:is_speaking() and self.quotes:get_frame() or 1
        local head_w, head_h = game.assets:get_head_dimensions()
        local head_scale = math.min(24 / math.max(1, head_w), 24 / math.max(1, head_h))
        local head_draw_w = head_w * head_scale
        local head_draw_h = head_h * head_scale
        local head_x = width - 8 - head_draw_w
        local head_y = 4
        local good_name = game.localization:get(self.good_food_def.name_key)
        local bad_name = game.localization:get(self.bad_food_def.name_key)
        local hud_bg = game.assets:get_palette_color(self.theme.hud_bg, { 0.03, 0.07, 0.11, 0.78 })
        local hud_line = game.assets:get_palette_color(self.theme.hud_line, { 0.55, 0.75, 0.9, 0.6 })
        local hud_text = game.assets:get_palette_color(self.theme.hud_text, { 0.95, 0.98, 1, 1 })
        love.graphics.setColor(hud_bg)
        love.graphics.rectangle("fill", 0, 0, width, self.hud_height)
        love.graphics.setColor(hud_line)
        love.graphics.line(0, self.hud_height, width, self.hud_height)
        love.graphics.setColor(hud_text)
        love.graphics.print(game.localization:get(self.level.name_key), 8, 5)
        love.graphics.print(game.localization:get("hud_score", { score = game.session.score }), 8, 15)
        love.graphics.print(game.localization:get("hud_lives", { lives = game.session.lives }), 98, 5)
        love.graphics.print(game.localization:get("hud_goal", {
            current = game.session.level_stats.good_collected,
            total = self.goal_good,
        }), 98, 15)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(game.assets:get_food_icon(self.good_food_def.id, "good"), 182, 4)
        love.graphics.draw(game.assets:get_food_icon(self.bad_food_def.id, "bad"), 182, 15)
        love.graphics.setFont(game.assets:get_font("small"))
        love.graphics.printf(good_name, 194, 4, 62, "left")
        love.graphics.printf(bad_name, 194, 15, 62, "left")

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(game.assets:get_image("head"), game.assets:get_head_quad(head_frame), head_x, head_y, 0, head_scale, head_scale)

        if quote then
            local bubble_x = width - 148
            local bubble_y = 2
            local bubble_w = 98
            local bubble_h = 28
            local head_center_y = head_y + math.floor(head_draw_h * 0.5)
            local head_anchor_x = head_x + math.floor(head_draw_w * 0.4)
            local tail_y = math.max(bubble_y + 6, math.min(bubble_y + bubble_h - 6, head_center_y))
            local bubble_bg = game.assets:get_palette_color(self.theme.quote_bubble_bg, { 1, 1, 1, 1 })
            local bubble_fg = game.assets:get_palette_color(self.theme.quote_bubble_text, { 0.05, 0.06, 0.08, 1 })
            love.graphics.setColor(bubble_bg)
            love.graphics.rectangle("fill", bubble_x, bubble_y, bubble_w, bubble_h, 4, 4)
            love.graphics.polygon(
                "fill",
                bubble_x + bubble_w, tail_y - 4,
                bubble_x + bubble_w, tail_y + 4,
                head_anchor_x, head_center_y
            )
            love.graphics.setColor(bubble_fg)
            love.graphics.rectangle("line", bubble_x + 0.5, bubble_y + 0.5, bubble_w - 1, bubble_h - 1, 4, 4)
            love.graphics.polygon(
                "line",
                bubble_x + bubble_w, tail_y - 4,
                bubble_x + bubble_w, tail_y + 4,
                head_anchor_x, head_center_y
            )
            love.graphics.printf(quote, bubble_x + 5, bubble_y + 4, bubble_w - 10, "left")
        end
    end

    function state:draw()
        local width = game.renderer.logical_width
        local height = game.renderer.logical_height
        local background = game.assets:get_level_background(self.level.id)
        local play_bg = game.assets:get_palette_color(self.theme.play_bg, { 0.04, 0.06, 0.09, 1 })
        self:update_layout()
        love.graphics.setColor(play_bg)
        love.graphics.rectangle("fill", 0, 0, width, height)
        if background then
            love.graphics.setColor(1, 1, 1, 1)
            local sx = width / background:getWidth()
                local sy = height / background:getHeight()
                love.graphics.draw(background, 0, 0, 0, sx, sy)
            end
        self:draw_grid()
        self:draw_foods()
        self:draw_snake()
        self:draw_hud()
        if game:should_show_touch_controls() then
            self.controls:draw(game.assets, width, height, self.hud_height, game.settings.values.control_layout)
        end
    end

    return state
end
