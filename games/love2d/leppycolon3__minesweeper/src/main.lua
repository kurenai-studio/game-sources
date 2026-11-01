assetload = require 'assetload'

function table.find(haystack, needle)
	for i, v in pairs(haystack) do
		if v == needle then return i end
	end
end

function table.size(t)
	local count = 0
	for _, _ in pairs(t) do
		count = count + 1
	end
	return count
end

function toggleFullscreen()
	love.window.setFullscreen(not love.window.getFullscreen(), "exclusive")
end

function burp(t)
	for i,v in pairs(t) do
		print("i:",i,"v:",v)
	end
end

function playsound(s)
	local s = love.audio.newSource(s, "static")
	s:setVolume(0.5)
	s:play()
	s:release()
end

function plantmine()
	local newmine = {x = love.math.random(board.width), y = love.math.random(board.height)}
	for _,v in ipairs(board.mines) do
		if v.x == newmine.x and v.y == newmine.y then plantmine() return end
	end
	table.insert(board.mines,newmine)
end

function newgame()
	markedcount = 0
	board.tiles = emptyboard()
	board.mines = {}
	
	for m = 1, minesPopulation do
		plantmine()
	end
end

function emptyboard()
	local b = {}
	for y = 1, board.height do
		b[y] = {}
	end
	return b
end

function isempty()
	for _,v in pairs(board.tiles) do
		if table.size(v) > 0 then return false end
	end
	return true
end

screen = {}
screen.scale = 2
screen.w = 64
screen.h = 64
screen.bcolor = {1,1,1}
screen.canvas = love.graphics.newCanvas(screen.w, screen.h)
function screen.setDims(w,h)
	screen.canvas = love.graphics.newCanvas(w,h)
	screen.w = screen.scale*w
	screen.h = screen.scale*h
	love.window.setMode(screen.w, screen.h)
end
function screen.setBcolor(r,g,b)
	if g == nil and b == nil then
		screen.bcolor = r
	else
		screen.bcolor = {r,g,b}
	end
	love.graphics.setBackgroundColor(screen.bcolor)
end

function mouseX()
	return love.mouse.getX()/screen.scale
end
function mouseY()
	return love.mouse.getY()/screen.scale
end

function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")
	screen.canvas:setFilter("nearest", "nearest")
	screen.setBcolor(.75,.75,.75)
	
	
	board = {}
	board.x = 0
	board.y = 32
	board.width = 40
	board.height = 20
	board.grid = 16
	board.tiles = {}
	board.mines = {}
	minesPopulation = (board.width*board.height)*0.25
	if minesPopulation == board.width*board.height then
		minesPopulation = minesPopulation - 1
	end
	
	desperatestart = false
	markedcount = 0
	
	newgame()
	
	textures = {}
	textures[-1] = assld("image","assets/img/tile.png")
	for ya = 0, 8 do
		textures[ya] = assld("image", "assets/img/tile"..ya..".png")
	end
	textures["x"] = assld("image","assets/img/tilemine.png")
	textures["marked"] = assld("image","assets/img/tilemarked.png")
	
	
	love.graphics.setCanvas()
	screen.setDims(board.width*board.grid, board.height*board.grid+32)
end

function tile(x,y,state)
	board.tiles[y][x] = state
end

function checktile(x,y)
	local count = 0
	for _,v in ipairs(board.mines) do
		if (v.x >= x-1) and (v.x <= x+1) and (v.y >= y-1) and (v.y <= y+1) then
			count = count + 1
		end
	end
	
	return count
end

function ismine(x,y)
	local yeah = false
	for _, v in ipairs(board.mines) do
		if v.x == x and v.y == y then
			yeah = true
		end
	end
	return yeah
end

function revealtile(x,y,safe)
	if x<1 or y<1 or x>board.width or y>board.height then return end
	local t = board.tiles[y][x]
	if t then
		-- if t == "marked" then
			-- table.remove(board.tiles[y],x)
		-- end
		return
	end
	
	local fucked = ismine(x,y)
	
	if fucked then
		if not safe then tile(x,y,"x") end
	else
		count = checktile(x,y)
		tile(x,y,count)
		if count == 0 then
			revealtile(x-1, y-1)
			revealtile(x,   y-1)
			revealtile(x+1, y-1)
			revealtile(x-1, y)
			revealtile(x+1, y)
			revealtile(x-1, y+1)
			revealtile(x,   y+1)
			revealtile(x+1, y+1)
		end
	end
end

function cleanneighbors(ox,oy)
	revealtile(ox,oy)
	if board.tiles[oy][ox] == "x" then
		newgame()
		cleanneighbors(ox,oy)
		return
	end
	for x=ox-1, ox+1 do
		for y=oy-1, oy+1 do
			if not (x==ox and y==oy) then 
				revealtile(x,y,true)
				if board.tiles[y][x] == 0 then
					newgame()
					cleanneighbors(ox,oy)
					return
				end
			end
		end
	end
end

function chord(ox, oy)
	local flags = 0
	if board.tiles[oy][ox] and type(board.tiles[oy][ox]) == "number" and board.tiles[oy][ox] > 0 then
		for x=ox-1, ox+1 do
			for y=oy-1, oy+1 do
				if board.tiles[y] and not (x==ox and y==oy) then
					if board.tiles[y][x] == "marked" then flags = flags + 1 end
				end
			end
		end
	else
		return false
	end
	
	if flags == board.tiles[oy][ox] then
		revealtile(ox-1, oy-1)
		revealtile(ox,   oy-1)
		revealtile(ox+1, oy-1)
		revealtile(ox-1, oy)
		revealtile(ox+1, oy)
		revealtile(ox-1, oy+1)
		revealtile(ox,   oy+1)
		revealtile(ox+1, oy+1)
	else
		return false
	end
	
	return true
end

function click(mx, my, butt)
	local inboard = (mx >= board.x) and (mx < board.x+board.width*board.grid) and (my >= board.y) and (my < board.y+board.height*board.grid)
	if inboard then
		x = math.floor((mx-board.x)/board.grid)+1
		y = math.floor((my-board.y)/board.grid)+1
		if butt == 2 or love.keyboard.isDown("rctrl") or love.keyboard.isDown("lctrl") then
			if board.tiles[y][x] == "marked" then
				tile(x,y,nil)
				markedcount = markedcount - 1
			elseif board.tiles[y][x] == nil or board.tiles[y][x] == "x" then
				tile(x,y,"marked")
				markedcount = markedcount + 1
				playsound("assets/snd/mark.wav")
				if markedcount == #board.mines then
					local wincondition = true
					for i,v in ipairs(board.mines) do
						if board.tiles[v.y][v.x] ~= "marked" then
							wincondition = false
						end
					end
					if wincondition then
						playsound("assets/snd/windchimes.wav")
					end
				end
			end
		elseif butt == 1 then
			if board.tiles[y][x] == nil then
				if isempty() then
					repeat
						newgame()
						revealtile(x,y)
					until (board.tiles[y][x] == 0 or board.tiles[y][x] == 8) or (board.tiles[y][x] ~= "x" and desperatestart)
					if board.tiles[y][x] ~= 0 then
						cleanneighbors(x,y)
					end
				end
				revealtile(x,y)
				if board.tiles[y][x] == "x" then
					playsound("assets/snd/WEAP1000.wav")
				else
					playsound("assets/snd/click.wav")
				end
			end
		elseif butt == 3 or love.keyboard.isDown("rshift") or love.keyboard.isDown("lshift") then
			if board.tiles[y][x] then
				if chord(x,y) == true then
					local oops = false
					
					for tx=x-1, x+1 do
						for ty=y-1, y+1 do
							if board.tiles[ty] and not (tx==x and ty==y) then
								if board.tiles[ty][tx] == "x" then
									oops = true
								end
							end
						end
					end
					
					if oops then
						playsound("assets/snd/WEAP1000.wav")
					else
						playsound("assets/snd/click.wav")
					end
				end
			end
		end
	end
end

function love.mousepressed(x, y, butt)
	click(x/screen.scale,y/screen.scale,butt)
end

function love.update(dt)
	
end

function love.keypressed(key)
	if key == "escape" then love.event.quit() end
	if key == "f6" then debug.debug() end
	if key == "f11" then toggleFullscreen() end
	if key == "q" then
		desperatestart = not desperatestart
	end
	if key == "w" then
		newgame()
	end
	if key == "0" then
		for x = 1, board.width do
			for y = 1, board.height do
				board.tiles[y][x] = nil
				revealtile(x,y)
				markedcount = 0
			end
		end
	end
	if key == "z" then click(mouseX(), mouseY(), 1) end
	if key == "x" then click(mouseX(), mouseY(), 2) end
	if key == "c" then click(mouseX(), mouseY(), 3) end
end

function love.draw()
	love.graphics.setCanvas(screen.canvas)
	love.graphics.clear({.75,.75,.75})

	love.graphics.setColor(1,1,1)
	for x = 1, board.width do
		for y = 1, board.height do
			local tex
			if board.tiles[y] and board.tiles[y][x] then tex = board.tiles[y][x] end
			love.graphics.draw(textures[tex] or textures[-1],(x-1)*board.grid + board.x, (y-1)*board.grid + board.y)
		end
	end
	love.graphics.setColor(0,0,0)
	love.graphics.print("Flags: "..(#board.mines-markedcount))
	love.graphics.setCanvas()
	love.graphics.setColor(1,1,1)
	love.graphics.scale(screen.scale)
	love.graphics.draw(screen.canvas)
end