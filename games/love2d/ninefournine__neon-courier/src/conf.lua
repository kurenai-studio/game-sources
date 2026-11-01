function love.conf(t)
  t.identity = 'neon-courier-v1'
  t.version = '11.5'
  t.console = false
  t.window.title = 'NEON COURIER / Night Dispatch'
  t.window.width, t.window.height = 640, 480
  t.window.resizable = true
  t.window.minwidth, t.window.minheight = 320, 240
  t.window.vsync = 1
  t.window.msaa = 0
  t.modules.physics = false
  t.modules.video = false
end
