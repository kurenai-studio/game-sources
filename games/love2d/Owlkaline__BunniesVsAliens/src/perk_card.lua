require('text_box')

local perk_cards = {};

local card_width = 114;

function perk_cards.new(index, font, texture)
  local new_card = setmetatable({}, { __index = perk_cards })
  new_card.x = 112 + (141 * index);
  new_card.y = 163;
  new_card.highlight_x = 62 + 141 * index;
  new_card.highlight_y = 113;
  new_card.text_x = 122 + 141 * index;
  new_card.text_y = 175;
  new_card.texture = texture;
  new_card.highlight = Textures.ui_perk_hover;
  new_card.perk_index = nil
  new_card.hover_should_draw = false;
  new_card.text = TextBox.new(0, 0, PressStartFont, "", "", 0.0)

  table.insert(perk_cards, new_card)
end

function perk_cards.mouse_clicked(x, y, button)
  for _, card in ipairs(perk_cards) do
    if card.perk_index then
      local frame_box = {
        x = card.x,
        y = card.y,
        width = card.texture:getWidth(),
        height = card.texture:getHeight(),
      };

      if check_point_in_rect(x, y, frame_box) then
        -- Select perk and upgrade it
        Perks[card.perk_index]:upgrade();
        -- hide everything
        for _, card2 in ipairs(perk_cards) do
          card2.perk_index = nil;
        end
        GameSpeed = 1
        return
      end
    end
  end
end

function perk_cards.update(camera, dt)
  local mx, my = love.mouse.getPosition()
  mx = mx / camera.scale;
  my = my / camera.scale;
  for _, card in ipairs(perk_cards) do
    card.text:update();
    if card.perk_index then
      card.hover_should_draw = false;

      card.text.should_draw = true;
      local box = {
        x = card.x,
        y = card.y,
        width = card.texture:getWidth(),
        height = card.texture:getHeight(),
      };
      if check_point_in_rect(mx, my, box) then
        card.hover_should_draw = true;
      end
    end
  end
end

function perk_cards:set_perk_index(camera, idx)
  self.perk_index = idx;
  local title, description, current = Perks[self.perk_index]:get_perk_details();
  local next_level = Perks[self.perk_index].percent_at_level(Perks[self.perk_index].level + 1);

  self.text = TextBox.new(self.text_x, self.text_y, PressStartFont, title,
    "\n\n" .. string.gsub(description, "X", string.format("%.2f", next_level)) .. "\n" .. current,
    { 0.1, 0.1, 0.1, 1.0 },
    { 0, 0, 0, 0 }, card_width * camera.scale)
end

function perk_cards.draw()
  for _, card in ipairs(perk_cards) do
    if card.perk_index then
      if card.hover_should_draw then
        love.graphics.draw(card.highlight, card.highlight_x, card.highlight_y)
      end
      love.graphics.draw(card.texture, card.x, card.y)
    end
  end
end

function perk_cards.draw_text(camera)
  for _, card in ipairs(perk_cards) do
    if card.perk_index then
      card.text:draw_text(camera);
    end
    --  love.graphics.draw(
    --    card.cost.text,
    --    card.cost.x * camera.scale,
    --    card.cost.y * camera.scale
    --  )
    --end

    --for _, card in ipairs(cards) do
    --  card.text_info:draw_text(camera);
  end
end

return perk_cards;
