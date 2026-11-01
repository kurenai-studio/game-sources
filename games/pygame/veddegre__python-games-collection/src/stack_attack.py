import os
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'
import pygame, random, sys
from highscores import get_high_score, save_high_score

GAME_NAME = "stack_attack"

CELL      = 30
GRID_W    = 10
GRID_H    = 22
VISIBLE_H = 20
PANEL_W   = 196
BORDER    = 3

PC = {
    "Stick":  (0,   210, 255),
    "L-Block":(255, 130,   0),
    "J-Block":(80,   80, 255),
    "Box":    (255, 210,   0),
    "Skew-R": (0,   210,  90),
    "Skew-L": (220,  40,  80),
    "T-Block":(180,  60, 230),
}
SHAPES = {
    "Stick":  [(-1,0),(0,0),(1,0),(2,0)],
    "L-Block":[(-1,0),(0,0),(1,0),(1,1)],
    "J-Block":[(-1,1),(0,1),(1,1),(1,0)],
    "Box":    [(0,0),(0,1),(1,0),(1,1)],
    "Skew-R": [(0,0),(0,1),(1,-1),(1,0)],
    "Skew-L": [(0,0),(0,-1),(1,0),(1,1)],
    "T-Block":[(-1,0),(0,0),(0,1),(0,-1)],
}
PIECE_NAMES = list(SHAPES.keys())
HIDDEN = GRID_H - VISIBLE_H

class Piece:
    def __init__(self, name=None):
        self.name  = name or random.choice(PIECE_NAMES)
        self.color = PC[self.name]
        self.rot   = 0
        self.row   = HIDDEN - 1
        self.col   = GRID_W // 2

    def cells(self, row=None, col=None, rot=None):
        r = self.row if row is None else row
        c = self.col if col is None else col
        shape = self._rotated(self.rot if rot is None else rot)
        return [(r+dr, c+dc) for dr,dc in shape]

    def _rotated(self, times):
        offsets = list(SHAPES[self.name])
        for _ in range(times % 4):
            offsets = [(dc, -dr) for dr,dc in offsets]
        return offsets

class StackAttack:
    def __init__(self):
        self.reset()

    def reset(self):
        self.grid        = [[None]*GRID_W for _ in range(GRID_H)]
        self.cur         = Piece()
        self.nxt         = Piece()
        self.held        = None
        self.hold_locked = False
        self.score       = 0
        self.level       = 1
        self.lines       = 0
        self.combo       = 0
        self.game_over   = False
        self.drop_t      = 0
        self.drop_spd    = 32
        self.high_score  = get_high_score(GAME_NAME)
        self.new_high    = False
        self.particles   = []
        self.msg         = ""
        self.msg_t       = 0

    def _valid(self, row, col, rot):
        for r,c in self.cur.cells(row, col, rot):
            if c < 0 or c >= GRID_W or r >= GRID_H: return False
            if r >= 0 and self.grid[r][c] is not None: return False
        return True

    def move(self, dc):
        if self._valid(self.cur.row, self.cur.col+dc, self.cur.rot):
            self.cur.col += dc; return True
        return False

    def soft_drop(self):
        if self._valid(self.cur.row+1, self.cur.col, self.cur.rot):
            self.cur.row += 1; return True
        return False

    def rotate(self):
        nr = (self.cur.rot + 1) % 4
        for dc in (0,-1,1,-2,2):
            if self._valid(self.cur.row, self.cur.col+dc, nr):
                self.cur.rot=nr; self.cur.col+=dc; return True
        return False

    def hard_drop(self):
        n = 0
        while self.soft_drop(): n += 1
        self.score += n*2
        self._lock()

    def hold(self):
        if self.hold_locked: return
        name = self.cur.name
        if self.held is None:
            self.held=name; self.cur=self.nxt; self.nxt=Piece()
        else:
            self.held, name = name, self.held
            self.cur = Piece(name)
        self.hold_locked = True

    def _lock(self):
        for r, c in self.cur.cells():
            if 0 <= r < GRID_H:
                self.grid[r][c] = self.cur.color
        self._clear()
        self.cur = self.nxt
        self.nxt = Piece()
        self.hold_locked = False
        if not self._valid(self.cur.row, self.cur.col, self.cur.rot):
            self.game_over = True
            if save_high_score(GAME_NAME, self.score):
                self.new_high = True
            self.high_score = get_high_score(GAME_NAME)

    def _full_rows(self):
        return [r for r in range(GRID_H) if all(c is not None for c in self.grid[r])]

    def _clear(self):
        full = self._full_rows()
        if not full:
            self.combo = 0
            return
        n = len(full)
        self.combo += 1
        for r in full:
            for c in range(GRID_W):
                col = self.grid[r][c]
                if col:
                    for _ in range(3):
                        self.particles.append({
                            "x": float(BORDER + c * CELL + CELL // 2),
                            "y": float(BORDER + (r - HIDDEN) * CELL + CELL // 2),
                            "vx": random.uniform(-4, 4),
                            "vy": random.uniform(-6, -0.5),
                            "life": 32,
                            "color": col,
                        })
        base = [0, 100, 300, 600, 1200][min(n, 4)]
        bonus = (self.combo - 1) * 80
        total = (base + bonus) * self.level
        self.score += total
        self.lines += n
        self.level = min(15, 1 + self.lines // 10)
        self.drop_spd = max(4, 32 - (self.level - 1) * 2)
        if self.combo > 1:
            self.msg = f"COMBO x{self.combo}!  +{total}"
            self.msg_t = 90
        # Remove all full rows at once, then drop the stack (empty rows on top).
        full_set = set(full)
        kept = [self.grid[r][:] for r in range(GRID_H) if r not in full_set]
        self.grid = [[None] * GRID_W for _ in range(n)] + kept
        assert len(self.grid) == GRID_H

    def _ghost_row(self):
        r=self.cur.row
        while self._valid(r+1,self.cur.col,self.cur.rot): r+=1
        return r

    def update(self):
        if self.game_over: return
        for p in self.particles[:]:
            p["x"]+=p["vx"]; p["y"]+=p["vy"]; p["vy"]+=0.35
            p["life"]-=1
            if p["life"]<=0: self.particles.remove(p)
        if self.msg_t>0: self.msg_t-=1
        self.drop_t+=1
        if self.drop_t>=self.drop_spd:
            if not self.soft_drop(): self._lock()
            self.drop_t=0

    def draw(self, screen, GX, GY, SW, SH, stars,
             num_font, lbl_font, tiny_font, big_font):
        BG=(6,6,16); GRID_BG=(10,10,22); GRID_LINE=(20,22,40)
        PANEL_BG=(10,10,24); PANEL_SEP=(30,34,60)
        WHITE=(220,222,240); GRAY=(55,58,80); GOLD=(255,205,50)
        screen.fill(BG)
        for sx,sy,ss in stars:
            pygame.draw.circle(screen,(80,82,100),(sx,sy),ss)
        pygame.draw.rect(screen,GRID_BG,(GX,GY,GRID_W*CELL,VISIBLE_H*CELL))
        for r in range(VISIBLE_H+1):
            pygame.draw.line(screen,GRID_LINE,(GX,GY+r*CELL),(GX+GRID_W*CELL,GY+r*CELL))
        for c in range(GRID_W+1):
            pygame.draw.line(screen,GRID_LINE,(GX+c*CELL,GY),(GX+c*CELL,GY+VISIBLE_H*CELL))

        def draw_cell(color,row,col,ghost=False):
            rect=pygame.Rect(GX+col*CELL,GY+row*CELL,CELL,CELL)
            if ghost:
                s=pygame.Surface((CELL,CELL),pygame.SRCALPHA)
                pygame.draw.rect(s,(*color,45),(0,0,CELL,CELL),border_radius=3)
                pygame.draw.rect(s,(*color,100),(0,0,CELL,CELL),1,border_radius=3)
                screen.blit(s,rect.topleft)
            else:
                pygame.draw.rect(screen,color,rect,border_radius=3)
                bright=tuple(min(255,c+80) for c in color)
                pygame.draw.rect(screen,bright,(rect.x+2,rect.y+2,rect.w-4,5),border_radius=2)
                dark=tuple(max(0,c-60) for c in color)
                pygame.draw.rect(screen,dark,(rect.x+rect.w-4,rect.y+4,3,rect.h-6))
                pygame.draw.rect(screen,tuple(max(0,c-30) for c in color),rect,1,border_radius=3)

        for r in range(GRID_H):
            vr=r-HIDDEN
            if vr<0: continue
            for c in range(GRID_W):
                if self.grid[r][c]: draw_cell(self.grid[r][c],vr,c)

        gr=self._ghost_row()
        if gr!=self.cur.row:
            for r,c in self.cur.cells(gr,self.cur.col,self.cur.rot):
                vr=r-HIDDEN
                if 0<=vr<VISIBLE_H and 0<=c<GRID_W:
                    draw_cell(self.cur.color,vr,c,ghost=True)

        for r,c in self.cur.cells():
            vr=r-HIDDEN
            if 0<=vr<VISIBLE_H and 0<=c<GRID_W:
                draw_cell(self.cur.color,vr,c)

        for p in self.particles:
            a=max(0,int(255*p["life"]/32))
            s=pygame.Surface((8,8),pygame.SRCALPHA)
            pygame.draw.circle(s,(*p["color"],a),(4,4),4)
            screen.blit(s,(int(p["x"])-4,int(p["y"])-4))

        pygame.draw.rect(screen,(40,44,80),
            (GX-BORDER,GY-BORDER,GRID_W*CELL+BORDER*2,VISIBLE_H*CELL+BORDER*2),BORDER)

        px=GX+GRID_W*CELL+BORDER+10
        pygame.draw.rect(screen,PANEL_BG,(GX+GRID_W*CELL+BORDER,0,PANEL_W,SH))
        pygame.draw.line(screen,PANEL_SEP,(GX+GRID_W*CELL+BORDER,0),(GX+GRID_W*CELL+BORDER,SH),1)

        def lbl(t,y,col=WHITE): screen.blit(lbl_font.render(t,True,col),(px,y))
        def val(t,y,col=WHITE): screen.blit(num_font.render(t,True,col),(px,y))

        t1=num_font.render("STACK",True,PC["Stick"])
        t2=num_font.render("ATTACK",True,PC["T-Block"])
        screen.blit(t1,(px,8)); screen.blit(t2,(px,30))

        lbl("SCORE",62);  val(str(self.score),78,GOLD)
        lbl("BEST",114);  val(str(self.high_score),130,(255,175,0))
        lbl("LEVEL",164); val(str(self.level),180,PC["Skew-R"])
        lbl("LINES",214); val(str(self.lines),230,PC["Stick"])

        lbl("NEXT",264)
        self._mini(screen,self.nxt,px+10,284,self.nxt.name)
        lbl("HOLD  [C]",370)
        if self.held:
            fake=Piece(self.held)
            if self.hold_locked: fake.color=tuple(v//3 for v in fake.color)
            self._mini(screen,fake,px+10,390,self.held)

        for i,c in enumerate(["<- -> move","Up/Z rotate","Down soft drop",
                               "Space hard drop","C hold","P pause","R restart",
                               "ESC to menu"]):
            screen.blit(tiny_font.render(c,True,(70,72,100)),(px,SH-140+i*17))

        if self.msg_t>0:
            ms=num_font.render(self.msg,True,GOLD)
            ms.set_alpha(min(255,self.msg_t*4))
            screen.blit(ms,(GX+GRID_W*CELL//2-ms.get_width()//2,SH//2-50))

        if self.game_over:
            ov=pygame.Surface((GX+GRID_W*CELL+BORDER,SH),pygame.SRCALPHA)
            ov.fill((0,0,0,200)); screen.blit(ov,(0,0))
            cx2=(GX+GRID_W*CELL)//2
            go=big_font.render("GAME OVER",True,WHITE)
            sc=lbl_font.render(f"Score: {self.score}",True,WHITE)
            rs=lbl_font.render("Press R to restart",True,WHITE)
            screen.blit(go,(cx2-go.get_width()//2,SH//2-50))
            screen.blit(sc,(cx2-sc.get_width()//2,SH//2+6))
            screen.blit(rs,(cx2-rs.get_width()//2,SH//2+30))
            if self.new_high:
                nb=lbl_font.render("NEW BEST!",True,PC["Box"])
                screen.blit(nb,(cx2-nb.get_width()//2,SH//2+58))

    def _mini(self,screen,piece,ox,oy,name):
        cs=20
        cells=piece.cells(0,2,0)
        if not cells: return
        min_r=min(r for r,_ in cells); min_c=min(c for _,c in cells)
        color=PC[name]
        for r,c in cells:
            rx=ox+(c-min_c)*cs; ry=oy+(r-min_r)*cs
            pygame.draw.rect(screen,color,(rx+1,ry+1,cs-2,cs-2),border_radius=3)
            bright=tuple(min(255,v+70) for v in color)
            pygame.draw.rect(screen,bright,(rx+3,ry+3,cs-6,4),border_radius=1)


def run(screen=None):
    pygame.init()
    SW = CELL*GRID_W + BORDER*2 + PANEL_W
    SH = CELL*VISIBLE_H + BORDER*2
    GX = BORDER; GY = BORDER
    screen = pygame.display.set_mode((SW, SH))
    pygame.display.set_caption("Stack Attack")
    def _set_window_icon():
        base = os.path.dirname(os.path.abspath(__file__))
        for _icon_name in ("icon.bmp", "icon.png"):
            _icon_path = os.path.join(base, _icon_name)
            if os.path.isfile(_icon_path):
                try:
                    pygame.display.set_icon(pygame.image.load(_icon_path))
                    break
                except pygame.error:
                    pass
    
    _set_window_icon()

    num_font  = pygame.font.SysFont("Arial", 22, bold=True)
    lbl_font  = pygame.font.SysFont("Arial", 13, bold=True)
    tiny_font = pygame.font.SysFont("Arial", 11)
    big_font  = pygame.font.SysFont("Arial", 26, bold=True)
    stars = [(random.randint(0,SW),random.randint(0,SH),random.choice([1,1,1,2]))
             for _ in range(60)]
    game  = StackAttack()
    clock = pygame.time.Clock()
    ml=mr=md=False; INIT,REP=16,7; tl=tr=td=0
    paused=False
    running=True
    while running:
        for event in pygame.event.get():
            if event.type==pygame.QUIT: running=False
            if event.type==pygame.KEYDOWN:
                if event.key==pygame.K_ESCAPE: running=False
                elif event.key==pygame.K_r: game.reset(); paused=False
                elif event.key==pygame.K_p and not game.game_over:
                    paused=not paused; ml=mr=md=False; tl=tr=td=0
                elif not game.game_over and not paused:
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
        if not game.game_over and not paused:
            if ml: tl+=1
            if tl>=REP: game.move(-1);tl=0
            if mr: tr+=1
            if tr>=REP: game.move(1);tr=0
            if md: td+=1
            if td>=REP: game.soft_drop();td=0
        if not paused: game.update()
        game.draw(screen,GX,GY,SW,SH,stars,num_font,lbl_font,tiny_font,big_font)
        if paused and not game.game_over:
            ov=pygame.Surface((GX+GRID_W*CELL+BORDER,SH),pygame.SRCALPHA)
            ov.fill((0,0,0,170)); screen.blit(ov,(0,0))
            cx2=(GX+GRID_W*CELL)//2
            pt=big_font.render("PAUSED",True,(220,222,240))
            ps=lbl_font.render("Press P to resume",True,(160,162,190))
            screen.blit(pt,(cx2-pt.get_width()//2,SH//2-30))
            screen.blit(ps,(cx2-ps.get_width()//2,SH//2+14))
        pygame.display.flip(); clock.tick(60)
    try:
        pygame.display.quit()
    except pygame.error:
        pass
    return


if __name__ == '__main__':
    run()
