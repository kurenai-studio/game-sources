"""
sfx.py
Zero-asset procedural sound effects generator and manager using pygame.mixer.
Synthesizes retro chiptune and acoustic waveforms in memory at startup without
requiring any external .wav or .mp3 audio files.
"""

import math
import struct
import pygame

# Sample rate & audio format
_FREQ = 22050
_CHANNELS = 2
_SOUNDS = {}
_INITIALIZED = False
_MUTED = False


def _pack_stereo(v: int) -> bytes:
    """Pack a 16-bit signed integer into stereo L/R bytes."""
    v = max(-32767, min(32767, int(v)))
    return struct.pack('<hh', v, v)


def _synth(duration_sec: float, gen_fn) -> pygame.mixer.Sound:
    """
    Generate a pygame.mixer.Sound from a math sample function.
    gen_fn(i: int, t: float) -> float amplitude in [-32767, 32767].
    """
    samples = int(_FREQ * duration_sec)
    raw = bytearray()
    for i in range(samples):
        t = i / samples
        raw.extend(_pack_stereo(gen_fn(i, t)))
    return pygame.mixer.Sound(buffer=bytes(raw))


def init_sfx() -> None:
    """Initialize mixer and synthesize all sound effects in memory."""
    global _INITIALIZED, _SOUNDS
    if _INITIALIZED:
        return

    try:
        if not pygame.mixer.get_init():
            pygame.mixer.init(frequency=_FREQ, size=-16, channels=_CHANNELS, buffer=512)
    except Exception:
        # Mixer unavailable (e.g. headless system without audio hardware)
        _INITIALIZED = False
        return

    freq, _, _ = pygame.mixer.get_init()

    # 1. Melee Swing (Airy sword swoosh: 340Hz down to 110Hz + subtle filtered noise)
    def _melee(i, t):
        f = 340.0 - 230.0 * (t ** 1.5)
        phase = 2.0 * math.pi * f * (i / freq)
        wave = math.sin(phase) * 0.7 + (math.sin(phase * 2.3) * 0.3)
        env = math.sin(math.pi * t) * (1.0 - t * 0.4)
        return wave * env * 14000.0

    # 2. Shoot Bolt (High-tech retro laser: exponential sweep from 950Hz to 180Hz)
    def _shoot(i, t):
        f = 950.0 * (0.19 ** t)
        phase = 2.0 * math.pi * f * (i / freq)
        # Pulse wave
        wave = 1.0 if math.sin(phase) > 0.0 else -1.0
        env = (1.0 - t) ** 1.8
        return wave * env * 9500.0

    # 3. Monster Hit (Punchy distortion thud: 180Hz down to 60Hz)
    def _hit(i, t):
        f = 180.0 - 120.0 * t
        phase = 2.0 * math.pi * f * (i / freq)
        wave = math.sin(phase) + (0.5 if math.sin(phase * 1.5) > 0 else -0.5)
        env = (1.0 - t) ** 2.2
        return wave * env * 16000.0

    # 4. Player Hurt (Heavy impact punch: 130Hz -> 45Hz with rough grit)
    def _hurt(i, t):
        f = 130.0 - 85.0 * t
        phase = 2.0 * math.pi * f * (i / freq)
        noise = math.sin(i * 137.5) * 0.3
        wave = math.sin(phase) + noise
        env = (1.0 - t) ** 2.0
        return wave * env * 18000.0

    # 5. Enemy Death (Retro explosion burst: decaying noise + pitch dive)
    def _enemy_death(i, t):
        f = 160.0 * (1.0 - t)
        sine = math.sin(2.0 * math.pi * f * (i / freq))
        noise = math.sin(i * 12.9898 + (i % 7) * 4.14)
        wave = sine * 0.4 + noise * 0.6
        env = (1.0 - t) ** 1.6
        return wave * env * 16000.0

    # 6. Coin Pickup (Classic arcade 2-tone ping: B5 987Hz -> E6 1318Hz)
    def _coin(i, t):
        f = 987.77 if t < 0.38 else 1318.51
        phase = 2.0 * math.pi * f * (i / freq)
        env = (1.0 - t) ** 1.3
        return math.sin(phase) * env * 12000.0

    # 7. Potion Drink / Heal (Ascending 3-note arpeggio: C5 523Hz -> E5 659Hz -> G5 784Hz)
    def _heal(i, t):
        if t < 0.32:
            f = 523.25
            local_t = t / 0.32
        elif t < 0.64:
            f = 659.25
            local_t = (t - 0.32) / 0.32
        else:
            f = 783.99
            local_t = (t - 0.64) / 0.36
        phase = 2.0 * math.pi * f * (i / freq)
        env = math.sin(math.pi * min(1.0, local_t * 2.0)) * (1.0 - t * 0.5)
        # Harmonious overtone
        return (math.sin(phase) + 0.3 * math.sin(phase * 2.0)) * env * 12500.0

    # 8. Weapon Equip (Metallic click / blade draw: 1200Hz & 1800Hz clicks)
    def _equip(i, t):
        f1 = 1250.0 - 300.0 * t
        f2 = 1850.0 - 500.0 * t
        wave = math.sin(2.0 * math.pi * f1 * (i / freq)) + 0.5 * math.sin(2.0 * math.pi * f2 * (i / freq))
        env = (1.0 - t) ** 2.8
        return wave * env * 13500.0

    # 9. Chest Open (Wood creak rising + bright shimmer)
    def _chest(i, t):
        if t < 0.35:
            f = 190.0 + 120.0 * (t / 0.35)
            wave = math.sin(2.0 * math.pi * f * (i / freq))
        else:
            f = 880.0 + 350.0 * ((t - 0.35) / 0.65)
            wave = math.sin(2.0 * math.pi * f * (i / freq)) + 0.3 * math.sin(4.0 * math.pi * f * (i / freq))
        env = (1.0 - t) ** 1.4
        return wave * env * 13000.0

    # 10. Door Unlock (Mechanical key turn tick + heavy latch release)
    def _door_unlock(i, t):
        if t < 0.2:
            f = 950.0
            wave = math.sin(2.0 * math.pi * f * (i / freq))
        else:
            f = 170.0 - 100.0 * ((t - 0.2) / 0.8)
            wave = math.sin(2.0 * math.pi * f * (i / freq)) + 0.4 * (1.0 if math.sin(3.0 * math.pi * f * (i / freq)) > 0 else -1.0)
        env = (1.0 - t) ** 1.5
        return wave * env * 15500.0

    # 11. Door Locked (Two dull heavy thuds)
    def _door_locked(i, t):
        pulse = 1.0 if (t < 0.45 or (0.55 < t < 0.95)) else 0.0
        f = 90.0
        wave = math.sin(2.0 * math.pi * f * (i / freq))
        env = (1.0 - (t % 0.5) * 2.0) * pulse
        return wave * env * 15000.0

    # 12. Shrine Blessing (Arcane celestial major triad chord: A4 + C#5 + E5)
    def _shrine(i, t):
        f1, f2, f3 = 440.0, 554.37, 659.25
        phase1 = 2.0 * math.pi * f1 * (i / freq)
        phase2 = 2.0 * math.pi * f2 * (i / freq)
        phase3 = 2.0 * math.pi * f3 * (i / freq)
        # Slow shimmering tremolo
        trem = 0.85 + 0.15 * math.sin(2.0 * math.pi * 6.0 * t)
        wave = (math.sin(phase1) + math.sin(phase2) * 0.8 + math.sin(phase3) * 0.9) / 2.7
        env = (1.0 - t) ** 1.2 * trem
        return wave * env * 14000.0

    # 13. Stairs Descend (Deep portal whoosh: 260Hz down to 50Hz)
    def _descend(i, t):
        f = 260.0 * (0.22 ** t)
        phase = 2.0 * math.pi * f * (i / freq)
        wave = math.sin(phase) + 0.3 * math.sin(phase * 0.5)
        env = math.sin(math.pi * t) * (1.0 - t * 0.3)
        return wave * env * 17000.0

    # 14. Game Over (Somber descending triad: 440Hz -> 349Hz -> 293Hz)
    def _game_over(i, t):
        if t < 0.33:
            f = 440.0
        elif t < 0.66:
            f = 349.23
        else:
            f = 293.66
        phase = 2.0 * math.pi * f * (i / freq)
        env = (1.0 - t) ** 1.3
        return (math.sin(phase) + 0.25 * math.sin(phase * 2.0)) * env * 14000.0

    try:
        _SOUNDS["melee"]       = _synth(0.12, _melee)
        _SOUNDS["shoot"]       = _synth(0.14, _shoot)
        _SOUNDS["hit"]         = _synth(0.10, _hit)
        _SOUNDS["hurt"]        = _synth(0.14, _hurt)
        _SOUNDS["enemy_death"] = _synth(0.22, _enemy_death)
        _SOUNDS["coin"]        = _synth(0.19, _coin)
        _SOUNDS["heal"]        = _synth(0.30, _heal)
        _SOUNDS["equip"]       = _synth(0.12, _equip)
        _SOUNDS["chest"]       = _synth(0.26, _chest)
        _SOUNDS["door_unlock"] = _synth(0.24, _door_unlock)
        _SOUNDS["door_locked"] = _synth(0.16, _door_locked)
        _SOUNDS["shrine"]      = _synth(0.48, _shrine)
        _SOUNDS["descend"]     = _synth(0.36, _descend)
        _SOUNDS["game_over"]   = _synth(0.65, _game_over)
        _INITIALIZED = True
    except Exception:
        _INITIALIZED = False


def _play(name: str) -> None:
    """Helper to play a sound if initialized and unmuted."""
    if _MUTED or not _INITIALIZED:
        return
    snd = _SOUNDS.get(name)
    if snd:
        try:
            snd.play()
        except Exception:
            pass


def play_melee() -> None:       _play("melee")
def play_shoot() -> None:       _play("shoot")
def play_hit() -> None:         _play("hit")
def play_hurt() -> None:        _play("hurt")
def play_enemy_death() -> None: _play("enemy_death")
def play_coin() -> None:        _play("coin")
def play_heal() -> None:        _play("heal")
def play_equip() -> None:       _play("equip")
def play_chest() -> None:       _play("chest")
def play_door_unlock() -> None: _play("door_unlock")
def play_door_locked() -> None: _play("door_locked")
def play_shrine() -> None:      _play("shrine")
def play_descend() -> None:     _play("descend")
def play_game_over() -> None:   _play("game_over")
