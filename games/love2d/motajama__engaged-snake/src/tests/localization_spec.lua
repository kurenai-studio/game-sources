local Localization = require("src.core.localization")

local files = {
    ["datasets/base/lang/cs.json"] = [[{"hello":"Ahoj"}]],
}

love = {
    filesystem = {
        read = function(path)
            return files[path]
        end,
    },
}

local localization = Localization.new()
localization:load({ languages = { "cs" } })

if localization.current_language ~= "cs" then
    error("localization should select the first loaded dataset language when the default is unavailable")
end

if localization:get("hello") ~= "Ahoj" then
    error("localization should read from the selected dataset language")
end

if localization:set_language("en") then
    error("set_language should report unavailable languages")
end
