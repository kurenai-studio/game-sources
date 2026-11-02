from datetime import datetime

from duck_attack.highscores import HighScore, HighScoreList


def at(minute):
    return datetime(2026, 10, 17, 12, minute)


def test_sorted_by_score_then_earlier_round(tmp_path):
    scores = HighScoreList(tmp_path / "hs.json")
    scores.add(HighScore(50, at(1)))
    scores.add(HighScore(80, at(2)))
    scores.add(HighScore(50, at(0)))
    assert scores.entries == [HighScore(80, at(2)), HighScore(50, at(0)), HighScore(50, at(1))]


def test_add_returns_rank_or_none_when_list_is_full(tmp_path):
    scores = HighScoreList(tmp_path / "hs.json", max_entries=2)
    assert scores.add(HighScore(10, at(0))) == 0
    assert scores.add(HighScore(30, at(1))) == 0
    assert scores.add(HighScore(20, at(2))) == 1
    assert scores.add(HighScore(5, at(3))) is None
    assert [e.score for e in scores.entries] == [30, 20]


def test_persisted_between_sessions(tmp_path):
    path = tmp_path / "sub" / "hs.json"
    HighScoreList(path).add(HighScore(70, at(5)))
    assert HighScoreList(path).entries == [HighScore(70, at(5))]


def test_corrupt_file_starts_fresh(tmp_path):
    path = tmp_path / "hs.json"
    path.write_text("not json")
    assert HighScoreList(path).entries == []


def test_names_are_persisted(tmp_path):
    path = tmp_path / "hs.json"
    HighScoreList(path).add(HighScore(40, at(1), "Ann"))
    assert HighScoreList(path).entries == [HighScore(40, at(1), "Ann")]


def test_entries_without_name_still_load(tmp_path):
    path = tmp_path / "hs.json"
    path.write_text('[{"score": 30, "timestamp": "2026-10-17T12:03:00"}]')
    assert HighScoreList(path).entries == [HighScore(30, at(3), "")]
