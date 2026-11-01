import os
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'
"""
Neon Drift
----------
A falling-piece puzzle game on a TRIANGLE grid.
Pieces are made of connected triangles (not squares) — looks and feels
completely unlike any existing game.

Grid:  Each cell (row, col) is either an up-pointing or down-pointing triangle.
       Up   if (row + col) is even  → apex at top, base at bottom
       Down if (row + col) is odd   → apex at bottom, base at top

Pieces (7 normal + 1 bomb):
  Spike   — wide flat 5-tri band
  Arrow   — right-pointing arrowhead (4 tri)
  Diamond — 2×2 rhombus (4 tri)
  Hook    — L-shape (4 tri)
  Zigzag  — staircase (4 tri)
  Tower   — tall column (5 tri)
  Flash   — lightning bolt (5 tri)
  Bomb ★  — 2×2 block, clears 3-col × 4-row zone on landing

Mechanics:
  • CLEAR: any row where every cell is filled clears and scores points.
  • COLOUR MATCH: if a cleared row contains 3+ consecutive cells of the
    same colour, a colour-run bonus is awarded.
  • BOMB: every 15 rows cleared a Bomb piece spawns. It's shown by a ★
    overlay. When it locks, it blasts a 3-column wide, 4-row deep crater.
  • HOLD (C): swap current piece with hold slot once per drop.
  • HARD DROP (Space): instant drop + 2pts per row.

Controls: ← → move  |  Z/↑ rotate  |  ↓ soft drop
          Space hard drop  |  C hold  |  R restart
"""

import pygame, random, math, sys
from highscores import get_high_score, save_high_score

GAME_NAME = "neon_drift"
pygame.init()

# ── Grid geometry ─────────────────────────────────────────────────────────────
COLS      = 14          # number of triangle columns
ROWS      = 24          # number of rows
TRI_BASE  = 38          # base width of each triangle in pixels
TRI_H     = int(TRI_BASE * math.sqrt(3) / 2)   # ≈ 33 px
PANEL_W   = 200
SW        = COLS * (TRI_BASE // 2) + TRI_BASE // 2 + PANEL_W
SH        = ROWS * TRI_H + 2

screen = pygame.display.set_mode((SW, SH))
pygame.display.set_caption("Neon Drift")

# ── Colours ───────────────────────────────────────────────────────────────────
BLACK    = (8,   8,  18)
WHITE    = (230, 230, 245)
DGRAY    = (35,  37,  55)
MGRAY    = (60,  62,  85)
PANEL_BG = (14,  14,  30)
GOLD     = (255, 210,  50)
BOMB_C   = (255, 255, 255)

# 7 piece colours
PC = [
    (0,   229, 255),   # 0 Spike   cyan
    (255,  45, 200),   # 1 Arrow   magenta
    (255, 230,   0),   # 2 Diamond yellow
    (0,   255, 110),   # 3 Hook    green
    (255, 100,   0),   # 4 Zigzag  orange
    (168,  50, 255),   # 5 Tower   violet
    (255,  40,  70),   # 6 Flash   red
]

# ── Triangle geometry helpers ─────────────────────────────────────────────────
def is_up(row, col):
    """True if the triangle at (row,col) points upward."""
    return (row + col) % 2 == 0

def tri_verts(row, col):
    """
    Pixel vertices of the triangle at grid (row, col).
    Left edge of column col starts at x = col * (TRI_BASE//2).
    """
    x0 = col * (TRI_BASE // 2)
    y0 = row * TRI_H
    if is_up(row, col):
        # apex top-centre, base bottom
        return [(x0 + TRI_BASE // 2, y0),
                (x0,                  y0 + TRI_H),
                (x0 + TRI_BASE,       y0 + TRI_H)]
    else:
        # apex bottom-centre, base top
        return [(x0,                  y0),
                (x0 + TRI_BASE,       y0),
                (x0 + TRI_BASE // 2,  y0 + TRI_H)]

def tri_center(row, col):
    verts = tri_verts(row, col)
    return (sum(v[0] for v in verts)//3, sum(v[1] for v in verts)//3)

# ── Piece definitions ─────────────────────────────────────────────────────────
# Each piece is a list of (row_offset, col_offset) relative to an anchor cell.
# The anchor is always an UP-pointing triangle (even row+col sum).
# Rotations are pre-computed as lists of shape variants.

def _mk_rotations(cells_list):
    """Given a list of shape variants, return them padded to 4 by cycling."""
    while len(cells_list) < 4:
        cells_list.append(cells_list[-1])
    return cells_list

PIECES = [
    # 0 Spike: 5-tri flat band — [(0,0)up,(0,1)dn,(0,2)up,(0,3)dn,(0,4)up]
    _mk_rotations([
        [(0,0),(0,1),(0,2),(0,3),(0,4)],
        [(0,0),(1,1),(2,0),(3,1),(4,0)],   # vertical form
        [(0,0),(0,1),(0,2),(0,3),(0,4)],
        [(0,0),(1,1),(2,0),(3,1),(4,0)],
    ]),
    # 1 Arrow: right-pointing arrowhead
    _mk_rotations([
        [(0,0),(0,1),(0,2),(0,3)],
        [(0,0),(1,1),(2,0),(1,-1)],
        [(0,1),(0,2),(0,3),(0,4)],
        [(0,0),(1,1),(2,2),(1,3)],
    ]),
    # 2 Diamond: 2-row rhombus
    _mk_rotations([
        [(0,0),(0,1),(1,1),(1,2)],
        [(0,0),(0,1),(1,1),(1,2)],
        [(0,0),(0,1),(1,1),(1,2)],
        [(0,0),(0,1),(1,1),(1,2)],
    ]),
    # 3 Hook: L-shape
    _mk_rotations([
        [(0,0),(0,1),(1,1),(1,2)],
        [(0,0),(1,1),(2,0),(2,1)],
        [(0,0),(0,1),(0,2),(1,2)],
        [(0,0),(0,1),(1,0),(2,1)],
    ]),
    # 4 Zigzag: staircase
    _mk_rotations([
        [(0,0),(0,1),(1,2),(1,3)],
        [(0,1),(1,0),(1,1),(2,0)],
        [(0,0),(0,1),(1,2),(1,3)],
        [(0,1),(1,0),(1,1),(2,0)],
    ]),
    # 5 Tower: tall column
    _mk_rotations([
        [(0,0),(1,1),(2,0),(3,1),(4,0)],
        [(0,0),(0,1),(0,2),(0,3),(0,4)],
        [(0,0),(1,1),(2,0),(3,1),(4,0)],
        [(0,0),(0,1),(0,2),(0,3),(0,4)],
    ]),
    # 6 Flash: lightning bolt (5 tri)
    _mk_rotations([
        [(0,0),(0,1),(1,1),(1,2),(1,3)],
        [(0,1),(1,0),(1,1),(2,1),(3,0)],
        [(0,0),(0,1),(0,2),(1,2),(1,3)],
        [(0,0),(1,0),(1,1),(2,1),(2,0)],
    ]),
    # 7 BOMB: 2×2 compact block (special)
    _mk_rotations([
        [(0,0),(0,1),(1,1),(1,2)],
        [(0,0),(0,1),(1,1),(1,2)],
        [(0,0),(0,1),(1,1),(1,2)],
        [(0,0),(0,1),(1,1),(1,2)],
    ]),
]

PIECE_NAMES = ["Spike","Arrow","Diamond","Hook","Zigzag","Tower","Flash","Bomb ★"]

# ── Fonts ─────────────────────────────────────────────────────────────────────
tf  = pygame.font.SysFont("Arial", 19, bold=True)
nf  = pygame.font.SysFont("Arial", 21, bold=True)
lf  = pygame.font.SysFont("Arial", 13, bold=True)
sf  = pygame.font.SysFont("Arial", 11)
bf  = pygame.font.SysFont("Arial", 26, bold=True)

# ── Helpers ───────────────────────────────────────────────────────────────────
def bright(c, a=80): return tuple(min(255,v+a) for v in c)
def dim(c, f=4):     return tuple(v//f for v in c)

def draw_tri(surf, color, row, col, ghost=False, star=False):
    verts = tri_verts(row, col)
    if ghost:
        pygame.draw.polygon(surf, dim(color,3), verts)
        pygame.draw.polygon(surf, dim(color,1), verts, 1)
    else:
        pygame.draw.polygon(surf, color, verts)
        # top highlight line
        if is_up(row, col):
            pygame.draw.line(surf, bright(color,90), verts[0], verts[1], 2)
        else:
            pygame.draw.line(surf, bright(color,90), verts[0], verts[1], 2)
        pygame.draw.polygon(surf, bright(color,30), verts, 1)
    if star:
        cx, cy = tri_center(row, col)
        s = sf.render("★", True, GOLD)
        surf.blit(s, (cx - s.get_width()//2, cy - s.get_height()//2))

# ── Game class ────────────────────────────────────────────────────────────────
class NeonDrift:
    def __init__(self):
        self.reset()

    def reset(self):
        # grid[row][col] = colour tuple or 0
        self.grid        = [[0]*COLS for _ in range(ROWS)]
        self.rows_cleared= 0
        self.bomb_due    = 15
        self.cur         = self._new_piece()
        self.nxt         = self._new_piece()
        self.held        = None
        self.hold_locked = False
        self.score       = 0
        self.level       = 1
        self.combo       = 0
        self.game_over   = False
        self.drop_t      = 0
        self.drop_spd    = 34
        self.high_score  = get_high_score(GAME_NAME)
        self.new_high    = False
        self.particles   = []
        self.msg         = ""
        self.msg_t       = 0
        self.flash_rows  = set()
        self.flash_t     = 0

    def _new_piece(self):
        is_bomb = (self.rows_cleared >= self.bomb_due)
        if is_bomb:
            self.bomb_due += 15
            t = 7
        else:
            t = random.randint(0, 6)
        # find a valid starting column (anchor must be in bounds and up-pointing)
        # spawn near centre
        anchor_col = COLS // 2 - 1
        # ensure anchor cell is up-pointing at row 0
        if not is_up(0, anchor_col):
            anchor_col += 1
        return {
            "type": t,
            "rot":  0,
            "row":  0,
            "col":  anchor_col,
            "color": BOMB_C if is_bomb else PC[t],
            "bomb": is_bomb,
        }

    def _cells(self, piece=None):
        """Return list of (row, col) for all triangles in piece (default current)."""
        p = piece or self.cur
        shape = PIECES[p["type"]][p["rot"]]
        return [(p["row"]+dr, p["col"]+dc) for dr,dc in shape]

    def _valid(self, piece):
        for r,c in self._cells(piece):
            if c < 0 or c >= COLS or r >= ROWS:
                return False
            if r >= 0 and self.grid[r][c]:
                return False
        return True

    def move(self, dc):
        test = dict(self.cur); test["col"] += dc
        if self._valid(test):
            self.cur["col"] += dc
            return True
        return False

    def soft_drop(self):
        test = dict(self.cur); test["row"] += 1
        if self._valid(test):
            self.cur["row"] += 1
            return True
        return False

    def rotate(self):
        test = dict(self.cur)
        test["rot"] = (test["rot"]+1) % 4
        # try base position and small offsets
        for dc in (0, 1, -1, 2, -2):
            t2 = dict(test); t2["col"] += dc
            if self._valid(t2):
                self.cur["rot"] = t2["rot"]
                self.cur["col"] = t2["col"]
                return True
        return False

    def hard_drop(self):
        n = 0
        while self.soft_drop(): n += 1
        self.score += n * 2
        self._lock()

    def hold(self):
        if self.hold_locked: return
        t, c, b = self.cur["type"], self.cur["color"], self.cur["bomb"]
        if self.held is None:
            self.held = (t, c, b)
            self.cur  = self.nxt
            self.nxt  = self._new_piece()
        else:
            ot, oc, ob = self.held
            self.held  = (t, c, b)
            anchor_col = COLS//2 - 1
            if not is_up(0, anchor_col): anchor_col += 1
            self.cur   = {"type":ot,"rot":0,"row":0,"col":anchor_col,
                          "color":oc,"bomb":ob}
        self.hold_locked = True

    def _lock(self):
        cells = self._cells()
        for r,c in cells:
            if 0 <= r < ROWS and 0 <= c < COLS:
                self.grid[r][c] = self.cur["color"]

        if self.cur["bomb"]:
            # blast: clear 3 columns centred on anchor, 4 rows up from bottom of piece
            blast_col = self.cur["col"]
            blast_row = max(r for r,_ in cells)
            for r in range(max(0, blast_row-3), min(ROWS, blast_row+1)):
                for c in range(max(0, blast_col-1), min(COLS, blast_col+2)):
                    if self.grid[r][c]:
                        self._spawn_particle(r, c, self.grid[r][c])
                    self.grid[r][c] = 0
            self.score += 300 * self.level
            self._show_msg("BOMB! +300")

        self._clear_rows()
        self.cur  = self.nxt
        self.nxt  = self._new_piece()
        self.hold_locked = False

        # check game over: any cell in top 2 rows filled
        for c in range(COLS):
            if self.grid[0][c] or self.grid[1][c]:
                self.game_over = True
                if save_high_score(GAME_NAME, self.score):
                    self.new_high = True
                self.high_score = get_high_score(GAME_NAME)
                return

    def _clear_rows(self):
        full = [r for r in range(ROWS) if all(self.grid[r])]
        if not full:
            self.combo = 0
            return
        n = len(full); self.combo += 1

        # Colour-run bonus
        run_bonus = 0
        for r in full:
            row = self.grid[r]; i = 0
            while i < COLS:
                cv = row[i]
                if not cv: i+=1; continue
                j = i
                while j < COLS and row[j] == cv: j+=1
                run = j-i
                if run >= 3: run_bonus += run*20
                i = j
            for c in range(COLS):
                self._spawn_particle(r, c, self.grid[r][c])

        base  = [0,150,400,900,2000][min(n,4)]
        combo_pts = (self.combo-1)*100
        total = (base + combo_pts + run_bonus) * self.level
        self.score += total
        self.rows_cleared += n
        self.level = min(20, 1 + self.rows_cleared // 8)
        self.drop_spd = max(4, 34 - (self.level-1)*2)

        if self.combo > 1:   self._show_msg(f"COMBO x{self.combo}! +{total}")
        elif run_bonus:      self._show_msg(f"COLOUR RUN! +{run_bonus}")

        for r in sorted(full, reverse=True):
            del self.grid[r]
            self.grid.insert(0, [0]*COLS)

    def _show_msg(self, t): self.msg=t; self.msg_t=90

    def _spawn_particle(self, row, col, color):
        cx, cy = tri_center(row, col)
        for _ in range(3):
            self.particles.append({
                "x":float(cx),"y":float(cy),
                "vx":random.uniform(-3,3),"vy":random.uniform(-5,-0.5),
                "life":30,"color":color
            })

    def _ghost(self):
        test = dict(self.cur)
        while True:
            t2 = dict(test); t2["row"] += 1
            if not self._valid(t2): break
            test = t2
        return test

    def update(self):
        if self.game_over: return
        for p in self.particles[:]:
            p["x"]+=p["vx"]; p["y"]+=p["vy"]; p["vy"]+=0.3
            p["life"]-=1
            if p["life"]<=0: self.particles.remove(p)
        if self.msg_t>0: self.msg_t-=1
        self.drop_t+=1
        if self.drop_t >= self.drop_spd:
            if not self.soft_drop(): self._lock()
            self.drop_t=0

    # ── Drawing ───────────────────────────────────────────────────────────────
    def draw(self):
        screen.fill(BLACK)
        grid_w = COLS*(TRI_BASE//2)+TRI_BASE//2

        # Grid cells
        for r in range(ROWS):
            for c in range(COLS):
                v = self.grid[r][c]
                if v:
                    draw_tri(screen, v, r, c)
                else:
                    verts = tri_verts(r, c)
                    pygame.draw.polygon(screen, DGRAY, verts, 1)

        # Ghost
        ghost = self._ghost()
        if ghost["row"] != self.cur["row"]:
            gp = dict(self.cur); gp["row"]=ghost["row"]; gp["col"]=ghost["col"]
            for r,c in self._cells(gp):
                if 0<=r<ROWS and 0<=c<COLS:
                    draw_tri(screen, self.cur["color"], r, c, ghost=True)

        # Current piece
        for r,c in self._cells():
            if 0<=r<ROWS and 0<=c<COLS:
                draw_tri(screen, self.cur["color"], r, c,
                         star=self.cur["bomb"])

        # Particles
        for p in self.particles:
            a=max(0,int(255*p["life"]/30))
            s=pygame.Surface((6,6),pygame.SRCALPHA)
            pygame.draw.circle(s,(*p["color"],a),(3,3),3)
            screen.blit(s,(int(p["x"])-3,int(p["y"])-3))

        # Grid border
        pygame.draw.rect(screen, MGRAY, (0,0,grid_w,SH), 1)

        # ── Panel ─────────────────────────────────────────────────────────────
        px = grid_w + 8
        pygame.draw.rect(screen, PANEL_BG, (grid_w, 0, PANEL_W, SH))

        def lbl(t,y,col=WHITE): screen.blit(lf.render(t,True,col),(px,y))
        def val(t,y,col=WHITE): screen.blit(nf.render(t,True,col),(px,y))

        t1=tf.render("NEON",True,PC[0])
        t2=tf.render("DRIFT",True,PC[1])
        screen.blit(t1,(px,6)); screen.blit(t2,(px+t1.get_width()+4,6))

        lbl("SCORE",38);      val(str(self.score),54,GOLD)
        lbl("BEST",90);       val(str(self.high_score),106,(255,175,0))
        lbl("LEVEL",142);     val(str(self.level),158,PC[3])
        lbl("ROWS",196);      val(str(self.rows_cleared),212,PC[0])

        lbl("NEXT",244)
        self._draw_mini(self.nxt, px+10, 264)

        lbl("HOLD  [C]",360)
        if self.held:
            ht,hc,hb = self.held
            dim_c = hc if not self.hold_locked else tuple(v//3 for v in hc)
            fake = {"type":ht,"rot":0,"row":0,"col":0,"color":dim_c,"bomb":hb}
            self._draw_mini(fake, px+10, 380)

        # Bomb progress bar
        until = self.bomb_due - self.rows_cleared
        bw = 160; filled=max(0,int(bw*(1-min(until,15)/15)))
        lbl("BOMB ★",468,(200,200,200))
        pygame.draw.rect(screen,DGRAY,(px,486,bw,8),border_radius=3)
        pygame.draw.rect(screen,(255,230,0),(px,486,filled,8),border_radius=3)

        for i,c in enumerate(["← → move","Z/↑ rotate","↓ soft drop",
                               "SPACE hard drop","C hold","R restart"]):
            screen.blit(sf.render(c,True,(75,75,100)),(px,SH-106+i*17))

        if self.msg_t>0:
            ms=nf.render(self.msg,True,GOLD); ms.set_alpha(min(255,self.msg_t*4))
            screen.blit(ms,(grid_w//2-ms.get_width()//2, SH//2-50))

        if self.game_over:
            ov=pygame.Surface((grid_w,SH),pygame.SRCALPHA); ov.fill((0,0,0,195))
            screen.blit(ov,(0,0))
            cx2=grid_w//2
            go=bf.render("GAME OVER",True,WHITE)
            sc=lf.render(f"Score: {self.score}",True,WHITE)
            rs=lf.render("Press R to restart",True,WHITE)
            screen.blit(go,(cx2-go.get_width()//2,SH//2-50))
            screen.blit(sc,(cx2-sc.get_width()//2,SH//2+8))
            screen.blit(rs,(cx2-rs.get_width()//2,SH//2+34))
            if self.new_high:
                nb=lf.render("NEW BEST!",True,PC[2])
                screen.blit(nb,(cx2-nb.get_width()//2,SH//2+62))

    def _draw_mini(self, piece, ox, oy):
        """Draw a small preview of a piece."""
        cells = self._cells(piece)
        if not cells: return
        min_r = min(r for r,_ in cells); min_c = min(c for _,c in cells)
        SCALE = 0.55
        bs = int(TRI_BASE*SCALE); hs = int(TRI_H*SCALE)
        col = piece["color"]
        for r,c in cells:
            nr,nc = r-min_r, c-min_c
            x0 = ox + nc*(bs//2)
            y0 = oy + nr*hs
            if is_up(r,c):
                verts=[(x0+bs//2,y0),(x0,y0+hs),(x0+bs,y0+hs)]
            else:
                verts=[(x0,y0),(x0+bs,y0),(x0+bs//2,y0+hs)]
            pygame.draw.polygon(screen,col,verts)
            pygame.draw.polygon(screen,bright(col,40),verts,1)
        if piece.get("bomb"):
            cx2=ox+(max(c for _,c in cells)-min_c)*(bs//2)//2+bs//2
            cy2=oy+(max(r for r,_ in cells)-min_r)*hs//2+hs//2
            st=sf.render("★",True,GOLD)
            screen.blit(st,(cx2-st.get_width()//2,cy2-st.get_height()//2))


# ── Main loop ─────────────────────────────────────────────────────────────────
game  = NeonDrift()
clock = pygame.time.Clock()

ml=mr=md=False; INIT,REP=16,7; tl=tr=td=0
running=True
while running:
    for event in pygame.event.get():
        if event.type==pygame.QUIT: running=False
        if event.type==pygame.KEYDOWN:
            if event.key==pygame.K_r: game.reset()
            elif not game.game_over:
                if event.key==pygame.K_LEFT:   ml=True;tl=-INIT;game.move(-1)
                elif event.key==pygame.K_RIGHT: mr=True;tr=-INIT;game.move(1)
                elif event.key==pygame.K_DOWN:  md=True;td=-INIT;game.soft_drop()
                elif event.key in (pygame.K_UP,pygame.K_z): game.rotate()
                elif event.key==pygame.K_SPACE: game.hard_drop()
                elif event.key==pygame.K_c: game.hold()
        if event.type==pygame.KEYUP:
            if event.key==pygame.K_LEFT:  ml=False
            if event.key==pygame.K_RIGHT: mr=False
            if event.key==pygame.K_DOWN:  md=False

    if not game.game_over:
        if ml: tl+=1
        if tl>=REP: game.move(-1);tl=0
        if mr: tr+=1
        if tr>=REP: game.move(1);tr=0
        if md: td+=1
        if td>=REP: game.soft_drop();td=0

    game.update(); game.draw(); pygame.display.flip(); clock.tick(60)

pygame.quit(); sys.exit()
