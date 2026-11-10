local dandelion_handler = {
  total = 10,
  text = {}
}

function dandelion_handler:load(font)
  DandelionText = love.graphics.newText(font,
    { { 0.12, 0.13, 0.20 }, "" .. self.total }
  );
end

function dandelion_handler:add_dandelions(value)
  dandelion_handler.total = dandelion_handler.total + value;
  self:update_text();
end

function dandelion_handler:spend_dandelions(value)
  dandelion_handler.total = dandelion_handler.total - value;
  self:update_text();
end

function dandelion_handler:update_text()
  DandelionText:set({ { 0.12, 0.13, 0.20 }, "" .. dandelion_handler.total })
end

function dandelion_handler:draw(camera)
  love.graphics.draw(
    DandelionText,
    (8 + Textures.ui_counter_box:getWidth() * 0.5) * camera.scale - DandelionText:getWidth() * 0.5 - 1,
    (39 + Textures.ui_counter_box:getHeight() * 0.5) * camera.scale - DandelionText:getHeight() * 0.5 - 1
  )
end

return dandelion_handler;
