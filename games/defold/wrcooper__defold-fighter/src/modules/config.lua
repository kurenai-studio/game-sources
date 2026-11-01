-- Global tuning values. All distances are world units (1 sprite pixel = 3 units),
-- all times are 60 Hz simulation frames.
local M = {}

M.WIDTH = 1280
M.HEIGHT = 720
M.SCALE = 3

M.GROUND_Y = 78            -- screen y of the floor line the fighters stand on
M.STAGE_LEFT = 60          -- clamp range for fighter x
M.STAGE_RIGHT = 1220
M.START_X = { 440, 840 }

M.MAX_HEALTH = 100
M.ROUND_TIME = 99          -- seconds
M.ROUNDS_TO_WIN = 2

M.PUSH_HALF_WIDTH = 30     -- fighters can't get closer than 2x this
M.PUSH_HEIGHT = 150
M.INPUT_BUFFER = 6         -- frames a button press is remembered
M.LAND_FRAMES = 4

M.HITSTOP_LIGHT = 6
M.HITSTOP_HEAVY = 9
M.HITSTOP_BLOCK = 5

M.KNOCKDOWN_DOWN_FRAMES = 36
M.KNOCKDOWN_RISE_FRAMES = 18

return M
