# Pixel art definitions for Pixel TD. Each sprite is a list of rows; each char maps to a palette colour.
# '.' = transparent. An outline is added automatically around opaque pixels.
from PIL import Image

PAL = {
    'outline': (24, 20, 37),
}

C = {  # Endesga-32 inspired palette
    'red': (228, 59, 68), 'dred': (162, 38, 51), 'maroon': (115, 62, 57),
    'orange': (247, 118, 34), 'gold': (254, 174, 52), 'yellow': (254, 231, 97),
    'lgreen': (99, 199, 77), 'green': (62, 137, 72), 'dgreen': (38, 92, 66), 'xdgreen': (25, 60, 62),
    'dblue': (18, 78, 137), 'blue': (0, 153, 219), 'cyan': (44, 232, 245), 'white': (255, 255, 255),
    'lgray': (192, 203, 220), 'gray': (139, 155, 180), 'dgray': (90, 105, 136), 'xdgray': (58, 68, 102),
    'navy': (38, 43, 68), 'black': (24, 20, 37), 'pink': (246, 117, 122), 'purple': (104, 56, 108),
    'magenta': (181, 80, 136), 'skin': (232, 183, 150), 'dskin': (194, 133, 105), 'tan': (228, 166, 114),
    'brown': (184, 111, 80), 'dbrown': (115, 62, 57), 'xdbrown': (62, 39, 49), 'sand': (234, 212, 170),
    'rust': (190, 74, 47), 'lorange': (215, 118, 67),
}


# shaded tones used by the detailed (v0.1) characters
C['skin_l'] = (246, 214, 180)
C['skin_d'] = (194, 133, 105)
C['skin_dd'] = (150, 95, 80)
C['hat_l'] = (184, 111, 80)
C['hat'] = (138, 78, 62)
C['hat_d'] = (92, 48, 48)
C['den_l'] = (60, 120, 190)
C['den'] = (36, 82, 150)
C['den_d'] = (26, 52, 100)
C['stl_l'] = (232, 238, 248)
C['stl'] = (176, 188, 210)
C['stl_d'] = (116, 130, 160)
C['stl_dd'] = (70, 80, 112)
C['blu_l'] = (60, 170, 230)
C['blu'] = (24, 112, 190)
C['blu_d'] = (18, 70, 130)
C['gld_l'] = (255, 236, 120)
C['gld'] = (240, 180, 50)
C['gld_d'] = (180, 110, 40)
C['olv_l'] = (150, 170, 80)
C['olv'] = (100, 125, 60)
C['olv_d'] = (62, 82, 46)
C['olv_dd'] = (40, 52, 36)
C['tan_l'] = (220, 196, 140)
C['tan_m'] = (176, 150, 100)
C['tan_d'] = (124, 100, 70)
C['org_l'] = (255, 170, 70)
C['org'] = (240, 120, 30)
C['org_d'] = (180, 70, 30)
C['red_l'] = (240, 90, 90)
C['red_m'] = (200, 45, 55)
C['red_d'] = (130, 30, 45)
C['gun_l'] = (200, 210, 225)
C['gun'] = (110, 120, 145)
C['gun_d'] = (60, 66, 90)
C['wd'] = (130, 80, 50)
C['wd_d'] = (85, 50, 35)
C['glass'] = (120, 230, 245)
C['glass_d'] = (40, 140, 180)


def make(rows, cmap, outline=True, ocol=None):
    h = len(rows)
    w = max(len(r) for r in rows)
    pad = 1 if outline else 0
    img = Image.new('RGBA', (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    px = img.load()
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch == '.' or ch == ' ':
                continue
            col = cmap[ch]
            if isinstance(col, str):
                col = C[col]
            px[x + pad, y + pad] = tuple(col) + (255,) if len(col) == 3 else tuple(col)
    if outline:
        oc = ocol or C['black']
        src = img.copy().load()
        W, H = img.size
        for y in range(H):
            for x in range(W):
                if src[x, y][3] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < W and 0 <= ny < H and src[nx, ny][3] > 0:
                            px[x, y] = oc + (255,)
                            break
    return img


# ---------------------------------------------------------------- TOWERS (face right)
GUNNER = [
    "....................",
    "........hhh.........",
    ".......hHHHH........",
    "......hHHHHHd.......",
    "......HHHHHHd.......",
    "......rrrrrrd.......",
    "...BBBBBBBBBBBBB....",
    "....ddddddddddd.....",
    "......kfFFFFF.......",
    "......kFFFFeF.......",
    "......kFFFFFFn......",
    "......kfzFFFz.......",
    ".......fzzzz........",
    "......RRRRRRR.......",
    ".....wVVRRRVVv......",
    "....wwVVWWWVvFFlgggG",
    "....wWVVWWWVvFFGGgg.",
    "....FfVVWWWVv...G...",
    ".....vVVWWWVV.......",
    ".....LLLLyLLLx......",
    ".....jjJ..jjJx......",
    ".....jjJ..jjJ.......",
    ".....oooO.oooO......",
    "....ooooy.ooooy.....",
]
GUNNER_C = {'h': 'hat_l', 'H': 'hat', 'd': 'hat_d', 'r': 'red_m', 'B': 'hat', 'k': 'xdbrown', 'F': 'skin', 'f': 'skin_d', 'e': 'black', 'n': 'skin_d', 'z': 'skin_dd', 'R': 'red_l', 'V': 'hat_l', 'v': 'hat_d', 'w': 'sand', 'W': 'tan_l', 'l': 'gun_l', 'g': 'gun', 'G': 'gun_d', 'L': 'xdbrown', 'y': 'gld', 'x': 'hat', 'j': 'den', 'J': 'den_d', 'o': 'hat', 'O': 'hat_d'}
GUNNER_ELITE = {'h': 'xdgray', 'H': 'navy', 'd': 'black', 'r': 'gld', 'B': 'navy', 'k': 'xdbrown', 'F': 'skin', 'f': 'skin_d', 'e': 'black', 'n': 'skin_d', 'z': 'skin_dd', 'R': 'gld_l', 'V': 'purple', 'v': 'black', 'w': 'sand', 'W': 'tan_l', 'l': 'gld_l', 'g': 'gld', 'G': 'gld_d', 'L': 'xdbrown', 'y': 'gld', 'x': 'navy', 'j': 'den', 'J': 'den_d', 'o': 'navy', 'O': 'black'}

KNIGHT = [
    "........RR..........",
    ".......RrRR.....w...",
    ".......Rr.......wW..",
    "......aaaa......wW..",
    ".....aAAAAs.....wW..",
    ".....AAAAAAs....wW..",
    ".....AAAvvvs....wW..",
    ".....AAAAAAs....wW..",
    "......sAAAs.....wW..",
    "....pPPgggPPp...wW..",
    "..ccc.TTTTTPPp..wW..",
    ".cCCCc.TTyTTPaGYYYG.",
    "cCCyCCcTyyyTPaQAAb..",
    "cCyyyCcTTyTTPa..b...",
    "cCCyCCcTTTTTt.......",
    ".cCCCc.TTTTTt.......",
    "..ccc..MMMMMM.......",
    ".......mMmMmM.......",
    ".......LLl.LLl......",
    ".......LLl.LLl......",
    ".......LLl.LLl......",
    "......DDDd.DDDd.....",
    "......DDDd.DDDd.....",
    "....................",
]
KNIGHT_C = {'R': 'red_m', 'r': 'red_l', 'w': 'stl_l', 'W': 'stl', 'a': 'stl_l', 'A': 'stl', 's': 'stl_d', 'v': 'black', 'p': 'stl_l', 'P': 'stl_d', 'g': 'stl_dd', 'c': 'gld_d', 'C': 'blu', 'y': 'gld_l', 'T': 'blu', 't': 'blu_d', 'G': 'gld_d', 'Y': 'gld', 'Q': 'stl', 'b': 'wd', 'M': 'stl_d', 'm': 'stl_dd', 'L': 'stl', 'l': 'stl_d', 'D': 'stl_d', 'd': 'stl_dd'}
KNIGHT_ELITE = {'R': 'glass', 'r': 'red_l', 'w': 'glass', 'W': 'blu_l', 'a': 'gld_l', 'A': 'gld', 's': 'gld_d', 'v': 'black', 'p': 'gld_l', 'P': 'gld_d', 'g': 'stl_dd', 'c': 'gld_d', 'C': 'red_m', 'y': 'gld_l', 'T': 'red_m', 't': 'red_d', 'G': 'gld_d', 'Y': 'gld', 'Q': 'stl', 'b': 'wd', 'M': 'gld_d', 'm': 'stl_dd', 'L': 'gld', 'l': 'gld_d', 'D': 'gld_d', 'd': 'hat_d'}

FLAMER = [
    "....................",
    "....................",
    ".......HHHHH........",
    "......HhHHHHH.......",
    ".....HhHHHHHHd......",
    ".....HHHmmmHHd......",
    ".nn..HHmgGmgGd......",
    "tTTt.HHmGgmGgd......",
    "tTTt.HHHmmmmHd......",
    "tTTt..dHmffmd.......",
    "tYYt.SSSSccSSS......",
    "tYYtSSsSSSSSSSs.....",
    "tTTtSSsSSSSSSAAnnnnq",
    "tTTtSSsSSSSSSAAnNNNQ",
    "tTTt.SskykykyS......",
    ".tt..SsSSSSSSs......",
    ".....WWWWWWWWW......",
    ".....SSS..SSS.......",
    ".....SSs..SSs.......",
    ".....SSs..SSs.......",
    ".....BBB..BBB.......",
    "....BBBBb.BBBBb.....",
    "....................",
    "....................",
]
FLAMER_C = {'H': 'org', 'h': 'org_l', 'd': 'org_d', 'm': 'gun_d', 'g': 'glass', 'G': 'glass_d', 'f': 'gun', 't': 'red_d', 'T': 'red_m', 'S': 'org', 's': 'org_d', 'c': 'gld', 'A': 'xdbrown', 'n': 'gun', 'N': 'gun_d', 'W': 'xdbrown', 'B': 'xdbrown', 'b': 'black', 'Y': 'gld', 'q': 'yellow', 'Q': 'org_l', 'k': 'black', 'y': 'gld'}
FLAMER_ELITE = {'H': 'stl', 'h': 'stl_l', 'd': 'stl_d', 'm': 'gun_d', 'g': 'org_l', 'G': 'org_d', 'f': 'gun', 't': 'blu_d', 'T': 'blu', 'S': 'stl', 's': 'stl_d', 'c': 'glass', 'A': 'xdbrown', 'n': 'gun', 'N': 'gun_d', 'W': 'xdbrown', 'B': 'xdbrown', 'b': 'black', 'Y': 'glass', 'q': 'glass', 'Q': 'blu_l', 'k': 'black', 'y': 'gld'}

# enemies and friendly vehicles live in units.py (three views each)

# ---------------------------------------------------------------- DECOR
TREE = [
    "....gggggg....",
    "..ggGGGGGGgg..",
    ".gGGGGGGGGGGg.",
    "gGGGGGlGGGGGGg",
    "gGGlGGGGGGGlGg",
    "gGGGGGGGGGGGGg",
    "dGGGGGGGlGGGGd",
    ".dGGlGGGGGGGd.",
    "..ddGGGGGGdd..",
    "....ddddddd...",
    "......TT......",
    "......TT......",
    ".....TTTT.....",
]
TREE_C = {'g': 'lgreen', 'G': 'green', 'l': 'lgreen', 'd': 'dgreen', 'T': 'dbrown'}

BUSH = [
    "..gggg..",
    ".gGGGGg.",
    "gGGlGGGg",
    "gGGGGlGg",
    ".dddddd.",
]
BUSH_C = {'g': 'lgreen', 'G': 'green', 'l': 'lgreen', 'd': 'dgreen'}

ROCK = [
    "...llll...",
    "..lLLLLg..",
    ".lLLLLLLg.",
    "lLLLLLLLgg",
    "gggggggggg",
]
ROCK_C = {'l': 'lgray', 'L': 'gray', 'g': 'dgray'}

PINE = [
    "......g.......",
    ".....gGg......",
    "....gGGGg.....",
    "...gGGGGGd....",
    ".....GGG......",
    "...gGGGGGg....",
    "..gGGGGGGGd...",
    "....GGGGG.....",
    "..gGGGGGGGd...",
    ".gGGGGGGGGGd..",
    "gGGGGGGGGGGGd.",
    "......T.......",
    ".....TTT......",
]
PINE_C = {'g': 'green', 'G': 'dgreen', 'd': 'xdgreen', 'T': 'dbrown'}
SNOW_PINE_C = {'g': 'white', 'G': 'dgreen', 'd': 'xdgreen', 'T': 'dbrown'}

CACTUS = [
    "....gg....",
    "...gGGg...",
    "...gGGg.g.",
    "g..gGGg.Gg",
    "Gg.gGGg.Gg",
    "GgggGGgggg",
    ".gGGGGGG..",
    "...gGGg...",
    "...gGGg...",
    "...gGGg...",
    "..dddddd..",
]
CACTUS_C = {'g': 'lgreen', 'G': 'green', 'd': 'tan'}

SKULL = [
    ".wwww.",
    "wwwwww",
    "wbwwbw",
    "wwwwww",
    ".w.w..",
]
SKULL_C = {'w': 'sand', 'b': 'black'}

SNOWMAN = [
    "...hhh...",
    "..hhhhh..",
    ".hhhhhhh.",
    "..wwwww..",
    "..wbwbw..",
    "..wwoow..",
    "...www...",
    ".rrrrrrr.",
    ".wwwwwww.",
    "wwwwbwwww",
    "wwwwwwwww",
    "wwwwbwwww",
    ".wwwwwww.",
]
SNOWMAN_C = {'h': 'black', 'w': 'white', 'b': 'black', 'o': 'orange', 'r': 'red'}

ICE_BLOCK = [
    ".cccccc.",
    "cwwccccb",
    "cwccccbb",
    "cccccccb",
    "ccccccbb",
    ".bbbbbb.",
]
ICE_BLOCK_C = {'c': 'cyan', 'w': 'white', 'b': 'blue'}

PUMP = [
    "..RRRRRRR.",
    "..RwwwwwR.",
    "..RwBBBwR.",
    "..RwwwwwR.",
    "..RRRRRRRh",
    "..RyyyyyR.h",
    "..RRRRRRR.h",
    "..RRRRRRR.h",
    "..RRRRRRRh.",
    "..RRRRRRR..",
    ".ggggggggg.",
]
PUMP_C = {'R': 'red', 'w': 'white', 'B': 'navy', 'y': 'yellow', 'h': 'black', 'g': 'gray'}

BARREL = [
    ".bbbbbb.",
    "bBBBBBBb",
    "yyyyyyyy",
    "bBBBBBBb",
    "bBBBBBBb",
    "yyyyyyyy",
    ".bbbbbb.",
]
BARREL_C = {'b': 'dblue', 'B': 'blue', 'y': 'yellow'}

TIRES = [
    ".kkkkkk.",
    "kKggggKk",
    ".kkkkkk.",
    "kKggggKk",
    ".kkkkkk.",
    "kKggggKk",
    ".kkkkkk.",
]
TIRES_C = {'k': 'black', 'K': 'xdgray', 'g': 'dgray'}

CONE = [
    "..o..",
    "..o..",
    ".www.",
    ".ooo.",
    "ooooo",
]
CONE_C = {'o': 'orange', 'w': 'white'}

CAR_RED = [
    "......WWWWWWWWW.........",
    ".....WcccWccccWW........",
    "....WccccWcccccWW.......",
    "..BBBBBBBBBBBBBBBBBBBB..",
    ".BBBBBBBBBBBBBBBBBBBBBy.",
    "BBBBBBBBBBBBBBBBBBBBBBBy",
    "BrrBBkkkkBBBBBBBkkkkBBBB",
    ".rr.kkggkk.....kkggkk...",
    "....kkggkk.....kkggkk...",
    ".....kkkk.......kkkk....",
]
CAR_C = {'W': 'dred', 'c': 'cyan', 'B': 'red', 'y': 'yellow', 'r': 'dred', 'k': 'black', 'g': 'gray'}
CAR_BLUE_C = dict(CAR_C, W='dblue', B='blue', r='dblue')

LAVA_ROCK = [
    "...kkkk...",
    "..kKKoKk..",
    ".kKKKKoKk.",
    "kKoKKKKKKk",
    "kkkkkkkkkk",
]
LAVA_ROCK_C = {'k': 'black', 'K': 'xdgray', 'o': 'orange'}

CRYSTAL = [
    "...c....",
    "..cCc.c.",
    "..cCc.Cc",
    ".ccCcCc.",
    ".cCCcCc.",
    "ccCCCCcc",
    ".pppppp.",
]
CRYSTAL_C = {'c': 'magenta', 'C': 'pink', 'p': 'purple'}

DEAD_TREE = [
    "..b...b..",
    "..bb.bb..",
    "b..bbb..b",
    "bb..b..bb",
    ".bbbbbbb.",
    "....b....",
    "....b....",
    "....b....",
    "...bbb...",
]
DEAD_TREE_C = {'b': 'xdbrown'}

# gas station props
LAMP = [
    "hhhhh",
    "hyyyh",
    ".hhh.",
    "..p..",
    "..p..",
    "..p..",
    "..p..",
    "..p..",
    "..p..",
    "..p..",
    "..p..",
    "..p..",
    "..p..",
    "..p..",
    "..p..",
    ".ppp.",
    "ppppp",
]
LAMP_C = {'h': 'dgray', 'y': 'yellow', 'p': 'xdgray'}

HYDRANT = [
    "..rr..",
    ".rllr.",
    "rrrrrr",
    ".rlrr.",
    "rrlrrr",
    ".rlrr.",
    ".rrrr.",
    "dddddd",
]
HYDRANT_C = {'r': 'red_m', 'l': 'red_l', 'd': 'red_d'}

TRASH = [
    ".gggggg.",
    "gGGGGGGg",
    ".dddddd.",
    ".gGlGGg.",
    ".gGlGGg.",
    ".gGlGGg.",
    ".gGGGGg.",
    ".dddddd.",
]
TRASH_C = {'g': 'green', 'G': 'dgreen', 'l': 'lgreen', 'd': 'xdgreen'}

DUMPSTER = [
    "..bbbbbbbbbbbbbbbbbb..",
    ".bBBBBBBBBBBBBBBBBBBb.",
    "gggggggggggggggggggggg",
    "gGGGGGGGGGGGGGGGGGGGGg",
    "gGGlGGGGlGGGGlGGGGlGGg",
    "gGGlGGGGlGGGGlGGGGlGGg",
    "gGGGGGGGGGGGGGGGGGGGGg",
    "dddddddddddddddddddddd",
    ".kk................kk.",
]
DUMPSTER_C = {'b': 'xdgreen', 'B': 'dgreen', 'g': 'green', 'G': 'dgreen', 'l': 'green', 'd': 'xdgreen', 'k': 'black'}

# swamp props
REEDS = [
    ".b....b..",
    ".b..b.b..",
    ".b..b.b.b",
    ".g..b.g.b",
    "g.g.g.g.g",
    "g.g.gg.g.",
    ".gg.g.gg.",
    "..ggggg..",
    "..ddddd..",
]
REEDS_C = {'b': 'wd_d', 'g': 'olv_l', 'd': 'olv_d'}

MUSHROOM = [
    "..rrrr..",
    ".rwrrwr.",
    "rrrrrrwr",
    "rwrrrrrr",
    "..ssss..",
    "...ss...",
    "...ss...",
]
MUSHROOM_C = {'r': 'red_m', 'w': 'white', 's': 'sand'}

LOG = [
    "..bbbbbbbbbb..",
    ".bBBBbBBBBBBtt",
    "bBBBBBBBbBBtTt",
    "bBbBBBBBBBBtTt",
    ".dddddddddddtt",
    "..g.....g.....",
]
LOG_C = {'b': 'wd', 'B': 'brown', 't': 'tan', 'T': 'wd', 'd': 'wd_d', 'g': 'olv_l'}

# graveyard props
TOMB = [
    "..ssss..",
    ".sSSSSs.",
    "sSSSSSSs",
    "sSkkkkSs",
    "sSSSSSSs",
    "sSkkkSSs",
    "sSSSSSSs",
    "sSSSSSSs",
    "dddddddd",
]
TOMB_C = {'s': 'gray', 'S': 'lgray', 'k': 'dgray', 'd': 'dgray'}

TOMB_CROSS = [
    "..sS..",
    "..sS..",
    "ssSSss",
    "sSSSSs",
    "..sS..",
    "..sS..",
    "..sS..",
    "..sS..",
    ".dddd.",
]
TOMB_CROSS_C = {'s': 'gray', 'S': 'lgray', 'd': 'dgray'}

PUMPKIN = [
    "...g....",
    "...gg...",
    ".ooOooo.",
    "oOoOoOoo",
    "oykOOkyo",
    "oOOkkOOo",
    "oOkOkOko",
    ".ooOooo.",
]
PUMPKIN_C = {'g': 'olv', 'o': 'org_d', 'O': 'org', 'k': 'black', 'y': 'yellow'}

AUTUMN_TREE_C = {'g': 'red_l', 'G': 'red_m', 'l': 'gld', 'd': 'red_d', 'T': 'xdbrown'}
SWAMP_TREE_C = {'g': 'olv_l', 'G': 'olv', 'l': 'olv_l', 'd': 'olv_d', 'T': 'xdbrown'}

# acid refinery
TOXIC_BARREL = [
    "..gG.....",
    ".bbgbbbb.",
    "bYYYYYYyb",
    "bkkkkkkkb",
    "bYYYYYYyb",
    "bYYgYYYyb",
    "bYYgYYYyb",
    "bkkgkkkkb",
    "bYYYYYYyb",
    ".bbbbbbb.",
    "..ggG....",
]
TOXIC_BARREL_C = {'b': 'dbrown', 'Y': 'gold', 'y': 'lorange', 'k': 'xdbrown', 'g': 'lgreen', 'G': 'green'}
ACID_BARREL = [
    ".........",
    ".bbbbbbb.",
    "bGGGGGGgb",
    "bGwGGGGgb",
    "bgggggggb",
    "bGGGGGGgb",
    "bGwGGGGgb",
    "bgggggggb",
    "bGGGGGGgb",
    ".bbbbbbb.",
]
ACID_BARREL_C = {'b': 'xdgreen', 'G': 'green', 'g': 'dgreen', 'w': 'lgreen'}
PIPE = [
    "...rrr......",
    "....s.......",
    "pPPPsPPPPPPp",
    "pLLLLLLLLLLp",
    "pPPPPPPPPPPp",
    "pdddddddddPp",
    "dd.......ddd",
]
PIPE_C = {'r': 'red', 's': 'dgray', 'p': 'xdgray', 'P': 'gray', 'L': 'lgray', 'd': 'dgray'}
def _big_barrel(W=30, H=40):
    """Huge yellow drum: lid, ribs, a white hazard label (black triangle with "!"), acid over the lid, a puddle."""
    r = [['.'] * W for _ in range(H)]
    top, bot = 4, H - 3
    for y in range(top, bot):
        for x in range(1, W - 1):
            r[y][x] = 'y' if x <= 4 else ('o' if x >= W - 6 else 'Y')
    for x in range(3, W - 3):              # lid
        r[top - 2][x] = 'd'
        r[top - 1][x] = 'y' if x < W - 6 else 'Y'
    for x in (1, 2, W - 3, W - 2):
        r[top - 1][x] = 'd'
    for y in (top + 6, bot - 6):           # ribs
        for x in range(1, W - 1):
            r[y][x] = 'd'
    lx0, ly0 = 7, top + 10                 # white label with a warning triangle
    for y in range(ly0, ly0 + 13):
        for x in range(lx0, lx0 + 16):
            r[y][x] = 'w'
    tri = ["......k......",
           ".....kkk.....",
           ".....kYk.....",
           "....kYkYk....",
           "....kYkYk....",
           "...kYYkYYk...",
           "...kYYkYYk...",
           "..kYYYYYYYk..",
           "..kYYYkYYYk..",
           ".kYYYYYYYYYk.",
           "kkkkkkkkkkkkk"]
    for dy, row in enumerate(tri):
        for dx, ch in enumerate(row):
            if ch != '.':
                r[ly0 + 1 + dy][lx0 + 1 + dx] = ch
    for x in range(6, 18):                 # acid spilling over the lid and running down
        r[top - 3][x] = 'g'
        r[top - 2][x] = 'G' if x % 3 else 'g'
    for y in range(top - 1, top + 9):
        r[y][8] = 'G'
        r[y][9] = 'g'
    for y in range(top - 1, top + 4):
        r[y][15] = 'G'
    for x in range(2, 18):                 # puddle at the foot
        r[bot][x] = 'G'
        r[bot + 1][x] = 'g' if x % 4 else 'G'
    return [''.join(row) for row in r]


BIG_BARREL = _big_barrel()
BIG_BARREL_C = {'Y': 'gold', 'y': 'yellow', 'o': 'lorange', 'd': 'xdbrown', 'w': 'white', 'k': 'black',
                'g': 'green', 'G': 'lgreen'}

TANK = [
    "......LLLLLLLLLLLLL.......",
    "...LLLsssssssssssssLLL....",
    "..LsssSSSSSSSSSSSSSsssL...",
    ".LssSSSSSSSSSSSSSSSSSssL..",
    ".LsSSSSSSSSSSSSSSSSSSSsLr.",
    "LsSSSSSSSSSSSSSSSSSSSSSsLr",
    "LdddddddddddddddddddddddLr",
    "LsSSSSSSSSSSSSSSSSSSSSSsLr",
    "LsSSSSSSSSyyyyySSSSSSSSsLr",
    "LsSSSSSSSyyGGGyySSSSSSSsLr",
    "LsSSSSSSSyGGGGGySSSSSSSsLr",
    "LsSSSSSSSyyGGGyySSSSSSSsLr",
    "LsSSSSSSSSyyyyySSSSSSSSsLr",
    "LsSSSSSSSSSSSSSSSSSSSSSsLr",
    "LdddddddddddddddddddddddLr",
    "LsSSSSSSSSSSSSSSSSSSSSSsLr",
    "LsSSSSSSSSSSSSSSSSSSSSSsLr",
    "LsSSSSSSSSSSSSSSSSSSSSSsLr",
    "LsSSSSSSSSSSSSSSSSSSSSSsLr",
    "LdddddddddddddddddddddddLr",
    "LsSSSSSSSSSSSSSSSSSSSSSsL.",
    ".LsSSSSSSSSSSSSSSSSSSSsL..",
    "..LLsssssssssssssssssLL...",
    "...kk.............kk......",
]
TANK_C = {'L': 'dgray', 's': 'gray', 'S': 'lgray', 'd': 'dgray', 'y': 'gold', 'k': 'black', 'G': 'lgreen',
          'r': 'xdgray'}

# farmlands
HAYSTACK = [
    "....yyy....",
    "..yyYyyy...",
    ".yYyyYyyy..",
    ".yyyYyyYy..",
    "yYyyyyYyyy.",
    "yyyYyyyyYy.",
    "ddddddddddd",
]
HAYSTACK_C = {'y': 'gold', 'Y': 'yellow', 'd': 'lorange'}
HAY_BALE = [
    "yyyyyyyy",
    "yYyyYyyY",
    "rrrrrrrr",
    "yyYyyyYy",
    "dddddddd",
]
HAY_BALE_C = {'y': 'gold', 'Y': 'yellow', 'r': 'red', 'd': 'lorange'}
SCARECROW = [
    "...hhh...",
    "..hhhhh..",
    "...sss...",
    "...sks...",
    "ttttttttt",
    "y.tRRRt.y",
    "..tRRRt..",
    "...RRR...",
    "...yby...",
    "....b....",
    "....b....",
    "....b....",
]
SCARECROW_C = {'h': 'hat', 's': 'sand', 'k': 'black', 't': 'tan', 'y': 'gold', 'R': 'red', 'b': 'wd_d'}

DECOR_SPRITES = {
    'haystack': (HAYSTACK, HAYSTACK_C), 'hay_bale': (HAY_BALE, HAY_BALE_C), 'scarecrow': (SCARECROW, SCARECROW_C),
    'toxic_barrel': (TOXIC_BARREL, TOXIC_BARREL_C), 'acid_barrel': (ACID_BARREL, ACID_BARREL_C),
    'pipe': (PIPE, PIPE_C), 'tank': (TANK, TANK_C), 'big_barrel': (BIG_BARREL, BIG_BARREL_C),
    'swamp_tree': (TREE, SWAMP_TREE_C), 'autumn_tree': (TREE, AUTUMN_TREE_C),
    'lamp': (LAMP, LAMP_C), 'hydrant': (HYDRANT, HYDRANT_C), 'trash': (TRASH, TRASH_C),
    'dumpster': (DUMPSTER, DUMPSTER_C), 'reeds': (REEDS, REEDS_C), 'mushroom': (MUSHROOM, MUSHROOM_C),
    'log': (LOG, LOG_C), 'tomb': (TOMB, TOMB_C), 'tomb_cross': (TOMB_CROSS, TOMB_CROSS_C),
    'pumpkin': (PUMPKIN, PUMPKIN_C),
    'tree': (TREE, TREE_C), 'bush': (BUSH, BUSH_C), 'rock': (ROCK, ROCK_C), 'pine': (PINE, PINE_C),
    'snow_pine': (PINE, SNOW_PINE_C), 'cactus': (CACTUS, CACTUS_C), 'skull': (SKULL, SKULL_C),
    'snowman': (SNOWMAN, SNOWMAN_C), 'ice_block': (ICE_BLOCK, ICE_BLOCK_C), 'pump': (PUMP, PUMP_C),
    'barrel': (BARREL, BARREL_C), 'tires': (TIRES, TIRES_C), 'cone': (CONE, CONE_C),
    'car_red': (CAR_RED, CAR_C), 'car_blue': (CAR_RED, CAR_BLUE_C), 'lava_rock': (LAVA_ROCK, LAVA_ROCK_C),
    'crystal': (CRYSTAL, CRYSTAL_C), 'dead_tree': (DEAD_TREE, DEAD_TREE_C),
}

# ---------------------------------------------------------------- ICONS (8x8, outlined -> 10x10)
ICONS = {
    'map': ([
        "tsTsstTs",
        "sgTssTrs",
        "ssTrrTss",
        "srTssTsx",
        "sggssTxs",
        "tsTsstTs",
    ], {'s': 'sand', 't': 'tan_l', 'T': 'tan', 'g': 'lgreen', 'r': 'red', 'x': 'red_d'}),
    'heart': ([
        ".RR.RR.",
        "RwRRRRR",
        "RRRRRRR",
        ".RRRRR.",
        "..RRR..",
        "...R...",
    ], {'R': 'red', 'w': 'white'}),
    'coin': ([
        ".yyyy.",
        "yYYYYy",
        "yYyYYy",
        "yYyYYy",
        "yYYYYy",
        ".yyyy.",
    ], {'y': 'gold', 'Y': 'yellow'}),
    'wave': ([
        "f......",
        "fRRRR..",
        "fRRRRR.",
        "fRRRR..",
        "f......",
        "f......",
    ], {'f': 'lgray', 'R': 'red'}),
    'lock': ([
        "..ggg..",
        ".g...g.",
        ".g...g.",
        "yyyyyyy",
        "yyYkYyy",
        "yyykyyy",
        "yyyyyyy",
    ], {'g': 'lgray', 'y': 'gold', 'Y': 'yellow', 'k': 'black'}),
    'star': ([
        "...y...",
        "..yYy..",
        "yyYYYyy",
        ".yYYYy.",
        ".yy.yy.",
    ], {'y': 'gold', 'Y': 'yellow'}),
    'star_off': ([
        "...g...",
        "..ggg..",
        "ggggggg",
        ".ggggg.",
        ".gg.gg.",
    ], {'g': 'xdgray'}),
    'play': ([
        "w....",
        "www..",
        "wwwww",
        "www..",
        "w....",
    ], {'w': 'white'}),
    'ff': ([
        "w...w...",
        "ww..ww..",
        "wwwwwwww",
        "ww..ww..",
        "w...w...",
    ], {'w': 'white'}),
    'pause': ([
        "ww.ww",
        "ww.ww",
        "ww.ww",
        "ww.ww",
        "ww.ww",
    ], {'w': 'white'}),
    'skull': ([
        ".wwww.",
        "wwwwww",
        "wkwwkw",
        "wwwwww",
        ".wkkw.",
    ], {'w': 'white', 'k': 'black'}),
    'shield': ([
        "ggggggg",
        "gBBwBBg",
        "gBBwBBg",
        "gwwwwwg",
        ".gBwBg.",
        "..gwg..",
        "...g...",
    ], {'g': 'gray', 'B': 'blue', 'w': 'white'}),
    'fire': ([
        "...r...",
        "..rr.r.",
        ".rroorr",
        "rrooyor",
        "royyyor",
        ".ryyyr.",
    ], {'r': 'red', 'o': 'orange', 'y': 'yellow'}),
    'boot': ([
        "..bbb.",
        "..bbb.",
        "..bbb.",
        "bbbbb.",
        "bbbbbb",
    ], {'b': 'brown'}),
    'sword': ([
        "......w",
        ".....w.",
        "....w..",
        "g..w...",
        ".gw....",
        ".bg....",
        "b..g...",
    ], {'w': 'white', 'g': 'gold', 'b': 'brown'}),
    'range': ([
        "..ggg..",
        ".g...g.",
        "g..w..g",
        "g.www.g",
        "g..w..g",
        ".g...g.",
        "..ggg..",
    ], {'g': 'cyan', 'w': 'white'}),
    'clock': ([
        ".wwww.",
        "wwkwww",
        "wwkwww",
        "wwkkww",
        "wwwwww",
        ".wwww.",
    ], {'w': 'white', 'k': 'black'}),
    'trophy': ([
        "yyyyyyy",
        "yYYYYYy",
        ".yYYYy.",
        "..yYy..",
        "...y...",
        "..yyy..",
        ".yyyyy.",
    ], {'y': 'gold', 'Y': 'yellow'}),
    'up': ([
        "...g...",
        "..ggg..",
        ".ggggg.",
        "ggggggg",
        "..ggg..",
        "..ggg..",
    ], {'g': 'lgreen'}),
    'target': ([
        "..rrr..",
        ".r...r.",
        "r..r..r",
        "r.rrr.r",
        "r..r..r",
        ".r...r.",
        "..rrr..",
    ], {'r': 'red'}),
    'gear': ([
        "..g.g..",
        ".ggggg.",
        "ggg.ggg",
        ".g...g.",
        "ggg.ggg",
        ".ggggg.",
        "..g.g..",
    ], {'g': 'lgray'}),
    'heal': ([
        "..g..",
        "..g..",
        "ggggg",
        "..g..",
        "..g..",
    ], {'g': 'lgreen'}),
}

# ---------------------------------------------------------------- v0.1 additions
SOLDIER = [
    "....................",
    "....................",
    "........hhhh........",
    "......hhHHHHH.......",
    ".....hHHHnHHHd......",
    ".....HHHHqQqQd......",
    ".....dddddddddd.....",
    "......kFFFFFF.......",
    "......kFFFeFF.......",
    "......kfFFFFFn......",
    ".......fzzzf........",
    "....BBOOOOOOO.......",
    "...BBbOoOOOoO.......",
    "...BBbOoOOOOOFtGGGGl",
    "...BBbOoOPPOOttGGG..",
    "...BBbOOOPPOOO..G...",
    "....bbOOOOOOOO......",
    ".....wwwwywwww......",
    ".....OOO..OOO.......",
    ".....OOo..OOo.......",
    ".....OOo..OOo.......",
    ".....KKK..KKK.......",
    "....KKKKk.KKKKk.....",
    "....................",
]
SOLDIER_C = {'q': 'glass', 'Q': 'glass_d', 'e': 'black', 'h': 'olv_l', 'H': 'olv', 'n': 'olv_l', 'd': 'olv_d', 'k': 'xdbrown', 'F': 'skin', 'f': 'skin_d', 'z': 'skin_dd', 'g': 'glass', 'G': 'gun_d', 'B': 'tan_m', 'b': 'tan_d', 'O': 'tan_l', 'o': 'tan_m', 'P': 'olv', 't': 'wd', 'T': 'wd_d', 'l': 'gun_l', 'w': 'olv_dd', 'y': 'gld', 'K': 'xdbrown'}
SOLDIER_ELITE = {'q': 'red_l', 'Q': 'red_d', 'e': 'black', 'h': 'xdgray', 'H': 'navy', 'n': 'xdgray', 'd': 'black', 'k': 'xdbrown', 'F': 'skin', 'f': 'skin_d', 'z': 'skin_dd', 'g': 'glass', 'G': 'gun_d', 'B': 'gun_d', 'b': 'black', 'O': 'gun', 'o': 'gun_d', 'P': 'navy', 't': 'gld', 'T': 'gld_d', 'l': 'gld_l', 'w': 'black', 'y': 'gld', 'K': 'xdbrown'}

# MINIGUNNER: bandana, shades and a six-barrel minigun at the hip
MINIGUN = [
    "....................",
    "....................",
    "........rrrr........",
    ".......rRRRRr.......",
    "......rRRRRRRr......",
    "......FFFFFFFrr.....",
    "......FkkkkkF.r.....",
    "......FFFFFFF.......",
    "......fFFzFFf.......",
    ".......fzzzf........",
    "....FFSSSSSSSFF.....",
    "...FFSSySSSySSFF....",
    "...FFSSSySySSSFF....",
    "...FFSSSSySSSGGGG...",
    "...fFSSSSSSGGGllllll",
    "....fSSSSSGGGGGGGGGG",
    ".....sssssGGGllllll.",
    ".....bbbbybbGGG.....",
    ".....OOO..OOO.......",
    ".....OOo..OOo.......",
    ".....OOo..OOo.......",
    ".....KKK..KKK.......",
    "....KKKKk.KKKKk.....",
    "....................",
]
MINIGUN_C = {'r': 'red_m', 'R': 'red_l', 'F': 'skin', 'f': 'skin_d', 'z': 'skin_dd', 'k': 'black', 'S': 'olv',
             's': 'olv_d', 'y': 'gld', 'G': 'gun_d', 'l': 'gun_l', 'b': 'xdbrown', 'O': 'tan_m', 'o': 'tan_d',
             'K': 'xdbrown'}
MINIGUN_ELITE = dict(MINIGUN_C, r='xdgray', R='gray', S='navy', s='black', G='gld_d', l='gld_l', y='red_l', O='gun',
                     o='gun_d')

SNIPER = [
    "....................",
    ".......g.g..........",
    "......gHHHHg........",
    ".....gHHHHHHh.......",
    "....hHHgHHHHHd......",
    "....HHHHHHgHHd......",
    "....HHkFFFFFFd......",
    "....HdkFFFFeF.......",
    "....HdkfFFPPFn......",
    "....Hd.fFFFFf.......",
    "...gHd..fzzz........",
    "..HHHHHCCCCCC.......",
    "..HgHHCCcCCCCwSSSo..",
    "..HHHCCCcCCCAAbbbbbL",
    "..HHgCCCcCCCAa.b....",
    "...HHCCCcCCCC.......",
    "...gHHWWWWyWW.......",
    "....HHCCC..CCC......",
    ".....hCCc..CCc......",
    "......CCc..CCc......",
    "......KKK..KKK......",
    ".....KKKKk.KKKKk....",
    "....................",
    "....................",
]
SNIPER_C = {'g': 'olv_l', 'h': 'olv_l', 'H': 'olv_d', 'd': 'olv_dd', 'k': 'olv_dd', 'F': 'skin', 'f': 'skin_d',
            'z': 'skin_dd', 'e': 'black', 'n': 'skin_d', 'P': 'olv_dd', 'C': 'tan_m', 'c': 'tan_d',
            'w': 'gun', 'S': 'gun_d', 'o': 'glass', 'A': 'xdbrown', 'a': 'wd', 'b': 'gun', 'L': 'gun_l',
            'W': 'xdbrown', 'y': 'gld', 'K': 'xdbrown'}
SNIPER_ELITE = dict(SNIPER_C, g='xdgray', h='xdgray', H='navy', d='black', k="black", P="black", C="gun",
                    c='gun_d', o='red_l', S='gld_d', w='gld', b='gld', L='gld_l', W='black')

NECRO = [
    "....................",
    "...............ggg..",
    "......hhh.....gGWGg.",
    ".....hHHHh....gGGGg.",
    "....hHHHHHh....ggg..",
    "....HHHHHHHd....s...",
    "....HHkkkkHd....s...",
    "....HHkekekd....s...",
    "....HHkkkkkd....s...",
    "....dHHkkkHd....s...",
    "...rRRHHHHHRr...s...",
    "..rRRRRRRRRRRfffs...",
    "..rRRRRrRRRRR..fs...",
    "..rRRRRrRRRRr...s...",
    "..rRRRbbbRRRr...s...",
    "..rRRRRrRRRRr...s...",
    "..rRRRRrRRRRRr..s...",
    ".rRRRRRrRRRRRr..s...",
    ".rRRRRRrRRRRRRr.s...",
    "rRRRRRRrRRRRRRRrs...",
    "rRRRRRRrRRRRRRRRs...",
    "rrrrrrrrrrrrrrrrS...",
    "....................",
    "....................",
]
NECRO_C = {'h': 'magenta', 'H': 'purple', 'd': (62, 30, 70), 'k': 'black', 'e': 'lgreen', 'r': (62, 30, 70),
           'R': 'purple', 'b': 'gld', 'f': 'lgray', 's': 'wd', 'S': 'wd_d', 'g': 'green', 'G': 'lgreen',
           'W': 'white'}
NECRO_ELITE = dict(NECRO_C, h='xdgray', H='navy', d='black', r='black', R='navy', b='gld_l', e='cyan', g='blu',
                   G='cyan', s='gld_d', S='gld_d')

FREEZER = [
    "....................",
    "....................",
    ".......wwwww........",
    "......wHHHHHw.......",
    ".....wHMMMMMMw......",
    ".....wMggMggMw......",
    ".....wHMMMMMMw......",
    ".ii...wHMCCMHw......",
    "tTTt..wwwwwww.......",
    "tLTt.JJJJJJJJJ......",
    "tLTtJjJJJJJJJJJ.....",
    "tLTtJjJJJJJJJAAnnnnq",
    "tTTtJjJJJJJJJAAnNNNQ",
    "tTTt.jkkkykkkJ......",
    "tTTt.jJJJJJJJJ......",
    ".tt..jJJJJJJJJ......",
    ".....PPPPPPPPP......",
    ".....PPP..PPP.......",
    ".....PPp..PPp.......",
    ".....PPp..PPp.......",
    ".....BBB..BBB.......",
    "....BBBBb.BBBBb.....",
    "....................",
    "....................",
]
FREEZER_C = {'w': 'white', 'H': 'blu', 'M': 'gun_d', 'C': 'gun', 'g': 'glass', 'i': 'gun',
             't': 'blu_d', 'T': 'glass_d', 'L': 'glass', 'J': 'blu_l', 'j': 'blu', 'k': 'black', 'y': 'gld',
             'A': 'navy', 'n': 'gun', 'N': 'gun_d', 'q': 'cyan', 'Q': 'blu_l', 'P': 'den', 'p': 'den_d',
             'B': 'xdbrown', 'b': 'black'}
# liquid nitrogen: steel dewar, white suit
FREEZER_ELITE = dict(FREEZER_C, H='stl', J='stl_l', j='stl', t='stl_dd', T='stl_d', L='white', g='cyan',
                     q='white', Q='stl_l', P='navy', p='black', y='cyan')

TOXIC = [
    "....................",
    "....................",
    ".......HHHHH........",
    "......HHHHHHH.......",
    ".....HHMMMMMHH......",
    ".....HMggMggMH......",
    ".....HMMMMMMMH......",
    "......HMcCcMH.......",
    "......HHMcMHH.......",
    ".....SSSSSSSSS......",
    "....SsSSSSSSSSS.....",
    "....SsSSSSSSAAnnnnnq",
    "....SsSSSSSSAAnGGNNQ",
    "....SskkkkkkkS.GG...",
    ".....sSSSSSSSS......",
    ".....sSSSSSSSS......",
    ".....PPPPPPPPP......",
    ".....PPP..PPP.......",
    ".....PPp..PPp.......",
    ".....PPp..PPp.......",
    ".....BBB..BBB.......",
    "....BBBBx.BBBBx.....",
    "....................",
    "....................",
]
TOXIC_C = {'H': 'gld_d', 'M': 'xdgray', 'g': 'lgreen', 'c': 'gun', 'C': 'gun_d', 'S': 'gld', 's': 'gld_d',
           'A': 'black', 'n': 'gun_d', 'N': 'xdgray', 'q': 'lgreen', 'Q': 'green', 'G': 'lgreen', 'k': 'black',
           'P': 'gld_d', 'p': 'hat_d', 'B': 'xdgray', 'x': 'black'}
# Toxic Overload: black hazmat suit, glowing acid
TOXIC_ELITE = dict(TOXIC_C, H='navy', S='xdgray', s='navy', P='navy', p='black', k='green', G=(170, 240, 100),
                   q=(170, 240, 100))

ASSASSIN = [
    "....................",
    "....................",
    "........hhhh........",
    ".......hHHHHh.......",
    "......hHHHHHHd......",
    "......HHkkkkHd......",
    "......HkEkkEkd......",
    "......HmmmmmmHd.....",
    ".......dmmmmd.......",
    ".....CCCCCCCCC......",
    "....CcCCCCCCCCC....w",
    "....CcCCbbCCCCAAwww.",
    "....CcCCCbCCCCAA....",
    "....CcCCCCbCCCC.....",
    "...CcCCCCCCbCCCC....",
    "...CcCCCCCCCbCCC....",
    "...cCCCCCCCCCCCCc...",
    "....PPPPPPPPPP......",
    ".....PPP..PPP.......",
    ".....PPp..PPp.......",
    ".....BBB..BBB.......",
    "....BBBBx.BBBBx.....",
    "....................",
    "....................",
]
ASSASSIN_C = {'h': 'olv_l', 'H': 'olv', 'd': 'olv_d', 'k': 'black', 'E': 'lgreen', 'm': 'olv_dd', 'C': 'olv',
              'c': 'olv_d', 'b': 'wd_d', 'A': 'black', 'w': 'lgray', 'P': 'olv_dd', 'p': 'black', 'B': 'xdbrown',
              'x': 'black'}
# Master Assassin: black cloak, poison-green blade
ASSASSIN_ELITE = dict(ASSASSIN_C, h='xdgray', H='navy', d='black', C='navy', c='black', m='black', P='black',
                      w='lgreen', b='green')

GARAGE = [
    "..RRRRRRRRRRRR..",
    ".RRRRRRRRRRRRRR.",
    "RrRRrRRrRRrRRrRR",
    "WWWWWWWWWWWWWWWW",
    "WWyyWWWWWWWWWWWW",
    "WDDDDDDDDDDDDDDW",
    "WddddddddddddddW",
    "WDDDDDDDDDDDDDDW",
    "WddddddddddddddW",
    "WDDDDDDDDDDDDDDW",
    "WddddddddddddddW",
    "WDDDDDDDDDDDDDDW",
    "gggggggggggggggg",
]
GARAGE_C = {'R': 'red', 'r': 'dred', 'W': 'lgray', 'y': 'gold', 'D': 'gray', 'd': 'dgray', 'g': 'xdgray'}
GARAGE_ELITE = dict(GARAGE_C, R='dblue', r='navy', W='sand', y='cyan', D='gold', d='lorange')

# FARM: a red barn and a patch of wheat (pays money every wave)
FARM = [
    "......rRRRRr........",
    ".....rRRRRRRr.......",
    "....rRRRwwRRRr......",
    "...rRRRRwwRRRRr.....",
    "..rRRRRRRRRRRRRr....",
    "..WWWWWWWWWWWWWW....",
    "..WRRRRRRRRRRRRW....",
    "..WRRRWWWWWWRRRW.y.y",
    "..WRRRWdWWdWRRRWyYyY",
    "..WRRRWWdWdWRRRWyYyY",
    "..WRRRWWWdWWRRRW.y.y",
    "..WRRRWWdWdWRRRWyYyY",
    "..WRRRWdWWdWRRRWyYyY",
    "..WRRRWWWWWWRRRWgggg",
    "gggggggggggggggggggg",
]
FARM_C = {'R': 'red', 'r': 'dred', 'W': 'white', 'w': 'sand', 'd': 'dbrown', 'y': 'gold', 'Y': 'yellow',
          'g': 'dgreen'}
FARM_ELITE = dict(FARM_C, R='gld', r='gld_d', W='white', w='white', d='red', y='yellow', Y='white')

UP_ICONS = {
    # minigunner
    'bigger_drum': ([
        ".ggggg.",
        "gGyGyGg",
        "gyGyGyg",
        "gGyGyGg",
        ".ggggg.",
    ], {'g': 'gun_d', 'G': 'gun', 'y': 'gld'}),
    'hot_barrels': ([
        "ooooooo",
        "rrrrrr.",
        "ooooooo",
        "rrrrrr.",
        "ooooooo",
    ], {'o': 'org', 'r': 'red_m'}),
    'tungsten': ([
        "..ww...",
        ".wGGg..",
        "wGGGggg",
        ".wGGg..",
        "..ww...",
    ], {'w': 'white', 'G': 'gray', 'g': 'gld'}),
    'twin_barrels': ([
        "lllllll",
        "ggg....",
        "lllllll",
        "ggg....",
        "lllllll",
    ], {'l': 'gun_l', 'g': 'gun_d'}),
    'heavy_minigun': ([
        "..ggggg",
        "gggGGGl",
        "gGGGGGl",
        "gggGGGl",
        "..y.y..",
    ], {'g': 'gun_d', 'G': 'gun', 'l': 'gun_l', 'y': 'gld'}),
    'bullet_storm': ([
        "y.y.y.y",
        ".y.y.y.",
        "y.y.y.y",
        ".y.y.y.",
        "y.y.y.y",
    ], {'y': 'gld_l'}),
    # farm
    'bigger_fields': ([
        "y.y.y.y",
        "YyYyYyY",
        "y.y.y.y",
        "YyYyYyY",
        "ggggggg",
    ], {'y': 'gold', 'Y': 'yellow', 'g': 'dgreen'}),
    'barn': ([
        "..rrr..",
        ".rRRRr.",
        "rRRRRRr",
        "WRWWWRW",
        "WRWdWRW",
    ], {'r': 'dred', 'R': 'red', 'W': 'white', 'd': 'dbrown'}),
    'tractor': ([
        "...gg..",
        "...gGg.",
        "gGGGGGG",
        "kKk.kKk",
        ".k...k.",
    ], {'g': 'dgreen', 'G': 'lgreen', 'k': 'black', 'K': 'gray'}),
    'irrigation': ([
        "...b...",
        "..bBb..",
        ".bBBBb.",
        ".bBwBb.",
        "..bbb..",
    ], {'b': 'dblue', 'B': 'blue', 'w': 'white'}),
    'greenhouse': ([
        "..ccc..",
        ".cCcCc.",
        "cCcCcCc",
        "cgCgCgc",
        "ggggggg",
    ], {'c': 'glass_d', 'C': 'glass', 'g': 'lgreen'}),
    'agro_empire': ([
        "y.y.y.y",
        "yyyyyyy",
        ".YYYYY.",
        "yyyyyyy",
        ".YYYYY.",
    ], {'y': 'gld_d', 'Y': 'gld_l'}),
    # v0.2 top tiers
    'fan_hammer': ([
        ".kkkkkk",
        "kGGGGGG",
        "kGkkk..",
        "kG.....",
        "kk.....",
    ], {'k': 'black', 'G': 'gray'}),
    'templar': ([
        ".wwwww.",
        "wwrwrww",
        "wrrrrrw",
        "wwrwrww",
        ".wwrww.",
        "..www..",
    ], {'w': 'white', 'r': 'red'}),
    'paladin': ([
        "...w...",
        "...w...",
        "...w...",
        ".yyyyy.",
        "...b...",
        "...b...",
    ], {'w': 'lgray', 'y': 'gld', 'b': 'wd_d'}),
    'holy_champion': ([
        "y.y.y.y",
        ".yyyyy.",
        "yyywyyy",
        ".yyyyy.",
        "y.y.y.y",
    ], {'y': 'gld', 'w': 'white'}),
    'heavy_gunner': ([
        "gggggg.",
        "gGGGGGq",
        "gggggg.",
        ".k.k...",
    ], {'g': 'gun_d', 'G': 'gun', 'q': 'yellow', 'k': 'black'}),
    'commando': ([
        "..ooo..",
        ".oOOOo.",
        "oOkOkOo",
        "oOOOOOo",
        ".ooooo.",
    ], {'o': 'olv_d', 'O': 'olv', 'k': 'black'}),
    'plating': ([
        "ggggggg",
        "gLgLgLg",
        "ggggggg",
        "gLgLgLg",
        "ggggggg",
    ], {'g': 'gray', 'L': 'lgray'}),
    'twin_turret': ([
        "nnn.nnn",
        "..g.g..",
        ".ggggg.",
        "gGGGGGg",
        "ggggggg",
    ], {'n': 'gun', 'g': 'olv_d', 'G': 'olv'}),
    'inferno': ([
        "..y....",
        ".yoy.y.",
        ".ooo.o.",
        "orroooo",
        "orrroro",
        ".rrrrr.",
    ], {'y': 'yellow', 'o': 'orange', 'r': 'red'}),
    'dragon_breath': ([
        "rr.....",
        "rrr.oy.",
        ".rrooyy",
        "rrr.oy.",
        "rr.....",
    ], {'r': 'dred', 'o': 'orange', 'y': 'yellow'}),
    'anti_material': ([
        "ggggggggw",
        ".gg......",
        ".g.......",
    ], {'g': 'gun_d', 'w': 'white'}),
    'deadeye': ([
        "..www..",
        ".wkkkw.",
        "wkkrkkw",
        ".wkkkw.",
        "..www..",
    ], {'w': 'white', 'k': 'black', 'r': 'red'}),
    'soul_harvest': ([
        "...gg..",
        "..ggGg.",
        ".gGGGg.",
        "..ggg..",
        ".g.g...",
        "g..g...",
    ], {'g': 'green', 'G': 'lgreen'}),
    'lord_bones': ([
        "y.y.y.y",
        "yyyyyyy",
        ".wwwww.",
        "wkwwwkw",
        ".wwkww.",
        "..www..",
    ], {'y': 'gld', 'w': 'white', 'k': 'black'}),
    'cryo_cannon': ([
        "bbbbbcw",
        "bBBBBcc",
        "bbbbbcw",
        ".k.k...",
    ], {'b': 'dblue', 'B': 'blue', 'c': 'cyan', 'w': 'white', 'k': 'black'}),
    'shadow_blade': ([
        "......G",
        ".....G.",
        "....G..",
        ".k.G...",
        "..k....",
        ".k.k...",
    ], {'G': 'lgreen', 'k': 'navy'}),
    'corrosive_mix': ([
        "..gg..",
        "..gg..",
        ".gGGg.",
        "gGlGGg",
        "gGGGlg",
        ".gggg.",
    ], {'g': 'dgreen', 'G': 'lgreen', 'l': 'white'}),
    'toxic_scope': ([
        "..g..",
        ".ggg.",
        "gg.gg",
        ".ggg.",
        "..g..",
    ], {'g': 'lgreen'}),
    'acid_splash': ([
        "g.....g",
        "..G.G..",
        ".GlGGG.",
        "g.GGG.g",
        "..G.G..",
        "g.....g",
    ], {'g': 'green', 'G': 'lgreen', 'l': 'white'}),
    'toxic_overload': ([
        ".GGGGG.",
        "GGGGGGG",
        "GkkGkkG",
        "GGGkGGG",
        ".GGGGG.",
        ".G.G.G.",
    ], {'G': 'lgreen', 'k': 'black'}),
    'poisoned_blades': ([
        "....w",
        "...w.",
        "..w..",
        "bw...",
        ".b.G.",
        "b..G.",
    ], {'w': 'lgray', 'b': 'wd_d', 'G': 'lgreen'}),
    'swift_strikes': ([
        "...ww",
        "..ww.",
        ".ww.w",
        "ww.ww",
        "w.ww.",
        ".ww..",
    ], {'w': 'lgray'}),
    'throwing_daggers': ([
        "......w",
        ".....w.",
        "....w..",
        ".g.w...",
        "..b....",
        ".b.g...",
    ], {'w': 'lgray', 'b': 'wd_d', 'g': 'gray'}),
    'twin_daggers': ([
        "w.....w",
        ".w...w.",
        "..w.w..",
        "...w...",
        "..b.b..",
        ".b...b.",
    ], {'w': 'lgray', 'b': 'wd_d'}),
    'master_assassin': ([
        "..hhh..",
        ".hHHHh.",
        "hHkkkHh",
        "hkGkGkh",
        "hHkkkHh",
        ".hhhhh.",
    ], {'h': 'olv_d', 'H': 'olv', 'k': 'black', 'G': 'lgreen'}),
    'cold_water': ([
        "..b..",
        "..b..",
        ".bwb.",
        ".bwb.",
        "bccbb",
        "bcbbb",
        ".bbb.",
    ], {'b': 'blue', 'c': 'cyan', 'w': 'white'}),
    'pressure_hose': ([
        ".....c.",
        "ggg.c..",
        "gGGnnc.",
        "gGGnn.c",
        "ggg.c..",
        ".....c.",
    ], {'g': 'gray', 'G': 'dgray', 'n': 'lgray', 'c': 'cyan'}),
    'ice_water': ([
        "wwwwww",
        "wcccbb",
        "wcwccb",
        "wccccb",
        "wcccbb",
        "bbbbbb",
    ], {'w': 'white', 'c': 'cyan', 'b': 'blue'}),
    'nitrogen': ([
        "w..w..w",
        ".w.w.w.",
        "..www..",
        "wwwcwww",
        "..www..",
        ".w.w.w.",
        "w..w..w",
    ], {'w': 'white', 'c': 'cyan'}),
    'dark_pact': ([
        "..p..",
        ".pPp.",
        "pPPPp",
        "pPgPp",
        ".pPp.",
        "..p..",
    ], {'p': 'purple', 'P': 'magenta', 'g': 'lgreen'}),
    'bone_army': ([
        "w....w",
        ".w..w.",
        "..ww..",
        "..ww..",
        ".w..w.",
        "w....w",
    ], {'w': 'sand'}),
    'lich': ([
        "y.y.y",
        "yyyyy",
        "ycyCy",
        "yyyyy",
    ], {'y': 'gold', 'c': 'cyan', 'C': 'lgreen'}),
    'quick_draw': ([
        "....yy",
        "...yy.",
        "..yy..",
        ".yyyyy",
        "...yy.",
        "..yy..",
        ".yy...",
    ], {'y': 'yellow'}),
    'hollow_points': ([
        "..s..",
        ".sss.",
        ".sss.",
        ".ooo.",
        ".ooo.",
        ".ooo.",
        ".ddd.",
    ], {'s': 'lgray', 'o': 'gold', 'd': 'lorange'}),
    'dual_pistols': ([
        "gggggg..",
        "gg.b....",
        "........",
        "..gggggg",
        "..gg.b..",
    ], {'g': 'lgray', 'b': 'brown'}),
    'sharpened_blade': ([
        "y.....w",
        "....ww.",
        "...ww..",
        "..ww...",
        "gww....",
        ".g.....",
        "b.g..y.",
    ], {'w': 'white', 'g': 'gold', 'b': 'brown', 'y': 'yellow'}),
    'cleave': ([
        "..www..",
        ".w...w.",
        "w.....w",
        "w.....w",
        ".......",
        "w.....w",
    ], {'w': 'white'}),
    'champion': ([
        "y..y..y",
        "yy.y.yy",
        "yyyyyyy",
        "yrybyry",
        "yyyyyyy",
    ], {'y': 'gold', 'r': 'red', 'b': 'cyan'}),
    'ap_rounds': ([
        "..r..",
        ".rrr.",
        ".sss.",
        ".ooo.",
        ".ooo.",
        ".ooo.",
        ".ddd.",
    ], {'r': 'red', 's': 'lgray', 'o': 'gold', 'd': 'lorange'}),
    'grenades': ([
        "..gg..",
        ".g..g.",
        ".GGGG.",
        "GGlGGG",
        "GGGGGG",
        "GlGGGG",
        ".GGGG.",
    ], {'g': 'lgray', 'G': 'green', 'l': 'lgreen'}),
    'machine_gun': ([
        "o.o.o.o",
        "o.o.o.o",
        "s.s.s.s",
        "kkkkkkk",
    ], {'o': 'gold', 's': 'lgray', 'k': 'xdgray'}),
    'bigger_tank': ([
        ".rrrr.",
        "rRrrrr",
        "rRrwwr",
        "rRrwkr",
        "rRrrrr",
        "rRrrrr",
        ".rrrr.",
    ], {'r': 'red', 'R': 'pink', 'w': 'white', 'k': 'black'}),
    'optics': ([
        "..ggg..",
        ".g.r.g.",
        "g..r..g",
        "grrrrrg",
        "g..r..g",
        ".g.r.g.",
        "..ggg..",
    ], {'g': 'lgray', 'r': 'red'}),
    'fmj': ([
        "..o..",
        ".ooo.",
        ".ooo.",
        ".OOO.",
        ".sss.",
        ".sss.",
        ".sss.",
        ".ddd.",
    ], {'o': 'orange', 'O': 'rust', 's': 'gold', 'd': 'lorange'}),
    'headshot': ([
        "r.www.r",
        ".wwwww.",
        ".wkwkw.",
        ".wwwww.",
        "..www..",
        "r.w.w.r",
    ], {'w': 'white', 'k': 'black', 'r': 'red'}),
    'napalm': ([
        "..o..",
        "..o..",
        ".ooo.",
        "ooyoo",
        "oyyyo",
        "ooyoo",
        ".ooo.",
    ], {'o': 'orange', 'y': 'yellow'}),
    'blue_flame': ([
        "...b...",
        "..bb.b.",
        ".bbccbb",
        "bbccwcb",
        "bcwwwcb",
        ".bwwwb.",
    ], {'b': 'dblue', 'c': 'blue', 'w': 'cyan'}),
}

CURSOR_ARROW = [
    "w.......",
    "ww......",
    "wlw.....",
    "wllw....",
    "wlllw...",
    "wllllw..",
    "wlllllw.",
    "wllllllw",
    "wlllwww.",
    "wwlw....",
    "w..lw...",
    "...lw...",
    "....w...",
]
CURSOR_HAND = [
    "..ww....",
    "..wl....",
    "..wl....",
    "..wlwww.",
    "..wlllww",
    "wwwlllll",
    "wlllllll",
    ".wllllll",
    "..wlllll",
    "..wllll.",
    "...www..",
]
CURSOR_CROSS = [
    "yyy...yyy",
    "y.......y",
    "y.......y",
    ".........",
    "....w....",
    ".........",
    "y.......y",
    "y.......y",
    "yyy...yyy",
]
CURSOR_C = {'w': 'white', 'l': 'lgray', 'y': 'yellow'}
