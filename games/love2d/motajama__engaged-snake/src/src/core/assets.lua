local Assets = {}
Assets.__index = Assets

local function rgb(hex)
    return {
        tonumber(hex:sub(2, 3), 16) / 255,
        tonumber(hex:sub(4, 5), 16) / 255,
        tonumber(hex:sub(6, 7), 16) / 255,
        1,
    }
end

local function color_from_value(value, fallback)
    if type(value) == "string" and value:sub(1, 1) == "#" and #value == 7 then
        return rgb(value)
    end
    return fallback
end

function Assets.new(renderer)
    return setmetatable({
        renderer = renderer,
        images = {},
        food_icons = {},
        level_backgrounds = {},
        quads = {},
        fonts = {},
        palette = {
            bg = rgb("#101820"),
            panel = rgb("#203040"),
            accent = rgb("#f9c74f"),
            accent2 = rgb("#90be6d"),
            danger = rgb("#f94144"),
            text = rgb("#f1f5f9"),
            mute = rgb("#94a3b8"),
        },
    }, Assets)
end

local function make_canvas(width, height, painter)
    local canvas = love.graphics.newCanvas(width, height)
    canvas:setFilter("nearest", "nearest")
    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    painter()
    love.graphics.setCanvas()
    love.graphics.pop()
    return canvas
end

local function load_image_or_placeholder(path, fallback)
    if path and love.filesystem.getInfo(path) then
        local image = love.graphics.newImage(path)
        image:setFilter("nearest", "nearest")
        return image
    end
    return fallback()
end

local function load_font_slot(slot, fallback_size)
    local size = slot and slot.size or fallback_size
    local hinting = slot and slot.hinting or "mono"

    if slot and slot.path then
        local font_path = "datasets/base/" .. slot.path
        if love.filesystem.getInfo(font_path) then
            local ok, font = pcall(love.graphics.newFont, font_path, size, hinting)
            if ok and font then
                return font
            end
        end
    end

    return love.graphics.newFont(size, hinting)
end

function Assets:load(dataset)
    self.dataset = dataset
    self.food_icons = {}
    self.level_backgrounds = {}
    local font_config = dataset.ui_fonts or {}
    self.fonts.small = load_font_slot(font_config.small, 8)
    self.fonts.medium = load_font_slot(font_config.medium, 12)
    self.fonts.large = load_font_slot(font_config.large, 16)
    self.fonts.title = load_font_slot(font_config.title, 24)

    local width = self.renderer.logical_width
    local height = self.renderer.logical_height

    local function make_screen_placeholder(screen, base_color, accent_color)
        return load_image_or_placeholder(screen and screen.image and ("datasets/base/" .. screen.image), function()
            return make_canvas(width, height, function()
                love.graphics.clear(base_color[1], base_color[2], base_color[3], 1)
                love.graphics.setColor(accent_color[1], accent_color[2], accent_color[3], accent_color[4] or 1)
                for i = 0, math.floor(width / 24) do
                    love.graphics.rectangle("fill", i * 24, height - 42 + (i % 2) * 4, 18, 42)
                end
            end)
        end)
    end

    self.images.title = load_image_or_placeholder(dataset.title_screen and ("datasets/base/" .. dataset.title_screen), function()
        return make_canvas(width, height, function()
        love.graphics.clear(0.08, 0.1, 0.14, 1)
        love.graphics.setColor(rgb("#1d3557"))
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setColor(rgb("#457b9d"))
        local columns = math.floor(width / 20)
        for i = 0, columns do
            local x = i * 20
            love.graphics.rectangle("fill", x, height - 48 + (i % 2) * 5, 20, 48)
        end
        love.graphics.setColor(rgb("#a8dadc"))
        love.graphics.circle("fill", width - 34, 38, 16)
        love.graphics.setColor(rgb("#f1faee"))
        love.graphics.setFont(self.fonts.title)
        love.graphics.printf(dataset.title or "DIVADELNI UTOPIE", 0, 38, width, "center")
        love.graphics.setFont(self.fonts.medium)
        love.graphics.printf(dataset.subtitle or "", 0, 68, width, "center")
        end)
    end)

    self.images.intro = make_screen_placeholder(dataset.intro, { 0.09, 0.08, 0.16 }, { 0.24, 0.17, 0.3, 1 })
    self.images.game_over = make_screen_placeholder(dataset.game_over, { 0.12, 0.02, 0.04 }, { 0.36, 0.08, 0.08, 1 })
    self.images.victory = make_screen_placeholder(dataset.victory, { 0.06, 0.12, 0.08 }, { 0.16, 0.28, 0.14, 1 })

    local guide = dataset.characters and dataset.characters.guide or {}
    local guide_frame_w = guide.frame_width or 64
    local guide_frame_h = guide.frame_height or 64
    local guide_frames = guide.frames or 4
    self.images.head = load_image_or_placeholder(guide.sprite and ("datasets/base/" .. guide.sprite), function()
        return make_canvas(guide_frame_w * guide_frames, guide_frame_h, function()
        for frame = 0, guide_frames - 1 do
            local x = frame * guide_frame_w
            love.graphics.setColor(rgb("#2b2d42"))
            love.graphics.rectangle("fill", x, 0, guide_frame_w, guide_frame_h)
            love.graphics.setColor(rgb("#ef233c"))
            love.graphics.rectangle("fill", x + 18, 16, 28, 28)
            love.graphics.setColor(rgb("#edf2f4"))
            love.graphics.rectangle("fill", x + 24 + frame % 2, 24, 6, 6)
            love.graphics.rectangle("fill", x + 34 - frame % 2, 24, 6, 6)
            love.graphics.setColor(rgb("#8d99ae"))
            love.graphics.rectangle("fill", x + 18, 48 - frame, 28, 5)
        end
        end)
    end)

    local head_sheet_w = guide_frame_w * guide_frames
    for frame = 1, guide_frames do
        self.quads[frame] = love.graphics.newQuad((frame - 1) * guide_frame_w, 0, guide_frame_w, guide_frame_h, head_sheet_w, guide_frame_h)
    end

    local faces = dataset.difficulty_faces or {}
    local configured_face_w = faces.frame_w or 64
    local configured_face_h = faces.frame_h or 64
    self.images.difficulty_faces = load_image_or_placeholder(faces.sprite and ("datasets/base/" .. faces.sprite), function()
        return make_canvas(configured_face_w * 4, configured_face_h, function()
        local colors = {
            { "#6c757d", "#f1f3f5" },
            { "#2a9d8f", "#f1faee" },
            { "#e9c46a", "#1d3557" },
            { "#e63946", "#f1faee" },
        }
        for frame = 0, 3 do
            local x = frame * configured_face_w
            local pair = colors[frame + 1]
            love.graphics.setColor(rgb(pair[1]))
            love.graphics.rectangle("fill", x, 0, configured_face_w, configured_face_h)
            love.graphics.setColor(rgb(pair[2]))
            love.graphics.rectangle("fill", x + 16, 16, 32, 32)
            love.graphics.rectangle("fill", x + 22, 24, 6, 6)
            love.graphics.rectangle("fill", x + 36, 24, 6, 6)
            love.graphics.rectangle("fill", x + 22, 42, 20, 4)
        end
        end)
    end)

    self.quads.difficulty_faces = {}
    local face_w = math.floor(self.images.difficulty_faces:getWidth() / 4)
    local face_h = self.images.difficulty_faces:getHeight()
    for frame = 1, 4 do
        self.quads.difficulty_faces[frame] = love.graphics.newQuad(
            (frame - 1) * face_w,
            0,
            face_w,
            face_h,
            self.images.difficulty_faces:getWidth(),
            self.images.difficulty_faces:getHeight()
        )
    end

    self.images.good_food = make_canvas(8, 8, function()
        love.graphics.setColor(rgb("#ffd166"))
        love.graphics.rectangle("fill", 1, 1, 6, 6)
        love.graphics.setColor(rgb("#ef476f"))
        love.graphics.rectangle("fill", 3, 0, 2, 2)
    end)

    self.images.bad_food = make_canvas(8, 8, function()
        love.graphics.setColor(rgb("#118ab2"))
        love.graphics.rectangle("fill", 1, 1, 6, 6)
        love.graphics.setColor(rgb("#073b4c"))
        love.graphics.line(1, 1, 6, 6)
        love.graphics.line(6, 1, 1, 6)
    end)

    for id, food in pairs(dataset.foods or {}) do
        self.food_icons[id] = load_image_or_placeholder(food.icon and ("datasets/base/" .. food.icon), function()
            if food.kind == "bad" or id == "bad" or id:find("bad") then
                return self.images.bad_food
            end
            return self.images.good_food
        end)
    end

    for _, level in ipairs(dataset.levels or {}) do
        local level_theme = level.theme or {}
        local bg_a = color_from_value(level_theme.play_bg, { 0.08, 0.12, 0.16, 1 })
        local bg_b = color_from_value(level_theme.play_bg_accent, { 0.12, 0.18, 0.24, 1 })
        self.level_backgrounds[level.id] = load_image_or_placeholder(level.background and ("datasets/base/" .. level.background), function()
            return make_canvas(width, height, function()
                love.graphics.clear(bg_a[1], bg_a[2], bg_a[3], 1)
                love.graphics.setColor(bg_b)
                for y = 0, math.floor(height / 20) do
                    for x = 0, math.floor(width / 20) do
                        if (x + y) % 2 == 0 then
                            love.graphics.rectangle("fill", x * 20, y * 20, 12, 12)
                        else
                            love.graphics.rectangle("fill", x * 20 + 8, y * 20 + 8, 8, 8)
                        end
                    end
                end
            end)
        end)
    end
end

function Assets:get_font(name)
    return self.fonts[name]
end

function Assets:get_image(name)
    return self.images[name]
end

function Assets:get_head_quad(frame)
    return self.quads[frame] or self.quads[1]
end

function Assets:get_head_frame_count()
    return #self.quads
end

function Assets:get_head_dimensions()
    local image = self.images.head
    local frame_count = math.max(1, self:get_head_frame_count())
    local width = image and image:getWidth() or 64
    local height = image and image:getHeight() or 64
    return width / frame_count, height
end

function Assets:get_difficulty_face(index)
    return self.images.difficulty_faces, self.quads.difficulty_faces[(index or 0) + 1] or self.quads.difficulty_faces[1]
end

function Assets:get_food_icon(food_id, fallback_kind)
    if food_id and self.food_icons[food_id] then
        return self.food_icons[food_id]
    end
    if fallback_kind == "bad" then
        return self.images.bad_food
    end
    return self.images.good_food
end

function Assets:get_level_background(level_id)
    return self.level_backgrounds[level_id]
end

function Assets:get_palette_color(value, fallback)
    return color_from_value(value, fallback)
end

return Assets
