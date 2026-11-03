

local globals = require( 'utils.GlobalVars' )

local decklib = require( 'utils.DeckObj' )
local handlib = require( 'utils.HandObj' )
local cardlib = require( 'utils.CardObj' )

local oppolib1 = require( 'utils.OpponentAI' )
local oppolib2 = require( 'utils.OpponentAI2' )
local oppolib3 = require( 'utils.OpponentAI3' )
local scorelib = require( 'utils.BlackjackScoring' )

local dprint = print
--local function dprint()
--end

local M = {}

-- a bit convoluted, but card-param has to be a number (not string)
-- so we pass in numeric references to card-back images (see CardObj)
M.deck_backs = { 4, 12, 7, 1, 9 }

function M.start_of_game()
	dprint( 'start of game '..globals.game_level )
	
	globals.prev_deck_scores = {}
	globals.player_gemscore = 0

	-- config the opponent AI
	if( globals.game_level == 1 ) then
		globals.oppoai = oppolib1.new({
			hand_size = 6,
			deck_size = 52,
		})
	elseif( globals.game_level == 2 ) then
		globals.oppoai = oppolib2.new({
			hand_size = 6,
			deck_size = 52,
		})
	elseif( globals.game_level == 3 ) then
		globals.oppoai = oppolib3.new({
			hand_size = 6,
			deck_size = 52,
		})
	else
		print( 'Unknown game level = '..globals.game_level )
	end

	globals.player_hand = handlib.new({
		size = 6,
	})
	globals.opponent_hand = handlib.new({
		size = 6,
	})

	-- numbers will be incremented later (to start at 1)
	globals.deck_num  = 0
	globals.hand_num  = 0
	globals.round_num = 0

	globals.player_score = 0
	globals.opponent_score = 0

	-- placeholders for selected cards
	globals.card1 = nil
	globals.card1obj = nil
	globals.card2 = nil
	globals.card2obj = nil

	globals.winner = 'nobody'

	-- now init the deck
	M.start_of_deck()
end
function M.end_of_game()
	dprint( 'end_of_game' )

	ptotal = 0
	ototal = 0
	ptxt = ''
	otxt = ''
	for deck_num = 1,#globals.prev_deck_scores do
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
	globals.winner = winner

	msg.post( '/mvc#view', 'game_over', {
		winner = winner,
		player_decks = ptotal,
		opponent_decks = ototal,
	})
	
	dprint( winner .. ' wins !!' )
	dprint( '   final totals:  '..ptotal..' to '..ototal )
	dprint( '      player=  '..ptxt )
	dprint( '      opponent='..otxt )

	-- force end to the main loop
	return true
end

function M.start_of_deck()
	globals.deck_num = globals.deck_num + 1
	-- TODO: check if deck_num > 5 ??
	dprint( 'start_of_deck', globals.deck_num )

	globals.card_back = M.deck_backs[globals.deck_num]

	-- print( 'shuffling new deck' )
	--math.randomseed( 3333*os.time() )
	globals.deck = decklib.new({num_gems=10})
	globals.deck:shuffle()
	
	msg.post( '/mvc#view', 'start_of_deck', {
		player_score = globals.player_score,
		opponent_score = globals.opponent_score,
		deck_num = globals.deck_num,
	})
	
	globals.player_score = 0
	globals.opponent_score = 0
	globals.hand_num = 0
	
	M.start_of_hand()
end
function M.end_of_deck()
	dprint( 'end_of_deck', globals.deck_num )
	local rtn = false

	-- end of the deck ... what's next?
	table.insert( globals.prev_deck_scores, {
		player_score = globals.player_score,
		opponent_score = globals.opponent_score,
	})
	
	-- "encourage" the garbage collector to clean-up?
	globals.deck = {}

	if( globals.deck_num == 5 ) then
		-- game over!
		-- TODO: should we post an end_of_deck visual first, then show end_of_game?
		rtn = M.end_of_game()
	else
		msg.post( '/mvc#view', 'end_of_deck', {
			player_score = globals.player_score,
			opponent_score = globals.opponent_score,
			deck_num = globals.deck_num,
		})
		M.start_of_deck()
	end

	return rtn
end

function M.start_of_hand()
	globals.hand_num = globals.hand_num + 1
	-- TODO: check if hand_num > 4 ??
	dprint( 'start_of_hand', globals.hand_num )

	-- deal out cards to both players
	-- : both hands should have 0 cards now
	for i=1,globals.player_hand.size do
		local card = globals.deck:takeTopCard()
		globals.player_hand:addCard( card )

		card = globals.deck:takeTopCard()
		globals.opponent_hand:addCard( card )
	end

	-- toss one card (to make it 13 cards per hand == exactly 4 hands per deck)
	local card = globals.deck:takeTopCard()

	-- create the player's card-gfx-objs
	local props = {
		parent = msg.url(),
		back = globals.card_back,
	}
	for i=1,globals.player_hand.size do
		local y = 125
		local x = 135 + (i-1)*150
		local cdata = globals.player_hand:get(i)
		props.suit = cdata.suit
		props.num  = cdata.num
		props.gem  = cdata.gem
		props.state = 1   -- show front of card
		local pos = vmath.vector3( x,y,0 )
		local cid = factory.create( 'cardFactory#factory', off_screen_pos, nil, props, globals.card_scale )
		cdata:setXtra( 'go_id', cid )
		msg.post( cid, 'deal_to_home', {pos=pos} )
		--print( 'created card at', pos )
	end

	-- now create the opponent's card-gfx-objs
	for i=1,globals.opponent_hand.size do
		local y = 625
		local x = 135 + (i-1)*150
		local cdata = globals.opponent_hand:get(i)
		props.suit = cdata.suit
		props.num  = cdata.num
		props.gem  = cdata.gem
		props.state = 0   -- show back of card
		local pos = vmath.vector3( x,y,0 )
		local cid = factory.create( 'cardFactory#factory', off_screen_pos, nil, props, globals.card_scale )
		cdata:setXtra( 'go_id', cid )
		msg.post( cid, 'deal_to_home', {pos=pos} )
		--print( 'created card at', pos )
	end

	globals.round_num = 0

	M.start_of_round()
end
function M.end_of_hand()
	dprint( 'end_of_hand', globals.hand_num )
	
	local rtn = false

	if( globals.hand_num == 4 ) then
		rtn = M.end_of_deck()
	else
		M.start_of_hand()
	end
	return rtn
end

function M.start_of_round()
	globals.round_num = globals.round_num + 1
	dprint( 'start_of_round', globals.round_num )
	-- TODO: check if > 3 ??

	globals.card1 = nil
	globals.card2 = nil
	globals.o_card1 = nil
	globals.o_card2 = nil

	msg.post( '/mvc#view', 'set_round', {deck_num=globals.deck_num, hand_num=globals.hand_num, round_num=globals.round_num } )
end
function M.end_of_round()
	dprint( 'end_of_round', globals.round_num )
	
	local rtn = false

	-- remove gfx-objs (also transitions them off-screen)
	msg.post( globals.o_card1.xtra.go_id, 'destroy' )
	msg.post( globals.o_card2.xtra.go_id, 'destroy' )
	msg.post( globals.p_card1.xtra.go_id, 'destroy' )
	msg.post( globals.p_card2.xtra.go_id, 'destroy' )

	if( globals.round_num == 3 ) then
		rtn = M.end_of_hand()
	else
		M.start_of_round()
	end

	globals.input_enabled = true
	
	return rtn
end
function M.process_round()
	dprint( 'process_round' )
	globals.input_enabled = false

	-- globals.card1/card2 are the selected cards for the player,
	-- but they are still in player's hand
	globals.player_hand:removeCard( globals.card1 )
	globals.player_hand:removeCard( globals.card2 )

	-- get opponent's cards to play
	-- : this also removes the card from the oppo hand
	local o_card1 = globals.oppoai:playCard( globals.round_num )
	local o_card2 = globals.oppoai:playCard( globals.round_num )
	local xtra1 = o_card1:getXtraAll()
	local xtra2 = o_card2:getXtraAll()

	-- move opponent's cards to play area
	msg.post( xtra1.script_url, 'to_target', {target=3} )
	msg.post( xtra1.script_url, 'flip' )
	msg.post( xtra2.script_url, 'to_target', {target=4} )
	msg.post( xtra2.script_url, 'flip' )

	local pscore = scorelib.score( globals.card1, globals.card2 )
	local oscore = scorelib.score( o_card1, o_card2 )

	-- IF the player wins, how many gems to they get?
	local add_gems = 0
	local gem1 = false
	local gem2 = false
	if( globals.card1.gem ) then
		add_gems = add_gems + 1
		gem1 = true
	end
	if( globals.card2.gem ) then
		add_gems = add_gems + 1
		gem2 = true
	end
	
	local winner = 'tie'
	if( globals.round_num == 1 ) then
		if( pscore > oscore ) then
			winner = 'player'
		elseif( oscore > pscore ) then
			winner = 'opponent'
		else
			winner = 'tie'
		end
	elseif( globals.round_num == 2 ) then
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
		elseif( oscore > (pscore+4) ) then
		--elseif( oscore > pscore ) then
			winner = 'opponent'
		else
			winner = 'tie'
		end
	end
	if( winner == 'player' ) then
		globals.player_score = globals.player_score + 1

		if( add_gems > 0 ) then
			print( 'player wins ',add_gems,' gems' )
			globals.player_gemscore = globals.player_gemscore + add_gems
			msg.post( 'mvc#view', 'gem_score', { player_gemscore = globals.player_gemscore, gem1=gem1, gem2=gem2 } )
		end

	elseif( winner == 'opponent' ) then
		globals.opponent_score = globals.opponent_score + 1
	end

	dprint( 'player ', globals.card1:tostring(), globals.card2:tostring(),
			'     oppo ', o_card1:tostring(), o_card2:tostring() )
	dprint( 'pscore=',pscore, '     oscore=',oscore )

	msg.post( '/mvc#view', 'new_score', { winner=winner, player_score=pscore, opponent_score=oscore, round_num=globals.round_num } )

	-- store the current cards being played
	globals.p_card1 = globals.card1
	globals.p_card2 = globals.card2
	globals.o_card1 = o_card1
	globals.o_card2 = o_card2

	-- "zero" out the card1/card2 vars so that the Ok button doesn't accidentally show up
	globals.card1 = nil
	globals.card2 = nil

	timer.delay( 1.0, false, M.end_of_round )

end

return M


