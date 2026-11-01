function new_bonus_box()
    window_width = love.graphics.getWidth()

    local bonus_box = {
        width = 30,
        height = 30,
        dx= 0,
        dy = 70
    }

    bonus_box.x = love.math.random(0,window_width-bonus_box.width)
    bonus_box.y = -bonus_box.width

    return bonus_box
end