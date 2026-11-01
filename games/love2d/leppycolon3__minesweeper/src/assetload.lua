-- asset loading system :3
-- loads an asset if its not in memory and returns it if the path is already loaded

local assetload = {}

assetload.memory = {
	image = {},
	sound = {},
	music = {}
}

assetload.funcs = {
	image = function(path)
		return love.graphics.newImage(path)
	end,
	sound = function(path)
		return love.audio.newSource(path,"static")
	end,
	music = function(path)
		return love.audio.newSource(path,"stream")
	end
}

function assld(asstype,path)
	if assetload.memory[asstype][path] then return assetload.memory[asstype][path] end
	assetload.memory[asstype][path] = assetload.funcs[asstype](path)
	return assetload.memory[asstype][path]
end

return assetload