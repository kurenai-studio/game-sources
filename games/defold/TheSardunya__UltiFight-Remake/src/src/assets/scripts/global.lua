smap = {nil, nil}
keyList = {}

default_pos1 = vmath.vector3(0, 0, 0)
default_pos2 = vmath.vector3(0, 0, 0)

xSpeed = 8

default_y = 149

bumpImpact_y_offset  = -18

friction = 0.4


function vfx(url, pos1)
	local pos = vmath.vector3(pos1)
	if pos == nil or url == nil then return -1 end
	factory.create(url, pos)
	return 0
end

function vfx_particle(url, pos1)
	
	if not (url == nil or pos1 == nil) then
		local pos = vmath.vector3(pos1)
		go.set_position(pos, url)
		particlefx.play(url)
	else 
		return -1
	end
	return 0
end

function setOffset(Vector3, x, y, z)
	local xOffset = not (x == nil)
	local yOffset = not (y == nil)
	local zOffset = not (z == nil)

	local ret = vmath.vector3(Vector3.x, Vector3.y, Vector3.z)
	
	if xOffset then ret.x = ret.x + x end
	if yOffset then ret.y = ret.y + y end
	if zOffset then ret.z = ret.z + z end
	
	return ret
end

function getCurrentFrame(url)
	if url == nil then
		return go.get("#sprite", "frame_count") * go.get("#sprite", "cursor")
	else
		return go.get(url, "frame_count") * go.get(url, "cursor")
	end
end

function searchList(data, arr)
	for i = 1, #arr, 1 do
		if arr[i] == data then
			return {exist = true, pos = i}
		end
	end
	return {exist = false, pos = nil}
end

function keyPressed(key_str)
	return searchList(hash(key_str), keyList).exist
end

function putKey(action, key)
	
	if action.pressed and not (searchList(key, keyList).exist) then
		table.insert(keyList, key)
		if key == hash("R") or key == hash("F2") then
			resetGameStatus()
		end
	end
	
	if action.released and searchList(key, keyList).exist then
		table.remove(keyList, searchList(key, keyList).pos)
	end
	return 0
end

function dashFist(self)
	

	
	
	if self.attacking4 and self.dashCooldown == 0 then
		self.dashCooldown = 1

		if self.direction == 1 then vfx_particle(self.rTrailUrl, vmath.vector3(self.pos.x + 160, self.pos.y, self.pos.z)) end
		if self.direction == -1 then vfx_particle(self.lTrailUrl, vmath.vector3(self.pos.x - 160, self.pos.y, self.pos.z)) end
		
		local endPos = vmath.vector3()
		local startPos = vmath.vector3()
		local endPos2 = vmath.vector3()
		local startPos2 = vmath.vector3()
		
		if self.direction == 1 then
			endPos = vmath.vector3(self.pos.x + 256, self.pos.y + 12, self.pos.z)
			startPos = vmath.vector3(self.pos.x - 12, self.pos.y + 12, self.pos.z)
		end
		if self.direction == -1 then
			endPos = vmath.vector3(self.pos.x - 256, self.pos.y + 12, self.pos.z)
			startPos = vmath.vector3(self.pos.x + 12, self.pos.y + 12, self.pos.z)
		end
		
		endPos2 = vmath.vector3(endPos)
		startPos2 = vmath.vector3(startPos)
		
		if endPos2.x > 1320 then
			local offset = endPos2.x - 1320
			endPos2.x = -20 + offset
			startPos2.x = -20
		else 
			if endPos2.x < -20 then 
				local offset = endPos2.x - 20
				endPos2.x = 1320 - offset 
				startPos2.x = 1320
			end 
		end

		local rcast = physics.raycast(startPos, endPos, {hash(self.opponent_str)})
		local rcast2 = physics.raycast(startPos2, endPos2, {hash(self.opponent_str)})

		if (rcast or rcast2) and self.dealDmg4 then
			if (rcast.group == hash(self.opponent_str) or rcast2.group == hash(self.opponent_str)) then
				vfx(self.impactUrl, vmath.vector3(smap[self.opponent].pos.x, self.pos.y + 12, self.pos.z))
				self.dealDmg4 = false
				
				smap[self.opponent].hp = smap[self.opponent].hp - 10
				smap[self.opponent].gotHit1 = true
				print(smap[self.opponent].hp)
			end
		end
		if not (rcast or rcast2) then self.dealDmg4 = false end
		
		
		
		if self.direction == 1 then self.pos.x = self.pos.x + 256 end
		if self.direction == -1 then self.pos.x = self.pos.x - 256 end
		self.attacking4 = false 
		self.dealDmg4 = true 
	end
end

function fist(self)
	if self.attacking1 and getCurrentFrame() > 1.5 and getCurrentFrame() < 4.5 and self.dealDmg1 then
		local endPos = vmath.vector3()
		local startPos = vmath.vector3()
		if self.direction == 1 then
			endPos = vmath.vector3(self.pos.x + 16, self.pos.y + 12, self.pos.z)
			startPos = vmath.vector3(self.pos.x - 4, self.pos.y + 12, self.pos.z)
		end
		if self.direction == -1 then
			endPos = vmath.vector3(self.pos.x - 16, self.pos.y + 12, self.pos.z)
			startPos = vmath.vector3(self.pos.x + 4, self.pos.y + 12, self.pos.z)
		end

		local rcast = physics.raycast(startPos, endPos, {hash(self.opponent_str)})

		if rcast then
			if rcast.group == hash(self.opponent_str) then
				vfx(self.impactUrl, vmath.vector3(smap[self.opponent].pos.x, self.pos.y + 12, self.pos.z))
				
				smap[self.opponent].hp = smap[self.opponent].hp - 20
				smap[self.opponent].gotHit1 = true
				print(smap[self.opponent].hp)
			end
		end
		self.dealDmg1 = false
	end
end

function bump(self)

	if self.onGround then
		
		if self.dealDmg2 and self.attacking2 then
			local vfxPos = vmath.vector3(self.pos)
			vfxPos.y = default_y - 32
			if self.direction == 1 then vfxPos = setOffset(vfxPos, -6) end
			if self.direction == -1 then vfxPos = setOffset(vfxPos, 6) end
			vfx(self.impactUrl, vfxPos)
		end
		
		self.dealDmg2 = true
		self.attacking2 = false
	end
	
	if self.attacking2 and getCurrentFrame() == 7 and (self.currentanim == "RightBump" or self.currentanim == "LeftBump") and self.dealDmg2 then

		self.pos.y = self.pos.y - 16

		local endPos = vmath.vector3()

		endPos = vmath.vector3(self.pos.x , self.pos.y - 16, self.pos.z)	

		local rcast = physics.raycast(self.pos, endPos, {hash(self.opponent_str)})

		if rcast then
			if rcast.group == hash(self.opponent_str) then
				
				vfx(self.impactUrl, vmath.vector3(self.pos.x, smap[self.opponent].pos.y + 18, self.pos.z))
				
				smap[self.opponent].hp = smap[self.opponent].hp - 25
				smap[self.opponent].gotHit2 = true
				print(smap[self.opponent].hp)
				self.dealDmg2 = false
				self.attacking2 = false
			end
		end
	end
	
end

function flykick(self)

	if self.attacking3 and getCurrentFrame() == 8 and (self.currentanim == "RightFlyKick" or self.currentanim == "LeftFlyKick") and self.dealDmg3 then

		if self.direction == 1 then self.pos.x = self.pos.x + 16 end
		if self.direction == -1 then self.pos.x = self.pos.x - 16 end
		
		self.flyDm = self.flyDm + 16

		if self.flyDm > 160 then
			self.flyDm = 0
			self.attacking3 = false
			self.dealDmg3 = false
		end

		local endPos = vmath.vector3()

		if self.direction == 1 then endPos = vmath.vector3(self.pos.x + 16 , self.pos.y, self.pos.z) end
		if self.direction == -1 then endPos = vmath.vector3(self.pos.x - 16 , self.pos.y, self.pos.z) end

		local rcast = physics.raycast(self.pos, endPos, {hash(self.opponent_str)})

		if rcast then
			if rcast.group == hash(self.opponent_str) then

				vfx(self.impactUrl, vmath.vector3(smap[self.opponent].pos.x, self.pos.y, self.pos.z))

				smap[self.opponent].hp = smap[self.opponent].hp - 35
				smap[self.opponent].gotHit3 = true
				print(smap[self.opponent].hp)
				if self.direction == 1 then smap[self.opponent].gotHit3spd = 32 end
				if self.direction == -1 then smap[self.opponent].gotHit3spd = -32 end
				self.dealDmg3 = false
				self.attacking3 = false
				self.flyDm = 0
			end
		end
	end

end

function jump(self)
	
	self.pos.y = self.pos.y + self.gravity 
	
	self.gravity = self.gravity - friction


	return 0
end

function animate(self, anim_str, end_function, spriteurl)
	
	if not (self.currentanim == anim_str) and spriteurl == nil then
		if end_function == nil then sprite.play_flipbook("#sprite", anim_str) 
		else sprite.play_flipbook("#sprite", anim_str, end_function) end
		self.currentanim = anim_str
	end
	if not (self.currentanim == anim_str) and not (spriteurl == nil) then
		if end_function == nil then sprite.play_flipbook(spriteurl, anim_str) 
		else sprite.play_flipbook(spriteurl, anim_str, end_function) end
		self.currentanim = anim_str
	end
	
	return 0
end

function animate_direction(self, anim_str_r, anim_str_l, end_function, url)
	if self.direction == 1 then animate(self, anim_str_r, end_function, url) end
	if self.direction == -1 then animate(self, anim_str_l, end_function, url) end
end

function initChar1(self)
	self.impactUrl = "/vfxCreator1#impact"
	self.direction = 1
	self.idle = true
	self.RightMovementKey = "D"
	self.LeftMovementKey = "A"
	self.JumpMovementKey = "W"
	self.JumpThroughMovementKey = "S"
	self.PrimaryAttackKey = "Q"
	self.SecondaryAttackKey = "E"
	self.hp = 100
	self.jump = false
	self.gravity = 0
	self.onGround = true
	self.attacking1 = false
	self.attacking2 = false
	self.attacking3 = false
	self.attacking4 = false
	self.dealDmg1 = true
	self.dealDmg2 = true
	self.dealDmg3 = true
	self.dealDmg4 = true
	self.opponent = 2
	self.opponent_str = "char2"
	self.gotHit1 = false
	self.gotHit2 = false
	self.gotHit3 = false
	self.gotHit4 = false
	self.flyDm = 0
	self.dashCooldown = 0
	self.reverse = false
	self.dead = false
	self.rTrailUrl = "/vfxCreator1#stickmanTrailR"
	self.lTrailUrl = "/vfxCreator1#stickmanTrailL"
end

function initChar2(self)
	self.impactUrl = "/vfxCreator2#impact"
	self.direction = -1
	self.idle = true
	self.RightMovementKey = "Right"
	self.LeftMovementKey = "Left"
	self.JumpMovementKey = "Up"
	self.JumpThroughMovementKey = "Down"
	self.PrimaryAttackKey = "Rctrl"
	self.SecondaryAttackKey = "Rshift"
	self.hp = 100
	self.jump = false
	self.gravity = 0
	self.onGround = true
	self.attacking1 = false
	self.attacking2 = false
	self.attacking3 = false
	self.attacking4 = false
	self.dealDmg1 = true
	self.dealDmg2 = true
	self.dealDmg3 = true
	self.dealDmg4 = true
	self.opponent = 1
	self.opponent_str = "char1"
	self.gotHit1 = false
	self.gotHit2 = false
	self.gotHit3 = false
	self.gotHit4 = false
	self.flyDm = 0
	self.dashCooldown = 0
	self.reverse = false
	self.dead = false
	self.rTrailUrl = "/vfxCreator2#redmanTrailR"
	self.lTrailUrl = "/vfxCreator2#redmanTrailL"
end

function resetGameStatus()
	if smap[1].dead or smap[2].dead then
		
		initChar1(smap[1])
		initChar2(smap[2])
		go.set_position(default_pos1, "/char1")
		go.set_position(default_pos2, "/char2")
		
	end
end