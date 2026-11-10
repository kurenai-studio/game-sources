-- Window / project configuration for the Space Invaders clone (LÖVE 11.x)
function love.conf(t)
  t.title    = "Space Invaders"
  t.identity = "space-invaders-clone"
  t.version  = "11.4"

  t.window.width     = 800
  t.window.height    = 600
  t.window.vsync     = 1
  t.window.resizable = false
end
