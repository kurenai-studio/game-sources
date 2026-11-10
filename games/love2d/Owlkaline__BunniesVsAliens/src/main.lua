require('map')
local wave = require('wave')
local camera = require('camera')
local aliens = require('aliens')
local bunnies = require('bunnies')
local balls = require('balls')
local dandelion_handler = require('dandelion_handler')
local dandelions = require('dandelions')
local cards = require('cards')
local ghosts = require('ghosts')
local perks = require('perks')
local perk_cards = require('perk_card')
local game_over_screen = require('gameover')

GameState = {
  MainMenu = 0,
  Game = 1,
  GameOver = 2,
}

CurrentGameState = GameState.MainMenu;

DandelionCost = 0
GameSpeed = 1.0;

BunnyType = {
  None = 0,
  Dandelion = 10,
  White = 50,
  Pyon = 100,
  Gameboy = 200,
}

local function bunny_cost(selected_bunny)
  if selected_bunny == BunnyType.Dandelion then
    return DandelionCost
  else
    return selected_bunny
  end
end

SelectedBunny = BunnyType.None;

Textures = {
  bunny = {},
  alien = {},
  alien_attack = {},
  floor_background = {},
  ui_background = {},
  ball = {},

  dandelion = {},
  white_bunny = {},
  pyon_bunny = {},
  gameboy_bunny = {},
  gameboy_ball = {},
  gameboy_alien = {},

  shadow_dandelion = {},
  shadow_white_bunny = {},
  shadow_pyon_bunny = {},
  shadow_gameboy_bunny = {},

  ghost_dandelion = {},
  ghost_white_bunny = {},
  ghost_pyon_bunny = {},
  ghost_gameboy_bunny = {},

  dandelion_floating = {},

  ui_dandelion_icon = {},      -- pos 6, 2
  ui_dandelion_cost_icon = {}, -- pos
  ui_counter_box = {},         -- pos 8, 39
  ui_bunny_frame = {},
  ui_card_frame = {},
  ui_card_info = {},
  ui_dandelion_card = {},

  ui_perk_card = {},
  ui_perk_hover = {},

  main_menu = {},

  game_over_alien = {},
  game_over_alien_attack = {},
  game_over_earth = {},
  game_over_text = {},
}

function love.load()
  love.graphics.setLineStyle("rough")
  love.graphics.setDefaultFilter("nearest", "nearest", 1)
  love.graphics.setLineStyle("rough")

  PressStartFont = love.graphics.newFont("assets/font/PressStart2P-Regular.ttf")
  PressStartFont:setFilter("nearest", "nearest")
  love.graphics.setFont(PressStartFont)
  dandelion_handler:load(PressStartFont)

  PressStartFontBig = love.graphics.newFont("assets/font/PressStart2P-Regular.ttf", 16);
  PressStartFont:setFilter("nearest", "nearest")


  PressStartFontBigBig = love.graphics.newFont("assets/font/PressStart2P-Regular.ttf", 32);
  PressStartFont:setFilter("nearest", "nearest")

  Canvas = love.graphics.newCanvas(640.0, 360.0)
  --Canvas = love.graphics.newCanvas(320.0, 180.0)
  Canvas:setFilter("nearest", "nearest")

  love.window.setMode(1280.0, 720.0)
  love.window.setTitle("Bunnies Vs Aliens")

  camera:safeScale()

  Textures.bunny = love.graphics.newImage("assets/white-bunny.png")
  Textures.alien = love.graphics.newImage("assets/alien.png")
  Textures.shadow_alien = love.graphics.newImage("assets/shadow-alien.png")
  Textures.alien_attack = love.graphics.newImage("assets/alien-attack.png")
  Textures.ui_background = love.graphics.newImage("assets/ui-background.png")
  Textures.floor_background = love.graphics.newImage("assets/background.png")
  Textures.ball = love.graphics.newImage("assets/ball.png")
  Textures.ball_shadow = love.graphics.newImage("assets/shadow-ball.png")

  Textures.dandelion = love.graphics.newImage("assets/dandelion-plant-shadow.png")
  Textures.white_bunny = love.graphics.newImage("assets/white-bunny-shadow.png")
  Textures.pyon_bunny = love.graphics.newImage("assets/pyon-bunny-shadow.png")
  Textures.gameboy_bunny = love.graphics.newImage("assets/gameboy-bunny-shadow.png")
  Textures.gameboy_ball = love.graphics.newImage("assets/gameboy-ball.png")
  Textures.gameboy_alien = love.graphics.newImage("assets/gameboy-alien.png")

  Textures.ghost_dandelion = love.graphics.newImage("assets/ghost-dandelion.png")
  Textures.ghost_white_bunny = love.graphics.newImage("assets/ghost-white-bunny.png")
  Textures.ghost_pyon_bunny = love.graphics.newImage("assets/ghost-pyon-bunny.png")
  Textures.ghost_gameboy_bunny = love.graphics.newImage("assets/ghost-gameboy-bunny.png")

  Textures.dandelion_floating = love.graphics.newImage("assets/dandelion-item.png")
  Textures.ui_dandelion_icon = love.graphics.newImage("assets/dandelion-menu-big.png")
  Textures.ui_dandelion_cost_icon = love.graphics.newImage("assets/dandelion-unit.png")
  Textures.ui_counter_box = love.graphics.newImage("assets/ui-dandelion-counter-button.png")
  Textures.ui_card_frame = love.graphics.newImage("assets/ui-card.png")
  Textures.ui_card_info = love.graphics.newImage("assets/card-info.png")
  Textures.ui_dandelion_card = love.graphics.newImage("assets/card-dandelion.png")
  Textures.ui_gameboy_card = love.graphics.newImage("assets/card-gameboy-bunny.png")
  Textures.ui_pyon_card = love.graphics.newImage("assets/card-pyon-bunny.png")
  Textures.ui_white_card = love.graphics.newImage("assets/card-white-bunny.png")

  Textures.ui_perk_card = love.graphics.newImage("assets/ui-upgrade-card.png")
  Textures.ui_perk_hover = love.graphics.newImage("assets/ui-upgrade-card-selection-effect.png")

  Textures.main_menu = love.graphics.newImage("assets/title-screen.png")
  Textures.game_over_alien = love.graphics.newImage("assets/gameover-alien.png")
  Textures.game_over_alien_attack = love.graphics.newImage("assets/gameover-alien-attack.png")
  Textures.game_over_earth = love.graphics.newImage("assets/gameover-earth.png");
  Textures.game_over_text = love.graphics.newImage("assets/gameover-text.png");
  Textures.game_over_background = love.graphics.newImage("assets/gameover-background.png");

  cards.new(0, PressStartFont, Textures.ui_dandelion_card, BunnyType.Dandelion)
  cards.new(1, PressStartFont, Textures.ui_white_card, BunnyType.White)
  cards.new(2, PressStartFont, Textures.ui_pyon_card, BunnyType.Pyon)
  cards.new(3, PressStartFont, Textures.ui_gameboy_card, BunnyType.Gameboy)

  perk_cards.new(0, PressStartFont, Textures.ui_perk_card)
  perk_cards.new(1, PressStartFont, Textures.ui_perk_card)
  perk_cards.new(2, PressStartFont, Textures.ui_perk_card)

  game_over_screen.load(camera)

  dandelions.load();

  math.randomseed(os.time())
  Map:load(camera)
  wave = wave.new(PressStartFont);
end

function love.keypressed(key)
  if CurrentGameState == GameState.MainMenu then
    if key ~= "" then
      CurrentGameState = GameState.Game;
    end
  end

  if CurrentGameState ~= GameState.Game then
    return
  end

  -- In game controls
  if key == "p" then
    if GameSpeed == 0 then
      GameSpeed = 1
    else
      GameSpeed = 0
    end
  end

  if key == '1' then
    SelectedBunny = BunnyType.Dandelion
  end
  if key == '2' then
    SelectedBunny = BunnyType.White
  end
  if key == '3' then
    SelectedBunny = BunnyType.Pyon
  end
  if key == '4' then
    SelectedBunny = BunnyType.Gameboy
  end
end

function love.mousepressed(x, y, button, istouch, presses)
  if CurrentGameState == GameState.MainMenu then
    if button ~= 0 then
      CurrentGameState = GameState.Game;
    end
  end

  if CurrentGameState ~= GameState.Game then
    return
  end

  x = x / camera.scale;
  y = y / camera.scale;

  cards.mouse_clicked(x, y, button)
  perk_cards.mouse_clicked(x, y, button)

  if button == 1 and SelectedBunny ~= BunnyType.None and dandelion_handler.total >= bunny_cost(SelectedBunny) then
    if not Map:is_grid_filled_at_xy(x, y) then
      dandelion_handler:spend_dandelions(bunny_cost(SelectedBunny))
      local grid_x, grid_y = Map:get_grid_location_from_xy(x, y)
      bunnies.spawn(grid_x, grid_y, SelectedBunny)
      SelectedBunny = BunnyType.None;
    end
  end
  if button == 2 then
    SelectedBunny = BunnyType.None
    --GameSpeed = GameSpeed + 1
    --if GameSpeed > 50 then
    --  GameSpeed = 1
    --end
  end
end

function love.update(dt)
  if CurrentGameState == GameState.GameOver then
    game_over_screen.update(dt)
  end

  if CurrentGameState ~= GameState.Game then
    return
  end

  perk_cards.update(camera, dt)

  for i = 1, math.ceil(dt / 0.01) do
    dt = 0.01
    for i = 1, GameSpeed do
      aliens.update(bunnies, dt)
      bunnies.update(aliens, balls, dandelions, dt);
      balls.update(aliens, dt)
      dandelions.update(dandelion_handler, camera, dt);
      wave:update(camera, aliens, perk_cards, dt)
    end
  end

  cards.update(camera, dt)
end

local function draw_ui()
  if CurrentGameState == GameState.GameOver then
    game_over_screen.draw_ui();
  end

  if CurrentGameState == GameState.MainMenu then
    love.graphics.draw(Textures.main_menu, 0, 0)
  end

  if CurrentGameState == GameState.Game then
    love.graphics.draw(Textures.ui_background, 0, 0)

    love.graphics.draw(Textures.ui_dandelion_icon, 6, 2)
    love.graphics.draw(Textures.ui_counter_box, 8, 39)

    cards.draw(dandelion_handler);
    perk_cards.draw();
  end
end

local function draw_text()
  if CurrentGameState == GameState.GameOver then
    game_over_screen.draw_text(camera, wave);
  end

  if CurrentGameState == GameState.MainMenu then
    love.graphics.setFont(PressStartFontBigBig)
    love.graphics.print("Click to start", 208 * camera.scale, 316 * camera.scale);
    love.graphics.setFont(PressStartFont)
  end

  if CurrentGameState == GameState.Game then
    dandelion_handler:draw(camera);
    cards.draw_text(camera)
    perk_cards.draw_text(camera)
    wave:draw(camera);
  end
end

function love.draw()
  love.graphics.setCanvas(Canvas);
  love.graphics.clear()
  --love.graphics.scale(4)
  love.graphics.push()

  -- Translate and scale the camera
  --love.graphics.scale(camera.scale)
  if CurrentGameState == GameState.GameOver then
    game_over_screen.draw();
  end
  if CurrentGameState == GameState.Game then
    Map:draw();

    love.graphics.setColor(1, 1, 1)
    bunnies.draw();
    balls.draw();
    aliens.draw()
    dandelions.draw();
    ghosts.draw(camera);
  end

  -- Draw game here

  love.graphics.pop()

  love.graphics.push();
  love.graphics.setCanvas()
  love.graphics.translate(-camera.x, -camera.y)
  love.graphics.scale(camera.scale)
  love.graphics.draw(Canvas)

  -- Draw Ui here
  draw_ui();
  love.graphics.pop();
  draw_text();
end

function TableContains(tbl, value)
  for _, v in ipairs(tbl) do
    if v == value then
      return true -- The value exists in the table
    end
  end
  return false -- The value does not exist in the table
end
