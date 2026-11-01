import os
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'
import pygame, random, math, sys
from highscores import get_high_score, save_high_score

GAME_NAME = "helicopter_dash"

GRAVITY      = 0.18
THRUST       = -0.38
MAX_VY       = 4.5
SCROLL_SPEED = 2.8
SEGMENT_W    = 48
HELI_W, HELI_H = 52, 22
# Collision / clearance (rotor extends above the body in draw_helicopter)
HELI_COLL_PAD_X = 6
HELI_COLL_PAD_TOP = 32
HELI_COLL_PAD_BOT = 8
MIN_PASS_GAP = HELI_H + HELI_COLL_PAD_TOP + HELI_COLL_PAD_BOT + 12
MAX_CENTRE_STEP = 18
PLAY_TOP = 50
PLAY_BOTTOM = 480


def heli_hit_rect(heli):
    """Axis-aligned bounds used for cave and spike collisions."""
    x = int(heli["x"])
    y = int(heli["y"])
    return pygame.Rect(
        x + HELI_COLL_PAD_X,
        y - HELI_COLL_PAD_TOP,
        HELI_W - HELI_COLL_PAD_X * 2,
        HELI_H + HELI_COLL_PAD_TOP + HELI_COLL_PAD_BOT,
    )


def gap_for_score(score):
    """Vertical opening between cave surfaces; never smaller than the helicopter."""
    min_play = PLAY_BOTTOM - PLAY_TOP
    easy = min(240, 200 - score * 1.0)
    gap = max(MIN_PASS_GAP, easy)
    return min(gap, min_play - 48)

def drift_for_score(score):
    return min(55, 14 + score * 0.5)

WHITE    = (255,255,255)
YELLOW   = (255,220,50)
GRAY     = (160,160,170)
DARK_GRAY= (80,80,90)
RED      = (220,60,60)
ORANGE   = (255,150,0)
CAVE_TOP = (55,50,70)
CAVE_MID = (35,32,50)
ROTOR_C  = (200,200,210)
SKY_C    = (30,30,48)
HUD_C    = (20,20,36)
GOLD     = (255,210,50)

def _overlap_height(top_a, bot_a, top_b, bot_b):
    return min(bot_a, bot_b) - max(top_a, top_b)


def _segment_passable(seg, prev_top, prev_bot):
    """Both segments must leave room for the heli where their x-ranges overlap."""
    if seg["bot"] - seg["top"] < MIN_PASS_GAP:
        return False
    if _overlap_height(seg["top"], seg["bot"], prev_top, prev_bot) < MIN_PASS_GAP:
        return False
    mid_y = (prev_top + prev_bot) // 2
    for y in (mid_y, mid_y - 36, mid_y + 36):
        if segment_blocks_heli(seg, heli_hit_rect({"x": 120.0, "y": float(y), "vy": 0.0})):
            return False
    return True


def _build_segment(prev_top, prev_bot, seg_x, score):
    prev_top = int(prev_top)
    prev_bot = int(prev_bot)
    gap = int(gap_for_score(score))
    prev_centre = (prev_top + prev_bot) // 2
    max_step = int(min(MAX_CENTRE_STEP, drift_for_score(score), max(10, (gap - MIN_PASS_GAP) // 2)))
    max_step = max(1, max_step)
    centre = prev_centre + random.randint(-max_step, max_step)
    jolt_chance = min(0.22, 0.04 + score * 0.003)
    if random.random() < jolt_chance:
        jolt = random.choice([-1, 1]) * random.randint(max_step, max_step + 8)
        centre = prev_centre + max(-max_step - 6, min(max_step + 6, jolt))
    centre = max(PLAY_TOP + gap // 2 + 4, min(PLAY_BOTTOM - gap // 2 - 4, centre))
    top = centre - gap // 2
    bot = centre + gap // 2
    if bot - top < MIN_PASS_GAP:
        centre = (PLAY_TOP + PLAY_BOTTOM) // 2
        top = centre - MIN_PASS_GAP // 2
        bot = centre + MIN_PASS_GAP // 2
    if _overlap_height(top, bot, prev_top, prev_bot) < MIN_PASS_GAP:
        centre = prev_centre
        top = centre - gap // 2
        bot = centre + gap // 2
        if _overlap_height(top, bot, prev_top, prev_bot) < MIN_PASS_GAP:
            overlap_mid = (max(top, prev_top) + min(bot, prev_bot)) // 2
            centre = overlap_mid
            top = centre - gap // 2
            bot = centre + gap // 2
            centre = max(PLAY_TOP + MIN_PASS_GAP // 2, min(PLAY_BOTTOM - MIN_PASS_GAP // 2, centre))
            top = centre - gap // 2
            bot = centre + gap // 2

    spike = None
    spike_chance = min(0.32, score * 0.005)
    spare = (bot - top) - MIN_PASS_GAP
    if score > 12 and random.random() < spike_chance and spare > 36:
        max_spike = min(40, spare // 2 - 14)
        if max_spike >= 14:
            spike_len = random.randint(14, max_spike)
            spike_side = random.choice(["top", "bot"])
            spike_x = seg_x + SEGMENT_W // 2
            if spike_side == "top":
                spike = {"side": "top", "x": spike_x, "y": top, "len": spike_len}
            else:
                spike = {"side": "bot", "x": spike_x, "y": bot, "len": spike_len}
    return {"x": int(seg_x), "top": int(top), "bot": int(bot), "spike": spike}


def make_segment(prev_top, prev_bot, seg_x, score=0):
    prev_top = int(prev_top)
    prev_bot = int(prev_bot)
    for _ in range(16):
        seg = _build_segment(prev_top, prev_bot, seg_x, score)
        if _segment_passable(seg, prev_top, prev_bot):
            return seg
    centre = (prev_top + prev_bot) // 2
    gap = max(MIN_PASS_GAP, int(gap_for_score(score)))
    top = centre - gap // 2
    bot = centre + gap // 2
    return {"x": int(seg_x), "top": int(top), "bot": int(bot), "spike": None}


def segment_blocks_heli(seg, rect):
    """True if the helicopter hit rect intersects cave or spikes."""
    sx1, sx2 = seg["x"], seg["x"] + SEGMENT_W
    if rect.right <= sx1 or rect.left >= sx2:
        return False
    if rect.top < seg["top"] or rect.bottom > seg["bot"]:
        return True
    sp = seg.get("spike")
    if not sp:
        return False
    spx = seg["x"] + SEGMENT_W // 2
    if rect.right <= spx - 14 or rect.left >= spx + 14:
        return False
    if sp["side"] == "top":
        spike_rect = pygame.Rect(spx - 12, sp["y"], 24, sp["len"])
    else:
        spike_rect = pygame.Rect(spx - 12, sp["y"] - sp["len"], 24, sp["len"])
    return rect.colliderect(spike_rect)

def reset(high_score):
    heli = {"x": 120.0, "y": 240.0, "vy": 0.0}
    segs = []
    start_gap = gap_for_score(0)
    centre = (PLAY_TOP + PLAY_BOTTOM) // 2
    pt, pb = centre - start_gap // 2, centre + start_gap // 2
    for i in range(16):
        sx = 600 + i * SEGMENT_W
        seg = {"x": sx, "top": pt, "bot": pb, "spike": None} if i < 6 else make_segment(pt, pb, sx, 0)
        if i >= 6:
            pt, pb = seg["top"], seg["bot"]
        segs.append(seg)
    return heli, segs, 0, False, False, high_score, False, False

if __name__ == '__main__':
    pygame.init()
    WIDTH, HEIGHT = 600, 480
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    pygame.display.set_caption("Helicopter Dash")
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
    
    
    font       = pygame.font.SysFont("Arial", 36, bold=True)
    small_font = pygame.font.SysFont("Arial", 20)
    clock      = pygame.time.Clock()
    rotor_angle = [0]
    high_score  = get_high_score(GAME_NAME)
    heli, segs, score, game_over, started, high_score, new_high, thrusting = reset(high_score)

    def draw_helicopter(h, thrusting):
        cx = int(h["x"]) + HELI_W//2
        cy = int(h["y"]) + HELI_H//2
        pygame.draw.ellipse(screen, GRAY,       (cx-24,cy-9,48,18))
        pygame.draw.ellipse(screen, DARK_GRAY,  (cx-24,cy-9,48,18), 2)
        pygame.draw.ellipse(screen, (180,220,255),(cx+4,cy-10,20,14))
        pygame.draw.ellipse(screen, DARK_GRAY,  (cx+4,cy-10,20,14), 1)
        pygame.draw.polygon(screen, DARK_GRAY,
            [(cx-24,cy-3),(cx-24,cy+3),(cx-42,cy+1),(cx-42,cy-1)])
        pygame.draw.rect(screen, ROTOR_C, (cx-44,cy-8,4,16))
        pygame.draw.line(screen, DARK_GRAY,(cx-14,cy+9),(cx+16,cy+9),2)
        pygame.draw.line(screen, DARK_GRAY,(cx-10,cy+6),(cx-14,cy+9),2)
        pygame.draw.line(screen, DARK_GRAY,(cx+12,cy+6),(cx+16,cy+9),2)
        rotor_angle[0] = (rotor_angle[0] + (14 if thrusting else 8)) % 360
        for blade in range(3):
            a   = math.radians(rotor_angle[0] + blade*120)
            bx2 = int(cx + math.cos(a)*30)
            by2 = int(cy - 10 + math.sin(a)*5)
            pygame.draw.line(screen, ROTOR_C, (cx,cy-10), (bx2,by2), 3)
        pygame.draw.circle(screen, DARK_GRAY, (cx,cy-10), 4)
        if thrusting:
            fx, fy = cx, cy+10
            pygame.draw.polygon(screen, ORANGE,
                [(fx-5,fy),(fx+5,fy),(fx,fy+random.randint(6,14))])

    def draw_cave(segs):
        for seg in segs:
            x  = int(seg["x"]); sw = SEGMENT_W+2
            pygame.draw.rect(screen,CAVE_TOP,(x,50,sw,seg["top"]-50))
            pygame.draw.rect(screen,CAVE_TOP,(x,seg["bot"],sw,HEIGHT-seg["bot"]))
            pygame.draw.line(screen,CAVE_MID,(x,seg["top"]-4),(x+sw,seg["top"]-4),2)
            pygame.draw.line(screen,CAVE_MID,(x,seg["bot"]+4),(x+sw,seg["bot"]+4),2)
            sp = seg.get("spike")
            if sp:
                sx2    = int(seg["x"]) + SEGMENT_W//2
                base_y = int(sp["y"])
                tip_y  = base_y + sp["len"] if sp["side"]=="top" else base_y - sp["len"]
                pygame.draw.polygon(screen,CAVE_TOP,
                    [(sx2-10,base_y),(sx2+10,base_y),(sx2,tip_y)])
                pygame.draw.polygon(screen,CAVE_MID,
                    [(sx2-10,base_y),(sx2+10,base_y),(sx2,tip_y)],1)

    def draw_hud(score, high_score, started, game_over):
        pygame.draw.rect(screen,HUD_C,(0,0,WIDTH,50))
        pygame.draw.line(screen,(60,60,80),(0,50),(WIDTH,50),1)
        sc = font.render(str(score),True,WHITE)
        screen.blit(sc,(WIDTH//2-sc.get_width()//2,8))
        hi = small_font.render(f"Best: {high_score}",True,GOLD)
        screen.blit(hi,(10,15))
        if not started and not game_over:
            hint = small_font.render("Hold SPACE or click to fly!",True,(180,180,200))
            screen.blit(hint,(WIDTH//2-hint.get_width()//2,HEIGHT//2+40))

    running = True
    while running:
        clock.tick(60)
        for event in pygame.event.get():
            if event.type == pygame.QUIT: running = False
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE: running = False
                elif event.key in (pygame.K_SPACE, pygame.K_UP):
                    if game_over:
                        heli,segs,score,game_over,started,high_score,new_high,thrusting = reset(high_score)
                    else: started = True
                elif event.key == pygame.K_r and game_over:
                    heli,segs,score,game_over,started,high_score,new_high,thrusting = reset(high_score)
            if event.type == pygame.MOUSEBUTTONDOWN:
                if game_over:
                    heli,segs,score,game_over,started,high_score,new_high,thrusting = reset(high_score)
                else: started = True

        keys         = pygame.key.get_pressed()
        mouse_pressed= pygame.mouse.get_pressed()[0]
        thrusting    = started and not game_over and (keys[pygame.K_SPACE] or keys[pygame.K_UP] or mouse_pressed)

        if started and not game_over:
            heli["vy"] += THRUST if thrusting else GRAVITY
            heli["vy"]  = max(-MAX_VY, min(MAX_VY, heli["vy"]))
            heli["y"]  += heli["vy"]
            current_speed = SCROLL_SPEED + min(score*0.04, 2.5)
            for seg in segs: seg["x"] -= current_speed
            if segs and segs[0]["x"]+SEGMENT_W < 0:
                segs.pop(0)
                last = segs[-1]
                segs.append(make_segment(last["top"],last["bot"],last["x"]+SEGMENT_W,score))
            for seg in segs:
                if not seg.get("scored") and seg["x"]+SEGMENT_W < heli["x"]:
                    seg["scored"] = True; score += 1
            hrect = heli_hit_rect(heli)
            if hrect.top < PLAY_TOP or hrect.bottom > PLAY_BOTTOM:
                game_over = True
                if save_high_score(GAME_NAME, score):
                    new_high = True
                high_score = get_high_score(GAME_NAME)
            for seg in segs:
                if segment_blocks_heli(seg, hrect):
                    game_over = True
                    if save_high_score(GAME_NAME, score):
                        new_high = True
                    high_score = get_high_score(GAME_NAME)
                    break

        screen.fill(SKY_C)
        draw_cave(segs)
        draw_helicopter(heli, thrusting)
        draw_hud(score, high_score, started, game_over)

        if game_over:
            ov = pygame.Surface((WIDTH,HEIGHT),pygame.SRCALPHA)
            ov.fill((0,0,0,155)); screen.blit(ov,(0,0))
            go  = font.render("CRASHED!",True,RED)
            sc_t= font.render(f"Score: {score}",True,WHITE)
            rst = small_font.render("SPACE / R / click to retry  |  ESC to menu",True,WHITE)
            screen.blit(go, (WIDTH//2-go.get_width()//2,   HEIGHT//2-80))
            screen.blit(sc_t,(WIDTH//2-sc_t.get_width()//2,HEIGHT//2-24))
            screen.blit(rst, (WIDTH//2-rst.get_width()//2, HEIGHT//2+20))
            if new_high:
                nb = font.render("NEW BEST!",True,YELLOW)
                screen.blit(nb,(WIDTH//2-nb.get_width()//2,HEIGHT//2+55))

        pygame.display.flip()

    pygame.quit(); sys.exit()
