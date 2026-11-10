function love.conf(t)
  t.window.width = 1280
  t.window.height = 720

  t.version = "11.5"
  t.console = false
  t.gammacorrect = false
  t.window.icon = 'assets/alien.png'
  t.window.highdpi = false

  t.modules.audio = false
  t.modules.sound = false
  t.modules.joystick = false
  t.modules.physics = false
end
