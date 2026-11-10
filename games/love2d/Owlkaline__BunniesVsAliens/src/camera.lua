local camera = {
  x = 0,
  y = 0,
  scale = 1,
  rotation = 0,
  subpixels = 2,
  integer_scaling = true
}

function camera:safeScale()
  local _, _, windowWidth, windowHeight = love.window.getSafeArea()
  local canvasWidth, canvasHeight = Canvas:getDimensions()

  -- Fill as much of the window as possible with the canvas while preserving the aspect ratio.
  self.scale = math.min(windowWidth / canvasWidth, windowHeight / canvasHeight)
  -- self.scale = windowHeight / canvasHeight -- This would fill the height and possibly cut off the sides.

  if self.integer_scaling then
    self.scale = math.floor(self.scale * self.subpixels) / self.subpixels
    self.scale = math.max(self.scale, 1 / self.subpixels) -- Avoid self.scale =0 if the window is tiny!
  end

  self.scaledWidth = canvasWidth * self.scale
  self.scaledHeight = canvasHeight * self.scale

  -- center canvas
  self.x = (math.floor((windowWidth - self.scaledWidth) / 2))
  self.y = (math.floor((windowHeight - self.scaledHeight) / 2))
end

function camera.followEntity(entity)
  camera.x = entity.x - Canvas:getWidth() / 2
  camera.y = entity.y - Canvas:getHeight() / 2
end

function camera.move(dx, dy)
  camera.x = camera.x + dx
  camera.y = camera.y + dy
end

function camera.setScale(scale)
  camera.scale = scale
end

return camera
