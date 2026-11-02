function love.conf(t)
  t.identity = "kindred-lights"
  t.version = "11.5"
  t.window.title = "Kindred Lights"
  t.window.width = 1280
  t.window.height = 720
  t.window.resizable = true
  t.window.minwidth = 640
  t.window.minheight = 360
  t.window.vsync = 1
  t.window.msaa = 4
  t.window.highdpi = false
  t.modules.joystick = false
  t.modules.physics = false
  t.modules.video = false
end
