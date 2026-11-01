"""Menú Principal: [1] Nueva Partida (desde el prólogo) y [2] Continuar (perfiles guardados en saves/).

En «Continuar» se elige el perfil con las flechas y ENTER (o con un clic), o se escribe su nombre y ENTER. Sin partidas
guardadas aparece «No hay registros guardados» con un aviso sonoro. [SUPR] (o [X] con la caja de nombre vacía) o el botón
«Borrar» de cada fila piden borrar el perfil: una ventana de confirmación ([ENTER]/Sí borra, [ESC]/No cancela)."""
import datetime
import time

import pygame

import config as C
from src.core import sfx
from src.core.audio_manager import audio
from src.managers.state_machine import GameState, State
from src.mechanics import save_manager as saves
from src.ui.name_input import NameInput

ROW_H = 54
MAX_ROWS = 7


def _when(stamp):
    try:
        return datetime.datetime.fromisoformat(stamp).strftime("%d/%m/%Y %H:%M")
    except (TypeError, ValueError):
        return stamp or "-"


class MainMenuState(State):
    def enter(self, **kwargs):
        audio.play_music("menu")
        self.mode = "main"                       # "main" | "continue"
        self.profiles = []
        self.selected = 0
        self.typed = NameInput(max_len=saves.MAX_NAME)
        self.notice, self.notice_until = "", 0.0
        self.row_rects = []
        self.delete_rects = []                   # botón «Borrar» de cada fila
        self.confirm = None                      # perfil pendiente de confirmar su borrado
        self.confirm_buttons = {}

    # --- acciones ---
    def exit(self):
        audio.stop_music()

    def new_game(self):
        self.game.new_campaign()
        self.game.machine.transition(GameState.SUB_ACT_1_1)

    def open_continue(self):
        """[2] Continuar: lista los perfiles; sin ninguno, aviso visual y sonoro."""
        self.profiles = saves.list_profiles()
        if not self.profiles:
            self.warn("No hay registros guardados")
            return False
        self.mode, self.selected = "continue", 0
        self.typed = NameInput(max_len=saves.MAX_NAME)
        return True

    def warn(self, text):
        self.notice, self.notice_until = text, time.monotonic() + 3.0
        sfx.play("error")

    # --- borrado de perfiles ---
    def request_delete(self, index=None):
        """[SUPR] / [X] / botón «Borrar»: abre la confirmación del perfil seleccionado (o el de la fila `index`)."""
        if not self.profiles:
            return False
        if index is not None:
            self.selected = index
        self.confirm = self.profiles[self.selected]
        return True

    def confirm_delete(self):
        """Sí: borra el archivo, avisa con un tono y refresca la lista con el cursor en el perfil de al lado. Si era el
        último, vuelve al menú con «No hay registros guardados»."""
        prof, self.confirm = self.confirm, None
        if prof is None:
            return False
        ok = saves.delete_save_profile(prof["name"], path=prof["path"])
        sfx.play("error")
        self.profiles = saves.list_profiles()
        if not ok:
            self.warn(f"No se pudo borrar el perfil «{prof['name']}»")
            return False
        if not self.profiles:
            self.mode = "main"
            self.notice, self.notice_until = "No hay registros guardados", time.monotonic() + 3.0
            return True
        self.selected = min(self.selected, len(self.profiles) - 1)      # el adyacente ocupa su lugar
        self.notice, self.notice_until = f"Perfil «{prof['name']}» eliminado", time.monotonic() + 3.0
        return True

    def cancel_delete(self):
        self.confirm = None

    def _confirm_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
                self.confirm_delete()
            elif event.key == pygame.K_ESCAPE:
                self.cancel_delete()
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.confirm_buttons.get("yes", pygame.Rect(0, 0, 0, 0)).collidepoint(event.pos):
                self.confirm_delete()
            elif self.confirm_buttons.get("no", pygame.Rect(0, 0, 0, 0)).collidepoint(event.pos):
                self.cancel_delete()

    def load(self, profile):
        self.game.continue_profile(profile["path"])

    def load_typed(self):
        """ENTER con un nombre escrito: reanuda ese perfil (sin distinguir mayúsculas)."""
        profile = saves.find_profile(self.typed.text)
        if profile is None:
            self.warn(f"No existe el perfil «{self.typed.text}»")
            self.typed.done = False
            return False
        self.load(profile)
        return True

    # --- eventos ---
    def handle_event(self, event):
        if self.mode == "continue":
            self._continue_event(event)
            return
        if event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_1, pygame.K_KP1, pygame.K_RETURN, pygame.K_KP_ENTER):
                self.new_game()
            elif event.key in (pygame.K_2, pygame.K_KP2):
                self.open_continue()
            elif event.key == pygame.K_ESCAPE:
                self.game.running = False
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            for key, rect in self._main_buttons().items():
                if rect.collidepoint(event.pos):
                    self.new_game() if key == "new" else self.open_continue()

    def _continue_event(self, event):
        if self.confirm is not None:                     # la confirmación de borrado manda sobre todo
            self._confirm_event(event)
            return
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_DELETE or (event.key == pygame.K_x and not self.typed.text):
                self.request_delete()                    # la X solo borra con la caja de nombre vacía (si no, es una letra)
            elif event.key == pygame.K_ESCAPE:
                self.mode = "main"
            elif event.key in (pygame.K_UP, pygame.K_DOWN):
                step = -1 if event.key == pygame.K_UP else 1
                self.selected = (self.selected + step) % len(self.profiles)
            elif event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
                if self.typed.text:
                    self.load_typed()
                else:
                    self.load(self.profiles[self.selected])
            else:
                self.typed.handle_event(event)            # escribir el nombre del perfil (letras, números, Retroceso)
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            for i, rect in enumerate(self.delete_rects):
                if rect.collidepoint(event.pos):
                    self.request_delete(i)
                    return
            for i, rect in enumerate(self.row_rects):
                if rect.collidepoint(event.pos):
                    self.selected = i
                    self.load(self.profiles[i])
                    return

    # --- dibujo ---
    @staticmethod
    def _main_buttons():
        cx = C.WINDOW_WIDTH // 2
        return {"new": pygame.Rect(cx - 330, 330, 300, 70), "continue": pygame.Rect(cx + 30, 330, 300, 70)}

    def draw(self, screen):
        hud = self.game.hud
        screen.fill(C.BG_COLOR)
        cx = C.WINDOW_WIDTH // 2
        hud.text(screen, "ROBOT RENEGADO", (cx, 150), "xl", C.CYAN, center=True)
        hud.text(screen, "Una señal fantasma, una IA atrapada y una fábrica que hay que destruir.", (cx, 228), "m", C.MAGENTA,
                 center=True)
        if self.mode == "continue":
            self._draw_profiles(screen, hud, cx)
        else:
            mouse = pygame.mouse.get_pos()
            for key, rect in self._main_buttons().items():
                color = C.GREEN if key == "new" else C.CYAN
                hud.panel(screen, rect, color)
                if rect.collidepoint(mouse):
                    pygame.draw.rect(screen, color, rect, 3)
                label = "[1] NUEVA PARTIDA" if key == "new" else "[2] CONTINUAR"
                sub = "Desde el prólogo" if key == "new" else "Perfiles guardados"
                hud.text(screen, label, (rect.centerx, rect.y + 14), "m", color, center=True)
                hud.text(screen, sub, (rect.centerx, rect.y + 44), "s", C.WHITE, center=True)
            hud.text(screen, "WASD mover · SHIFT dash · clic izq. disparar/construir · H botiquín · E interactuar · ESPACIO pausa",
                     (cx, 470), "s", C.CYAN, center=True)
            hud.text(screen, "[1] / ENTER Nueva partida    [2] Continuar    [ESC] Salir", (cx, 560), "l", C.YELLOW, center=True)
        if self.notice and time.monotonic() < self.notice_until:
            r = pygame.Rect(0, 0, 520, 46)
            r.center = (cx, 640)
            hud.panel(screen, r, C.RED)
            hud.text(screen, self.notice, r.center, "m", C.RED, center=True)

    def _draw_profiles(self, screen, hud, cx):
        hud.text(screen, "CONTINUAR · PERFILES GUARDADOS", (cx, 270), "l", C.CYAN, center=True)
        self.row_rects, self.delete_rects = [], []
        mouse = pygame.mouse.get_pos()
        top = 310
        typed = self.typed.text.lower()
        for i, prof in enumerate(self.profiles[:MAX_ROWS]):
            rect = pygame.Rect(cx - 420, top + i * ROW_H, 840, ROW_H - 6)
            self.row_rects.append(rect)
            sel = i == self.selected
            match = bool(typed) and prof["name"].lower().startswith(typed)
            color = C.YELLOW if sel else (C.GREEN if match else C.DARK_GRAY)
            hud.panel(screen, rect, color)
            if sel:
                pygame.draw.rect(screen, color, rect, 3)
            hud.text(screen, prof["name"], (rect.x + 14, rect.y + 6), "m", C.WHITE if sel else C.CYAN)
            hud.text(screen, _when(prof["saved_at"]), (rect.right - 290, rect.y + 6), "s", C.DARK_GRAY)
            delete = pygame.Rect(rect.right - 104, rect.y + 8, 94, rect.h - 16)          # botón «Borrar» de la fila
            self.delete_rects.append(delete)
            hot = delete.collidepoint(mouse)
            hud.panel(screen, delete, C.RED if hot else (120, 40, 46))
            hud.text(screen, "X Borrar", delete.center, "s", C.RED if hot else (200, 90, 96), center=True)
            hud.text(screen, prof["progress"], (rect.x + 14, rect.y + 28), "s", (190, 195, 210), shadow=False)
        y = top + min(len(self.profiles), MAX_ROWS) * ROW_H + 10
        box = pygame.Rect(cx - 200, y, 400, 36)
        pygame.draw.rect(screen, (8, 14, 22), box)
        pygame.draw.rect(screen, C.CYAN, box, 1)
        r = hud.text(screen, self.typed.text or "escribe un nombre...", (box.x + 10, box.y + 8), "s",
                     C.WHITE if self.typed.text else C.DARK_GRAY, shadow=False)
        if self.typed.cursor_on:
            x = r.right + 3 if self.typed.text else box.x + 10
            pygame.draw.line(screen, C.CYAN, (x, box.y + 7), (x, box.bottom - 7), 2)
        hud.text(screen, "Flechas + ENTER elegir · escribe un nombre + ENTER · clic en un perfil · ESC volver",
                 (cx, box.bottom + 14), "s", C.DARK_GRAY, center=True)
        hud.text(screen, "[SUPR / X] Borrar partida", (cx, box.bottom + 38), "s", (220, 110, 110), center=True)
        if self.confirm is not None:
            self._draw_confirm(screen, hud, cx)

    def _draw_confirm(self, screen, hud, cx):
        """Ventana modal: «¿Eliminar el perfil de 'Nombre' permanentemente?» con Sí / No."""
        shade = pygame.Surface(screen.get_size(), pygame.SRCALPHA)
        shade.fill((0, 0, 0, 170))
        screen.blit(shade, (0, 0))
        panel = pygame.Rect(0, 0, 640, 200)
        panel.center = (cx, C.WINDOW_HEIGHT // 2)
        pygame.draw.rect(screen, (10, 12, 20), panel)               # opaca: la lista no se transparenta
        hud.panel(screen, panel, C.RED)
        hud.text(screen, "BORRAR PARTIDA", (cx, panel.y + 18), "m", C.RED, center=True)
        hud.text(screen, f"¿Eliminar el perfil de '{self.confirm['name']}' permanentemente?", (cx, panel.y + 62), "m",
                 C.WHITE, center=True)
        self.confirm_buttons = {"yes": pygame.Rect(cx - 250, panel.bottom - 74, 230, 52),
                                "no": pygame.Rect(cx + 20, panel.bottom - 74, 230, 52)}
        mouse = pygame.mouse.get_pos()
        for key, label, color in (("yes", "[ENTER] Sí, borrar", C.RED), ("no", "[ESC] No", C.CYAN)):
            rect = self.confirm_buttons[key]
            hud.panel(screen, rect, color)
            if rect.collidepoint(mouse):
                pygame.draw.rect(screen, color, rect, 3)
            hud.text(screen, label, rect.center, "m", color, center=True)
