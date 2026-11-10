TILE_H = 48
TILE_W = 48

constraints = {
    field_sz = {
        x = {
            min = 6,
            max = 32 -- might increase this later
        },
        y = {
            min = 4,
            max = 32 -- might increase this later
        }
    }
}


DIR_UP              = 0x0010
DIR_DOWN            = 0x0020
DIR_RIGHT           = 0x0040
DIR_LEFT            = 0x0080

DIRMASK             = 0x00F0

GAME_STATE_LAUNCH   = 0x0000
GAME_STATE_NEW      = 0x0001
GAME_STATE_PLAY     = 0x0002
GAME_STATE_EXIT     = 0x0003
GAME_STATE_PAUSED   = 0x0004
GAME_STATE_LOSS     = 0x0005
GAME_STATE_WIN      = 0x0006

igfont_std = love.graphics.newFont('assets/fonts/NovaSquare.ttf', 16)
igfont_fxw = love.graphics.newFont('assets/fonts/NovaMono.ttf', 16)
lgfont_std = love.graphics.newFont('assets/fonts/NovaSquare.ttf', 24)
smfont_std = love.graphics.newFont('assets/fonts/FiraSans-Regular.ttf', 12)
smfont_fxw = love.graphics.newFont('assets/fonts/FiraMono-Regular.ttf', 12)

function clamp(low, high, n) return math.min(math.max(n, low), high) end

function printf(s,...)
    return io.write(s:format(...))
end
