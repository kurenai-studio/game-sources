
import pygame, sys, random, csv, os, time, math
from battle_engine import WEAPON_NAMES, WEAPON_MAP, resolve_round
from ai_agent import AIAgent

pygame.init()
WIDTH, HEIGHT = 1400, 768
WIN = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Archery Combat Strategy Game - AI Enhanced")

# Optimized fonts for better screen fit
TITLE_FONT = pygame.font.SysFont("Arial", 24, bold=True)
HEAD_FONT = pygame.font.SysFont("Arial", 20, bold=True)
FONT = pygame.font.SysFont("Arial", 16)
SMALL = pygame.font.SysFont("Arial", 12)
BIG = pygame.font.SysFont("Arial", 20, bold=True)
HUGE = pygame.font.SysFont("Arial", 36, bold=True)

CLOCK = pygame.time.Clock()
FPS = 60

# Enhanced color scheme
BG = (8, 12, 18)
PANEL = (20, 24, 32)
ACCENT = (64, 144, 212)
WHITE = (245, 245, 245)
GREEN = (76, 175, 80)
RED = (244, 67, 54)
YELLOW = (255, 193, 7)
HIGHLIGHT = (255, 152, 0)
GRAY = (120, 120, 130)
LOG_BG = (15, 19, 26)
DARK_BG = (5, 8, 12)

# Elemental color accents for UI badges and effects
ELEMENT_COLORS = {
    "Fire": (235, 87, 87),
    "Ice": (142, 209, 252),
    "Water": (80, 170, 240),
    "Electric": (255, 220, 92),
    "Air": (180, 220, 255),
    "Earth": (169, 132, 88),
    "Toxin": (140, 210, 90),
    "Dark": (150, 100, 180),
    "Light": (255, 245, 170),
    "Chaos": (255, 120, 200),
    "Spirit": (170, 255, 210),
    "Metal": (180, 200, 210),
}

def get_element_color(elem):
    return ELEMENT_COLORS.get(elem, ACCENT)

# Fixed layout - proper proportions
LEFT_W = 690  # Reasonable player panel width
RIGHT_W = 690  # Compact AI panel
CENTER_W =WIDTH-40  # Fixed center width for battle area
LEFT_X = 20
CENTER_X =20
RIGHT_X = LEFT_X + LEFT_W  +15 # 20 + 690 = 710, no gap

# Panel heights - balanced layout
PANEL_H = 320  # Reasonable panel height
BATTLE_AREA_H = 300  # Compact battle area
LOG_H =80

# Main panels

LOG_PANEL = pygame.Rect(LEFT_X, 20, WIDTH - 40, LOG_H)
BATTLE_PANEL = pygame.Rect(CENTER_X, LOG_PANEL.bottom + 10, CENTER_W, BATTLE_AREA_H)  # Full upper width
PLAYER_PANEL = pygame.Rect(LEFT_X, BATTLE_PANEL.bottom + 10, LEFT_W, PANEL_H)  # Lower left
AI_PANEL = pygame.Rect(RIGHT_X, BATTLE_PANEL.bottom + 10, RIGHT_W, PANEL_H)  # Lower right


RESET_BTN = pygame.Rect(RIGHT_X + RIGHT_W - 120, LOG_PANEL.y + 20, 100, 40)
NEXT_BTN = pygame.Rect(WIDTH // 2 - 100, PLAYER_PANEL.bottom - 10, 200, 50)  # Change +10 to -10 to move up




# Inventory layout - show all 15 arrows in 5x3 grid with larger boxes
INV_START_X = PLAYER_PANEL.x + 20
INV_START_Y = PLAYER_PANEL.y + 60
INV_W, INV_H = 120,70  # Larger cards for better text display
GAP_X, GAP_Y = 15,15  # More spacing between cards

MAX_ROUNDS = 20
round_no = 1
scroll_offset = 0
ARROWS_PER_PAGE = 15  # Show all arrows in 5x3 grid

agent = AIAgent()

# Game state management
class GameState:
    def __init__(self):
        self.phase = "player_pick"  # player_pick, animating, round_resolved, game_over
        self.selected_player_idxs = []
        self.round_logs = []  # Current round logs
        self.all_rounds = []  # All rounds history
        self.animation_timer = 0.0
        self.animation_duration = 3.0
        self.hover_idx = -1
        self.particles = []
        self.float_texts = []
        self.arrow_animations = []
        self.hp_animations = {"player": 0, "ai": 0}
        self.ai_prediction_display = ""
        self.log_scroll = 0  # Scroll offset for logs
        self.current_round_data = {}

game_state = GameState()

# Animation classes
class ArrowAnimation:
    def __init__(self, start_x, start_y, end_x, end_y, color, element):
        self.start_x = start_x
        self.start_y = start_y
        self.end_x = end_x
        self.end_y = end_y
        self.current_x = start_x
        self.current_y = start_y
        self.color = color
        self.element = element
        self.progress = 0.0
        self.speed = 0.02
        self.active = True
        
    def update(self):
        if self.progress < 1.0:
            self.progress += self.speed
            t = self.progress
            # Smooth easing
            t = t * t * (3.0 - 2.0 * t)
            self.current_x = self.start_x + (self.end_x - self.start_x) * t
            self.current_y = self.start_y + (self.end_y - self.start_y) * t
        else:
            self.active = False

class HPAnimation:
    def __init__(self, target_hp, current_hp, duration=1.0):
        self.start_hp = current_hp
        self.target_hp = target_hp
        self.duration = duration
        self.timer = 0.0
        self.active = True
        
    def update(self, dt):
        self.timer += dt
        if self.timer >= self.duration:
            self.active = False
            return self.target_hp
        
        t = self.timer / self.duration
        t = t * t * (3.0 - 2.0 * t)  # Smooth easing
        return self.start_hp + (self.target_hp - self.start_hp) * t

def draw_panel(rect, title, subtitle=""):
    # Enhanced panel with gradient effect
    pygame.draw.rect(WIN, PANEL, rect, border_radius=12)
    pygame.draw.rect(WIN, ACCENT, (rect.x, rect.y, rect.width, 40), border_radius=12)
    
    # Title
    title_surface = TITLE_FONT.render(title, True, WHITE)
    WIN.blit(title_surface, (rect.x + 15, rect.y + 8))
    
    # Subtitle if provided
    if subtitle:
        subtitle_surface = SMALL.render(subtitle, True, (200, 200, 200))
        WIN.blit(subtitle_surface, (rect.x + 15, rect.y + 35))

def draw_button(rect, label, hover=False, enabled=True):
    if not enabled:
        base = (60, 60, 70)
        text_color = (120, 120, 120)
    else:
        base = (70, 140, 200) if not hover else (90, 160, 220)
        text_color = WHITE
    
    shadow = pygame.Rect(rect.x, rect.y + 3, rect.width, rect.height)
    pygame.draw.rect(WIN, (20, 30, 40), shadow, border_radius=10)
    pygame.draw.rect(WIN, base, rect, border_radius=10)
    txt = BIG.render(label, True, text_color)
    WIN.blit(txt, (rect.centerx - txt.get_width()//2, rect.centery - txt.get_height()//2))

def draw_hp(x, y, hp, width=250, height=24, label="HP"):
    # Background
    pygame.draw.rect(WIN, (40, 40, 50), (x, y, width, height), border_radius=12)
    
    # HP bar
    frac = max(0, min(1, hp/200.0))
    hp_width = int(width * frac)
    if hp_width > 0:
        color = GREEN if frac > 0.3 else (RED if frac > 0.1 else (100, 0, 0))
        pygame.draw.rect(WIN, color, (x, y, hp_width, height), border_radius=12)
    
    # Border
    pygame.draw.rect(WIN, (80, 80, 90), (x, y, width, height), 2, border_radius=12)
    
    # Text
    hp_text = f"{label}: {int(hp)}/200"
    text_surface = SMALL.render(hp_text, True, WHITE)
    WIN.blit(text_surface, (x + 8, y + 4))

def reset_match():
    # draw 15 random arrows from the 30 pool for this match (shared pool)
    all_arrows = WEAPON_NAMES.copy()
    random.shuffle(all_arrows)
    match_pool = all_arrows[:30]
    player_deck = all_arrows[:15]
    random.shuffle(all_arrows)
    ai_deck = all_arrows[:15]
    player_hp = 200
    ai_hp = 200
    return player_hp, ai_hp, player_deck, ai_deck, match_pool

player_hp, ai_hp, player_deck, ai_deck, match_pool = reset_match()
match_id = int(time.time())

# Game initialized successfully

def add_round_log(line, color=WHITE):
    game_state.round_logs.append((line, color))

def add_global_log(line, color=WHITE):
    # Add to current round and global history
    game_state.round_logs.append((line, color))

def clear_round():
    """Reset UI selection state between rounds"""
    global scroll_offset
    game_state.selected_player_idxs = []
    # Save current round logs to history
    if game_state.round_logs:
        game_state.all_rounds.append({
            "round": round_no,
            "logs": game_state.round_logs.copy()
        })
    game_state.round_logs = []
    
    # clamp scroll_offset so page stays valid
    try:
        deck_len = len(player_deck)
    except NameError:
        deck_len = len(match_pool)
    if scroll_offset + ARROWS_PER_PAGE > deck_len:
        scroll_offset = max(0, deck_len - ARROWS_PER_PAGE)

def save_human_log(match_id, round_no, remaining, picks, ai_picks, player_hp, ai_hp, filename="human_game_log.csv"):
    file_exists = os.path.isfile(filename)
    with open(filename, "a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow(["Match_ID", "Round", "Remaining_Pool", "Player_Picks", "AI_Picks", "Player_HP", "AI_HP"])
        writer.writerow([match_id, round_no, "|".join(remaining), "|".join(picks), "|".join(ai_picks), player_hp, ai_hp])

def render_inventory(inv, selected_idxs, start_x=INV_START_X, start_y=INV_START_Y):
    start_y +=0  # Move down to avoid HP bar
    visible_inv = inv[scroll_offset:scroll_offset + ARROWS_PER_PAGE]
    
    for idx, name in enumerate(visible_inv):
        col = idx % 5  # 5 columns to fit all arrows
        row = idx // 5
        x = start_x + col * (INV_W + GAP_X)
        y = start_y + row * (INV_H + GAP_Y)
        r = pygame.Rect(x, y, INV_W, INV_H)
        
        # card base
        pygame.draw.rect(WIN, (62, 64, 74), r, border_radius=12)
        
        # hover effect
        global_selected = scroll_offset + idx
        if global_selected == game_state.hover_idx:
            pygame.draw.rect(WIN, (120, 120, 140), r, 3, border_radius=12)
        
        if global_selected in selected_idxs:
            pygame.draw.rect(WIN, HIGHLIGHT, r, 4, border_radius=12)
        
        # title and stats - better spacing
        elem = WEAPON_MAP[name]['Element']
        dmg = WEAPON_MAP[name]['Damage']
        
        # Arrow name (truncate if too long) - allow longer names with larger boxes
        display_name = name
        if len(name) > 18:
            display_name = name[:15] + "..."
        lbl = FONT.render(f"{global_selected + 1}. {display_name}", True, WHITE)
        WIN.blit(lbl, (x + 8, y + 8))
        
        # Damage stat
        stat = SMALL.render(f"DMG: {dmg}", True, (210, 210, 210))
        WIN.blit(stat, (x + 10, y + 30))
        
        # elemental badge - better positioned
        badge_r = pygame.Rect(x + r.width - 70, y + r.height -20, 60, 18)
        col = get_element_color(elem)
        pygame.draw.rect(WIN, col, badge_r, border_radius=10)
        etxt = SMALL.render(elem, True, (20, 20, 22))
        WIN.blit(etxt, (badge_r.x + badge_r.width//2 - etxt.get_width()//2, badge_r.y + 2))
    
    # up/down arrows - positioned for 3-column layout
    if scroll_offset > 0:
        up_btn = pygame.Rect(start_x + 3 * INV_W + 3 * GAP_X, start_y, 50, 50)
        pygame.draw.rect(WIN, ACCENT, up_btn, border_radius=10)
        WIN.blit(FONT.render("↑", True, WHITE), (up_btn.x + 18, up_btn.y + 12))
    
    if scroll_offset + ARROWS_PER_PAGE < len(inv):
        down_btn = pygame.Rect(start_x + 3 * INV_W + 3 * GAP_X, start_y + 2 * (INV_H + GAP_Y), 50, 50)
        pygame.draw.rect(WIN, ACCENT, down_btn, border_radius=10)
        WIN.blit(FONT.render("↓", True, WHITE), (down_btn.x + 18, down_btn.y + 12))

def spawn_particles(center_x, center_y, color, count=24, speed=3.0):
    for _ in range(count):
        ang = random.uniform(0, 6.283)
        mag = random.uniform(0.6, 1.0) * speed
        vx = mag * math.cos(ang)
        vy = mag * math.sin(ang)
        game_state.particles.append({
            "x": float(center_x),
            "y": float(center_y),
            "vx": vx,
            "vy": vy,
            "life": random.uniform(0.6, 1.0),
            "size": random.randint(2, 4),
            "color": color
        })

def add_float_text(x, y, text, color):
    game_state.float_texts.append({"x": float(x), "y": float(y), "text": text, "color": color, "vy": -0.6, "life": 1.4})

def update_fx(dt):
    # particles
    i = 0
    while i < len(game_state.particles):
        p = game_state.particles[i]
        p["x"] += p["vx"]
        p["y"] += p["vy"]
        p["vy"] += 0.03  # slight gravity
        p["life"] -= dt
        if p["life"] <= 0:
            game_state.particles.pop(i)
        else:
            i += 1
    
    # float texts
    j = 0
    while j < len(game_state.float_texts):
        t = game_state.float_texts[j]
        t["y"] += t["vy"]
        t["life"] -= dt
        if t["life"] <= 0:
            game_state.float_texts.pop(j)
        else:
            j += 1
    
    # arrow animations
    k = 0
    while k < len(game_state.arrow_animations):
        arrow = game_state.arrow_animations[k]
        arrow.update()
        if not arrow.active:
            game_state.arrow_animations.pop(k)
        else:
            k += 1

def draw_fx():
    for p in game_state.particles:
        pygame.draw.circle(WIN, p["color"], (int(p["x"]), int(p["y"])), p["size"])
    
    for t in game_state.float_texts:
        alpha = max(0, min(255, int(255 * (t["life"] / 1.4))))
        surf = BIG.render(t["text"], True, t["color"])
        surf.set_alpha(alpha)
        WIN.blit(surf, (int(t["x"]) - surf.get_width()//2, int(t["y"])))
    
    # Draw arrow animations
    for arrow in game_state.arrow_animations:
        if arrow.active:
            # Draw arrow as a line with arrowhead
            start_pos = (int(arrow.current_x), int(arrow.current_y))
            # Simple arrow representation
            pygame.draw.circle(WIN, arrow.color, start_pos, 8)
            # Arrow trail effect
            trail_length = 20
            trail_x = arrow.current_x - trail_length * math.cos(arrow.progress * math.pi)
            trail_y = arrow.current_y - trail_length * math.sin(arrow.progress * math.pi)
            pygame.draw.line(WIN, arrow.color, (int(trail_x), int(trail_y)), start_pos, 3)

def draw_battle_area():
    """Draw the central battle area with animations and detailed info"""
    pygame.draw.rect(WIN, DARK_BG, BATTLE_PANEL, border_radius=15)
    pygame.draw.rect(WIN, ACCENT, BATTLE_PANEL, 3, border_radius=15)
    
    # Battle area title
    title = HEAD_FONT.render("BATTLE ARENA", True, WHITE)
    WIN.blit(title, (BATTLE_PANEL.centerx - title.get_width()//2, BATTLE_PANEL.y + 10))
    
    if game_state.phase == "animating":
        # Show animation progress
        progress = game_state.animation_timer / game_state.animation_duration
        progress_text = FONT.render(f"Clash in progress... {progress*100:.0f}%", True, YELLOW)
        WIN.blit(progress_text, (BATTLE_PANEL.centerx - progress_text.get_width()//2, BATTLE_PANEL.centery - 20))
        
        # Draw collision point
        collision_x = BATTLE_PANEL.centerx
        collision_y = BATTLE_PANEL.centery
        pygame.draw.circle(WIN, WHITE, (collision_x, collision_y), 12)
        pygame.draw.circle(WIN, YELLOW, (collision_x, collision_y), 8)
    
    elif game_state.phase == "round_resolved" and game_state.current_round_data:
        # Show round results with more detail
        data = game_state.current_round_data
        y_pos = BATTLE_PANEL.y + 40
        
        result_text = ""
        result_color = WHITE
        
        if data['winner'] == "Player":
            result_text = "PLAYER WINS!"
            result_color = GREEN
        elif data['winner'] == "AI":
            result_text = "AI WINS!"
            result_color = RED
        else:
            result_text = "ROUND TIED!"
            result_color = YELLOW
        
        result_surface = BIG.render(result_text, True, result_color)
        WIN.blit(result_surface, (BATTLE_PANEL.centerx - result_surface.get_width()//2, y_pos))
        y_pos += 30

         # Add base damages (new lines here)
        base_text = f"Player Base: {data.get('player_base', 0):.0f} | AI Base: {data.get('ai_base', 0):.0f}"
        base_surface = FONT.render(base_text, True, WHITE)
        WIN.blit(base_surface, (BATTLE_PANEL.centerx - base_surface.get_width()//2, y_pos))
        y_pos += 25  # Space for next content
            
        # Show power comparison
        power_text = f"Player: {data['player_power']:.1f} vs AI: {data['ai_power']:.1f}"
        power_surface = FONT.render(power_text, True, WHITE)
        WIN.blit(power_surface, (BATTLE_PANEL.centerx - power_surface.get_width()//2, y_pos))
        y_pos += 25
        
        # Show damage dealt
        if data['damage_to_ai'] > 0:
            dmg_text = f"AI takes {int(data['damage_to_ai'])} damage"
            dmg_surface = FONT.render(dmg_text, True, GREEN)
            WIN.blit(dmg_surface, (BATTLE_PANEL.centerx - dmg_surface.get_width()//2, y_pos))
        elif data['damage_to_player'] > 0:
            dmg_text = f"Player takes {int(data['damage_to_player'])} damage"
            dmg_surface = FONT.render(dmg_text, True, RED)
            WIN.blit(dmg_surface, (BATTLE_PANEL.centerx - dmg_surface.get_width()//2, y_pos))

        
        max_lines = 10  # Limit to fit in battle panel
        start_idx = max(0, len(game_state.round_logs) - max_lines)
        for i in range(start_idx, len(game_state.round_logs)):
            if y_pos + 18 <= BATTLE_PANEL.bottom:  # Clamp to panel
                text, color = game_state.round_logs[i]
                lbl = SMALL.render(text, True, color)
                WIN.blit(lbl, (BATTLE_PANEL.x + 15, y_pos))
                y_pos += 18
        
    
    else:
        # Show game instructions
        inst_text = "Select 3 arrows and commit to battle!"
        inst_surface = FONT.render(inst_text, True, WHITE)
        WIN.blit(inst_surface, (BATTLE_PANEL.centerx - inst_surface.get_width()//2, BATTLE_PANEL.centery - 10))

def draw_ai_prediction():
    """Draw AI prediction information"""
    if game_state.ai_prediction_display:
        pred_x = AI_PANEL.x + 20
        pred_y = AI_PANEL.y + 100
        
        # AI prediction panel
        pred_rect = pygame.Rect(pred_x, pred_y, AI_PANEL.width - 40, 80)
        pygame.draw.rect(WIN, (30, 40, 50), pred_rect, border_radius=8)
        pygame.draw.rect(WIN, (50, 70, 100), pred_rect, 2, border_radius=8)
        
        pred_title = SMALL.render("AI PREDICTION", True, YELLOW)
        WIN.blit(pred_title, (pred_x + 10, pred_y + 5))
        
        pred_text = SMALL.render(game_state.ai_prediction_display, True, WHITE)
        WIN.blit(pred_text, (pred_x + 10, pred_y + 25))

# Buttons

# Adjust buttons


# Log scroll buttons
LOG_SCROLL_UP = pygame.Rect(LOG_PANEL.x + LOG_PANEL.width - 50, LOG_PANEL.y + 30, 30, 25)
LOG_SCROLL_DOWN = pygame.Rect(LOG_PANEL.x + LOG_PANEL.width - 50, LOG_PANEL.y + LOG_PANEL.height - 30, 30, 25)

running = True
while running:
    dt = CLOCK.tick(FPS) / 1000.0  # Delta time in seconds
    
    for ev in pygame.event.get():
        if ev.type == pygame.QUIT:
            running = False
            break
        
        if ev.type == pygame.KEYDOWN:
            if ev.key == pygame.K_ESCAPE:
                running = False
                break
            elif ev.key == pygame.K_r:
                player_hp, ai_hp, player_deck, ai_deck, match_pool = reset_match()
                game_state.selected_player_idxs.clear()
                round_no = 1
                game_state.round_logs.clear()
                game_state.all_rounds.clear()
                game_state.phase = "player_pick"
        
        # Mouse wheel scrolling for logs
        if ev.type == pygame.MOUSEWHEEL:
            if LOG_PANEL.collidepoint(pygame.mouse.get_pos()):
                game_state.log_scroll = max(0, min(game_state.log_scroll + ev.y, len(game_state.round_logs) - 20))
        
        if ev.type == pygame.MOUSEMOTION and game_state.phase == "player_pick":
            # track hover index for inventory
            mx, my = ev.pos
            game_state.hover_idx = -1
            visible_inv = player_deck[scroll_offset:scroll_offset + ARROWS_PER_PAGE]
            for idx, _name in enumerate(visible_inv):
                col = idx % 5
                row = idx // 5
                x = INV_START_X + col * (INV_W + GAP_X)
                y = INV_START_Y + row * (INV_H + GAP_Y)
                r = pygame.Rect(x, y, INV_W, INV_H)
                if r.collidepoint((mx, my)):
                    game_state.hover_idx = scroll_offset + idx
                    break
        
        if ev.type == pygame.MOUSEBUTTONDOWN:
            mx, my = ev.pos
            
            if game_state.phase == "player_pick":
                visible_inv = player_deck[scroll_offset:scroll_offset + ARROWS_PER_PAGE]
                for idx, name in enumerate(visible_inv):
                    col = idx % 5
                    row = idx // 5
                    x = INV_START_X + col * (INV_W + GAP_X)
                    y = INV_START_Y + row * (INV_H + GAP_Y)
                    r = pygame.Rect(x, y, INV_W, INV_H)
                    if r.collidepoint((mx, my)):
                        global_idx = scroll_offset + idx
                        if global_idx in game_state.selected_player_idxs:
                            game_state.selected_player_idxs.remove(global_idx)
                            add_round_log(f"Deselected: {player_deck[global_idx]}")
                        else:
                            if len(game_state.selected_player_idxs) < 3:
                                game_state.selected_player_idxs.append(global_idx)
                                add_round_log(f"Selected: {player_deck[global_idx]}")
                            else:
                                add_round_log("Select only 3 arrows to commit this round.", YELLOW)
                
                if NEXT_BTN.collidepoint((mx, my)):
                    if len(game_state.selected_player_idxs) != 3:
                        add_round_log("You must select exactly 3 arrows before committing.", YELLOW)
                
                # Log scroll button clicks
                if LOG_SCROLL_UP.collidepoint((mx, my)) and game_state.log_scroll > 0:
                    game_state.log_scroll = max(0, game_state.log_scroll - 5)
                elif LOG_SCROLL_DOWN.collidepoint((mx, my)) and game_state.log_scroll < len(game_state.round_logs) - 20:
                    game_state.log_scroll = min(len(game_state.round_logs) - 20, game_state.log_scroll + 5)
                
                if NEXT_BTN.collidepoint((mx, my)) and len(game_state.selected_player_idxs) == 3:
                    # Prepare player choice
                    player_choice = [player_deck[i] for i in game_state.selected_player_idxs]
                    add_round_log(f"Round {round_no} — Player committed: {', '.join(player_choice)}", GREEN)
                    
                    # AI prediction and choice
                    predicted_proba = agent.predict_player_probs(player_deck)
                    ai_choice = agent.pick_ai_combo(ai_deck, player_deck, player_probs=predicted_proba)
                    
                    # Display AI prediction
                    if agent.model is not None:
                        game_state.ai_prediction_display = f"Using trained ML model for prediction"
                        model_status = "TRAINED MODEL"
                    else:
                        game_state.ai_prediction_display = f"Using heuristic prediction (no model trained)"
                        model_status = "HEURISTIC"
                    
                    # Add AI model details to log (condensed)
                    add_round_log(f"AI Analysis: {model_status} | Deck: {len(player_deck)} arrows | Confidence: {max(predicted_proba):.2f}", YELLOW)
                    
                    add_round_log(f"AI committed: {', '.join(ai_choice)}", RED)
                    
                    # Resolve round
                    details = resolve_round(player_choice, ai_choice, debug=True)
                    game_state.current_round_data = details
                    
                    # Add detailed calculations to log for teaching
                    add_round_log("=" * 50, WHITE)
                    add_round_log("DETAILED BATTLE CALCULATIONS:", YELLOW)
                    add_round_log("=" * 50, WHITE)
                    
                    # Player combo analysis - ensure we have the debug data
                    add_round_log(f"PLAYER COMBO: {', '.join(player_choice)}", GREEN)
                    player_base = details.get('player_base', 0)
                    player_syn = details.get('player_syn', 1.0)
                    player_elem_eff = details.get('player_elem_eff', 1.0)
                    player_power = details['player_power']
                    
                    add_round_log(f"  Base Damage: {player_base:.0f}", WHITE)
                    add_round_log(f"  Synergy Multiplier: {player_syn:.2f}x", WHITE)
                    add_round_log(f"  Element Effectiveness: {player_elem_eff:.2f}x", WHITE)
                    add_round_log(f"  Calculation: {player_base:.0f} × {player_syn:.2f} × {player_elem_eff:.2f} = {player_power:.1f}", GREEN)
                    add_round_log(f"  Final Power: {player_power:.1f}", GREEN)
                    
                    # AI combo analysis - ensure we have the debug data
                    add_round_log(f"AI COMBO: {', '.join(ai_choice)}", RED)
                    ai_base = details.get('ai_base', 0)
                    ai_syn = details.get('ai_syn', 1.0)
                    ai_elem_eff = details.get('ai_elem_eff', 1.0)
                    ai_power = details['ai_power']
                    
                    add_round_log(f"  Base Damage: {ai_base:.0f}", WHITE)
                    add_round_log(f"  Synergy Multiplier: {ai_syn:.2f}x", WHITE)
                    add_round_log(f"  Element Effectiveness: {ai_elem_eff:.2f}x", WHITE)
                    add_round_log(f"  Calculation: {ai_base:.0f} × {ai_syn:.2f} × {ai_elem_eff:.2f} = {ai_power:.1f}", RED)
                    add_round_log(f"  Final Power: {ai_power:.1f}", RED)
                    
                    # Power comparison
                    power_diff = abs(player_power - ai_power)
                    add_round_log(f"Power Difference: {power_diff:.1f}", YELLOW)
                    add_round_log(f"SUMMARY: Player {player_power:.1f} vs AI {ai_power:.1f}", YELLOW)
                    
                    # Explain synergy and effectiveness
                    add_round_log("SYNERGY EXPLANATION:", YELLOW)
                    player_elems = [WEAPON_MAP[name]['Element'] for name in player_choice]
                    ai_elems = [WEAPON_MAP[name]['Element'] for name in ai_choice]
                    add_round_log(f"  Player elements: {', '.join(player_elems)}", WHITE)
                    add_round_log(f"  AI elements: {', '.join(ai_elems)}", WHITE)
                    
                    # Explain synergy types (using already extracted variables)
                    
                    if player_syn >= 2.0:
                        add_round_log(f"  Player: MONO-ELEMENT COMBO ({player_syn:.1f}x)", GREEN)
                    elif player_syn >= 1.8:
                        add_round_log(f"  Player: PERFECT SYNERGY CHAIN ({player_syn:.1f}x)", GREEN)
                    elif player_syn >= 1.4:
                        add_round_log(f"  Player: PARTIAL SYNERGY ({player_syn:.1f}x)", GREEN)
                    elif player_syn >= 1.3:
                        add_round_log(f"  Player: FOCUS COMBO ({player_syn:.1f}x)", GREEN)
                    elif player_syn <= 0.6:
                        add_round_log(f"  Player: ELEMENTAL CLASH ({player_syn:.1f}x)", RED)
                    
                    if ai_syn >= 2.0:
                        add_round_log(f"  AI: MONO-ELEMENT COMBO ({ai_syn:.1f}x)", RED)
                    elif ai_syn >= 1.8:
                        add_round_log(f"  AI: PERFECT SYNERGY CHAIN ({ai_syn:.1f}x)", RED)
                    elif ai_syn >= 1.4:
                        add_round_log(f"  AI: PARTIAL SYNERGY ({ai_syn:.1f}x)", RED)
                    elif ai_syn >= 1.3:
                        add_round_log(f"  AI: FOCUS COMBO ({ai_syn:.1f}x)", RED)
                    elif ai_syn <= 0.6:
                        add_round_log(f"  AI: ELEMENTAL CLASH ({ai_syn:.1f}x)", GREEN)
                    
                    add_round_log("ELEMENT EFFECTIVENESS:", YELLOW)
                    add_round_log(f"  Player vs AI effectiveness: {details.get('player_elem_eff', 1.0):.2f}x", WHITE)
                    add_round_log(f"  AI vs Player effectiveness: {details.get('ai_elem_eff', 1.0):.2f}x", WHITE)
                    
                    add_round_log("=" * 50, WHITE)
                    
                    # Start animation phase
                    game_state.phase = "animating"
                    game_state.animation_timer = 0
                    
                    # Create arrow animations
                    battle_center_x = BATTLE_PANEL.centerx
                    battle_center_y = BATTLE_PANEL.centery
                    
                    # Player arrows (from left)
                    for i, arrow_name in enumerate(player_choice):
                        elem = WEAPON_MAP[arrow_name]["Element"]
                        color = get_element_color(elem)
                        start_x = PLAYER_PANEL.centerx
                        start_y = PLAYER_PANEL.y + 50 + i * 20
                        game_state.arrow_animations.append(
                            ArrowAnimation(start_x, start_y, battle_center_x, battle_center_y, color, elem)
                            )
                        
                        # AI arrows (from right)
                        for i, arrow_name in enumerate(ai_choice):
                            elem = WEAPON_MAP[arrow_name]["Element"]
                            color = get_element_color(elem)
                            start_x = AI_PANEL.centerx
                            start_y = AI_PANEL.y + 50 + i * 20
                            game_state.arrow_animations.append(
                                ArrowAnimation(start_x, start_y, battle_center_x, battle_center_y, color, elem)
                            )
                
                if RESET_BTN.collidepoint((mx, my)):
                    player_hp, ai_hp, player_deck, ai_deck, match_pool = reset_match()
                    game_state.selected_player_idxs.clear()
                    round_no = 1
                    game_state.round_logs.clear()
                    game_state.all_rounds.clear()
                    game_state.phase = "player_pick"
            
            elif game_state.phase == "round_resolved":
                if NEXT_BTN.collidepoint((mx, my)):
                    # End conditions
                    if player_hp <= 0 or ai_hp <= 0 or len(player_deck) < 3 or round_no >= MAX_ROUNDS:
                        game_state.phase = "game_over"
                    else:
                        round_no += 1
                        clear_round()
                        game_state.phase = "player_pick"
                        game_state.ai_prediction_display = ""
                
                if RESET_BTN.collidepoint((mx, my)):
                    player_hp, ai_hp, player_deck, ai_deck, match_pool = reset_match()
                    game_state.selected_player_idxs.clear()
                    round_no = 1
                    game_state.round_logs.clear()
                    game_state.all_rounds.clear()
                    game_state.phase = "player_pick"
            
            elif game_state.phase == "game_over":
                if RESET_BTN.collidepoint((mx, my)):
                    player_hp, ai_hp, player_deck, ai_deck, match_pool = reset_match()
                    game_state.selected_player_idxs.clear()
                    round_no = 1
                    game_state.round_logs.clear()
                    game_state.all_rounds.clear()
                    game_state.phase = "player_pick"
        
        if ev.type == pygame.MOUSEWHEEL:
            if game_state.phase == "player_pick":
                if ev.y > 0 and scroll_offset > 0:
                    scroll_offset = max(0, scroll_offset - ARROWS_PER_PAGE)
                elif ev.y < 0 and scroll_offset + ARROWS_PER_PAGE < len(player_deck):
                    scroll_offset = min(max(0, len(player_deck) - ARROWS_PER_PAGE), scroll_offset + ARROWS_PER_PAGE)
            # Log scrolling
            if LOG_PANEL.collidepoint(pygame.mouse.get_pos()):
                game_state.log_scroll = max(0, min(game_state.log_scroll + ev.y, len(game_state.round_logs) - 20))
    
    # Update game state
    if game_state.phase == "animating":
        game_state.animation_timer += dt
        if game_state.animation_timer >= game_state.animation_duration:
            # Animation complete, apply damage and show results
            details = game_state.current_round_data
            if details['winner'] == "Player":
                dmg = int(details['damage_to_ai'])
                ai_hp = max(0, ai_hp - dmg)
                add_round_log(f"Result: Player stronger → AI -{dmg} HP", GREEN)
                add_float_text(AI_PANEL.centerx, AI_PANEL.centery, f"-{dmg}", RED)
            elif details['winner'] == "AI":
                dmg = int(details['damage_to_player'])
                player_hp = max(0, player_hp - dmg)
                add_round_log(f"Result: AI stronger → Player -{dmg} HP", RED)
                add_float_text(PLAYER_PANEL.centerx, PLAYER_PANEL.centery, f"-{dmg}", RED)
            else:
                add_round_log("Result: Tie — no HP change", YELLOW)
            
            # Remove used arrows
            for w in details['player_combo']:
                if w in player_deck:
                    player_deck.remove(w)
            for w in details['ai_combo']:
                if w in ai_deck:
                    ai_deck.remove(w)
            
            # Save logs
            save_human_log(match_id, round_no, match_pool, details['player_combo'], details['ai_combo'], player_hp, ai_hp)
            
            # Clamp scroll offset
            if scroll_offset + ARROWS_PER_PAGE > len(player_deck):
                scroll_offset = max(0, len(player_deck) - ARROWS_PER_PAGE)
            
            game_state.phase = "round_resolved"
    
    # Update effects
    update_fx(dt)
    
    # DRAWING
    WIN.fill(BG)
    
    # Draw main panels
    draw_panel(PLAYER_PANEL, "PLAYER", f"Select 3 arrows ({len(game_state.selected_player_idxs)}/3)")
    draw_panel(AI_PANEL, "AI OPPONENT", "Hidden strategy")
    draw_panel(LOG_PANEL, "BATTLE LOG", f"Round {round_no} - {len(game_state.all_rounds)} rounds completed")
    
    # Draw HP bars
    draw_hp(PLAYER_PANEL.x + 150, PLAYER_PANEL.y + 8, player_hp, 300, 24, "Player HP")  # In header, right of title
    draw_hp(AI_PANEL.x + 150, AI_PANEL.y + 8, ai_hp, 300, 24, "AI HP")
    
    # Draw inventory (only in player panel)
    if game_state.phase == "player_pick":
        render_inventory(player_deck, game_state.selected_player_idxs)
    
    # Draw battle area
    draw_battle_area()
    
    # Draw AI prediction
    draw_ai_prediction()
    
    # Draw buttons
    mx, my = pygame.mouse.get_pos()
    next_hover = NEXT_BTN.collidepoint((mx, my))
    next_enabled = (game_state.phase == "player_pick" and len(game_state.selected_player_idxs) == 3) or game_state.phase == "round_resolved"
    
    if game_state.phase == "player_pick":
        button_text = "COMMIT ROUND"
    elif game_state.phase == "round_resolved":
        button_text = "NEXT ROUND"
    else:
        button_text = "COMMIT"
    
    draw_button(NEXT_BTN, button_text, hover=next_hover, enabled=next_enabled)
    
    # Draw reset button
    reset_hover = RESET_BTN.collidepoint((mx, my))
    draw_button(RESET_BTN, "RESET", hover=reset_hover)
    
    # Draw log scroll buttons
    up_hover = LOG_SCROLL_UP.collidepoint((mx, my))
    down_hover = LOG_SCROLL_DOWN.collidepoint((mx, my))
    draw_button(LOG_SCROLL_UP, "↑", hover=up_hover, enabled=game_state.log_scroll > 0)
    draw_button(LOG_SCROLL_DOWN, "↓", hover=down_hover, enabled=game_state.log_scroll < len(game_state.round_logs) - 20)
    
    # Draw scrollable logs
    y = LOG_PANEL.y + 60
    max_lines = min(20, len(game_state.round_logs))  # Show up to 20 lines
    start_idx = max(0, len(game_state.round_logs) - max_lines - game_state.log_scroll)
    end_idx = len(game_state.round_logs) - game_state.log_scroll
    
    for i in range(start_idx, end_idx):
        if i >= 0 and i < len(game_state.round_logs):
            text, color = game_state.round_logs[i]
            lbl = SMALL.render(text, True, color)
            if y + lbl.get_height() <= LOG_PANEL.bottom:
                WIN.blit(lbl, (LOG_PANEL.x + 15, y))
    
    # Draw effects
    draw_fx()
    
    # Game over overlay
    if game_state.phase == "game_over" or player_hp <= 0 or ai_hp <= 0 or round_no > MAX_ROUNDS:
        overlay = pygame.Surface((WIDTH, HEIGHT))
        overlay.set_alpha(220)
        overlay.fill((10, 10, 12))
        WIN.blit(overlay, (0, 0))
        
        if player_hp > ai_hp:
            res = HUGE.render("PLAYER WINS!", True, GREEN)
        elif ai_hp > player_hp:
            res = HUGE.render("AI WINS!", True, RED)
        else:
            res = HUGE.render("GAME OVER - DRAW", True, WHITE)
        
        WIN.blit(res, (WIDTH // 2 - res.get_width() // 2, HEIGHT // 2 - 60))
        sub = FONT.render("Press RESET or R to restart.", True, WHITE)
        WIN.blit(sub, (WIDTH // 2 - sub.get_width() // 2, HEIGHT // 2 + 20))
    
    pygame.display.flip()

pygame.quit()
sys.exit()
