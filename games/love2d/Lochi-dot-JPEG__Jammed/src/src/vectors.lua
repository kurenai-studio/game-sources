-- Credit: https://love2d.org/wiki/Vectors
-- vector metatable:
Vector = {}
Vector.__index = Vector

-- vector constructor:
function Vector.new(x, y)
	local v = { x = x or 0, y = y or 0 }
	setmetatable(v, Vector)
	return v
end

-- vector addition:
function Vector.__add(a, b)
	return Vector.new(a.x + b.x, a.y + b.y)
end

-- vector subtraction:
function Vector.__sub(a, b)
	return Vector.new(a.x - b.x, a.y - b.y)
end

-- multiplication of a vector by a scalar:
function Vector.__mul(a, b)
	if type(a) == "number" then
		return Vector.new(b.x * a, b.y * a)
	elseif type(b) == "number" then
		return Vector.new(a.x * b, a.y * b)
	else
		error("Can only multiply vector by scalar.")
	end
end

-- dividing a vector by a scalar:
function Vector.__div(a, b)
	if type(b) == "number" then
		return Vector.new(a.x / b, a.y / b)
	else
		error("Invalid argument types for vector division.")
	end
end

-- vector equivalence comparison:
function Vector.__eq(a, b)
	return a.x == b.x and a.y == b.y
end

-- vector not equivalence comparison:
function Vector.__ne(a, b)
	return not Vector.__eq(a, b)
end

-- unary negation operator:
function Vector.__unm(a)
	return Vector.new(-a.x, -a.y)
end

-- vector < comparison:
function Vector.__lt(a, b)
	return a.x < b.x and a.y < b.y
end

-- vector <= comparison:
function Vector.__le(a, b)
	return a.x <= b.x and a.y <= b.y
end

-- vector value string output:
function Vector.__tostring(v)
	return "(" .. v.x .. ", " .. v.y .. ")"
end

-- lerp
function Vector.lerp(a, b, t)
	local x = a.x * (1 - t) + b.x * t
	local y = a.y * (1 - t) + b.y * t
	return Vector.new(x, y)
end

-- distancesquared
function Vector.distance_squared_to(a, b)
	local x = b.x - a.x
	local y = b.y - a.y
	return x * x + y * y
end
