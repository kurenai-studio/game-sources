import unittest

from game.engine.rhythm import RhythmEngine


class FakeClock:
    def __init__(self):
        self.ms = 0.0

    def __call__(self):
        return self.ms


def make(notes):
    clock = FakeClock()
    return RhythmEngine(notes, clock), clock


class TestJudgment(unittest.TestCase):
    def test_perfect(self):
        eng, clock = make([{"lane": 0, "time": 1000.0}])
        clock.ms = 1005
        j = eng.press_lane(0)
        self.assertEqual(j.rating, "perfect")
        self.assertEqual(eng.counts["perfect"], 1)
        self.assertEqual(eng.combo, 1)
        self.assertEqual(eng.score_display, 100)

    def test_windows(self):
        for is_great, is_good in ((80, "great"), (130, "good")):
            eng, clock = make([{"lane": 1, "time": 1000.0}])
            clock.ms = 1000 + is_great
            self.assertEqual(eng.press_lane(1).rating, is_good)

    def test_no_penalty_for_empty_press(self):
        eng, clock = make([{"lane": 0, "time": 1000.0}])
        clock.ms = 500
        self.assertIsNone(eng.press_lane(0))
        self.assertEqual(eng.combo, 0)

    def test_auto_miss_breaks_combo(self):
        eng, clock = make([{"lane": 0, "time": 1000.0},
                           {"lane": 0, "time": 2000.0}])
        clock.ms = 1000
        eng.press_lane(0)
        self.assertEqual(eng.combo, 1)
        clock.ms = 2000 + 141
        eng.update(0.016)
        self.assertEqual(eng.counts["miss"], 1)
        self.assertEqual(eng.combo, 0)

    def test_out_of_window_is_miss_via_update(self):
        eng, clock = make([{"lane": 2, "time": 1000.0}])
        clock.ms = 500
        self.assertIsNone(eng.press_lane(2))  # too early, ignored
        clock.ms = 1200
        eng.update(0.016)
        self.assertEqual(eng.counts["miss"], 1)


class TestBoost(unittest.TestCase):
    def test_boost_note_charges_and_multiplies(self):
        eng, clock = make([{"lane": 0, "time": 1000.0, "boost": True}])
        clock.ms = 1000
        eng.press_lane(0)
        self.assertEqual(eng.boost_charge, 20.0)
        self.assertTrue(eng.press_boost())
        clock.ms = 1010
        eng.press_lane(0)
        # no more notes

    def test_boost_requires_charge(self):
        eng, clock = make([])
        self.assertFalse(eng.press_boost())

    def test_double_points_while_active(self):
        eng, clock = make([{"lane": 0, "time": 1000.0, "boost": True},
                           {"lane": 1, "time": 1100.0}])
        clock.ms = 1000
        eng.press_lane(0)  # perfect +100, charge 20
        eng.press_boost()
        clock.ms = 1100
        eng.press_lane(1)  # perfect, doubled +200
        self.assertEqual(eng.score_display, 300)

    def test_boost_drains(self):
        eng, clock = make([{"lane": 0, "time": 1000.0, "boost": True}])
        clock.ms = 1000
        eng.press_lane(0)
        eng.press_boost()
        clock.ms = 1100
        eng.update(0.5)  # 0.5s * 20/s = 10 -> charge 10
        self.assertAlmostEqual(eng.boost_charge, 10.0, places=3)
        eng.update(0.6)  # drains to 0, deactivates
        self.assertEqual(eng.boost_charge, 0.0)
        self.assertFalse(eng.boost_active)


class TestSustain(unittest.TestCase):
    def test_hold_accrues_points(self):
        eng, clock = make([{"lane": 0, "time": 1000.0, "end": 2000.0}])
        clock.ms = 1000
        eng.press_lane(0)
        self.assertEqual(eng.counts["perfect"], 1)
        base = eng.score
        clock.ms = 1300
        eng.update(0.1)  # 100 pts/s * 0.1 = 10
        self.assertAlmostEqual(eng.score - base, 10.0, places=3)

    def test_release_stops_accrual(self):
        eng, clock = make([{"lane": 0, "time": 1000.0, "end": 2000.0}])
        clock.ms = 1000
        eng.press_lane(0)
        eng.update(0.1)
        val = eng.score
        eng.release_lane(0)
        clock.ms = 1400
        eng.update(0.5)
        self.assertEqual(eng.score, val)

    def test_hold_finishes_at_tail(self):
        eng, clock = make([{"lane": 0, "time": 1000.0, "end": 1200.0}])
        clock.ms = 1000
        eng.press_lane(0)
        clock.ms = 1200 + 141
        eng.update(0.016)
        from game.engine.note import HIT
        self.assertEqual(eng.notes[0].status, HIT)

    def test_ten_second_hold_stays_active_for_the_full_duration(self):
        from game.engine.note import HIT, HOLDING
        eng, clock = make([{"lane": 0, "time": 1000.0, "end": 11000.0}])
        clock.ms = 1000
        eng.press_lane(0)
        self.assertEqual(eng.notes[0].status, HOLDING)
        base = eng.score
        # still holding 9 s in, still accruing
        clock.ms = 10000
        eng.update(0.5)
        self.assertEqual(eng.notes[0].status, HOLDING)
        self.assertAlmostEqual(eng.score - base, 50.0, places=3)
        # accrues right up to the tail...
        clock.ms = 11000
        eng.update(0.1)
        self.assertEqual(eng.notes[0].status, HOLDING)
        # ...and only completes once the tail passes the judgment window
        clock.ms = 11000 + 141
        eng.update(0.016)
        self.assertEqual(eng.notes[0].status, HIT)
        self.assertTrue(eng.finished)


class TestFinish(unittest.TestCase):
    def test_finished_after_all_notes(self):
        eng, clock = make([{"lane": 0, "time": 1000.0}])
        clock.ms = 1000
        eng.press_lane(0)
        clock.ms = 1200
        eng.update(0.016)
        self.assertTrue(eng.finished)


if __name__ == "__main__":
    unittest.main()
