"""Sound design: every sound effect in the game, built from synth parts.

Names matter: a skill or power-up plays the sound with the same name as its
icon ("shield", "time_warp" ...), so adding a skill only needs a sound here.
Frequencies are in Hz; e.g. 1047 is a high C.
"""

from app import config
from app.audio.synth import Samples, Synth



def build_sound_bank(s: Synth) -> dict[str, Samples]:
    bank: dict[str, Samples] = {}

    # --- Menus --------------------------------------------------------------------------------------
    bank["ui_hover"] = s.tone(1900, 0.03, decay=60, volume=0.16)
    bank["ui_tick"] = s.tone(1300, 0.035, decay=70, volume=0.22)
    bank["ui_click"] = s.tone(900, 0.06, freq_end=620, wave="triangle", decay=35, volume=0.35)
    bank["ui_back"] = s.tone(620, 0.07, freq_end=400, wave="triangle", decay=30, volume=0.32)
    bank["error"] = s.mix((s.tone(200, 0.08, freq_end=180, wave="square", decay=20, volume=0.16), 0),
                          (s.tone(170, 0.10, freq_end=150, wave="square", decay=20, volume=0.16), 0.09))
    bank["buy"] = s.mix((s.tone(1047, 0.12, decay=18, volume=0.35), 0),           # two notes going up ...
                        (s.tone(1568, 0.22, decay=12, volume=0.35), 0.07))
    bank["sell"] = s.mix((s.tone(1568, 0.10, decay=20, volume=0.3), 0),           # ... and the same two going down
                         (s.tone(1047, 0.20, decay=14, volume=0.3), 0.07))

    # --- Abilities and utility spells (named like their icons) ---------------------------------------------
    bank["shield"] = s.mix((s.tone(260, 0.35, freq_end=620, attack=0.02, decay=7, volume=0.5), 0),
                           (s.noise(0.25, decay=12, volume=0.10, smooth=0.15), 0))
    bank["wall"] = s.mix((s.tone(150, 0.30, freq_end=80, wave="square", decay=14, volume=0.25), 0),
                         (s.noise(0.20, decay=18, volume=0.28, smooth=0.08), 0))
    bank["dash"] = s.noise(0.22, decay=10, volume=0.45, smooth=0.12, attack=0.04)
    bank["sprint"] = s.tone(380, 0.45, freq_end=900, wave="triangle", attack=0.03, decay=5, volume=0.32,
                            vibrato_rate=14, vibrato_depth=0.03)
    bank["blink"] = s.mix((s.tone(2200, 0.16, freq_end=180, wave="saw", decay=16, volume=0.26), 0),
                          (s.noise(0.10, decay=30, volume=0.22, smooth=0.5), 0))
    bank["denied"] = s.tone(160, 0.06, wave="square", decay=40, volume=0.08)      # still on cooldown
    bank["block"] = s.mix((s.noise(0.18, decay=25, volume=0.45, smooth=0.6), 0),
                          (s.tone(1400, 0.25, freq_end=260, wave="triangle", decay=14, volume=0.4), 0))
    bank["wall_hit"] = s.mix((s.tone(220, 0.08, freq_end=120, wave="triangle", decay=40, volume=0.32), 0),
                             (s.noise(0.06, decay=50, volume=0.22, smooth=0.3), 0))

    # --- Coins: each pickup in a quick combo is a step higher ---------------------------------------------
    for i in range(config.COIN_COMBO_STEPS):
        base = 1320 * 2 ** (i * 2 / 12)                   # two semitones per step
        bank[f"coin{i}"] = s.mix((s.tone(base, 0.08, decay=25, volume=0.28), 0),
                                 (s.tone(base * 1.5, 0.16, decay=18, volume=0.22), 0.04))
    bank["coin_big"] = s.arpeggio([1047, 1319, 1568, 2093], 0.05, 0.2, wave="sine", volume=0.3, decay=12)

    # --- Power-ups ----------------------------------------------------------------------------------------
    bank["powerup_get"] = s.arpeggio([523, 659, 784, 1047], 0.06, 0.25, volume=0.3)
    bank["powerup_lost"] = s.tone(700, 0.25, freq_end=300, wave="triangle", decay=10, volume=0.22)
    bank["stasis"] = s.bell([520, 1040, 1560, 2210], 0.9, decay=4, volume=0.35)
    bank["time_warp"] = s.tone(900, 0.7, freq_end=180, decay=3, volume=0.38, vibrato_rate=9, vibrato_depth=0.08)
    bank["warp"] = s.mix((s.tone(2600, 0.24, freq_end=140, wave="saw", decay=10, volume=0.26), 0),
                         (s.noise(0.16, decay=20, volume=0.24, smooth=0.4), 0))
    bank["nova"] = s.mix((s.tone(90, 0.8, freq_end=40, decay=4, volume=0.55), 0),      # parts kept low enough
                         (s.noise(0.6, decay=6, volume=0.28, smooth=0.1), 0),           # that the sum never clips
                         (s.tone(1800, 0.3, freq_end=400, wave="triangle", decay=10, volume=0.15), 0))
    bank["coin_rush"] = s.arpeggio([1047, 1175, 1319, 1568, 1760, 2093], 0.04, 0.16, wave="sine", volume=0.25)

    # --- Threats: laser warnings get higher and faster as danger rises (3 tiers) ---------------------------
    for tier, (pitch, beeps, gap) in enumerate(((880, 2, 0.12), (1100, 3, 0.09), (1320, 3, 0.07))):
        bank[f"laser_warn{tier}"] = s.mix(*((s.tone(pitch, 0.08, wave="square", decay=22, volume=0.18), i * gap)
                                            for i in range(beeps)))
    charge = config.LASER_CHARGE_SOUND_TIME
    bank["laser_charge"] = s.tone(300, charge, freq_end=1500, wave="saw", attack=charge * 0.9, decay=0, volume=0.14)
    bank["laser_fire"] = s.mix((s.noise(0.45, decay=7, volume=0.45, smooth=0.25), 0),
                               (s.tone(140, 0.4, freq_end=60, wave="square", decay=7, volume=0.25), 0),
                               (s.tone(1800, 0.2, freq_end=600, wave="saw", decay=15, volume=0.12), 0))

    # --- Run events ----------------------------------------------------------------------------------------
    bank["ready"] = s.tone(660, 0.12, decay=18, volume=0.28)
    # Close call: a fast whoosh with a bright glint.
    bank["near_miss"] = s.mix((s.noise(0.2, attack=0.08, decay=12, volume=0.32, smooth=0.35), 0),
                              (s.tone(1600, 0.12, freq_end=2400, decay=20, volume=0.12), 0.05))
    # Danger milestone: a rising noise sweep that slams into a low hit.
    bank["danger"] = s.mix((s.noise(0.6, attack=0.55, decay=0, volume=0.22, smooth=0.3), 0),
                           (s.tone(80, 0.6, freq_end=40, decay=5, volume=0.5), 0.55),
                           (s.noise(0.3, decay=12, volume=0.28, smooth=0.2), 0.55),
                           (s.tone(110, 0.5, wave="square", decay=4, volume=0.12), 0.55))
    # Survival milestone: a short fanfare.
    bank["milestone"] = s.mix((s.arpeggio([880, 1109, 1319, 1760], 0.06, 0.2, wave="sine", volume=0.28), 0),
                              (s.bell([1760, 2637], 0.9, decay=3, volume=0.22), 0.24))
    bank["go"] = s.mix((s.tone(880, 0.10, decay=20, volume=0.3), 0), (s.tone(1320, 0.30, decay=9, volume=0.3), 0.08))
    bank["second_wind"] = s.bell([784, 988, 1175, 1568], 1.2, decay=3, volume=0.35, stagger=0.04)
    bank["second_wind_ready"] = s.mix((s.tone(1175, 0.15, decay=14, volume=0.22), 0),
                                      (s.tone(1568, 0.30, decay=9, volume=0.22), 0.08))
    bank["death"] = s.mix((s.tone(420, 1.1, freq_end=55, wave="saw", decay=3, volume=0.22), 0),
                          (s.noise(0.5, decay=8, volume=0.3, smooth=0.1), 0),      # random: kept low enough
                          (s.tone(70, 0.8, decay=5, volume=0.42), 0))                # that the sum never clips
    bank["new_best"] = s.mix((s.arpeggio([784, 988, 1175], 0.09, 0.2, volume=0.3), 0),
                             (s.bell([1568, 2349], 1.0, decay=3, volume=0.3), 0.27))
    return bank
