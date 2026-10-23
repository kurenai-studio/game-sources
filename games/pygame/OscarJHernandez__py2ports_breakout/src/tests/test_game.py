from test_common import unittest, pygame, Game
from main import LAYOUTS


class BreakoutTests(unittest.TestCase):
    def setUp(self):
        self.game = Game()
        self.game.handle("confirm")

    def test_explicit_launch_and_paddle_limits(self):
        self.assertTrue(self.game.ready)
        self.game.update(0.1, -1)
        self.assertEqual(self.game.ball_x, self.game.paddle_x)
        for _ in range(30):
            self.game.update(0.1, -1)
        self.assertEqual(self.game.paddle_x, 70)
        self.game.handle("confirm")
        self.assertFalse(self.game.ready)
        y = self.game.ball_y
        self.game.update(0.02)
        self.assertLess(self.game.ball_y, y)

    def test_wall_bounce(self):
        self.game.ready = False
        self.game.ball_x, self.game.ball_y = 30, 300
        self.game.vx, self.game.vy = -200, 0
        self.game.update(0.01)
        self.assertGreater(self.game.vx, 0)

    def test_paddle_bounce(self):
        self.game.ready = False
        self.game.ball_x, self.game.ball_y = 320, 410
        self.game.vx, self.game.vy = 0, 200
        self.game.update(0.03)
        self.assertLess(self.game.vy, 0)
        self.assertEqual(self.game.lives, 3)

    def test_brick_hit_scores_and_reflects(self):
        brick = self.game.bricks[-1]
        count = len(self.game.bricks)
        self.game.ready = False
        self.game.ball_x, self.game.ball_y = brick.centerx, brick.bottom + 7
        self.game.vx, self.game.vy = 0, -200
        self.game.update(0.02)
        self.assertEqual(len(self.game.bricks), count - 1)
        self.assertEqual(self.game.score, 10)
        self.assertGreater(self.game.vy, 0)

    def test_lives_and_game_over(self):
        for lives in (2, 1, 0):
            self.game.ready = False
            self.game.ball_y, self.game.vy = 460, 200
            self.game.update(0.01)
            self.assertEqual(self.game.lives, lives)
            self.assertEqual(self.game.state, "over" if lives == 0 else "playing")
        self.game.handle("confirm")
        self.assertEqual((self.game.lives, self.game.level, self.game.score), (3, 1, 0))

    def test_all_levels_and_victory(self):
        speed = self.game.speed
        for level in (1, 2, 3):
            brick = pygame.Rect(200, 200, 50, 19)
            self.game.bricks = [brick]
            self.game.ready = False
            self.game.ball_x, self.game.ball_y = brick.centerx, brick.bottom + 7
            self.game.vx, self.game.vy = 0, -200
            self.game.update(0.02)
            if level < 3:
                self.assertEqual(self.game.level, level + 1)
                self.assertGreater(self.game.speed, speed)
                speed = self.game.speed
                self.assertTrue(self.game.ready)
            else:
                self.assertEqual(self.game.state, "won")
        self.assertEqual(self.game.score, 30)
        self.assertEqual(len(LAYOUTS), 3)

    def test_pause_resume_and_back_preserve_game(self):
        self.game.handle("confirm")
        self.game.handle("pause")
        before = (self.game.ball_x, self.game.ball_y, self.game.paddle_x)
        self.game.update(0.1, 1)
        self.assertEqual((self.game.ball_x, self.game.ball_y, self.game.paddle_x), before)
        self.game.handle("confirm")
        self.assertFalse(self.game.ready)
        self.game.handle("back")
        self.assertEqual(self.game.state, "paused")
        self.game.handle("back")
        self.assertEqual(self.game.state, "menu")

    def test_high_speed_updates_do_not_skip_bricks(self):
        self.game.level = 3
        self.game.load_level()
        brick = self.game.bricks[-1]
        count = len(self.game.bricks)
        self.game.ready = False
        self.game.ball_x, self.game.ball_y = brick.centerx, brick.bottom + 12
        self.game.vx, self.game.vy = 0, -self.game.speed
        self.game.update(0.08)
        self.assertLess(len(self.game.bricks), count)
