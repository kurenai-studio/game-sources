--
--   Copyright 2016-2017 John Pormann
--

local CardObj = {}

CardObj.cardBacks = {
	"cardBack_blue2",	--1
	"cardBack_blue3",
	"cardBack_blue4",
	"cardBack_blue5",
	"cardBack_red2",	--5
	"cardBack_red3",
	"cardBack_red4",
	"cardBack_red5",
	"cardBack_green2",
	"cardBack_green3",	--10
	"cardBack_green4",
	"cardBack_green5",
}

CardObj.cardSuits = {
	"Clubs",
	"Spades",
	"Diamonds",
	"Hearts",
}

CardObj.cardNums = {"A","2","3","4","5","6","7","8","9","10","J","Q","K"}

--  --  --  --  --  --  --  --  --  -- 

function CardObj.new( in_args )
	in_args = in_args or {}
	
	-- must set defaults for all available options
	local obj = {
		suit = in_args.suit or -1,
		num  = in_args.num or -1,
		gem  = in_args.gem or false,
		xtra = in_args.xtra or {},
	}

	if( obj.suit < 0 ) then
		print( '** random suit' )
		obj.suit = math.random(1,#CardObj.cardSuits)
	end
	if( obj.num < 0 ) then
		print( '** random number' )
		obj.num = math.random(1,#CardObj.cardNums)
	end

	--  --  --  --  --  --  --  --  --  --
	  --  --  --  --  --  --  --  --  --
	--  --  --  --  --  --  --  --  --  --
		
	function obj:tostring()
		-- local txt = '('
		-- for k,v in pairs(self) do
		-- 	txt = txt .. k .. '=' .. v .. ','
		-- end
		-- txt = txt:sub(1,-2) .. ')
		local gt = 'f'
		if( self.gem ) then
			gt = 't'
		end
		local txt = '(s:'..self.suit..',n:'..self.num..',g:'..gt..')'
		return txt
	end
	function obj:tostringNL()
		local txt = ''
		for k,v in pairs(self) do
			txt = txt .. k .. '=' .. v:tostring() .. '\n'
		end
		txt = txt:sub(1,-2)
		return txt
	end

	--  --  --  --  --  --  --  --  --  --  --  --  --  --  --
	  --  --  --  --  --  --  --  --  --  --  --  --  --  --
	--  --  --  --  --  --  --  --  --  --  --  --  --  --  --

	function obj:show()
		local txt = self:tostring()
		print( txt )
	end

	function obj:getValue()
		return {self.suit,self.num,self.gem}
	end

	function obj:getXtraAll()
		return self.xtra
	end
	function obj:getXtra( key )
		return self.xtra[key]
	end
	
	function obj:setXtra( key, val )
		local rtn = self.xtra[key]
		self.xtra[key] = val
		return rtn
	end
	function obj:setXtraMult( kvpairs )
		local rtn = 0
		for key,val in pairs(kvpairs) do
			self.xtra[key] = val
			rtn = rtn + 1
		end
		return rtn
	end
	function obj:delXtra( key )
		local rtn = self.xtra[key]
		self.xtra[key] = nil
		return rtn
	end
	
	--  --  --  --  --  --  --  --  --  --  --  --  --  --  --

	return obj
end

return CardObj
