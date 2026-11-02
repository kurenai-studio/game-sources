-- R. Bassett Jr. 
-- 2026.07.21
-- Save and load CSV game data
-- All data are score for levels. It only works for 16 levels, because
-- I'm old and I forget the math to make it work for unlimited levels.
-- GNU General Public License (GPLv3) - https://www.gnu.org/licenses/gpl-3.0.html

local savemgr = {}

-- tonumber, as all values are numbers and need to be used as such
function savemgr:csvToTable(str)
	local r = {}
	local i = 1
	local p = 1
	while true do
		local s = str:find(',', p, true)
		if not s then
			r[i] = str:sub(p)
			break
		end
		r[i] = tonumber(str:sub(p, s - 1))
		p = s + 1
		i = i + 1
	end
	return r
end


function savemgr:saveExists()
	local info = love.filesystem.getInfo("save.csv", info)
	
	if not info then
		return false
	end
	
	-- Exists, but is empty
	if info.size < 1 then
		return false
	end
	
	return true
end


function savemgr:createSaveData()
	data = ""
	for i = 1, 64, 1 do
		data = data .. "0,"
	end
	
	data = string.sub(data, 1, string.len(data)-1) -- remove trailing comma
	
	local df = love.filesystem.newFileData(data, "save.csv")		
	local success, message = love.filesystem.write("save.csv", df)
	
	return savemgr:csvToTable(data)
end


function savemgr:writeSaveData()
	local data = ""
	
	for i = 1, 64, 1 do
		data = data .. saveData[i] .. ","
	end
	
	data = string.sub(data, 1, string.len(data)-1)

	local df = love.filesystem.newFileData(data, "save.csv")		
	local success, message = love.filesystem.write("save.csv", df)
end


function savemgr:loadSaveData()
	local saveFileContents = love.filesystem.read("save.csv", nil)
	
	if saveFileContents then
		return savemgr:csvToTable(saveFileContents)
	else
		print("Failed to load save data!")
		love.event.quit()
	end
end


-- SaveData: Normal 1to16, Easy 17to32, Hard 33to48, Crazy 49to64
-- There is math for this... modulo... something... I forget
function savemgr:putSlotInRange(diff, s)
	if diff == 2 then
		s = s + 16
	elseif diff == 3 then
		s = s + 32
	elseif diff ==4 then
		s = s + 48
	end
	
	return s
end


-- Returns high score for a difficulty
function savemgr:getDiffHS(diff)
	local hs = 0
	local low = 1
	local high = 16
	
	if diff == 2 then
		low = low + 16
		high = high + 16
	elseif diff == 3 then
		low = low + 32
		high = high + 32
	elseif diff == 4 then
		low = low + 48
		high = high + 48
	end
	
	for i = low, high, 1 do
		hs = hs + tonumber(saveData[i]) -- Lua did not complain here, but...
	end
	
	return hs
end


-- Returns high score for the specified level
function savemgr:getLevelHS(diff, level)
	local saveSlot = savemgr:putSlotInRange(diff, level)
	
	return saveData[saveSlot]
end


-- Returns highest level for a difficulty
function savemgr:getHighestLevel(diff)
	local lvl = 0
	local low = 1
	local high = 16
	
	if diff == 2 then
		low = low + 16
		high = high + 16
	elseif diff == 3 then
		low = low + 32
		high = high + 32
	elseif diff == 4 then
		low = low + 48
		high = high + 48
	end
	
	for i = low, high, 1 do
		if tonumber(saveData[i]) > 0 then -- ... it did here! Makes no sense, as I tonumber'd each entry on line 20.
			lvl = lvl + 1
		end
	end
	
	return lvl
end


-- Set a high score
function savemgr:setHS(diff, level, score)
	local saveSlot = savemgr:putSlotInRange(diff, level)
	
	saveData[saveSlot] = score
end


function savemgr:compare(diff, level, score)
	local saveSlot = savemgr:putSlotInRange(diff, level)

	if score > savemgr:getLevelHS(diff, level) then
		return true
	end

	return false
end

return savemgr