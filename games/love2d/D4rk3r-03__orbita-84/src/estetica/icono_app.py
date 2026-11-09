#!/usr/bin/env python3
"""Ícono de la app de Android: el 84 en letras gordas, la nave y el platillo, en una
pantalla de 24x24 con la rejilla del LCD. Salida: img/icono_app.png (512x512)."""
import os

from PIL import Image

import generar
from generar import Pantalla
from efectos import DIB, a_imagen

p = Pantalla(24, 24)
p.gordo("84", 5, 4)
p.dibujo(DIB["nave"], 4, 14)
p.punto(12, 16)
p.dibujo(DIB["platillo"], 14, 14)
for x in range(3, 21):
    p.punto(x, 19, "+")
img = a_imagen(p.px, 20)
lienzo = Image.new("RGB", (512, 512), generar.FONDO)
lienzo.paste(img, ((512 - img.width) // 2 + 1, (512 - img.height) // 2 + 1))
ruta = os.path.join(generar.SALIDA, "icono_app.png")
lienzo.save(ruta)
print("listo:", ruta)
