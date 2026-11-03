
-- AI2 - play best available card plus 1 random card

local globals = require( 'utils.GlobalVars' )

local M = {}

function M.new( in_args )
	in_args = in_args or {}

	-- must set defaults for all available options
	local obj = {
		deck_size = in_args.deck_size or -1,
		hand_size = in_args.hand_size or -1,
		random_next_card = false,
	}

	--  --  --  --  --  --  --  --  --  --
	  --  --  --  --  --  --  --  --  --  --
	--  --  --  --  --  --  --  --  --  --

	function obj:showHand()
		print( globals.opponent_hand )
	end

	function obj:playCard( rnd )
		local rcard = nil
		local myhand = globals.opponent_hand
		if( self.random_next_card == false ) then
			-- new trick ... select both cards to play
			-- : scan all pairs of cards for best option
			local best_score = -1
			local best_card = nil
			for i=1,#myhand.hand do
				local card1 = myhand:get(i)
				if( card1.num > best_score ) then
					best_score = card1.num
					best_card  = card1
				end
			end
			-- print( 'best pair='..best_pair[1]:tostring()..','..best_pair[2]:tostring() )
			-- we have the card-pair we want to play
			rcard = best_card
			myhand:removeCard( rcard )
			self.random_next_card = true
		else
			-- this time, we just pick random card
			rcard = myhand:playRandomCard()
			self.random_next_card = false
		end
		return rcard
	end
	
	return obj
end

return M
