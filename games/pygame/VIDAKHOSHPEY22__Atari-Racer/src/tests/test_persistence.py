import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import tempfile
import pytest
from utils.persistence import load_high_score, save_high_score, load_progress, save_progress

@pytest.fixture
def isolated_cwd(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    yield tmp_path

def test_high_score_save_load(isolated_cwd):
    save_high_score(250)
    assert load_high_score() == 250

def test_high_score_load_missing_file(isolated_cwd):
    assert load_high_score() == 0

def test_high_score_load_negative_is_clamped(isolated_cwd):
    with open("highscore.txt", "w") as f:
        f.write("-50")
    assert load_high_score() == 0

def test_high_score_load_invalid_contents(isolated_cwd):
    with open("highscore.txt", "w") as f:
        f.write("not a number")
    assert load_high_score() == 0

def test_progress_save_load(isolated_cwd):
    upgrades = {"speed": 3, "life": 1}
    save_progress(120, upgrades)
    wallet, loaded = load_progress()
    assert wallet == 120
    assert loaded == upgrades

def test_progress_load_missing_file(isolated_cwd):
    wallet, upgrades = load_progress()
    assert wallet == 0
    assert upgrades == {"speed": 0, "life": 0}

def test_progress_load_clamps_out_of_range_levels(isolated_cwd):
    with open("progress.txt", "w") as f:
        f.write("50,99,99")
    wallet, upgrades = load_progress()
    assert wallet == 50
    assert upgrades == {"speed": 5, "life": 2}

def test_progress_load_malformed_contents(isolated_cwd):
    with open("progress.txt", "w") as f:
        f.write("garbage")
    wallet, upgrades = load_progress()
    assert wallet == 0
    assert upgrades == {"speed": 0, "life": 0}
