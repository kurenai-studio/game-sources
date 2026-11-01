"""Fachada de compatibilidad: los efectos viven en src/core/audio_manager.py (AudioManager, modo híbrido archivo/síntesis
y canales dedicados). `sfx.play(nombre)` sigue funcionando igual y nunca rompe el juego (sin audio, no suena)."""
from src.core.audio_manager import audio


def _build(name):
    """Muestras sintetizadas del efecto `name` (respaldo procedural)."""
    return audio.synth(name)


def play(name):
    """Reproduce un efecto del AudioManager ('crit', 'ricochet', 'error', ...). False si no sonó."""
    return audio.play(name)
