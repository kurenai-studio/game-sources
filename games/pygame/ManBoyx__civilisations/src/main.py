#!/usr/bin/env python3
"""Trois civilisations, du Moyen-Âge à nos jours — bac à sable divin (pygame)."""
import math
import os
import random
import sys
import time

import pygame

import sim as S
from gfx import Gfx, TS
from sim import (W, H, RES, RNAME, TECH, GOV, BDEF, ERAS, BIOMES, SEASONS, CHILD, TNAME, END_YEAR)

WIN_W, WIN_H = 1700, 960
SIDEX = 1300
VIEW = pygame.Rect(0, 124, SIDEX, 686)
BG, PANEL, LINE, TX, MUT, ACC = (20, 22, 26), (29, 32, 38), (48, 53, 62), (232, 234, 238), (150, 158, 170), (240, 180, 40)
RCOL = {'food': (230, 70, 90), 'water': (70, 150, 230), 'wood': (160, 105, 50), 'stone': (170, 170, 180), 'metal': (245, 175, 60)}
ACT = {'food': RCOL['food'], 'water': RCOL['water'], 'wood': RCOL['wood'], 'stone': RCOL['stone'], 'metal': RCOL['metal'],
       'armée': (220, 60, 60), 'combat': (255, 40, 40), 'garde': (180, 80, 80), 'repos': (90, 100, 150), 'abri': (90, 100, 150),
       'repas': (210, 130, 170), 'social': (240, 220, 90), 'explore': (110, 200, 110), 'fuite': (255, 150, 60),
       'gouverne': (255, 215, 60), 'jeu': (160, 220, 240), 'autre': (95, 100, 110)}
TABS = [('terrain', 'Terrain'), ('meteo', 'Météo'), ('cata', 'Catastrophes'), ('crea', 'Créatures'), ('civ', 'Civilisation')]
POWERS = {
    'terrain': [('deep', 'Abysse'), ('water', 'Eau'), ('sand', 'Sable'), ('grass', 'Herbe'), ('forest', 'Forêt'), ('mountain', 'Montagne'),
                ('ice', 'Neige'), ('lava', 'Lave'), ('berries', 'Baies'), ('ore', 'Minerai'), ('rock', 'Pierre'), ('erase', 'Gomme')],
    'meteo': [('rain', 'Pluie'), ('storm', 'Orage'), ('snow', 'Neige'), ('blizzard', 'Blizzard'), ('heat', 'Canicule'), ('fog', 'Brouillard'),
              ('clear', 'Ciel clair')],
    'cata': [('bolt', 'Foudre'), ('meteor', 'Météorite'), ('quake', 'Séisme'), ('volcano', 'Volcan'), ('tornado', 'Tornade'),
             ('flood', 'Inondation'), ('fire', 'Incendie'), ('locust', 'Criquets'), ('plague', 'Épidémie'), ('drought', 'Sécheresse')],
    'crea': [('villager', 'Villageois'), ('group', 'Groupe x6'), ('deer', 'Cerfs'), ('wolves', 'Loups'), ('bless', 'Bénir'),
             ('heal', 'Soigner'), ('manna', 'Manne')],
    'civ': [('build', 'Construire'), ('demolish', 'Démolir')],
}
PAINT = {'deep', 'water', 'sand', 'grass', 'forest', 'mountain', 'ice', 'lava', 'berries', 'ore', 'rock', 'erase'}
SPEEDS = [(1, 'x1'), (2, 'x2'), (5, 'x5'), (10, 'x10'), (30, 'x30'), (100, 'MAX')]
CARD_H = 204


class Button:
    def __init__(self, rect, label, cb, active=None, col=None):
        self.rect, self.label, self.cb, self.active, self.col = pygame.Rect(rect), label, cb, active, col

    def draw(self, ui, hover):
        on = self.active() if self.active else False
        bg = (74, 64, 30) if on else (54, 59, 68) if hover else (40, 44, 52)
        pygame.draw.rect(ui.scr, bg, self.rect, border_radius=4)
        pygame.draw.rect(ui.scr, ACC if on else LINE, self.rect, 1, border_radius=4)
        t = ui.f.render(self.label, True, self.col or TX)
        ui.scr.blit(t, t.get_rect(center=self.rect.center))


class Slider:
    def __init__(self, rect, get, set_, lo, hi, label, col=ACC, fmt='%.1f'):
        self.rect, self.get, self.set, self.lo, self.hi, self.label, self.col, self.fmt = pygame.Rect(rect), get, set_, lo, hi, label, col, fmt

    def set_from(self, x):
        f = max(0, min(1, (x - self.rect.x) / self.rect.w))
        self.set(round(self.lo + f * (self.hi - self.lo), 2))

    def draw(self, ui, label_dy=-12):
        v = self.get()
        f = (v - self.lo) / (self.hi - self.lo)
        ui.text('%s %s' % (self.label, self.fmt % v), self.rect.x, self.rect.y + label_dy, MUT, ui.fs)
        ui.bar(self.rect.x, self.rect.y + 2, self.rect.w, 6, f, self.col)
        pygame.draw.circle(ui.scr, (255, 255, 255), (self.rect.x + int(self.rect.w * f), self.rect.y + 5), 5)


class UI:
    def __init__(self):
        pygame.init()
        flags = pygame.SCALED | pygame.RESIZABLE
        self.scr = pygame.display.set_mode((WIN_W, WIN_H), flags)
        pygame.display.set_caption('Trois Civilisations — du Moyen-Âge à nos jours')
        name = pygame.font.match_font('dejavusans,liberationsans,arial') or None
        self.f = pygame.font.Font(name, 13)
        self.fs = pygame.font.Font(name, 11)
        self.ft = pygame.font.Font(name, 9)
        self.fb = pygame.font.Font(name, 16)
        self.fl = pygame.font.Font(name, 26)
        self.clock = pygame.time.Clock()
        self.speed, self.paused = 1, False
        self.tab, self.power, self.btype, self.size = 'terrain', 'look', 'house', 2
        self.sel = 0
        self.picked = None
        self.follow = False
        self.names = False
        self.hover_tile = None
        self.toast = ('', 0)
        self.banner = 0
        self.acc = 0.0
        self.tps = 0
        self.painting = False
        self.drag = None
        self.panning = None
        self.diplo = []
        self.view = dict(x=0.0, y=0.0, z=1.0, sel=None)
        self.xf = (0, 0, 1)
        self.mini = None
        self.mini_t = 0
        self.tip = ''
        self._rc = False
        self.new_world()

    # ───────── monde ─────────
    def new_world(self):
        self.sim = S.Sim()
        self.gfx = Gfx(self.sim)
        self.gfx.init_font(self.fs)
        self.picked = None
        self.mini = None
        self.banner = 0
        self.view.update(x=0.0, y=0.0, z=1.4, sel=None)
        self.center_on(120, 75)
        self.build_ui()

    def build_ui(self):
        self.buttons, self.sliders, self.world_sl, self.card_sl = [], [], [], []
        B = self.buttons
        sim = self.sim
        B.append(Button((10, 8, 70, 28), 'Pause', self.toggle_pause, lambda: self.paused))
        x = 86
        for v, lab in SPEEDS:
            B.append(Button((x, 8, 44, 28), lab, lambda v=v: self.set_speed(v), lambda v=v: self.speed == v and not self.paused))
            x += 48
        B.append(Button((SIDEX - 250, 8, 120, 28), 'Nouvelle carte', self.new_world, col=(255, 160, 140)))
        B.append(Button((SIDEX - 124, 8, 112, 28), 'Noms/Pensées', lambda: setattr(self, 'names', not self.names), lambda: self.names))
        x = 10
        for k, lab in TABS:
            B.append(Button((x, 46, 124, 28), lab, lambda k=k: self.set_tab(k), lambda k=k: self.tab == k, col=ACC))
            x += 128
        B.append(Button((x + 8, 46, 90, 28), 'Observer', lambda: setattr(self, 'power', 'look'), lambda: self.power == 'look'))
        self.size_sl = Slider((SIDEX - 150, 90, 130, 10), lambda: self.size, lambda v: setattr(self, 'size', int(round(v))), 1, 8, 'Pinceau', fmt='%d')
        self.sliders.append(self.size_sl)
        self.build_powers()
        keys = [('food', 'Nourriture', 2), ('water', 'Eau', 2), ('wood', 'Bois', 2), ('stone', 'Pierre', 2), ('metal', 'Métal', 2), ('military', 'Armée', 1)]
        for c in sim.civs:
            y0 = c.id * CARD_H
            for n, (k, lab, mx) in enumerate(keys):
                col, row = n % 3, n // 3
                self.card_sl.append(Slider((SIDEX + 12 + col * 128, y0 + 166 + row * 20, 112, 10),
                                           lambda c=c, k=k: c.prio[k], lambda v, c=c, k=k: c.prio.__setitem__(k, v), 0, mx, lab, c.color))
        wy = 3 * CARD_H + 100 + 14
        defs = [('temp', 'Température', -1, 1), ('fert', 'Fertilité', 0, 3), ('birth', 'Natalité', 0, 3), ('cons', 'Consommation', .3, 3),
                ('research', 'Recherche', 0, 4), ('wfreq', 'Météo', 0, 4), ('aggr', 'Belligérance', 0, 3)]
        for n, (k, lab, lo, hi) in enumerate(defs):
            col, row = n % 2, n // 2
            self.world_sl.append(Slider((SIDEX + 12 + col * 195, wy + 14 + row * 20, 170, 10),
                                        lambda k=k: sim.p[k], lambda v, k=k: sim.p.__setitem__(k, v), lo, hi, lab, (120, 200, 160)))
        self.all_sl = self.sliders + self.card_sl + self.world_sl

    def build_powers(self):
        self.power_btns = []
        x = 10
        for k, lab in POWERS[self.tab]:
            w = max(70, 12 + len(lab) * 8)
            self.power_btns.append(Button((x, 84, w, 28), lab, lambda k=k: self.set_power(k), lambda k=k: self.power == k))
            x += w + 4
        if self.tab == 'civ':
            self.power_btns.append(Button((x + 6, 84, 170, 28), 'Bâtiment : %s' % BDEF[self.btype][0], self.cycle_btype, col=ACC))
            x += 182
            c = lambda: self.sim.civs[self.sel]
            self.power_btns.append(Button((x, 84, 100, 28), 'Offrande', lambda: self.sim.gift(c())))
            self.power_btns.append(Button((x + 104, 84, 100, 28), 'Filon', lambda: self.sim.ev_ore(c())))
            self.power_btns.append(Button((x + 208, 84, 120, 28), 'Révolution', lambda: self.sim.revolution(c(), None, True), col=(255, 160, 140)))
            self.power_btns.append(Button((x + 332, 84, 120, 28), 'Famine', self.famine, col=(255, 160, 140)))

    def famine(self):
        c = self.sim.civs[self.sel]
        c.stock['food'] = 0
        c.stock['water'] = 0
        self.sim.say('Famine provoquée chez %s' % c.name, (255, 150, 100))

    def toggle_pause(self):
        self.paused = not self.paused

    def set_speed(self, v):
        self.speed, self.paused = v, False

    def set_tab(self, k):
        self.tab = k
        self.build_powers()
        self.power = POWERS[k][0][0]

    def set_power(self, k):
        self.power = k

    def cycle_btype(self):
        ks = list(BDEF)
        self.btype = ks[(ks.index(self.btype) + 1) % len(ks)]
        self.build_powers()

    def say_toast(self, m):
        self.toast = (m, 160)

    # ───────── utilitaires de dessin ─────────
    def text(self, s, x, y, col=TX, font=None):
        t = (font or self.f).render(s, True, col)
        self.scr.blit(t, (x, y))
        return t.get_width()

    def bar(self, x, y, w, h, frac, col, bg=(45, 49, 57)):
        pygame.draw.rect(self.scr, bg, (x, y, w, h), border_radius=2)
        if frac > 0:
            pygame.draw.rect(self.scr, col, (x, y, max(1, int(w * max(0, min(1, frac)))), h), border_radius=2)

    def wrap(self, s, font, w):
        out, line = [], ''
        for word in s.split():
            test = (line + ' ' + word).strip()
            if font.size(test)[0] > w and line:
                out.append(line)
                line = word
            else:
                line = test
        if line:
            out.append(line)
        return out

    # ───────── caméra ─────────
    def tile_at(self, pos):
        if not VIEW.collidepoint(pos):
            return None
        ox, oy, tz = self.xf
        x, y = int((pos[0] - ox) / tz), int((pos[1] - oy) / tz)
        if 0 <= x < W and 0 <= y < H:
            return x, y
        return None

    def zoom_at(self, pos, f):
        v = self.view
        z0 = v['z']
        z1 = max(.55, min(7, z0 * f))
        wx, wy = v['x'] + (pos[0] - VIEW.x) / z0, v['y'] + (pos[1] - VIEW.y) / z0
        v['z'] = z1
        v['x'], v['y'] = wx - (pos[0] - VIEW.x) / z1, wy - (pos[1] - VIEW.y) / z1

    def center_on(self, x, y):
        v = self.view
        v['x'] = x * TS - VIEW.w / v['z'] / 2
        v['y'] = y * TS - VIEW.h / v['z'] / 2

    def minimap_rect(self):
        return pygame.Rect(VIEW.x + 8, VIEW.bottom - 158, 240, 150)

    # ───────── pouvoirs ─────────
    def apply(self, t, first):
        sim = self.sim
        c = sim.civs[self.sel]
        x, y = t
        if self.power == 'look':
            if first:
                self.pick(x, y)
            return
        if self.power in PAINT:
            sim.power(self.power, x, y, c, self.size)
            return
        if not first:
            return
        msg = sim.power(self.power, x, y, c, self.size, self.btype)
        if msg:
            self.say_toast(msg)

    def pick(self, x, y):
        best, bd = None, 2.2
        for c in self.sim.civs:
            for a in c.agents:
                d = math.hypot(a.x - x, a.y - y)
                if d < bd:
                    best, bd = a, d
        self.picked = best
        self.view['sel'] = best

    # ───────── panneaux ─────────
    def draw_top(self):
        sim = self.sim
        pygame.draw.rect(self.scr, PANEL, (0, 0, SIDEX, VIEW.y))
        mouse = pygame.mouse.get_pos()
        for b in self.buttons + self.power_btns:
            b.draw(self, b.rect.collidepoint(mouse))
        y = sim.year()
        self.text('%d' % y, 400, 4, TX, self.fl)
        self.text('%s · %s' % (SEASONS[sim.season()], ERAS[sim.world_era()]), 490, 14, ACC)
        self.text('%02dh' % int(sim.hour() * 24), 700, 14, MUT)
        self.bar(750, 16, 160, 8, (y - 1000) / (END_YEAR - 1000), ACC)
        self.text('→ %d' % END_YEAR, 916, 14, MUT, self.fs)
        if self.power != 'look':
            nm = dict(sum(POWERS.values(), []))[self.power]
            self.text('Outil actif : %s' % nm, 10, 114, MUT, self.fs)
        self.size_sl.draw(self)

    def draw_cards(self):
        sim = self.sim
        pygame.draw.rect(self.scr, PANEL, (SIDEX, 0, WIN_W - SIDEX, WIN_H))
        mouse = pygame.mouse.get_pos()
        self.tip = ''
        for c in sim.civs:
            y0 = c.id * CARD_H
            card = pygame.Rect(SIDEX + 4, y0 + 4, 392, CARD_H - 6)
            pygame.draw.rect(self.scr, (35, 39, 46), card, border_radius=6)
            pygame.draw.rect(self.scr, c.color if c.id == self.sel else LINE, card, 2, border_radius=6)
            pygame.draw.circle(self.scr, c.color, (SIDEX + 22, y0 + 20), 8)
            self.text(c.name, SIDEX + 36, y0 + 10, TX, self.fb)
            g = GOV[c.gov]
            gr = pygame.Rect(SIDEX + 112, y0 + 10, 100, 20)
            pygame.draw.rect(self.scr, (60, 52, 30) if gr.collidepoint(mouse) else (44, 48, 56), gr, border_radius=4)
            self.text(g['name'], gr.x + 8, gr.y + 3, ACC)
            if c.alive:
                self.text('Pop %d/%d' % (c.pop, sim.cap(c)), SIDEX + 222, y0 + 12, TX)
                x = SIDEX + 300
                for fl in sorted(c.flags):
                    col = (255, 90, 90) if fl in ('GUERRE', 'FAIM', 'SOIF') else (130, 190, 255)
                    x += self.text(fl, x, y0 + 14, col, self.fs) + 5
                ld = c.leader
                self.text('%s · %s %s' % (ERAS[c.era], sim.title(c), ld.name if ld else '—'), SIDEX + 14, y0 + 32, MUT, self.fs)
                self.text('Armée %d · humeur %d' % (c.soldiers, c.mood), SIDEX + 270, y0 + 32, MUT, self.fs)
                cnt = {}
                for a in c.agents:
                    cnt[a.act] = cnt.get(a.act, 0) + 1
                xx, tot = SIDEX + 12, max(1, c.pop)
                for k, n in sorted(cnt.items(), key=lambda kv: -kv[1]):
                    w = int(368 * n / tot)
                    pygame.draw.rect(self.scr, ACT.get(k, (95, 100, 110)), (xx, y0 + 46, max(1, w), 5))
                    xx += w
                if pygame.Rect(SIDEX + 12, y0 + 44, 368, 9).collidepoint(mouse):
                    self.tip = 'Activités : ' + ', '.join('%d %s' % (n, k) for k, n in sorted(cnt.items(), key=lambda kv: -kv[1]))
            else:
                self.text('ÉTEINTE — cliquer pour refonder', SIDEX + 222, y0 + 12, (255, 90, 90))
            cap = sim.stock_cap(c)
            for n, r in enumerate(RES):
                yy = y0 + 55 + n * 11
                self.text(RNAME[r], SIDEX + 14, yy - 2, MUT, self.fs)
                self.bar(SIDEX + 84, yy + 1, 220, 7, c.stock[r] / cap, RCOL[r])
                need = max(1, c.pop) * S.PER[r]
                mx = SIDEX + 84 + int(220 * min(1, need / cap))
                pygame.draw.line(self.scr, (255, 255, 255), (mx, yy), (mx, yy + 9))
                self.text('%d' % c.stock[r], SIDEX + 312, yy - 2, TX, self.fs)
            self.text('clic : +10', SIDEX + 340, y0 + 60, (80, 86, 98), self.ft)
            self.text('clic droit : -10', SIDEX + 340, y0 + 71, (80, 86, 98), self.ft)
            for k, (key, tk) in enumerate(TECH.items()):
                rect = pygame.Rect(SIDEX + 10 + (k % 10) * 38, y0 + 113 + (k // 10) * 13, 36, 12)
                known = key in c.tech
                ok = all(q in c.tech for q in tk[2])
                bg = (50, 120, 70) if known else (110, 90, 30) if c.research == key else (42, 46, 54) if ok else (30, 32, 38)
                pygame.draw.rect(self.scr, bg, rect, border_radius=2)
                if c.research == key:
                    pygame.draw.rect(self.scr, ACC, (rect.x, rect.bottom - 2, int(36 * c.rp / tk[1]), 2))
                self.text(tk[3][:6], rect.x + 2, rect.y + 2, TX if (known or ok) else (90, 95, 105), self.ft)
                if rect.collidepoint(mouse):
                    self.tip = '%s — %s — coût %d%s' % (tk[0], ERAS[tk[4]], tk[1], '' if ok else ' (prérequis manquants)')
            if c.research:
                self.text('Recherche : %s  %d/%d' % (TECH[c.research][0], c.rp, TECH[c.research][1]), SIDEX + 12, y0 + 140, MUT, self.fs)
            else:
                self.text("Recherche en attente de l'époque suivante", SIDEX + 12, y0 + 140, MUT, self.fs)
        for sl in self.card_sl:
            sl.draw(self)
        y0 = 3 * CARD_H + 2
        self.text('DIPLOMATIE', SIDEX + 12, y0, ACC, self.fs)
        self.diplo = []
        for n, (a, b) in enumerate(((0, 1), (0, 2), (1, 2))):
            y = y0 + 14 + n * 28
            ca, cb = sim.civs[a], sim.civs[b]
            self.text(ca.name, SIDEX + 12, y, ca.color, self.fs)
            self.text('↔', SIDEX + 66, y, MUT, self.fs)
            self.text(cb.name, SIDEX + 82, y, cb.color, self.fs)
            r = sim.rel[a][b]
            pygame.draw.rect(self.scr, (45, 49, 57), (SIDEX + 12, y + 14, 130, 7))
            pygame.draw.line(self.scr, MUT, (SIDEX + 77, y + 12), (SIDEX + 77, y + 23))
            w = int(abs(r) / 100 * 65)
            pygame.draw.rect(self.scr, (90, 200, 110) if r >= 0 else (230, 80, 80), (SIDEX + 77 if r >= 0 else SIDEX + 77 - w, y + 14, w, 7))
            war = sim.at_war(a, b)
            self.text('GUERRE' if war else 'Paix', SIDEX + 150, y + 6, (255, 90, 90) if war else (130, 220, 140), self.fs)
            for k, (lab, fn) in enumerate((('Guerre', lambda a=a, b=b: sim.declare_war(a, b)), ('Paix', lambda a=a, b=b: sim.make_peace(a, b)),
                                           ('+Amitié', lambda a=a, b=b: sim.add_rel(a, b, 20)))):
                self.diplo.append(Button((SIDEX + 200 + k * 64, y, 60, 24), lab, fn))
        for bt in self.diplo:
            bt.draw(self, bt.rect.collidepoint(mouse))
        y0 = 3 * CARD_H + 100
        pygame.draw.line(self.scr, LINE, (SIDEX + 8, y0), (SIDEX + 392, y0))
        self.text('PARAMÈTRES DU MONDE (effet immédiat)', SIDEX + 12, y0 + 2, ACC, self.fs)
        for sl in self.world_sl:
            sl.draw(self)
        self.draw_inspector(3 * CARD_H + 198)

    def draw_inspector(self, y0):
        sim = self.sim
        pygame.draw.line(self.scr, LINE, (SIDEX + 8, y0 - 2), (SIDEX + 392, y0 - 2))
        a = self.picked
        x0 = SIDEX + 12
        if a is not None and a.dead:
            self.text('%s est mort(e) (%s).' % (a.name, a.why), x0, y0 + 4, (255, 120, 120))
            return
        if a is not None:
            c = sim.civs[a.civ]
            self.text('%s' % a.name, x0, y0, c.color, self.fb)
            self.text('%s%s · %s · %d ans' % (a.title + ' · ' if a.title else '', c.name, 'enfant' if a.age < CHILD else a.role, a.age // 50), x0 + 110, y0 + 3, MUT, self.fs)
            items = [('Travail', a.tr['travail']), ('Courage', a.tr['courage']), ('Social', a.tr['social']), ('Curiosité', a.tr['curio'])]
            for k, (lab, v) in enumerate(items):
                self.text(lab, x0, y0 + 24 + k * 12, MUT, self.fs)
                self.bar(x0 + 58, y0 + 27 + k * 12, 70, 6, v, (150, 180, 255))
            needs = [('Santé', a.hp / 100, (230, 90, 90)), ('Faim', a.hunger / 100, RCOL['food']), ('Soif', a.thirst / 100, RCOL['water']),
                     ('Énergie', a.energy / 100, (200, 200, 120)), ('Humeur', a.mood / 100, (240, 200, 80))]
            for k, (lab, v, col) in enumerate(needs):
                self.text(lab, x0 + 140, y0 + 24 + k * 12, MUT, self.fs)
                self.bar(x0 + 190, y0 + 27 + k * 12, 70, 6, v, col)
            fr = sorted(a.friends.items(), key=lambda kv: -kv[1])[:3]
            names = [sim.byid[i].name for i, _ in fr if i in sim.byid]
            self.text('Amis : ' + (', '.join(names) if names else '—'), x0 + 268, y0 + 24, MUT, self.fs)
            self.text('Activité : %s' % a.act, x0 + 268, y0 + 38, MUT, self.fs)
            self.text('Victimes : %d' % a.kills, x0 + 268, y0 + 52, MUT, self.fs)
            yy = y0 + 88
            for k, (yr, th) in enumerate(a.thoughts[:5]):
                col = TX if k == 0 else MUT
                for ln in self.wrap(('« %s »' % th) if k == 0 else th, self.fs, 366)[:2]:
                    self.text(ln, x0, yy, col, self.fs)
                    yy += 13
                    if yy > y0 + 168:
                        return
        else:
            if self.tip:
                self.text(self.tip, x0, y0 + 4, TX, self.fs)
            self.text('Clic droit sur un villageois : voir ses pensées.', x0, y0 + 24, MUT, self.fs)
            if self.hover_tile:
                x, y = self.hover_tile
                i = y * W + x
                lines = ['Tuile (%d,%d) · %s · %s' % (x, y, BIOMES[sim.biome[i]], TNAME[sim.terr[i]])]
                res = [('nourriture', sim.food[i]), ('bois', sim.wood[i]), ('pierre', sim.stone[i]), ('métal', sim.metal[i])]
                res = ['%s %d' % (n, v) for n, v in res if v >= 1]
                lines.append('Ressources : ' + (', '.join(res) if res else '—') + (' · eau' if sim.water[i] else ''))
                if sim.owner[i] >= 0:
                    lines.append('Territoire : %s' % sim.civs[sim.owner[i]].name)
                if i in sim.fire:
                    lines.append('EN FEU')
                b = sim.bld[i]
                if b:
                    lines.append('Bâtiment : %s (%s)%s' % ('Capitale' if b.type == 'town' else BDEF[b.type][0], sim.civs[b.civ].name, '' if b.done else ' — chantier'))
                for k, ln in enumerate(lines):
                    self.text(ln, x0, y0 + 46 + k * 14, MUT, self.fs)
            self.text('Molette : zoom · glisser (Observer) / WASD : déplacer · F : suivre', x0, y0 + 118, (90, 96, 108), self.fs)
            self.text('Espace : pause · Tab : civ. suivante · N : noms · F11 : plein écran', x0, y0 + 132, (90, 96, 108), self.fs)

    def draw_bottom(self):
        sim = self.sim
        y0 = VIEW.bottom
        pygame.draw.rect(self.scr, PANEL, (0, y0, SIDEX, WIN_H - y0))
        self.text('JOURNAL', 10, y0 + 4, ACC, self.fs)
        y = y0 + 20
        for yr, msg, col in sim.log[:8]:
            self.text(str(yr), 10, y, MUT, self.fs)
            self.text(msg, 52, y, col, self.fs)
            y += 14
        gx, gy, gw, gh = 860, y0 + 22, 420, 118
        self.text('POPULATION', gx, y0 + 4, ACC, self.fs)
        pygame.draw.rect(self.scr, (24, 26, 31), (gx, gy, gw, gh))
        mx = max([5] + [max(h) if h else 0 for h in sim.hist])
        for i, h in enumerate(sim.hist):
            if len(h) > 1:
                n = len(h)
                pts = [(gx + k * gw / max(n - 1, 1), gy + gh - 4 - v / mx * (gh - 10)) for k, v in enumerate(h)]
                pygame.draw.lines(self.scr, sim.civs[i].color, False, pts, 2)
            self.text('%s %d' % (sim.civs[i].name, sim.civs[i].pop), gx + 6 + i * 120, gy + 3, sim.civs[i].color, self.fs)
        self.text('%d tick/s · %d habitants · %d phénomènes météo' % (self.tps, sum(c.pop for c in sim.civs), len(sim.wx)), 10, WIN_H - 16, (90, 96, 108), self.fs)

    def draw_minimap(self):
        r = self.minimap_rect()
        if self.mini is None or time.time() - self.mini_t > 1.0:
            self.mini = pygame.transform.smoothscale(self.gfx.world, (240, 150))
            self.mini_t = time.time()
        self.scr.blit(self.mini, r.topleft)
        pygame.draw.rect(self.scr, (200, 200, 210), r, 1)
        v = self.view
        vx, vy = v['x'] / TS / W * 240, v['y'] / TS / H * 150
        vw, vh = VIEW.w / v['z'] / TS / W * 240, VIEW.h / v['z'] / TS / H * 150
        pygame.draw.rect(self.scr, (255, 255, 255), (r.x + vx, r.y + vy, vw, vh), 1)
        for c in self.sim.civs:
            pygame.draw.circle(self.scr, c.color, (r.x + c.cx / W * 240, r.y + c.cy / H * 150), 3)
        for w in self.sim.wx:
            pygame.draw.circle(self.scr, (255, 255, 255), (r.x + w.x / W * 240, r.y + w.y / H * 150), 2, 1)

    def draw_bubbles(self):
        sim = self.sim
        ox, oy, tz = self.xf
        shown = []
        if self.picked and not self.picked.dead:
            shown.append(self.picked)
        t = self.tile_at(pygame.mouse.get_pos())
        if t:
            for c in sim.civs:
                for a in sim.near_agents(c.id, t[0], t[1], 1):
                    if abs(a.x - t[0]) <= 1 and abs(a.y - t[1]) <= 1 and a not in shown and a.state != 'sleep':
                        shown.append(a)
                        break
        if self.names and self.view['z'] >= 2.4:
            for c in sim.civs:
                for a in c.agents[:200]:
                    sx, sy = ox + a.x * tz, oy + a.y * tz
                    if VIEW.collidepoint(sx, sy) and a not in shown and len(shown) < 12 and a.thought and a.state != 'sleep':
                        shown.append(a)
        for a in shown[:12]:
            if not a.thought:
                continue
            sx, sy = ox + a.x * tz + tz / 2, oy + a.y * tz - 4
            lines = self.wrap(a.thought, self.fs, 200)[:3]
            wd = max(self.fs.size(l)[0] for l in lines) + 12
            hh = len(lines) * 13 + 8
            r = pygame.Rect(0, 0, wd, hh)
            r.midbottom = (sx, sy)
            r.clamp_ip(VIEW)
            pygame.draw.rect(self.scr, (252, 250, 240), r, border_radius=6)
            pygame.draw.rect(self.scr, sim.civs[a.civ].color, r, 2, border_radius=6)
            pygame.draw.polygon(self.scr, (252, 250, 240), [(sx - 4, r.bottom - 1), (sx + 4, r.bottom - 1), (sx, r.bottom + 5)])
            for k, l in enumerate(lines):
                self.text(l, r.x + 6, r.y + 4 + k * 13, (30, 30, 40), self.fs)

    # ───────── entrées ─────────
    def handle(self, e):
        if e.type == pygame.QUIT:
            return False
        if e.type == pygame.KEYDOWN:
            if e.key == pygame.K_ESCAPE:
                return False
            if e.key == pygame.K_SPACE:
                self.toggle_pause()
            elif e.key == pygame.K_TAB:
                self.sel = (self.sel + 1) % 3
            elif e.key == pygame.K_f:
                self.follow = not self.follow
            elif e.key == pygame.K_n:
                self.names = not self.names
            elif e.key == pygame.K_F11:
                pygame.display.toggle_fullscreen()
            elif pygame.K_1 <= e.key <= pygame.K_6:
                self.set_speed(SPEEDS[e.key - pygame.K_1][0])
        elif e.type == pygame.MOUSEWHEEL:
            pos = pygame.mouse.get_pos()
            if VIEW.collidepoint(pos):
                self.zoom_at(pos, 1.15 if e.y > 0 else 1 / 1.15)
        elif e.type == pygame.MOUSEBUTTONDOWN:
            self.click(e)
        elif e.type == pygame.MOUSEBUTTONUP:
            self.drag = None
            self.painting = False
            self.panning = None
        elif e.type == pygame.MOUSEMOTION:
            self.hover_tile = self.tile_at(e.pos)
            if self.drag:
                self.drag.set_from(e.pos[0])
            elif self.panning:
                v = self.view
                v['x'] -= e.rel[0] / v['z']
                v['y'] -= e.rel[1] / v['z']
                self.follow = False
            elif self.painting and self.hover_tile:
                self.apply(self.hover_tile, False)
            elif pygame.mouse.get_pressed()[0] and self.minimap_rect().collidepoint(e.pos):
                self.mini_click(e.pos)
        return True

    def mini_click(self, pos):
        r = self.minimap_rect()
        self.center_on((pos[0] - r.x) / 240 * W, (pos[1] - r.y) / 150 * H)
        self.follow = False

    def stock_row(self, pos):
        if pos[0] < SIDEX or pos[1] >= 3 * CARD_H:
            return None
        i = pos[1] // CARD_H
        for n, r in enumerate(RES):
            if pygame.Rect(SIDEX + 80, i * CARD_H + 55 + n * 11 - 2, 232, 12).collidepoint(pos):
                return self.sim.civs[i], r
        return None

    def click(self, e):
        pos = e.pos
        if e.button == 3:
            sr = self.stock_row(pos)
            if sr:
                c, r = sr
                c.stock[r] = max(0, c.stock[r] - 10)
                return
            t = self.tile_at(pos)
            if t:
                self.pick(*t)
            return
        if e.button == 2:
            self.panning = True
            return
        if e.button != 1:
            return
        for b in self.buttons + self.power_btns + self.diplo:
            if b.rect.collidepoint(pos):
                b.cb()
                return
        for sl in self.all_sl:
            if sl.rect.inflate(10, 14).collidepoint(pos):
                self.drag = sl
                sl.set_from(pos[0])
                return
        if pos[0] >= SIDEX:
            if pos[1] < 3 * CARD_H:
                i = pos[1] // CARD_H
                self.sel = i
                c = self.sim.civs[i]
                y0 = i * CARD_H
                if not c.alive:
                    self.sim.refound(c)
                    return
                if pygame.Rect(SIDEX + 112, y0 + 10, 100, 20).collidepoint(pos):
                    gl = list(GOV)
                    self.sim.revolution(c, gl[(gl.index(c.gov) + 1) % 3], True)
                    return
                sr = self.stock_row(pos)
                if sr:
                    c, r = sr
                    c.stock[r] = min(self.sim.stock_cap(c), c.stock[r] + 10)
                    return
                for k, key in enumerate(TECH):
                    rect = pygame.Rect(SIDEX + 10 + (k % 10) * 38, y0 + 113 + (k // 10) * 13, 36, 12)
                    if rect.collidepoint(pos) and key not in c.tech and all(q in c.tech for q in TECH[key][2]):
                        c.research, c.rp = key, 0
                        return
            return
        if self.minimap_rect().collidepoint(pos):
            self.mini_click(pos)
            return
        t = self.tile_at(pos)
        if t:
            if self.power == 'look':
                self.pick(*t)
                if self.picked is None:
                    self.panning = True
            else:
                self.painting = True
                self.apply(t, True)

    def keys_move(self, dt):
        k = pygame.key.get_pressed()
        v = self.view
        sp = 420 * dt / v['z']
        if k[pygame.K_a] or k[pygame.K_LEFT]:
            v['x'] -= sp
            self.follow = False
        if k[pygame.K_d] or k[pygame.K_RIGHT]:
            v['x'] += sp
            self.follow = False
        if k[pygame.K_w] or k[pygame.K_UP]:
            v['y'] -= sp
            self.follow = False
        if k[pygame.K_s] or k[pygame.K_DOWN]:
            v['y'] += sp
            self.follow = False

    def step_sim(self, dt):
        sim = self.sim
        t0 = time.time()
        n = 0
        if not self.paused:
            self.acc += dt * 10 * self.speed
            want = min(int(self.acc), 800)
            self.acc = min(self.acc - int(self.acc), 1.0)
            while n < want and time.time() - t0 < .016:
                sim.tick()
                n += 1
            for f in sim.fx[:]:
                f[3] -= 1
                if f[3] <= 0:
                    sim.fx.remove(f)
            for cv in sim.carav[:]:
                cv[2] += .004 * n
                if cv[2] >= 1:
                    sim.carav.remove(cv)
        self.tps = int(n / max(dt, .001)) if n else 0

    def render(self, headless=False):
        sim = self.sim
        self.gfx.flush(sim)
        if self.follow and self.picked and not self.picked.dead:
            self.center_on(self.picked.x, self.picked.y)
        alpha = min(1.0, self.acc) if self.speed <= 5 else 1.0
        shake = sim.shake
        if shake:
            sim.shake -= 1
        self.scr.fill(BG)
        v = self.view
        if shake:
            v = dict(v)
            v['x'] += random.uniform(-3, 3) * shake / 10
            v['y'] += random.uniform(-3, 3) * shake / 10
        self.xf = self.gfx.draw_scene(self.scr, VIEW, sim, v, alpha, pygame.time.get_ticks(), self.names)
        if v is not self.view:
            self.view['x'], self.view['y'] = self.view['x'], self.view['y']
        self.draw_bubbles()
        self.draw_minimap()
        self.draw_top()
        self.draw_bottom()
        self.draw_cards()
        msg, left = self.toast
        if left > 0:
            self.toast = (msg, left - 1)
            t = self.fb.render(msg, True, (255, 200, 120))
            r = t.get_rect(center=(VIEW.centerx, VIEW.y + 30)).inflate(24, 12)
            pygame.draw.rect(self.scr, (40, 30, 20), r, border_radius=6)
            self.scr.blit(t, t.get_rect(center=r.center))
        if sim.reached and self.banner < 500:
            self.banner += 1
            t = self.fl.render('ÉPOQUE ACTUELLE — %d' % END_YEAR, True, (255, 230, 120))
            r = t.get_rect(center=(VIEW.centerx, VIEW.centery - 120)).inflate(40, 20)
            pygame.draw.rect(self.scr, (30, 26, 14), r, border_radius=8)
            pygame.draw.rect(self.scr, ACC, r, 2, border_radius=8)
            self.scr.blit(t, t.get_rect(center=r.center))
        if self.paused:
            t = self.fl.render('PAUSE', True, (255, 255, 255))
            self.scr.blit(t, t.get_rect(center=(VIEW.centerx, VIEW.centery)))

    def run(self):
        running = True
        while running:
            dt = self.clock.tick(60) / 1000
            for e in pygame.event.get():
                running = self.handle(e) and running
            self.keys_move(dt)
            self.step_sim(dt)
            self.render()
            pygame.display.flip()
        pygame.quit()


def main():
    if '--headless' in sys.argv:
        os.environ['SDL_VIDEODRIVER'] = 'dummy'
        i0 = sys.argv.index('--headless')
        n, out = int(sys.argv[i0 + 1]), sys.argv[i0 + 2]
        random.seed(2)
        ui = UI()
        for _ in range(n):
            ui.sim.tick()
        for p in sys.argv[i0 + 3:]:
            kind, x, y = p.split(',')
            ui.sim.power(kind, int(x), int(y), ui.sim.civs[0], 3)
        for _ in range(30):
            ui.sim.tick()
        ui.picked = ui.sim.civs[1].agents[0]
        ui.view['sel'] = ui.picked
        ui.view['z'] = float(os.environ.get('ZOOM', 3))
        ui.center_on(ui.picked.x, ui.picked.y)
        ui.render()
        ui.render()
        pygame.image.save(ui.scr, out)
        return
    UI().run()


if __name__ == '__main__':
    main()
