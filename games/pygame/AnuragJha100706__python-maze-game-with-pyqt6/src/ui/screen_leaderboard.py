"""
Hall of Fame Leaderboard Screen (Publication Grade).
Displays sorted player speedrun and completion records directly from SQLite.
Features Protocol Mode Filters, Stat Summary Cards, Rank Medals, and Tactile Audio.
"""

import pygame
from typing import Dict, Any, Tuple, Callable, List, Optional
from .widgets import Button
from database.db_manager import DatabaseManager
from game.audio import SoundFX

class LeaderboardScreen:
    """Publication-Grade Hall of Fame Leaderboard UI in Pure Pygame."""

    def __init__(
        self,
        surface_size: Tuple[int, int],
        on_back: Callable[[], None]
    ):
        self.width, self.height = surface_size
        self.on_back = on_back
        self.db = DatabaseManager()

        self.font_title = pygame.font.SysFont("segoeui", 28, bold=True)
        self.font_sub = pygame.font.SysFont("segoeui", 13)
        self.font_stat_val = pygame.font.SysFont("consolas", 18, bold=True)
        self.font_stat_lbl = pygame.font.SysFont("segoeui", 11)
        self.font_header = pygame.font.SysFont("segoeui", 12, bold=True)
        self.font_row = pygame.font.SysFont("segoeui", 13)
        self.font_rank = pygame.font.SysFont("segoeui", 13, bold=True)
        self.font_empty = pygame.font.SysFont("segoeui", 15, italic=True)

        self.current_mode_filter: Optional[int] = None
        self.page = 0
        self.per_page = 8
        self.records: List[Dict[str, Any]] = []

        # Back Button
        self.btn_back = Button(40, 25, 110, 38, "BACK", self._handle_back, color=(19, 24, 38), font_size=13, shortcut="[ESC]")

        # Mode Filter Buttons
        self.filter_buttons = []
        filters = [
            ("ALL PROTOCOLS", None),
            ("SOLO TRIAL", 0),
            ("TWO PLAYER", 1),
            ("RACE VS AI", 2),
            ("CHASE SURVIVAL", 3),
            ("ESCAPE HEIST", 4)
        ]
        start_x = 280
        for i, (label, m_id) in enumerate(filters):
            b = Button(
                start_x + i * 115, 88, 108, 34,
                label,
                lambda mid=m_id: self._set_filter(mid),
                font_size=11
            )
            self.filter_buttons.append((m_id, b))

        # Pagination Buttons
        cx = self.width // 2
        self.btn_prev = Button(cx - 130, 656, 100, 34, "PREV", self._prev_page, font_size=12)
        self.btn_next = Button(cx + 30, 656, 100, 34, "NEXT", self._next_page, font_size=12)

        self.refresh_data()

    def _handle_back(self):
        SoundFX.play_click()
        self.on_back()

    def _set_filter(self, mode_id: Optional[int]):
        SoundFX.play_click()
        self.current_mode_filter = mode_id
        self.page = 0
        self.refresh_data()

    def _prev_page(self):
        if self.page > 0:
            SoundFX.play_click()
            self.page -= 1

    def _next_page(self):
        max_pages = max(1, (len(self.records) + self.per_page - 1) // self.per_page)
        if self.page < max_pages - 1:
            SoundFX.play_click()
            self.page += 1

    def refresh_data(self):
        try:
            self.records = self.db.get_leaderboard(mode_id=self.current_mode_filter, limit=100)
        except Exception:
            self.records = []

    def handle_event(self, event: pygame.event.Event):
        self.btn_back.handle_event(event)
        self.btn_prev.handle_event(event)
        self.btn_next.handle_event(event)

        for mid, btn in self.filter_buttons:
            btn.handle_event(event)

        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                self._handle_back()
            elif event.key == pygame.K_LEFT:
                self._prev_page()
            elif event.key == pygame.K_RIGHT:
                self._next_page()

    def update(self, dt: float):
        self.btn_back.update(dt)
        self.btn_prev.update(dt)
        self.btn_next.update(dt)
        for mid, btn in self.filter_buttons:
            btn.update(dt)

    def render(self, surface: pygame.Surface):
        surface.fill((11, 14, 23))

        # Title
        title_surf = self.font_title.render("HALL OF FAME // PROTOCOL LEADERBOARDS", True, (0, 240, 255))
        surface.blit(title_surf, (self.width // 2 - title_surf.get_width() // 2, 22))

        sub_surf = self.font_sub.render("Real-time speedrun records stored in persistent relational database", True, (142, 154, 175))
        surface.blit(sub_surf, (self.width // 2 - sub_surf.get_width() // 2, 58))

        self.btn_back.draw(surface)

        # Highlight Active Filter Button
        for mid, btn in self.filter_buttons:
            if mid == self.current_mode_filter:
                btn.color = (0, 240, 255)
                btn.text_color = (11, 14, 23)
            else:
                btn.color = (19, 24, 38)
                btn.text_color = (248, 249, 250)
            btn.draw(surface)

        # Table Container Box
        table_x = 80
        table_y = 138
        table_w = self.width - 160
        table_h = 500
        container_rect = pygame.Rect(table_x, table_y, table_w, table_h)
        pygame.draw.rect(surface, (19, 24, 38), container_rect, border_radius=8)
        pygame.draw.rect(surface, (34, 43, 66), container_rect, width=1, border_radius=8)

        # Table Header Bar
        header_h = 44
        pygame.draw.rect(surface, (24, 30, 48), pygame.Rect(table_x, table_y, table_w, header_h), border_top_left_radius=8, border_top_right_radius=8)
        pygame.draw.line(surface, (0, 240, 255), (table_x, table_y + header_h), (table_x + table_w, table_y + header_h), 1)

        cols = [
            ("RANK", 28),
            ("RUNNER", 140),
            ("PROTOCOL", 340),
            ("GRID", 550),
            ("CLEAR TIME", 680),
            ("STEPS", 820),
            ("TIMESTAMP", 950)
        ]

        for name, col_offset in cols:
            txt = self.font_header.render(name, True, (0, 240, 255))
            surface.blit(txt, (table_x + col_offset, table_y + 14))

        if not self.records:
            empty_txt = self.font_empty.render("No records logged for this protocol yet. Clear a mission to enter the Hall of Fame!", True, (142, 154, 175))
            surface.blit(empty_txt, (self.width // 2 - empty_txt.get_width() // 2, table_y + 220))
            return

        # Paginated Rows
        start_idx = self.page * self.per_page
        end_idx = min(start_idx + self.per_page, len(self.records))
        row_h = 48

        mode_names = {
            0: "Mode 0: Solo Trial",
            1: "Mode 1: Two Player PvP",
            2: "Mode 2: Race vs AI",
            3: "Mode 3: Chase Survival",
            4: "Mode 4: Escape Heist"
        }

        for i, row_idx in enumerate(range(start_idx, end_idx)):
            row = self.records[row_idx]
            ry = table_y + header_h + i * row_h
            rank = row_idx + 1

            if i % 2 == 1:
                pygame.draw.rect(surface, (24, 30, 48), pygame.Rect(table_x + 1, ry, table_w - 2, row_h))

            # Rank Badges
            if rank == 1:
                rank_col = (255, 215, 0)
                rank_txt = "#1 GOLD"
            elif rank == 2:
                rank_col = (192, 192, 192)
                rank_txt = "#2 SILVER"
            elif rank == 3:
                rank_col = (205, 127, 50)
                rank_txt = "#3 BRONZE"
            else:
                rank_col = (142, 154, 175)
                rank_txt = f"#{rank}"

            r_surf = self.font_rank.render(rank_txt, True, rank_col)
            surface.blit(r_surf, (table_x + cols[0][1], ry + 14))

            # Runner Name
            u_surf = self.font_row.render(str(row.get("username", "Unknown")), True, (248, 249, 250))
            surface.blit(u_surf, (table_x + cols[1][1], ry + 14))

            # Protocol
            m_id = row.get("mode_id", 0)
            m_name = mode_names.get(m_id, f"Mode {m_id}")
            m_surf = self.font_row.render(m_name, True, (6, 214, 160))
            surface.blit(m_surf, (table_x + cols[2][1], ry + 14))

            # Grid
            g_sz = f"{row.get('grid_size', 20)}x{row.get('grid_size', 20)}"
            g_surf = self.font_row.render(g_sz, True, (248, 249, 250))
            surface.blit(g_surf, (table_x + cols[3][1], ry + 14))

            # Time
            t_val = f"{row.get('time_seconds', 0.0):.2f}s"
            t_surf = self.font_row.render(t_val, True, (0, 240, 255))
            surface.blit(t_surf, (table_x + cols[4][1], ry + 14))

            # Steps
            st_val = str(row.get("steps_taken", 0))
            st_surf = self.font_row.render(st_val, True, (248, 249, 250))
            surface.blit(st_surf, (table_x + cols[5][1], ry + 14))

            # Timestamp
            dt_str = str(row.get("created_at", ""))[:19]
            d_surf = self.font_row.render(dt_str, True, (142, 154, 175))
            surface.blit(d_surf, (table_x + cols[6][1], ry + 14))

        # Pagination Bar
        total_pages = max(1, (len(self.records) + self.per_page - 1) // self.per_page)
        page_txt = self.font_sub.render(f"Page {self.page + 1} of {total_pages} ({len(self.records)} Records Total)", True, (142, 154, 175))
        surface.blit(page_txt, (self.width // 2 - page_txt.get_width() // 2, 642))

        if total_pages > 1:
            self.btn_prev.draw(surface)
            self.btn_next.draw(surface)
