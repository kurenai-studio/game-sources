local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(game)
    return setmetatable({
        game = game,
        current = nil,
        current_name = nil,
    }, StateMachine)
end

function StateMachine:change(name, params)
    if self.current and self.current.leave then
        self.current:leave()
    end

    local factory = assert(self.game.state_factories[name], "unknown state: " .. tostring(name))
    self.current = factory(self.game)
    self.current_name = name

    if self.current.enter then
        self.current:enter(params or {})
    end
end

function StateMachine:update(dt)
    if self.current and self.current.update then
        self.current:update(dt)
    end
end

function StateMachine:draw()
    if self.current and self.current.draw then
        self.current:draw()
    end
end

return StateMachine
