"""Headless tests for the game logic (no pygame needed).
Run from the project root:  python -m unittest discover -s tests -t .
"""
import unittest
from src import settings as S
from src.level import Level
from src.level_manager import LevelManager, compute_rank, compute_score
from src.player import Intent
from tests.level_lint import lint

DT = 1 / 60.0
T = S.TILE


def room(w=24, h=10, extra=None, entities=None, required=0, spawns=True, exits=True):
    """Build an open room: walls around, floor tile row at h-1, robots standing on row h-2.
    `extra` maps (col,row) -> char to stamp on the grid."""
    g = [["."] * w for _ in range(h)]
    for c in range(w):
        g[0][c] = g[h - 1][c] = "#"
    for r in range(h):
        g[r][0] = g[r][w - 1] = "#"
    if spawns:
        g[h - 2][2], g[h - 2][4] = "r", "u"
    if exits:
        g[h - 2][w - 6], g[h - 2][w - 3] = "x", "b"
    for (c, r), ch in (extra or {}).items():
        g[r][c] = ch
    return Level({"name": "t", "map": ["".join(r) for r in g], "entities": entities or [],
                  "required_crystals": required})


def run(level, players, frames, intents=None):
    """Advance the simulation exactly like PlayScene does."""
    evs = []
    for f in range(frames):
        evs += level.update_mechanisms(DT, players)
        for i, p in enumerate(players):
            p.update(DT, intents(f, i) if intents else Intent(), level)
        evs += level.post_update(DT, players)
    return evs


def floor_row(lv):
    return lv.rows - 2          # row the robots stand on


class PhysicsTests(unittest.TestCase):
    def setUp(self):
        self.lv = room()
        self.px, self.pb = self.lv.create_players()
        self.floor_y = (floor_row(self.lv) + 1) * T

    def test_gravity_lands_and_stays_grounded(self):
        self.px.box.y -= 100
        run(self.lv, [self.px, self.pb], 60)
        self.assertTrue(self.px.on_ground)
        self.assertAlmostEqual(self.px.box.bottom, self.floor_y, places=2)

    def test_jump_reaches_expected_height(self):
        run(self.lv, [self.px], 10)
        peak = self.px.box.bottom
        for f in range(70):
            self.px.update(DT, Intent(0, f == 0, True), self.lv)
            peak = min(peak, self.px.box.bottom)
        rise = self.floor_y - peak
        self.assertGreater(rise, 125)   # clears a 3-tile ledge with margin
        self.assertLess(rise, 160)      # but not a 4-tile one

    def test_short_hop_when_key_released(self):
        run(self.lv, [self.px], 10)
        peak = self.px.box.bottom
        for f in range(70):
            self.px.update(DT, Intent(0, f == 0, False), self.lv)
            peak = min(peak, self.px.box.bottom)
        self.assertLess(self.floor_y - peak, 60)

    def test_coyote_time_allows_late_jump(self):
        run(self.lv, [self.px], 10)
        self.px.on_ground = False                    # just walked off a ledge
        self.px.coyote = S.COYOTE_TIME * 0.5
        ev = self.px.step(DT, 0, True, True, self.lv.solids_near)
        self.assertIn("jump", ev)

    def test_no_coyote_after_it_expires(self):
        run(self.lv, [self.px], 10)
        self.px.box.y -= 80
        self.px.on_ground = False
        self.px.coyote = 0.0
        ev = self.px.step(DT, 0, True, True, self.lv.solids_near)
        self.assertNotIn("jump", ev)

    def test_jump_buffer_fires_on_landing(self):
        run(self.lv, [self.px], 10)
        self.px.box.y -= 6                           # hovering just above the floor
        self.px.on_ground = False
        self.px.coyote = 0.0
        self.px.step(DT, 0, True, True, self.lv.solids_near)       # pressed in the air: buffered
        jumped = any("jump" in self.px.step(DT, 0, False, True, self.lv.solids_near) for _ in range(8))
        self.assertTrue(jumped)

    def test_no_tunnelling_at_terminal_velocity(self):
        self.px.box.y = 1.2 * T
        self.px.vy = S.MAX_FALL_SPEED
        for _ in range(60):
            self.px.step(S.MAX_DT, 0, False, False, self.lv.solids_near)
        self.assertLessEqual(self.px.box.bottom, self.floor_y + 0.01)

    def test_walls_block_horizontal_motion(self):
        run(self.lv, [self.px], 200, lambda f, i: Intent(-1))
        self.assertGreaterEqual(self.px.box.left, T - 0.01)
        run(self.lv, [self.px], 400, lambda f, i: Intent(1))
        self.assertLessEqual(self.px.box.right, (self.lv.cols - 1) * T + 0.01)

    def test_ceiling_stops_jump(self):
        lv = room(w=12, h=5)                         # only 3 free rows: 120 px of headroom
        p = lv.create_players()[0]
        for f in range(40):
            p.update(DT, Intent(0, f == 0, True), lv)
            self.assertGreaterEqual(p.box.top, T - 0.01)

    def test_acceleration_is_gradual_and_capped(self):
        run(self.lv, [self.px], 5)
        self.px.update(DT, Intent(1), self.lv)
        self.assertLess(self.px.vx, S.MOVE_SPEED)
        run(self.lv, [self.px], 30, lambda f, i: Intent(1))
        self.assertAlmostEqual(self.px.vx, S.MOVE_SPEED, places=3)

    def test_independent_control_of_both_robots(self):
        run(self.lv, [self.px, self.pb], 20)
        x0, b0 = self.px.box.x, self.pb.box.x
        run(self.lv, [self.px, self.pb], 30, lambda f, i: Intent(1) if i == 0 else Intent(-1))
        self.assertGreater(self.px.box.x, x0)
        self.assertLess(self.pb.box.x, b0)


class HazardTests(unittest.TestCase):
    def _drop_into(self, ch, kind):
        w, h = 20, 8
        extra = {(c, h - 2): ch for c in range(5, 9)}       # a pool tile row replaces the floor row
        lv = room(w=w, h=h, extra=extra)
        ps = lv.create_players()
        p = [q for q in ps if q.kind == kind][0]
        p.box.x, p.box.y = 6 * T, (h - 5) * T
        for _ in range(90):
            lv.update_mechanisms(DT, ps)
            p.update(DT, Intent(), lv)
            lv.post_update(DT, ps)
        return p

    def test_red_dies_in_water_and_survives_lava(self):
        self.assertFalse(self._drop_into("W", "x").alive)
        self.assertTrue(self._drop_into("L", "x").alive)

    def test_blue_dies_in_lava_and_survives_water(self):
        self.assertFalse(self._drop_into("L", "b").alive)
        self.assertTrue(self._drop_into("W", "b").alive)

    def test_spikes_kill_both(self):
        for kind in ("x", "b"):
            w, h = 20, 8
            lv = room(w=w, h=h, extra={(c, h - 2): "^" for c in range(6, 9)})
            ps = lv.create_players()
            p = [q for q in ps if q.kind == kind][0]
            p.box.x, p.box.y = 7 * T - 14, (h - 5) * T
            for _ in range(60):
                lv.update_mechanisms(DT, ps)
                p.update(DT, Intent(), lv)
                lv.post_update(DT, ps)
            self.assertFalse(p.alive, kind)

    def test_pit_kills(self):
        lv = room()
        p = lv.create_players()[0]
        p.box.y = lv.pixel_h + S.FALL_DEATH_MARGIN + 5
        evs = lv.post_update(DT, [p])
        self.assertFalse(p.alive)
        self.assertEqual(evs[0][:2], ("death", p))

    def test_dead_robot_ignores_input(self):
        lv = room()
        p = lv.create_players()[0]
        p.kill("lava")
        x = p.box.x
        p.update(DT, Intent(1, True, True), lv)
        self.assertEqual(p.box.x, x)
        self.assertEqual(p.anim_state, "death")


class MechanismTests(unittest.TestCase):
    def test_button_opens_door_and_closed_door_blocks(self):
        ents = [{"type": "button", "id": "a", "x": 6, "y": 8},
                {"type": "door", "x": 10, "y": 6, "w": 1, "h": 3, "triggers": ["a"]}]
        lv = room(entities=ents)
        px, pb = lv.create_players()
        run(lv, [pb], 300, lambda f, i: Intent(1))
        self.assertLessEqual(pb.box.right, 10 * T + 0.01)               # blocked by the closed door
        px.box.x = 6 * T + 6                                             # red steps on the button
        run(lv, [px, pb], 60, lambda f, i: Intent(1) if i == 1 else Intent())
        self.assertTrue(lv.buttons["a"].active)
        self.assertGreater(pb.box.right, 10 * T)                         # blue got through
        px.box.x = 3 * T                                                 # red leaves: door closes
        run(lv, [px], 60)
        self.assertFalse(lv.buttons["a"].active)
        self.assertGreater(lv.doors[0].solid_box.h, 100)

    def test_latch_button_stays_on(self):
        lv = room(entities=[{"type": "button", "id": "a", "x": 6, "y": 8, "latch": True}])
        px, pb = lv.create_players()
        px.box.x = 6 * T + 6
        run(lv, [px], 20)
        px.box.x = 2 * T
        run(lv, [px], 20)
        self.assertTrue(lv.buttons["a"].active)

    def test_all_mode_needs_every_trigger(self):
        ents = [{"type": "button", "id": "a", "x": 5, "y": 8}, {"type": "button", "id": "b", "x": 7, "y": 8},
                {"type": "door", "x": 10, "y": 6, "w": 1, "h": 3, "triggers": ["a", "b"], "mode": "all"}]
        lv = room(entities=ents)
        px, pb = lv.create_players()
        px.box.x = 5 * T + 6
        run(lv, [px, pb], 60)
        self.assertEqual(lv.doors[0].open_amount, 0.0)
        pb.box.x = 7 * T + 6
        run(lv, [px, pb], 60)
        self.assertEqual(lv.doors[0].open_amount, 1.0)

    def test_door_does_not_crush(self):
        ents = [{"type": "button", "id": "a", "x": 6, "y": 8},
                {"type": "door", "x": 10, "y": 6, "w": 1, "h": 3, "triggers": ["a"]}]
        lv = room(entities=ents)
        px, pb = lv.create_players()
        px.box.x = 6 * T + 6
        run(lv, [px, pb], 60)
        pb.box.x = 10 * T + 6                   # blue stands in the open doorway
        px.box.x = 2 * T                        # button released
        run(lv, [px, pb], 60)
        self.assertEqual(lv.doors[0].open_amount, 1.0)

    def test_mover_carries_rider(self):
        ents = [{"type": "mover", "x": 3, "y": 8, "w": 3, "dx": 6, "dy": 0, "speed": 120}]
        lv = room(entities=ents)
        px, pb = lv.create_players()
        px.box.x, px.box.y = 4 * T, 8 * T - S.PLAYER_H - 1
        start = px.box.x
        run(lv, [px], 90)
        self.assertGreater(px.box.x, start + 80)
        self.assertTrue(px.on_ground)
        self.assertIs(px.ground_solid, lv.movers[0].box)

    def test_vertical_mover_lifts_rider_when_powered(self):
        ents = [{"type": "button", "id": "a", "x": 1, "y": 8},
                {"type": "mover", "x": 8, "y": 9, "w": 2, "dx": 0, "dy": -5, "speed": 100, "triggers": ["a"]}]
        lv = room(entities=ents, extra={(8, 9): ".", (9, 9): "."})
        px, pb = lv.create_players()
        pb.box.x, pb.box.y = 8 * T + 6, 9 * T - S.PLAYER_H - 1
        run(lv, [pb], 30)
        self.assertEqual(lv.movers[0].t, 0.0)                    # idle without power
        px.box.x = 1 * T + 6
        y0 = pb.box.y
        run(lv, [px, pb], 90)
        self.assertLess(pb.box.y, y0 - 80)                       # rode up with it

    def test_fading_platform_crumbles_and_returns(self):
        ents = [{"type": "fading", "x": 8, "y": 6, "w": 2, "delay": 0.3, "respawn": 1.0}]
        lv = room(entities=ents)
        px, pb = lv.create_players()
        px.box.x, px.box.y = 8 * T + 4, 6 * T - S.PLAYER_H - 1
        run(lv, [px], 10)
        self.assertEqual(lv.fadings[0].state, "crumbling")
        run(lv, [px], 40)
        self.assertEqual(lv.fadings[0].state, "gone")
        px.box.x = 2 * T
        run(lv, [px], 90)
        self.assertEqual(lv.fadings[0].state, "solid")

    def test_electric_barrier_kills_unless_powered_off(self):
        ents = [{"type": "button", "id": "a", "x": 1, "y": 8},
                {"type": "barrier", "x": 8, "y": 6, "w": 1, "h": 3, "triggers": ["a"]}]
        lv = room(entities=ents)
        px, pb = lv.create_players()
        pb.box.x = 6 * T
        run(lv, [pb], 300, lambda f, i: Intent(1))
        self.assertFalse(pb.alive)
        lv2 = room(entities=ents)
        a, b = lv2.create_players()
        a.box.x = 1 * T + 6                        # red holds the button while blue crosses
        b.box.x = 6 * T
        run(lv2, [a, b], 120, lambda f, i: Intent(1) if i == 1 else Intent())
        self.assertTrue(b.alive)
        self.assertGreater(b.box.x, 9 * T)

    def test_bridge_extends_and_supports_robot(self):
        w, h = 24, 10
        extra = {(c, h - 1): "." for c in range(8, 14)}
        ents = [{"type": "button", "id": "a", "x": 1, "y": 8},
                {"type": "bridge", "x": 8, "y": 9, "w": 6, "triggers": ["a"]}]
        lv = room(w=w, h=h, entities=ents, extra={**extra, **{(c, h - 1): "." for c in range(8, 14)}})
        lv.pixel_h = 14 * T                                    # leave room to fall
        px, pb = lv.create_players()
        self.assertEqual(lv.bridges[0].solids(), [])
        px.box.x = 1 * T + 6
        run(lv, [px], 60)
        self.assertAlmostEqual(lv.bridges[0].box.w, 6 * T, delta=1)


class WinConditionTests(unittest.TestCase):
    @staticmethod
    def _at_doors(lv, ps):
        for p in ps:
            ex = lv.exits[p.kind]
            p.box.x = ex.x + (T - p.box.w) / 2
            p.box.y = ex.bottom - p.box.h

    def test_level_needs_both_robots(self):
        lv = room()
        px, pb = lv.create_players()
        self._at_doors(lv, [px])
        run(lv, [px, pb], 10)
        self.assertFalse(lv.completed)
        self._at_doors(lv, [px, pb])
        evs = run(lv, [px, pb], 5)
        self.assertTrue(lv.completed)
        self.assertIn(("complete",), evs)

    def test_each_door_only_accepts_its_robot(self):
        lv = room()
        px, pb = lv.create_players()
        eb, ex = lv.exits["b"], lv.exits["x"]
        px.box.x, px.box.y = eb.x + 6, eb.bottom - px.box.h          # red inside BLUE's door
        pb.box.x, pb.box.y = ex.x + 6, ex.bottom - pb.box.h          # blue inside RED's door
        run(lv, [px, pb], 5)
        self.assertFalse(lv.completed)

    def test_dead_robot_cannot_finish(self):
        lv = room()
        px, pb = lv.create_players()
        self._at_doors(lv, [px, pb])
        pb.kill("lava")
        run(lv, [px, pb], 5)
        self.assertFalse(lv.completed)

    def test_required_crystals_gate_completion(self):
        lv = room(extra={(3, 8): "*"}, required=1)
        px, pb = lv.create_players()
        self._at_doors(lv, [px, pb])
        run(lv, [px, pb], 5)
        self.assertFalse(lv.completed)
        px.box.x, px.box.y = 3 * T + 6, 8 * T            # grab it
        run(lv, [px], 3)
        self.assertEqual(lv.crystals_collected, 1)
        self._at_doors(lv, [px, pb])
        run(lv, [px, pb], 5)
        self.assertTrue(lv.completed)

    def test_either_robot_collects_crystals(self):
        for idx in (0, 1):
            lv = room(extra={(3, 8): "*"})
            ps = lv.create_players()
            ps[idx].box.x, ps[idx].box.y = 3 * T + 6, 8 * T
            run(lv, ps, 3)
            self.assertEqual(lv.crystals_collected, 1)

    def test_timer_stops_after_completion(self):
        lv = room()
        ps = lv.create_players()
        self._at_doors(lv, ps)
        run(lv, ps, 5)
        t = lv.time
        run(lv, ps, 30)
        self.assertEqual(lv.time, t)


class LevelDataTests(unittest.TestCase):
    def test_all_levels_load_and_are_geometrically_reachable(self):
        lm = LevelManager()
        self.assertGreaterEqual(lm.count, 5)
        for i in range(lm.count):
            lv = lm.load(i)
            self.assertEqual(lint(lv), [], lv.name)
            self.assertGreaterEqual(lv.total_crystals, lv.required_crystals)

    def test_levels_have_distinct_layouts(self):
        lm = LevelManager()
        maps = [tuple(lm.load(i).grid) for i in range(lm.count)]
        self.assertEqual(len(set(maps)), lm.count)

    def test_rank_and_score(self):
        self.assertEqual(compute_rank(50, 60, 10, 10), "S")
        self.assertEqual(compute_rank(80, 60, 9, 10), "A")
        self.assertEqual(compute_rank(500, 60, 1, 10), "C")
        self.assertGreater(compute_score(40, 60, 10, 10), compute_score(40, 60, 5, 10))


if __name__ == "__main__":
    unittest.main()
