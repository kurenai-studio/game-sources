-- components
local dungeoncomponent = require('components.dungeon')
local sidebarcomponent = require('components.sidebar')

local renderer = {}

local renders = {
    [dungeoncomponent.ID] = dungeoncomponent.render,
    [sidebarcomponent.ID] = sidebarcomponent.render,
}

function renderer.renders()
    for _, render in pairs(renders) do
        render()
    end
end

return renderer
