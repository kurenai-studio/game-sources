
local globals = require( 'utils.GlobalVars' )

local M = {}

function M.new( in_args )
	in_args = in_args or {}

	-- must set defaults for all available options
	local obj = {
		deck_size = in_args.deck_size or -1,
		hand_size = in_args.hand_size or -1,
	}

	--  --  --  --  --  --  --  --  --  --
	  --  --  --  --  --  --  --  --  --  --
	--  --  --  --  --  --  --  --  --  --

	function obj:showHand()
		print( globals.opponent_hand )
	end

	function obj:playCard( rnd )
		-- for now, just random selection
		-- local rcard = globals.opponent_hand:playRandomCard()
		local rcard = globals.opponent_hand:playFirstCard()
		return rcard
	end
	
	return obj
end

return M
