---
-- Config is responsible for loading and saving game data.
--
-- classmod: Config

Object = require "classic"
local Config = Object:extend()


local FILENAME = "save.lua"
local DEFAULT = {
	version = 1;

	music = 50;
	sound = 100;

	language = 1;

	msaa = 0;
	bloom = 3;
	scanlines = false;
	crt = 0;
	pixel = 1;

	ship = 1;
	gamemode = 1;
}


function Config:new()
	self.values = DEFAULT
	self:load()
end


--- Save game.
function Config:save()
	res = ''
	self:_serialize(self.values)
	success, err = love.filesystem.write(
		FILENAME, res
	)
	if not success then
		print(err)
	end
end


--- Load game or fallback to default config.
function Config:load()
	local savedir = love.filesystem.getSaveDirectory()
	local path = savedir .. "/" ..  FILENAME
	local info = love.filesystem.getInfo(FILENAME)
	if not info then
		return
	end
	local str, err = love.filesystem.read(FILENAME)
	if not str then
		print(err)
		return
	end

	self.values = self:_deserialize(str)
	for k, v in pairs(DEFAULT) do
		if self.values[k] == nil then
			self.values[k] = v
		end
	end
end


function Config:_deserialize(str)
	return assert((loadstring or load)("return " .. str))()
end


function Config:_serialize(o)
	local t = type(o)
	if t == "number" then
		res = res .. string.format("%d", o)
	elseif t == "boolean" then
		res = res .. (o and "true" or "false")
	elseif t == "string" then
		res = res .. string.format("%q", o)
	elseif t == "table" then
		res = res .. "{\n"
		for k,v in pairs(o) do
			res = res .. "\t" .. k .. " = "
			self:_serialize(v)
			res = res .. ";\n"
		end
		res = res .. "}\n"
	end
end


return Config
