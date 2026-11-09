function love.conf(t)
	t.identity = "orbita84"
	t.version = "11.4"
	t.window.title = "Orbita 84"
	t.window.width = 640
	t.window.height = 480
	t.window.resizable = true
	t.window.vsync = os.getenv("ORBITA_CAPTURA") and 0 or 1
	t.modules.physics = false
	t.modules.video = false
end
