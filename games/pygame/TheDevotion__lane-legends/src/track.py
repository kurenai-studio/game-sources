"""
Lane Legends: Human vs AI
track.py - Dual-track road rendering, animated scrolling, synchronized obstacle manager,
and finish line mechanics.
"""

import math
import random
from typing import List, Tuple, Optional

import pygame
from settings import (
    WINDOW_WIDTH,
    WINDOW_HEIGHT,
    TRACK_WIDTH,
    LANE_WIDTH,
    LANE_COUNT,
    TRACK_1_LEFT,
    TRACK_1_RIGHT,
    TRACK_1_LANES,
    TRACK_2_LEFT,
    TRACK_2_RIGHT,
    TRACK_2_LANES,
    CENTER_DIVIDER_LEFT,
    CENTER_DIVIDER_RIGHT,
    CENTER_DIVIDER_WIDTH,
    CAR_RESTING_Y,
    CAR_HEIGHT,
    RACE_DISTANCE_METERS,
    METERS_PER_PIXEL,
    OBSTACLE_TRAFFIC,
    OBSTACLE_BARRIER,
    OBSTACLE_CONE,
    OBSTACLE_OIL,
    COLOR_BG,
    COLOR_ASPHALT,
    COLOR_ASPHALT_LINE,
    COLOR_GRASS,
    COLOR_GRASS_DETAIL,
    COLOR_KERB_RED,
    COLOR_KERB_WHITE,
    COLOR_LANE_MARKING,
    COLOR_ROAD_BORDER,
    COLOR_CYAN,
    COLOR_ORANGE,
    COLOR_CRIMSON,
    COLOR_WHITE,
    COLOR_MUTED,
)
from entities import Car, Obstacle


class ObstacleBlueprint:
    """Pre-calculated template to ensure 100% fair, symmetrical obstacle placement."""
    def __init__(self, obstacle_type: str, lane: int, world_dist: float):
        self.obstacle_type = obstacle_type
        self.lane = lane
        self.world_dist = world_dist


class DualTrackManager:
    """
    Manages dual parallel racing tracks, road scrolling, symmetrical obstacle spawning,
    collision resolution, and finish line detection.
    """

    def __init__(self, seed: Optional[int] = None):
        self.seed = seed if seed is not None else random.randint(1000, 999999)
        self.total_world_distance = RACE_DISTANCE_METERS / METERS_PER_PIXEL  # ~12,000 px

        # Scrolling texture offsets
        self.scroll_y_p1 = 0.0
        self.scroll_y_p2 = 0.0

        # Symmetrical obstacle stream
        self.blueprints: List[ObstacleBlueprint] = []
        self._generate_blueprints()

        # Active obstacles per track
        self.track_1_obstacles: List[Obstacle] = []
        self.track_2_obstacles: List[Obstacle] = []
        self._spawn_track_obstacles()

    def _generate_blueprints(self) -> None:
        """
        Generate identical obstacle sequence for the entire 3000m race.
        Guarantees fair play and ensures at least one lane is always open.
        """
        rng = random.Random(self.seed)
        cur_dist = 650.0  # First obstacle appears after comfortable start (~150m)

        obstacle_types = [
            (OBSTACLE_TRAFFIC, 0.45),
            (OBSTACLE_BARRIER, 0.25),
            (OBSTACLE_CONE, 0.15),
            (OBSTACLE_OIL, 0.15),
        ]

        def pick_obstacle_type() -> str:
            roll = rng.random()
            cum = 0.0
            for o_type, prob in obstacle_types:
                cum += prob
                if roll <= cum:
                    return o_type
            return OBSTACLE_TRAFFIC

        while cur_dist < self.total_world_distance - 400.0:
            pattern = rng.random()
            if pattern < 0.60:
                # Single lane blocked
                lane = rng.choice([0, 1, 2])
                self.blueprints.append(ObstacleBlueprint(pick_obstacle_type(), lane, cur_dist))
            else:
                # Double lane blocked (pinch point, exactly 1 safe escape lane)
                open_lane = rng.choice([0, 1, 2])
                for l in range(3):
                    if l != open_lane:
                        self.blueprints.append(ObstacleBlueprint(pick_obstacle_type(), l, cur_dist))

            # Dynamic spacing: starts spacious (480-600px), becomes tighter (340-440px)
            difficulty_progress = cur_dist / self.total_world_distance
            min_gap = 480.0 - (140.0 * difficulty_progress)
            max_gap = 620.0 - (140.0 * difficulty_progress)
            cur_dist += rng.uniform(min_gap, max_gap)

    def _spawn_track_obstacles(self) -> None:
        """Instantiate Obstacle objects for Track 1 and Track 2 from identical blueprints."""
        self.track_1_obstacles.clear()
        self.track_2_obstacles.clear()

        for bp in self.blueprints:
            obs1 = Obstacle(
                obstacle_type=bp.obstacle_type,
                lane=bp.lane,
                world_distance=bp.world_dist,
                lane_x=TRACK_1_LANES[bp.lane],
            )
            obs2 = Obstacle(
                obstacle_type=bp.obstacle_type,
                lane=bp.lane,
                world_distance=bp.world_dist,
                lane_x=TRACK_2_LANES[bp.lane],
            )
            self.track_1_obstacles.append(obs1)
            self.track_2_obstacles.append(obs2)

    def get_track_radar(self, track_id: int, car: Car) -> Tuple[float, float, float]:
        """
        Compute the nearest obstacle distance ahead in each of the 3 lanes for AI perception.
        Returns pixel distance ahead: [left_dist, mid_dist, right_dist].
        """
        obstacles = self.track_1_obstacles if track_id == 1 else self.track_2_obstacles
        radar = [9999.0, 9999.0, 9999.0]

        for obs in obstacles:
            dist_ahead = obs.world_distance - car.distance_traveled
            # Looking forward within range
            if dist_ahead >= -20.0:
                if dist_ahead < radar[obs.lane]:
                    radar[obs.lane] = dist_ahead

        return radar[0], radar[1], radar[2]

    def update(self, dt: float, car_p1: Car, car_p2: Car, sound_mgr=None) -> None:
        """
        Update scrolling offsets, project obstacle screen coordinates,
        check collisions, and award passing scores.
        """
        # 1. Road scrolling offsets
        self.scroll_y_p1 = (self.scroll_y_p1 + car_p1.speed * dt) % 80.0
        self.scroll_y_p2 = (self.scroll_y_p2 + car_p2.speed * dt) % 80.0

        # 2. Update Track 1 Obstacles
        for obs in self.track_1_obstacles:
            obs.screen_y = CAR_RESTING_Y - (obs.world_distance - car_p1.distance_traveled)
            # Collision detection
            if not obs.has_collided and obs.rect.colliderect(car_p1.rect):
                obs.has_collided = True
                car_p1.handle_collision(obs.obstacle_type, sound_mgr)
            # Passing detection
            if not obs.has_passed and obs.screen_y > (CAR_RESTING_Y + CAR_HEIGHT // 2 + 10):
                obs.has_passed = True
                if not obs.has_collided:
                    car_p1.obstacles_passed += 1
                    car_p1.score += 150
                    if sound_mgr and not car_p1.is_ai:
                        sound_mgr.play("pass")

        # 3. Update Track 2 Obstacles
        for obs in self.track_2_obstacles:
            obs.screen_y = CAR_RESTING_Y - (obs.world_distance - car_p2.distance_traveled)
            # Collision detection
            if not obs.has_collided and obs.rect.colliderect(car_p2.rect):
                obs.has_collided = True
                car_p2.handle_collision(obs.obstacle_type, sound_mgr)
            # Passing detection
            if not obs.has_passed and obs.screen_y > (CAR_RESTING_Y + CAR_HEIGHT // 2 + 10):
                obs.has_passed = True
                if not obs.has_collided:
                    car_p2.obstacles_passed += 1
                    car_p2.score += 150
                    if sound_mgr and not car_p2.is_ai:
                        sound_mgr.play("pass")

    def render(self, surface: pygame.Surface, car_p1: Car, car_p2: Car) -> None:
        """Draw both race tracks, curbs, lane markings, center divider, obstacles, and finish line."""
        # A. Outer Grass Shoulders
        surface.fill(COLOR_GRASS)
        # Subtle horizontal stripes on grass
        for gy in range(0, WINDOW_HEIGHT, 40):
            pygame.draw.rect(surface, COLOR_GRASS_DETAIL, (0, gy, 70, 20))
            pygame.draw.rect(surface, COLOR_GRASS_DETAIL, (1210, gy, 70, 20))

        # B. Render Track 1 (Left Track)
        self._render_single_track(
            surface,
            left_x=TRACK_1_LEFT,
            right_x=TRACK_1_RIGHT,
            scroll_y=self.scroll_y_p1,
            obstacles=self.track_1_obstacles,
            car=car_p1,
            label="PLAYER 1",
            theme_color=COLOR_CYAN,
        )

        # C. Render Track 2 (Right Track)
        label_p2 = "AI OPPONENT" if car_p2.is_ai else "PLAYER 2"
        theme_p2 = COLOR_CRIMSON if car_p2.is_ai else COLOR_ORANGE
        self._render_single_track(
            surface,
            left_x=TRACK_2_LEFT,
            right_x=TRACK_2_RIGHT,
            scroll_y=self.scroll_y_p2,
            obstacles=self.track_2_obstacles,
            car=car_p2,
            label=label_p2,
            theme_color=theme_p2,
        )

        # D. Render Center Divider
        self._render_center_divider(surface, car_p1, car_p2)

    def _render_single_track(
        self,
        surface: pygame.Surface,
        left_x: int,
        right_x: int,
        scroll_y: float,
        obstacles: List[Obstacle],
        car: Car,
        label: str,
        theme_color: Tuple[int, int, int],
    ) -> None:
        """Render asphalt, scrolling dashed lanes, racing kerbs, and obstacles for one track."""
        width = right_x - left_x

        # 1. Main Asphalt Surface
        pygame.draw.rect(surface, COLOR_ASPHALT, (left_x, 0, width, WINDOW_HEIGHT))

        # 2. Road Border Rails / Kerbs (Red & White alternating rumble strips)
        kerb_w = 12
        dash_len = 40
        num_dashes = (WINDOW_HEIGHT // dash_len) + 3

        for i in range(-1, num_dashes):
            ky = int(i * dash_len + (scroll_y % dash_len))
            color = COLOR_KERB_RED if (i % 2 == 0) else COLOR_KERB_WHITE
            # Left kerb
            pygame.draw.rect(surface, color, (left_x - kerb_w, ky, kerb_w, dash_len))
            # Right kerb
            pygame.draw.rect(surface, color, (right_x, ky, kerb_w, dash_len))

        # 3. Lane Markings (Dashed white/yellow strips between lanes)
        lane_w = width // LANE_COUNT
        mark_len = 36
        gap_len = 28
        cycle_len = mark_len + gap_len

        for lane_idx in range(1, LANE_COUNT):
            lx = left_x + lane_idx * lane_w
            # Draw dashed strip down lane boundary
            start_offset = scroll_y % cycle_len
            for my in range(int(-cycle_len + start_offset), WINDOW_HEIGHT + cycle_len, cycle_len):
                pygame.draw.rect(surface, (230, 230, 240), (lx - 3, my, 6, mark_len), border_radius=2)

        # 4. Finish Line Banner (Chequered flag grid across the track)
        finish_screen_y = CAR_RESTING_Y - (self.total_world_distance - car.distance_traveled)
        if -50 <= finish_screen_y <= WINDOW_HEIGHT + 50:
            self._render_finish_line(surface, left_x, width, finish_screen_y)

        # 5. Render Obstacles
        for obs in obstacles:
            obs.render(surface)

    def _render_finish_line(self, surface: pygame.Surface, left_x: int, width: int, y: float) -> None:
        """Draw chequered flag finish line across track."""
        tile_size = 16
        rows = 3
        cols = width // tile_size

        for r in range(rows):
            for c in range(cols):
                color = COLOR_WHITE if (r + c) % 2 == 0 else (15, 18, 24)
                pygame.draw.rect(
                    surface,
                    color,
                    (left_x + c * tile_size, int(y) - rows * tile_size // 2 + r * tile_size, tile_size, tile_size),
                )

        # Finish Line Overhead Gantry Banner
        gantry_y = int(y) - 30
        pygame.draw.rect(surface, (18, 22, 32), (left_x - 10, gantry_y, width + 20, 22), border_radius=4)
        pygame.draw.rect(surface, (255, 215, 0), (left_x - 10, gantry_y, width + 20, 22), 2, border_radius=4)

        font = pygame.font.SysFont("arialblack", 14)
        text = font.render("🏁 FINISH LINE 🏁", True, (255, 220, 0))
        surface.blit(text, text.get_rect(center=(left_x + width // 2, gantry_y + 11)))

    def _render_center_divider(self, surface: pygame.Surface, car_p1: Car, car_p2: Car) -> None:
        """Render stylish futuristic center barrier dividing the two tracks."""
        x = CENTER_DIVIDER_LEFT
        w = CENTER_DIVIDER_WIDTH
        cx = x + w // 2

        # Base Divider Pillar
        pygame.draw.rect(surface, (18, 22, 28), (x, 0, w, WINDOW_HEIGHT))
        pygame.draw.rect(surface, (30, 36, 48), (x + 8, 0, w - 16, WINDOW_HEIGHT))

        # Neon Divider Borders
        pygame.draw.line(surface, COLOR_CYAN, (x, 0), (x, WINDOW_HEIGHT), 2)
        pygame.draw.line(surface, COLOR_CRIMSON, (x + w, 0), (x + w, WINDOW_HEIGHT), 2)

        # Race Branding & Chevron Lights
        font_brand = pygame.font.SysFont("impact", 17)
        brand_text = font_brand.render("LANE LEGENDS", True, (240, 245, 255))
        brand_rect = brand_text.get_rect(center=(cx, 40))
        surface.blit(brand_text, brand_rect)

        # Center animated distance indicator / arrows
        num_markers = 8
        spacing = WINDOW_HEIGHT // num_markers
        time_sec = pygame.time.get_ticks() * 0.005

        for i in range(num_markers):
            my = i * spacing + 60
            # Neon Arrow chevron pointing upward (racing forward)
            offset = int(math.sin(time_sec + i) * 3)
            pts = [
                (cx - 16, my + 10 + offset),
                (cx, my - 2 + offset),
                (cx + 16, my + 10 + offset),
                (cx + 10, my + 10 + offset),
                (cx, my + 3 + offset),
                (cx - 10, my + 10 + offset),
            ]
            arrow_color = (60, 160, 230) if i % 2 == 0 else (240, 120, 40)
            pygame.draw.polygon(surface, arrow_color, pts)

        # Quick race progress comparison in center divider
        p1_pct = min(1.0, car_p1.distance_traveled / self.total_world_distance)
        p2_pct = min(1.0, car_p2.distance_traveled / self.total_world_distance)

        # Mini vertical progress slots
        bar_top = 220
        bar_height = 280
        bar_w = 12

        # P1 progress bar
        pygame.draw.rect(surface, (30, 35, 45), (cx - 24, bar_top, bar_w, bar_height), border_radius=4)
        p1_h = int(bar_height * p1_pct)
        if p1_h > 0:
            pygame.draw.rect(surface, COLOR_CYAN, (cx - 24, bar_top + bar_height - p1_h, bar_w, p1_h), border_radius=4)

        # P2/AI progress bar
        pygame.draw.rect(surface, (30, 35, 45), (cx + 12, bar_top, bar_w, bar_height), border_radius=4)
        p2_h = int(bar_height * p2_pct)
        p2_color = COLOR_CRIMSON if car_p2.is_ai else COLOR_ORANGE
        if p2_h > 0:
            pygame.draw.rect(surface, p2_color, (cx + 12, bar_top + bar_height - p2_h, bar_w, p2_h), border_radius=4)

        # Labels for mini bars
        font_micro = pygame.font.SysFont("arial", 11, bold=True)
        lbl_p1 = font_micro.render("P1", True, COLOR_CYAN)
        lbl_p2 = font_micro.render("AI" if car_p2.is_ai else "P2", True, p2_color)
        surface.blit(lbl_p1, lbl_p1.get_rect(center=(cx - 18, bar_top - 12)))
        surface.blit(lbl_p2, lbl_p2.get_rect(center=(cx + 18, bar_top - 12)))

        # Distance remaining indicator
        meters_left_p1 = max(0, int(RACE_DISTANCE_METERS - car_p1.distance_traveled * METERS_PER_PIXEL))
        font_dist = pygame.font.SysFont("arial", 12, bold=True)
        dist_lbl = font_dist.render(f"{meters_left_p1}m", True, (220, 225, 235))
        surface.blit(dist_lbl, dist_lbl.get_rect(center=(cx, bar_top + bar_height + 22)))
