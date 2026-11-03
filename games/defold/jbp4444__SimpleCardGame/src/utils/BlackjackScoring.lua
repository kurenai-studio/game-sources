
local M = {}

function M.score( card1, card2 )
	-- local xtra1 = card1:getXtra()
	-- local xtra2 = card2:getXtra()

	local suit1 = card1.suit
	local num1  = card1.num
	local suit2 = card2.suit
	local num2  = card2.num

	local score = 0

	if( num1 > 10 ) then
		num1 = 10
	end
	if( num2 > 10 ) then
		num2 = 10
	end
	if( (num1==1) and (num2==1) ) then
		-- two aces ... easier to just factor this out first
		score = 12
	elseif( (num1==1) or (num2==1) ) then
		-- only one ace
		if( num1 == 1 ) then
			score = 11 + num2
		else
			score = 11 + num1
		end
	else
		score = num1 + num2
	end

	return score
end

return M
