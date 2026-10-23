---
-- Session controls game flow, difficulty,
-- and transition between different states.
-- classmod: Session

Object = require "classic"
Event  = require "event"
local Session = Object:extend()


function Session:new()
	--- Required score amount to beat the game.
	self.goal = 10000
	--- Starting score.
	self.startingScore = 200
	--- Score multiplier.
	self.scoreMultiplier = 0.3
	--- Countdown time in seconds.
	self.countdownTime = 10

	--- Current score.
	self.score = self.startingScore
	--- Session duration.
	self.timer = 0
	--- Whether score goal has been reached.
	self.goalReached = false
	--- Current countdown.
	self.winCountdown = self.countdownTime

	--- Event that is invoked on game over after the delay.
	self.onGameOver = Event()
	--- Event that is invoked when the countdown hits zero.
	self.onWin = Event()
	--- Event that is invoked at the end of the final animation.
	self.onFinalAnimEnd = Event()

	--- In endless mode there is no goal.
	self.endlessMode = false

	self._gameOver = false
	self._gameOverDelay = 1
	self._gameOverDelayTimer = 0
	self._paused = false
end


--[[ Callbacks -----------------------------------------]]--


--- Start new run.
-- Called from UI when the play button is pressed.
function Session:start(endlessMode)
	self.timer = 0
	if endlessMode or self.endlessMode then
		self.endlessMode = true
	else
		self.endlessMode = false
		self:resetScore()
	end
	laser:reset()
	ship.ignorefirebutton = true
	ship.angle = 0
	ship.dead = false
	ship:setActive(true)
	self:pause(false)
end


--- Pause the game.
function Session:pause(state)
	self._paused = state
	ship:pause(state)
	asteroids:pause(state)
end


function Session:reset()
	ship:setActive(false)
	asteroids:pause(true)
	asteroids:reset()
end


--- Called immediately when an asteroid collides with the ship.
function Session:gameOver()
	self._gameOver = true
	self.goalReached = false
	self.winCountdown = self.countdownTime
	asteroids:onGameOver()
	print("Game over!")
end


--- Called after the game over delay.
function Session:gameOverDelayed()
	self._gameOver = false
	self._gameOverDelayTimer = 0
	self:reset()
	self.onGameOver:invoke()
	self:resetScore()
end


--- Called when the countdown hits zero.
function Session:win()
	self.goalReached = false
	self.winCountdown = self.countdownTime
	ship:setActive(false)
	explosionAnim:play()
	print("Game won!")
	self.onWin:invoke()
end


--- Called at the end of the final animation.
function Session:finalAnimEnd()
	self:reset()
	self.onFinalAnimEnd:invoke()
end


--- Update the session.
function Session:update(dt)
	if self._paused then
		return
	end

	self.timer = self.timer + dt

	if self._gameOver then
		self._gameOverDelayTimer = self._gameOverDelayTimer + dt
		if self._gameOverDelayTimer >= self._gameOverDelay then
			self:gameOverDelayed()
		end
	end

	if self.goalReached then
		self.winCountdown = self.winCountdown - 1 * dt
		if self.winCountdown <= 1 then
			self:win()
		end
	end
end


--[[ Score ---------------------------------------------]]--


--- Increase the score by selected amount taking the multiplier into account.
-- number: score  Amount to add.
function Session:addScore(score)
	self.score = self.score + score * self.scoreMultiplier
	if self.score >= self.goal and not self.endlessMode then
		self.goalReached = true
	end
end


--- Decrease the score by selected amount.
-- Makes sure that the score is never below 0.
-- number: score  Amount to reduce.
function Session:reduceScore(score)
	self.score = self.score - score
	if self.score < 0 then
		self.score = 0
	end
end


--- Reset the score to its starting amount.
function Session:resetScore()
	self.score = self.startingScore
end


--- Get current score.
-- treturn: number
function Session:getScore()
	return self.score
end


return Session
