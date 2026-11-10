require('common')
require('extern/class')
require('math')
require('colors')
require('math')
if not pcall(function() bit =  require('bit32') end) then
    bit = require('extern/numberlua')
end

PIECE_NONE           = 0x0001
PIECE_PIPE           = 0x0002
PIECE_SPILL          = 0x0004

PIECE_SRC            = 0x1000
PIECE_DEST           = 0x2000

PIPE_SRC             = 0x1002
PIPE_DEST            = 0x2002

PIPE_UP              = 0x0010
PIPE_DOWN            = 0x0020
PIPE_RIGHT           = 0x0040
PIPE_LEFT            = 0x0080

PIPE_STRAIGHT        = 0x0100
PIPE_ANGLE           = 0x0200
PIPE_X               = 0x0400

PIPE_HORIZONTAL      = 0x01C2
PIPE_VERTICAL        = 0x0132
PIPE_CROSS           = 0x04F2
PIPE_ANGLE_LEFTUP    = 0x0292
PIPE_ANGLE_LEFTDOWN  = 0x02A2
PIPE_ANGLE_UPRIGHT   = 0x0252
PIPE_ANGLE_DOWNRIGHT = 0x0262

pdirections = {PIPE_UP, PIPE_DOWN, PIPE_RIGHT, PIPE_LEFT}

ptypes = {PIPE_HORIZONTAL, PIPE_VERTICAL, PIPE_CROSS, PIPE_ANGLE_LEFTUP, PIPE_ANGLE_LEFTDOWN, PIPE_ANGLE_UPRIGHT, PIPE_ANGLE_DOWNRIGHT}

piece_images = {}

Piece = class()
function Piece:init(type)
    self.type = type
    self.canvas = love.graphics.newCanvas(TILE_W, TILE_H)
    self.flow = {
        flowing = {
            dir_in = 0,
            dir_out = 0
        },
        full = {
            dir_in = 0,
            dir_out = 0
        },
        counter = 16
    }
    self.spilldir = 0

    if bit.band(self.type, PIECE_SRC) ~= 0 then
        self.flow.flowing.dir_out = bit.band(self.type, DIRMASK)
        self.flow.counter = 8
    end

    self:render()
end

function Piece:render()
    love.graphics.setCanvas(self.canvas)
        love.graphics.setBackgroundColor(colors.invis)
        love.graphics.clear()
        if bit.band(self.type, bit.bor(PIECE_NONE, PIECE_SPILL)) == PIECE_NONE then
            love.graphics.setCanvas()
            return
        end

        love.graphics.clear()
        love.graphics.setLineWidth(2)

        in_ct = clamp(0, 8, 16 - self.flow.counter)/8
        out_ct = clamp(0, 8, 8 - self.flow.counter)/8


        -- Draw piece background
        if bit.band(self.type, PIECE_NONE) == 0 then
            love.graphics.setColor(colors.tile_bg)
                love.graphics.rectangle('fill', 0, 0, TILE_W, TILE_H)
            love.graphics.setColor(colors.tile_border)
                love.graphics.rectangle('line', 0, 0, TILE_W, TILE_H)
            love.graphics.setColor(colors.default)
        end

        -- Draw spill
        if bit.band(self.type, PIECE_SPILL) ~= 0 then
            in_ct = clamp(0, 7/9, in_ct)
            love.graphics.setColor(colors.pipe_water)
                if self.spilldir == 0 then
                    love.graphics.circle('fill', TILE_W/2, TILE_H/2, TILE_W*((13/16)*out_ct))
                end
                if bit.band(self.spilldir, DIR_UP) ~= 0 then
                    love.graphics.circle('fill', TILE_W/2, 0, TILE_H*out_ct)
                end
                if bit.band(self.spilldir, DIR_DOWN) ~= 0 then
                    love.graphics.circle('fill', TILE_W/2, TILE_H, TILE_H*out_ct)
                end
                if bit.band(self.spilldir, DIR_LEFT) ~= 0 then
                    love.graphics.circle('fill', 0, TILE_H/2, TILE_W*out_ct)
                end
                if bit.band(self.spilldir, DIR_RIGHT) ~= 0 then
                    love.graphics.circle('fill', TILE_W, TILE_H/2, TILE_W*out_ct)
                end
            love.graphics.setColor(colors.tile_alert)
                if self.flow.counter % 2 == 0 then
                    love.graphics.setLineWidth(4)
                        love.graphics.rectangle('line', 0, 0, TILE_W, TILE_H)
                    love.graphics.setLineWidth(2)
                end
            love.graphics.setColor(colors.default)
        end


        -- Draw "drain"
        if bit.band(self.type, PIECE_DEST) ~= 0 then
            love.graphics.draw(piece_images[PIECE_DEST])
        end

        -- Draw pipes (pt 1)
        if bit.band(self.type, PIPE_DOWN) ~= 0 then
            love.graphics.setColor(colors.pipe_inside)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.rectangle('fill', TILE_W*7/16, TILE_H*3/4, TILE_W*1/8, TILE_H*1/4)
                elseif bit.band(self.type, PIECE_PIPE) ~= 0 then
                    love.graphics.rectangle('fill', TILE_W*7/16, TILE_H*7/16, TILE_W*1/8, TILE_H*9/16)
                end
            love.graphics.setColor(colors.default)
        end

        if bit.band(self.type, PIPE_UP) ~= 0 then
            love.graphics.setColor(colors.pipe_inside)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.rectangle('fill', TILE_W*7/16, 0, TILE_W*1/8, TILE_H*1/4)
                elseif bit.band(self.type, PIECE_PIPE) ~= 0 then
                    love.graphics.rectangle('fill', TILE_W*7/16, 0, TILE_W*1/8, TILE_H*9/16)
                end
            love.graphics.setColor(colors.default)
        end

        if bit.band(self.type, PIPE_LEFT) ~= 0 then
            love.graphics.setColor(colors.pipe_inside)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.rectangle('fill', 0, TILE_H*7/16, TILE_W*1/4, TILE_H*1/8)
                elseif bit.band(self.type, PIECE_PIPE) ~= 0 then
                    love.graphics.rectangle('fill', 0, TILE_H*7/16, TILE_W*9/16, TILE_H*1/8)
                end
            love.graphics.setColor(colors.default)
        end

        if bit.band(self.type, PIPE_RIGHT) ~= 0 then
            love.graphics.setColor(colors.pipe_inside)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.rectangle('fill', TILE_W*3/4, TILE_H*7/16, TILE_W*1/4, TILE_H*1/8)
                elseif bit.band(self.type, PIECE_PIPE) ~= 0 then
                    love.graphics.rectangle('fill', TILE_W*7/16, TILE_H*7/16, TILE_W*9/16, TILE_H*1/8)
                end
            love.graphics.setColor(colors.default)
        end

        -- Draw flowed water
        if bit.band(bit.bor(self.flow.full.dir_in, self.flow.full.dir_out), PIPE_DOWN) ~= 0 then
            love.graphics.setColor(colors.pipe_water)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.rectangle('fill', TILE_W*7/16, TILE_H*11/16, TILE_W*1/8, TILE_H*5/16)
                else
                    love.graphics.rectangle('fill', TILE_W*7/16, TILE_H*7/16, TILE_W*1/8, TILE_H*9/16)
                end
            love.graphics.setColor(colors.default)
        end

        if bit.band(bit.bor(self.flow.full.dir_in, self.flow.full.dir_out), PIPE_UP) ~= 0 then
            love.graphics.setColor(colors.pipe_water)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.rectangle('fill', TILE_W*7/16, 0, TILE_W*1/8, TILE_H*5/16)
                else
                    love.graphics.rectangle('fill', TILE_W*7/16, 0, TILE_W*1/8, TILE_H*9/16)
                end
            love.graphics.setColor(colors.default)
        end

        if bit.band(bit.bor(self.flow.full.dir_in, self.flow.full.dir_out), PIPE_LEFT) ~= 0 then
            love.graphics.setColor(colors.pipe_water)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.rectangle('fill', 0, TILE_H*7/16, TILE_W*5/16, TILE_H*1/8)
                else
                    love.graphics.rectangle('fill', 0, TILE_H*7/16, TILE_W*9/16, TILE_H*1/8)
                end
            love.graphics.setColor(colors.default)
        end

        if bit.band(bit.bor(self.flow.full.dir_in, self.flow.full.dir_out), PIPE_RIGHT) ~= 0 then
            love.graphics.setColor(colors.pipe_water)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.rectangle('fill', TILE_W*11/16, TILE_H*7/16, TILE_W*5/16, TILE_H*1/8)
                else
                    love.graphics.rectangle('fill', TILE_W*7/16, TILE_H*7/16, TILE_W*9/16, TILE_H*1/8)
                end
            love.graphics.setColor(colors.default)
        end

        -- Draw flowing water
        if bit.band(self.flow.flowing.dir_in, PIPE_DOWN) ~= 0 then
            love.graphics.setColor(colors.pipe_water)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.rectangle('fill', TILE_W*7/16, TILE_H*((11/16)+((5/16)*(1-in_ct))), TILE_W*1/8, (TILE_H*5/16)*in_ct)
                else
                    love.graphics.rectangle('fill', TILE_W*7/16, TILE_H*((7/16)+((9/16)*(1-in_ct))), TILE_W*1/8, (TILE_H*9/16)*in_ct)
                end
            love.graphics.setColor(colors.default)
        elseif bit.band(self.flow.flowing.dir_out, PIPE_DOWN) ~= 0 then
            love.graphics.setColor(colors.pipe_water)
                love.graphics.rectangle('fill', TILE_W*7/16, TILE_H*7/16, TILE_W*1/8, (TILE_H*9/16)*out_ct)
            love.graphics.setColor(colors.default)
        end

        if bit.band(self.flow.flowing.dir_in, PIPE_UP) ~= 0 then
            love.graphics.setColor(colors.pipe_water)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.rectangle('fill', TILE_W*7/16, 0, TILE_W*1/8, (TILE_H*5/16)*in_ct)
                else
                    love.graphics.rectangle('fill', TILE_W*7/16, 0, TILE_W*1/8, (TILE_H*9/16)*in_ct)
                end
            love.graphics.setColor(colors.default)
        elseif bit.band(self.flow.flowing.dir_out, PIPE_UP) ~= 0 then
            love.graphics.setColor(colors.pipe_water)
                love.graphics.rectangle('fill', TILE_W*7/16, TILE_H*((7/16)+((-9/16)*out_ct)), TILE_W*1/8, (TILE_H*9/16)*out_ct)
            love.graphics.setColor(colors.default)
        end

        if bit.band(self.flow.flowing.dir_in, PIPE_LEFT) ~= 0 then
            love.graphics.setColor(colors.pipe_water)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.rectangle('fill', 0, TILE_H*7/16, (TILE_H*5/16)*in_ct, TILE_H*1/8)
                else
                    love.graphics.rectangle('fill', 0, TILE_H*7/16, (TILE_W*9/16)*in_ct, TILE_H*1/8)
                end
            love.graphics.setColor(colors.default)
        elseif bit.band(self.flow.flowing.dir_out, PIPE_LEFT) ~= 0 then
            love.graphics.setColor(colors.pipe_water)
                love.graphics.rectangle('fill', TILE_W*((7/16)+((-9/16)*out_ct)), TILE_H*7/16, (TILE_W*9/16)*out_ct, TILE_H*1/8)
            love.graphics.setColor(colors.default)
        end

        if bit.band(self.flow.flowing.dir_in, PIPE_RIGHT) ~= 0 then
            love.graphics.setColor(colors.pipe_water)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.rectangle('fill', TILE_W*((11/16)+((5/16)*(1-in_ct))), TILE_H*7/16, (TILE_W*5/16)*in_ct, TILE_H*1/8)
                else
                    love.graphics.rectangle('fill', TILE_W*((7/16)+((9/16)*(1-in_ct))), TILE_H*7/16, (TILE_W*9/16)*in_ct, TILE_H*1/8)
                end
            love.graphics.setColor(colors.default)
        elseif bit.band(self.flow.flowing.dir_out, PIPE_RIGHT) ~= 0 then
            love.graphics.setColor(colors.pipe_water)
                love.graphics.rectangle('fill', TILE_W*7/16, TILE_H*7/16, (TILE_W*9/16)*out_ct, TILE_H*1/8)
            love.graphics.setColor(colors.default)
        end

        -- Draw pipes (pt 2)
        love.graphics.setLineWidth(2)
        if bit.band(self.type, PIPE_DOWN) ~= 0 then
            love.graphics.setColor(colors.pipe_outside)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.line(TILE_W*7/16, TILE_H*3/4, TILE_W*7/16, TILE_H)
                    love.graphics.line(TILE_W*9/16, TILE_H*3/4, TILE_W*9/16, TILE_H)
                elseif bit.band(self.type, PIECE_PIPE) ~= 0 then
                    love.graphics.line(TILE_W*7/16, TILE_H*9/16, TILE_W*7/16, TILE_H)
                    love.graphics.line(TILE_W*9/16, TILE_H*9/16, TILE_W*9/16, TILE_H)
                end
            love.graphics.setColor(colors.default)
        end

        if bit.band(self.type, PIPE_UP) ~= 0 then
            love.graphics.setColor(colors.pipe_outside)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.line(TILE_W*7/16, 0, TILE_W*7/16, TILE_H*1/4)
                    love.graphics.line(TILE_W*9/16, 0, TILE_W*9/16, TILE_H*1/4)
                elseif bit.band(self.type, PIECE_PIPE) ~= 0 then
                    love.graphics.line(TILE_W*7/16, 0, TILE_W*7/16, TILE_H*7/16)
                    love.graphics.line(TILE_W*9/16, 0, TILE_W*9/16, TILE_H*7/16)
                end
            love.graphics.setColor(colors.default)
        end

        if bit.band(self.type, PIPE_LEFT) ~= 0 then
            love.graphics.setColor(colors.pipe_outside)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.line(0, TILE_H*7/16, TILE_W*1/4, TILE_H*7/16)
                    love.graphics.line(0, TILE_H*9/16, TILE_W*1/4, TILE_H*9/16)
                elseif bit.band(self.type, PIECE_PIPE) ~= 0 then
                    love.graphics.line(0, TILE_H*7/16, TILE_W*7/16, TILE_H*7/16)
                    love.graphics.line(0, TILE_H*9/16, TILE_W*7/16, TILE_H*9/16)
                end
            love.graphics.setColor(colors.default)
        end

        if bit.band(self.type, PIPE_RIGHT) ~= 0 then
            love.graphics.setColor(colors.pipe_outside)
                if bit.band(self.type, PIECE_DEST) ~= 0 then
                    love.graphics.line(TILE_W*3/4, TILE_H*7/16, TILE_W, TILE_H*7/16)
                    love.graphics.line(TILE_W*3/4, TILE_H*9/16, TILE_W, TILE_H*9/16)
                elseif bit.band(self.type, PIECE_PIPE) ~= 0 then
                    love.graphics.line(TILE_W*9/16, TILE_H*7/16, TILE_W, TILE_H*7/16)
                    love.graphics.line(TILE_W*9/16, TILE_H*9/16, TILE_W, TILE_H*9/16)
                end
            love.graphics.setColor(colors.default)
        end

        if bit.band(self.type, PIECE_PIPE) ~= 0 then
            if bit.band(self.type, bit.bor(PIPE_DOWN, PIPE_UP)) ~= 0 then
                love.graphics.setColor(colors.pipe_outside)
                    if bit.band(self.type, PIPE_LEFT) == 0 then
                        love.graphics.line(TILE_W*7/16, TILE_H*9/16, TILE_W*7/16, TILE_H*7/16)
                    end
                    if bit.band(self.type, PIPE_RIGHT) == 0 then
                        love.graphics.line(TILE_W*9/16, TILE_H*9/16, TILE_W*9/16, TILE_H*7/16)
                    end
                love.graphics.setColor(colors.default)
            end

            if bit.band(self.type, bit.bor(PIPE_LEFT, PIPE_RIGHT)) ~= 0 then
                love.graphics.setColor(colors.pipe_outside)
                    if bit.band(self.type, PIPE_UP) == 0 then
                        love.graphics.line(TILE_W*9/16, TILE_H*7/16, TILE_W*7/16, TILE_H*7/16)
                    end
                    if bit.band(self.type, PIPE_DOWN) == 0 then
                        love.graphics.line(TILE_W*9/16, TILE_H*9/16, TILE_W*7/16, TILE_H*9/16)
                    end
                love.graphics.setColor(colors.default)
            end

        end

        -- Draw "faucet"
        if bit.band(self.type, PIECE_SRC) ~= 0 then
            love.graphics.draw(piece_images[PIECE_SRC])
        end

    love.graphics.setCanvas()
end

-- I *think* as long as we only have a single source piece, flows can only meet
-- *in* tiles and not at tile borders.
function Piece:drip(direction)

    direction = direction or false

    if direction ~= false and bit.band(direction, PIECE_SPILL) ~= 0 then
        self.type = bit.bor(self.type, PIECE_SPILL)
        self.flow.counter = 8
        self.spilldir = bit.bor(self.spilldir, bit.band(DIRMASK, direction))
        return 0
    elseif direction ~= false then

        self.flow.flowing.dir_in = bit.bor(self.flow.flowing.dir_in, direction)

        if (bit.band(self.type, PIECE_NONE) ~= 0) then
            -- Create spill if piece is empty
            self.type = bit.bor(self.type, PIECE_SPILL)
        elseif (bit.band(self.type, PIECE_SRC) ~= 0) then
            -- Create spill if piece is source
            self.type = bit.bor(self.type, PIECE_SPILL)
        elseif (bit.band(self.type, direction) == 0) then
            -- Create spill if no pipe to receive flow
            self.type = bit.bor(self.type, PIECE_SPILL)
        end


        if (bit.band(self.type, bit.bor(PIECE_DEST, PIECE_SPILL)) == 0) then
            if self.flow.flowing.dir_in ~= direction then
                -- If we have multiple flows going into the same tile,
                -- use all available outputs
                self.flow.flowing.dir_out = bit.band(bit.band(DIRMASK, bit.bnot(bit.bor(self.flow.flowing.dir_in, bit.bor(self.flow.full.dir_in, self.flow.full.dir_out)))), self.type)
            elseif (bit.band(self.type, PIPE_X) == 0) then
                self.flow.flowing.dir_out = bit.band(bit.band(DIRMASK, bit.bnot(bit.bor(self.flow.flowing.dir_in, bit.bor(self.flow.full.dir_in, self.flow.full.dir_out)))), self.type)
            elseif direction == DIR_UP then
                self.flow.flowing.dir_out = bit.bor(self.flow.flowing.dir_out, DIR_DOWN)
            elseif direction == DIR_DOWN then
                self.flow.flowing.dir_out = bit.bor(self.flow.flowing.dir_out, DIR_UP)
            elseif direction == DIR_LEFT then
                self.flow.flowing.dir_out = bit.bor(self.flow.flowing.dir_out, DIR_RIGHT)
            elseif direction == DIR_RIGHT then
                self.flow.flowing.dir_out = bit.bor(self.flow.flowing.dir_out, DIR_LEFT)
            end
        end

        return 0

    elseif self.flow.counter == 0 then
        if bit.band(self.type, PIECE_SPILL) ~= 0 then
            return PIECE_SPILL
        end

        self.flow.counter = 16

        ret = self.flow.flowing.dir_out

        self.flow.full.dir_out = bit.bor(self.flow.flowing.dir_out, self.flow.full.dir_out)
        self.flow.flowing.dir_out = 0

        self.flow.full.dir_in = bit.bor(self.flow.flowing.dir_in, self.flow.full.dir_in)
        self.flow.flowing.dir_in = 0

        if bit.band(self.type, PIECE_DEST) ~= 0 then
            return PIECE_DEST
        end

        if self.flow.full.dir_in == bit.band(DIRMASK, self.type) then
            self.flow.counter = 8
            return PIPE_X
        end

        if ret == 0 then
            self.flow.counter = 8
            return PIECE_SRC
        end

        -- print(ret)
        return ret
    elseif self.flow.counter == 8 and self.flow.flowing.dir_out == 0 then
        if bit.band(self.type, bit.bor(PIECE_SPILL, PIECE_SRC)) == 0 then
            self.flow.counter = 0
        else
            self.flow.counter = self.flow.counter - 1
        end
        self:render()
        return 0
    else
        self.flow.counter = self.flow.counter - 1
        self:render()
        return 0
    end

end

function gen_piece_images()

    piece_images[PIECE_DEST] = love.graphics.newCanvas(TILE_W, TILE_H)
    love.graphics.setCanvas(piece_images[PIECE_DEST])
        love.graphics.clear()
        love.graphics.setLineWidth(2)
        love.graphics.setColor(colors.drain_bg)
            love.graphics.rectangle('fill', TILE_W/5, TILE_H/5, TILE_W*3/5, TILE_H*3/5)
        love.graphics.setColor(colors.drain_lines)
            love.graphics.rectangle('line', TILE_W/5, TILE_H/5, TILE_W*3/5, TILE_H*3/5)
        love.graphics.setColor(colors.drain_holes)
            love.graphics.setBlendMode('replace')
                love.graphics.rectangle('fill', TILE_W*06/20, TILE_H*06/20, TILE_W*3/20, TILE_H*3/20)
                love.graphics.rectangle('fill', TILE_W*11/20, TILE_H*06/20, TILE_W*3/20, TILE_H*3/20)
                love.graphics.rectangle('fill', TILE_W*11/20, TILE_H*11/20, TILE_W*3/20, TILE_H*3/20)
                love.graphics.rectangle('fill', TILE_W*06/20, TILE_H*11/20, TILE_W*3/20, TILE_H*3/20)
            love.graphics.setBlendMode('alpha')
        love.graphics.setColor(colors.drain_lines)
            love.graphics.rectangle('line', TILE_W*06/20, TILE_H*06/20, TILE_W*3/20, TILE_H*3/20)
            love.graphics.rectangle('line', TILE_W*11/20, TILE_H*06/20, TILE_W*3/20, TILE_H*3/20)
            love.graphics.rectangle('line', TILE_W*11/20, TILE_H*11/20, TILE_W*3/20, TILE_H*3/20)
            love.graphics.rectangle('line', TILE_W*06/20, TILE_H*11/20, TILE_W*3/20, TILE_H*3/20)
        love.graphics.setColor(colors.default)
    love.graphics.setCanvas()

    piece_images[PIECE_SRC] = love.graphics.newCanvas(TILE_W, TILE_H)
    src_canvas_temp1 = love.graphics.newCanvas(TILE_W, TILE_H)

    love.graphics.setCanvas({src_canvas_temp1, stencil=true})
        inner_scale = 3/4
        love.graphics.clear()
        love.graphics.setLineWidth(2)

        love.graphics.stencil((function() love.graphics.circle('fill', TILE_W/2, TILE_H/2, (TILE_W*9/32)*inner_scale) end), 'replace', 1, false)

        love.graphics.setColor(colors.invis)
            love.graphics.circle('fill', TILE_W/2, TILE_H/2, (TILE_W*9/32)*inner_scale)
        love.graphics.setColor(colors.faucet_lines)
            love.graphics.circle('line', TILE_W/2, TILE_H/2, (TILE_W*9/32)*inner_scale)
        love.graphics.setColor(colors.default)

        distance = (TILE_W*11/32)*inner_scale
        size = (TILE_W*1/10)*inner_scale

        love.graphics.setColor(colors.invis)
            love.graphics.setBlendMode('replace')
                love.graphics.circle('fill', TILE_W/2, (TILE_H/2)-distance, size)
                love.graphics.circle('fill', TILE_W/2, (TILE_H/2)+distance, size)
                love.graphics.circle('fill', (TILE_W/2)-distance, TILE_H/2, size)
                love.graphics.circle('fill', (TILE_W/2)+distance, TILE_H/2, size)
                love.graphics.circle('fill', (TILE_W/2)-(distance/math.sqrt(2)), (TILE_H/2)-(distance/math.sqrt(2)), size)
                love.graphics.circle('fill', (TILE_W/2)+(distance/math.sqrt(2)), (TILE_H/2)-(distance/math.sqrt(2)), size)
                love.graphics.circle('fill', (TILE_W/2)-(distance/math.sqrt(2)), (TILE_H/2)+(distance/math.sqrt(2)), size)
                love.graphics.circle('fill', (TILE_W/2)+(distance/math.sqrt(2)), (TILE_H/2)+(distance/math.sqrt(2)), size)
            love.graphics.setBlendMode('alpha')
        love.graphics.setColor(colors.default)
        love.graphics.setStencilTest('equal', 1)
            love.graphics.setColor(colors.faucet_lines)
                love.graphics.circle('line', TILE_W/2, (TILE_H/2)-distance, size)
                love.graphics.circle('line', TILE_W/2, (TILE_H/2)+distance, size)
                love.graphics.circle('line', (TILE_W/2)-distance, TILE_H/2, size)
                love.graphics.circle('line', (TILE_W/2)+distance, TILE_H/2, size)
                love.graphics.circle('line', (TILE_W/2)-(distance/math.sqrt(2)), (TILE_H/2)-(distance/math.sqrt(2)), size)
                love.graphics.circle('line', (TILE_W/2)+(distance/math.sqrt(2)), (TILE_H/2)-(distance/math.sqrt(2)), size)
                love.graphics.circle('line', (TILE_W/2)-(distance/math.sqrt(2)), (TILE_H/2)+(distance/math.sqrt(2)), size)
                love.graphics.circle('line', (TILE_W/2)+(distance/math.sqrt(2)), (TILE_H/2)+(distance/math.sqrt(2)), size)
            love.graphics.setColor(colors.default)
        love.graphics.setStencilTest()

        sp8 = math.sin(math.pi/8)*(TILE_W*9/32)*inner_scale
        cp8 = math.cos(math.pi/8)*(TILE_W*9/32)*inner_scale

        love.graphics.setColor(colors.faucet_lines)
            love.graphics.line(TILE_W/2, TILE_H/2, (TILE_W/2)-cp8, (TILE_H/2)-sp8)
            love.graphics.line(TILE_W/2, TILE_H/2, (TILE_W/2)-cp8, (TILE_H/2)+sp8)
            love.graphics.line(TILE_W/2, TILE_H/2, (TILE_W/2)+cp8, (TILE_H/2)-sp8)
            love.graphics.line(TILE_W/2, TILE_H/2, (TILE_W/2)+cp8, (TILE_H/2)+sp8)
            love.graphics.line(TILE_W/2, TILE_H/2, (TILE_W/2)-sp8, (TILE_H/2)-cp8)
            love.graphics.line(TILE_W/2, TILE_H/2, (TILE_W/2)-sp8, (TILE_H/2)+cp8)
            love.graphics.line(TILE_W/2, TILE_H/2, (TILE_W/2)+sp8, (TILE_H/2)-cp8)
            love.graphics.line(TILE_W/2, TILE_H/2, (TILE_W/2)+sp8, (TILE_H/2)+cp8)
        love.graphics.setColor(colors.default)


    love.graphics.setCanvas({piece_images[PIECE_SRC], stencil=true})
        outer_scale = 7/6
        love.graphics.clear()
        love.graphics.setLineWidth(2)

        love.graphics.stencil((function() love.graphics.circle('fill', TILE_W/2, TILE_H/2, (TILE_W*9/32)*outer_scale) end), 'replace', 1, false)

        love.graphics.setColor(colors.faucet_fg)
            love.graphics.circle('fill', TILE_W/2, TILE_H/2, (TILE_W*9/32)*outer_scale)
        love.graphics.setColor(colors.faucet_lines)
            love.graphics.circle('line', TILE_W/2, TILE_H/2, (TILE_W*9/32)*outer_scale)
        love.graphics.setColor(colors.default)

        distance = (TILE_W*11/32)*outer_scale
        size = (TILE_W*1/10)*outer_scale

        love.graphics.setColor(colors.invis)
            love.graphics.setBlendMode('replace')
                love.graphics.circle('fill', TILE_W/2, (TILE_H/2)-distance, size)
                love.graphics.circle('fill', TILE_W/2, (TILE_H/2)+distance, size)
                love.graphics.circle('fill', (TILE_W/2)-distance, TILE_H/2, size)
                love.graphics.circle('fill', (TILE_W/2)+distance, TILE_H/2, size)
                love.graphics.circle('fill', (TILE_W/2)-(distance/math.sqrt(2)), (TILE_H/2)-(distance/math.sqrt(2)), size)
                love.graphics.circle('fill', (TILE_W/2)+(distance/math.sqrt(2)), (TILE_H/2)-(distance/math.sqrt(2)), size)
                love.graphics.circle('fill', (TILE_W/2)-(distance/math.sqrt(2)), (TILE_H/2)+(distance/math.sqrt(2)), size)
                love.graphics.circle('fill', (TILE_W/2)+(distance/math.sqrt(2)), (TILE_H/2)+(distance/math.sqrt(2)), size)
            love.graphics.setBlendMode('alpha')
        love.graphics.setColor(colors.default)
        love.graphics.setStencilTest('equal', 1)
            love.graphics.setColor(colors.faucet_lines)
                love.graphics.circle('line', TILE_W/2, (TILE_H/2)-distance, size)
                love.graphics.circle('line', TILE_W/2, (TILE_H/2)+distance, size)
                love.graphics.circle('line', (TILE_W/2)-distance, TILE_H/2, size)
                love.graphics.circle('line', (TILE_W/2)+distance, TILE_H/2, size)
                love.graphics.circle('line', (TILE_W/2)-(distance/math.sqrt(2)), (TILE_H/2)-(distance/math.sqrt(2)), size)
                love.graphics.circle('line', (TILE_W/2)+(distance/math.sqrt(2)), (TILE_H/2)-(distance/math.sqrt(2)), size)
                love.graphics.circle('line', (TILE_W/2)-(distance/math.sqrt(2)), (TILE_H/2)+(distance/math.sqrt(2)), size)
                love.graphics.circle('line', (TILE_W/2)+(distance/math.sqrt(2)), (TILE_H/2)+(distance/math.sqrt(2)), size)
            love.graphics.setColor(colors.default)
        love.graphics.setStencilTest()

        love.graphics.setBlendMode('replace')
            love.graphics.stencil((function() love.graphics.circle('fill', TILE_W/2, TILE_H/2, (TILE_W*9/32)*inner_scale) end), 'replace', 1, false)
            love.graphics.setStencilTest('equal', 1)
                love.graphics.draw(src_canvas_temp1)
            love.graphics.setStencilTest()
        love.graphics.setBlendMode('alpha')

        love.graphics.setLineWidth(1.6)
        love.graphics.setColor(colors.faucet_fg)
            love.graphics.circle('fill', TILE_W/2, TILE_H/2, TILE_W*5/64)
        love.graphics.setColor(colors.faucet_lines)
            love.graphics.circle('line', TILE_W/2, TILE_H/2, TILE_W*5/64)
        love.graphics.setColor(colors.default)

    love.graphics.setCanvas()

end

function get_random_pipe()
    return Piece(ptypes[math.random(1, table.getn(ptypes))])
end

