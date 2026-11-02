--Misc functions

local utils = {}

local function getByName(target, list)
    local result = nil
    for i = 1, #list do
        if list[i].name == target then
            result = list[i]
            break
        end
    end 
    return result
end
utils.getByName = getByName

--Black magic- - - Converted from https://stackoverflow.com/questions/10134192/calculating-the-mid-point-of-a-rotated-rectangle-in-javascript
local function getMidPoint(x, y, width, height, angle_degrees) 
    angle_rad = angle_degrees * math.pi / 180;
    cosa = math.cos(angle_rad);
    sina = math.sin(angle_rad);
    wp = width/2;
    hp = height/2;
	px = ( x + wp * cosa - hp * sina )
	py = ( y + wp * sina + hp * cosa )
    return px, py
end
utils.getMidPoint = getMidPoint

local function hex2rgb(hex)
    hex = hex:gsub("#","")
    return {tonumber("0x"..hex:sub(3,4)) / 255, tonumber("0x"..hex:sub(5,6)) / 255, tonumber("0x"..hex:sub(7,8)) / 255, tonumber("0x"..hex:sub(1,2)) / 255}
end
utils.hex2rgb = hex2rgb

return utils