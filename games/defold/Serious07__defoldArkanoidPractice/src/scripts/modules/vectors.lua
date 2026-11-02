function vectorsSame(vector1, vector2)
	return vector1.x == vector2.x and vector1.y == vector2.y
end

function vectorsSameDirection(vector1, vector2)
	local v1XIsPositive = vector1.x > 0
	local v2XIsPositive = vector2.x > 0
	local v1YIsPositive = vector1.y > 0
	local v2YIsPositive = vector2.y > 0

	local xDirectionIsSame = v1XIsPositive == v2XIsPositive
	local yDirectionIsSame = v1YIsPositive == v2YIsPositive
	
	return xDirectionIsSame and yDirectionIsSame
end