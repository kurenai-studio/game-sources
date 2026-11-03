
vmath = require( 'sim.vmath' )
msg = require( 'sim.msg' )
timer = require( 'sim.timer' )

local globals = require( 'utils.GlobalVars' )

local gamelib = require( 'utils.thegame' )

--local playerai = require( 'utils.PlayerAI' )
local playerai = require( 'utils.PlayerAI2' )


--  --  --  --  --  --  --  --  --  --  --  --
--  --  --  --  --  --  --  --  --  --  --
--  --  --  --  --  --  --  --  --  --  --  --

math.randomseed( 3333*os.time() )

local playerai = playerai.new({
	hand_size = 6,
	deck_size = 52,
})

sim_player_total = 0
sim_opponent_total = 0
sim_tie_total = 0

for game_num = 1,1000 do
	gamelib.start_of_game()

	while( true ) do
		globals.card1 = playerai:playCard( round_num )
		globals.card2 = playerai:playCard( round_num )
		gamelib.process_round()

		local alldone = gamelib.end_of_round()
		if( alldone ) then
			break
		end
	end

	local winner = globals.winner
	if( winner == 'player' ) then
		sim_player_total = sim_player_total + 1
	elseif( winner == 'opponent' ) then
		sim_opponent_total = sim_opponent_total + 1
	elseif( winner == 'nobody' ) then
		print( 'warning .. winner=nobody' )
	else
		sim_tie_total = sim_tie_total + 1
	end
end

ntotal = sim_player_total+sim_opponent_total+sim_tie_total
print( sim_player_total, sim_opponent_total, sim_tie_total )
print( 100.0*sim_player_total/ntotal, 100*sim_opponent_total/ntotal, 100.0*sim_tie_total/ntotal )
