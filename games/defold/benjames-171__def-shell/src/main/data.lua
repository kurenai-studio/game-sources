local M = {}

M.STATE_NULL = -1
M.STATE_MENU = 1
M.STATE_CONTROLS = 2
M.STATE_SETTINGS = 3
M.STATE_CREDITS = 4

M.STATE_GAME = 100
M.STATE_PLAYING = 101
M.STATE_PAUSE = 102
M.STATE_CLEAR = 103
M.STATE_GAMEOVER = 104
M.STATE_COMPLETE = 105

M.state = M.STATE_MENU

M.SCR_W = 0
M.SCR_H = 0
M.CANV_W = 0
M.CANV_H = 0
M.TILE = 16
M.PIXEL = 4
M.MAX_LEVELS = 10
M.GATE = 1/25

M.APP_NAME = "appname"
M.FILE_NAME = "game.sav"

M.level = 1
M.time = 0
M.offset = vmath.vector3()
M.scrollpos = vmath.vector3()
M.bounds = vmath.vector3()

M.gate = {}

M.save = {
	sfx = 7,
	music = 7,
	fullscreen = false,
}

function M.loadgamefile()
	local file = sys.load(sys.get_save_file(M.APP_NAME, M.FILE_NAME))

	if next(file) ~= nil then
		M.save = file
		return true
	end
	return false
end

function M.savegamefile()
	sys.save(sys.get_save_file(M.APP_NAME, M.FILE_NAME), M.save)
end

function M.world2tile(p)
	return vmath.vector3(math.floor((p.x + M.TILE) / M.TILE), math.floor((p.y + M.TILE) / M.TILE), p.z)
end

function M.tile2world(p)
	return vmath.vector3((p.x * M.TILE) - (M.TILE / 2), (p.y * M.TILE) - (M.TILE / 2), p.z)
end

function M.hex2rgba(hex)
	hex = hex:gsub("#","")
	local rgba = vmath.vector4(tonumber("0x"..hex:sub(1,2))/255, tonumber("0x"..hex:sub(3,4))/255, tonumber("0x"..hex:sub(5,6))/255, 1)
	return rgba
end

function M.onscreen(p, m)
	if p.x > M.scrollpos.x - m and
		p.x < M.scrollpos.x + m + M.CANV_W and
		p.y > M.scrollpos.y - m and
		p.y < M.scrollpos.y + m + M.CANV_H then
		return true
	else
		return false
	end
end

function M.capdt(dt)
	if dt > 1/30 then
		dt = 1/30
	end
	return dt
end

function M.clamp(v, min, max)
	if type(v) ~= "number" then v = 0 end
	if v < min then v = min
	elseif v > max then v = max
	end
	return v
end

function M.wrap(v, min, max)
	if type(v) ~= "number" then v = 0 end
	if v < min then v = max
	elseif v > max then v = min
	end
	return v
end

function M.diff(a, b)
	return math.abs(a - b)
end

function M.ms2str(time)
	local day = math.floor(time / 86400)
	local rem = time % 86400
	local hr = math.floor(rem / 3600)
	rem = rem % 3600
	local min = math.floor(rem / 60)
	rem = rem % 60
	local sec = rem

	local str = ""
	if day > 0 then str = tostring(day) .. "d " end
	if hr > 0 or day > 0 then str = str .. tostring(hr) .. ":" end

	str = string.format("%s%02d:%02d", str, min, math.floor(sec))
	return str
end

function M.sound(id, gate, vol)
	vol = vol or 1
	if M.save.sfx > 0 then
		local t = M.gate[id] or 0
		t = os.clock() - t
		if t > (gate or M.GATE) then
			M.gate[id] = os.clock()
			msg.post("main:/sound", "play", {id = id, vol = vol})
		end
	end
end

function M.playmusic(id)
	if id ~= nil and id ~= M.currentsong then
		msg.post("main:/sound", "music", {id = id})
	end
end

function M.pausemusic(pause)
	msg.post("main:/sound", "pause", {pause = pause})
end

function M.stopmusic()
	msg.post("main:/sound", "stopmusic")
end

function M.setmusicvol(vol)
	msg.post("main:/sound", "setmusicvol")
end

function M.fullscreen()
	M.save.fullscreen = not defos.is_fullscreen()
	defos.set_fullscreen(M.save.fullscreen)
	defos.set_cursor_visible(not defos.is_fullscreen())
end

return M
