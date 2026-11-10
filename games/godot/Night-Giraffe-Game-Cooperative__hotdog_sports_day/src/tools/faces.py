"""Cartoon faces and the things worn on them, as hand-made pixel stamps.

A face is drawn by the game on top of the body, at the anchors the body sheet
saved for each frame (eyes, mouth, brow, top). Stamps are never scaled; on a
spinning frame they are turned in quarter turns, which keeps them crisp.

Keys: k ink line, w eye white, p pupil, g glint, m mouth, t tongue, n tooth,
c cheek, s shades, h shades glint, b brow, o moustache, l moustache light,
r hair, q hair light.
"""
import palette as P

PAL = {
    "k": P.INK,
    "w": P.EYE_WHITE[2],
    "e": P.EYE_WHITE[1],
    "p": P.PUPIL[0],
    "g": P.WHITE,
    "m": P.MOUTH[1],
    "t": P.TONGUE[1],
    "n": P.TOOTH[1],
    "c": P.CHEEK,
    "s": P.hx("#1a1430"),
    "h": P.hx("#7ae0ff"),
    "j": P.hx("#ff5ad0"),
    "b": P.INK,
    "o": P.hx("#3a1e1a"),
    "l": P.hx("#6a3a2a"),
    "r": P.hx("#5a2e1e"),
    "q": P.hx("#8a4a2a"),
    "y": P.hx("#f2c41e"),
    "z": P.hx("#fff07a"),
    "u": P.hx("#e0383a"),     # red (3D specs, a hero's mask)
    "v": P.hx("#2a7ae2"),     # blue
    "a": P.hx("#f2c83a"),     # gold (a monocle)
    "d": P.hx("#1eaab4"),     # teal (goggles)
    "f": P.hx("#bfeeff"),     # a lens
    "G": P.hx("#5ac83a"),     # a green mohawk
    "H": P.hx("#b4f06a"),
    "Y": P.hx("#f2d870"),     # blond
    "Z": P.hx("#fff4b4"),
}

# Each eye is one stamp; the face puts two, 1 pixel apart at the eyes anchor.
EYES = {
    "look": [            # looking ahead (to the right): the usual
        ".kkkk.",
        "kwwwwk",
        "kwwgpk",
        "kwwppk",
        "kwwppk",
        "kwwwwk",
        ".kkkk.",
    ],
    "front": [           # looking at us
        ".kkkk.",
        "kwwwwk",
        "kwgpwk",
        "kwppwk",
        "kwppwk",
        "kwwwwk",
        ".kkkk.",
    ],
    "up": [              # looking up (the bar, the board)
        ".kkkk.",
        "kwwgpk",
        "kwwppk",
        "kwwwwk",
        "kwwwwk",
        "kwwwwk",
        ".kkkk.",
    ],
    "wide": [            # surprised, or flying
        ".kkkk.",
        "kwwwwk",
        "kwwwwk",
        "kwwgpk",
        "kwwppk",
        "kwwwwk",
        "kwwwwk",
        ".kkkk.",
    ],
    "happy": [           # ^ ^
        "......",
        "......",
        ".kkkk.",
        "kk..kk",
        "k....k",
        "......",
        "......",
    ],
    "shut": [            # squeezed shut, trying hard
        "......",
        "......",
        "kkkkkk",
        ".kkkk.",
        "......",
        "......",
        "......",
    ],
    "dizzy": [
        "......",
        "k...k.",
        ".k.k..",
        "..k...",
        ".k.k..",
        "k...k.",
        "......",
    ],
    "sleepy": [
        "......",
        "......",
        "kkkkkk",
        "kwwppk",
        "kwwppk",
        ".kkkk.",
        "......",
    ],
    "star": [
        "..yy..",
        "..yy..",
        "yyzzyy",
        ".yzzy.",
        ".y..y.",
        "......",
        "......",
    ],
}

# Mouths: stamps centred on the mouth anchor.
MOUTHS = {
    "smile": [
        "k...k",
        ".kkk.",
    ],
    "grin": [
        "kkkkk",
        "knnnk",
        ".kmk.",
    ],
    "open": [
        ".kkk.",
        "kmmmk",
        "kmtmk",
        ".kkk.",
    ],
    "o": [
        ".k.",
        "kmk",
        ".k.",
    ],
    "flat": [
        "kkkk",
    ],
    "wobble": [
        ".k.k.",
        "k.k.k",
    ],
    "grit": [
        "kkkkk",
        "knknk",
        "kkkkk",
    ],
    "frown": [
        ".kkk.",
        "k...k",
    ],
    "tongue": [
        "kkkkk",
        ".kmtk",
        "..kk.",
    ],
}

BROWS = {
    "none": [],
    "keen": [             # determined: down toward the middle
        "kk...kk",
        "..k.k..",
    ],
    "worried": [
        "..k.k..",
        "kk...kk",
    ],
    "up": [
        ".kk.kk.",
        ".......",
    ],
}

# Things worn on the face (the dressing room). Drawn after the eyes.
SPECS = {
    "none": [],
    "shades": [          # 80s wayfarers
        "kkkkkkkkkk",
        "kshskshssk",
        "ksssksssk.",
        ".kkk.kkk..",
    ],
    "neon": [            # neon pink party shades
        "jjjjjjjjjj",
        "jshsjjshsj",
        "jsssjjsssj",
        ".jjj..jjj.",
    ],
    "round": [
        ".kk..kk.",
        "k.gkk.gk",
        "k..kk..k",
        ".kk..kk.",
    ],
    # unlocked by playing
    "hearts": [
        "jj.jj.jj.jj",
        "jjjjjkjjjjj",
        "jhjjj.jhjjj",
        ".jjj...jjj.",
        "..j.....j..",
    ],
    "stars": [
        "..y.....y..",
        ".yzy...yzy.",
        "yzzzykyzzzy",
        ".yzy...yzy.",
        ".y.y...y.y.",
    ],
    "3d": [
        "kkkkkkkkkkk",
        "kuuuukvvvvk",
        "kuuuukvvvvk",
        ".kkk...kkk.",
    ],
    "monocle": [
        "......aaa..",
        ".....a...a.",
        ".....a...a.",
        ".....a...a.",
        "......aaa..",
    ],
    "patch": [
        "kk....kkkk.",
        "..kk.kssssk",
        ".....kssssk",
        "......kssk.",
        ".......kk..",
    ],
    "goggles": [
        ".dddd.dddd.",
        "dfhffdfhffd",
        "dffffdffffd",
        ".dddd.dddd.",
    ],
    "nerd": [
        "kkkkk.kkkkk",
        "k...kwk...k",
        "k...k.k...k",
        "kkkkk.kkkkk",
    ],
    "mask": [
        ".uuuuuuuuu.",
        "uu...u...uu",
        "uu...u...uu",
        ".uuu...uuu.",
    ],
}

TACHES = {
    "none": [],
    "tache": [           # an 80s moustache
        ".oooo.",
        "oolloo",
        "o....o",
    ],
    "handlebar": [
        "o.oooo.o",
        "ooolloo.",
        ".o....o.",
    ],
    "walrus": [
        ".oooooo.",
        "oolllloo",
        "oo.oo.oo",
        "o..o..o.",
    ],
    "curly": [
        ".o.oooo.o.",
        "o.oolloo.o",
        "oo......oo",
    ],
}

# Hair goes under the sweatband, on top of the head.
HAIR = {
    "none": [],
    "flattop": [
        "rrrrrrrrrrr",
        "rqqqqqqqqqr",
        "rqrqrqrqrqr",
    ],
    "curly": [         # the 80s perm
        "..rr.rr.rr..",
        ".rqqrqqrqqr.",
        "rqrqqrqqrqqr",
        "rrrrrrrrrrrr",
    ],
    "spikes": [
        "r..r..r..r",
        "rr.rr.rr.r",
        "rrrrrrrrrr",
    ],
    # unlocked by playing
    "mohawk": [
        ".GG.",
        "GHHG",
        "GHHG",
        "GHGG",
        "GGGG",
    ],
    "afro": [
        "....rrrrrrr....",
        "..rrqrrqrrqrr..",
        ".rqrrqrrqrrqrr.",
        "rrqrrqrrqrrqrrr",
        "rqrrqrrqrrqrrqr",
        "rrrrrrrrrrrrrrr",
    ],
    "pigtails": [
        "jj...........jj",
        "rrj.YYYYYYY.jrr",
        "YZrYYZZZZZYYrZY",
        ".YY.YYYYYYY.YY.",
    ],
    "quiff": [
        "......rrrr.",
        "....rrqqqrr",
        "..rrqqrrrr.",
        "rrrrrrrrrr.",
    ],
}

# A mullet hangs down the back: drawn behind the head, offset backward.
MULLET = [
    "rrr",
    "rqr",
    "rqr",
    "rqr",
    "rr.",
    "r..",
]

# The cheek blush, one each side under the eyes.
CHEEK = ["cc"]
