--
--   Copyright 2016-2017 John Pormann
--

local cardlib = require( 'utils.CardObj' )

local DeckObj = {}


function DeckObj.new( in_args )
	in_args = in_args or {}
	
	-- must set defaults for all available options
	local obj = {
		deck = {},
		pointer = in_args.pointer or 1,
		num_shuffles = in_args.num_shuffles or 33,
		num_gems = in_args.num_gems or 0,
	}

	--  --  --  --  --  --  --  --  --  --
	  --  --  --  --  --  --  --  --  --
	--  --  --  --  --  --  --  --  --  --

	function obj:remainingCards()
		return (#self.deck - self.pointer + 1)
	end

	function obj:addCard( card )
		table.insert( self.deck, card )
	end

	function obj:takeTopCard()
		if( self.pointer > #self.deck ) then
			return nil
		end
		local card = self.deck[self.pointer]
		--print( 'take card ... pointer='..self.pointer.. ' : '..card:tostring() )
		self.pointer = self.pointer + 1
		return card
	end

	function obj:shuffle()
		local dsize = #self.deck
		local dk = self.deck
		for i = 1, self.num_shuffles do
			for j = 1, dsize do
				local ndx = math.random(1,dsize)
				local temp = dk[ j ]
				dk[ j ] = dk[ ndx ]
				dk[ ndx ] = temp
			end
		end
	end

	function obj:shuffleAndReset()
		self:shuffle()
		self.pointer = 1
	end

	function obj:tostring()
		local txt = '{' .. self.deck[1]:tostring()
		for i = 2, #self.deck do
			txt = txt .. ',' .. self.deck[i]:tostring()
		end
		txt = txt .. '}'
		return txt
	end
	function obj:tostringNL()
		local txt = '{\n'
		for i = 1, #self.deck do
			txt = txt .. '   ' .. self.deck[i]:tostring() .. '\n'
		end
		txt = txt .. '}\n'
		return txt
	end
	function obj:show()
		print( self:tostring() )
	end

	-- BUILD THE DECK
	function obj:initDeck()
		self.deck = {}
		self.pointer = 1

		for s=1,#cardlib.cardSuits do
			for n=1,#cardlib.cardNums do
				local card = cardlib.new({
					suit = s,
					num = n,
					gem = false,
				})
				self:addCard( card )
			end
		end

		print( 'adding '..self.num_gems..' gems to deck' )
		for n=1,self.num_gems do
			local rn = math.random( 1, #self.deck )
			self.deck[rn].gem = true
			self.deck[rn]:show()
		end
	end

	-- always start with an initialized deck?
	obj:initDeck()
	-- print( "deck size = ", #obj.deck )

	return obj
end

return DeckObj
