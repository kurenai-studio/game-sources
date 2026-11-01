local colors = require "src.colors"

return {
    cellSize = 20,
    gridLineWidth = 4,

    toroidalGrid = true,

    backgroundColor = colors.background,
    gridColor = colors.grid_line,
    gridActiveColor = colors.grid_active,
    player1Color = colors.player_one,
    player2Color = colors.player_two,

    updateInterval = 0.15,

    placeKey = 1,
    pauseKey = 'space',

    useTurns = false,
    turn = 1,
    paused = true
}