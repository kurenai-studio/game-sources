noblox = {
	path = ...
}

noblox.g3d = require("g3d")
noblox.vector3 = require(noblox.path .. "/vector3")
noblox.cframe = require(noblox.path .. "/cframe")
noblox.model = require(noblox.path .. "/model")

local noblox = noblox
_G.noblox = nil
return noblox
