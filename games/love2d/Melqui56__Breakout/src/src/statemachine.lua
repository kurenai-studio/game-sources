-- StateMachine: máquina de estados finita reutilizable.
-- Guarda el estado actual y delega en él los callbacks. Cada estado es una
-- tabla con las funciones enter/update/draw/keypressed que necesite.
local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(states)
    return setmetatable({ states = states, current = {}, currentName = "" }, StateMachine)
end

function StateMachine:switch(name, ...)
    self.current = self.states[name]
    self.currentName = name
    if self.current.enter then
        self.current.enter(...)
    end
end

function StateMachine:update(dt)
    if self.current.update then self.current.update(dt) end
end

function StateMachine:draw()
    if self.current.draw then self.current.draw() end
end

function StateMachine:keypressed(key)
    if self.current.keypressed then self.current.keypressed(key) end
end

return StateMachine
