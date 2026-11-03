
vmath = require( 'sim.vmath' )

local globals = require( 'utils.GlobalVars' )

local decklib = require( 'utils.DeckObj' )
local handlib = require( 'utils.HandObj' )
local cardlib = require( 'utils.CardObj' )

local oppolib  = require( 'utils.OpponentAI' )
--local playerai = require( 'utils.PlayerAI' )
local playerai = require( 'utils.PlayerAI2' )
local scorelib = require( 'utils.BlackjackScoring' )


function start_of_game( gameobj )
	globals.prev_deck_scores = {}
	
	globals.player_hand = handlib.new({
		size = 6,
	})
	globals.opponent_hand = handlib.new({
		size = 6,
	})

end
function end_of_game( gameobj )
	ptotal = 0
	ototal = 0
	ptxt = ''
	otxt = ''
	for deck_num = 1,5 do
		local pscore = globals.prev_deck_scores[deck_num].player_score
		local oscore = globals.prev_deck_scores[deck_num].opponent_score
		ptxt = ptxt .. '\t'..pscore
		otxt = otxt .. '\t'..oscore
		if( pscore > oscore ) then
			ptotal = ptotal + 1
		elseif( oscore > pscore ) then
			ototal = ototal + 1
		end
	end
	local winner = 'tie'
	if( ptotal > ototal ) then
		winner = 'player'
	elseif( ototal > ptotal ) then
		winner = 'opponent'
	else
		winner = 'tie'
	end
	-- print( winner .. ' wins !!' )
	-- print( '   final totals:  '..ptotal..' to '..ototal )
	-- print( '      player=  '..ptxt )
	-- print( '      opponent='..otxt )
	return winner
end

function start_of_deck( gameobj )
	-- print( 'shuffling new deck' )
	globals.deck = decklib.new()
	globals.deck:shuffle()
	globals.player_score = 0
	globals.opponent_score = 0
end
function end_of_deck( gameobj )
	-- end of the deck ... what's next?
	table.insert( globals.prev_deck_scores, {
		player_score = globals.player_score,
		opponent_score = globals.opponent_score,
	})

	-- "encourage" the garbage collector to clean-up?
	globals.deck = {}
end

function start_of_hand( gameobj )
	-- deal out cards to both players
	for i=1,globals.player_hand.size do
		local card = globals.deck:takeTopCard()
		globals.player_hand:addCard( card )

		card = globals.deck:takeTopCard()
		globals.opponent_hand:addCard( card )
	end
end
function end_of_hand( gameobj )
	-- toss one card (to make it 13 cards per hand == exactly 4 hands per deck)
	local card = globals.deck:takeTopCard()
end

function start_of_round( gameobj )
end
function end_of_round( gameobj )
end


--  --  --  --  --  --  --  --  --  --  --  --
  --  --  --  --  --  --  --  --  --  --  --
--  --  --  --  --  --  --  --  --  --  --  --

math.randomseed( 3333*os.time() )

gameobj = {}
-- config the opponent AI
gameobj.oppoai = oppolib.new({
	hand_size = 6,
	deck_size = 52,
})
gameobj.playerai = playerai.new({
	hand_size = 6,
	deck_size = 52,
})

sim_player_total = 0
sim_opponent_total = 0
sim_tie_total = 0

for game_num = 1,10000 do
	start_of_game( gameobj )

	for deck_num = 1,5 do
		-- print( 'deck='..deck_num )
		gameobj.deck_num = deck_num
		start_of_deck(gameobj)

		for hand_num = 1,4 do
			-- print( '   hand='..hand_num )
			gameobj.hand_num = hand_num
			start_of_hand(gameobj)
			
			-- print( '      player hand:   '..globals.player_hand:tostring() )
			-- print( '      opponent hand: '..globals.opponent_hand:tostring() )

			for round_num = 1,3 do
				-- print( '      round='..round_num )
				gameobj.round_num = round_num
				start_of_round(gameobj)
				
				local p1 = gameobj.playerai:playCard( round_num )
				local p2 = gameobj.playerai:playCard( round_num )
				local o1 = gameobj.oppoai:playCard( round_num )
				local o2 = gameobj.oppoai:playCard( round_num )

				local pscore = scorelib.score( p1,p2 )
				local oscore = scorelib.score( o1,o2 )

				local winner = 'tie'
				if( round_num == 1 ) then
					if( pscore > oscore ) then
						winner = 'player'
					elseif( oscore > pscore ) then
						winner = 'opponent'
					else
						winner = 'tie'
					end
				elseif( round_num == 2 ) then
					--if( pscore > (oscore+2) ) then
					if( pscore > oscore ) then
						winner = 'player'
					elseif( oscore > pscore ) then
						winner = 'opponent'
					else
						winner = 'tie'
					end
				else
					if( pscore > (oscore+4) ) then
						winner = 'player'
					--elseif( oscore > (pscore+4) ) then
					elseif( oscore > pscore ) then
						winner = 'opponent'
					else
						winner = 'tie'
					end
				end
				if( winner == 'player' ) then
					globals.player_score = globals.player_score + 1
				elseif( winner == 'opponent' ) then
					globals.opponent_score = globals.opponent_score + 1
				end
				-- print( '         player='..p1:tostring()..','..p2:tostring()..'\t= '..pscore )
				-- print( '         opponent='..o1:tostring()..','..o2:tostring()..'\t= '..oscore )
				-- print( '        '..winner..' wins ... score='..globals.player_score..':'..globals.opponent_score )
				
				end_of_round(gameobj)
			end

			end_of_hand(gameobj)
		end

		end_of_deck(gameobj)
	end

	local winner = end_of_game(gameobj)
	if( winner == 'player' ) then
		sim_player_total = sim_player_total + 1
	elseif( winner == 'opponent' ) then
		sim_opponent_total = sim_opponent_total + 1
	else
		sim_tie_total = sim_tie_total + 1
	end
end

ntotal = sim_player_total+sim_opponent_total+sim_tie_total
print( sim_player_total, sim_opponent_total, sim_tie_total )
print( 100.0*sim_player_total/ntotal, 100*sim_opponent_total/ntotal, 100.0*sim_tie_total/ntotal )
