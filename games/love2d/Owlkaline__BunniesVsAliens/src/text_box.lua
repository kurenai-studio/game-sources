TextBox = {}
TextBox.__index = TextBox

local MaxWidthWrapping = 400;

function TextBox.new(x, y, font, title, text, text_colour, background_colour, wrapping_width)
  local new_text_box = setmetatable({}, TextBox)
  new_text_box.x = x;
  new_text_box.y = y;
  new_text_box.title = title
  new_text_box.description = text;
  new_text_box.title_height = PressStartFontBig:getHeight(title);
  new_text_box.background_colour = background_colour;
  new_text_box.text_colour = text_colour;

  new_text_box.max_warp = MaxWidthWrapping;
  if wrapping_width then
    new_text_box.max_warp = wrapping_width
  end

  local text_width = font:getWidth(title);
  local text_height = new_text_box.title_height;

  local width, lines = font:getWrap(text, MaxWidthWrapping);
  text_width = width;
  for i, line in ipairs(lines) do
    text_height = text_height + font:getHeight(line);
  end

  new_text_box.background_width = text_width;
  new_text_box.background_height = text_height;

  new_text_box.should_draw = false;

  new_text_box.x = new_text_box.x; --+ new_text_box.background_width * 0.33

  return new_text_box
end

function TextBox:update()
  self.should_draw = false;
end

function TextBox:draw_text(camera)
  if not self.should_draw then
    return;
  end

  local padding = 4;

  local x = self.x * camera.scale;
  local y = self.y * camera.scale;
  love.graphics.setColor(self.background_colour);
  love.graphics.rectangle("fill", x, y, self.background_width + padding,
    self.background_height + padding);
  love.graphics.setColor(self.text_colour);


  love.graphics.setFont(PressStartFontBig)
  love.graphics.printf(self.title, x + padding, y + padding, MaxWidthWrapping);

  love.graphics.setFont(PressStartFont)
  love.graphics.printf(self.description, x + padding, y + padding + self.title_height, self.max_warp)

  love.graphics.setColor(1, 1, 1, 1);
end
