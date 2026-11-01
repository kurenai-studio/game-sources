
function initGraphics(scale, width, height)

    --Make a canvas to draw things to
    canvas = love.graphics.newCanvas(width, height)
    --Make sure pixels aren't blurry
    canvas:setFilter("nearest", "nearest")

    --Second canvas for another shader
    finalCanvas = love.graphics.newCanvas(width, height)
    finalCanvas:setFilter("nearest", "nearest")
    canvasPos = {x = 0, y = 0}
    canvasScale = 1

    --Make sure pixels are pixellated
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
    love.graphics.setDefaultFilter("nearest", "nearest")

    --Window things
    love.window.setMode(width * scale, height * scale)
    isFullscreen = false

    --Palette shader
    SHADER = love.graphics.newShader(
        [[
            extern vec4 palette[4];
            vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
            {
                vec4 pixel = Texel(texture,texture_coords) * color;
                vec4 colored = palette[int((pixel).r*3.99)];
                return vec4(colored.r, colored.g, colored.b, pixel.a);
            }
        ]]
    )
    SHADER:send("palette", unpack(PALETTES[1]))

    if USE_SHADER then
        --Shader applied to everything
        FINALSHADER = love.graphics.newShader("shader.frag")
        --send parameters to shader
        for i, v in ipairs(SHADER_PARAMS) do
            FINALSHADER:send(v[1], v[2])
        end
    end

    --Other things
    opacityValue = 1
    bckgColor = {0, 0, 0}

end

function startDrawing()
    love.graphics.setShader(SHADER)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(bckgColor)
    love.graphics.origin()
    love.graphics.setColor(bckgColor)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.setColor(1, 1, 1, opacityValue)
end


function endDrawing()
    love.graphics.setScissor()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader(FINALSHADER)
    love.graphics.origin()
    love.graphics.setCanvas(finalCanvas)
    love.graphics.draw(canvas,0, 0, 0, 1, 1);
    love.graphics.setCanvas()
    love.graphics.draw(finalCanvas, canvasPos.x, canvasPos.y, 0, canvasScale * SCALE, canvasScale * SCALE)
end


function makePalettes(filename)
    local data = love.image.newImageData(filename)
    local palettes = {}
	for i = 1, data:getHeight() do
        local palette = {}
		for j = 1, data:getWidth() do
			local red, green, blue, alpha = data:getPixel(j-1, i-1)
			table.insert(palette, {red, green, blue, alpha})
		end
        table.insert(palettes, palette)
	end
	return palettes
end

function makePalette(filename)
    local data = love.image.newImageData(filename)
    local palette = {}
    for i = 1, data:getHeight() do
        for j = 1, data:getWidth() do
            local red, green, blue, alpha = data:getPixel(j-1, i-1)
            table.insert(palette, {red, green, blue, alpha})
        end
    end
    return palette
end


function initSprites(spriteSheet, spriteSize)
    local quads = {}
	local sw = spriteSheet:getWidth()
	local sh = spriteSheet:getHeight()
	for i = 0, sh / spriteSize - 1 do
		for j = 0, sw / spriteSize - 1 do
			local quad = love.graphics.newQuad(j*spriteSize, i*spriteSize, spriteSize, spriteSize, sw, sh)
			table.insert(quads, quad)
		end
	end
	return quads
end


function toggleFullscreen()
    isFullscreen = not isFullscreen
    love.window.setMode(SCREEN_WIDTH * SCALE, SCREEN_HEIGHT * SCALE, {fullscreen = isFullscreen})
    if isFullscreen then
        if love.graphics.getWidth()/love.graphics.getHeight() > SCREEN_WIDTH/SCREEN_HEIGHT then
            canvasScale = love.graphics.getHeight() / (SCREEN_HEIGHT * SCALE)
            canvasPos.x = (love.graphics.getWidth()/2) - ((SCREEN_WIDTH * canvasScale * SCALE)/2)
        else
            canvasScale = love.graphics.getWidth() / (SCREEN_WIDTH * SCALE)
            canvasPos.y = (love.graphics.getHeight()/2) - ((SCREEN_HEIGHT * canvasScale * SCALE)/2)
        end
    else
        canvasPos.x = 0
        canvasPos.y = 0
        canvasScale = 1
    end
end


function camera(x, y, r, sx, sy, kx, ky)
	if x == nil and y == nil then
		if love.graphics.getStackDepth() > 0 then
			love.graphics.origin()
		end
        return
	end
	if love.graphics.getStackDepth() <= 1 then
		love.graphics.push()
	end
	love.graphics.translate(math.floor(x), math.floor(y))
    love.graphics.rotate(math.rad(r or 0))
    love.graphics.scale(sx or 1, sy or 1)
    love.graphics.shear(kx or 0, ky or 0)
end


function palette(n)
    CURRENT_PALETTE = n
    SHADER:send("palette", unpack(PALETTES[CURRENT_PALETTE]))
end

function colorSwitch(c1, c2, c3, c4)
    local p = PALETTES[CURRENT_PALETTE]
    local newColors = {p[c1], p[c2], p[c3], p[c4]}
    SHADER:send("palette", unpack(newColors))
end

function color(n)
    love.graphics.setColor(GRAYSCALE[n][1], GRAYSCALE[n][2], GRAYSCALE[n][3], opacityValue)
end

function backgroundColor(n)
    bckgColor = GRAYSCALE[n]
--    love.graphics.setBackgroundColor(GRAYSCALE[n])
end

function opacity(n)
    if n then
        opacityValue = n * 0.25
        local oldC = {love.graphics.getColor()}
        love.graphics.setColor(oldC[1], oldC[2], oldC[3], opacityValue)
    else
        opacityValue = 1
        local oldC = {love.graphics.getColor()}
        love.graphics.setColor(oldC[1], oldC[2], oldC[3], 1)
    end
end

function clip(x, y, width, height)
    love.graphics.setScissor(x, y, width, height)
end

function line(x, y, xx, yy)
    love.graphics.line(x, y, xx, yy)
end

function rect(x, y, w, h)
    love.graphics.rectangle("line", x, y, w, h)
end

function rectFill(x, y, w, h)
    love.graphics.rectangle("fill", x, y, w, h)
end

function circle(x, y, r)
    love.graphics.circle("line", x, y, r)
end

function circleFill(x, y, r)
    love.graphics.circle("fill", x, y, r)
end

function polygon(...)
    love.graphics.polygon("line", ...)
end

function polygonFill(...)
    love.graphics.polygon("fill", ...)
end

function pixel(...)
    love.graphics.points(...)
end

function print(text, x, y, r)
    love.graphics.print(text, math.floor(x), math.floor(y), math.rad(r or 0))
end

function printf(text, x, y, limit, align)
    love.graphics.printf(text, math.floor(x), math.floor(y), limit, align )
end

function sprite(n, x, y, r, flipX, flipY)
    local oldColor = {love.graphics.getColor()}
    r = r or 0
    flipX = flipX or 1
    flipY = flipY or 1
    love.graphics.setColor(1, 1, 1, opacityValue)
    love.graphics.draw(SPRITE_SHEET, QUADS[n], math.floor(x), math.floor(y), math.rad(r), flipX, flipY)
    love.graphics.setColor(oldColor)
end

function bigsprite(n, x, y, w, h)
    local limit = SPRITE_SHEET:getWidth()/SPRITE_SIZE
	for i = 0, h - 1 do
		for j = 0, w - 1 do
			local n = (n + j) + (i * limit)
			local x = x + SPRITE_SIZE * j
			local y = y + SPRITE_SIZE * i
			sprite(n, x, y)
		end
	end
end
