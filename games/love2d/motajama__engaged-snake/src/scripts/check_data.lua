local Json = require("src.util.json")

local files = {
    "datasets/base/dataset.json",
    "datasets/base/lang/en.json",
    "datasets/base/lang/cs.json",
}

local decoded = {}

local function fail(message)
    error(message, 0)
end

local function read_json(path)
    local file, open_error = io.open(path, "rb")
    if not file then
        fail(string.format("failed to open %s: %s", path, tostring(open_error)))
    end

    local content = file:read("*a")
    file:close()
    return Json.decode(content)
end

for _, path in ipairs(files) do
    decoded[path] = read_json(path)
end

local dataset = decoded["datasets/base/dataset.json"]

local function load_language(language)
    local path = string.format("datasets/base/lang/%s.json", language)
    decoded[path] = decoded[path] or read_json(path)
    return decoded[path]
end

local function require_key(language, table_data, key, context)
    if type(key) ~= "string" or key == "" then
        fail(string.format("%s has an empty localization key", context))
    end
    if table_data[key] == nil then
        fail(string.format("%s references missing %s localization key %q", context, language, key))
    end
end

local function require_food(id, expected_kind, context)
    local food = dataset.foods and dataset.foods[id]
    if not food then
        fail(string.format("%s references missing food %q", context, tostring(id)))
    end
    if food.id and food.id ~= id then
        fail(string.format("food %q has mismatched id %q", id, tostring(food.id)))
    end
    if food.kind ~= expected_kind then
        fail(string.format("%s references %s food %q declared as %q", context, expected_kind, id, tostring(food.kind)))
    end
end

if type(dataset.languages) ~= "table" or #dataset.languages == 0 then
    fail("dataset.languages must list at least one language")
end

local active_languages = {}
for _, language in ipairs(dataset.languages) do
    if active_languages[language] then
        fail(string.format("duplicate language %q", language))
    end
    active_languages[language] = load_language(language)
end

for food_id, food in pairs(dataset.foods or {}) do
    if food.id and food.id ~= food_id then
        fail(string.format("food %q has mismatched id %q", food_id, tostring(food.id)))
    end
    if food.kind ~= "good" and food.kind ~= "bad" then
        fail(string.format("food %q must declare kind \"good\" or \"bad\"", food_id))
    end
    for language, strings in pairs(active_languages) do
        require_key(language, strings, food.name_key, string.format("food %q", food_id))
        require_key(language, strings, food.description_key, string.format("food %q", food_id))
    end
end

local screen_key_fields = {
    intro = { "title_key", "body_key", "skip_key" },
    game_over = { "title_key", "body_key", "hint_key" },
    victory = { "title_key", "body_key", "hint_key" },
}

for screen, fields in pairs(screen_key_fields) do
    for _, field in ipairs(fields) do
        local key = dataset[screen] and dataset[screen][field]
        for language, strings in pairs(active_languages) do
            require_key(language, strings, key, string.format("%s.%s", screen, field))
        end
    end
end

local seen_levels = {}
for index, level in ipairs(dataset.levels or {}) do
    local context = string.format("level %d (%s)", index, tostring(level.id))
    if type(level.id) ~= "string" or level.id == "" then
        fail(string.format("level %d has an empty id", index))
    end
    if seen_levels[level.id] then
        fail(string.format("duplicate level id %q", level.id))
    end
    seen_levels[level.id] = true

    require_food(level.good_food_type, "good", context .. " good_food_type")
    require_food(level.bad_food_type, "bad", context .. " bad_food_type")

    for language, strings in pairs(active_languages) do
        require_key(language, strings, level.name_key, context)
        require_key(language, strings, level.description_key, context)
        require_key(language, strings, level.story_key, context)
        for _, quote_key in ipairs(level.hud_quotes or {}) do
            require_key(language, strings, quote_key, context)
            if not quote_key:match("^" .. level.id:gsub("([^%w])", "%%%1") .. "_quote_") then
                fail(string.format("%s has quote key %q from another level", context, quote_key))
            end
        end
    end
end
