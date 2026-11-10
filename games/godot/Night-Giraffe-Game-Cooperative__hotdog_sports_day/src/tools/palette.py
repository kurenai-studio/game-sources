"""Every colour in HotDog Sports Day. Art may only use these ramps.

Each ramp runs dark -> light. Darks lean purple and cool, lights lean warm and
yellow, so everything sits in the same summer-afternoon light. The first step
of a ramp doubles as that material's outline.
"""


def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def ramp(*cols):
    return [hx(c) for c in cols]


INK = hx("#24152e")          # the darkest dark: deep plum, never black
WHITE = hx("#fffaf0")        # the lightest light: warm paper white

# -- sausages ------------------------------------------------------------------
FRANK = ramp("#4a1730", "#86283a", "#b8423d", "#dc6a4c", "#f49a73")     # classic frankfurter
BRAT = ramp("#4a2a2c", "#8a5546", "#bf8a68", "#dfb08a", "#f4d3ac")      # pale bratwurst
RED_POLSE = ramp("#4c0f2c", "#9a1638", "#d92b3a", "#f45a4d", "#ff9478")  # Danish red
BANGER = ramp("#3e1c28", "#7a3a35", "#a85a42", "#cf8358", "#ebb184")    # British banger
CHORIZO = ramp("#3a1022", "#7a1f2c", "#b2382e", "#d86040", "#f0905e")
BACON = ramp("#40122a", "#93303a", "#cf5a54", "#ef8f7c", "#ffc6ae")
BACON_FAT = ramp("#a86a6a", "#e8b8a0", "#fbe2cc")
CUMBERLAND = ramp("#36171f", "#6a3330", "#97533b", "#be7850", "#dea474")  # coarse, peppery, English
GLAMORGAN = ramp("#5a3418", "#a46a30", "#d29c4e", "#ecc878", "#fbe6aa")   # Welsh: cheese and leek, crumbed
LORNE = ramp("#4a1424", "#8e2c3a", "#c4504a", "#e47a62", "#f8a888")       # Scottish square sausage
HERB = ramp("#1e3a1e", "#3e6a2e", "#6a9a3e")
FAT_FLECK = ramp("#c8806a", "#f2c0a8", "#ffe2d2")

# -- breads --------------------------------------------------------------------
BUN = ramp("#5a2e2a", "#9a5534", "#cf8a45", "#eab067", "#f8d896")        # soft golden bun
CRUMB = ramp("#9a7a56", "#e2c896", "#f6e6bc", "#fff6dc")                 # the inside
CRUSTY = ramp("#4a2422", "#874329", "#b8692f", "#dc9547", "#f0c072")     # baguette/brötchen
WHITE_BREAD = ramp("#7a5a4a", "#d8c2a0", "#f2e6cc", "#fffaf0")
POPPY_BUN = BUN
BATTER = ramp("#5a2e1e", "#a8601e", "#da9a2e", "#f2c24e", "#fde28a")     # corn dog
FLATBREAD = ramp("#6a4a3a", "#c49a6a", "#e8cc9a", "#fbecc8")
STICK = ramp("#5a3a2a", "#a07a52", "#d8b884", "#f2dcb0")
FLOURY = ramp("#6a3a2a", "#a8683e", "#d49c5e", "#ecc68c", "#faeac0")     # a floury bap
SODA = ramp("#6a4a34", "#b08a5e", "#d8b886", "#eed8aa", "#fbf0d2")       # soda farl
FLOUR = ramp("#d8d0c0", "#fffaf0")

# -- toppings ------------------------------------------------------------------
MUSTARD = ramp("#7a4a12", "#d9a21b", "#f7d331", "#fff38a")
BROWN_MUSTARD = ramp("#5a3410", "#a8701e", "#d6a03a", "#f2cc6a")
KETCHUP = ramp("#5c0f22", "#b0202e", "#e0383a", "#ff7a6a")
BROWN_SAUCE = ramp("#2e1414", "#5e2a1e", "#8a4428", "#b26a3a")
RELISH = ramp("#1e4a2a", "#38a03a", "#7ad448", "#c4f27a")                # neon Chicago green
PICKLE = ramp("#1e3a1e", "#3d6a2a", "#6a9a3a", "#a8c860")
TOMATO = ramp("#5c0f22", "#c02a30", "#ef5040", "#ff9a7a")
ONION = ramp("#6a4a6a", "#d8c8e0", "#fff4fa")
CRISPY_ONION = ramp("#4a2410", "#9a5a1e", "#d0902e", "#f2c25a")
REMOULADE = ramp("#8a7a3a", "#e6dc9a", "#fffacc")
AVOCADO = ramp("#24401e", "#4e7e2a", "#86b23a", "#c0dc6a")
MAYO = ramp("#a8a08a", "#ece6d2", "#fffcf0")
CHEESE = ramp("#8a5a12", "#e0a82a", "#f8d050", "#fff09a")
POTATO_STICKS = ramp("#7a4a1a", "#d29a3a", "#f2c860", "#fff0a0")
CORN = ramp("#8a5a10", "#e8b82a", "#ffe46a")
PEAS = ramp("#1e4a1e", "#4a9a2e", "#8ad24a")
BEANS = ramp("#2a1418", "#5a2a24", "#8a4a32")
JALAPENO = ramp("#163a1e", "#2e7a2e", "#5ab03a", "#a0e070")
POPPY = ramp("#2a1e2e", "#4a3a4a")
SESAME = ramp("#c8a868", "#fff0c0")
NORI = ramp("#101e1a", "#24402e", "#3a5a3e")
LEEK_WHITE = ramp("#8a9a7a", "#dce8c8", "#fbfff0")
LEEK_GREEN = ramp("#163a1e", "#2e7a32", "#5ab04a", "#9ad870")
EGG_WHITE = ramp("#a8a08a", "#ece6d2", "#fffcf0")
YOLK = ramp("#9a4a0e", "#f0981e", "#ffcc3a", "#fff09a")

# -- face ----------------------------------------------------------------------
EYE_WHITE = ramp("#3a2a4a", "#c8c4e0", "#fffaf0")
PUPIL = ramp("#140a1e", "#24152e", "#4a3a6a")
CHEEK = hx("#ff7a7a")
MOUTH = ramp("#2a0f1e", "#6a1a2e", "#c83a4a")
TONGUE = ramp("#8a2a3a", "#f06a7a", "#ffa0a8")
TOOTH = ramp("#8a8aa0", "#fffaf0")

# -- the stadium ---------------------------------------------------------------
TRACK = ramp("#5a1e2a", "#8e3434", "#bc4c3c", "#d86a48", "#ec8c5e")       # tartan
LANE_LINE = ramp("#c8b8b0", "#fffaf0")
GRASS = ramp("#1a3a2e", "#2a5a34", "#3e7e3a", "#5ea040", "#8cc650", "#bce070")
SAND = ramp("#7a4e2e", "#c08e52", "#e2b870", "#f6dc9a")
SKY = ramp("#3a5aa8", "#4e7ece", "#6aa2e2", "#94c6f0", "#c4e2f8")
DUSK = ramp("#2a1e4a", "#5a2e6a", "#a0466e", "#e2706a", "#f8b07a")
CONCRETE = ramp("#2e2a3e", "#4e4a62", "#7a7690", "#a8a6ba", "#d4d4e0")
SEAT_BLUE = ramp("#1a1e4a", "#2a3a8a", "#3e62c0", "#6a92e2")
SEAT_RED = ramp("#3e0f2a", "#8a1e34", "#c83a3e", "#ec6a5a")
STEEL = ramp("#1e1e2e", "#3a3a52", "#6a6a86", "#a0a0b8", "#e0e0ee")
WATER = ramp("#123a5a", "#1e5e8a", "#2e86b4", "#56b2d8", "#9ad8f0", "#e0f6ff")
TILE = ramp("#2a5a7a", "#6aaac8", "#c8e8f2", "#f0faff")
WOOD = ramp("#3a1e1e", "#6a3a2a", "#9a5e3a", "#c88a52", "#e8b878")
MAT_BLUE = ramp("#141a4a", "#233a96", "#3a5ad2", "#6a8af0", "#a4baff")
LED_OFF = hx("#1a1424")
LED_AMBER = ramp("#5a2a10", "#e08a1e", "#ffd060", "#fff4c0")

# -- 80s sweatbands (keyed: swapped at run time for team colours) -----------------
# The sprite sheets paint sweatbands in these exact key colours; ui/swap.gdshader
# replaces them with a team's band colours (main, stripe), each as a ramp of 3.
BAND_KEY_MAIN = [hx("#ff00f0"), hx("#ff40f4"), hx("#ff80f8")]
BAND_KEY_STRIPE = [hx("#00fff0"), hx("#40fff4"), hx("#80fff8")]
TERRY_WHITE = ramp("#8a8aa8", "#d8d8ec", "#fffaf0")

# Team colours: (main ramp, stripe ramp) — dark, mid, light.
TEAM = {
    "red": ramp("#7a1428", "#d42c3a", "#ff6a6a"),
    "white": ramp("#9a9ab8", "#e8e8f4", "#fffaf0"),
    "blue": ramp("#141e6a", "#2a4ad2", "#6a8aff"),
    "navy": ramp("#0e1238", "#1e2a7a", "#3e5ac0"),
    "yellow": ramp("#9a6a10", "#f2c41e", "#fff07a"),
    "green": ramp("#0e4a2a", "#1e9a4a", "#5ad87a"),
    "black": ramp("#0e0a14", "#2a2436", "#5a5070"),
    "gold": ramp("#7a4a10", "#dca02a", "#ffe08a"),
    "pink": ramp("#7a1e5a", "#f04aa8", "#ff9ad8"),
    "teal": ramp("#0e4a5a", "#1eaab4", "#7af0f0"),
    "orange": ramp("#7a2a0e", "#f0701e", "#ffb070"),
    "purple": ramp("#3a1468", "#7a3ad2", "#b88aff"),
    "sky": ramp("#1e4a8a", "#4aa2e8", "#a8dcff"),
    "lime": ramp("#3a6a10", "#8ad42a", "#d4ff7a"),
    # unlocked by playing
    "silver": ramp("#4a4a62", "#a8a8c0", "#f0f0fa"),
    "mint": ramp("#1e6a4a", "#5ad8a8", "#c4fae2"),
    "lilac": ramp("#5a3a8a", "#b48ae8", "#ecd8ff"),
    "coral": ramp("#8a2a2a", "#ff7a6a", "#ffc4b4"),
    "cream": ramp("#8a7a5a", "#efe2be", "#fffaf0"),
    "maroon": ramp("#3a0a1a", "#7a1a34", "#b4405a"),
    "neon": ramp("#4a7a0e", "#c4ff2a", "#f4ffa8"),
    "brown": ramp("#2e140e", "#6a3a22", "#a8683e"),
}

# Flags are drawn small (pixel art), from these.
FLAG = {
    "red": hx("#d42c3a"), "white": hx("#fffaf0"), "blue": hx("#2a4ad2"),
    "navy": hx("#1e2a7a"), "yellow": hx("#f2c41e"), "green": hx("#1e9a4a"),
    "black": hx("#2a2436"), "gold": hx("#dca02a"), "sky": hx("#4aa2e8"),
    "orange": hx("#f0801e"), "saltire": hx("#2a68d2"), "dragon": hx("#d42c3a"), "leaf": hx("#2a9a4a"),
}

# -- the wardrobe (tools/wardrobe.py): hats, outfits, silly sausages and buns ------
CAP_BLUE = ramp("#141e5a", "#2a3ab4", "#3e6ae2", "#7aa2ff")
PARTY_PINK = ramp("#6a1448", "#d43a9a", "#ff6ac8", "#ffaae4")
PARTY_YELLOW = ramp("#7a4a10", "#e8a81e", "#ffd83a", "#fff28a")
KNIT_RED = ramp("#5a0f22", "#b42434", "#e2443e", "#ff806a")
KNIT_WHITE = ramp("#8a8aa8", "#d8d8ec", "#fffaf0")
CHEF_WHITE = ramp("#7a7a9a", "#c8c8e0", "#ececf6", "#fffcf4")
COWBOY = ramp("#3a1e14", "#6a3a22", "#9a5e34", "#c48a52")
GOLD = ramp("#6a3a0e", "#c08a1e", "#f2c83a", "#fff090")
JEWEL_RED = ramp("#5a0a22", "#d42a4a", "#ff7a8a")
JEWEL_BLUE = ramp("#0e1e6a", "#2a6ae2", "#8ac2ff")
JEWEL_GREEN = ramp("#0e4a2a", "#2ab45a", "#8af0a0")
TOP_BLACK = ramp("#0e0a14", "#241c30", "#3e344e", "#625878")
HORN = ramp("#6a5a4a", "#c8b898", "#ece2c8", "#fffaf0")
WIZARD = ramp("#1a0e4a", "#3a1e8a", "#5a3ac8", "#8a6af0")
STAR = ramp("#fff07a")
STRAW = ramp("#6a4a1a", "#b8862e", "#e2b84e", "#f8e08a")
CONE_ORANGE = ramp("#6a1e0e", "#d4501e", "#ff7a2e", "#ffb070")
BUNNY = ramp("#8a8aa8", "#d4d4ea", "#f4f2fa", "#fffcff")
BUNNY_PINK = ramp("#c85a8a", "#ff9ac8")
UNICORN = ramp("#7a6aa8", "#d8c8f8", "#fff4ff")
ANTLER = ramp("#3a2218", "#6a4428", "#9a6e42", "#c49a64")
PETAL_PINK = ramp("#8a1e5a", "#f05aa8", "#ff9ad0", "#ffd4ec")
PETAL_YELLOW = ramp("#8a5a0e", "#f2b81e", "#ffe04a", "#fff6a8")
PETAL_BLUE = ramp("#1e2a8a", "#4a7ae8", "#8ab8ff", "#d0e6ff")
PETAL_WHITE = ramp("#8a8aa8", "#d8d8ec", "#f4f4fa", "#fffaf0")
SHARK = ramp("#1e2a4a", "#3e5a82", "#6a8ab0", "#a4c0dc")
CAPE_RED = ramp("#4a0a1e", "#a01a30", "#d8303a", "#ff6a5a")
TUTU_PINK = ramp("#a02a6a", "#f07ab8", "#ffb4dc", "#ffe4f4")

# silly sausages and buns
GOLDEN = ramp("#5a3008", "#b0700e", "#e8a81e", "#ffd84a", "#fff4a8")
BLUE_RASPBERRY = ramp("#0e1a5a", "#1e3ab4", "#2e6ae8", "#5aa2ff", "#a8d8ff")
PINK_SAUSAGE = ramp("#5a0f3a", "#a82a6a", "#e04a98", "#ff80c0", "#ffc0e2")
GLOW = ramp("#0e4a1e", "#2a9a2a", "#5ae03a", "#a8ff6a", "#eaffc0")
ZOMBIE = ramp("#1e2a1e", "#3e5a32", "#62824a", "#8aa868", "#b8cc92")
PRETZEL = ramp("#2e120a", "#5e2814", "#8e441c", "#b8682a", "#d89448")
CHOCOLATE = ramp("#1e0e10", "#3e1e1a", "#6a3424", "#945232", "#b87848")
ICING_PINK = ramp("#a02a6a", "#f07ab8", "#ffb4dc", "#ffe4f4")
GLITTER = ramp("#3a1468", "#7a3ad2", "#b88aff", "#e4d4ff")
SALT = ramp("#d8d8e8", "#fffaf0")
SPRINKLES = [ramp("#ff5a5a"), ramp("#ffd83a"), ramp("#5ad87a"), ramp("#5aa2ff"), ramp("#fffaf0")]
