import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from utils.helpers import clamp, clamp_color, level_threshold, get_combo_multiplier

def test_clamp():
    assert clamp(5, 0, 10) == 5
    assert clamp(-1, 0, 10) == 0
    assert clamp(11, 0, 10) == 10
    assert clamp(0, 0, 10) == 0
    assert clamp(10, 0, 10) == 10

def test_clamp_color():
    assert clamp_color(300, -10, 150) == (255, 0, 150)
    assert clamp_color(100, 200, 50) == (100, 200, 50)
    assert clamp_color(-5, 256, 0) == (0, 255, 0)

def test_level_threshold():
    assert level_threshold(1) == 26
    assert level_threshold(2) == 64
    assert level_threshold(3) == 114
    assert level_threshold(4) == 176
    assert level_threshold(5) == 250

def test_get_combo_multiplier():
    assert get_combo_multiplier(0) == 1.0
    assert get_combo_multiplier(2) == 1.0
    assert get_combo_multiplier(3) == 1.5
    assert get_combo_multiplier(6) == 1.5
    assert get_combo_multiplier(7) == 2.0
    assert get_combo_multiplier(11) == 2.0
    assert get_combo_multiplier(12) == 2.5
    assert get_combo_multiplier(17) == 2.5
    assert get_combo_multiplier(18) == 3.0
    assert get_combo_multiplier(24) == 3.0
    assert get_combo_multiplier(25) == 4.0
    assert get_combo_multiplier(30) == 4.0
    assert get_combo_multiplier(100) == 4.0
