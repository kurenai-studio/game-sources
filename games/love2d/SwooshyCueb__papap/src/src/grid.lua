require('common')
require('extern/class')
require('piece')
require('colors')
if not pcall(function() bit =  require('bit32') end) then
    bit = require('extern/numberlua')
end

Grid = class()
function Grid:init(sz_x, sz_y)
    self.sz = {x = sz_x, y = sz_y}
    self.selected = {x = 0, y = 0}
    self.map = {}
    for xpos = 0, self.sz.x-1 do
        self.map[xpos] = {}
        for ypos = 0, self.sz.y-1 do
            self.map[xpos][ypos] = Piece(PIECE_NONE)
        end
    end

    self.basecanvas = love.graphics.newCanvas((self.sz.x*TILE_W)+16, (self.sz.y*TILE_H)+16)
    self.pipecanvas = love.graphics.newCanvas((self.sz.x*TILE_W)+16, (self.sz.y*TILE_H)+16)
    self.canvas = love.graphics.newCanvas((self.sz.x*TILE_W)+16, (self.sz.y*TILE_H)+16)
    self:render()

end

function Grid:select(x, y)
    self.selected.x = x
    self.selected.y = y
    self:renderstg3()
end

function Grid:set(x, y, piece)
    self.map[x-1][y-1] = piece
    self:renderstg2()
    self:renderstg3()
end

function Grid:drip(x, y, dir)
    --[[
    printf("%02u, %02u", x, y)
    if dir ~= nil then
        printf(", 0x%08x: ", dir)
    else
        printf(", ----------: ")
    end
    --]]
    local dr = self.map[x-1][y-1]:drip(dir)
    --printf("0x%08x\n", dr)
    self:renderstg2()
    self:renderstg3()
    return dr
end

function Grid:get(x, y)
    return self.map[x-1][y-1]
end

function Grid:renderstg1()
    love.graphics.setCanvas({self.basecanvas, stencil=true})
        love.graphics.setBackgroundColor(colors.invis)
        love.graphics.clear()

        love.graphics.stencil((function()
            love.graphics.setLineWidth(1)
            for xpos = 0, self.sz.x-1 do
                for ypos = 0, self.sz.y-1 do
                    love.graphics.rectangle('line', (xpos*TILE_W)+8, (ypos*TILE_H)+8, TILE_W, TILE_H)
                end
            end
            love.graphics.setLineWidth(2)
            love.graphics.rectangle('line', 8, 8, TILE_W*self.sz.x, TILE_H*self.sz.y)
        end), 'replace', 1, false)

        love.graphics.setColor(colors.grid_bg)
            love.graphics.setStencilTest("equal", 0)
                love.graphics.rectangle('fill', 8, 8, (self.sz.x*TILE_W), (self.sz.y*TILE_H))
            love.graphics.setStencilTest()
        love.graphics.setColor(colors.gridlines)
            love.graphics.setStencilTest("equal", 1)
                love.graphics.rectangle('fill', 0, 0, (self.sz.x*TILE_W)+16, (self.sz.y*TILE_H)+16)
            love.graphics.setStencilTest()
        love.graphics.setColor(colors.default)
    love.graphics.setCanvas()
end

function Grid:renderstg2()
    love.graphics.setCanvas(self.pipecanvas)
        love.graphics.setBackgroundColor(colors.invis)
        love.graphics.clear()
        love.graphics.draw(self.basecanvas)
        for xpos = 0, self.sz.x-1 do
            for ypos = 0, self.sz.y-1 do
                love.graphics.draw(self.map[xpos][ypos].canvas, (xpos*TILE_W)+8, (ypos*TILE_H)+8)
            end
        end
    love.graphics.setCanvas()
end

function Grid:renderstg3()
    love.graphics.setCanvas(self.canvas)
        love.graphics.setBackgroundColor(colors.invis)
        love.graphics.clear()
        love.graphics.draw(self.pipecanvas)
        if (self.selected.x*self.selected.y) ~= 0 then
            love.graphics.setLineWidth(2)
                love.graphics.setColor(colors.grid_sel)
                love.graphics.setBlendMode('add')
                    love.graphics.rectangle('line', ((self.selected.x-1)*TILE_W)+8, ((self.selected.y-1)*TILE_H)+8, TILE_W, TILE_H)
                love.graphics.setBlendMode('alpha')
            love.graphics.setColor(colors.default)
        end
    love.graphics.setCanvas()
end

function Grid:render()
    self:renderstg1()
    self:renderstg2()
    self:renderstg3()
end
