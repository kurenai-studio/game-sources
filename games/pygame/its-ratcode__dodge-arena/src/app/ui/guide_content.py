"""The text of the in-game guide.

Every number comes from ``config`` (or the upgrade table) and every key from
the player's settings, so the guide can never disagree with the game.
"""

from app import config
from app.core.settings import MOVE_BUTTONS, Settings
from app.progression.upgrades import UPGRADE_BY_ID, UPGRADES, RunStats, second_wind_cooldown
from app.ui.document import Bullets, Entry, KeyList, Paragraph, Section, Subheading, Table
from app.util.keys import key_label


def sec(value: float) -> str:
    return f"{value:g} s"


def pct(value: float) -> str:
    return f"{value * 100:.0f}%"


def mine(base: float, yours: float, unit: str) -> str:
    """ "1.5 s", or "1.5 s (yours 2.1 s)" once upgrades change it."""
    if abs(base - yours) < 1e-9:
        return f"{base:g}{unit}"
    return f"{base:g}{unit} (yours {yours:g}{unit})"


def build_guide(settings: Settings, levels: dict[str, int] | None = None) -> list[Section]:
    """The guide's text, with your key bindings and, where upgrades change a number, your own value."""
    levels = levels or {}
    stats = RunStats.from_levels(levels)
    key = {action: key_label(name) for action, name in settings.keybinds.items()}
    move = MOVE_BUTTONS[settings.move_button].lower()
    ramp_minutes = config.DANGER_RAMP_TIME / 60

    def ability_cooldown(base: float) -> str:
        return mine(base, round(base * stats.cooldown_mult, 2), " s")

    return [
        Section("Basics", [
            Paragraph(f"Survive as long as you can. Use {move} to walk to a point, or hold it to keep "
                      f"following the cursor. One hit ends the run."),
            Subheading("Moving"),
            Bullets([
                f"Use {move} anywhere to walk there in a straight line at a steady "
                f"{mine(config.PLAYER_SPEED, round(stats.player_speed), ' px/s')}. You stop exactly where you "
                f"clicked.",
                f"Hold {move} to keep following the cursor.",
                "A green marker shows where you clicked, and a dotted line shows your path "
                "(Settings > Display > Movement path).",
                "You can't leave the arena: a click outside it walks you to the edge.",
            ]),
            Subheading("Aiming"),
            Paragraph("Abilities and utility spells fire toward the cursor, so aim with the mouse before you "
                      "press the key."),
            Subheading("A run, step by step"),
            Bullets([
                f"Danger rises from 0% to 100% over {ramp_minutes:g} minutes. Threats get faster and more "
                f"frequent, then stay at their worst.",
                f"Danger is announced at {', '.join(pct(m) for m in config.DANGER_MILESTONES[:-1])} and MAX, "
                f"and a fanfare plays every {sec(config.SURVIVAL_MILESTONE_INTERVAL)} you survive.",
                f"Press {key['pause']} to pause at any time. The game also pauses when its window loses "
                f"focus (you can turn that off in Settings).",
            ]),
            Subheading("Close calls"),
            Paragraph(f"A bolt or laser that passes within {config.NEAR_MISS_DISTANCE} px without hitting you "
                      f"is worth {config.CLOSE_CALL_COINS} coin. Nothing counts while you are untouchable."),
        ], icon="play"),
        Section("Threats", [
            Entry("bolt", "bolt", "Bolts",
                  "Fly in from every edge, aimed at where you stood when they appeared. They never turn, so "
                  "a short step sideways is usually enough. Later on they sometimes come in pairs.",
                  facts=[("SPEED", f"{config.BOLT_SPEED_START}-{config.BOLT_SPEED_END} px/s"),
                         ("EVERY", f"{config.BOLT_SPAWN_INTERVAL_START:g}-{config.BOLT_SPAWN_INTERVAL_END:g} s"),
                         ("PAIRS", f"up to {pct(config.DOUBLE_SHOT_CHANCE_END)}")]),
            Entry("laser", "laser", "Lasers",
                  "A lane lights up across the whole arena through your position, then a beam fires along "
                  "it. Get out of the lane before the warning ends. Walls don't stop lasers.",
                  facts=[("FIRST AT", sec(config.LASER_FIRST_DELAY)),
                         ("WARNING", f"{config.LASER_WARNING_START:g}-{config.LASER_WARNING_END:g} s"),
                         ("DEADLY FOR", sec(config.LASER_ACTIVE_TIME))]),
        ], icon="bolt"),
        Section("Difficulty", [
            Paragraph(f"Danger rises steadily from 0% to 100% over {ramp_minutes:g} minutes. Everything below "
                      f"scales smoothly in between, then stays at its worst."),
            Table(["", "At 0% danger", "At 100% danger"], [
                ("Bolt speed", f"{config.BOLT_SPEED_START} px/s", f"{config.BOLT_SPEED_END} px/s"),
                ("Time between bolts", sec(config.BOLT_SPAWN_INTERVAL_START), sec(config.BOLT_SPAWN_INTERVAL_END)),
                ("Chance of a pair", pct(config.DOUBLE_SHOT_CHANCE_START), pct(config.DOUBLE_SHOT_CHANCE_END)),
                ("Time between lasers", f"{config.LASER_INTERVAL_MIN_START:g}-{config.LASER_INTERVAL_MAX_START:g} s",
                 f"{config.LASER_INTERVAL_MIN_END:g}-{config.LASER_INTERVAL_MAX_END:g} s"),
                ("Laser warning", sec(config.LASER_WARNING_START), sec(config.LASER_WARNING_END)),
            ], [0.42, 0.29, 0.29]),
            Subheading("Notes"),
            Bullets([
                "The bar under the timer shows the current danger, in a color that runs from calm to red.",
                f"Starting danger (Settings > Gameplay, now {settings.options['start_danger']}%) starts your run "
                f"already harder. Use it to practise the late game.",
                "Time Warp slows threats and their spawn timers, but not the danger itself.",
            ]),
        ], icon="warning"),
        Section("Abilities", [
            Paragraph("Short cooldowns: use them often. The box in the ability bar shows the time left."),
            Entry("shield", "shield", "Shield",
                  "A bubble that blocks the next hit, bolt or laser. While it is up, the bubble is your "
                  "hitbox, so it is a little bigger than you.",
                  key=key["shield"], facts=[("COOLDOWN", ability_cooldown(config.SHIELD_COOLDOWN)),
                                            ("LASTS", mine(config.SHIELD_DURATION, stats.shield_duration, " s"))]),
            Entry("wall", "wall", "Wall",
                  "Raises a wall in front of you, across the direction of the cursor. Bolts that touch it "
                  "are destroyed. It blinks just before it disappears.",
                  key=key["wall"], facts=[("COOLDOWN", ability_cooldown(config.WALL_COOLDOWN)),
                                          ("LASTS", sec(config.WALL_DURATION)),
                                          ("LENGTH", mine(config.WALL_LENGTH, stats.wall_length, " px"))]),
            Entry("dash", "dash", "Dash",
                  "A quick dash toward the cursor. You travel the distance, so a bolt in the way can "
                  "still hit you.",
                  key=key["dash"], facts=[("COOLDOWN", ability_cooldown(config.DASH_COOLDOWN)),
                                          ("RANGE", f"{config.DASH_RANGE} px")]),
        ], icon="shield"),
        Section("Utility spells", [
            Paragraph("Long cooldowns: keep them for emergencies."),
            Entry("sprint", "sprint", "Sprint", "A burst of movement speed.",
                  key=key["sprint"], facts=[("COOLDOWN", sec(config.SPRINT_COOLDOWN)),
                                            ("LASTS", mine(config.SPRINT_DURATION, stats.sprint_duration, " s")),
                                            ("SPEED", f"+{pct(config.SPRINT_MULTIPLIER - 1)}")]),
            Entry("blink", "blink", "Blink",
                  "Teleports you instantly toward the cursor: as far as the cursor, up to its range. "
                  "Nothing can hit you on the way, and it cancels a Dash.",
                  key=key["blink"], facts=[("COOLDOWN", sec(config.BLINK_COOLDOWN)),
                                           ("RANGE", mine(config.BLINK_RANGE, stats.blink_range, " px"))]),
        ], icon="blink"),
        Section("Power-ups", [
            Paragraph(f"The first power-up appears {sec(config.POWERUP_FIRST_DELAY)} into a run, one at a time. "
                      f"It stays for {sec(config.POWERUP_MAP_LIFETIME)} (the ring shows the time left) and blinks "
                      f"before it goes. Walk over it to hold it, then press {key['powerup']} to use it. A held "
                      f"power-up has one use and expires after {sec(config.POWERUP_HOLD_TIME)}."),
            Entry("stasis", "stasis", "Stasis",
                  "Turns you into a golden statue. Nothing can hit you, but you can't move or cast. A move "
                  "you click during it runs as soon as it ends.",
                  key=key["powerup"], facts=[("LASTS", sec(config.STASIS_DURATION))]),
            Entry("time_warp", "time_warp", "Time Warp",
                  "Bolts, lasers and the timers that spawn them slow down. You keep your full speed. The "
                  "screen turns blue while it lasts.",
                  key=key["powerup"], facts=[("LASTS", sec(config.TIME_WARP_DURATION)),
                                             ("THREAT SPEED", pct(config.TIME_WARP_FACTOR))]),
            Entry("warp", "warp", "Warp", "A long-range Blink toward the cursor.",
                  key=key["powerup"], facts=[("RANGE", f"{config.WARP_RANGE} px")]),
            Entry("nova", "nova", "Nova",
                  "A shockwave that destroys every bolt and laser on screen, even lasers still showing "
                  "their warning.",
                  key=key["powerup"], facts=[("CLEARS", "Everything")]),
            Entry("coin_rush", "coin", "Coin Rush",
                  "For a while coins appear much faster, more of them fit on the field, and each one is "
                  "worth more.",
                  key=key["powerup"], facts=[("LASTS", sec(config.COIN_RUSH_DURATION)),
                                             ("VALUE", f"x{config.COIN_RUSH_MULT}"),
                                             ("EXTRA", f"+{config.COIN_RUSH_EXTRA_COINS} on field")]),
        ], icon="empty"),
        Section("Coins and upgrades", [
            Entry("coin", "coin", "Coins",
                  f"Appear around the arena and vanish after {sec(config.COIN_LIFETIME)}, blinking first. "
                  f"Big coins are worth {config.BIG_COIN_VALUE}. At the end of a run you also get one coin "
                  f"for every {1 / config.COINS_PER_SECOND_SURVIVED:g} s you survived. Leaving a run early "
                  f"still keeps what you picked up.",
                  facts=[("ON FIELD", f"up to {config.COIN_MAX_ON_FIELD}"),
                         ("BIG COIN", f"{pct(config.BIG_COIN_CHANCE)} chance")]),
            Subheading("Upgrades"),
            Paragraph("Spend coins in the Shop. Upgrades last forever, and selling a level refunds exactly "
                      "what you paid, so trying a different build never costs anything."),
            Table(["Upgrade", "Per level", "Level prices", "Yours"],
                  [(u.name, per_level(u), " / ".join(str(u.cost(i)) for i in range(u.max_level)),
                    f"{levels.get(u.id, 0)}/{u.max_level}") for u in UPGRADES],
                  [0.27, 0.29, 0.30, 0.14]),
        ], icon="coin"),
        Section("Second Wind", [
            Entry("second_wind", "second_wind", "Second Wind",
                  f"A passive upgrade. When a hit would end your run, Second Wind saves you instead and makes "
                  f"you untouchable for a moment. Then it recharges. The heart left of the ability bar shows "
                  f"when it is ready. The Shield is always used first.",
                  facts=[("UNTOUCHABLE", sec(config.SECOND_WIND_INVULN_TIME)),
                         ("RECHARGE", f"{sec(config.SECOND_WIND_COOLDOWN)} "
                                      f"(-{sec(UPGRADE_BY_ID['second_wind'].step)} per extra level)")]),
            Table(["Level", "Recharge", "Price", ""],
                  [(f"Level {lv}", sec(second_wind_cooldown(lv)), str(UPGRADE_BY_ID["second_wind"].cost(lv - 1)),
                    "Yours" if levels.get("second_wind", 0) == lv else "")
                   for lv in range(1, UPGRADE_BY_ID["second_wind"].max_level + 1)],
                  [0.3, 0.3, 0.25, 0.15]),
        ], icon="second_wind"),
        Section("The HUD", [
            Subheading("Top of the screen"),
            Bullets([
                "Center: your survival time, with the danger bar and percentage under it. Messages about "
                "power-ups, Second Wind and danger milestones appear just below.",
                "Right: your coins, what this run has added so far in green (+N), and your best time.",
                "Left: your keys as a reminder, and the frame rate. Both can be turned off in Settings.",
            ]),
            Subheading("Ability bar"),
            Bullets([
                "Left to right: abilities, utility spells, then the power-up box. Each box shows its key.",
                "On cooldown a dark sweep drains clockwise and the seconds left are shown. A ready box has a "
                "colored border and flashes the moment it comes back.",
                "While an effect lasts, the box gets an outline and a thin bar drains along its bottom.",
                "The power-up box shows a faint dashed diamond while you hold nothing.",
            ]),
            Subheading("Around the bar"),
            Bullets([
                "Left: Second Wind if you own it (READY, or a ring filling up while it recharges), then your "
                "active effects, each with a ring timer and the seconds left.",
                "Right: the power-up you hold, with its key, what it does and a bar until it expires.",
            ]),
            Subheading("Feedback"),
            Bullets([
                "BLOCKED pops up when your Shield takes a hit. Big moments shake the screen and freeze it for an "
                "instant (Settings > Display turns shake off).",
                "Bolts leave trails and are brightest at the front, so you can see which way they fly.",
                "When a hit ends the run, the screen slows down with red edges and the bolt that hit you is "
                "outlined.",
                "The music gains layers as danger rises, and every action has its own sound "
                "(Settings > Audio).",
            ]),
        ], icon="time_warp"),
        Section("Controls", [
            Subheading("In a run (your bindings)"),
            KeyList([
                ([MOVE_BUTTONS[settings.move_button].upper()], "Walk there; hold to follow the cursor"),
                ([key["shield"], key["wall"], key["dash"]], "Shield, Wall, Dash (abilities)"),
                ([key["sprint"], key["blink"]], "Sprint, Blink (utility spells)"),
                ([key["powerup"]], "Use the power-up you hold"),
                ([key["pause"]], "Pause"),
                ([key["restart"]], "Play again (game over) or restart (pause)"),
            ]),
            Subheading("Menus"),
            KeyList([
                (["UP", "DOWN"], "Move between items, or between sections here"),
                (["LEFT", "RIGHT"], "Change a value, or switch tab"),
                (["ENTER", "SPACE"], "Choose"),
                (["TAB"], "Next item (Shift + Tab: previous)"),
                (["ESC"], "Back"),
                (["PGUP", "PGDN"], "Scroll long pages (Home / End jump)"),
                (["+", "DEL"], "Buy or sell the focused upgrade"),
            ]),
            Subheading("Rebinding and your save"),
            Bullets([
                "Every key above the menu list can be changed in Settings > Controls. Choosing a key that is "
                "already used swaps the two.",
                f"Progress and settings are kept in one file, {config.SAVE_FILENAME}, in your user data folder. "
                f"Delete it to start over.",
            ]),
        ], icon="gear"),
        Section("Accessibility", [
            Paragraph("Settings > Accessibility changes how the game looks, and Settings > Gameplay how it "
                      "plays. Everything is saved right away."),
            Bullets([
                "Color modes for deuteranopia, protanopia and tritanopia, plus High contrast. You can also "
                "pick your own color for yourself, bolts and lasers.",
                "Threat outlines draw a bright edge around every bolt and laser.",
                "Reduce flashing stops all blinking and pulsing. Reduced motion stops floating, wobbling, "
                "spinning, sliding and smooth scrolling.",
                "Game speed (down to 50%), longer laser warnings (up to 200%) and turning lasers off make runs "
                "easier to learn. "
                "Runs with these assists still earn coins, but don't set best times.",
                "Starting danger lets you practise the fast part of a run straight away.",
                "Settings > Audio has a laser audio cue: beeps when a laser appears (higher and faster as "
                "danger rises) and a rising whine just before it fires.",
            ]),
        ], icon="eye"),
        Section("Tips", [Bullets(tips(settings))], icon="book"),
    ]


def tips(settings: Settings) -> list[str]:
    """Short pieces of advice: all of them in the guide, a random one on the main menu."""
    blink = key_label(settings.keybinds["blink"])
    return [
        "Keep moving in short steps. Bolts are aimed at where you were, not where you are going.",
        "When a laser lane lights up, step out sideways rather than running along it.",
        f"Save Blink ({blink}) for the hit you can't dodge any other way.",
        "A Wall between you and a busy edge buys you a few seconds of calm.",
        "Coin Rush plus Coin Magnet is the fastest way to afford upgrades.",
        "Sell upgrades any time to try a new build: refunds are always full.",
        "Let bolts pass close: every close call is worth a coin.",
        "Stay near the middle. Corners trap you and cut Blink short.",
    ]


def per_level(upgrade) -> str:
    """What one level of an upgrade adds, for the guide's table."""
    if upgrade.id == "second_wind":
        return f"Unlock, then -{upgrade.step:g} s"
    return upgrade.effect.format(upgrade.step)
