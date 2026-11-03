"""Menu, gameplay, ranking, and result scenes."""

from __future__ import annotations

import random

import pygame

from game.audio import ProceduralAudio
from game.config import (
    BOSS_DELAY_MS,
    CYAN,
    FPS,
    GREEN,
    HEIGHT,
    INK,
    MAGENTA,
    MUTED,
    ORANGE,
    RED,
    VIOLET,
    WIDTH,
)
from game.entities import Boss, Enemy, Player, PowerUp, Projectile
from game.storage import SaveSystem
from game.ui import Button, draw_panel, draw_text
from game.visuals import StarField, build_background, ship_surface


class MenuScene:
    def __init__(
        self,
        screen: pygame.Surface,
        audio: ProceduralAudio,
        saves: SaveSystem,
    ):
        self.screen = screen
        self.audio = audio
        self.saves = saves
        self.clock = pygame.time.Clock()
        self.background = build_background()
        self.stars = StarField()
        self.title_font = pygame.font.SysFont("bahnschrift", 58, bold=True)
        self.subtitle_font = pygame.font.SysFont("bahnschrift", 21)
        self.button_font = pygame.font.SysFont("bahnschrift", 22, bold=True)
        self.small_font = pygame.font.SysFont("bahnschrift", 18)
        self.selected_index = 0
        self.buttons = self._build_buttons()

    def _build_buttons(self) -> list[Button]:
        labels = [
            ("NOVO JOGO", "new_game", True),
            ("CONTINUAR", "continue_game", self.saves.has_progress()),
            ("RANKING", "ranking", True),
            ("INSTRUÇÕES", "instructions", True),
            ("SAIR", "quit", True),
        ]
        x = WIDTH // 2 - 150
        return [
            Button(label, pygame.Rect(x, 208 + index * 56, 300, 44), action, enabled)
            for index, (label, action, enabled) in enumerate(labels)
        ]

    def run(self) -> str:
        self.buttons = self._build_buttons()
        self.audio.switch_music(False)
        while True:
            dt = self.clock.tick(FPS) / 1_000
            self.stars.update(dt)
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    return "quit"
                if event.type == pygame.KEYDOWN:
                    action = self._keyboard_action(event.key)
                    if action == "instructions":
                        if InstructionsScene(self.screen, self.background, self.stars).run() == "quit":
                            return "quit"
                    elif action:
                        return action
                for index, button in enumerate(self.buttons):
                    if button.accepts(event):
                        self.selected_index = index
                        self.audio.play("powerup")
                        if button.action == "instructions":
                            if InstructionsScene(self.screen, self.background, self.stars).run() == "quit":
                                return "quit"
                        else:
                            return button.action

            self.draw()
            pygame.display.flip()

    def _keyboard_action(self, key: int) -> str | None:
        enabled_indices = [index for index, button in enumerate(self.buttons) if button.enabled]
        if key in (pygame.K_UP, pygame.K_w):
            current = enabled_indices.index(self.selected_index) if self.selected_index in enabled_indices else 0
            self.selected_index = enabled_indices[(current - 1) % len(enabled_indices)]
        elif key in (pygame.K_DOWN, pygame.K_s):
            current = enabled_indices.index(self.selected_index) if self.selected_index in enabled_indices else 0
            self.selected_index = enabled_indices[(current + 1) % len(enabled_indices)]
        elif key in (pygame.K_RETURN, pygame.K_SPACE):
            selected = self.buttons[self.selected_index]
            if selected.enabled:
                self.audio.play("powerup")
                return selected.action
        elif key == pygame.K_ESCAPE:
            return "quit"
        return None

    def draw(self) -> None:
        self.screen.blit(self.background, (0, 0))
        self.stars.draw(self.screen)
        draw_panel(self.screen, pygame.Rect(WIDTH // 2 - 205, 24, 410, 494), 220)
        draw_text(
            self.screen,
            "NEBULA STRIKE",
            self.title_font,
            INK,
            center=(WIDTH // 2, 72),
        )
        draw_text(
            self.screen,
            "Boss fight arcade em Python e Pygame",
            self.subtitle_font,
            CYAN,
            center=(WIDTH // 2, 116),
        )
        ship = pygame.transform.scale(ship_surface(), (116, 80))
        self.screen.blit(ship, ship.get_rect(center=(WIDTH // 2, 164)))

        mouse = pygame.mouse.get_pos()
        for index, button in enumerate(self.buttons):
            button.draw(
                self.screen,
                self.button_font,
                mouse,
                selected=index == self.selected_index,
            )

        draw_text(
            self.screen,
            "Setas/WASD para navegar • Enter para confirmar",
            self.small_font,
            MUTED,
            center=(WIDTH // 2, 500),
        )


class InstructionsScene:
    def __init__(self, screen: pygame.Surface, background: pygame.Surface, stars: StarField):
        self.screen = screen
        self.background = background
        self.stars = stars
        self.clock = pygame.time.Clock()
        self.title_font = pygame.font.SysFont("bahnschrift", 48, bold=True)
        self.body_font = pygame.font.SysFont("bahnschrift", 25)
        self.small_font = pygame.font.SysFont("bahnschrift", 19)

    def run(self) -> str:
        while True:
            dt = self.clock.tick(FPS) / 1_000
            self.stars.update(dt)
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    return "quit"
                if event.type == pygame.KEYDOWN and event.key in (pygame.K_ESCAPE, pygame.K_RETURN):
                    return "menu"
                if event.type == pygame.MOUSEBUTTONDOWN:
                    return "menu"
            self.draw()
            pygame.display.flip()

    def draw(self) -> None:
        self.screen.blit(self.background, (0, 0))
        self.stars.draw(self.screen)
        panel = pygame.Rect(90, 24, WIDTH - 180, HEIGHT - 48)
        draw_panel(self.screen, panel)
        draw_text(self.screen, "COMO JOGAR", self.title_font, INK, center=(WIDTH // 2, 72))
        lines = [
            ("Mover", "Setas ou WASD"),
            ("Atirar", "Barra de espaço"),
            ("Pausar", "ESC salva o progresso e volta ao menu"),
            ("Power-up azul", "Aumenta a velocidade e a cadência de tiro"),
            ("Power-up verde", "Bloqueia o próximo dano recebido"),
            ("Objetivo", "Sobreviva por 30 segundos e derrote o boss"),
        ]
        for index, (label, description) in enumerate(lines):
            y = 125 + index * 55
            draw_text(self.screen, label, self.body_font, CYAN, topleft=(145, y))
            draw_text(self.screen, description, self.body_font, INK, topleft=(330, y))
        draw_text(
            self.screen,
            "ESC, Enter ou clique para voltar",
            self.small_font,
            MUTED,
            center=(WIDTH // 2, 505),
        )


class RankingScene:
    def __init__(self, screen: pygame.Surface, saves: SaveSystem):
        self.screen = screen
        self.saves = saves
        self.clock = pygame.time.Clock()
        self.background = build_background()
        self.stars = StarField(seed=52)
        self.title_font = pygame.font.SysFont("bahnschrift", 48, bold=True)
        self.body_font = pygame.font.SysFont("consolas", 25, bold=True)
        self.small_font = pygame.font.SysFont("bahnschrift", 18)

    def run(self) -> str:
        while True:
            dt = self.clock.tick(FPS) / 1_000
            self.stars.update(dt)
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    return "quit"
                if event.type == pygame.KEYDOWN and event.key in (pygame.K_ESCAPE, pygame.K_RETURN):
                    return "menu"
                if event.type == pygame.MOUSEBUTTONDOWN:
                    return "menu"
            self.draw()
            pygame.display.flip()

    def draw(self) -> None:
        self.screen.blit(self.background, (0, 0))
        self.stars.draw(self.screen)
        draw_panel(self.screen, pygame.Rect(80, 24, WIDTH - 160, HEIGHT - 48))
        draw_text(self.screen, "MELHORES PILOTOS", self.title_font, INK, center=(WIDTH // 2, 66))
        entries = self.saves.load_ranking()
        if not entries:
            draw_text(
                self.screen,
                "Nenhuma pontuação registrada ainda",
                self.body_font,
                MUTED,
                center=(WIDTH // 2, HEIGHT // 2),
            )
        for index, entry in enumerate(entries, start=1):
            color = ORANGE if index == 1 else INK
            line = f"{index:>2}.  {entry.name:<12}  {entry.score:>5} pts  {entry.time_seconds:>5.1f}s"
            draw_text(self.screen, line, self.body_font, color, center=(WIDTH // 2, 92 + index * 36))
        draw_text(
            self.screen,
            "ESC, Enter ou clique para voltar",
            self.small_font,
            MUTED,
            center=(WIDTH // 2, 510),
        )


class GameOverScene:
    def __init__(
        self,
        screen: pygame.Surface,
        saves: SaveSystem,
        score: int,
        elapsed_seconds: float,
        won: bool,
    ):
        self.screen = screen
        self.saves = saves
        self.score = score
        self.elapsed_seconds = elapsed_seconds
        self.won = won
        self.clock = pygame.time.Clock()
        self.background = build_background()
        self.stars = StarField(seed=73)
        self.name = "PILOTO"
        self.title_font = pygame.font.SysFont("bahnschrift", 55, bold=True)
        self.body_font = pygame.font.SysFont("bahnschrift", 28)
        self.input_font = pygame.font.SysFont("consolas", 32, bold=True)
        self.small_font = pygame.font.SysFont("bahnschrift", 18)
        self.save_button = Button("SALVAR", pygame.Rect(WIDTH // 2 - 205, 355, 190, 50), "save")
        self.menu_button = Button("MENU", pygame.Rect(WIDTH // 2 + 15, 355, 190, 50), "menu")

    def run(self) -> str:
        while True:
            dt = self.clock.tick(FPS) / 1_000
            self.stars.update(dt)
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    return "quit"
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_RETURN:
                        self._save()
                        return "menu"
                    if event.key == pygame.K_ESCAPE:
                        return "menu"
                    if event.key == pygame.K_BACKSPACE:
                        self.name = self.name[:-1]
                    elif event.unicode and event.unicode.isprintable() and len(self.name) < 12:
                        if self.name == "PILOTO":
                            self.name = ""
                        self.name += event.unicode.upper()
                if self.save_button.accepts(event):
                    self._save()
                    return "menu"
                if self.menu_button.accepts(event):
                    return "menu"
            self.draw()
            pygame.display.flip()

    def _save(self) -> None:
        self.saves.save_score(self.name, self.score, self.elapsed_seconds)

    def draw(self) -> None:
        self.screen.blit(self.background, (0, 0))
        self.stars.draw(self.screen)
        draw_panel(self.screen, pygame.Rect(150, 28, WIDTH - 300, HEIGHT - 56))
        title = "MISSÃO CONCLUÍDA" if self.won else "FIM DE JOGO"
        title_color = GREEN if self.won else RED
        draw_text(self.screen, title, self.title_font, title_color, center=(WIDTH // 2, 86))
        draw_text(
            self.screen,
            f"Pontuação: {self.score}    Tempo: {self.elapsed_seconds:.1f}s",
            self.body_font,
            INK,
            center=(WIDTH // 2, 158),
        )
        draw_text(self.screen, "Nome do piloto", self.body_font, CYAN, center=(WIDTH // 2, 225))
        input_rect = pygame.Rect(WIDTH // 2 - 180, 255, 360, 56)
        pygame.draw.rect(self.screen, (8, 18, 40), input_rect, border_radius=10)
        pygame.draw.rect(self.screen, CYAN, input_rect, width=2, border_radius=10)
        draw_text(self.screen, self.name or "_", self.input_font, INK, center=input_rect.center)
        mouse = pygame.mouse.get_pos()
        self.save_button.draw(self.screen, self.body_font, mouse)
        self.menu_button.draw(self.screen, self.body_font, mouse)
        draw_text(
            self.screen,
            "Digite o nome e pressione Enter",
            self.small_font,
            MUTED,
            center=(WIDTH // 2, 456),
        )


class GameScene:
    def __init__(
        self,
        screen: pygame.Surface,
        audio: ProceduralAudio,
        progress: dict[str, int] | None = None,
        seed: int | None = None,
    ):
        self.screen = screen
        self.audio = audio
        self.clock = pygame.time.Clock()
        self.background = build_background()
        self.stars = StarField(seed=91)
        self.rng = random.Random(seed)
        self.status: str | None = None
        self.score = int(progress.get("score", 0)) if progress else 0
        lives = int(progress.get("lives", 3)) if progress else 3
        self.elapsed_offset = int(progress.get("elapsed_seconds", 0)) if progress else 0
        self.session_started_at = pygame.time.get_ticks()
        self.elapsed_seconds = float(self.elapsed_offset)
        self.player = Player(lives=lives)
        self.enemies: list[Enemy] = []
        self.player_shots: list[Projectile] = []
        self.enemy_shots: list[Projectile] = []
        self.powerup: PowerUp | None = None
        self.boss: Boss | None = None
        self.next_enemy_spawn_at = 0
        self.next_powerup_at = self.session_started_at + 11_000
        self.boss_music_started = False
        self.hud_font = pygame.font.SysFont("consolas", 23, bold=True)
        self.banner_font = pygame.font.SysFont("bahnschrift", 34, bold=True)

    def run(self) -> dict[str, int | float | str]:
        self.audio.switch_music(False)
        while self.status is None:
            dt = min(0.05, self.clock.tick(FPS) / 1_000)
            now_ms = pygame.time.get_ticks()
            self._handle_events(now_ms)
            if self.status is None:
                self.update(dt, now_ms)
            self.draw()
            pygame.display.flip()
        self.audio.stop()
        return self.result()

    def _handle_events(self, now_ms: int) -> None:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.status = "quit"
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                self.status = "menu"
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_SPACE:
                if self.player.can_shoot(now_ms):
                    self.player_shots.append(
                        Projectile((self.player.rect.right - 4, self.player.rect.centery - 4), True)
                    )
                    self.audio.play("shoot")

    def update(self, dt: float, now_ms: int) -> None:
        self.elapsed_seconds = self.elapsed_offset + (now_ms - self.session_started_at) / 1_000
        self.stars.update(dt)
        self.player.update(pygame.key.get_pressed(), dt, now_ms)

        if self.elapsed_seconds * 1_000 >= BOSS_DELAY_MS:
            self._ensure_boss(now_ms)
        else:
            self._spawn_enemies(now_ms)

        for enemy in self.enemies:
            enemy.update(dt, self.elapsed_seconds)
            if enemy.ready_to_shoot(now_ms):
                self.enemy_shots.append(
                    Projectile((enemy.rect.left - 8, enemy.rect.centery - 4), False)
                )
        self.enemies = [enemy for enemy in self.enemies if not enemy.off_screen]

        if self.boss is not None:
            self.boss.update(dt)
            if self.boss.ready_to_shoot(now_ms):
                for vertical_speed in (-145.0, 0.0, 145.0):
                    self.enemy_shots.append(
                        Projectile(
                            (self.boss.rect.left - 8, self.boss.rect.centery - 4),
                            False,
                            velocity=(-380.0, vertical_speed),
                            boss_shot=True,
                        )
                    )

        for projectile in [*self.player_shots, *self.enemy_shots]:
            projectile.update(dt)
        self.player_shots = [shot for shot in self.player_shots if not shot.off_screen]
        self.enemy_shots = [shot for shot in self.enemy_shots if not shot.off_screen]

        if self.powerup is None and now_ms >= self.next_powerup_at:
            kind = self.rng.choice(("speed", "shield"))
            self.powerup = PowerUp(kind, self.rng.uniform(70, HEIGHT - 90))
            self.next_powerup_at = now_ms + self.rng.randint(11_000, 15_000)
        if self.powerup is not None:
            self.powerup.update(dt)
            if self.powerup.off_screen:
                self.powerup = None
            elif self.powerup.rect.colliderect(self.player.rect):
                self.player.activate_powerup(self.powerup.kind, now_ms)
                self.audio.play("powerup")
                self.powerup = None

        self._resolve_collisions(now_ms)
        if self.player.lives <= 0:
            self.status = "defeated"

    def _spawn_enemies(self, now_ms: int) -> None:
        desired_count = min(7, 2 + int(self.elapsed_seconds // 12))
        if len(self.enemies) >= desired_count or now_ms < self.next_enemy_spawn_at:
            return
        kind = "striker" if self.elapsed_seconds >= 12 and self.rng.random() < 0.34 else "scout"
        self.enemies.append(Enemy(kind, self.rng))
        self.next_enemy_spawn_at = now_ms + 360

    def _ensure_boss(self, now_ms: int) -> None:
        if self.boss is None:
            self.boss = Boss()
            self.enemies.clear()
            self.enemy_shots.clear()
            self.boss.last_shot_at = now_ms
        if not self.boss_music_started:
            self.audio.play("boss")
            self.audio.switch_music(True)
            self.boss_music_started = True

    def _resolve_collisions(self, now_ms: int) -> None:
        for projectile in list(self.player_shots):
            hit = False
            for enemy in list(self.enemies):
                if projectile.rect.colliderect(enemy.rect):
                    hit = True
                    if enemy.take_damage(projectile.damage):
                        self.score += enemy.points
                        self.enemies.remove(enemy)
                    break
            if not hit and self.boss is not None and projectile.rect.colliderect(self.boss.rect):
                hit = True
                if self.boss.take_damage(projectile.damage):
                    self.score += 500
                    self.status = "victory"
            if hit and projectile in self.player_shots:
                self.player_shots.remove(projectile)

        for projectile in list(self.enemy_shots):
            if projectile.rect.colliderect(self.player.rect):
                outcome = self.player.take_damage(now_ms)
                if outcome == "damaged":
                    self.audio.play("hit")
                elif outcome == "shielded":
                    self.audio.play("powerup")
                self.enemy_shots.remove(projectile)

        for enemy in list(self.enemies):
            if enemy.rect.colliderect(self.player.rect):
                outcome = self.player.take_damage(now_ms)
                if outcome == "damaged":
                    self.audio.play("hit")
                self.enemies.remove(enemy)

    def draw(self) -> None:
        self.screen.blit(self.background, (0, 0))
        self.stars.draw(self.screen)
        if self.powerup is not None:
            self.powerup.draw(self.screen)
        for enemy in self.enemies:
            enemy.draw(self.screen)
        if self.boss is not None:
            self.boss.draw(self.screen)
        for projectile in self.player_shots:
            projectile.draw(self.screen)
        for projectile in self.enemy_shots:
            projectile.draw(self.screen)
        self.player.draw(self.screen)
        self._draw_hud()

    def _draw_hud(self) -> None:
        overlay = pygame.Surface((WIDTH, 74), pygame.SRCALPHA)
        overlay.fill((3, 10, 29, 178))
        self.screen.blit(overlay, (0, 0))
        draw_text(self.screen, f"PONTOS {self.score:05d}", self.hud_font, INK, topleft=(22, 22))
        draw_text(
            self.screen,
            f"TEMPO {self.elapsed_seconds:05.1f}s",
            self.hud_font,
            INK,
            center=(WIDTH // 2, 34),
        )
        for index in range(3):
            color = RED if index < self.player.lives else (69, 78, 98)
            x = WIDTH - 122 + index * 34
            pygame.draw.circle(self.screen, color, (x - 5, 28), 7)
            pygame.draw.circle(self.screen, color, (x + 5, 28), 7)
            pygame.draw.polygon(self.screen, color, [(x - 12, 31), (x + 12, 31), (x, 46)])

        if self.boss is not None:
            bar = pygame.Rect(WIDTH // 2 - 190, 82, 380, 16)
            pygame.draw.rect(self.screen, (45, 31, 62), bar, border_radius=8)
            health_width = int(bar.width * self.boss.hp / self.boss.MAX_HP)
            pygame.draw.rect(
                self.screen,
                MAGENTA,
                pygame.Rect(bar.x, bar.y, health_width, bar.height),
                border_radius=8,
            )
            pygame.draw.rect(self.screen, INK, bar, width=2, border_radius=8)
            draw_text(self.screen, "BOSS", self.hud_font, VIOLET, center=(WIDTH // 2, 116))
        else:
            remaining = max(0, int((BOSS_DELAY_MS / 1_000) - self.elapsed_seconds))
            draw_text(
                self.screen,
                f"BOSS EM {remaining:02d}s",
                self.hud_font,
                ORANGE,
                center=(WIDTH // 2, 92),
            )

        if self.player.powerup_type:
            label = "ESCUDO" if self.player.powerup_type == "shield" else "TURBO"
            draw_text(self.screen, label, self.hud_font, GREEN, topleft=(22, 88))

    def result(self) -> dict[str, int | float | str]:
        return {
            "status": self.status or "menu",
            "score": self.score,
            "lives": self.player.lives,
            "elapsed_seconds": round(self.elapsed_seconds, 2),
        }

    def prepare_preview(self, boss: bool = False) -> None:
        self.enemies = [Enemy("scout", self.rng), Enemy("striker", self.rng)]
        positions = ((705, 218), (825, 385))
        for enemy, position in zip(self.enemies, positions):
            enemy.position.update(position)
            enemy.sync_rect()
        self.player_shots = [Projectile((345, 280), True), Projectile((515, 260), True)]
        self.enemy_shots = [Projectile((665, 240), False)]
        self.powerup = PowerUp("shield", 425)
        self.powerup.position.x = 570
        self.powerup.sync_rect()
        self.elapsed_seconds = 18.4
        self.score = 180
        if boss:
            self.enemies.clear()
            self.powerup = None
            self.boss = Boss()
            self.boss.hp = 23
            self.enemy_shots = [
                Projectile((760, 300), False, velocity=(-380, -90), boss_shot=True),
                Projectile((710, 360), False, velocity=(-380, 90), boss_shot=True),
            ]
            self.elapsed_seconds = 34.2
            self.score = 420
