Prompting = false

local textObject = nil

local lastRenderedText = "this hasnt been rendered yet"
local typedText = ""
local promptType = ""

local drawPosX = DefaultOffsetX - 10
local drawPosY = DefaultOffsetY - 64
local promptDrawPosX = DefaultOffsetX - 32
local promptDrawPosY = DefaultOffsetY - 16 - 60

local outputs = {}

local function listClues()
	if next(LogUnlocks) == nil then
		return "No logs collected."
	end
	local output = "Entries:"
	for key, _ in pairs(LogUnlocks) do
		output = output .. "\n- " .. string.upper(key)
	end
	output = output .. "\nEnter one of these into the base computer."
	return output
end

local logs = {
	loga =
	"I left all of my thoughts down on notes like this one.\n If anyone finds them, use them to navigate this place.",
	logb =
	"My drone is complete! \nMy design is a little delicate so I will need to avoid bumping into walls.",

	logc =
	"Up north, I created a really strong password on the wall to keep those drones out of getting out.",
	logd =
	"This little shortcut opens when I input open SESAme so I can sneak around that drone.",
	loge = "The entrance to the vault is very secure. Nobody will ever PASS.",
	logf = "I evaded the drones but now I'm closing off this lab forever. I am finally FREE.",
}

local function showClue(name)
	if LogUnlocks[name] ~= nil then
		Notify(logs[name])
	end
end

local function doorSound()
	love.audio.play(Sounds.door)
end

function PromptLoad()
	-- Tutorial
	outputs.complist = function()
		Notify(listClues())
	end
	outputs.comphelp = function()
		Notify("Did you need a CLUE?")
	end
	outputs.compclue = function()
		Notify("The door is broken. Maybe SHUTting it before OPENing it might do something.")
	end
	outputs.compman = function()
		Notify("this isn't a real terminal")
	end
	outputs.compls = function()
		Notify(listClues())
	end
	outputs.bdooropen = function()
		if not Unlocks.base_open then
			if Unlocks.unstuck then
				Unlocks.base_open = true
				Notify("Opening!")
				doorSound()
			else
				Notify("It looks stuck.")
			end
		end
	end
	outputs.bdoorshut = function()
		if not Unlocks.unstuck then
			Unlocks.unstuck = true
		end
		Notify("It looks less stuck.")
	end

	-- Fun
	outputs.comphiya = function()
		Notify("Hiiii!")
	end
	outputs.compturn = function()
		Notify("Turn what?")
	end

	-- Logs
	outputs.comploga = function()
		showClue("loga")
	end
	outputs.complogb = function()
		showClue("logb")
	end
	outputs.complogc = function()
		showClue("logc")
	end
	outputs.complogd = function()
		showClue("logd")
	end
	outputs.comploge = function()
		showClue("loge")
	end
	outputs.complogf = function()
		showClue("logf")
	end

	-- Level Computers
	outputs.door2arms = function()
		if Unlocks.symbolsdoor then
			return
		end
		Unlocks.symbolsdoor = true
		doorSound()
		Notify("Door opening...")
	end
	outputs.shortcutpass = function()
		if Unlocks.enddoor then
			return
		end
		Unlocks.enddoor = true
		doorSound()
		Notify("Door opening...")
	end
	outputs.shortcutsesa = function()
		if Unlocks.shortcut then
			return
		end
		Unlocks.shortcut = true
		doorSound()
		Notify("Open sesame!")
	end
	outputs.freefree = function()
		Unlocks.free = true
		Notify("The window slides open!")
		Notify("You see a man in a white lab coat outside.")
		Notify("He is running away.")
		Notify("The end")
		Complete = true
	end

	textObject = love.graphics.newText(AsepriteFont, "hi")
end

function Prompt(pType)
	promptType = pType
	Prompting = true
	PlayerPos = (GetTileIndex(CurrentRoom, PlayerPos) + CurrentRoom.position) * TileSize
	PlayerPos.x = PlayerPos.x - TileSize / 2
	PlayerPos.y = PlayerPos.y - 6
	typedText = ""
end

function PromptDraw()
	if lastRenderedText ~= typedText then
		textObject:set("> " .. typedText)
		lastRenderedText = typedText
	end
	love.graphics.draw(Textures.prompt, promptDrawPosX, promptDrawPosY)
	love.graphics.draw(textObject, drawPosX, drawPosY)
end

function love.textinput(t)
	if not Prompting then
		return
	end
	if string.len(typedText) < 4 then
		typedText = typedText .. t
		love.audio.play(Sounds.type)
		typedText = string.lower(typedText)
	end
end

local function SubmitCode()
	local attempt = string.lower(promptType .. typedText)
	print("Attempted " .. attempt)
	local attemptResult = outputs[attempt]
	love.audio.play(Sounds.enter)
	Prompting = false
	if attemptResult == nil then
		if typedText ~= "" then
			Notify("Command not found")
		end
		Release()
		return
	end
	attemptResult()
	Release()
end

function PromptUpdate(dt)
	PlayerUpdateDroneSound(dt, false)
end

function PromptKeypressed(key, scancode, isrepeat)
	if not Prompting then
		return
	end
	if key == "return" then
		SubmitCode()
	end
	if key == "backspace" then
		if string.len(typedText) > 0 then
			typedText = string.sub(typedText, 0, string.len(typedText) - 1)
			love.audio.play(Sounds.type)
		end
	end
end
