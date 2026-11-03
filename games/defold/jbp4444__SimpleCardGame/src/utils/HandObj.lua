
local HandObj = {}

function HandObj.new( in_args )
	in_args = in_args or {}
	
	-- must set defaults for all available options
	local obj = {
		hand = {},
		size = in_args.size or 5,
	}

	--  --  --  --  --  --  --  --  --  --
	  --  --  --  --  --  --  --  --  --
	--  --  --  --  --  --  --  --  --  --

	function obj:addCard( card )
		local flag = false
		if( card ~= nil ) then
			if( #self.hand < self.size ) then
				table.insert( self.hand, card )
				flag = true
			end
		end
		return flag
	end

	function obj:removeCard( card )
		local idx = nil
		for i = 1,#self.hand do
			if( self.hand[i] == card ) then
				idx = i
				break
			end
		end
		if( idx ~= nil ) then
			table.remove( self.hand, idx )
		end
		return idx
	end

	function obj:get( idx )
		if( (idx<1) or (idx>#self.hand) ) then
			return nil
		end
		return self.hand[idx]
	end

	function obj:removeCardIndex( idx )
		-- TODO: check that idx is valid
		table.remove( self.hand, idx )
		return idx
	end

	function obj:tostring()
		-- TODO: check that len(hand) > 0
		local txt = '{' .. self.hand[1]:tostring()
		for i = 2,#self.hand do
			txt = txt .. ',' .. self.hand[i]:tostring()
		end
		txt = txt .. '}'
		return txt
	end
	function obj:tostringNL()
		-- TODO: check that len(hand) > 0
		local txt = '{\n'
		for i = 1,#self.hand do
			txt = txt .. '   ' .. self.hand[i]:tostring() .. '\n'
		end
		txt = txt .. '}\n'
		return txt
	end
	function obj:show()
		print( self:tostring() )
	end

	function obj:playRandomCard()
		local rn = math.random( 1, #self.hand )
		local c0 = self.hand[rn]
		self:removeCard( c0 )
		return c0
	end
	
	function obj:playFirstCard()
		local rtn = nil
		if( #self.hand > 0 ) then
			local c0 = self.hand[1]
			rtn = c0
			self:removeCard( c0 )
		end
		return rtn
	end

	function obj:scanCard( suit, num )
		local rtn = nil
		for i = 1,#self.hand do
			local card = self.hand[ i ]
			local found = true
			if( suit ~= nil ) then
				found = found and ( suit == card.suit )
			end
			if( num ~= nil ) then
				found = found and ( num == card.num )
			end
			if( found ) then
				rtn = card
				break
			end
		end
		return rtn
	end
	function obj:scanXtra( key, search_val )
		local rtn = nil
		for i = 1,#self.hand do
			local card = self.hand[ i ]
			local val = card:getXtra( key )
			if( val == search_val ) then
				rtn = card
				break
			end
		end
		return rtn
	end

	function obj:cardIterator()
		local index = 0
		local count = #self.hand

		return function()
			index = index + 1
			if( index <= count ) then
			--if( index <= #self.hand ) then
				return self.hand[index]
			end
		end
	end
	
	return obj
end

return HandObj
