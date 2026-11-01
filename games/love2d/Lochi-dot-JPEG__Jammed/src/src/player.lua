--PlayerPos = Vector.new(32 - 420, 32)
PlayerPos = Vector.new(32, 32)

PlayerSpeed = 20
PickupDistance = 12 * 12 -- Uses distance squared because square roots are bad

PLAYER_MAX_HP = 5.0
PlayerHp = PLAYER_MAX_HP

local velocity = Vector.new(0, 0)
local gravity = 5.5
local drag = 1.5
HoldingObjects = {}
local object_offset = Vector.new(TileSize / 2, TileSize / 2)
local flipped = 1

function Player_Draw()
	local draw_x = GameWidth / 2
	local draw_y = GameHeight / 2
	love.graphics.draw(Textures.player, draw_x, draw_y, 0, flipped, 1, 16, 16)
	for _, value in pairs(HoldingObjects) do
		value:Draw()
	end
end

local function accel_x(amount)
	velocity.x = velocity.x + amount
end

local function accel_y(amount)
	velocity.y = velocity.y + amount
end

local function get_collider()
	local tile_collision = GetTile(CurrentRoom, PlayerPos)
	if tile_collision == 0 then
		for _, object in pairs(CurrentRoom.objects) do
			if object.width ~= nil then
				if object:ContainsPoint(PlayerPos) then
					return 1
				end
			end
		end
	end
	return tile_collision
end

function Release()
	if not Outputting and not Prompting then
		MoveY(-11)
		SetVelocity(Vector.new(0, -2))
	end
end

local function OnEnterBaseComp()
	if PlayerHp ~= PLAYER_MAX_HP then
		Notify("> Frame repaired.")
	end
	PlayerHp = PLAYER_MAX_HP
	local added_logs = {}
	local added_batteries = 0
	for _, object in pairs(HoldingObjects) do
		if object.id ~= nil and type(object.id) == "string" then
			LogUnlocks[object.id] = true
			table.insert(added_logs, object.id)
		end
		if object.is_battery ~= nil then
			AddBattery()
			added_batteries = added_batteries + 1
		end
	end

	if added_batteries > 1 then
		Notify("> Adds " .. added_batteries .. " batteries")
		love.audio.play(Sounds.item)
	elseif added_batteries > 0 then
		Notify("> Adds battery")
		love.audio.play(Sounds.item)
	end
	if #added_logs ~= 0 then
		local logmsg = ""
		for i = 1, #added_logs do
			logmsg = logmsg .. "> Adds log " .. added_logs[i] .. "\n"
		end
		Notify(logmsg)
	end

	HoldingObjects = {}
end

function MoveX(amount)
	local last_position = PlayerPos.x
	PlayerPos.x = PlayerPos.x + amount
	local collider = get_collider()
	if collider == 1 then
		velocity.x = -velocity.x * 0.7
		PlayerPos.x = last_position
		Collide()
	elseif type(collider) == "string" then
		if collider == "comp" then
			OnEnterBaseComp()
		end
		Prompt(collider)
	end
end

function SetVelocity(_velocity)
	velocity = _velocity
end

function MoveY(amount)
	local last_position = PlayerPos.y
	PlayerPos.y = PlayerPos.y + amount
	local collider = get_collider()
	if collider == 1 then
		PlayerPos.y = last_position
		Collide()
		velocity.y = -velocity.y * 0.7
	elseif type(collider) == "string" then
		if collider == "comp" then
			OnEnterBaseComp()
		end
		Prompt(collider)
	end
end

-- This is so ugly
local function GetRoom()
	local tile = PlayerPos / 320
	tile.x = math.floor(tile.x)
	tile.y = math.floor(tile.y)
	if tile.y == 0 then
		if tile.x == 0 then
			return Rooms.base
		elseif tile.x == -1 then
			return Rooms.first_room
		elseif tile.x == -2 then
			return Rooms.second_room
		end
	elseif tile.y == -1 then
		if tile.x == -2 then
			return Rooms.left_center
		elseif tile.x == -1 then
			return Rooms.center_center
		elseif tile.x == 0 then
			return Rooms.right_center
		end
	elseif tile.y == -2 then
		if tile.x == 0 then
			return Rooms.right_top
		elseif tile.x == -1 then
			return Rooms.center_top
		elseif tile.x == -2 then
			return Rooms.left_top
		end
	end
	return Rooms.base
end

function Collide()
	PlayerHp = PlayerHp - 1
	if PlayerHp > 0 then
		love.audio.stop(Sounds.hurt)
		love.audio.play(Sounds.hurt)
	end
	Flash(0.2, 0.8, 0.8, 0.8)
end

function PlayerUpdateDroneSound(dt, active)
	local target_vol = 2.0 - velocity.y
	local current_vol = Sounds.dronefly:getVolume()
	local new_pitch = math.max(0.8 - velocity.y / 8, 0.4)
	if not active then
		target_vol = 0
		new_pitch = 0.4
	end
	Sounds.dronefly:setPitch(new_pitch)
	if current_vol < target_vol then
		Sounds.dronefly:setVolume(current_vol + dt * 2)
	end
	if current_vol > target_vol then
		Sounds.dronefly:setVolume(current_vol - dt * 2)
	end
end

function PlayerUpdate(dt)
	if PlayerHp <= 0 then
		BatteryDead()
	end

	love.audio.play(Sounds.dronefly)
	PlayerUpdateDroneSound(dt, true)
	local net_horizontal = 0
	if input_pressed(Inputs.down) then
		accel_y(dt * PlayerSpeed)
	end
	if input_pressed(Inputs.up) then
		accel_y(-dt * PlayerSpeed)
	else
		velocity.y = velocity.y + dt * gravity
	end
	if input_pressed(Inputs.left) then
		accel_x(-dt * PlayerSpeed)
		net_horizontal = 1
	end
	if input_pressed(Inputs.right) then
		accel_x(dt * PlayerSpeed)
		net_horizontal = net_horizontal - 1
	end
	if net_horizontal ~= 0 then
		flipped = net_horizontal
	end

	velocity.x = velocity.x * (1 - drag * dt)
	velocity.y = velocity.y * (1 - drag * dt)
	MoveX(velocity.x * dt * 20)
	CurrentRoom = GetRoom()
	MoveY(velocity.y * dt * 20)
	CurrentRoom = GetRoom()
	for key, object in pairs(CurrentRoom.objects) do
		if object.position ~= nil then
			local dist = Vector.distance_squared_to(object.position + object_offset, PlayerPos)
			if dist < PickupDistance then
				love.audio.play(Sounds.item)
				table.remove(CurrentRoom.objects, key)
				table.insert(HoldingObjects, object)
			end
		end
		if object.width ~= nil then
			if Unlocks[object.unlock] == true then
				table.remove(CurrentRoom.objects, key)
			end
		end
	end
	for key, object in pairs(HoldingObjects) do
		if object.position ~= nil then
			object.position = Vector.lerp(object.position, PlayerPos - object_offset, dt * 3 * (1 + key))
		end
	end
end
