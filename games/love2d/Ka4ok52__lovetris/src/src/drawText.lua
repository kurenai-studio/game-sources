local DEFAULT_COLOR = {1, 1, 1, 1}

local function drawText(params)
    love.graphics.push("all")
    love.graphics.setColor(params.color or DEFAULT_COLOR)
    if params.font then
        love.graphics.setFont(params.font)
    end
    if params.width and params.align then
        love.graphics.printf(params.text, params.x, params.y, params.width, params.align)
    else
        love.graphics.print(params.text, params.x, params.y)
    end
    love.graphics.pop()
end

return drawText
