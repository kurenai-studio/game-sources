Outputting = false

local textObject = nil

local drawPosX = GameWidth / 2 - 64
local drawPosY = GameHeight / 2 - 64

local messageQueue = {}

function OutputsLoad()
	textObject = love.graphics.newText(AsepriteFont, "output")
end

local function wrap(message, max_len)
	local new_message = ""
	local char_count = 0
	message = string.gsub(message, "\n", " \n ")
	for word in string.gmatch(message, "([^ ]+)") do
		char_count = char_count + string.len(word) + 1
		if string.find(word, "\n") ~= nil then
			char_count = 0
		end
		if char_count >= max_len then
			new_message = new_message .. "\n"
			char_count = string.len(word)
		end
		new_message = new_message .. word
		new_message = new_message .. " "
	end
	return new_message
end

local function nextOutput()
	if #messageQueue == 0 then
		Outputting = false
		Release()
		return
	end

	if textObject ~= nil then
		Outputting = true
		local new_message = table.remove(messageQueue, 1)
		love.audio.play(Sounds.enter)
		new_message = wrap(new_message, 28)
		textObject:set(new_message)
	end
end

local function refreshOutput(dt)
	if #messageQueue == 0 then
		Outputting = false
		Release()
	end
	if not Outputting then
		nextOutput()
	end
end

function OutputKeypressed(key, _, _)
	if not Outputting then
		return
	end
	if key == "return" then
		nextOutput()
	end
end

function Notify(_text)
	table.insert(messageQueue, _text)
	refreshOutput()
end

function OutputUpdate(dt)
	PlayerUpdateDroneSound(dt, false)
end

function OutputDraw()
	if Outputting then
		love.graphics.draw(Textures.outputbg, drawPosX, drawPosY)
		love.graphics.draw(textObject, drawPosX + 8, drawPosY + 8)
	end
end
