function pow(x, y)
	return math.pow(x, y)
end

function sqrt(num)
	return math.sqrt(num)
end

function abs(num)
	return math.abs(num)
end

function clamp(min, num, max)
	return math.max(min, math.min(num, max))
end

function floor(num)
	return math.floor(num)
end

function ceil(num)
	return math.ceil(num)
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function sin(num)
	return math.sin(num)
end

function cos(num)
	return math.cos(num)
end

function tan(x)
    return math.tan(x)
end

function atan2(x, y)
	return math.atan2(y, x)
end

function random(min, max)
	return love.math.random(min, max)
end

function min(...)
	return math.min(...)
end

function max(...)
	return math.max(...)
end

function dist(x, y, xx, yy)
	return ((xx - x) ^ 2 + (yy - y) ^ 2) ^ 0.5
end

function sign(num)
	if num < 0 then
		return -1
	elseif num > 0 then
		return 1
	else
		return 0
	end
end

function boxcolliding(x, y, w, h, xx, yy, ww, hh)
    if(x < xx + ww and x + w > xx and y < yy + hh and y + h > yy) then
    	return true
	end
    return false
end
