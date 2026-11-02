function love.conf(t)
	t.window.title      = "Game States Example"
	t.identity = "gsExample"
	t.version  = "11.5"
	t.console  = false
	t.window.width = 640
	t.window.height = 480
	t.window.minwidth = 640
	t.window.minheight = 480
	t.window.resizable  = false
	t.window.borderless = false
	t.window.fullscreen = false
	t.window.fullscreentype = "exclusive"
	t.window.display = 1  
	t.window.vsync      = 1
	
	-- For HiDPI screens
	t.window.highdpi = true
	t.window.usedpiscale = true
	
	-- Disabling modules this game doesn't use
	t.modules.audio = false
	t.modules.image = false
	t.modules.mouse = false
	t.modules.physics = false 
	t.modules.sound = false  
	t.modules.system = false 
	t.modules.thread = false
	t.modules.touch = false
	t.modules.video = false
end