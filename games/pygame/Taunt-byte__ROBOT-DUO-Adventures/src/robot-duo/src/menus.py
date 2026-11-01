"""Menu scenes: main menu, level select, controls, settings, pause overlay helper and level-complete screen."""
import math
import random
import textwrap
import pygame
from . import settings as S
from .background import Background, THEMES
from .level_manager import format_time
from .particles import AmbientFX, ParticleSystem
from .ui import RANK_COLORS, draw_panel, draw_text


class Scene:
    def handle_event(self, e):
        pass

    def update(self, dt):
        pass

    def draw(self, screen):
        pass


class ButtonList:
    """Vertical list of big buttons controlled by keyboard (W/S/arrows + Enter) or mouse."""

    def __init__(self, game, labels, cx=S.SCREEN_W // 2, top=250, w=330, h=50, gap=12):
        self.game, self.labels = game, labels
        self.rects = [pygame.Rect(cx - w // 2, top + i * (h + gap), w, h) for i in range(len(labels))]
        self.selected = 0

    def handle_event(self, e):
        """Returns the index of an activated button, or None."""
        if e.type == pygame.KEYDOWN:
            if e.key in (pygame.K_UP, pygame.K_w):
                self.selected = (self.selected - 1) % len(self.labels)
                self.game.audio.play("menu_move")
            elif e.key in (pygame.K_DOWN, pygame.K_s):
                self.selected = (self.selected + 1) % len(self.labels)
                self.game.audio.play("menu_move")
            elif e.key in (pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_SPACE):
                self.game.audio.play("menu_select")
                return self.selected
        elif e.type == pygame.MOUSEMOTION:
            for i, r in enumerate(self.rects):
                if r.collidepoint(e.pos) and i != self.selected:
                    self.selected = i
                    self.game.audio.play("menu_move")
        elif e.type == pygame.MOUSEBUTTONDOWN and e.button == 1:
            for i, r in enumerate(self.rects):
                if r.collidepoint(e.pos):
                    self.selected = i
                    self.game.audio.play("menu_select")
                    return i
        return None

    def draw(self, screen, t):
        for i, (label, r) in enumerate(zip(self.labels, self.rects)):
            sel = i == self.selected
            rr = r.inflate(14, 6) if sel else r
            col = (46, 118, 230) if sel else (28, 44, 84)
            pygame.draw.rect(screen, (6, 10, 24), rr.move(0, 4), border_radius=14)
            pygame.draw.rect(screen, col, rr, border_radius=14)
            pygame.draw.rect(screen, (150, 210, 255) if sel else (70, 100, 160), rr, 3, border_radius=14)
            draw_text(screen, self.game.fonts, label, 24, S.C_WHITE, rr.center, "center")
            if sel:
                ax = rr.x - 22 + int(math.sin(t * 8) * 3)
                pygame.draw.polygon(screen, S.C_YELLOW, [(ax, rr.centery - 9), (ax, rr.centery + 9), (ax + 14, rr.centery)])


def draw_logo(screen, fonts, cy, t):
    f1, f2 = fonts.get(88), fonts.get(88)
    a = f1.render("ROBOT", True, S.C_RED_LIGHT)
    b = f2.render("DUO", True, S.C_CYAN_LIGHT)
    total = a.get_width() + b.get_width() + 24
    x = S.SCREEN_W // 2 - total // 2
    y = cy + int(math.sin(t * 2) * 4)
    for text, col, px in (("ROBOT", S.C_RED, x), ("DUO", S.C_CYAN, x + a.get_width() + 24)):
        for dx, dy in ((-4, 0), (4, 0), (0, -4), (0, 4), (-3, -3), (3, 3), (-3, 3), (3, -3), (0, 7)):
            screen.blit(f1.render(text, True, (8, 12, 30)), (px + dx, y + dy))
        screen.blit(f1.render(text, True, col), (px, y))
        hl = f1.render(text, True, (255, 255, 255))
        hl.set_alpha(70)
        screen.blit(hl, (px, y - 3))
    banner = pygame.Rect(S.SCREEN_W // 2 - 150, y + 92, 300, 38)
    pygame.draw.rect(screen, (10, 14, 34), banner, border_radius=10)
    pygame.draw.rect(screen, S.C_YELLOW, banner, 3, border_radius=10)
    draw_text(screen, fonts, "ADVENTURES", 26, S.C_YELLOW, banner.center, "center", outline=None)


class MenuBackdrop:
    """Slowly scrolling parallax shared by all menu screens."""

    def __init__(self, game, theme="factory"):
        self.bg = game.get_background(theme, 0)
        self.amb = AmbientFX(theme, S.SCREEN_W, S.SCREEN_H, 50)
        self.x = 0.0
        self.t = 0.0

    def update(self, dt):
        self.t += dt
        self.x += 38 * dt
        self.amb.update(dt)

    def draw(self, screen):
        self.bg.draw(screen, self.x, self.t)
        self.amb.draw(screen, self.x)
        shade = pygame.Surface((S.SCREEN_W, S.SCREEN_H), pygame.SRCALPHA)
        shade.fill((4, 8, 22, 90))
        screen.blit(shade, (0, 0))


class MainMenuScene(Scene):
    LABELS = ["JOGAR", "SELECIONAR FASE", "CONTROLES", "CONFIGURAÇÕES", "SAIR"]

    def __init__(self, game):
        self.game = game
        self.backdrop = MenuBackdrop(game)
        self.menu = ButtonList(game, self.LABELS, top=262, h=48, gap=11)
        self.t = 0.0
        game.audio.play_music("menu")

    def handle_event(self, e):
        i = self.menu.handle_event(e)
        if i is None:
            return
        g = self.game
        if i == 0:
            g.start_level(min(g.save.unlocked, g.levels.count) - 1)
        elif i == 1:
            g.change_scene(LevelSelectScene(g))
        elif i == 2:
            g.change_scene(ControlsScene(g))
        elif i == 3:
            g.change_scene(SettingsScene(g, MainMenuScene))
        else:
            g.running = False

    def update(self, dt):
        self.t += dt
        self.backdrop.update(dt)
        self.hero_t = self.t

    def draw(self, screen):
        self.backdrop.draw(screen)
        draw_logo(screen, self.game.fonts, 36, self.t)
        for kind, cx in (("x", 150), ("b", S.SCREEN_W - 150)):
            facing = 1 if kind == "x" else -1
            spr = self.game.hero[kind].get("idle", self.t, facing)
            screen.blit(spr, (cx - spr.get_width() // 2, 440 - self.game.hero[kind].foot_offset + 120))
        self.menu.draw(screen, self.t)
        draw_text(screen, self.game.fonts, "ENTER confirma  |  W/S ou setas navegam", 15, (190, 210, 240),
                  (S.SCREEN_W // 2, S.SCREEN_H - 18), "center", bold=False)


class LevelSelectScene(Scene):
    PER_ROW = 5

    def __init__(self, game):
        self.game = game
        self.backdrop = MenuBackdrop(game, "lab")
        self.sel = min(game.save.unlocked, game.levels.count) - 1
        self.t = 0.0
        self.rects = []
        for i in range(game.levels.count):
            r, c = divmod(i, self.PER_ROW)
            self.rects.append(pygame.Rect(35 + c * 190, 170 + r * 270, 170, 250))

    def _go(self):
        g = self.game
        if self.sel < g.save.unlocked:
            g.audio.play("menu_select")
            g.start_level(self.sel)
        else:
            g.audio.play("death", 0.5)

    def handle_event(self, e):
        n = self.game.levels.count
        if e.type == pygame.KEYDOWN:
            if e.key == pygame.K_ESCAPE:
                self.game.change_scene(MainMenuScene(self.game))
            elif e.key in (pygame.K_RIGHT, pygame.K_d):
                self.sel = (self.sel + 1) % n
                self.game.audio.play("menu_move")
            elif e.key in (pygame.K_LEFT, pygame.K_a):
                self.sel = (self.sel - 1) % n
                self.game.audio.play("menu_move")
            elif e.key in (pygame.K_DOWN, pygame.K_s):
                self.sel = min(n - 1, self.sel + self.PER_ROW)
            elif e.key in (pygame.K_UP, pygame.K_w):
                self.sel = max(0, self.sel - self.PER_ROW)
            elif e.key in (pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_SPACE):
                self._go()
        elif e.type == pygame.MOUSEMOTION:
            for i, r in enumerate(self.rects):
                if r.collidepoint(e.pos):
                    self.sel = i
        elif e.type == pygame.MOUSEBUTTONDOWN and e.button == 1:
            for i, r in enumerate(self.rects):
                if r.collidepoint(e.pos):
                    self.sel = i
                    self._go()

    def update(self, dt):
        self.t += dt
        self.backdrop.update(dt)

    def draw(self, screen):
        self.backdrop.draw(screen)
        g = self.game
        draw_text(screen, g.fonts, "SELECIONAR FASE", 46, S.C_WHITE, (S.SCREEN_W // 2, 70), "center")
        for i, r in enumerate(self.rects):
            meta = g.levels.meta[i]
            locked = i >= g.save.unlocked
            sel = i == self.sel
            rr = r.inflate(12, 12).move(0, -6) if sel else r
            draw_panel(screen, rr, (16, 26, 54), 235, (255, 214, 58) if sel else (70, 100, 160), 16, 4 if sel else 2)
            sky = THEMES.get(meta["theme"], THEMES["factory"])["sky"]
            band = pygame.Rect(rr.x + 8, rr.y + 8, rr.w - 16, 80)
            pygame.draw.rect(screen, sky[1] if not locked else (50, 54, 70), band, border_radius=10)
            pygame.draw.rect(screen, sky[0] if not locked else (30, 32, 44), (band.x, band.y, band.w, 34), border_radius=10)
            draw_text(screen, g.fonts, str(i + 1), 52, S.C_WHITE if not locked else (120, 126, 150), band.center, "center")
            y = rr.y + 104
            for line in textwrap.wrap(meta["name"], 13)[:2]:
                draw_text(screen, g.fonts, line, 19, S.C_WHITE if not locked else (120, 126, 150), (rr.centerx, y), "center")
                y += 24
            if locked:
                draw_text(screen, g.fonts, "BLOQUEADA", 16, (200, 150, 120), (rr.centerx, rr.bottom - 40), "center")
            else:
                best = g.save.best.get(str(i))
                if best:
                    draw_text(screen, g.fonts, best["rank"], 40, RANK_COLORS[best["rank"]], (rr.centerx, rr.bottom - 66), "center")
                    draw_text(screen, g.fonts, format_time(best["time"]) + "   " + str(best["score"]) + " pts", 13,
                              (190, 210, 240), (rr.centerx, rr.bottom - 24), "center", bold=False, outline=None)
                else:
                    draw_text(screen, g.fonts, "NOVA", 18, S.C_GREEN, (rr.centerx, rr.bottom - 40), "center")
        sel_meta = g.levels.meta[self.sel]
        draw_text(screen, g.fonts, sel_meta["subtitle"], 20, S.C_CYAN_LIGHT, (S.SCREEN_W // 2, 520 + (g.levels.count // 6) * 100), "center")
        draw_text(screen, g.fonts, "ESC volta  |  ENTER joga", 15, (190, 210, 240), (S.SCREEN_W // 2, S.SCREEN_H - 18),
                  "center", bold=False)


class ControlsScene(Scene):
    def __init__(self, game):
        self.game = game
        self.backdrop = MenuBackdrop(game, "abandoned")
        self.t = 0.0

    def handle_event(self, e):
        if e.type in (pygame.KEYDOWN, pygame.MOUSEBUTTONDOWN):
            self.game.change_scene(MainMenuScene(self.game))

    def update(self, dt):
        self.t += dt
        self.backdrop.update(dt)

    @staticmethod
    def _key(screen, fonts, label, cx, cy, w=46):
        r = pygame.Rect(0, 0, w, 42)
        r.center = (cx, cy)
        pygame.draw.rect(screen, (8, 10, 22), r.move(0, 4), border_radius=8)
        pygame.draw.rect(screen, (214, 224, 244), r, border_radius=8)
        pygame.draw.rect(screen, (90, 104, 140), r, 3, border_radius=8)
        draw_text(screen, fonts, label, 20, (20, 26, 50), r.center, "center", outline=None, shadow=False)

    def draw(self, screen):
        self.backdrop.draw(screen)
        f = self.game.fonts
        draw_text(screen, f, "CONTROLES", 46, S.C_WHITE, (S.SCREEN_W // 2, 56), "center")
        for kind, cx, title, col, keys in (
                ("x", 255, "ROBO-X", S.C_RED_LIGHT, ("W", "A", "D")),
                ("b", 745, "ROBO-B", S.C_CYAN_LIGHT, ("^", "<", ">"))):
            draw_panel(screen, (cx - 215, 100, 430, 270), (14, 22, 48), 225, col, 18, 3)
            draw_text(screen, f, title, 30, col, (cx, 128), "center")
            spr = self.game.hero[kind].get("idle", self.t, 1 if kind == "x" else -1)
            small = pygame.transform.smoothscale(spr, (130, 130))
            screen.blit(small, (cx - 65 - 105, 175))
            self._key(screen, f, keys[0], cx + 90, 200)
            self._key(screen, f, keys[1], cx + 38, 252)
            self._key(screen, f, keys[2], cx + 142, 252)
            draw_text(screen, f, "pular", 15, S.C_WHITE, (cx + 90, 232), "center", bold=False, outline=None)
            draw_text(screen, f, "andar", 15, S.C_WHITE, (cx + 90, 292), "center", bold=False, outline=None)
            res = "Resiste à LAVA, morre na ÁGUA" if kind == "x" else "Resiste à ÁGUA, morre na LAVA"
            draw_text(screen, f, res, 16, col, (cx, 335), "center", bold=False)
        lines = [("TAB", "alterna o robô em foco (câmera e seta)"), ("1 / 2", "seleciona ROBO-X / ROBO-B"),
                 ("R", "reinicia a fase"), ("ESC", "pausa"), ("ENTER", "confirma")]
        for i, (k, d) in enumerate(lines):
            y = 405 + i * 36
            self._key(screen, f, k, 250, y, 84 if len(k) > 2 else 56)
            draw_text(screen, f, d, 19, S.C_WHITE, (320, y), "midleft", bold=False)
        draw_text(screen, f, "Os dois robôs existem ao mesmo tempo: use os dois conjuntos de teclas juntos!", 17, S.C_YELLOW,
                  (S.SCREEN_W // 2, S.SCREEN_H - 38), "center", bold=False)
        draw_text(screen, f, "Pressione qualquer tecla para voltar", 14, (190, 210, 240), (S.SCREEN_W // 2, S.SCREEN_H - 16),
                  "center", bold=False, outline=None)


class SettingsScene(Scene):
    def __init__(self, game, back):
        """`back` is either a Scene class (instantiated with game) or an existing Scene instance."""
        self.game, self.back = game, back
        self.backdrop = MenuBackdrop(game, "cave")
        self.sel = 0
        self.t = 0.0
        self.rows = pygame.Rect(180, 170, 640, 56)

    def _rect(self, i):
        return pygame.Rect(180, 170 + i * 72, 640, 56)

    def _exit(self):
        self.game.save.save()
        self.game.change_scene(self.back(self.game) if isinstance(self.back, type) else self.back)

    def _adjust(self, i, d):
        s = self.game.save.settings
        g = self.game
        if i == 0:
            s["music_volume"] = round(min(1.0, max(0.0, s["music_volume"] + 0.1 * d)), 2)
            g.audio.apply_volumes()
        elif i == 1:
            s["sfx_volume"] = round(min(1.0, max(0.0, s["sfx_volume"] + 0.1 * d)), 2)
            g.audio.play("crystal")
        elif i == 2:
            s["fullscreen"] = not s["fullscreen"]
            g.apply_fullscreen()
        elif i == 3:
            s["control_mode"] = "single" if s["control_mode"] == "dual" else "dual"
        g.audio.play("menu_move")

    def handle_event(self, e):
        if e.type == pygame.KEYDOWN:
            if e.key == pygame.K_ESCAPE:
                self._exit()
            elif e.key in (pygame.K_UP, pygame.K_w):
                self.sel = (self.sel - 1) % 5
            elif e.key in (pygame.K_DOWN, pygame.K_s):
                self.sel = (self.sel + 1) % 5
            elif e.key in (pygame.K_LEFT, pygame.K_a):
                if self.sel < 4:
                    self._adjust(self.sel, -1)
            elif e.key in (pygame.K_RIGHT, pygame.K_d):
                if self.sel < 4:
                    self._adjust(self.sel, 1)
            elif e.key in (pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_SPACE):
                if self.sel == 4:
                    self._exit()
                elif self.sel >= 2:
                    self._adjust(self.sel, 1)
        elif e.type == pygame.MOUSEMOTION:
            for i in range(5):
                if self._rect(i).collidepoint(e.pos):
                    self.sel = i
        elif e.type == pygame.MOUSEBUTTONDOWN and e.button == 1:
            for i in range(5):
                r = self._rect(i)
                if r.collidepoint(e.pos):
                    self.sel = i
                    if i == 4:
                        self._exit()
                    else:
                        self._adjust(i, 1 if e.pos[0] > r.centerx else -1)

    def update(self, dt):
        self.t += dt
        self.backdrop.update(dt)

    def draw(self, screen):
        self.backdrop.draw(screen)
        f = self.game.fonts
        s = self.game.save.settings
        draw_text(screen, f, "CONFIGURAÇÕES", 46, S.C_WHITE, (S.SCREEN_W // 2, 70), "center")
        labels = ["Volume da música", "Volume dos efeitos", "Tela cheia", "Modo de controle", "VOLTAR"]
        for i, label in enumerate(labels):
            r = self._rect(i)
            sel = i == self.sel
            draw_panel(screen, r, (18, 30, 66) if not sel else (40, 90, 190), 230, (255, 214, 58) if sel else (70, 100, 160), 14, 3)
            draw_text(screen, f, label, 22, S.C_WHITE, (r.x + 22, r.centery), "midleft")
            if i < 2:
                v = s["music_volume"] if i == 0 else s["sfx_volume"]
                bar = pygame.Rect(r.x + 330, r.centery - 8, 220, 16)
                pygame.draw.rect(screen, (8, 12, 28), bar, border_radius=8)
                pygame.draw.rect(screen, S.C_CYAN, (bar.x, bar.y, int(bar.w * v), bar.h), border_radius=8)
                pygame.draw.rect(screen, S.C_WHITE, bar, 2, border_radius=8)
                draw_text(screen, f, "%d%%" % int(v * 100), 18, S.C_WHITE, (r.right - 22, r.centery), "midright")
            elif i == 2:
                draw_text(screen, f, "LIGADA" if s["fullscreen"] else "DESLIGADA", 20, S.C_GREEN if s["fullscreen"] else (200, 200, 210),
                          (r.right - 22, r.centery), "midright")
            elif i == 3:
                draw_text(screen, f, "Simultâneo" if s["control_mode"] == "dual" else "Alternado (TAB)", 20, S.C_YELLOW,
                          (r.right - 22, r.centery), "midright")
        hint = ("Simultâneo: WASD controla o ROBO-X e as setas o ROBO-B ao mesmo tempo."
                if s["control_mode"] == "dual" else "Alternado: só o robô em foco se move (qualquer conjunto de teclas).")
        draw_text(screen, f, hint, 16, S.C_CYAN_LIGHT, (S.SCREEN_W // 2, 545), "center", bold=False)
        draw_text(screen, f, "Setas esquerda/direita ajustam  |  ESC volta", 15, (190, 210, 240), (S.SCREEN_W // 2, S.SCREEN_H - 18),
                  "center", bold=False)


class CompleteScene(Scene):
    def __init__(self, game, index, time_s, crystals, total, rank, score, new_best):
        self.game, self.index = game, index
        self.stats = (time_s, crystals, total, rank, score, new_best)
        self.backdrop = MenuBackdrop(game, game.levels.meta[index]["theme"])
        self.particles = ParticleSystem()
        labels = []
        if game.levels.has_next(index):
            labels.append("PRÓXIMA FASE")
        labels += ["REPETIR FASE", "MENU PRINCIPAL"]
        self.labels = labels
        self.menu = ButtonList(game, labels, top=455, h=44, gap=10, w=300)
        self.t = 0.0
        self.reveal = 0.0
        game.audio.play("victory")

    def handle_event(self, e):
        i = self.menu.handle_event(e)
        if i is None:
            return
        g, label = self.game, self.labels[i]
        if label == "PRÓXIMA FASE":
            g.start_level(self.index + 1)
        elif label == "REPETIR FASE":
            g.start_level(self.index)
        else:
            g.change_scene(MainMenuScene(g))

    def update(self, dt):
        self.t += dt
        self.reveal = min(1.0, self.reveal + dt * 1.5)
        self.backdrop.update(dt)
        if int(self.t * 6) != int((self.t - dt) * 6):
            self.particles.confetti(random.uniform(100, 900), -10, 3)
        self.particles.update(dt)

    def draw(self, screen):
        self.backdrop.draw(screen)
        self.particles.draw(screen, 0, 0)
        g, f = self.game, self.game.fonts
        time_s, crystals, total, rank, score, new_best = self.stats
        draw_panel(screen, (250, 40, 500, 400), (12, 20, 46), 235, S.C_YELLOW, 22, 4)
        draw_text(screen, f, "FASE CONCLUÍDA!", 40, S.C_YELLOW, (500, 85), "center")
        draw_text(screen, f, g.levels.meta[self.index]["name"], 22, S.C_CYAN_LIGHT, (500, 125), "center")
        rows = [("Tempo", format_time(time_s)), ("Cristais", "%d / %d" % (crystals, total)), ("Pontuação", str(score))]
        for i, (k, v) in enumerate(rows):
            y = 180 + i * 42
            draw_text(screen, f, k, 24, S.C_WHITE, (290, y), "midleft")
            draw_text(screen, f, v, 26, S.C_YELLOW, (550, y), "midright")
        size = 120 + int(20 * (1 - self.reveal))
        col = RANK_COLORS[rank]
        draw_text(screen, f, rank, int(size * self.reveal) + 10, col, (640, 270), "center")
        draw_text(screen, f, "CLASSIFICAÇÃO", 14, S.C_WHITE, (640, 335), "center", bold=False, outline=None)
        if new_best:
            draw_text(screen, f, "NOVO RECORDE!", 22, S.C_GREEN, (500, 400), "center")
        for kind, cx, facing in (("x", 120, 1), ("b", S.SCREEN_W - 120, -1)):
            spr = g.hero[kind].get("victory", self.t, facing)
            screen.blit(spr, (cx - spr.get_width() // 2, 300))
        self.menu.draw(screen, self.t)
