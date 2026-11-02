from duck_attack.player import load_player_name, save_player_name


def test_missing_file_gives_empty_name(tmp_path):
    assert load_player_name(tmp_path / "player.txt") == ""


def test_saved_name_is_loaded(tmp_path):
    path = tmp_path / "sub" / "player.txt"
    save_player_name(path, "Ann")
    assert load_player_name(path) == "Ann"
