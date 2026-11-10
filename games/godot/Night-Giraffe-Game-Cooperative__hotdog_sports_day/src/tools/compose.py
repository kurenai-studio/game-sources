"""Puts a whole athlete together in Python, the way the game does at run time
(ui/athlete_view.gd): the layers painted over each other, the sweatband's key
colours swapped for the team's, and the face stamped on at the frame's anchors.
For pictures made ahead of time: the app icon, the title, previews.
"""
import numpy as np
from PIL import Image

import dogs
import faces
import palette as P
import pix

CHICAGO = ("frank", "poppy", ["mustard", "relish", "tomato", "pickle"], ("blue", "red"))


def swap(rgba, main, stripe):
    a = rgba.copy()
    for keys, team in ((P.BAND_KEY_MAIN, P.TEAM[main]), (P.BAND_KEY_STRIPE, P.TEAM[stripe])):
        for k, t in zip(keys, team):
            m = (a[..., 0] == k[0]) & (a[..., 1] == k[1]) & (a[..., 2] == k[2])
            a[m, :3] = t
    return a


def over(dst, src):
    m = src[..., 3] > 0
    dst[m] = src[m]
    return dst


def face(img, anchors, eyes="look", mouth="smile", brow="none", spin=0):
    ex, ey = anchors["eyes"]
    e = faces.EYES[eyes]
    w = len(e[0])
    pix.stamp(img, e, faces.PAL, (ex - w / 2, ey), rot=spin)
    pix.stamp(img, e, faces.PAL, (ex + w / 2, ey), rot=spin)
    mx, my = anchors["mouth"]
    pix.stamp(img, faces.MOUTHS[mouth], faces.PAL, (mx, my), rot=spin)
    if brow != "none":
        bx, by = anchors["brow"]
        pix.stamp(img, faces.BROWS[brow], faces.PAL, (bx + 0.5, by), rot=spin)


def athlete(look=CHICAGO, frame="sq3", expr=("look", "grin", "none")):
    sausage, bun, tops, team = look
    xf = dict(dogs.frame_specs())[frame]
    back, front = dogs.bun_layers(bun)
    layers = [back, dogs.sausage_layer(sausage), front, sum((dogs.topping_layer(t) for t in tops), []),
              dogs.band_layer(sausage)]
    img = np.zeros((dogs.CELL[1], dogs.CELL[0], 4), np.uint8)
    for parts in layers:
        if parts:
            img = over(img, dogs.paint_layer(parts, xf))
    pim = Image.fromarray(swap(img, *team)).copy()
    face(pim, dogs.anchors_for(xf), *expr)
    return np.array(pim)
