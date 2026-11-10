require('text_box')

local cards = {};


function cards.new(index, font, texture, card_type)
  local new_card = setmetatable({}, { __index = cards })
  new_card.x = 64 + (59 * index);
  new_card.y = 2;
  new_card.texture = texture;
  new_card.frame = Textures.ui_card_frame;
  new_card.info = Textures.ui_card_info;
  new_card.type = card_type;
  new_card.cost = {
    x = 71 + 59 * index,
    y = 48,
    icon_x = 95 + 59 * index,
    icon_y = 45,
    info_x = 100 + 59 * index,
    info_y = 5,
    text = love.graphics.newText(font,
      { { 0.12, 0.13, 0.20 }, "" .. card_type }
    ),
  }

  new_card.text_info = {}

  local tooltip_x = new_card.cost.info_x + new_card.info:getWidth();
  local tooltip_y = new_card.cost.info_y + new_card.info:getHeight();

  local description = GetBunnyDescription(new_card.type)
  local title = GetBunnyTitle(new_card.type)
  local life = GetBunnyLife(new_card.type);
  local damage = GetBunnyDamage(new_card.type);
  local action = GetBunnyAction(new_card.type);
  local action2 = GetBunnyAction2(new_card.type);
  description =
      string.gsub(
        string.gsub(
          string.gsub(
            string.gsub(description,
              'LIFE', life),
            'ACTION', action),
          'DAMAGE', damage),
        'ACTION2', action2)
  new_card.text_info = TextBox.new(tooltip_x, tooltip_y, font, title, description, { 1, 1, 1, 1 }, { 0.1, 0.1, 0.1, 0.8 })
  if new_card.type == BunnyType.Dandelion then
    new_card.cost.text:set({ { 0.12, 0.13, 0.20 }, "" .. DandelionCost })
  end

  if not new_card.text_info then
    print("Error: text_info is not initialized for card:", new_card.type) -- Debug log
  end

  table.insert(cards, new_card)
end

function cards.mouse_clicked(x, y, button)
  for _, card in ipairs(cards) do
    local frame_box = {
      x = card.x,
      y = card.y,
      width = card.frame:getWidth(),
      height = card.frame:getHeight(),
    };

    if check_point_in_rect(x, y, frame_box) then
      SelectedBunny = card.type;
    end
  end
end

function cards.update(camera, dt)
  local mx, my = love.mouse.getPosition()
  mx = mx / camera.scale;
  my = my / camera.scale;
  for _, card in ipairs(cards) do
    card.text_info:update();
    local box = {
      x = card.cost.info_x,
      y = card.cost.info_y,
      width = card.info:getWidth(),
      height = card.info:getHeight(),
    };
    if check_point_in_rect(mx, my, box) then
      card.text_info.should_draw = true;
    end
  end
end

function cards.draw(dandelion_handler)
  for _, card in ipairs(cards) do
    local cost = card.type;
    if card.type == BunnyType.Dandelion then
      cost = DandelionCost;
      card.cost.text:set({ { 0.12, 0.13, 0.20 }, "" .. cost })
    end

    if dandelion_handler.total < cost then
      love.graphics.setColor(0.6, 0.6, 0.6);
    end
    love.graphics.draw(card.frame, card.x, card.y)
    love.graphics.draw(card.texture, card.x + 2, card.y + 2)

    love.graphics.draw(Textures.ui_dandelion_cost_icon, card.cost.icon_x, card.cost.icon_y)
    love.graphics.draw(card.info, card.cost.info_x, card.cost.info_y)

    if dandelion_handler.total < cost then
      love.graphics.setColor(1, 1, 1);
    end
  end
end

function cards.draw_text(camera)
  for _, card in ipairs(cards) do
    love.graphics.draw(
      card.cost.text,
      card.cost.x * camera.scale,
      card.cost.y * camera.scale
    )
  end

  for _, card in ipairs(cards) do
    card.text_info:draw_text(camera);
  end
end

return cards;
