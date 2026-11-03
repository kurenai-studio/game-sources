import sys
import math
import random
import pygame

import audio


#  PARÁMETROS DEL JUEGO

WIDTH, HEIGHT = 960, 540        # resolución lógica (se escala a la ventana)

# Física del salto
VELOCIDAD_SALTO = -7.5          # px/frame
GRAVEDAD = 0.55                 # px/frame²

# Geometría de los cuerpos, en altura sobre el suelo (franjas verticales)
ALTO_PIE = 46                   # atleta de pie:   0 .. 46
ALTO_AGACHADO = 22              # atleta agachado: 0 .. 22
ROCA_BASE, ROCA_TECHO = 0.0, 28.0     # piedra: 0 .. 28  (se salta)
DRON_BASE, DRON_TECHO = 34.0, 62.0    # dron:  34 .. 62 (imposible de saltar)

# Reglas de juego
VIDAS_INICIALES = 3
VIDAS_MAXIMAS = 5
FRAMES_INVULNERABLE = 90        # 1.5 s de gracia tras perder una vida
PUNTOS_POR_VIDA = 3000          # cada 3000 puntos aparece un corazón
BONO_VIDA_LLENA = 100           # puntos si ya tienes el máximo de vidas
PUNTOS_POR_OBSTACULO = 100      # puntos SOLO al esquivar una piedra o un dron
VELOCIDAD_MAXIMA = 11.0         # tope base: evita el "tunneling" entre frames
SUELO_BASE = 420                # altura media del terreno en pantalla

# Bonus
BONO_FORMULA = 500              # puntos al completar una fórmula
PUNTOS_POR_NIVEL = 10000        # cada 10.000 puntos sube un nivel
NIVELES_MAXIMOS = 3             # 11 -> 14 px/frame como máximo
VELOCIDAD_POR_NIVEL = 1.0       # px/frame extra por nivel

# Fórmulas que se completan recogiendo letras (la letra sale siempre en orden).
# El texto es el que se muestra en el HUD; la clave son solo letras A-Z.
FORMULAS = [
    ("DERIVADA", "Derivación numérica"),
    ("NEWTON", "Newton-Raphson modificado"),
    ("GAUSS", "Gauss-Seidel"),
    ("JACOBI", "Jacobi"),
    ("EULER", "Método de Euler"),
    ("BISECCION", "Bisección"),
]


#  VÍDEO: superficie lógica + escalado a la ventana

pygame.mixer.pre_init(audio.SR, -16, 1, 512)   # formato que sintetiza audio.py
pygame.init()
audio.iniciar()                                 # música + efectos (silencioso si falla)
_info = pygame.display.Info()


def _tamano_inicial():
    """Ventana inicial 16:9 que quepa cómoda en el escritorio."""
    w, h = _info.current_w, _info.current_h
    if w <= 0 or h <= 0:            # algunos drivers no informan el tamaño
        w, h = 1280, 720
    alto = min(int(h * 0.85), 900)
    ancho = int(alto * WIDTH / HEIGHT)
    if ancho > w * 0.92:
        ancho = int(w * 0.92)
        alto = int(ancho * HEIGHT / WIDTH)
    return max(480, ancho), max(270, alto)


ventana = pygame.display.set_mode(_tamano_inicial(), pygame.RESIZABLE)
pygame.display.set_caption("Runner Matemático: Atleta Definitivo")
screen = pygame.Surface((WIDTH, HEIGHT)).convert()
clock = pygame.time.Clock()

# Pantalla completa manual: en Wayland SDL2 ignora toggle_fullscreen(), así que
# se reconstruye el modo de vídeo con set_mode y se guarda el tamaño de ventana.
pantalla_completa = False
_tamano_ventana = ventana.get_size()


def alternar_pantalla_completa():
    """F11: alterna ventana / pantalla completa en cualquier plataforma.

    Devuelve True si el cambio se aplicó. Si el compositor no concede el modo,
    se restaura la ventana anterior en lugar de dejar una ventana inservible.
    """
    global ventana, pantalla_completa, _tamano_ventana
    if not pantalla_completa:
        _tamano_ventana = ventana.get_size()
        ventana = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
        ancho, alto = ventana.get_size()
        if ancho < 320 or alto < 240:
            ventana = pygame.display.set_mode(_tamano_ventana, pygame.RESIZABLE)
            pantalla_completa = False
            return False
        pantalla_completa = True
    else:
        ventana = pygame.display.set_mode(_tamano_ventana, pygame.RESIZABLE)
        pantalla_completa = False
    return True

# Fuentes (proporcionales a la resolución lógica)
font_s = pygame.font.SysFont("monospace", 14, bold=True)
font_m = pygame.font.SysFont("monospace", 18, bold=True)
font_l = pygame.font.SysFont("monospace", 30, bold=True)
font_xl = pygame.font.SysFont("monospace", 46, bold=True)


def presentar():
    """Escala la superficie lógica al tamaño actual de la ventana."""
    vw, vh = ventana.get_size()
    if vw < 1 or vh < 1:
        return
    escala = min(vw / WIDTH, vh / HEIGHT)
    tw = max(1, int(WIDTH * escala))
    th = max(1, int(HEIGHT * escala))
    lienzo = screen if (tw, th) == (WIDTH, HEIGHT) else pygame.transform.scale(screen, (tw, th))
    ventana.fill((0, 0, 0))
    ventana.blit(lienzo, ((vw - tw) // 2, (vh - th) // 2))
    pygame.display.flip()


def evento_global(event):
    """QUIT y pantalla completa. Devuelve True si el evento ya fue atendido."""
    if event.type == pygame.QUIT:
        pygame.quit()
        sys.exit()
    if event.type == pygame.KEYDOWN and event.key == pygame.K_F11:
        alternar_pantalla_completa()
        return True
    return False



#  TEMAS VISUALES

TEMAS = {
    "Clásico": {
        # Cielo con degradado (arriba azul, abajo casi blanco)
        "fondo": (160, 208, 240),
        "fondo2": (232, 246, 252),
        "suelo": (44, 116, 56),          # línea del terreno (verde)
        "cesped": (118, 186, 96),        # franja de césped bajo la línea
        "tierra": (152, 114, 82),        # relleno del terreno
        "detalle_suelo": (124, 92, 64),
        "atleta": (60, 60, 70),
        "camiseta": (232, 96, 60),
        "piel": (244, 204, 162),
        "piedra": (140, 132, 122),
        "dron": (62, 118, 196),
        "dron_detalle": (225, 78, 62),
        "dron_ojo": (255, 236, 120),
        "hud": (34, 56, 74),
        "hud_tenue": (104, 132, 152),
        "acento": (232, 118, 38),
        "vida": (226, 62, 78),
        "nube": (255, 255, 255),
        "grosor": 3,
        "estilo": "normal",
    },
    "Halloween": {
        # Noche de Halloween: cielo morado con luna, fantasmas y lápidas
        "fondo": (26, 10, 42),
        "fondo2": (92, 34, 70),
        "suelo": (214, 118, 42),
        "cesped": (96, 62, 34),
        "tierra": (34, 16, 26),
        "detalle_suelo": (58, 30, 40),
        "atleta": (60, 30, 70),
        "camiseta": (150, 60, 180),
        "piel": (150, 190, 130),
        "piedra": (170, 172, 182),
        "dron": (232, 238, 250),
        "dron_detalle": (150, 130, 190),
        "dron_ojo": (40, 24, 60),
        "hud": (240, 230, 245),
        "hud_tenue": (170, 145, 175),
        "acento": (255, 150, 50),
        "vida": (255, 70, 90),
        "nube": (44, 20, 50),
        "grosor": 3,
        "estilo": "halloween",       # dibuja fantasmas y tumbas
        "luna": (250, 240, 200),
        "estrella": (255, 246, 220),
    },
    "Oscuro": {
        "fondo": (10, 14, 24),
        "fondo2": (26, 38, 62),
        "suelo": (0, 220, 250),
        "cesped": (10, 96, 120),
        "tierra": (8, 22, 36),
        "detalle_suelo": (16, 52, 70),
        "atleta": (240, 214, 120),
        "camiseta": (255, 126, 60),
        "piel": (240, 214, 120),
        "piedra": (230, 70, 70),
        "dron": (90, 170, 255),
        "dron_detalle": (255, 160, 40),
        "dron_ojo": (255, 245, 150),
        "hud": (235, 235, 235),
        "hud_tenue": (110, 150, 175),
        "acento": (0, 255, 180),
        "vida": (255, 90, 110),
        "nube": (32, 44, 64),
        "grosor": 3,
        "estilo": "normal",
    },
    "Navidad": {
        # Nochebuena: cielo azul profundo, estrellas, nieve, regalos y bolas
        "fondo": (12, 22, 48),
        "fondo2": (62, 96, 146),
        "suelo": (240, 244, 252),        # línea de nieve
        "cesped": (226, 236, 250),       # manto de nieve
        "tierra": (44, 66, 96),
        "detalle_suelo": (92, 116, 148),
        "atleta": (40, 60, 92),
        "camiseta": (198, 44, 58),       # rojo navideño
        "piel": (244, 204, 162),
        "piedra": (198, 44, 58),         # regalo: caja roja
        "dron": (46, 130, 88),           # bola verde
        "dron_detalle": (246, 202, 96),  # cinta y remate dorados
        "dron_ojo": (255, 255, 255),
        "hud": (238, 244, 252),
        "hud_tenue": (150, 172, 204),
        "acento": (255, 96, 96),
        "vida": (255, 80, 100),
        "nube": (34, 50, 78),
        "grosor": 3,
        "estilo": "navidad",             # dibuja regalos y bolas de Navidad
        "estrella": (235, 242, 255),
        "nieve": (250, 252, 255),        # copos que caen
    },
}

ORDEN_TEMAS = ["Halloween", "Clásico", "Navidad", "Oscuro"]

# Configuración y Opciones del Juego
options_config = {
    "dificultad": "Normal",
    "tema": "Halloween",
}

# Perfiles de dificultad. Normal y Extremo conservan los valores de siempre;
# Ultramegasuperextremo es el infierno: arranca corriendo, acelera al doble
# de ritmo, tiene un solo corazón, huecos casi pegados y 2 de cada 3 señales
# son drones. La meta de 2000 puntos queda en terreno de leyenda.
ORDEN_DIFICULTAD = ["Normal", "Extremo", "Ultramegasuperextremo"]
DIFICULTADES = {
    "Normal": {
        "velocidad": 5.5,             # px/frame al arrancar
        "techo": VELOCIDAD_MAXIMA,    # tope base de velocidad
        "vidas": VIDAS_INICIALES,
        "esquivados_por_paso": 3,     # sube 0.5 px/frame cada N esquivados
        "agresividad": 0,             # no aprieta los huecos extra
        "peso_dron": 0.5,             # probabilidad de que el obstáculo sea dron
    },
    "Extremo": {
        "velocidad": 7.0,
        "techo": VELOCIDAD_MAXIMA,
        "vidas": VIDAS_INICIALES,
        "esquivados_por_paso": 3,
        "agresividad": 0,
        "peso_dron": 0.5,
    },
    "Ultramegasuperextremo": {
        "velocidad": 8.5,
        "techo": VELOCIDAD_MAXIMA + 3.0,   # tope de 14.0 px/frame
        "vidas": 1,                        # un error y se acabó
        "esquivados_por_paso": 1,          # la velocidad crece sin piedad
        "agresividad": 2,                  # huecos casi pegados entre sí
        "peso_dron": 2 / 3,                # mayoría de drones
    },
}

# Ranking de la sesión
high_scores = []

MEDALLAS = [
    (3000, "DIAMANTE", (0, 220, 250)),
    (2000, "ORO", (235, 180, 30)),
    (1000, "PLATA", (160, 175, 190)),
    (500, "BRONCE", (176, 108, 52)),
]


def asignar_medalla(score):
    for puntos, nombre, _ in MEDALLAS:
        if score >= puntos:
            return nombre
    return "SIN MEDALLA"


def color_medalla(nombre):
    for _, medalla, color in MEDALLAS:
        if medalla == nombre:
            return color
    return (140, 140, 140)



#  TERRENO Y DERIVACIÓN NUMÉRICA

def terreno_f(x):
    # Amplitudes calibradas: la pendiente máxima queda en 0.235, de modo que en 36 px (ancho de solape horizontal) el terreno cambia <= 8.41 px. Ese margen garantiza la regla "el dron se pasa agachado, nunca saltando".
    return SUELO_BASE + 18 * math.sin(x * 0.007) + 10 * math.cos(x * 0.014)


def derivada_numerica(x, h=1.0):
    return (terreno_f(x + h) - terreno_f(x - h)) / (2 * h)



#  DIBUJOS AUXILIARES

_fondos = {}


def fondo_tema(tema):
    """Cielo con degradado vertical. Se construye una vez por tema."""
    clave = (tema["fondo"], tema.get("fondo2", tema["fondo"]),
             tema.get("luna"), tema.get("estrella"))
    superficie = _fondos.get(clave)
    if superficie is None:
        superficie = pygame.Surface((WIDTH, HEIGHT))
        c1 = tema["fondo"]
        c2 = tema.get("fondo2", tema["fondo"])
        for y in range(HEIGHT):
            t = y / (HEIGHT - 1)
            color = tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))
            pygame.draw.line(superficie, color, (0, y), (WIDTH, y))

        # Estrellas: posiciones deterministas
        if tema.get("estrella"):
            for i in range(70):
                sx = (i * 137 + 53) % WIDTH
                sy = (i * 59 + 17) % 300
                pygame.draw.circle(superficie, tema["estrella"], (sx, sy),
                                   1 if i % 3 else 2)

        # Luna con cráteres
        if tema.get("luna"):
            cx, cy, r = 690, 100, 38
            pygame.draw.circle(superficie, tema["luna"], (cx, cy), r)
            sombra = tuple(max(0, c - 22) for c in tema["luna"])
            pygame.draw.circle(superficie, sombra, (cx - 12, cy - 8), 7)
            pygame.draw.circle(superficie, sombra, (cx + 14, cy + 6), 5)
            pygame.draw.circle(superficie, sombra, (cx + 4, cy + 18), 3)

        _fondos[clave] = superficie
    return superficie


def dibujar_corazon(surface, cx, cy, color, escala=1.0):
    r = max(2, int(4 * escala))
    pygame.draw.circle(surface, color, (int(cx - r / 2), int(cy - r / 2)), r)
    pygame.draw.circle(surface, color, (int(cx + r / 2), int(cy - r / 2)), r)
    pygame.draw.polygon(surface, color, [
        (int(cx - r * 1.5), int(cy)),
        (int(cx + r * 1.5), int(cy)),
        (int(cx), int(cy + r * 1.8)),
    ])
    # Brillo para que el corazón se lea bien sobre cualquier fondo
    brillo = tuple(min(255, c + 70) for c in color[:3])
    pygame.draw.circle(surface, brillo, (int(cx - r * 0.55), int(cy - r * 0.6)), max(1, r // 2))


def dibujar_letra(surface, cx, cy, letra, color, fondo, frame):
    """Letra coleccionable dentro de una insignia redonda."""
    pygame.draw.circle(surface, fondo, (int(cx), int(cy)), 13)
    pygame.draw.circle(surface, color, (int(cx), int(cy)), 13, 2)
    txt = font_s.render(letra, True, color)
    surface.blit(txt, (int(cx - txt.get_width() / 2), int(cy - txt.get_height() / 2)))


def dibujar_piedra(surface, rect, color):
    """Piedra del camino, dibujada dentro del rectángulo exacto del obstáculo.

    Todo queda dentro de `rect` para que el sprite coincida con la caja de
    colisión (franja 0..28 sobre el suelo): si se ve, choca.
    """
    x, y, w, h = rect
    claro = tuple(min(255, c + 45) for c in color[:3])
    oscuro = tuple(max(0, c - 45) for c in color[:3])

    # Silueta irregular de la roca
    puntos = [
        (x + 1, y + h - 1),
        (x, y + h - 10),
        (x + 5, y + h - 20),
        (x + 11, y + h - 25),
        (x + 18, y + h - 23),
        (x + 23, y + h - 14),
        (x + 23, y + h - 2),
    ]
    pygame.draw.polygon(surface, color, puntos)

    # Cara iluminada (arriba a la izquierda) y grieta
    pygame.draw.polygon(surface, claro, [
        (x + 3, y + h - 15),
        (x + 8, y + h - 22),
        (x + 13, y + h - 21),
        (x + 9, y + h - 13),
    ])
    pygame.draw.line(surface, oscuro, (x + 9, y + h - 12), (x + 15, y + h - 3), 1)

    # Piedrita pequeña al pie, para que no parezca un bloque solo
    pygame.draw.circle(surface, color, (x + w - 3, y + h - 3), 3)



def dibujar_dron(surface, rect, color, detalle, ojo):
    """Dron dentro de su rectángulo exacto (franja 34..62 sobre el suelo).

    Todo se dibuja dentro de `rect` para que el sprite coincida con la caja de
    colisión: si se ve, choca.
    """
    x, y, w, h = rect
    # Hélices: barra superior con dos rotores
    pygame.draw.line(surface, detalle, (x + 1, y + 3), (x + w - 2, y + 3), 2)
    pygame.draw.line(surface, detalle, (x + 3, y + 1), (x + 3, y + 5), 2)
    pygame.draw.line(surface, detalle, (x + w - 5, y + 1), (x + w - 5, y + 5), 2)
    # Cuerpo
    pygame.draw.ellipse(surface, color, (x + 2, y + 6, w - 4, h - 13))
    # Franja inferior del cuerpo (más oscura) y patas
    pygame.draw.line(surface, detalle, (x + 4, y + h - 9), (x + w - 5, y + h - 9), 2)
    pygame.draw.line(surface, detalle, (x + 5, y + h - 7), (x + 3, y + h - 1), 2)
    pygame.draw.line(surface, detalle, (x + w - 6, y + h - 7), (x + w - 4, y + h - 1), 2)
    # Ojo / sensor
    pygame.draw.circle(surface, ojo, (x + 7, y + 13), 3)
    pygame.draw.circle(surface, detalle, (x + 7, y + 13), 1)


def dibujar_tumba(surface, rect, color):
    """Lápida del camino (tema Halloween), dentro del rectángulo de colisión."""
    x, y, w, h = rect
    claro = tuple(min(255, c + 35) for c in color[:3])
    oscuro = tuple(max(0, c - 55) for c in color[:3])

    # Montículo de tierra removida al pie
    pygame.draw.ellipse(surface, oscuro, (x, y + h - 6, w, 6))

    # Lápida: rectángulo con la parte superior redondeada
    pygame.draw.rect(surface, color, (x + 4, y + 10, w - 8, h - 14), border_radius=2)
    pygame.draw.circle(surface, color, (x + w // 2, y + 11), (w - 8) // 2)

    # Cruz grabada
    pygame.draw.line(surface, oscuro, (x + w // 2, y + 9), (x + w // 2, y + 20), 2)
    pygame.draw.line(surface, oscuro, (x + w // 2 - 4, y + 14),
                     (x + w // 2 + 4, y + 14), 2)
    # Grieta y brillo
    pygame.draw.line(surface, oscuro, (x + 7, y + 18), (x + 10, y + 24), 1)
    pygame.draw.circle(surface, claro, (x + w // 2 - 4, y + 9), 2)


def dibujar_fantasma(surface, rect, color, detalle, ojo):
    """Fantasma flotante (tema Halloween), dentro de su rectángulo de colisión."""
    x, y, w, h = rect

    # Cabeza redonda, cuerpo recto y borde inferior ondulado
    pygame.draw.circle(surface, color, (x + w // 2, y + 11), 10)
    pygame.draw.rect(surface, color, (x + 2, y + 11, w - 4, 12))
    for i in range(3):
        pygame.draw.circle(surface, color, (x + 6 + i * 6, y + h - 4), 3)

    # Pliegues de la sábana
    pygame.draw.line(surface, detalle, (x + 8, y + 19), (x + 8, y + 24), 1)
    pygame.draw.line(surface, detalle, (x + 16, y + 19), (x + 16, y + 24), 1)

    # Ojos y boca
    pygame.draw.circle(surface, ojo, (x + 8, y + 10), 2)
    pygame.draw.circle(surface, ojo, (x + 16, y + 10), 2)
    pygame.draw.circle(surface, ojo, (x + 12, y + 16), 2)


def dibujar_regalo(surface, rect, color, cinta):
    """Regalo con lazo (tema Navidad), dentro del rectángulo de colisión."""
    x, y, w, h = rect
    oscuro = tuple(max(0, c - 55) for c in color[:3])

    # Caja y tapa
    pygame.draw.rect(surface, color, (x + 3, y + 10, w - 6, h - 10), border_radius=2)
    pygame.draw.rect(surface, color, (x + 1, y + 7, w - 2, 7), border_radius=2)

    # Cinta vertical y horizontal
    pygame.draw.rect(surface, cinta, (x + w // 2 - 2, y + 7, 4, h - 7))
    pygame.draw.rect(surface, cinta, (x + 1, y + 14, w - 2, 3))

    # Lazo
    pygame.draw.circle(surface, cinta, (x + w // 2 - 4, y + 5), 3)
    pygame.draw.circle(surface, cinta, (x + w // 2 + 4, y + 5), 3)
    pygame.draw.circle(surface, oscuro, (x + w // 2, y + 6), 2)

    # Sombra al pie
    pygame.draw.line(surface, oscuro, (x + 3, y + h - 1), (x + w - 3, y + h - 1), 1)


def dibujar_bola(surface, rect, color, detalle, ojo):
    """Bola de Navidad colgante, dentro de su rectángulo de colisión."""
    x, y, w, h = rect
    cx = x + w // 2

    # Hilo, remate y esfera
    pygame.draw.line(surface, detalle, (cx, y + 1), (cx, y + 7), 1)
    pygame.draw.rect(surface, detalle, (cx - 3, y + 6, 6, 4), border_radius=1)
    pygame.draw.circle(surface, color, (cx, y + 18), 9)

    # Franja decorativa y brillo
    pygame.draw.line(surface, detalle, (cx - 8, y + 14), (cx + 8, y + 14), 2)
    pygame.draw.circle(surface, ojo, (cx - 3, y + 15), 2)


def _copo(i, salt):
    """Valor pseudoaleatorio en [0,1) derivado del índice (determinista)."""
    v = math.sin(i * 12.9898 + salt) * 43758.5453
    return v - math.floor(v)


def dibujar_nieve(surface, color, frame, copos=70):
    """Copos que caen (tema Navidad). Posiciones derivadas del frame, sin azar."""
    for i in range(copos):
        x = (_copo(i, 1.7) * WIDTH + math.sin(frame * 0.015 + i) * 16) % WIDTH
        y = (_copo(i, 4.3) * HEIGHT + frame * (0.6 + _copo(i, 9.1) * 1.8)) % HEIGHT
        pygame.draw.circle(surface, color, (int(x), int(y)),
                           2 if _copo(i, 7.3) > 0.7 else 1)


def dibujar_nube(surface, x, y, color, escala=1.0):
    alto = int(9 * escala)
    pygame.draw.rect(surface, color, (int(x), int(y + alto), int(46 * escala), max(3, alto // 2)),
                     border_radius=3)
    pygame.draw.circle(surface, color, (int(x + 13 * escala), int(y + alto)), int(8 * escala))
    pygame.draw.circle(surface, color, (int(x + 25 * escala), int(y + alto - 3)), int(10 * escala))
    pygame.draw.circle(surface, color, (int(x + 37 * escala), int(y + alto)), int(7 * escala))


def dibujar_suelo(surface, world_offset, tema):
    """Terreno en color: césped, tierra debajo y la línea de la función."""
    puntos = [(x, terreno_f(x + world_offset)) for x in range(0, WIDTH + 4, 4)]

    # Relleno hasta el borde inferior de la pantalla (la "tierra")
    pygame.draw.polygon(surface, tema["tierra"],
                        puntos + [(WIDTH, HEIGHT), (0, HEIGHT)])

    # Franja de césped de 12 px pegada a la curva
    banda = puntos + [(x, y + 12) for x, y in reversed(puntos)]
    pygame.draw.polygon(surface, tema["cesped"], banda)

    # Línea de la función (borde superior del terreno)
    pygame.draw.lines(surface, tema["suelo"], False, puntos, tema["grosor"])

    # Piedritas y matas de hierba, como en el dinosaurio de Chrome
    primero = int(world_offset // 90) * 90
    for i in range(0, WIDTH // 90 + 3):
        wx = primero + i * 90
        sx = wx - world_offset
        if -12 < sx < WIDTH:
            gy = terreno_f(wx) + 8
            largo = 5 + (int(wx) * 7 + 3) % 9
            pygame.draw.line(surface, tema["detalle_suelo"], (sx, gy), (sx + largo, gy), 2)
            # Textura de tierra: piedritas repartidas bajo el césped
            pygame.draw.circle(surface, tema["detalle_suelo"],
                               (int(sx + 22), int(gy + 26)), 2)
            pygame.draw.circle(surface, tema["detalle_suelo"],
                               (int(sx + 58), int(gy + 52)), 3)
            if i % 2 == 0:
                pygame.draw.line(surface, tema["suelo"], (sx + 30, gy - 4),
                                 (sx + 33, gy - 9), 2)
                pygame.draw.line(surface, tema["suelo"], (sx + 34, gy - 4),
                                 (sx + 34, gy - 8), 2)



#  ATLETA

class Player:
    def __init__(self):
        self.x = 150
        self.y = terreno_f(self.x)
        self.vy = 0
        self.is_jumping = False
        self.is_crouching = False
        self.score = 0
        self.anim_timer = 0
        self.h = 0.0            # altura de vuelo (0 = pisando el terreno)

    def jump(self):
        """Inicia el salto. Devuelve True si el salto arrancó de verdad."""
        if not self.is_jumping and not self.is_crouching:
            # Salto corto y preciso: techo físico de 47.45 px (ver manual táctico).
            # Alcanza para la piedra (28 px) pero NUNCA para el dron (62 px).
            self.vy = VELOCIDAD_SALTO
            self.h = 0.0            # el vuelo arranca a ras de suelo
            self.is_jumping = True
            return True
        return False

    def crouch(self, down_pressed):
        if not self.is_jumping:
            self.is_crouching = down_pressed

    def altura_vuelo(self):
        """Altura del salto (px) medida desde el terreno bajo los pies.

        Se obtiene integrando numéricamente la velocidad vertical (h -= vy),
        así que no depende de la pendiente: su techo es siempre
        VELOCIDAD_SALTO**2 / (2*GRAVEDAD) ~ 47.45 px (51.14 en tiempo continuo).
        Es la magnitud que usan la colisión y el HUD.
        """
        return self.h

    def estatura(self):
        return ALTO_AGACHADO if self.is_crouching else ALTO_PIE

    def get_banda_vertical(self, suelo):
        """Franja vertical del cuerpo sobre una referencia de suelo dada.

        Devuelve (base, techo) en píxeles sobre ese suelo. Usar una única
        referencia vertical (el suelo del obstáculo) hace que la colisión sea
        exactamente lo que se ve en pantalla, aunque haya cuestas.
        """
        base = suelo - round(self.y)
        return base, base + self.estatura()

    def update(self, world_offset, speed):
        real_x = self.x + world_offset
        ground_y = terreno_f(real_x)

        if self.is_jumping:
            # Gravedad ligeramente más pesada para que caiga rápido
            self.vy += GRAVEDAD
            self.h = self.h - self.vy      # integra numéricamente la altura
            self.y = ground_y - self.h     # el salto se mide sobre el terreno
            if self.h <= 0:
                self.h = 0.0
                self.vy = 0
                self.y = ground_y
                self.is_jumping = False
        else:
            self.y = ground_y
            self.anim_timer += speed * 0.15

    def get_rect(self):
        alto = self.estatura()
        return pygame.Rect(self.x - 12, round(self.y - alto), 24, alto)

    def draw(self, surface, world_offset, tema):
        real_x = self.x + world_offset
        angulo_deg = math.degrees(math.atan(derivada_numerica(real_x)))

        p_surface = pygame.Surface((40, 50), pygame.SRCALPHA)
        piel = tema["piel"]
        camiseta = tema["camiseta"]
        pantalon = tema["atleta"]

        cx, cy = 20, 25

        if self.is_crouching:
            pygame.draw.circle(p_surface, piel, (cx + 6, cy + 8), 8)
            pygame.draw.circle(p_surface, pantalon, (cx + 9, cy + 6), 2)
            pygame.draw.rect(p_surface, camiseta, (cx - 10, cy + 12, 22, 10), border_radius=4)
            pygame.draw.line(p_surface, pantalon, (cx - 10, cy + 20), (cx - 14, cy + 24), 3)
        else:
            pygame.draw.circle(p_surface, piel, (cx, cy - 12), 8)
            pygame.draw.circle(p_surface, pantalon, (cx + 3, cy - 14), 2)
            pygame.draw.rect(p_surface, camiseta, (cx - 5, cy - 5, 10, 19), border_radius=3)

            swing = math.sin(self.anim_timer) * 8
            pygame.draw.line(p_surface, piel, (cx, cy), (cx + int(swing), cy + 8), 3)
            pygame.draw.line(p_surface, pantalon, (cx, cy + 14), (cx - 6 + int(swing), cy + 24), 3)
            pygame.draw.line(p_surface, pantalon, (cx, cy + 14), (cx + 6 - int(swing), cy + 24), 3)

        rotated = pygame.transform.rotate(p_surface, -angulo_deg)
        rect = rotated.get_rect(center=(int(self.x), int(self.y - 25)))
        surface.blit(rotated, rect.topleft)



#  OBSTÁCULOS Y CORAZONES

class Obstacle:
    def __init__(self, world_x, peso_dron=0.5):
        self.world_x = world_x
        self.tipo = 'alto' if random.random() < peso_dron else 'bajo'
        self.width = 24
        if self.tipo == 'bajo':
            self.base, self.techo = ROCA_BASE, ROCA_TECHO
        else:
            self.base, self.techo = DRON_BASE, DRON_TECHO
        self.height = int(self.techo - self.base)
        self.golpeado = False   # el jugador choco con el: no da puntos
        self.superado = False   # ya se conto como esquivado

    def get_screen_x(self, world_offset):
        return self.world_x - world_offset

    def get_rect(self, world_offset):
        screen_x = self.get_screen_x(world_offset)
        ground_y = int(round(terreno_f(self.world_x)))
        screen_y = ground_y - int(self.techo)
        return pygame.Rect(int(screen_x), screen_y, self.width, self.height)

    def get_banda_vertical(self):
        """Franja que ocupa el obstáculo, medida en altura sobre SU suelo.

        - Piedra ('bajo'):  0 a 28 px  -> se salta (el salto llega a 47.45 px).
        - Dron   ('alto'): 34 a 62 px  -> NO se salta: hay que agacharse.
        """
        return self.base, self.techo

    def draw(self, surface, world_offset, tema):
        rect = self.get_rect(world_offset)
        estilo = tema.get("estilo", "normal")
        if self.tipo == 'bajo':
            if estilo == "halloween":
                dibujar_tumba(surface, rect, tema["piedra"])
            elif estilo == "navidad":
                dibujar_regalo(surface, rect, tema["piedra"], tema["dron_detalle"])
            else:
                dibujar_piedra(surface, rect, tema["piedra"])
        else:
            if estilo == "halloween":
                dibujar_fantasma(surface, rect, tema["dron"],
                                 tema["dron_detalle"], tema["dron_ojo"])
            elif estilo == "navidad":
                dibujar_bola(surface, rect, tema["dron"],
                             tema["dron_detalle"], tema["dron_ojo"])
            else:
                dibujar_dron(surface, rect, tema["dron"],
                             tema["dron_detalle"], tema["dron_ojo"])


class Corazon:
    """Vida extra recogible que aparece a lo largo del camino."""

    def __init__(self, world_x, altura=30):
        self.world_x = world_x
        self.altura = altura
        self.width, self.height = 18, 16

    def get_screen_x(self, world_offset):
        return self.world_x - world_offset

    def get_rect(self, world_offset):
        cx = self.get_screen_x(world_offset)
        cy = terreno_f(self.world_x) - self.altura
        return pygame.Rect(int(cx - 9), int(cy - 8), self.width, self.height)

    def draw(self, surface, world_offset, tema, frame):
        cx = self.get_screen_x(world_offset)
        cy = terreno_f(self.world_x) - self.altura + math.sin(frame * 0.12) * 3
        dibujar_corazon(surface, cx, cy, tema["vida"], 1.15)


class Letra:
    """Letra coleccionable: completa la fórmula que se ve en el HUD."""

    def __init__(self, world_x, altura, letra):
        self.world_x = world_x
        self.altura = altura
        self.letra = letra
        self.width = self.height = 26

    def get_screen_x(self, world_offset):
        return self.world_x - world_offset

    def get_rect(self, world_offset):
        cx = self.get_screen_x(world_offset)
        cy = terreno_f(self.world_x) - self.altura
        return pygame.Rect(int(cx - 13), int(cy - 13), self.width, self.height)

    def draw(self, surface, world_offset, tema, frame):
        cx = self.get_screen_x(world_offset)
        cy = terreno_f(self.world_x) - self.altura + math.sin(frame * 0.12) * 3
        fondo = tuple(max(0, c - 30) for c in tema["fondo"])
        dibujar_letra(surface, cx, cy, self.letra, tema["acento"], fondo, frame)


class Popup:
    """Texto flotante breve (+1 VIDA, +100...)."""

    def __init__(self, texto, x, y, color):
        self.texto = texto
        self.x = x
        self.y = y
        self.color = color
        self.t = 0

    def draw(self, surface):
        surf = font_s.render(self.texto, True, self.color)
        surf.set_alpha(max(0, 255 - self.t * 5))
        surface.blit(surf, (int(self.x - surf.get_width() / 2), int(self.y - self.t * 0.7)))



#  COLISIÓN

def colisiona(player, obs, world_offset):
    """Colisión en dos fases, medida sobre una referencia vertical común.

    Fase 1 (horizontal): los rectángulos deben solaparse en X.
    Fase 2 (vertical): se comparan franjas de altura sobre el SUELO DEL
    OBSTÁCULO. Al usar la misma referencia para ambos cuerpos, la pendiente
    del terreno ya no "regala" altura y la colisión coincide exactamente con
    lo que se dibuja: si los sprites se solapan, hay choque; si no, no.
    """
    p_rect = player.get_rect()
    o_rect = obs.get_rect(world_offset)
    if not (p_rect.right > o_rect.left and p_rect.left < o_rect.right):
        return False

    suelo_obs = int(round(terreno_f(obs.world_x)))
    p_base, p_techo = player.get_banda_vertical(suelo_obs)
    o_base, o_techo = obs.get_banda_vertical()
    return p_base < o_techo and p_techo > o_base



#  ESTADO DE UNA PARTIDA (se puede avanzar sin dibujar)

def nuevo_hueco(ultimo_x, speed, nivel=0, agresividad=0):
    """Distancia al próximo obstáculo.

    La separación mínima crece con la velocidad para que el salto (27 frames en
    el aire) siga siendo posible; el margen aleatorio se acorta con el nivel,
    así a partir de 10.000 puntos los obstáculos salen más seguidos.

    `agresividad` (solo Ultramegasuperextremo) aprieta el margen aleatorio:
    los obstáculos casi no dejan aire de respiración entre sí.
    """
    minimo = max(230, int(28 * speed) + 70 - nivel * 10)
    extra = max(max(80, 230 - nivel * 50) - agresividad * 80, 0)
    return ultimo_x + random.randint(minimo, minimo + extra)


class Sesion:
    def __init__(self):
        self.cfg = DIFICULTADES[options_config["dificultad"]]
        self.tema = TEMAS[options_config["tema"]]
        self.player = Player()
        self.base_speed = self.cfg["velocidad"]
        self.techo_velocidad = self.cfg["techo"]
        self.vidas = self.cfg["vidas"]
        self.speed = self.base_speed
        self.world_offset = 0.0
        self.obstacles = [Obstacle(900, self.cfg["peso_dron"]),
                          Obstacle(1350, self.cfg["peso_dron"])]
        self.invulnerable = 0
        self.corazones = []
        self.popups = []
        self.proximo_corazon = PUNTOS_POR_VIDA
        self.game_over = False
        self.pausa = False
        self.frame = 0
        # Bonus: letras de fórmulas y niveles de velocidad
        self.letras = []
        self.proxima_letra = 1200
        self.formula_indice = 0
        self.formula_progreso = 0
        self.formulas_completas = 0
        self.nivel = 0
        # contadores informativos (útiles para pruebas y estadísticas)
        self.golpes = 0
        self.vidas_ganadas = 0
        self.esquivados = 0
        self.letras_recogidas = 0

    def formula_actual(self):
        """(palabra, nombre del método) de la fórmula en curso."""
        return FORMULAS[self.formula_indice]

    def _separada(self, x, margen=170, entre_recogibles=110):
        """True si x está lejos de obstáculos y de otros recogibles."""
        for o in self.obstacles:
            if abs(x - o.world_x) < margen:
                return False
        for grupo in (self.corazones, self.letras):
            for obj in grupo:
                if abs(x - obj.world_x) < entre_recogibles:
                    return False
        return True

    def _x_libre(self, x, margen=170):
        """Desplaza x hasta encontrar un hueco limpio."""
        for _ in range(16):
            if self._separada(x, margen):
                return x
            x += 80
        return x

    def _reubicar_recogibles(self, obs):
        """Si un obstáculo nuevo cae sobre un recogible, lo aparta. Los dos
        están todavía fuera de pantalla, así que el salto no se ve."""
        for grupo in (self.corazones, self.letras):
            for obj in grupo:
                if abs(obj.world_x - obs.world_x) < 170:
                    obj.world_x = self._x_libre(obs.world_x + 220)

    def saltar(self):
        """Salto pedido por el jugador (sin puntos: se cobran al esquivar)."""
        salto = self.player.jump()
        if salto:
            audio.sonar("salto")
        return salto

    def agacharse(self, presionado):
        """Agacharse/incorporarse (sin puntos: se cobran al esquivar)."""
        self.player.crouch(presionado)

    def avanzar(self):
        """Un frame de simulación. No dibuja nada."""
        if self.game_over or self.pausa:
            return

        self.frame += 1
        p = self.player
        tema = self.tema

        # Cada 10.000 puntos sube el nivel: más velocidad y menos hueco.
        nivel_previo = self.nivel
        self.nivel = min(p.score // PUNTOS_POR_NIVEL, NIVELES_MAXIMOS)
        if self.nivel > nivel_previo:
            self.popups.append(Popup(f"¡NIVEL {self.nivel + 1}!",
                                     p.x, p.y - 122, tema["acento"]))
            self.popups.append(Popup("MÁS RÁPIDO", p.x, p.y - 102, tema["hud"]))
            audio.sonar("nivel")

        # La velocidad sube con cada N obstáculos esquivados (según la
        # dificultad) y con cada nivel.
        self.speed = min(self.techo_velocidad + self.nivel * VELOCIDAD_POR_NIVEL,
                         self.base_speed + (self.esquivados // self.cfg["esquivados_por_paso"]) * 0.5
                         + self.nivel * VELOCIDAD_POR_NIVEL)
        self.world_offset += self.speed
        if self.invulnerable > 0:
            self.invulnerable -= 1

        # --- obstáculos esquivados: +100 solo si pasó sin chocar ---
        for obs in self.obstacles:
            if obs.superado or obs.golpeado:
                continue
            if obs.world_x + obs.width < p.x - 12 + self.world_offset:
                obs.superado = True
                p.score += PUNTOS_POR_OBSTACULO
                self.esquivados += 1
                self.popups.append(Popup(f"+{PUNTOS_POR_OBSTACULO}", p.x,
                                         p.y - 96, tema["acento"]))
                audio.sonar("punto")

        # --- obstáculos: reciclar y mantener al menos 2 en camino ---
        while self.obstacles and self.obstacles[0].get_screen_x(self.world_offset) < -60:
            self.obstacles.pop(0)
        while len(self.obstacles) < 2:
            ultimo = self.obstacles[-1].world_x if self.obstacles else self.world_offset + WIDTH + 120
            nuevo = Obstacle(nuevo_hueco(ultimo, self.speed, self.nivel,
                                         self.cfg["agresividad"]),
                             self.cfg["peso_dron"])
            self.obstacles.append(nuevo)
            self._reubicar_recogibles(nuevo)

        # --- corazones de vida ---
        if p.score >= self.proximo_corazon:
            self.proximo_corazon += PUNTOS_POR_VIDA
            x = self._x_libre(self.world_offset + WIDTH + random.randint(140, 320))
            self.corazones.append(Corazon(x))

        for cor in self.corazones[:]:
            if cor.world_x - self.world_offset < -40:
                self.corazones.remove(cor)
                continue
            if p.get_rect().inflate(8, 8).colliderect(cor.get_rect(self.world_offset)):
                self.corazones.remove(cor)
                if self.vidas < VIDAS_MAXIMAS:
                    self.vidas += 1
                    self.vidas_ganadas += 1
                    self.popups.append(Popup("+1 VIDA", p.x, p.y - 96, tema["vida"]))
                    audio.sonar("vida")
                else:
                    p.score += BONO_VIDA_LLENA
                    self.popups.append(Popup(f"+{BONO_VIDA_LLENA}", p.x, p.y - 96, tema["acento"]))
                    audio.sonar("vida_llena")

        # --- letras: se recogen en orden para completar la fórmula ---
        if not self.letras and self.world_offset >= self.proxima_letra:
            palabra, _metodo = self.formula_actual()
            letra = palabra[self.formula_progreso]
            x = self._x_libre(self.world_offset + WIDTH + random.randint(60, 200))
            self.letras.append(Letra(x, random.choice((30, 66, 80)), letra))
            self.proxima_letra = x + random.randint(420, 640)

        for let in self.letras[:]:
            if let.world_x - self.world_offset < -40:
                self.letras.remove(let)
                # la misma letra vuelve a salir un poco más adelante
                self.proxima_letra = min(self.proxima_letra,
                                         self.world_offset + random.randint(340, 520))
                continue
            if p.get_rect().inflate(12, 12).colliderect(let.get_rect(self.world_offset)):
                self.letras.remove(let)
                self.letras_recogidas += 1
                self.formula_progreso += 1
                palabra, _metodo = self.formula_actual()
                if self.formula_progreso >= len(palabra):
                    p.score += BONO_FORMULA
                    self.formulas_completas += 1
                    self.popups.append(Popup(f"+{BONO_FORMULA}", p.x,
                                             p.y - 118, tema["acento"]))
                    self.popups.append(Popup(f"¡{palabra}!", p.x, p.y - 98,
                                             tema["hud"]))
                    audio.sonar("formula")
                    self.formula_indice = (self.formula_indice + 1) % len(FORMULAS)
                    self.formula_progreso = 0
                else:
                    self.popups.append(Popup(let.letra, p.x, p.y - 98,
                                             tema["acento"]))
                    audio.sonar("letra")

        # --- choques ---
        # Un obstáculo que toca al atleta queda marcado como golpeado aunque esté
        # en periodo de gracia: así no regala puntos por "pasar" a través de él.
        for obs in self.obstacles[:]:
            if obs.golpeado or obs.superado:
                continue
            if colisiona(p, obs, self.world_offset):
                obs.golpeado = True
                if self.invulnerable > 0:
                    continue                 # gracia: no cuesta vida
                self.vidas -= 1
                self.golpes += 1
                self.invulnerable = FRAMES_INVULNERABLE
                if len(self.obstacles) > 1:
                    self.obstacles.remove(obs)
                if self.vidas <= 0:
                    self.game_over = True
                    audio.sonar("game_over")
                else:
                    audio.sonar("choque")
                break

        p.update(self.world_offset, self.speed)

        for pop in self.popups[:]:
            pop.t += 1
            if pop.t > 50:
                self.popups.remove(pop)



#  DIBUJO DE LA ESCENA (compartido por el juego y las capturas de prueba)

def dibujar_escena(surface, sesion, tema, nubes, player_name="", name_entered=False):
    """Pinta un frame completo de la partida sobre `surface` (960x540)."""
    surface.blit(fondo_tema(tema), (0, 0))

    # --- Nubes con parallax ---
    for nube in nubes:
        if not sesion.game_over and not sesion.pausa:
            nube["x"] -= sesion.speed * 0.18
        if nube["x"] < -70:
            nube["x"] = WIDTH + random.uniform(10, 160)
            nube["y"] = random.uniform(30, 150)
            nube["s"] = random.uniform(0.7, 1.4)
        dibujar_nube(surface, nube["x"], nube["y"], tema["nube"], nube["s"])

    # --- Suelo, corazones, obstáculos y atleta ---
    dibujar_suelo(surface, sesion.world_offset, tema)

    for cor in sesion.corazones:
        cor.draw(surface, sesion.world_offset, tema, sesion.frame)

    for let in sesion.letras:
        let.draw(surface, sesion.world_offset, tema, sesion.frame)

    for obs in sesion.obstacles:
        obs.draw(surface, sesion.world_offset, tema)

    parpadeo = sesion.invulnerable > 0 and (sesion.frame // 4) % 2 == 0
    if not parpadeo:
        sesion.player.draw(surface, sesion.world_offset, tema)

    for pop in sesion.popups:
        pop.draw(surface)

    # --- Nieve (solo temas que la definen) ---
    if tema.get("nieve"):
        dibujar_nieve(surface, tema["nieve"], sesion.frame)

    # --- HUD ---
    derivada_actual = derivada_numerica(sesion.player.x + sesion.world_offset)
    surface.blit(font_s.render(f"f'(x) = {derivada_actual:+.3f}", True, tema["hud_tenue"]), (18, 14))
    surface.blit(font_s.render(f"h    = {sesion.player.altura_vuelo():5.2f} px", True,
                               tema["hud_tenue"]), (18, 34))

    # Fórmula en curso: método + letras conseguidas
    palabra, metodo = sesion.formula_actual()
    surface.blit(font_s.render(f"MÉTODO: {metodo}", True, tema["hud_tenue"]), (18, 58))
    x_letra = 18
    for i, ch in enumerate(palabra):
        color = tema["acento"] if i < sesion.formula_progreso else tema["hud_tenue"]
        gl = font_m.render(ch, True, color)
        surface.blit(gl, (x_letra, 78))
        x_letra += gl.get_width() + 6

    hi = max([e["score"] for e in high_scores] + [0])
    hi = max(hi, sesion.player.score)
    marcador = font_m.render(f"{sesion.player.score:05d}", True, tema["hud"])
    record = font_s.render(f"HI {hi:05d}", True, tema["hud_tenue"])
    surface.blit(marcador, (WIDTH - 20 - marcador.get_width(), 12))
    surface.blit(record, (WIDTH - 30 - marcador.get_width() - record.get_width(), 17))

    # Dificultad en juego (solo si no es la de siempre)
    if options_config["dificultad"] != "Normal":
        dif = font_s.render(options_config["dificultad"], True, tema["hud_tenue"])
        surface.blit(dif, (WIDTH // 2 - dif.get_width() // 2, 14))

    for i in range(sesion.vidas):
        dibujar_corazon(surface, WIDTH - 24 - i * 22, 52, tema["vida"], 1.0)

    if sesion.nivel > 0:
        txt = font_s.render(f"NIVEL {sesion.nivel + 1}", True, tema["acento"])
        surface.blit(txt, (WIDTH - 20 - txt.get_width(), 92))

    # --- Superposiciones ---
    if sesion.pausa and not sesion.game_over:
        overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 150))
        surface.blit(overlay, (0, 0))
        txt = font_xl.render("PAUSA", True, (255, 255, 255))
        surface.blit(txt, (WIDTH // 2 - txt.get_width() // 2, HEIGHT // 2 - 50))
        sub = font_s.render("ESC / P continuar   ·   TAB reiniciar", True, (220, 220, 220))
        surface.blit(sub, (WIDTH // 2 - sub.get_width() // 2, HEIGHT // 2 + 12))

    if sesion.game_over:
        overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 170))
        surface.blit(overlay, (0, 0))

        over = font_xl.render("GAME OVER", True, (240, 70, 70))
        surface.blit(over, (WIDTH // 2 - over.get_width() // 2, 110))

        pts = font_l.render(f"PUNTAJE: {sesion.player.score}", True, (255, 255, 255))
        surface.blit(pts, (WIDTH // 2 - pts.get_width() // 2, 178))

        medalla = asignar_medalla(sesion.player.score)
        med = font_m.render(f"Medalla: {medalla}", True, color_medalla(medalla))
        surface.blit(med, (WIDTH // 2 - med.get_width() // 2, 220))

        if not name_entered:
            prompt = font_m.render(f"Nombre: {player_name}_", True, (255, 255, 255))
            surface.blit(prompt, (WIDTH // 2 - prompt.get_width() // 2, 275))
            ayuda = font_s.render("ENTER guardar   ·   TAB reintentar", True, (200, 200, 200))
            surface.blit(ayuda, (WIDTH // 2 - ayuda.get_width() // 2, 315))
        else:
            ok = font_m.render("¡Guardado!", True, (0, 255, 180))
            surface.blit(ok, (WIDTH // 2 - ok.get_width() // 2, 275))
            ayuda = font_s.render("ESPACIO menú   ·   TAB reintentar", True, (200, 200, 200))
            surface.blit(ayuda, (WIDTH // 2 - ayuda.get_width() // 2, 315))



#  PARTIDA (entrada + bucle)

def run_game():
    sesion = Sesion()
    audio.musica("juego")            # tema alegre durante la partida
    tema = sesion.tema
    player_name = ""
    name_entered = False

    nubes = [{"x": random.uniform(0, WIDTH), "y": random.uniform(30, 150),
              "s": random.uniform(0.7, 1.4)} for _ in range(3)]

    while True:
        # --- Eventos ---
        keys = pygame.key.get_pressed()
        for event in pygame.event.get():
            if evento_global(event):
                continue
            if event.type == pygame.KEYDOWN:
                if sesion.game_over:
                    if not name_entered:
                        if event.key == pygame.K_RETURN and player_name.strip() != "":
                            high_scores.append({
                                "name": player_name.strip(),
                                "score": sesion.player.score,
                                "medal": asignar_medalla(sesion.player.score),
                            })
                            high_scores.sort(key=lambda x: x["score"], reverse=True)
                            name_entered = True
                        elif event.key == pygame.K_TAB:
                            return "reiniciar"
                        elif event.key == pygame.K_BACKSPACE:
                            player_name = player_name[:-1]
                        elif len(player_name) < 10 and event.unicode.isalnum():
                            player_name += event.unicode
                    else:
                        if event.key == pygame.K_SPACE:
                            return "menu"
                        if event.key == pygame.K_TAB:
                            return "reiniciar"
                elif event.key in (pygame.K_ESCAPE, pygame.K_p):
                    sesion.pausa = not sesion.pausa
                elif event.key == pygame.K_m:
                    audio.alternar_musica()
                elif sesion.pausa:
                    if event.key in (pygame.K_SPACE, pygame.K_UP):
                        sesion.pausa = False
                    elif event.key == pygame.K_TAB:
                        return "reiniciar"
                elif event.key in (pygame.K_SPACE, pygame.K_UP):
                    sesion.saltar()

        # --- Simulación ---
        if not sesion.game_over and not sesion.pausa:
            sesion.agacharse(keys[pygame.K_DOWN])
        sesion.avanzar()

        # --- Escena + HUD ---
        dibujar_escena(screen, sesion, tema, nubes, player_name, name_entered)

        presentar()
        clock.tick(60)



#  MENÚS

def menu_high_scores():
    tema = TEMAS[options_config["tema"]]
    while True:
        screen.blit(fondo_tema(tema), (0, 0))
        title = font_l.render("MEJORES PUNTUACIONES", True, tema["acento"])
        screen.blit(title, (WIDTH // 2 - title.get_width() // 2, 50))

        if len(high_scores) == 0:
            empty = font_m.render("Aún no hay récords. ¡Juega y sé el primero!", True, tema["hud_tenue"])
            screen.blit(empty, (WIDTH // 2 - empty.get_width() // 2, 240))
        else:
            for i, entry in enumerate(high_scores[:5]):
                txt = f"{i+1}. {entry['name']:<10} {entry['score']:>5} pts   [{entry['medal']}]"
                surf = font_m.render(txt, True, tema["hud"])
                screen.blit(surf, (WIDTH // 2 - 250, 140 + i * 45))

        back = font_s.render("ESC para volver al menú", True, tema["hud_tenue"])
        screen.blit(back, (WIDTH // 2 - back.get_width() // 2, HEIGHT - 50))

        for event in pygame.event.get():
            if evento_global(event):
                continue
            if event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                return

        presentar()
        clock.tick(60)


def menu_options():
    tema = TEMAS[options_config["tema"]]
    while True:
        audio.musica("menu")
        screen.blit(fondo_tema(tema), (0, 0))
        title = font_l.render("MENÚ DE OPCIONES", True, tema["acento"])
        screen.blit(title, (WIDTH // 2 - title.get_width() // 2, 60))

        filas = [
            f"1. Dificultad: < {options_config['dificultad']} >   (D para cambiar)",
            f"2. Tema visual: < {options_config['tema']} >   (T para cambiar)",
            f"3. Música: < {'ON' if audio.musica_activa() else 'OFF'} >   (M para cambiar)",
            f"4. Vidas: {VIDAS_INICIALES} iniciales, hasta {VIDAS_MAXIMAS} con corazones",
            "5. Pausa: ESC o P   ·   F11 pantalla completa",
        ]
        if options_config["dificultad"] == "Ultramegasuperextremo":
            filas.append("")
            filas.append("⚠ 1 sola vida, velocidad brutal: llegar a 2000 pts   "
                         "es casi imposible")
        else:
            filas.append("")
            filas.append(f"Dificultad actual: {options_config['dificultad']} "
                         f"arranca a {DIFICULTADES[options_config['dificultad']]['velocidad']} px/frame")
        for i, txt in enumerate(filas):
            surf = font_m.render(txt, True, tema["hud"])
            screen.blit(surf, (WIDTH // 2 - 320, 165 + i * 45))

        back = font_s.render("ESC para volver al menú", True, tema["hud_tenue"])
        screen.blit(back, (WIDTH // 2 - back.get_width() // 2, HEIGHT - 50))

        for event in pygame.event.get():
            if evento_global(event):
                continue
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    return
                elif event.key == pygame.K_d:
                    i = ORDEN_DIFICULTAD.index(options_config["dificultad"])
                    options_config["dificultad"] = ORDEN_DIFICULTAD[(i + 1) % len(ORDEN_DIFICULTAD)]
                    audio.sonar("blip")
                elif event.key == pygame.K_t:
                    i = ORDEN_TEMAS.index(options_config["tema"])
                    options_config["tema"] = ORDEN_TEMAS[(i + 1) % len(ORDEN_TEMAS)]
                    tema = TEMAS[options_config["tema"]]
                    audio.sonar("blip")
                elif event.key == pygame.K_m:
                    audio.alternar_musica()
                    audio.sonar("blip")

        presentar()
        clock.tick(60)


def main_menu():
    selected = 0
    opciones = ["Jugar", "Mejor puntuación con nombre", "Opciones", "Salir"]

    while True:
        audio.musica("menu")         # tema de menú, distinto al del juego
        tema = TEMAS[options_config["tema"]]
        screen.blit(fondo_tema(tema), (0, 0))
        title = font_l.render("RUNNER MATEMÁTICO", True, tema["acento"])
        sub = font_s.render("A T L E T A   D E F I N I T I V O", True, tema["hud_tenue"])
        screen.blit(title, (WIDTH // 2 - title.get_width() // 2, 70))
        screen.blit(sub, (WIDTH // 2 - sub.get_width() // 2, 112))

        for i, opt in enumerate(opciones):
            color = tema["acento"] if i == selected else tema["hud_tenue"]
            prefix = "> " if i == selected else "  "
            surf = font_l.render(prefix + opt, True, color)
            screen.blit(surf, (WIDTH // 2 - 190, 200 + i * 55))

        pie = font_s.render("↑↓ mover   ·   ENTER elegir   ·   M música   ·   F11 pantalla completa",
                            True, tema["hud_tenue"])
        screen.blit(pie, (WIDTH // 2 - pie.get_width() // 2, HEIGHT - 40))

        for event in pygame.event.get():
            if evento_global(event):
                continue
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_UP:
                    selected = (selected - 1) % len(opciones)
                    audio.sonar("blip")
                elif event.key == pygame.K_DOWN:
                    selected = (selected + 1) % len(opciones)
                    audio.sonar("blip")
                elif event.key == pygame.K_RETURN:
                    if selected == 0:
                        while run_game() == "reiniciar":
                            pass
                    elif selected == 1:
                        menu_high_scores()
                    elif selected == 2:
                        menu_options()
                    elif selected == 3:
                        pygame.quit()
                        sys.exit()
                elif event.key == pygame.K_m:
                    audio.alternar_musica()

        presentar()
        clock.tick(60)


if __name__ == "__main__":
    main_menu()
