Object = require "classic"
Vector = require "vector"
Menu = require "menu"
Event = require "event"

LOCALIZATIONS = {
	require "localization.eng",
	require "localization.rus"
}


local UI = Object:extend()


function UI:new()
	self.font = love.graphics.setNewFont(
		"res/PressStart2P-Regular.ttf", 16, "mono"
	)
	self.font:setFilter("nearest", "nearest")
	--self.center = Vector(love.graphics.getDimensions())
	self.center = Vector(960, 540)
	self.showFPS = false
	session.onWin:add(function()
		self.menus.hudFuel.active = false
		self.menus.hudHeat.active = false
	end, self)

	self.loc = {}
	self:setLocalization(LOCALIZATIONS[config.values.language])

	self.menus = {}
	self:createMenus()

	self.startGameCallback = Event()
	session.onGameOver:add(self.onGameOver, self)
	session.onFinalAnimEnd:add(self.onGameWin, self)
end


function UI:setLocalization(loc)
	for k, v in pairs(loc) do
		self.loc[k] = v
	end
end


function UI:createMenus()
	local l = self.loc
	local title = Menu(input, self.font)
	title.alignment = "center"
	title:add({
		textFunc = function() return l.gameName end,
		color = {1, 1, 1, 1},
		scale = 3.0,
		lineHeight = self.font:getHeight() * 3.2
	})
	title:add({
		textFunc = function() return string.format(l.title.authorFmt, l.credits.author) end,
		color = {1, 1, 1, .5}
	})
	title:add()
	title:add()
	title:add({
		select = true;
		textFunc = function() return l.title.press2Start end;
		onenter = function()
			-- Title screen is never displayed again
			self.menus.title = nil
			self.menus.main.active = true
			self.menus.main.focused = true
		end
	})
	title.active = true
	title.focused = true

	local main = Menu(input, self.font)
	main.alignment = "left"
	main:add({
		select = true;
		textFunc = function() return l.main.play end;
		onenter = function()
			self.menus.main.active = false
			self.menus.play.active = true
			self.menus.play._selection = #self.menus.play.entries - 1
			setGameMode(config.values.gamemode)
			ship.angle = 0
			ship.preview = true
		end
	})
	main:add({
		select = true;
		textFunc = function() return l.main.options end;
		onselection = function(state)
			self.menus.options.active = state
		end;
		onenter = function()
			self.menus.main.focused = false
			self.menus.pause.focused = false
			self.menus.options.focused = true
		end;
	})
	main:add({
		select = true;
		textFunc = function() return l.main.credits end;
		onselection = function(state)
			self.menus.credits.active = state
		end;
	})
	main:add({
		select = true;
		textFunc = function() return l.main.exit end;
		onenter = function()
			love.event.quit()
		end
	})
	main.outlineSelection = true

	local play = Menu(input, self.font)
	play.alignment = "right"
	play.focused = true
	play.offset = 150
	play:add({
		select = true;
		textFunc = function()
			return l.ships[ship:get().name]
		end;
		onselection = function(state)
			self.menus.shipInfo.active = state
			self:updateShipInfo()
		end;
		onenter = function()
			if not self.shipSelect then
				return
			end
			self.shipSelect()
			self:updateShipInfo()
		end
	})
	play:add({
		select = true;
		textFunc = function()
			return l.play.modes[gameModes[config.values.gamemode]]
		end;
		onselection = function(state)
		end;
		onenter = function()
			if not self.selectMode then
				return
			end
			self.selectMode()
		end
	})
	play:add({ text = "---" })
	play:add({
		select = true;
		textFunc = function() return l.play.start end;
		onenter = function()
			ship.preview = false
			self.startGameCallback:invoke()
			self.menus.play.active = false
			self.menus.hudFuel.active = true
			self.menus.hudHeat.active = true
		end
	})
	play:add({
		select = true;
		textFunc = function() return l.common.back end;
		onenter = function()
			ship.preview = false
			self.menus.main.active = true
			self.menus.play.active = false
		end
	})

	local shipInfo = Menu(input, self.font)
	shipInfo.alignment = "left"
	shipInfo.offset = 150
	shipInfo:add()
	shipInfo:add()
	shipInfo:add()
	shipInfo:add()

	local options = Menu(input, self.font)
	options.alignment = "right"
	options:add({
		select = true;
		textFunc = function()
			return string.format(l.options.music, config.values.music)
		end;
		onenter = function()
			if not self.changeMusicVolumeCallback then
				return
			end
			self.changeMusicVolumeCallback()
		end
	})
	options:add({
		select = true;
		textFunc = function()
			return string.format(l.options.sound, config.values.sound)
		end;
		onenter = function()
			if not self.changeSoundVolumeCallback then
				return
			end
			self.changeSoundVolumeCallback()
		end
	})
	options:add({
		select = true;
		textFunc = function()
			return string.format(l.options.language, l.languageNative)
		end;
		onenter = function()
			config.values.language = config.values.language + 1
			if config.values.language > #LOCALIZATIONS then
				config.values.language = 1
			end
			self:setLocalization(LOCALIZATIONS[config.values.language])
			for _, menu in pairs(self.menus) do
				menu:updateText()
			end
		end
	})
	options:add({
		select = true;
		textFunc = function()
			return string.format(l.options.msaa, config.values.msaa)
		end;
		onenter = function()
			if not self.changeMSAACallback then
				return
			end
			self.changeMSAACallback()
		end
	})
	options:add({
		select = true;
		textFunc = function()
			return string.format(l.options.bloom, config.values.bloom)
		end;
		onenter = function()
			if not self.changeBloom then
				return
			end
			self.changeBloom()
		end
	})
	options:add({
		select = true;
		textFunc = function()
			return string.format(
				l.options.scanlines,
				config.values.scanlines and l.common.on or l.common.off
			)
		end;
		onenter = function()
			if not self.toggleScanlines then
				return
			end
			self.toggleScanlines()
		end
	})
	options:add({
		select = true;
		textFunc = function()
			return string.format(l.options.crt, config.values.crt)
		end;
		onenter = function()
			if not self.changeCRT then
				return
			end
			self.changeCRT()
		end
	})
	options:add({
		select = true;
		textFunc = function()
			return string.format(l.options.pixel, config.values.pixel)
		end;
		onenter = function()
			if not self.changePixel then
				return
			end
			self.changePixel()
		end
	})
	options.onback = function()
		self.menus.options.focused = false
		self.menus.main.focused = true
		self.menus.pause.focused = true
	end
	options.onleft = options.onback

	local credits = Menu(input, self.font)
	credits.alignment = "right"
	credits:add({textFunc = function() return
		string.format(l.credits.authorFmt, l.credits.author)
	end})
	credits:add({textFunc = function() return l.credits.love end})
	credits:add({textFunc = function() return l.credits.music end})
	credits:add({textFunc = function() return l.credits.font end})
	credits:add({textFunc = function() return l.credits.laser end})

	local hudFuel = Menu(input, self.font)
	hudFuel.offset = 150
	hudFuel.trueTransparency = true
	hudFuel.alignment = "left"
	hudFuel:add()
	hudFuel.beforedraw = function()
		local score = math.floor(session.score)
		local scorePerc = math.floor(score / session.goal * 100)

		if not session.goalReached then
			self.menus.hudFuel.visible = true
			self.menus.hudFuel.entries[1].color = {1, 1, 1, 0.2}
			local scoreText =  "F " .. score
			if not session.endlessMode then
				scoreText = scoreText .. " " ..  scorePerc .. "%"
			end
			self.menus.hudFuel.entries[1].text = scoreText
		else
			self.menus.hudFuel.entries[1].color = {1, 1, 0, 1}
			local floored = math.floor(session.winCountdown)
			local fraction = session.winCountdown - floored
			self.menus.hudFuel.entries[1].text = string.format(l.ui.charging, floored)
			self.menus.hudFuel.visible = fraction > 0.5
		end
	end
	hudFuel.focused = true
	hudFuel.onback = function() self:onPause() end

	local hudHeat = Menu(input, self.font)
	hudHeat.offset = -200
	hudHeat.trueTransparency = true
	hudHeat.alignment = "left"
	hudHeat:add()
	hudHeat.beforedraw = function()
		if laser.overheat then
			self.menus.hudHeat.entries[1].color = {1, 0, 0, 1}
		else
			self.menus.hudHeat.entries[1].color = {1, 1, 1, 0.2}
		end

		local heat = math.floor(laser.heat) .. "%"
		self.menus.hudHeat.entries[1].text = heat
	end

	local pause = Menu(input, self.font)
	pause.alignment = "left"
	pause.offset = hudFuel.offset
	pause:add({
		select = true;
		textFunc = function() return l.pause.resume end;
		onenter = function()
			session:pause(false)
			self.menus.hudFuel.active = true
			self.menus.hudHeat.active = true
			self.menus.options.active = false
			self.menus.pause.active = false
		end
	})
	-- Options menu.
	pause:add(main.entries[2])
	pause:add({
		select = true;
		textFunc = function() return l.main.exit end;
		onenter = function()
			session:pause(false)
			self.menus.pause.active = false
			self.menus.main.active = true
			self.menus.options.offset = self.menus.main.offset
			session:reset()
		end;
	})
	pause.outlineSelection = true
	pause.focused = true
	pause.onback = pause.entries[1].onenter


	local gameover = Menu(input, self.font)
	gameover:add({
		select = true;
		textFunc = function() return l.gameover.retry end;
		onenter = function()
			self.startGameCallback:invoke()
			self.menus.gameover.active = false
			self.menus.stats.active = false
			self.menus.hudFuel.active = true
			self.menus.hudHeat.active = true
		end
	})
	gameover:add({
		select = true;
		textFunc = function() return l.common.back end;
		onenter = function()
			self.menus.gameover:selectFirst()
			self.menus.gameover.active = false
			self.menus.stats.active = false
			self.menus.main.active = true
			self.menus.options.offset = self.menus.main.offset
			ship.dead = false
		end
	})

	local stats = Menu(input, self.font)
	stats.alignment = "right"
	stats:add({})
	stats:add({})


	local gamewon = Menu(input, self.font)
	gamewon.alignment = "center"
	gamewon:add({textFunc = function() return l.win.l1 end})
	gamewon:add({textFunc = function() return l.win.l2 end})
	gamewon:add({textFunc = function() return l.win.l3 end})
	gamewon:add()
	gamewon:add({
		select = true;
		textFunc = function() return l.win.endlessMode end;
		onenter = function()
			self.startGameCallback:invoke(true)
			self.menus.gamewon.active = false
			self.menus.hudFuel.active = true
			self.menus.hudHeat.active = true
		end
	})
	gamewon:add({
		select = true;
		textFunc = function() return l.common.back end;
		onenter = function()
			self.menus.gamewon:selectFirst()
			self.menus.gamewon.active = false
			self.menus.main.active = true
		end
	})


	self.menus.title = title
	self.menus.main = main
	self.menus.play = play
	self.menus.shipInfo = shipInfo
	self.menus.options = options
	self.menus.credits = credits
	self.menus.pause = pause
	self.menus.hudFuel = hudFuel
	self.menus.hudHeat = hudHeat
	self.menus.gameover = gameover
	self.menus.stats = stats
	self.menus.gamewon = gamewon
end


function UI:updateShipInfo()
	local l = self.loc
	local s = ship:getStats()
	local shipInfo = self.menus.shipInfo
	local text = {
		"|",
		"||",
		"|||",
		"||||",
		"|||||"
	}
	shipInfo.entries[1].text = string.format("%s: %8s", l.shipStats.damage, text[s.damage])
	shipInfo.entries[2].text = string.format("%s: %8s", l.shipStats.range, text[s.range])
	shipInfo.entries[3].text = string.format("%s: %8s", l.shipStats.speed, text[s.speed])
	shipInfo.entries[4].text = string.format("%s: %8s", l.shipStats.heat, text[s.heat])
end


function UI:onPause()
	if session._gameOver then
		return
	end
	session:pause(true)
	self.menus.hudFuel.active = false
	self.menus.hudHeat.active = false
	self.menus.options.offset = self.menus.pause.offset
	self.menus.pause:selectFirst()
	self.menus.pause.active = true
end


function UI:onGameOver()
	local score = math.floor(session.score)
	local scorePerc = math.floor(score / session.goal * 100)
	local scoreText =  "F " .. score
	if not session.endlessMode then
		scoreText = scoreText .. " " ..  scorePerc .. "%"
	end
	self.menus.stats.entries[1].text = scoreText
	self.menus.stats.entries[2].text = math.floor(session.timer) .. "s"
	self.menus.hudFuel.active = false
	self.menus.hudHeat.active = false
	self.menus.gameover.active = true
	self.menus.gameover.focused = true
	self.menus.stats.active = true
end


function UI:onGameWin()
	self.menus.hudFuel.active = false
	self.menus.hudHeat.active = false
	self.menus.gamewon.active = true
	self.menus.gamewon.focused = true
end


function UI:toggleFPS()
	self.showFPS = not self.showFPS
end


function UI:resize(w, h)
	self.center.x = w / 2
	self.center.y = h / 2
	for i, menu in pairs(self.menus) do
		menu:resize(w, h)
	end
end


function UI:update(dt)
	for i, menu in pairs(self.menus) do
		menu:update(dt)
	end
end


function UI:draw()
	love.graphics.setLineWidth(1)
	if self.showFPS then
		love.graphics.setColor(1, 1, 1, 0.2)
		love.graphics.line(
			self.center.x - 10000, self.center.y,
			self.center.x + 10000, self.center.y
		)
		love.graphics.line(
			self.center.x, self.center.y - 10000,
			self.center.x, self.center.y + 10000
		)
		love.graphics.print(love.timer.getFPS(), 5, 5)
		love.graphics.setColor(1, 1, 1, 1)
	end

	for i, menu in pairs(self.menus) do
		menu:draw()
	end

	love.graphics.setColor(1, 1, 1, 1)
end


return UI
