import json
import os
import tempfile
import unittest

import pygame

from game.core.config import DEFAULT_KEYS, GROUPS, Config


def write(path, payload):
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(payload, fh)


class TestConfig(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.path = os.path.join(self.dir, "settings.json")
        pygame.init()

    def test_defaults_without_file(self):
        cfg = Config(self.path)
        self.assertEqual(cfg.lane_keys, ["d", "f", "j", "k"])
        self.assertEqual(cfg.key("lane_0"), pygame.K_d)
        self.assertEqual(cfg.key("boost"), pygame.K_SPACE)
        self.assertEqual(cfg.key("cancel"), pygame.K_ESCAPE)

    def test_groups_cover_every_action(self):
        grouped = [a for _title, actions in GROUPS for a in actions]
        self.assertEqual(sorted(grouped), sorted(DEFAULT_KEYS))
        self.assertEqual(len(grouped), len(set(grouped)))

    def test_roundtrip(self):
        cfg = Config(self.path)
        cfg.set_key("lane_0", pygame.K_q)
        cfg.clear_key("boost")
        again = Config(self.path)
        self.assertEqual(again.key("lane_0"), pygame.K_q)
        self.assertIsNone(again.key("boost"))
        self.assertEqual(again.label("boost"), "UNBOUND")

    def test_legacy_file_is_migrated(self):
        write(self.path, {"lane_keys": ["q", "w", "e", None],
                          "editor_stop": "tab"})
        cfg = Config(self.path)
        self.assertEqual(cfg.key("lane_0"), pygame.K_q)
        self.assertEqual(cfg.key("lane_3"), None)
        self.assertEqual(cfg.key("editor_stop"), pygame.K_TAB)
        # untouched actions keep their defaults
        self.assertEqual(cfg.key("confirm"), pygame.K_RETURN)

    def test_invalid_values_fall_back(self):
        write(self.path, {"keys": {"lane_0": "not_a_key",
                                   "cancel": "escape"}})
        cfg = Config(self.path)
        self.assertEqual(cfg.key("lane_0"), None)
        self.assertEqual(cfg.key("cancel"), pygame.K_ESCAPE)

    def test_corrupt_file_uses_defaults(self):
        with open(self.path, "w", encoding="utf-8") as fh:
            fh.write("{oops")
        cfg = Config(self.path)
        self.assertEqual(cfg.lane_keys, ["d", "f", "j", "k"])


if __name__ == "__main__":
    unittest.main()
