
-- AI3 - play best available trick at each round (scan all possible combos)

local globals = require( 'utils.GlobalVars' )

local scorelib = require( 'utils.BlackjackScoring' )

local M = {}

function M.new( in_args )
	in_args = in_args or {}

	-- must set defaults for all available options
	local obj = {
		deck_size = in_args.deck_size or -1,
		hand_size = in_args.hand_size or -1,
		next_card = nil,
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
		if( self.next_card == nil ) then
			-- new trick ... select both cards to play
			-- : scan all pairs of cards for best option
			local best_score = -1
			local best_pair = nil
			for i=1,#myhand.hand do
				local card1 = myhand:get(i)
				for j=(i+1),#myhand.hand do
					local card2 = myhand:get(j)
					local score = scorelib.score( card1, card2 )
					if( score > best_score ) then
						best_score = score
						best_pair = {card1,card2}
					end
				end
			end
			-- print( 'best pair='..best_pair[1]:tostring()..','..best_pair[2]:tostring() )
			-- we have the card-pair we want to play
			rcard = best_pair[1]
			self.next_card = best_pair[2]
			print( 'oppo card1 = '..rcard:tostring() )
		else
			-- we have a 'next_card' already selected, just play it
			rcard = self.next_card
			print( 'oppo card2 = '..rcard:tostring() )
			self.next_card = nil
		end
		myhand:removeCard( rcard )
		return rcard
	end
	
	return obj
end

return M
