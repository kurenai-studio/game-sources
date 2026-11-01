"""Astro Drift — PyGame edition.

Twist (Python-native showcase):
  1. Procedural nebula background generated once on startup with numpy
     (Gaussian blobs + per-pixel noise — uses surfarray to blit a numpy
     array straight to a pygame Surface, no image assets).
  2. AI autopilot — press Tab to hand the ship to a heuristic AI that
     locks the nearest asteroid, aligns heading, thrusts when far, fires
     when within tolerance, and dodges anything inside a danger radius.

The AI uses only Python stdlib + numpy — no ML, no opaque models.
You can read every decision in the `ai_step()` function.
"""

import math
import random
import sys

import numpy as np
import pygame

W, H = 960, 540
THRUST, ROT_SPEED, DRAG_PER_SEC, MAX_SPEED = 350.0, 4.0, 0.55, 480.0
BULLET_SPEED, BULLET_LIFE, SHOOT_COOLDOWN = 720.0, 1.0, 0.18

SIZE_LARGE, SIZE_MEDIUM, SIZE_SMALL = 2, 1, 0
ASTEROID_RADII = [12.0, 22.0, 40.0]
SCORE_FOR_SIZE = [100, 50, 20]


def generate_nebula(rng: random.Random) -> pygame.Surface:
	"""numpy-built backdrop: dark gradient + Gaussian color clouds + noise stars."""
	img = np.zeros((H, W, 3), dtype=np.float32)
	yy, xx = np.meshgrid(np.arange(H), np.arange(W), indexing="ij")
	img[..., 2] += 0.04 + 0.03 * (yy / H)

	for _ in range(7):
		cx, cy = rng.uniform(0, W), rng.uniform(0, H)
		sx, sy = rng.uniform(80, 220), rng.uniform(60, 180)
		intensity = rng.uniform(0.08, 0.22)
		color = np.array(rng.choice([
			(0.45, 0.20, 0.80), (0.20, 0.45, 0.95),
			(0.85, 0.30, 0.55), (0.10, 0.80, 0.95),
		]))
		gauss = np.exp(-(((xx - cx) / sx) ** 2 + ((yy - cy) / sy) ** 2))
		img += np.einsum("ij,c->ijc", gauss * intensity, color)

	noise = np.random.default_rng(rng.randrange(2**32)).random((H, W)) ** 18
	star_mask = noise > 0.3
	img[star_mask] = np.clip(img[star_mask] + noise[star_mask, None] * 1.6, 0, 1)

	pixels = (np.clip(img, 0, 1) * 255).astype(np.uint8)
	return pygame.surfarray.make_surface(pixels.swapaxes(0, 1))


class Ship:
	def __init__(self) -> None:
		self.x, self.y = W / 2, H / 2
		self.vx = self.vy = 0.0
		self.rot = 0.0
		self.cooldown = 0.0
		self.alive = True


class Asteroid:
	def __init__(self, size: int, x: float, y: float, vx: float, vy: float) -> None:
		self.size = size
		self.r = ASTEROID_RADII[size]
		self.x, self.y, self.vx, self.vy = x, y, vx, vy
		self.spin = random.uniform(-2.0, 2.0)
		self.rot = 0.0
		n = 11
		self.shape = [
			(math.cos(i / n * math.tau) * self.r * random.uniform(0.75, 1.1),
			 math.sin(i / n * math.tau) * self.r * random.uniform(0.75, 1.1))
			for i in range(n)
		]


def spawn_wave(asteroids: list, wave: int) -> None:
	for _ in range(3 + wave):
		edge = random.randint(0, 3)
		if edge == 0: x, y = random.uniform(0, W), -40.0
		elif edge == 1: x, y = W + 40.0, random.uniform(0, H)
		elif edge == 2: x, y = random.uniform(0, W), H + 40.0
		else: x, y = -40.0, random.uniform(0, H)
		to_cx, to_cy = W / 2 - x, H / 2 - y
		base = math.atan2(to_cy, to_cx) + random.uniform(-0.5, 0.5)
		sp = random.uniform(70, 130)
		asteroids.append(Asteroid(SIZE_LARGE, x, y, math.cos(base) * sp, math.sin(base) * sp))


def split(asteroid: Asteroid, out: list) -> None:
	if asteroid.size == SIZE_SMALL:
		return
	for _ in range(2):
		ang = random.uniform(0, math.tau)
		sp = random.uniform(120, 200)
		out.append(Asteroid(asteroid.size - 1, asteroid.x, asteroid.y,
		                    math.cos(ang) * sp, math.sin(ang) * sp))


def wrap_pos(x: float, y: float) -> tuple[float, float]:
	return x % W, y % H


def transform_polygon(points, cx, cy, rot):
	cs, sn = math.cos(rot), math.sin(rot)
	return [(cx + p[0] * cs - p[1] * sn, cy + p[0] * sn + p[1] * cs) for p in points]


def nearest_asteroid(ship: Ship, asteroids: list) -> Asteroid | None:
	best, best_d = None, 1e9
	for a in asteroids:
		d = math.hypot(a.x - ship.x, a.y - ship.y)
		if d < best_d:
			best, best_d = a, d
	return best


def angular_diff(a: float, b: float) -> float:
	d = (a - b + math.pi) % math.tau - math.pi
	return d


def ai_step(ship: Ship, asteroids: list, dt: float) -> tuple[bool, bool, bool, bool]:
	"""Return (rotate_left, rotate_right, thrust, fire) booleans for this frame."""
	target = nearest_asteroid(ship, asteroids)
	if target is None:
		return False, False, False, False

	desired_heading = math.atan2(target.y - ship.y, target.x - ship.x) + math.pi / 2
	current = ship.rot
	diff = angular_diff(desired_heading, current)
	rotate_left = diff < -0.05
	rotate_right = diff > 0.05

	dist = math.hypot(target.x - ship.x, target.y - ship.y)
	aligned = abs(diff) < 0.18
	thrust = aligned and dist > 180

	danger = False
	for a in asteroids:
		if math.hypot(a.x - ship.x, a.y - ship.y) < a.r + 80:
			danger = True
			break
	if danger:
		thrust = True
		rotate_left = diff < 0
		rotate_right = diff > 0

	fire = aligned and dist < 500
	return rotate_left, rotate_right, thrust, fire


def main() -> None:
	pygame.init()
	screen = pygame.display.set_mode((W, H))
	pygame.display.set_caption("Astro Drift — PyGame (numpy nebula + AI autopilot)")
	clock = pygame.time.Clock()
	font = pygame.font.SysFont("consolas", 16)
	big_font = pygame.font.SysFont("consolas", 28, bold=True)
	rng = random.Random()

	nebula = generate_nebula(rng)

	ship = Ship()
	asteroids: list[Asteroid] = []
	bullets: list[list[float]] = []
	score, wave, lives = 0, 1, 3
	ai_on = False
	game_over = False

	spawn_wave(asteroids, wave)

	while True:
		dt = clock.tick(60) / 1000.0
		for e in pygame.event.get():
			if e.type == pygame.QUIT:
				pygame.quit(); sys.exit()
			if e.type == pygame.KEYDOWN:
				if e.key == pygame.K_ESCAPE:
					pygame.quit(); sys.exit()
				if e.key == pygame.K_INSERT:
					ai_on = not ai_on
				if e.key == pygame.K_END and game_over:
					ship = Ship(); asteroids.clear(); bullets.clear()
					score, wave, lives, game_over = 0, 1, 3, False
					spawn_wave(asteroids, wave)

		keys = pygame.key.get_pressed()
		braking = False
		if not game_over:
			if ai_on:
				rot_l, rot_r, thrusting, firing = ai_step(ship, asteroids, dt)
			else:
				rot_l = keys[pygame.K_LEFT]
				rot_r = keys[pygame.K_RIGHT]
				thrusting = keys[pygame.K_UP]
				braking = keys[pygame.K_DOWN]
				firing = keys[pygame.K_DELETE]

			if rot_l: ship.rot -= ROT_SPEED * dt
			if rot_r: ship.rot += ROT_SPEED * dt
			if thrusting:
				ship.vx += math.cos(ship.rot - math.pi / 2) * THRUST * dt
				ship.vy += math.sin(ship.rot - math.pi / 2) * THRUST * dt
			damp = (0.08 if braking else DRAG_PER_SEC) ** dt
			ship.vx *= damp; ship.vy *= damp
			sp = math.hypot(ship.vx, ship.vy)
			if sp > MAX_SPEED:
				ship.vx, ship.vy = ship.vx / sp * MAX_SPEED, ship.vy / sp * MAX_SPEED
			ship.x, ship.y = wrap_pos(ship.x + ship.vx * dt, ship.y + ship.vy * dt)

			ship.cooldown -= dt
			if firing and ship.cooldown <= 0.0:
				ship.cooldown = SHOOT_COOLDOWN
				dx, dy = math.cos(ship.rot - math.pi / 2), math.sin(ship.rot - math.pi / 2)
				bullets.append([ship.x + dx * 18, ship.y + dy * 18, dx * BULLET_SPEED, dy * BULLET_SPEED, BULLET_LIFE])

		for b in bullets:
			b[0], b[1] = wrap_pos(b[0] + b[2] * dt, b[1] + b[3] * dt)
			b[4] -= dt
		bullets = [b for b in bullets if b[4] > 0]

		for a in asteroids:
			a.x, a.y = wrap_pos(a.x + a.vx * dt, a.y + a.vy * dt)
			a.rot += a.spin * dt

		new_asteroids: list[Asteroid] = []
		surviving_bullets: list[list[float]] = []
		for b in bullets:
			hit_idx = -1
			for i, a in enumerate(asteroids):
				if math.hypot(b[0] - a.x, b[1] - a.y) < a.r:
					hit_idx = i; break
			if hit_idx >= 0:
				hit = asteroids.pop(hit_idx)
				score += SCORE_FOR_SIZE[hit.size]
				split(hit, new_asteroids)
			else:
				surviving_bullets.append(b)
		bullets = surviving_bullets
		asteroids.extend(new_asteroids)

		if not game_over:
			for a in asteroids:
				if math.hypot(ship.x - a.x, ship.y - a.y) < a.r + 10:
					lives -= 1
					ship.x, ship.y, ship.vx, ship.vy = W / 2, H / 2, 0.0, 0.0
					if lives <= 0: game_over = True
					break

		if not asteroids and not game_over:
			wave += 1
			spawn_wave(asteroids, wave)

		screen.blit(nebula, (0, 0))
		for b in bullets:
			pygame.draw.circle(screen, (255, 240, 140), (int(b[0]), int(b[1])), 3)
			pygame.draw.circle(screen, (255, 220, 100, 80), (int(b[0]), int(b[1])), 6, 1)
		for a in asteroids:
			pts = transform_polygon(a.shape, a.x, a.y, a.rot)
			pygame.draw.polygon(screen, (140, 130, 120), pts)
			pygame.draw.polygon(screen, (235, 230, 220), pts, 2)
		if not game_over:
			hull = transform_polygon([(0, -14), (10, 12), (0, 6), (-10, 12)], ship.x, ship.y, ship.rot)
			pygame.draw.polygon(screen, (230, 242, 255), hull)
			pygame.draw.polygon(screen, (140, 192, 255), hull, 2)
			if keys[pygame.K_UP] and not ai_on:
				flame = transform_polygon([(-5, 8), (0, 18 + random.uniform(0, 6)), (5, 8)], ship.x, ship.y, ship.rot)
				pygame.draw.polygon(screen, (255, 153, 51), flame)

		hud_color = (220, 230, 255) if not ai_on else (255, 200, 120)
		mode = "AI AUTOPILOT" if ai_on else "MANUAL"
		hud_text = f"Score {score}   Wave {wave}   Lives {lives}   [{mode}]"
		screen.blit(font.render(hud_text, True, hud_color), (12, 12))

		controls = "← → rotate  |  ↑ thrust  |  ↓ brake  |  Del fire  |  Ins toggle AI  |  End restart  |  Esc quit"
		ctl_surf = font.render(controls, True, (160, 175, 215))
		screen.blit(ctl_surf, (W // 2 - ctl_surf.get_width() // 2, H - 22))

		if game_over:
			over = big_font.render("GAME OVER — press End to restart", True, (255, 220, 160))
			screen.blit(over, (W // 2 - over.get_width() // 2, H // 2 - 20))

		pygame.display.flip()


if __name__ == "__main__":
	main()
