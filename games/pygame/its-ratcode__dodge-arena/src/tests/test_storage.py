"""The save file: one JSON document, written safely, never fatal when broken."""

import json

from app.core.storage import SAVE_VERSION, SaveFile


def test_a_missing_file_starts_fresh(save_path):
    assert SaveFile(save_path).section("progress") == {}


def test_a_corrupt_file_starts_fresh(save_path):
    save_path.write_text("{not json", encoding="utf-8")
    assert SaveFile(save_path).section("progress") == {}


def test_sections_that_are_not_dicts_are_ignored(save_path):
    save_path.write_text(json.dumps({"progress": [1, 2], "settings": {"a": 1}}), encoding="utf-8")
    save = SaveFile(save_path)
    assert save.section("progress") == {} and save.section("settings") == {"a": 1}


def test_writing_one_section_keeps_the_others(save_path):
    save = SaveFile(save_path)
    assert save.write("progress", {"coins": 5})
    assert save.write("settings", {"x": 1})
    data = json.loads(save_path.read_text(encoding="utf-8"))
    assert data == {"version": SAVE_VERSION, "progress": {"coins": 5}, "settings": {"x": 1}}
    assert SaveFile(save_path).section("progress") == {"coins": 5}


def test_no_temporary_file_is_left_behind(save_path):
    SaveFile(save_path).write("progress", {})
    assert not save_path.with_suffix(".tmp").exists()


def test_the_folder_is_created_when_needed(tmp_path):
    path = tmp_path / "new" / "folder" / "save.json"
    assert SaveFile(path).write("progress", {})
    assert path.exists()
