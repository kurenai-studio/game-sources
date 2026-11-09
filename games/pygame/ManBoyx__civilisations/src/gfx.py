"""Rendu pixel-art : tuiles, sprites procéduraux, météo, effets."""
import math
import random

import pygame

from sim import (W, H, N, DEEP, WATER, SAND, GRASS, FOREST, ROCK, SNOW, LAVA, GOV, CHILD)

TS = 8   # taille d'une tuile en pixels du monde
NV = 8   # variantes par terrain
BASE = {DEEP: (24, 66, 134), WATER: (48, 124, 204), SAND: (228, 200, 130), GRASS: (100, 168, 72),
        FOREST: (78, 144, 60), ROCK: (130, 130, 140), SNOW: (238, 244, 252), LAVA: (232, 84, 24)}
AVG = dict(BASE)
AVG[FOREST] = (50, 110, 50)


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c)


def mk(w=8, h=8):
    return pygame.Surface((w, h), pygame.SRCALPHA)


class Gfx:
    def __init__(self, sim):
        self.rng = random.Random(5)
        self.cache = {}
        self.build_tiles()
        self.build_static()
        self.world = pygame.Surface((W * TS, H * TS))
        self.tint = {}
        self.sprite_cache = {}
        self.tcache = {}
        self.setup_civ_tints(sim)
        self.full(sim)

    # ───────── terrain ─────────
    def build_tiles(self):
        r = self.rng
        self.vars = {}
        for t, base in BASE.items():
            lst = []
            for v in range(NV):
                s = pygame.Surface((TS, TS))
                s.fill(base)
                for _ in range(14):
                    x, y = r.randrange(TS), r.randrange(TS)
                    k = r.choice((.92, .96, 1.05, 1.08))
                    s.set_at((x, y), shade(base, k))
                if t == GRASS or t == FOREST:
                    for _ in range(2):
                        x, y = r.randrange(1, 7), r.randrange(0, 6)
                        s.set_at((x, y), shade(base, 1.22))
                        s.set_at((x, y + 1), shade(base, .82))
                elif t == SAND:
                    for _ in range(3):
                        s.set_at((r.randrange(8), r.randrange(8)), (200, 170, 100))
                elif t in (WATER, DEEP):
                    for _ in range(2):
                        x, y = r.randrange(0, 6), r.randrange(8)
                        s.set_at((x, y), shade(base, 1.25))
                        s.set_at((x + 1, y), shade(base, 1.25))
                elif t == ROCK:
                    for _ in range(3):
                        s.set_at((r.randrange(8), r.randrange(8)), (96, 96, 108))
                elif t == LAVA:
                    for _ in range(6):
                        s.set_at((r.randrange(8), r.randrange(8)), r.choice([(255, 210, 60), (255, 150, 30), (170, 40, 10)]))
                lst.append(s)
            self.vars[t] = lst
        self.foam = {}
        for k, rect in enumerate(((0, 0, 8, 1), (0, 7, 8, 1), (0, 0, 1, 8), (7, 0, 1, 8))):
            s = mk()
            s.fill((235, 245, 255, 150), rect)
            self.foam[k] = s
        self.burn = mk()
        for _ in range(26):
            self.burn.set_at((r.randrange(8), r.randrange(8)), (28, 24, 22, 190))

    def setup_civ_tints(self, sim):
        self.tint = {}
        for c in sim.civs:
            t = mk()
            t.fill((*c.color, 34))
            edges = []
            for rect in ((0, 0, 8, 1), (0, 7, 8, 1), (0, 0, 1, 8), (7, 0, 1, 8)):
                e = mk()
                e.fill((*c.color, 230), rect)
                edges.append(e)
            self.tint[c.id] = (t, edges)

    # ───────── sprites ─────────
    def build_static(self):
        S = {}
        # arbres
        s = mk()
        pygame.draw.polygon(s, (24, 84, 40), [(4, 0), (1, 4), (7, 4)])
        pygame.draw.polygon(s, (30, 104, 48), [(4, 2), (0, 7), (8, 7)])
        s.fill((88, 58, 30), (3, 6, 2, 2))
        S['pine'] = s
        s = mk()
        pygame.draw.circle(s, (40, 118, 44), (4, 3), 3)
        pygame.draw.circle(s, (62, 146, 56), (3, 2), 1)
        s.fill((92, 62, 34), (3, 5, 2, 3))
        S['oak'] = s
        s = mk()
        s.fill((130, 96, 52), (4, 3, 1, 5))
        for p in ((1, 2), (2, 1), (6, 2), (5, 1), (3, 1), (4, 0)):
            s.set_at(p, (60, 150, 50))
        S['palm'] = s
        s = mk()
        pygame.draw.circle(s, (60, 130, 50), (4, 5), 2)
        for p in ((3, 4), (5, 5), (4, 6)):
            s.set_at(p, (230, 60, 90))
        S['berry'] = s
        s = mk()
        s.fill((150, 150, 160), (1, 5, 3, 2))
        s.fill((120, 120, 130), (4, 6, 3, 2))
        S['rock'] = s
        s = mk()
        s.fill((120, 120, 132), (1, 4, 3, 3))
        for p in ((5, 5), (6, 3), (3, 2)):
            s.set_at(p, (255, 190, 60))
        s.fill((255, 190, 60), (5, 4, 2, 2))
        S['ore'] = s
        s = mk()
        pygame.draw.polygon(s, (104, 102, 114), [(0, 8), (4, 0), (8, 8)])
        pygame.draw.polygon(s, (140, 138, 150), [(4, 0), (0, 8), (3, 8)])
        S['peak'] = s
        s = mk()
        pygame.draw.polygon(s, (170, 176, 190), [(0, 8), (4, 0), (8, 8)])
        pygame.draw.polygon(s, (250, 252, 255), [(4, 0), (1, 6), (7, 6)])
        pygame.draw.polygon(s, (205, 215, 235), [(4, 0), (7, 6), (5, 6)])
        S['snowpeak'] = s
        # animaux
        s = mk()
        s.fill((150, 100, 56), (1, 3, 5, 3))
        s.fill((150, 100, 56), (6, 1, 1, 3))
        s.fill((100, 66, 36), (1, 6, 1, 2))
        s.fill((100, 66, 36), (5, 6, 1, 2))
        s.fill((226, 210, 180), (7, 1, 1, 1))
        s.set_at((6, 0), (236, 226, 190))
        S['deer'] = s
        s = mk()
        s.fill((110, 112, 124), (1, 3, 5, 3))
        s.fill((110, 112, 124), (6, 2, 2, 2))
        s.fill((70, 72, 84), (1, 6, 1, 2))
        s.fill((70, 72, 84), (5, 6, 1, 2))
        s.set_at((7, 1), (70, 72, 84))
        s.set_at((7, 2), (255, 70, 70))
        S['wolf'] = s
        # flammes (3 images)
        for f in range(3):
            s = mk()
            pygame.draw.polygon(s, (255, 90, 20), [(1, 8), (4, 1 + f), (7, 8)])
            pygame.draw.polygon(s, (255, 190, 40), [(2, 8), (4, 3 + f), (6, 8)])
            pygame.draw.polygon(s, (255, 250, 150), [(3, 8), (4, 5 + f), (5, 8)])
            S['flame%d' % f] = s
        s = mk()
        for p in range(0, 8, 2):
            s.fill((150, 110, 60, 220), (p, 6, 1, 2))
        s.fill((150, 110, 60, 220), (0, 2, 8, 1))
        s.fill((150, 110, 60, 220), (0, 6, 8, 1))
        S['scaffold'] = s
        self.S = S

    def building(self, typ, era, gov, col):
        key = ('b', typ, era, gov, col)
        if key in self.cache:
            return self.cache[key]
        s = mk()
        d = (30, 28, 30)
        if typ == 'house':
            wall = [(178, 134, 92), (206, 176, 136), (176, 96, 76), (196, 202, 214)][era]
            roof = [(150, 108, 50), (196, 74, 52), (110, 56, 50), (90, 100, 122)][era]
            if era == 3:
                s.fill(wall, (1, 0, 6, 8))
                for yy in (1, 3, 5):
                    s.fill((90, 140, 210), (2, yy, 1, 1))
                    s.fill((90, 140, 210), (4, yy, 1, 1))
                    s.fill((250, 230, 130), (5, yy, 1, 1))
                s.fill(roof, (1, 0, 6, 1))
            else:
                pygame.draw.polygon(s, roof, [(0, 4), (4, 0), (8, 4)])
                s.fill(wall, (1, 4, 6, 4))
                s.fill(d, (3, 5, 2, 3))
                if era == 2:
                    s.fill((90, 60, 56), (6, 0, 1, 3))
                    s.fill((170, 170, 180), (6, 0, 1, 1))
        elif typ == 'farm':
            s.fill((142, 104, 56), (0, 1, 8, 7))
            for yy in (2, 4, 6):
                s.fill((150, 200, 60) if era < 3 else (220, 200, 60), (1, yy, 6, 1))
            if era >= 2:
                s.fill((200, 40, 40), (6, 0, 2, 2))
        elif typ == 'well':
            s.fill((128, 128, 138), (1, 3, 6, 4))
            s.fill((56, 130, 214), (2, 4, 4, 2))
            s.fill((100, 70, 40), (1, 0, 1, 4))
            s.fill((100, 70, 40), (6, 0, 1, 4))
            s.fill((100, 70, 40), (1, 0, 6, 1))
            if era >= 2:
                s.fill((180, 190, 210), (3, 1, 2, 2))
        elif typ == 'sawmill':
            s.fill((124, 84, 44), (0, 3, 8, 5))
            s.fill((176, 128, 70), (1, 1, 6, 2))
            for xx in (1, 3, 5):
                s.fill((210, 170, 100), (xx, 5, 1, 2))
            if era >= 2:
                s.fill((90, 90, 100), (6, 0, 2, 3))
        elif typ == 'mine':
            pygame.draw.polygon(s, (86, 84, 96), [(0, 8), (1, 2), (7, 2), (8, 8)])
            s.fill((14, 12, 14), (3, 4, 3, 4))
            s.fill((120, 84, 40), (2, 3, 5, 1))
            if era >= 2:
                s.fill((255, 180, 40), (6, 1, 1, 1))
        elif typ == 'warehouse':
            wall = [(184, 160, 104), (176, 150, 100), (150, 90, 70), (170, 180, 190)][era]
            s.fill(wall, (0, 2, 8, 6))
            s.fill(shade(wall, .7), (0, 1, 8, 1))
            s.fill(d, (2, 4, 4, 4))
            s.fill(shade(wall, 1.2), (3, 5, 2, 3))
        elif typ == 'barracks':
            wall = [(126, 64, 56), (130, 120, 110), (140, 76, 66), (110, 126, 100)][era]
            s.fill(wall, (0, 3, 8, 5))
            s.fill(shade(wall, 1.2), (0, 2, 8, 1))
            s.fill((220, 220, 230), (6, 0, 1, 3))
            s.fill(col, (4, 0, 2, 2))
            s.fill(d, (3, 5, 2, 3))
            if era >= 3:
                s.fill((70, 90, 60), (0, 3, 8, 1))
        elif typ == 'academy':
            s.fill((220, 214, 200), (0, 3, 8, 5))
            pygame.draw.polygon(s, (190, 60, 60) if era < 3 else (80, 110, 170), [(0, 3), (4, 0), (8, 3)])
            for xx in (1, 3, 5):
                s.fill((130, 120, 110), (xx, 4, 1, 4))
            s.fill(d, (3, 6, 2, 2))
        elif typ == 'factory':
            s.fill((150, 80, 66) if era < 3 else (150, 156, 168), (0, 3, 8, 5))
            s.fill((80, 80, 90), (1, 0, 1, 3))
            s.fill((80, 80, 90), (5, 0, 1, 3))
            s.fill((190, 190, 200), (1, 0, 1, 1))
            s.fill((250, 220, 110), (2, 5, 1, 1))
            s.fill((250, 220, 110), (4, 5, 1, 1))
            s.fill((250, 220, 110), (6, 5, 1, 1))
        elif typ == 'govt':
            if gov == 'monarchie':
                s.fill((176, 170, 160), (0, 3, 8, 5))
                for xx in (0, 3, 6):
                    s.fill((176, 170, 160), (xx, 2, 2, 1))
                s.fill((176, 170, 160), (1, 0, 2, 3))
                s.fill((176, 170, 160), (5, 0, 2, 3))
                s.fill(col, (3, 3, 2, 3))
                s.fill((255, 215, 60), (2, 0, 1, 1))
                s.fill((255, 215, 60), (6, 0, 1, 1))
            elif gov == 'republique':
                s.fill((236, 236, 240), (0, 6, 8, 2))
                pygame.draw.polygon(s, (226, 226, 232), [(0, 3), (4, 0), (8, 3)])
                for xx in (1, 3, 5):
                    s.fill((250, 250, 255), (xx, 3, 1, 3))
                s.fill(col, (3, 1, 2, 1))
            else:
                s.fill((60, 56, 64), (0, 2, 8, 6))
                s.fill((90, 86, 96), (0, 1, 8, 1))
                s.fill((210, 40, 40), (3, 3, 2, 3))
                s.fill((255, 215, 60), (3, 0, 2, 1))
                s.fill(d, (1, 5, 1, 3))
                s.fill(d, (6, 5, 1, 3))
        else:
            s.fill((150, 150, 150), (1, 1, 6, 6))
        self.cache[key] = s
        return s

    def town(self, civ_id, era, col):
        key = ('t', civ_id, era, col)
        if key in self.cache:
            return self.cache[key]
        s = mk(24, 24)
        d = (30, 28, 30)
        if era == 0:  # château
            st = (150, 146, 140)
            s.fill(st, (2, 8, 20, 14))
            for xx in (2, 8, 14, 20):
                s.fill(st, (xx, 6, 3, 2))
            for (tx, ty) in ((0, 3), (19, 3)):
                s.fill(shade(st, .85), (tx, ty, 5, 19))
                s.fill(st, (tx, ty - 2, 1, 2))
                s.fill(st, (tx + 2, ty - 2, 1, 2))
                s.fill(st, (tx + 4, ty - 2, 1, 2))
            s.fill(shade(st, 1.1), (9, 2, 6, 6))
            s.fill(col, (11, 0, 2, 5))
            s.fill(col, (13, 1, 4, 3))
            s.fill(d, (10, 14, 4, 8))
            for p in ((3, 10), (3, 14), (20, 10), (20, 14)):
                s.fill(d, (p[0], p[1], 1, 2))
        elif era == 1:  # palais
            s.fill((226, 218, 196), (1, 10, 22, 12))
            s.fill((190, 70, 60), (1, 8, 22, 2))
            pygame.draw.polygon(s, col, [(6, 10), (12, 1), (18, 10)])
            s.fill((255, 215, 70), (12, 0, 1, 2))
            for xx in range(3, 22, 4):
                s.fill((100, 120, 160), (xx, 13, 2, 3))
            s.fill(d, (10, 16, 4, 6))
        elif era == 2:  # grande halle industrielle
            s.fill((150, 80, 66), (0, 10, 24, 12))
            s.fill((110, 56, 50), (0, 8, 24, 2))
            for xx in (3, 11, 19):
                s.fill((84, 80, 90), (xx, 0, 2, 9))
                s.fill((200, 200, 210), (xx, 0, 2, 1))
            for xx in range(2, 22, 5):
                s.fill((250, 220, 110), (xx, 13, 3, 3))
            s.fill(col, (9, 9, 6, 2))
            s.fill(d, (10, 17, 4, 5))
        else:  # gratte-ciel
            for (bx, bw, bh) in ((0, 7, 16), (8, 8, 22), (17, 7, 13)):
                s.fill((126, 140, 160), (bx, 24 - bh, bw, bh))
                for yy in range(24 - bh + 2, 23, 3):
                    for xx in range(bx + 1, bx + bw - 1, 2):
                        s.set_at((xx, yy), (250, 230, 130) if (xx + yy) % 3 else (150, 200, 250))
            s.fill(col, (11, 0, 2, 3))
        pygame.draw.rect(s, (255, 255, 255, 60), (0, 0, 24, 24), 1)
        self.cache[key] = s
        return s

    def person(self, col, era, role, rank, leader, child, frame, gov):
        key = ('p', col, era, role, rank, leader, child, frame, gov)
        if key in self.cache:
            return self.cache[key]
        s = mk()
        skin = (238, 198, 152)
        leg = (52, 42, 40)
        if frame == 0:
            s.fill(leg, (2, 6, 1, 2))
            s.fill(leg, (5, 6, 1, 2))
        else:
            s.fill(leg, (3, 6, 1, 2))
            s.fill(leg, (4, 6, 1, 2))
        body = col
        if era >= 2 and role == 'worker':
            body = shade(col, .85)
        s.fill(body, (2, 3, 4, 3))
        s.fill(shade(body, .65), (2, 5, 4, 1))
        s.fill(skin, (3, 1, 2, 2))
        s.fill((72, 46, 30), (3, 0, 2, 1))
        if role == 'soldier':
            hel = [(160, 160, 172), (34, 34, 44), (70, 90, 62), (66, 84, 56)][era]
            s.fill(hel, (2, 0, 4, 2) if era != 1 else (2, 0, 4, 1))
            s.fill(skin, (3, 2, 2, 1))
            if era == 0:
                s.fill((220, 224, 236), (6, 1, 1, 5))
                s.fill((120, 70, 40), (6, 6, 1, 1))
                s.fill((200, 200, 210), (1, 3, 1, 3))
            elif era == 1:
                s.fill((110, 78, 44), (6, 2, 1, 5))
                s.fill((200, 200, 200), (6, 1, 1, 1))
                s.fill((250, 250, 250), (2, 3, 4, 1))
            elif era == 2:
                s.fill((100, 70, 40), (6, 2, 1, 5))
                s.fill((210, 210, 215), (6, 1, 1, 1))
                s.fill((200, 200, 220), (3, 3, 2, 1))
            else:
                s.fill((30, 30, 34), (5, 3, 3, 1))
                s.fill((30, 30, 34), (6, 2, 1, 2))
            if rank >= 1:
                s.fill((255, 215, 60), (2, 3, 1, 1))
            if rank >= 2:
                s.fill((230, 50, 50), (4, 0, 1, 1))
                s.fill((255, 215, 60), (1, 3, 1, 3))
        if leader:
            if gov == 'monarchie':
                s.fill((255, 215, 60), (3, 0, 2, 1))
                s.set_at((3, 0), (255, 245, 150))
                s.fill((170, 30, 50), (1, 3, 1, 4))
                s.fill((170, 30, 50), (6, 3, 1, 4))
            elif gov == 'republique':
                s.fill((250, 250, 255), (2, 3, 1, 3))
                s.fill((60, 60, 90), (3, 0, 2, 1))
                s.fill((255, 255, 255), (5, 3, 1, 3))
            else:
                s.fill((30, 30, 36), (2, 0, 4, 1))
                s.fill((200, 30, 30), (2, 3, 4, 1))
                s.fill((255, 215, 60), (2, 4, 1, 1))
                s.fill((255, 215, 60), (5, 4, 1, 1))
        if child:
            sm = pygame.transform.scale(s, (5, 5))
            s = mk()
            s.blit(sm, (1, 3))
        self.cache[key] = s
        return s

    def scaled(self, surf, key, size):
        k = (key, size)
        s = self.sprite_cache.get(k)
        if s is None:
            s = pygame.transform.scale(surf, (size, size)) if surf.get_width() == surf.get_height() else surf
            self.sprite_cache[k] = s
            if len(self.sprite_cache) > 3000:
                self.sprite_cache.clear()
        return s

    # ───────── monde ─────────
    def full(self, sim):
        for i in range(N):
            self.draw_tile(sim, i)
        self.towns(sim)
        sim.dirty.clear()

    def flush(self, sim):
        if not sim.dirty:
            return
        d = set(sim.dirty)
        if len(d) < 4000:
            for i in list(d):
                for j in (i - 1, i + 1, i - W, i + W):
                    if 0 <= j < N:
                        d.add(j)
        for i in d:
            self.draw_tile(sim, i)
        sim.dirty.clear()
        self.towns(sim)

    def towns(self, sim):
        for c in sim.civs:
            if c.alive:
                self.world.blit(self.town(c.id, c.era, c.color), ((c.cx - 1) * TS, (c.cy - 1) * TS))

    def draw_tile(self, sim, i):
        x, y = i % W, i // W
        t = sim.terr[i]
        px, py = x * TS, y * TS
        w = self.world
        v = ((x * 73856093) ^ (y * 19349663)) % NV
        tt = FOREST if (t == FOREST) else t
        w.blit(self.vars[tt][v], (px, py))
        if t == WATER and 0 < x < W - 1 and 0 < y < H - 1:
            for k, j in enumerate((i - W, i + W, i - 1, i + 1)):
                if sim.terr[j] not in (WATER, DEEP):
                    w.blit(self.foam[k], (px, py))
        if sim.burnt[i] and t not in (WATER, DEEP, LAVA):
            w.blit(self.burn, (px, py))
        o = sim.owner[i]
        if o >= 0 and t not in (WATER, DEEP):
            tn, edges = self.tint[o]
            w.blit(tn, (px, py))
            if 0 < x < W - 1 and 0 < y < H - 1:
                for k, j in enumerate((i - W, i + W, i - 1, i + 1)):
                    if sim.owner[j] != o:
                        w.blit(edges[k], (px, py))
        if t in (WATER, DEEP, LAVA):
            return
        S = self.S
        if t == ROCK and sim.wood[i] < 3 and sim.stone[i] >= 1 and (x * 3 + y * 5) % 3 == 0:
            w.blit(S['peak'], (px, py))
        elif t == SNOW and (x * 3 + y * 5) % 2 == 0:
            w.blit(S['snowpeak'], (px, py))
        if sim.wood[i] >= 3:
            b = sim.biome[i]
            w.blit(S['palm'] if b == 0 else S['pine'] if (b == 2 or (x + y) % 3 == 0) else S['oak'], (px, py))
        elif sim.stone[i] >= 1 and t not in (ROCK, SNOW):
            w.blit(S['rock'], (px, py))
        if sim.food[i] >= 1:
            w.blit(S['berry'], (px, py))
        if sim.metal[i] >= 1:
            w.blit(S['ore'], (px, py))
        b = sim.bld[i]
        if b and b.type != 'town' and b.done:
            c = sim.civs[b.civ]
            w.blit(self.building(b.type, c.era, c.gov, c.color), (px, py))

    # ───────── scène ─────────
    def draw_scene(self, scr, rect, sim, view, alpha, tms, show_names=False):
        z = view['z']
        sw, sh = int(rect.w / z) + 2, int(rect.h / z) + 2
        sx = int(clamp_(view['x'], 0, max(0, W * TS - sw)))
        sy = int(clamp_(view['y'], 0, max(0, H * TS - sh)))
        view['x'], view['y'] = sx, sy
        src = pygame.Rect(sx, sy, min(sw, W * TS - sx), min(sh, H * TS - sy))
        dw, dh = int(src.w * z), int(src.h * z)
        scr.set_clip(rect)
        scr.blit(pygame.transform.scale(self.world.subsurface(src), (dw, dh)), rect.topleft)
        ox, oy = rect.x - sx * z, rect.y - sy * z
        tz = TS * z
        ts = max(2, int(round(tz)))
        self.tms = tms
        self.vis = (sx / TS - 1, sy / TS - 1, (sx + src.w) / TS + 1, (sy + src.h) / TS + 1)

        def P(x, y):
            return ox + x * tz, oy + y * tz

        def vis(x, y):
            v = self.vis
            return v[0] <= x <= v[2] and v[1] <= y <= v[3]

        S = self.S
        fr = int(tms / 140)
        # eau animée (scintillement)
        for k in range(int(40 * z)):
            gx, gy = random.randint(int(self.vis[0]), int(self.vis[2])), random.randint(int(self.vis[1]), int(self.vis[3]))
            if 0 <= gx < W and 0 <= gy < H and sim.terr[gy * W + gx] in (WATER, DEEP):
                px, py = P(gx + random.random(), gy + random.random())
                pygame.draw.rect(scr, (210, 235, 255), (px, py, max(1, z), max(1, z)))
        # bâtiments en construction
        for c in sim.civs:
            for b in c.buildings:
                if not b.done and vis(b.x, b.y):
                    px, py = P(b.x, b.y)
                    scr.blit(self.scaled(S['scaffold'], 'scaf', ts), (px, py))
        # lave animée
        for i in list(sim.lava)[:400]:
            x, y = i % W, i // W
            if vis(x, y) and random.random() < .3:
                px, py = P(x + random.random(), y + random.random())
                pygame.draw.rect(scr, (255, 230, 90), (px, py, max(1, z), max(1, z)))
        # feu
        for i in sim.fire:
            x, y = i % W, i // W
            if vis(x, y):
                px, py = P(x, y - .3)
                scr.blit(self.scaled(S['flame%d' % ((fr + i) % 3)], 'fl%d' % ((fr + i) % 3), ts), (px, py))
        # animaux
        for an in sim.animals:
            if an.dead or not vis(an.x, an.y):
                continue
            wx_, wy_ = an.ox + (an.x - an.ox) * alpha, an.oy + (an.y - an.oy) * alpha
            px, py = P(wx_, wy_)
            scr.blit(self.scaled(S[an.kind], an.kind, ts), (px, py))
        # personnages
        sel = view.get('sel')
        for c in sim.civs:
            era, gov, col = c.era, c.gov, c.color
            for a in c.agents:
                if a.dead or not vis(a.x, a.y):
                    continue
                if a.state == 'sleep' and a is not sel:
                    continue
                wx_, wy_ = a.ox + (a.x - a.ox) * alpha, a.oy + (a.y - a.oy) * alpha
                px, py = P(wx_, wy_)
                if z < 1.3:
                    pygame.draw.rect(scr, (10, 10, 12), (px - 1, py - 1, 4, 4))
                    pygame.draw.rect(scr, (255, 215, 60) if a is c.leader else col, (px, py, 2, 2))
                else:
                    moving = a.state == 'move' and (a.ox != a.x or a.oy != a.y)
                    spr = self.person(col, era, a.role, a.rank, a is c.leader, a.age < CHILD, (fr + a.id) % 2 if moving else 0, gov)
                    scr.blit(self.scaled(spr, ('p', col, era, a.role, a.rank, a is c.leader, a.age < CHILD, (fr + a.id) % 2 if moving else 0, gov), ts), (px, py))
                    if a.carry:
                        pygame.draw.rect(scr, {'food': (230, 70, 90), 'water': (70, 150, 230), 'wood': (160, 105, 50),
                                               'stone': (170, 170, 180), 'metal': (245, 175, 60)}[a.carry[0]], (px + tz * .55, py - tz * .2, max(2, tz * .3), max(2, tz * .3)))
                if a is sel:
                    pygame.draw.circle(scr, (255, 255, 255), (px + tz / 2, py + tz / 2), max(6, tz * .8), 1)
                elif show_names and z >= 2.2:
                    t = self.font.render(a.name, True, (255, 255, 255))
                    scr.blit(t, (px + tz / 2 - t.get_width() / 2, py - 11))
        # caravanes
        for cv in sim.carav:
            x = cv[0].cx + (cv[1].cx - cv[0].cx) * cv[2]
            y = cv[0].cy + (cv[1].cy - cv[0].cy) * cv[2]
            px, py = P(x, y)
            pygame.draw.circle(scr, (255, 220, 120), (px + tz / 2, py + tz / 2), max(2, tz * .4))
            pygame.draw.circle(scr, (60, 40, 10), (px + tz / 2, py + tz / 2), max(2, tz * .4), 1)
        # météo (sous les effets)
        self.draw_weather(scr, rect, sim, P, tz, z)
        # effets
        for f in sim.fx:
            k, fx_, fy_, life = f[0], f[1], f[2], f[3]
            px, py = P(fx_ + .5, fy_ + .5)
            if k == 'bolt':
                pygame.draw.lines(scr, (255, 255, 210), False, [(px, rect.y), (px + 10 * z, py - 40 * z), (px - 6 * z, py - 18 * z), (px, py)], max(2, int(z * 1.4)))
                pygame.draw.circle(scr, (255, 255, 220), (px, py), 6 * z, 2)
            elif k == 'boom':
                rr = (40 - life) * .5 * z * 2
                pygame.draw.circle(scr, (255, 200, 80), (px, py), rr, max(2, int(life / 6)))
                pygame.draw.circle(scr, (255, 90, 30), (px, py), rr * .6)
            elif k == 'meteor':
                tt = life / 14
                pygame.draw.line(scr, (255, 170, 60), (px + 60 * tt * z, py - 120 * tt * z), (px, py), max(3, int(z * 2)))
                pygame.draw.circle(scr, (255, 240, 180), (px + 60 * tt * z * .08, py - 120 * tt * z * .08), max(3, 4 * z))
            elif k == 'shot':
                qx, qy = P(f[4] + .5, f[5] + .5)
                pygame.draw.line(scr, (255, 240, 150), (px, py), (qx, qy), 1)
            elif k == 'hit':
                pygame.draw.circle(scr, (255, 80, 80), (px, py), 5 * z, 1)
            elif k == 'bless':
                pygame.draw.circle(scr, (255, 245, 170), (px, py), (40 - life) * 1.6 * z, 2)
            elif k == 'smoke':
                for j in range(3):
                    pygame.draw.circle(scr, (70, 66, 70), (px + random.uniform(-10, 10) * z, py - (30 - life) * 2 * z - j * 6 * z), 5 * z)
            elif k == 'dust':
                pygame.draw.circle(scr, (180, 160, 130), (px, py), (25 - life) * .5 * z + 2, 1)
            elif k == 'crack':
                pygame.draw.line(scr, (30, 22, 18), (px, py), (px + 6 * z, py + 4 * z), 2)
        # nuit & saison
        dk = sim.dark()
        if dk > .02:
            ov = pygame.Surface(rect.size, pygame.SRCALPHA)
            ov.fill((8, 12, 48, int(125 * dk)))
            if dk > .3:
                for c in sim.civs:
                    px, py = P(c.cx + .5, c.cy + .5)
                    px -= rect.x
                    py -= rect.y
                    if -200 < px < rect.w + 200 and -200 < py < rect.h + 200:
                        for k, (rr, a_) in enumerate(((14, 70), (10, 40), (6, 0))):
                            if c.era >= 1 or k == 2:
                                pygame.draw.circle(ov, (8, 12, 48, int(a_ * dk)), (px, py), rr * z + 6)
                for i in list(sim.lava)[:200]:
                    px, py = P(i % W + .5, i // W + .5)
                    pygame.draw.circle(ov, (0, 0, 0, 40), (px - rect.x, py - rect.y), 4 * z)
            scr.blit(ov, rect.topleft)
        s = sim.season()
        tint = [None, (255, 220, 100, 14), (230, 120, 40, 22), (210, 230, 255, 50)][s]
        tp = sim.p['temp']
        if tint or abs(tp) > .1:
            ov = pygame.Surface(rect.size, pygame.SRCALPHA)
            if tint:
                ov.fill(tint)
            if tp > .1:
                ov.fill((255, 140, 60, int(60 * tp)), special_flags=pygame.BLEND_RGBA_ADD)
            elif tp < -.1:
                ov.fill((100, 170, 255, int(70 * -tp)), special_flags=pygame.BLEND_RGBA_ADD)
            scr.blit(ov, rect.topleft)
        scr.set_clip(None)
        return (ox, oy, tz)

    def draw_weather(self, scr, rect, sim, P, tz, z):
        t = self.tms
        for w in sim.wx:
            cx, cy = P(w.x + .5, w.y + .5)
            rr = w.r * tz
            if cx + rr < rect.x or cx - rr > rect.right or cy + rr < rect.y or cy - rr > rect.bottom:
                continue
            k = w.kind
            fade = min(1.0, w.life / 60, (w.max - w.life) / 40 + .2)
            ov = pygame.Surface((int(rr * 2) + 4, int(rr * 2) + 4), pygame.SRCALPHA)
            c0 = (int(rr) + 2, int(rr) + 2)
            if k in ('rain', 'storm', 'snow', 'blizzard'):
                col = {'rain': (90, 100, 125), 'storm': (50, 52, 70), 'snow': (200, 208, 224), 'blizzard': (225, 232, 245)}[k]
                a0 = {'rain': 80, 'storm': 125, 'snow': 80, 'blizzard': 120}[k]
                for j in range(9):
                    ang = j * 0.7 + t * .00005 * (j % 3 + 1)
                    pygame.draw.circle(ov, (*col, int(a0 * fade)), (c0[0] + math.cos(ang * 3) * rr * .5, c0[1] + math.sin(ang * 2 + j) * rr * .5), rr * .42)
                pygame.draw.circle(ov, (*col, int(a0 * .5 * fade)), c0, rr)
                scr.blit(ov, (cx - c0[0], cy - c0[1]))
                n = int(rr * (1.8 if k in ('rain', 'storm') else 1.2) * min(1, z + .3) * fade)
                for _ in range(n):
                    a_ = random.random() * 6.283
                    d_ = math.sqrt(random.random()) * rr
                    qx, qy = cx + math.cos(a_) * d_, cy + math.sin(a_) * d_
                    if k in ('rain', 'storm'):
                        pygame.draw.line(scr, (150, 180, 235), (qx, qy), (qx - 2 * z - 1, qy + 6 * z + 2), 1)
                    else:
                        pygame.draw.rect(scr, (255, 255, 255), (qx, qy, max(2, z), max(2, z)))
            elif k == 'fog':
                pygame.draw.circle(ov, (225, 232, 240, int(95 * fade)), c0, rr)
                pygame.draw.circle(ov, (225, 232, 240, int(60 * fade)), c0, rr * .7)
                scr.blit(ov, (cx - c0[0], cy - c0[1]))
            elif k == 'heat':
                pygame.draw.circle(ov, (255, 150, 40, int(52 * fade)), c0, rr)
                scr.blit(ov, (cx - c0[0], cy - c0[1]))
                for _ in range(int(rr * .15)):
                    a_ = random.random() * 6.283
                    d_ = math.sqrt(random.random()) * rr
                    qx, qy = cx + math.cos(a_) * d_, cy + math.sin(a_) * d_
                    pygame.draw.line(scr, (255, 220, 150), (qx, qy), (qx + math.sin(t * .01 + qx) * 4, qy - 7 * z), 1)
            elif k == 'locust':
                for _ in range(int(60 * min(z, 2) + 20)):
                    a_ = random.random() * 6.283
                    d_ = math.sqrt(random.random()) * rr
                    pygame.draw.rect(scr, (60, 50, 20), (cx + math.cos(a_) * d_, cy + math.sin(a_) * d_, max(2, z), max(2, z)))
            elif k == 'tornado':
                for j in range(9):
                    wd = (3 + j * 1.2) * z
                    yy = cy - (8 - j) * 3.2 * z
                    xx = cx + math.sin(t * .012 + j * .8) * (3 + j * .6) * z
                    pygame.draw.ellipse(scr, (92, 92, 104), (xx - wd, yy - z * 1.5, wd * 2, z * 3.4))
                    pygame.draw.ellipse(scr, (150, 150, 162), (xx - wd, yy - z * 1.5, wd * 2, z * 3.4), 1)
                for _ in range(6):
                    a_ = random.random() * 6.283
                    pygame.draw.rect(scr, (110, 80, 50), (cx + math.cos(a_) * rr * 1.6, cy - random.random() * 22 * z, max(2, z), max(2, z)))

    def init_font(self, font):
        self.font = font


def clamp_(v, a, b):
    return a if v < a else b if v > b else v
