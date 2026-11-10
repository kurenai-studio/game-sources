"""
Lane Legends: Human vs AI
entities.py - Vehicle Physics, Procedural Car & Obstacle Sprites, and Particle Systems.
"""

import math
import random
from typing import List, Tuple, Optional

import pygame
from settings import (
    CAR_WIDTH,
    CAR_HEIGHT,
    CAR_RESTING_Y,
    LANE_CHANGE_LERP,
    BASE_SPEED,
    MAX_SPEED,
    NITRO_SPEED,
    MIN_SPEED,
    ACCELERATION,
    BRAKING_DECEL,
    COAST_DECEL,
    NITRO_CAPACITY,
    NITRO_DRAIN_RATE,
    NITRO_RECHARGE_RATE,
    NITRO_BOOST_MULTIPLIER,
    COLLISION_SPEED_DROP,
    INVULNERABILITY_TIME,
    OIL_SLIP_DURATION,
    OBSTACLE_TRAFFIC,
    OBSTACLE_BARRIER,
    OBSTACLE_CONE,
    OBSTACLE_OIL,
    COLOR_WHITE,
    COLOR_CYAN,
    COLOR_ORANGE,
    COLOR_CRIMSON,
    COLOR_YELLOW,
)


class Particle:
    """Individual particle for exhaust, nitro flames, and crash sparks."""
    def __init__(
        self,
        x: float,
        y: float,
        vx: float,
        vy: float,
        color: Tuple[int, int, int],
        radius: float,
        life: float,
    ):
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.color = color
        self.radius = radius
        self.max_life = life
        self.life = life

    def update(self, dt: float) -> bool:
        """Update particle physics and lifetime. Returns False when dead."""
        self.x += self.vx * dt
        self.y += self.vy * dt
        self.life -= dt
        return self.life > 0

    def render(self, surface: pygame.Surface) -> None:
        """Draw particle with alpha fade."""
        if self.life <= 0:
            return
        fraction = max(0.0, self.life / self.max_life)
        cur_radius = max(1.0, self.radius * fraction)
        # Soft circle rendering
        color_with_alpha = (
            self.color[0],
            self.color[1],
            self.color[2],
            int(255 * fraction),
        )
        s = pygame.Surface((int(cur_radius * 2) + 2, int(cur_radius * 2) + 2), pygame.SRCALPHA)
        pygame.draw.circle(s, color_with_alpha, (int(cur_radius) + 1, int(cur_radius) + 1), int(cur_radius))
        surface.blit(s, (self.x - cur_radius, self.y - cur_radius))


class Obstacle:
    """
    Track obstacle with procedural rendering for cars, barriers, cones, and oil slicks.
    """

    def __init__(
        self,
        obstacle_type: str,
        lane: int,
        world_distance: float,  # absolute distance along the track
        lane_x: float,
    ):
        self.obstacle_type = obstacle_type
        self.lane = lane
        self.world_distance = world_distance  # in race distance units
        self.lane_x = lane_x
        self.screen_y = -200.0  # computed dynamically based on car progress
        self.has_collided = False
        self.has_passed = False

        # Dimensions by obstacle type
        if obstacle_type == OBSTACLE_TRAFFIC:
            self.width = 48
            self.height = 84
            self.color = random.choice([
                (230, 190, 40),   # Taxi Yellow
                (140, 60, 210),   # Purple Cruiser
                (40, 180, 120),   # Mint Sedan
                (200, 70, 70),    # Maroon Compact
            ])
        elif obstacle_type == OBSTACLE_BARRIER:
            self.width = 80
            self.height = 28
            self.color = (255, 120, 0)
        elif obstacle_type == OBSTACLE_CONE:
            self.width = 32
            self.height = 32
            self.color = (255, 100, 0)
        elif obstacle_type == OBSTACLE_OIL:
            self.width = 72
            self.height = 48
            self.color = (30, 32, 40)
        else:
            self.width = 44
            self.height = 44
            self.color = (200, 200, 200)

    @property
    def rect(self) -> pygame.Rect:
        """Collision hitbox centered on lane."""
        return pygame.Rect(
            int(self.lane_x - self.width // 2),
            int(self.screen_y - self.height // 2),
            self.width,
            self.height,
        )

    def render(self, surface: pygame.Surface) -> None:
        """Render arcade obstacle graphics."""
        # Only render if on or near screen
        if self.screen_y < -100 or self.screen_y > 800:
            return

        cx = int(self.lane_x)
        cy = int(self.screen_y)

        if self.obstacle_type == OBSTACLE_TRAFFIC:
            # Traffic Car (Top-down sedan)
            w, h = self.width, self.height
            # Shadow
            pygame.draw.rect(surface, (10, 12, 18, 140), (cx - w // 2 + 4, cy - h // 2 + 6, w, h), border_radius=6)
            # Body
            pygame.draw.rect(surface, self.color, (cx - w // 2, cy - h // 2, w, h), border_radius=6)
            # Roof / Windshield
            roof_rect = pygame.Rect(cx - w // 2 + 6, cy - h // 2 + 18, w - 12, h - 36)
            pygame.draw.rect(surface, (35, 42, 54), roof_rect, border_radius=4)
            # Front & Rear windshields
            pygame.draw.rect(surface, (18, 22, 30), (cx - w // 2 + 8, cy - h // 2 + 14, w - 16, 7), border_radius=2)
            pygame.draw.rect(surface, (18, 22, 30), (cx - w // 2 + 8, cy + h // 2 - 21, w - 16, 7), border_radius=2)
            # Taillights (Red)
            pygame.draw.rect(surface, (255, 40, 40), (cx - w // 2 + 4, cy + h // 2 - 4, 10, 4), border_radius=2)
            pygame.draw.rect(surface, (255, 40, 40), (cx + w // 2 - 14, cy + h // 2 - 4, 10, 4), border_radius=2)
            # Headlights (Soft amber glow towards top)
            pygame.draw.rect(surface, (255, 240, 160), (cx - w // 2 + 4, cy - h // 2, 10, 3), border_radius=1)
            pygame.draw.rect(surface, (255, 240, 160), (cx + w // 2 - 14, cy - h // 2, 10, 3), border_radius=1)

        elif self.obstacle_type == OBSTACLE_BARRIER:
            # Road Barrier with diagonal caution stripes
            w, h = self.width, self.height
            # Shadow
            pygame.draw.rect(surface, (10, 12, 18, 140), (cx - w // 2 + 3, cy - h // 2 + 5, w, h), border_radius=4)
            # Base metal frame
            pygame.draw.rect(surface, (60, 65, 75), (cx - w // 2, cy - h // 2, w, h), border_radius=4)
            pygame.draw.rect(surface, (240, 240, 245), (cx - w // 2 + 2, cy - h // 2 + 2, w - 4, h - 4), border_radius=3)
            # Diagonal orange stripes
            stripe_width = 14
            for x_offset in range(-w // 2 + 2, w // 2 - 2, stripe_width * 2):
                pts = [
                    (cx + x_offset, cy + h // 2 - 2),
                    (cx + x_offset + stripe_width, cy + h // 2 - 2),
                    (cx + x_offset + stripe_width + 8, cy - h // 2 + 2),
                    (cx + x_offset + 8, cy - h // 2 + 2),
                ]
                pygame.draw.polygon(surface, (255, 110, 0), pts)
            # Legs
            pygame.draw.circle(surface, (80, 85, 95), (cx - w // 2 + 6, cy), 4)
            pygame.draw.circle(surface, (80, 85, 95), (cx + w // 2 - 6, cy), 4)

        elif self.obstacle_type == OBSTACLE_CONE:
            # Traffic Cone (Circular base, conical ring, reflective band)
            r = self.width // 2
            # Drop shadow
            pygame.draw.ellipse(surface, (10, 12, 18, 140), (cx - r + 3, cy - r + 5, r * 2, r * 2))
            # Square rubber base
            pygame.draw.rect(surface, (240, 90, 0), (cx - r, cy - r, r * 2, r * 2), border_radius=4)
            # Inner orange circle
            pygame.draw.circle(surface, (255, 120, 10), (cx, cy), r - 3)
            # White reflective ring
            pygame.draw.circle(surface, (245, 245, 245), (cx, cy), r - 7)
            # Central orange tip
            pygame.draw.circle(surface, (255, 100, 0), (cx, cy), r - 11)

        elif self.obstacle_type == OBSTACLE_OIL:
            # Oil Spill (Iridescent glossy slick puddle)
            w, h = self.width, self.height
            # Outer dark spill blob
            puddle_surf = pygame.Surface((w + 10, h + 10), pygame.SRCALPHA)
            pygame.draw.ellipse(puddle_surf, (20, 24, 30, 220), (5, 5, w, h))
            # Inner rainbow shimmer sheen
            pygame.draw.ellipse(puddle_surf, (80, 40, 110, 160), (14, 10, w - 18, h - 12))
            pygame.draw.ellipse(puddle_surf, (40, 130, 150, 130), (22, 14, w - 34, h - 20))
            # Gloss highlight
            pygame.draw.ellipse(puddle_surf, (220, 240, 255, 140), (18, 12, 18, 8))
            surface.blit(puddle_surf, (cx - (w + 10) // 2, cy - (h + 10) // 2))


class Car:
    """
    Racer entity with smooth arcade physics, procedural sprite, nitro, and collision states.
    """

    def __init__(
        self,
        name: str,
        color: Tuple[int, int, int],
        lanes: List[int],
        start_lane: int = 1,
        is_ai: bool = False,
        speed_multiplier: float = 1.0,
    ):
        self.name = name
        self.color = color
        self.lanes = lanes  # X coordinates of the 3 lanes
        self.current_lane = start_lane
        self.target_lane = start_lane
        self.x = float(lanes[start_lane])
        self.y = float(CAR_RESTING_Y)
        self.is_ai = is_ai
        self.speed_multiplier = speed_multiplier

        # Physics & Speed
        self.speed = BASE_SPEED * self.speed_multiplier
        self.target_speed = BASE_SPEED * self.speed_multiplier
        self.max_speed = MAX_SPEED * self.speed_multiplier
        self.is_nitro_active = False
        self.is_braking = False

        # Nitro
        self.nitro_meter = NITRO_CAPACITY
        self.boosts_used = 0

        # State Timers
        self.invulnerable_timer = 0.0
        self.oil_slip_timer = 0.0
        self.tilt_angle = 0.0  # visual banking during lane changes

        # Race Progress & Metrics
        self.distance_traveled = 0.0
        self.score = 0
        self.collisions_count = 0
        self.obstacles_passed = 0
        self.has_finished = False
        self.finish_time = 0.0

        # Particle System
        self.particles: List[Particle] = []
        self.particle_timer = 0.0

    @property
    def rect(self) -> pygame.Rect:
        """Collision hitbox centered on current coordinates."""
        return pygame.Rect(
            int(self.x - CAR_WIDTH // 2),
            int(self.y - CAR_HEIGHT // 2),
            CAR_WIDTH,
            CAR_HEIGHT,
        )

    def change_lane(self, direction: int) -> bool:
        """
        Attempt to switch lane: -1 for Left, +1 for Right.
        Returns True if lane switch initiated, False if at boundary.
        """
        new_lane = self.target_lane + direction
        if 0 <= new_lane < len(self.lanes):
            self.target_lane = new_lane
            self.current_lane = new_lane
            # Set initial tilt angle for dynamic visual feel
            self.tilt_angle = -12.0 if direction < 0 else 12.0
            return True
        return False

    def activate_nitro(self) -> bool:
        """Engage nitro boost if sufficient meter remains."""
        if self.nitro_meter > 12.0:
            if not self.is_nitro_active:
                self.boosts_used += 1
            self.is_nitro_active = True
            return True
        self.is_nitro_active = False
        return False

    def deactivate_nitro(self) -> None:
        """Disengage nitro boost."""
        self.is_nitro_active = False

    def set_brake(self, active: bool) -> None:
        """Engage or release brakes."""
        self.is_braking = active

    def handle_collision(self, obstacle_type: str, sound_mgr=None) -> None:
        """
        Handle impact with obstacle. Reduces speed, deducts points, and triggers visual feedback.
        """
        if self.invulnerable_timer > 0:
            return  # Currently invulnerable from recent hit

        self.collisions_count += 1
        self.invulnerable_timer = INVULNERABILITY_TIME

        if obstacle_type == OBSTACLE_OIL:
            # Oil Slick: skid effect, less severe direct collision penalty
            self.oil_slip_timer = OIL_SLIP_DURATION
            self.speed = max(MIN_SPEED, self.speed * 0.60)
            self.score = max(0, self.score - 120)
            if sound_mgr:
                sound_mgr.play("skid")
            # Spawn dark oil spray particles
            for _ in range(16):
                ang = random.uniform(0, 2 * math.pi)
                spd = random.uniform(50, 160)
                self.particles.append(Particle(
                    self.x, self.y,
                    math.cos(ang) * spd, math.sin(ang) * spd,
                    (40, 45, 55),
                    random.uniform(3, 6),
                    0.4
                ))
        else:
            # Physical Obstacle Collision
            self.speed = max(MIN_SPEED, self.speed * COLLISION_SPEED_DROP)
            self.score = max(0, self.score - 250)
            if sound_mgr:
                sound_mgr.play("crash")
            # Spawn bright sparks and smoke particles
            for _ in range(24):
                ang = random.uniform(0, 2 * math.pi)
                spd = random.uniform(80, 260)
                color = random.choice([COLOR_YELLOW, COLOR_ORANGE, (255, 80, 40), (255, 255, 255)])
                self.particles.append(Particle(
                    self.x, self.y - 20,
                    math.cos(ang) * spd, math.sin(ang) * spd,
                    color,
                    random.uniform(2, 5),
                    0.45
                ))

    def update(self, dt: float, sound_mgr=None) -> None:
        """Update car physics, lane lerp, speed calculation, and particles."""
        # 1. Timers
        if self.invulnerable_timer > 0:
            self.invulnerable_timer = max(0.0, self.invulnerable_timer - dt)
        if self.oil_slip_timer > 0:
            self.oil_slip_timer = max(0.0, self.oil_slip_timer - dt)

        # 2. Lane Interpolation (Smooth X-axis motion)
        target_x = float(self.lanes[self.target_lane])
        # Add subtle oil wobble if slipping
        if self.oil_slip_timer > 0:
            wobble = math.sin(pygame.time.get_ticks() * 0.02) * 18.0
            target_x += wobble

        diff = target_x - self.x
        self.x += diff * min(1.0, LANE_CHANGE_LERP * dt)

        # Gradually ease tilt angle back to straight
        self.tilt_angle *= max(0.0, 1.0 - 8.0 * dt)

        # 3. Nitro Management
        if self.is_nitro_active:
            if self.nitro_meter > 0:
                self.nitro_meter = max(0.0, self.nitro_meter - NITRO_DRAIN_RATE * dt)
                self.target_speed = NITRO_SPEED * self.speed_multiplier
            else:
                self.is_nitro_active = False
                self.target_speed = self.max_speed
        elif self.is_braking:
            self.target_speed = MIN_SPEED * self.speed_multiplier
            # Recharging nitro while braking/coasting
            self.nitro_meter = min(NITRO_CAPACITY, self.nitro_meter + NITRO_RECHARGE_RATE * dt)
        else:
            self.target_speed = self.max_speed
            self.nitro_meter = min(NITRO_CAPACITY, self.nitro_meter + NITRO_RECHARGE_RATE * dt)

        # 4. Smooth Acceleration / Deceleration
        if self.speed < self.target_speed:
            self.speed = min(self.target_speed, self.speed + ACCELERATION * dt)
        elif self.speed > self.target_speed:
            decel = BRAKING_DECEL if self.is_braking else COAST_DECEL
            self.speed = max(self.target_speed, self.speed - decel * dt)

        # 5. Distance and Score Progress
        distance_step = self.speed * dt
        self.distance_traveled += distance_step
        if not self.has_finished:
            self.score += int(distance_step * 0.08)

        # 6. Particle Emitters (Nitro flames / Exhaust smoke)
        self.particle_timer += dt
        if self.particle_timer >= 0.035:
            self.particle_timer = 0.0
            rear_y = self.y + CAR_HEIGHT // 2 - 4
            left_tail_x = self.x - 14
            right_tail_x = self.x + 14

            if self.is_nitro_active:
                # Intense blue/cyan/orange afterburner flame particles
                for tx in (left_tail_x, right_tail_x):
                    self.particles.append(Particle(
                        tx + random.uniform(-2, 2),
                        rear_y,
                        random.uniform(-10, 10),
                        random.uniform(90, 180),
                        COLOR_CYAN if random.random() < 0.6 else COLOR_YELLOW,
                        random.uniform(4, 7),
                        0.25
                    ))
            else:
                # Normal subtle engine exhaust puff
                if random.random() < 0.35:
                    self.particles.append(Particle(
                        left_tail_x + random.uniform(-2, 2),
                        rear_y,
                        random.uniform(-5, 5),
                        random.uniform(40, 90),
                        (140, 145, 155),
                        random.uniform(2, 4),
                        0.30
                    ))

        # 7. Update active particles
        self.particles = [p for p in self.particles if p.update(dt)]

    def render(self, surface: pygame.Surface) -> None:
        """Draw high-polish procedural sports car with lighting, glass, and particles."""
        # 1. Render particles beneath the car body
        for p in self.particles:
            p.render(surface)

        # 2. Invulnerability blink effect
        if self.invulnerable_timer > 0:
            # Rapid 15Hz flicker
            if int(pygame.time.get_ticks() / 60) % 2 == 0:
                return

        cx = int(self.x)
        cy = int(self.y)
        w = CAR_WIDTH
        h = CAR_HEIGHT

        # Create car surface to allow tilt rotation
        car_surf = pygame.Surface((w + 24, h + 24), pygame.SRCALPHA)
        scx = (w + 24) // 2
        scy = (h + 24) // 2

        # A. Shadow
        shadow_rect = pygame.Rect(scx - w // 2 + 4, scy - h // 2 + 8, w, h)
        pygame.draw.rect(car_surf, (10, 12, 16, 150), shadow_rect, border_radius=12)

        # B. Wheels (4 alloy wheels on chassis corners)
        wheel_w, wheel_h = 8, 18
        wheel_coords = [
            (scx - w // 2 - 2, scy - h // 2 + 10),  # Front Left
            (scx + w // 2 - 6, scy - h // 2 + 10),  # Front Right
            (scx - w // 2 - 2, scy + h // 2 - 26),  # Rear Left
            (scx + w // 2 - 6, scy + h // 2 - 26),  # Rear Right
        ]
        for wx, wy in wheel_coords:
            pygame.draw.rect(car_surf, (20, 22, 28), (wx, wy, wheel_w, wheel_h), border_radius=3)
            # Wheel rim highlight
            pygame.draw.rect(car_surf, (120, 125, 135), (wx + 2, wy + 4, wheel_w - 4, wheel_h - 8), border_radius=1)

        # C. Aerodynamic Main Chassis Body
        body_rect = pygame.Rect(scx - w // 2, scy - h // 2, w, h)
        pygame.draw.rect(car_surf, self.color, body_rect, border_radius=14)

        # D. Racing Stripes / Carbon Accent down the center
        stripe_w = 10
        stripe_color = (
            min(255, int(self.color[0] * 1.3 + 40)),
            min(255, int(self.color[1] * 1.3 + 40)),
            min(255, int(self.color[2] * 1.3 + 40)),
        )
        pygame.draw.rect(car_surf, stripe_color, (scx - stripe_w // 2, scy - h // 2 + 4, stripe_w, h - 8), border_radius=2)

        # E. Cockpit Canopy / Windshield
        cockpit_rect = pygame.Rect(scx - w // 2 + 7, scy - h // 2 + 20, w - 14, h - 42)
        pygame.draw.rect(car_surf, (15, 20, 30), cockpit_rect, border_radius=8)

        # Front Windshield Glass
        pygame.draw.polygon(car_surf, (35, 75, 110), [
            (scx - w // 2 + 9, scy - h // 2 + 32),
            (scx + w // 2 - 9, scy - h // 2 + 32),
            (scx + w // 2 - 12, scy - h // 2 + 22),
            (scx - w // 2 + 12, scy - h // 2 + 22),
        ])
        # Glass Glare Specular Highlight
        pygame.draw.line(car_surf, (140, 200, 255, 180), (scx - w // 2 + 14, scy - h // 2 + 24), (scx - w // 2 + 20, scy - h // 2 + 30), 2)

        # Rear Window Glass
        pygame.draw.rect(car_surf, (25, 55, 80), (scx - w // 2 + 10, scy + h // 2 - 34, w - 20, 9), border_radius=3)

        # F. Rear Racing Spoiler
        spoiler_rect = pygame.Rect(scx - w // 2 + 2, scy + h // 2 - 8, w - 4, 7)
        pygame.draw.rect(car_surf, (25, 28, 35), spoiler_rect, border_radius=3)
        pygame.draw.rect(car_surf, stripe_color, (scx - w // 2 + 4, scy + h // 2 - 7, w - 8, 2))

        # G. Headlights (Bright Xenon glow with forward beam)
        hl_color = (255, 255, 210)
        pygame.draw.rect(car_surf, hl_color, (scx - w // 2 + 5, scy - h // 2 + 1, 9, 4), border_radius=2)
        pygame.draw.rect(car_surf, hl_color, (scx + w // 2 - 14, scy - h // 2 + 1, 9, 4), border_radius=2)

        # H. Taillights (Neon Red LED bar)
        tl_color = (255, 25, 25)
        pygame.draw.rect(car_surf, tl_color, (scx - w // 2 + 5, scy + h // 2 - 3, 10, 3), border_radius=1)
        pygame.draw.rect(car_surf, tl_color, (scx + w // 2 - 15, scy + h // 2 - 3, 10, 3), border_radius=1)

        # 3. Rotate surface according to tilt angle and blit to main display
        if abs(self.tilt_angle) > 0.5:
            rotated = pygame.transform.rotate(car_surf, self.tilt_angle)
            new_rect = rotated.get_rect(center=(cx, cy))
            surface.blit(rotated, new_rect.topleft)
        else:
            surface.blit(car_surf, (cx - (w + 24) // 2, cy - (h + 24) // 2))
