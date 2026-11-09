"""The screens, driven like a player would: keys and clicks through menus, pause, shop, settings and guide."""

import pygame

from app import config
from app.scenes.confirm import ConfirmScene
from app.scenes.game_over import CARD_DELAY, GameOverScene
from app.scenes.guide import GuideScene
from app.scenes.main_menu import MainMenuScene
from app.scenes.pause import PauseScene
from app.scenes.play import PlayScene
from app.scenes.settings import SettingsScene
from app.scenes.shop import ShopScene
from app.theme.palette import ACCENTS, PALETTE, danger_color
from helpers import calm, click, frames, press


def start(game):
    game.start_run()
    calm(game.world)
    frames(game, 0.5)
    return game.world


def test_the_game_opens_on_the_main_menu(game):
    assert isinstance(game.scene, MainMenuScene)
    press(game, "return")                               # Play is focused first
    assert isinstance(game.scene, PlayScene) and game.in_run


def test_pausing_freezes_the_run(game):
    world = start(game)
    press(game, "escape")
    assert isinstance(game.scene, PauseScene)
    time = world.survival_time
    frames(game, 1.0)
    assert world.survival_time == time
    press(game, "escape")
    assert isinstance(game.scene, PlayScene)


def test_esc_still_pauses_when_pause_is_on_another_key(game):
    game.settings.bind("pause", "p")
    start(game)
    press(game, "escape")
    assert isinstance(game.scene, PauseScene)
    press(game, "p")
    assert isinstance(game.scene, PlayScene)


def test_ending_a_run_from_pause_asks_first(game):
    world = start(game)
    world.coins_picked = 9
    press(game, "escape")
    press(game, "r")
    assert isinstance(game.scene, ConfirmScene)
    press(game, "return")                               # Cancel is focused: the safe choice
    assert isinstance(game.scene, PauseScene) and game.world is world
    press(game, "r")
    game.scene.buttons.buttons[1].activate()            # confirm
    assert isinstance(game.scene, PlayScene) and game.world is not world
    assert game.profile.coins >= 9, "the coins of the abandoned run are kept"


def test_play_again_follows_its_key_binding(game):
    start(game)
    game.settings.bind("restart", "t")
    game.end_run()
    assert isinstance(game.scene, GameOverScene)
    frames(game, CARD_DELAY + 0.5)
    press(game, "t")
    assert isinstance(game.scene, PlayScene)


def test_the_shop_buys_and_sells_with_keys_and_clicks(game):
    game.profile.coins = 1000
    game.open_shop()
    shop = game.scene
    assert isinstance(shop, ShopScene) and shop.group.focus == 0      # Swift Boots
    press(game, "return")
    press(game, "=")
    assert game.profile.level("boots") == 2
    press(game, "delete")
    assert game.profile.level("boots") == 1
    click(game, shop.cards[0].rect.center, button=3)                   # right click sells
    assert game.profile.level("boots") == 0 and game.profile.coins == 1000


def test_the_shop_explains_why_you_cannot_buy(game):
    game.open_shop()
    press(game, "return")
    assert "Not enough coins" in game.scene.message


def test_reset_to_defaults_needs_a_second_click(game):
    game.settings.bind("shield", "z")
    game.open_settings()
    settings = game.scene
    assert isinstance(settings, SettingsScene)
    settings.reset_button.activate()
    assert game.settings.keybinds["shield"] == "z", "the first click only asks"
    settings.reset_button.activate()
    assert game.settings.keybinds["shield"] == "q"


def test_rebinding_a_key_in_settings(game):
    game.open_settings()
    settings = game.scene
    shield_row = settings.rows[0]
    click(game, shield_row.rect.center)
    assert settings.waiting_for == "shield"
    press(game, "z")
    assert game.settings.keybinds["shield"] == "z" and settings.waiting_for is None


def test_the_accent_changes_the_interface_but_not_the_danger_bar(game):
    calm_color = danger_color(0.0)
    game.settings.options["accent"] = "Gold"
    game.apply_settings()
    assert PALETTE.accent == ACCENTS["Gold"] and danger_color(0.0) == calm_color


def test_the_guide_jumps_between_sections(game):
    game.open_guide()
    guide = game.scene
    assert isinstance(guide, GuideScene)
    titles = [tab.label for tab in guide.section_tabs]
    assert {"Basics", "Difficulty", "Controls", "Tips"} <= set(titles)
    press(game, "down")
    frames(game, 1.0)
    assert guide.current_section == 1
    press(game, "escape")
    assert isinstance(game.scene, MainMenuScene)


def test_tooltips_show_during_a_run(game):
    world = start(game)
    groups = game.hud.slot_groups(world)
    bar, rects = game.hud.bar_layout(groups)
    hovered = game.hud.hovered(world, [*world.loadout, world.powerup_slot], groups, rects, bar, rects[0].center)
    assert hovered and hovered[0] is world.loadout[0].skill
    assert game.hud.hovered(world, [*world.loadout, world.powerup_slot], groups, rects, bar, (5, 5)) is None


def test_screens_fade_into_each_other(game, monkeypatch):
    monkeypatch.setattr(config, "SCENE_FADE_TIME", 0.15)
    game.draw()
    game.open_settings()
    game.draw()
    assert game.fade_time > 0
    frames(game, 0.2)
    assert game.fade_time == 0


def test_every_screen_draws(game):
    """A smoke test: drawing each screen once must not fail."""
    for open_screen in (game.open_shop, game.open_settings, game.open_guide, game.open_main_menu):
        open_screen()
        game.draw()
    start(game)
    game.draw()
    press(game, "escape")
    game.draw()
    game.end_run()
    frames(game, CARD_DELAY + 0.5)
    game.draw()
    assert pygame.display.get_surface() is game.screen
