Snake = Object:extend(Object)

function Snake:new()
    local start_loc = {i=5,j=5}
    self.parts = {}
    for i=0,SNAKE_INIT_SIZE do 
        table.insert(self.parts, Rectangle(start_loc.i+i, start_loc.j))        
        grid[start_loc.i+i][start_loc.j] = 1
    end
    self.direction = "right"
end

function Snake:draw()
    love.graphics.setColor(0, 0.8, 0.0)
    for i,v in ipairs(self.parts) do
        if i == #self.parts then
            love.graphics.setColor(0.0, 0.0, 0.8)
        end
        v:draw()
    end
end

function Snake:move()
    local head = self.parts[#self.parts]
    local tail = self.parts[1]
    
    local i
    local j
    if self.direction == "right" then
        i = head.i+1
        j = head.j
    elseif self.direction == "left" then
        i = head.i-1
        j = head.j
    elseif self.direction == "up" then
        i = head.i 
        j = head.j-1
    elseif self.direction == "down" then
        i = head.i 
        j = head.j+1
    end
    
    if (i < 1 or j < 1 or i > NUM_X_TILES or j > NUM_Y_TILES) or
        (grid[i][j] == 1 and food.i ~= i and food.j ~= j) then
        game_state = "game_over"
        return 0
    end
    
    if i == food.i and j == food.j then
        table.insert(self.parts, Rectangle(i,j))        
        grid[i][j] = 1
        food = nil
        food = Food()
        tick = math.max(tick * TICK_ACC, TICK_MIN)
        score = score + 1
    else
        table.remove(self.parts, 1)
        grid[tail.i][tail.j] = 0
        table.insert(self.parts, Rectangle(i,j))        
        grid[i][j] = 1
    end
end