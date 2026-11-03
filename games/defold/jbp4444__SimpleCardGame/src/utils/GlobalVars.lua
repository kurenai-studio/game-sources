
local M = {}

M.game_level = 1

M.deck = nil

M.player_hand = nil
M.opponent_hand = nil

M.player_score = 0
M.opponent_score = 0
M.player_gemscore = 0
M.winner = 'nobody'

M.prev_deck_scores = {}

-- rather than using msg.post( 'okButton', 'enable' or 'disable') .. which isn't query-able
-- ... we'll just move it off-screen
M.off_screen_pos = vmath.vector3( -500, 384, 0 )
M.mid_screen_pos = vmath.vector3( 512, 384, 0 )

M.card_back = 1
M.card_scale = 1

M.colors = {
	highlight1 = '#FFEEB4',  -- beige
	highlight2 = '#FBE#07',  -- yellow/gold
	green_dk = '#28471E',
	green_lt = '#579A40',
	brown_dk = '#2A1514',
	brown_lt = '#7F3415',
	red = '#A40000',
	black = '#0D0809',  -- not pure black
}

M.off_screen_pos = vmath.vector3( -500, 384, 0 )

M.input_enabled = false

return M
