#!/usr/bin/env python3
"""Arma el manual de Órbita 84 (controles, naves, poderes y los diez expedientes con su historia)
en un solo archivo: publicar/manual/manual.html, en español e inglés.
Los dibujos salen de juego/datos.lua y las tomas de publicar/manual/tomas/n1..n10.png (84x48).
Uso: python3 herramientas/manual.py"""
import base64
import html
import io
import os
import re

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SALIDA = os.path.join(RAIZ, "publicar", "manual")
TOMAS = os.path.join(SALIDA, "tomas")

TINTA = (66, 82, 61, 255)
MEDIO = (138, 166, 143, 255)

_fuente = open(os.path.join(RAIZ, "juego", "datos.lua"), encoding="utf-8").read()
DIB = {}
for _m in re.finditer(r'(\w+)\s*=\s*\{\s*((?:"[^"]*"\s*,?\s*(?:--[^\n]*\n)?\s*)+)\}', _fuente):
    DIB[_m.group(1)] = re.findall(r'"([^"]*)"', _m.group(2))
# las cápsulas se arman en el juego: la mira de radar con el ícono adentro
MIRA = ["##...##", "#.....#", ".......", ".......", ".......", "#.....#", "##...##"]
for _n in ["triple", "rayo", "escudo", "vida", "tiempo", "sonda", "abduccion"]:
    _i = DIB["icono_" + _n]
    DIB["mejora_" + _n] = [f[:2] + _i[y - 1] + f[5:] if 1 <= y <= len(_i) else f for y, f in enumerate(MIRA)]


def png(img):
    b = io.BytesIO()
    img.save(b, "PNG", optimize=True)
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def sprite(nombre, escala=4, alt=""):
    filas = DIB[nombre]
    w, h = len(filas[0]), len(filas)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, fila in enumerate(filas):
        for x, c in enumerate(fila):
            if c == "#":
                img.putpixel((x, y), TINTA)
            elif c == "+":
                img.putpixel((x, y), MEDIO)
    return f'<img class="px" src="{png(img)}" width="{w * escala}" height="{h * escala}" alt="{html.escape(alt)}">'


def toma(n, alt):
    img = Image.open(os.path.join(TOMAS, f"n{n}.png")).convert("RGB")
    return f'<img class="px toma" src="{png(img)}" width="84" height="48" alt="{html.escape(alt)}">'


def t(es, en):
    """texto en los dos idiomas (se muestra uno según html[lang])"""
    return f'<span lang="es">{es}</span><span lang="en">{en}</span>'


# ---------------------------------------------------------------- contenido

CONTROLES = [
    (t("Mover", "Move"), t("Flechas o WASD", "Arrows or WASD"), t("Cruceta o stick", "D-pad or stick"), t("Cruceta", "D-pad")),
    (t("Disparar (mantén para cargar)", "Shoot (hold to charge)"), "Z / Space", "A", "A"),
    (t("Especial: rayo o pulso", "Special: beam or pulse"), "X", "B", "B"),
    (t("Usar el poder guardado", "Use the stored power"), "C", "Y / X", "Y"),
    (t("Saltar (en tierra)", "Jump (on the ground)"), t("Arriba", "Up"), t("Arriba", "Up"), t("Arriba", "Up")),
    (t("Menú y pausa", "Menu and pause"), "Enter", "Start", "START"),
    (t("Salir de la pausa", "Quit from pause"), "Tab", "Select", "SELECT"),
]

MENU = [
    (t("JUGAR", "PLAY"), t("Empieza la partida con el prólogo.", "Starts the game with the prologue.")),
    (t("NAVE", "SHIP"), t("Izquierda y derecha cambian de nave; con A ves su ficha.", "Left and right switch ships; A opens its card.")),
    (t("RECORDS", "SCORES"), t("Los 10 mejores, con la nave usada y hasta qué expediente llegaron.", "The top 10, with the ship used and how far each run got.")),
    (t("OPCIONES", "OPTIONS"), t("Sonido, color de la pantalla (verde, azul, ámbar o gris) e idioma.", "Sound, screen color (green, blue, amber or gray) and language.")),
]

NAVES = [
    ("nave", t("Cabina", "Cockpit"), t("Disparo simple y <b>rayo</b>: una línea que atraviesa toda la pantalla.", "Single shot and <b>beam</b>: a line that crosses the whole screen.")),
    ("nave_interceptor", t("Interceptor", "Interceptor"), t("Disparo doble y <b>pulso</b>: una onda que crece desde la nave y borra las balas cercanas.", "Double shot and <b>pulse</b>: a wave that grows from the ship and wipes nearby bullets.")),
    ("oruga", t("Oruga", "Tank"), t("En tierra la nave aterriza y se transforma. Salta con Arriba; el disparo lanza también cohetes que suben y buscan al blanco. El rayo sale hacia arriba, o hacia adelante si mantienes Derecha.", "On the ground the ship lands and transforms. Jump with Up; shooting also fires rockets that climb and seek a target. The beam fires upward, or forward if you hold Right.")),
    ("batiscafo", t("Batiscafo", "Bathyscaphe"), t("Bajo el agua la nave se vuelve batiscafo: tiene inercia y lanza torpedos que salen lentos y van tomando velocidad.", "Under water the ship becomes a bathyscaphe: it drifts with inertia and fires torpedoes that start slow and speed up.")),
]

ARMAS = [
    (t("Disparo", "Shot"), t("Mantén A y la nave dispara sola.", "Hold A and the ship keeps firing.")),
    (t("Obús cargado", "Charged shell"), t("Mientras mantienes A se carga un punto delante del cañón. Al soltarlo sale un obús: cuanto más cargado, más daño (de 2 a 6).", "While you hold A a dot charges in front of the cannon. Release it to fire a shell: the longer the charge, the more damage (2 to 6).")),
    (t("Obús lleno", "Full shell"), t("Cuando el punto titila la carga está completa: el obús sale más grande, <b>borra las balas enemigas</b> que toca y <b>corta los anillos</b> de la pirámide.", "When the dot blinks the charge is full: the shell comes out bigger, <b>wipes out enemy bullets</b> it touches and <b>cuts through</b> the pyramid's rings.")),
    (t("Especial", "Special"), t("B gasta una carga de rayo o pulso (los rayos que ves arriba). Las cápsulas de rayo dan dos más.", "B spends one beam or pulse charge (the bolts shown at the top). Beam capsules give two more.")),
]

CAPSULAS = [
    ("triple", t("Triple", "Triple"), t("12 s de dos balas extra en diagonal.", "12 s of two extra diagonal bullets."), False),
    ("rayo", t("Rayo", "Beam"), t("Dos cargas más de tu especial.", "Two more charges of your special."), False),
    ("vida", t("Vida", "Life"), t("Una vida más (máximo 5). Es la más rara.", "One more life (up to 5). The rarest one."), False),
    ("escudo", t("Escudo", "Shield"), t("6 s de un marco alrededor de la nave que aguanta los golpes.", "6 s of a frame around the ship that takes the hits."), True),
    ("tiempo", t("Tiempo perdido", "Lost time"), t("6 s en que enemigos, balas y jefe van cinco veces más lento; tú no. Dejan estela, las esquinas de la pantalla marcan lo que queda y suena un tic tac.", "6 s where enemies, bullets and the boss move five times slower; you don't. They leave trails, the screen corners show what's left and a clock ticks."), True),
    ("sonda", t("Sonda", "Probe"), t("15 s de una nave compañera que te sigue y dispara recto. En tierra suelta cada segundo un cohete que busca al blanco.", "15 s of a companion ship that follows you and fires straight ahead. On the ground it releases a seeking rocket every second."), True),
    ("abduccion", t("Abducción", "Abduction"), t("8 s de un haz que se traga las balas de adelante. Al acabarse te las devuelve en abanico como disparos tuyos.", "8 s of a beam that swallows bullets ahead. When it ends it fires them back in a fan as your own shots."), True),
]

# (caso, escenario, lo real, el jefe, dibujo del jefe, fases, frase del mapa)
EXPEDIENTES = [
    ("Roswell 1947", t("Espacio abierto", "Open space"),
     t("En julio de 1947 un ranchero encontró restos metálicos cerca de Roswell, Nuevo México. El ejército anunció que había recuperado un «disco volador» y al día siguiente dijo que era un globo meteorológico.",
       "In July 1947 a rancher found metal debris near Roswell, New Mexico. The Army announced it had recovered a \"flying disc\" and the next day said it was a weather balloon."),
     t("El platillo de Roswell", "The Roswell saucer"), "jefe",
     [t("Abanicos alternos de cinco y cuatro balas: el hueco de uno es la bala del otro.", "Alternating fans of five and four bullets: one fan's gap is the other's bullet."),
      t("Se queda al centro y suelta muros con un hueco; la silueta del muro aparece antes en tono medio.", "It holds the center and releases walls with one gap; the wall's outline shows first in a lighter tone."),
      t("Espiral hacia adelante y, cada tanto, cuatro balas que se frenan y te buscan.", "A forward spiral and, now and then, four bullets that stop and then home in.")],
     "UNA LUZ. NADA MAS"),
    ("Bélgica 1990", t("Sobre la cordillera", "Over the mountains"),
     t("Entre 1989 y 1990 miles de personas en Bélgica vieron un triángulo oscuro con tres luces en las puntas. La noche del 30 de marzo de 1990 la fuerza aérea envió dos F-16 a perseguirlo.",
       "Between 1989 and 1990 thousands of people in Belgium saw a dark triangle with three lights at its corners. On the night of 30 March 1990 the air force sent two F-16s after it."),
     t("La tenaza (el Triángulo Negro)", "The pincer (the Black Triangle)"), "tenaza",
     [t("Disparo doble recto desde las pinzas.", "A straight double shot from the pincers."),
      t("Tijera: las pinzas disparan en diagonal y las balas se cruzan.", "Scissors: the pincers fire diagonally and the bullets cross."),
      t("Embestida doble. Antes tiembla y fija la altura: apártate de esa línea.", "A double ram. It shakes first and locks its height: get off that line.")],
     "OTRA. MUY LEJOS"),
    ("Phoenix 1997", t("En tierra, entre ruinas: la nave se vuelve oruga", "On the ground, among ruins: the ship becomes a tank"),
     t("El 13 de marzo de 1997 miles de personas en Arizona vieron una enorme formación de luces en V cruzar el cielo de Phoenix en silencio.",
       "On 13 March 1997 thousands of people in Arizona saw a huge V-shaped formation of lights silently cross the sky over Phoenix."),
     t("La nodriza (la V de Phoenix)", "The mothership (the Phoenix V)"), "nodriza",
     [t("Bombas desde las patas y rodantes por el suelo.", "Bombs from its legs and rollers along the ground."),
      t("Cortina de siete bombas con un hueco; antes se marcan en tono medio.", "A curtain of seven bombs with one gap, marked first in a lighter tone."),
      t("Bombas que al tocar el suelo revientan en dos balas rasantes: sáltalas.", "Bombs that burst into two low bullets when they hit the ground: jump them.")],
     "TRES PUNTOS"),
    ("Hangar 18", t("La base, entre tuberías", "The base, among pipes"),
     t("Según la leyenda, en el Hangar 18 de la base Wright-Patterson, en Ohio, se guardan naves y cuerpos recuperados. El jefe lleva la insignia roja que Lonnie Zamora dijo ver en Socorro, Nuevo México, en 1964.",
       "Legend says Hangar 18 at Wright-Patterson Air Force Base, Ohio, holds recovered craft and bodies. The boss carries the red insignia Lonnie Zamora said he saw at Socorro, New Mexico, in 1964."),
     t("El núcleo (la insignia de Socorro)", "The core (the Socorro insignia)"), "nucleo",
     [t("Espiral de un brazo y abanico de tres. Sus escudos giran y frenan tus balas.", "A one-arm spiral and a fan of three. Its shields spin and stop your bullets."),
      t("Dos espirales que giran al revés y forman una red con rombos por donde pasar.", "Two spirals turning opposite ways that make a net with diamonds to slip through."),
      t("Los escudos se abren y giran más rápido; anillo de balas que se frenan y te buscan.", "The shields open and spin faster; a ring of bullets that stop and home in.")],
     "NO ESTAN AL AZAR"),
    ("Los Hill 1961", t("La cueva", "The cave"),
     t("En septiembre de 1961 Betty y Barney Hill volvían por Nuevo Hampshire cuando, según contaron, una nave los detuvo. Bajo hipnosis Betty dibujó un mapa de estrellas que le mostraron a bordo.",
       "In September 1961 Betty and Barney Hill were driving through New Hampshire when, they said, a craft stopped them. Under hypnosis Betty drew a star map she was shown on board."),
     t("El Gris", "The Grey"), "ojo_abierto",
     [t("Solo recibe daño con el ojo abierto. Cerrado lanza abanicos con un hueco; abierto te marca con una línea y dispara una ráfaga por ahí.", "It only takes damage with its eye open. Closed it throws fans with a gap; open it marks you with a line and fires a burst along it."),
      t("El mapa de Betty: siembra estrellas, las une con líneas de aviso que se vuelven rayos y al final cada estrella revienta en cuatro.", "Betty's map: it seeds stars, links them with warning lines that turn into beams, and finally each star bursts into four."),
      t("Abanicos y espiral; abierto, ráfagas de tres. Abre el ojo menos tiempo.", "Fans and a spiral; open, bursts of three. It keeps the eye open for less time.")],
     "ES UN MAPA"),
    ("Shag Harbour 1967", t("Sobre el mar: el agua frena pero no daña", "Over the sea: water slows you but does no harm"),
     t("El 4 de octubre de 1967 varios testigos vieron un objeto con luces caer al mar frente a Shag Harbour, Nueva Escocia. La marina canadiense buscó durante días y no encontró nada.",
       "On 4 October 1967 several witnesses saw a lit object fall into the sea off Shag Harbour, Nova Scotia. The Canadian navy searched for days and found nothing."),
     t("El objeto de Shag Harbour", "The Shag Harbour object"), "shag",
     [t("Flota disparando y se hunde.", "It floats while firing, then sinks."),
      t("Se acerca por debajo: una columna de burbujas avisa por dónde va a subir.", "It closes in from below: a column of bubbles shows where it will rise."),
      t("Sube de golpe soltando un abanico; el agua burbujea antes de cada géiser.", "It bursts up releasing a fan; the water bubbles before every geyser.")],
     "FALTAN CINCO"),
    ("Baikal 1982", t("Sobre el hielo: la oruga patina y los agujeros se saltan", "On the ice: the tank slides and holes must be jumped"),
     t("Según un relato soviético, en 1982 buzos de la marina que entrenaban en el lago Baikal se cruzaron bajo el hielo con figuras de unos tres metros vestidas de plata.",
       "According to a Soviet story, in 1982 navy divers training in Lake Baikal met figures about three metres tall dressed in silver under the ice."),
     t("El gigante plateado", "The silver giant"), "gigante",
     [t("Asoma por un agujero y lanza bloques de hielo en arco.", "It rises from a hole and lobs blocks of ice."),
      t("Abre el visor para disparar: solo entonces recibe daño.", "It opens its visor to shoot: only then does it take damage."),
      t("Se hunde y revienta el hielo en otro lado; una grieta avisa dónde. Su rayo va bajo (salta) o alto (quédate en el piso).", "It sinks and breaks the ice somewhere else; a crack shows where. Its beam goes low (jump) or high (stay down).")],
     "SE ACERCAN"),
    ("Golfo Nuevo 1960", t("De noche, con la pantalla invertida", "At night, with the screen inverted"),
     t("En febrero de 1960 la Armada Argentina pasó semanas persiguiendo en el Golfo Nuevo, en Chubut, a submarinos que nadie pudo identificar. Tiraron cargas de profundidad y nunca los atraparon.",
       "In February 1960 the Argentine Navy spent weeks chasing submarines nobody could identify in Golfo Nuevo, Chubut. They dropped depth charges and never caught them."),
     t("El submarino fantasma", "The phantom submarine"), "fantasma",
     [t("Solo se le puede pegar mientras lo alumbran los reflectores; alumbrado sube a cota de periscopio.", "You can only hit it while the searchlights are on it; lit up, it rises to periscope depth."),
      t("Aparece un segundo submarino que se queda hondo.", "A second submarine appears and stays deep."),
      t("Los reflectores se apagan: solo lo revelan los destellos de las cargas que tira la Armada.", "The searchlights go out: only the flashes of the navy's depth charges reveal it.")],
     "CASI COMPLETO"),
    ("Lubbock 1951", t("Lluvia de rocas", "Rock shower"),
     t("Entre agosto y septiembre de 1951 vecinos de Lubbock, Texas, vieron pasar formaciones de luces en arco. Un estudiante, Carl Hart Jr., las fotografió.",
       "Between August and September 1951 people in Lubbock, Texas, saw arcs of lights pass overhead. A student, Carl Hart Jr., photographed them."),
     t("El tren de luces", "The light train"), "serpiente_cabeza",
     [t("Solo la cabeza recibe daño; el cuerpo frena tus balas. Cada vagón dispara recto por turno.", "Only the head takes damage; the body stops your bullets. Each car fires straight in turn."),
      t("Va más rápido; cascada de los vagones y abanico de tres desde la cabeza.", "It moves faster; a cascade from the cars and a fan of three from the head."),
      t("Todas las luces se encienden y cada vagón suelta una bala que se frena y te busca.", "All the lights turn on and each car releases a bullet that stops and homes in.")],
     "ES POR DONDE ENTRAN"),
    ("Bermudas 1945", t("Bajo el agua, en batiscafo", "Under water, in the bathyscaphe"),
     t("El 5 de diciembre de 1945 el Vuelo 19, cinco bombarderos Avenger de la marina de Estados Unidos, desapareció en un vuelo de práctica sobre el mar, en lo que después se llamó el Triángulo de las Bermudas.",
       "On 5 December 1945 Flight 19, five US Navy Avenger bombers, vanished during a training flight over the sea, in what was later called the Bermuda Triangle."),
     t("La pirámide del Triángulo", "The pyramid of the Triangle"), "piramide",
     [t("Descansa en el fondo y lanza anillos de luz con un hueco por donde pasar. Solo recibe daño cuando abre la punta.", "It rests on the seabed and sends out rings of light with one gap to pass through. It only takes damage when its tip opens."),
      t("Al abrirse suelta tres balas que se frenan y te buscan.", "When it opens it releases three bullets that stop and home in."),
      t("Los anillos salen de a dos, con los huecos en zigzag. El obús lleno les abre un hueco nuevo.", "The rings come in pairs, with zigzag gaps. A full shell cuts a new gap in them.")],
     "LA PUERTA SE CIERRA"),
]
FRASES_EN = {
    "UNA LUZ. NADA MAS": "ONE LIGHT. NOTHING MORE", "OTRA. MUY LEJOS": "ANOTHER. FAR AWAY", "TRES PUNTOS": "THREE POINTS",
    "NO ESTAN AL AZAR": "NOT AT RANDOM", "ES UN MAPA": "IT IS A MAP", "FALTAN CINCO": "FIVE TO GO", "SE ACERCAN": "THEY ARE CLOSER",
    "CASI COMPLETO": "ALMOST COMPLETE", "ES POR DONDE ENTRAN": "IT IS HOW THEY COME IN", "LA PUERTA SE CIERRA": "THE DOOR CLOSES",
}

AVISTAMIENTOS = [
    ("chispa", "Foo fighter", t("Bolas de luz que seguían a los aviones aliados en 1944.", "Balls of light that followed Allied planes in 1944.")),
    ("medusa", t("Platillo de Arnold", "Arnold's saucer"), t("Kenneth Arnold vio nueve objetos en 1947 «como platos rebotando en el agua».", "Kenneth Arnold saw nine objects in 1947 \"like saucers skipping on water\".")),
    ("dardo", "Tic Tac", t("El objeto blanco y liso que persiguieron pilotos del portaaviones Nimitz en 2004.", "The smooth white object chased by pilots from the carrier Nimitz in 2004.")),
    ("rombo", t("Diamante", "Diamond"), t("El rombo de fuego que vieron Betty Cash y Vickie Landrum en Texas en 1980.", "The fiery diamond seen by Betty Cash and Vickie Landrum in Texas in 1980.")),
    ("caparazon", t("Triángulo", "Triangle"), t("El triángulo belga de tres luces, 1989.", "The three-light Belgian triangle, 1989.")),
    ("planeador", "La V", t("Las luces de Phoenix en formación, 1997.", "The Phoenix lights in formation, 1997.")),
    ("espora", t("Orbe", "Orb"), t("Las luces que flotan sobre el valle de Hessdalen, Noruega, desde 1981.", "The lights floating over the Hessdalen valley, Norway, since 1981.")),
    ("avispa", t("El Gris", "The Grey"), t("La cabeza grande y los ojos negros del relato de los Hill.", "The big head and black eyes from the Hills' account.")),
    ("lazo", t("Luces", "Lights"), t("Las luces en arco de Lubbock, 1951.", "The arcs of lights over Lubbock, 1951.")),
    ("orbitador", t("Círculo", "Circle"), t("Los círculos en los trigales ingleses de 1990.", "The English crop circles of 1990.")),
    ("minador", t("Cigarro", "Cigar"), t("La nave nodriza en forma de cigarro de cien relatos sin fecha.", "The cigar-shaped mothership of a hundred undated accounts.")),
    ("francotirador", t("Caballero Negro", "Black Knight"), t("El supuesto satélite que alguien rastreó en órbita en 1960.", "The supposed satellite someone tracked in orbit in 1960.")),
    ("orbe", t("Orbe marino", "Sea orb"), t("Luces que se meten al mar en Shag Harbour.", "Lights that dive into the sea at Shag Harbour.")),
    ("cilindro", t("Cilindro", "Cylinder"), t("Lo que la Armada buscaba en Golfo Nuevo.", "What the navy was hunting in Golfo Nuevo.")),
]


def li(items):
    return "".join(f"<li>{x}</li>" for x in items)


def construir():
    filas_controles = "".join(f"<tr><th scope=\"row\">{a}</th><td>{b}</td><td>{c}</td><td>{d}</td></tr>" for a, b, c, d in CONTROLES)
    menu = "".join(f"<div class=\"fila-menu\"><b>{a}</b><span>{b}</span></div>" for a, b in MENU)
    naves = "".join(f"<article class=\"ficha\"><div class=\"lcd chico\">{sprite(d, 6, d)}</div><h3>{n}</h3><p>{x}</p></article>" for d, n, x in NAVES)
    armas = "".join(f"<div class=\"fila-menu\"><b>{a}</b><span>{b}</span></div>" for a, b in ARMAS)

    def capsula(c):
        nombre, titulo, texto, guardable = c
        marca = t("CON Y", "WITH Y") if guardable else t("AL TOCARLA", "ON PICKUP")
        return (f"<article class=\"capsula\"><div class=\"lcd mini\">{sprite('mejora_' + nombre, 6, nombre)}</div>"
                f"<div><h3>{titulo} <small class=\"{'y' if guardable else 'ya'}\">{marca}</small></h3><p>{texto}</p></div></article>")
    capsulas = "".join(capsula(c) for c in CAPSULAS)

    expedientes = ""
    for i, (caso, escenario, real, jefe, dib, fases, frase) in enumerate(EXPEDIENTES, 1):
        fases_html = "".join(f"<li><b>{t('Fase', 'Phase')} {k}.</b> {f}</li>" for k, f in enumerate(fases, 1))
        expedientes += f"""
<article class="caso" id="caso-{i}">
  <header class="pestana"><span class="num">{t('EXPEDIENTE', 'CASE FILE')} {i:02d}</span><h3>{caso}</h3><span class="lugar">{escenario}</span></header>
  <div class="cuerpo">
    <figure class="lcd pantalla">{toma(i, caso)}</figure>
    <div class="texto">
      <p class="real"><span class="rotulo">{t('LO QUE SE CUENTA', 'THE RECORD')}</span>{real}</p>
      <div class="jefe"><div class="lcd chico">{sprite(dib, 3, dib)}</div><div><span class="rotulo">{t('JEFE', 'BOSS')}</span><b>{jefe}</b></div></div>
      <ol class="fases">{fases_html}</ol>
      <p class="mapa"><span class="rotulo">{t('EN EL MAPA', 'ON THE MAP')}</span>{t(frase, FRASES_EN[frase])}</p>
    </div>
  </div>
</article>"""

    avist = "".join(f"<article class=\"avist\"><div class=\"lcd mini\">{sprite(d, 5, d)}</div><div><h3>{n}</h3><p>{x}</p></div></article>" for d, n, x in AVISTAMIENTOS)

    return PLANTILLA.format(controles=filas_controles, menu=menu, naves=naves, armas=armas, capsulas=capsulas,
                            expedientes=expedientes, avistamientos=avist, titulo=sprite("jefe", 6, "Platillo de Roswell"),
                            nave=sprite("nave", 5, "Cabina"))


PLANTILLA = """<title>Manual de Órbita 84</title>
<meta name="author" content="D4rk3r">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Silkscreen&family=Special+Elite&family=Atkinson+Hyperlegible:ital,wght@0,400;0,700;1,400&display=swap">
<style>
  /* Carpeta de un expediente clasificado de 1984: hojas sobre un escritorio oscuro, pantallas LCD
     del juego incrustadas, sellos a máquina. Un solo aspecto (oscuro) a propósito. */
  :root {{
    --escritorio: #0f1622;
    --carpeta: #1d2a3f;
    --hoja: #24334c;
    --lcd: #c7f0d9;
    --lcd-tinta: #42523d;
    --texto: #e6ecf3;
    --suave: #a6b5c9;
    --sello: #e0806a;
    --pixel: "Silkscreen", "Courier New", monospace;
    --maquina: "Special Elite", "Courier New", monospace;
    --cuerpo: "Atkinson Hyperlegible", system-ui, sans-serif;
    color-scheme: dark;
  }}
  html {{ background: var(--escritorio); }}
  body {{
    background: var(--escritorio); color: var(--texto); font-family: var(--cuerpo); font-size: 17px; line-height: 1.6;
    padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px));
    padding-block: 24px 56px;
  }}
  html[lang="es"] [lang="en"], html[lang="en"] [lang="es"] {{ display: none; }}
  main {{ max-width: 1040px; margin: 0 auto; display: grid; gap: 56px; }}
  h1, h2, h3 {{ font-weight: 400; margin: 0; text-wrap: balance; }}
  h2 {{ font-family: var(--pixel); font-size: clamp(22px, 4vw, 28px); color: var(--lcd); letter-spacing: .04em; }}
  h3 {{ font-family: var(--pixel); font-size: 16px; color: var(--lcd); letter-spacing: .03em; }}
  p {{ margin: 0; max-width: 66ch; }}
  a {{ color: var(--lcd); }}
  a:focus-visible, button:focus-visible {{ outline: 2px solid var(--sello); outline-offset: 3px; }}
  img.px {{ image-rendering: pixelated; display: block; max-width: 100%; height: auto; }}
  section {{ display: grid; gap: 20px; }}
  .intro {{ color: var(--suave); }}
  .rotulo {{ display: block; font-family: var(--maquina); font-size: 13px; letter-spacing: .14em; color: var(--sello); text-transform: uppercase; }}

  /* portada de la carpeta */
  .tapa {{ display: grid; gap: 18px; background: var(--carpeta); border-radius: 14px; padding: clamp(20px, 5vw, 40px); position: relative; overflow: hidden; }}
  .tapa .arriba {{ display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 12px; }}
  .sello {{ font-family: var(--maquina); color: var(--sello); border: 2px solid var(--sello); padding: 2px 10px; letter-spacing: .14em; font-size: 14px; transform: rotate(-2deg); }}
  .idioma {{ display: flex; gap: 4px; }}
  .idioma button {{ font: 14px var(--pixel); color: var(--suave); background: transparent; border: 1px solid #3a4b66; border-radius: 6px; padding: 6px 12px; cursor: pointer; }}
  .idioma button[aria-pressed="true"] {{ background: var(--lcd); color: var(--lcd-tinta); border-color: var(--lcd); }}
  h1 {{ font-family: var(--pixel); font-size: clamp(44px, 11vw, 88px); line-height: .95; color: var(--lcd); }}
  h1 small {{ display: block; font-family: var(--maquina); font-size: clamp(16px, 3vw, 20px); color: var(--suave); letter-spacing: .08em; margin-top: 10px; }}
  .prologo {{ font-family: var(--maquina); font-size: clamp(17px, 2.6vw, 20px); line-height: 1.7; max-width: 46ch; }}
  .prologo em {{ color: var(--suave); font-style: normal; }}
  .tapa .ovni {{ position: absolute; right: clamp(12px, 5vw, 48px); top: clamp(70px, 14vw, 110px); opacity: .9; }}
  @media (max-width: 640px) {{ .tapa .ovni {{ position: static; justify-self: end; }} }}
  .acciones {{ display: flex; flex-wrap: wrap; gap: 12px; align-items: center; }}
  .boton {{ font-family: var(--pixel); background: var(--lcd); color: var(--lcd-tinta); text-decoration: none; padding: 10px 18px; border-radius: 8px; }}
  .firma {{ font-family: var(--maquina); color: var(--suave); font-size: 15px; }}
  nav.indice {{ display: flex; flex-wrap: wrap; gap: 8px; }}
  nav.indice a {{ font-family: var(--pixel); font-size: 13px; text-decoration: none; color: var(--suave); border: 1px solid #3a4b66; border-radius: 999px; padding: 4px 12px; }}
  nav.indice a:hover {{ color: var(--lcd); border-color: var(--lcd); }}

  /* tablas y listas */
  .tabla {{ overflow-x: auto; }}
  table {{ border-collapse: collapse; width: 100%; min-width: 560px; font-size: 16px; }}
  th, td {{ text-align: left; padding: 9px 12px; border-bottom: 1px solid #33445f; vertical-align: top; }}
  thead th {{ font-family: var(--pixel); font-size: 13px; color: var(--suave); font-weight: 400; }}
  tbody th {{ font-weight: 400; color: var(--texto); }}
  td {{ font-family: var(--pixel); font-size: 14px; color: var(--lcd); }}
  .lista {{ display: grid; gap: 2px; background: var(--hoja); border-radius: 12px; padding: 6px 0; }}
  .fila-menu {{ display: grid; grid-template-columns: minmax(110px, 180px) 1fr; gap: 16px; padding: 10px 18px; }}
  .fila-menu b {{ font-family: var(--pixel); font-weight: 400; color: var(--lcd); }}
  .fila-menu span {{ min-width: 0; }}
  @media (max-width: 520px) {{ .fila-menu {{ grid-template-columns: 1fr; gap: 2px; }} }}

  /* pantallas LCD del juego */
  .lcd {{ background: var(--lcd); border-radius: 6px; display: grid; place-items: center; }}
  .lcd.chico {{ padding: 14px; min-height: 76px; }}
  .lcd.mini {{ padding: 8px; width: 58px; height: 58px; flex: none; }}
  .lcd.pantalla {{ margin: 0; padding: 6px; border: 6px solid var(--carpeta); border-radius: 10px; }}
  .lcd.pantalla img {{ width: 100%; }}
  .fichas {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 14px; }}
  .ficha {{ background: var(--hoja); border-radius: 12px; padding: 14px; display: grid; gap: 10px; align-content: start; }}
  .ficha p, .capsula p, .avist p {{ color: var(--suave); font-size: 16px; }}
  .capsulas {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 12px; }}
  .capsula, .avist {{ display: flex; gap: 14px; align-items: flex-start; background: var(--hoja); border-radius: 12px; padding: 12px; }}
  .capsula > div:last-child, .avist > div:last-child {{ min-width: 0; display: grid; gap: 4px; }}
  .capsula small {{ font-family: var(--maquina); font-size: 12px; letter-spacing: .1em; margin-left: 6px; }}
  .capsula small.y {{ color: var(--sello); }}
  .capsula small.ya {{ color: var(--suave); }}
  .nota {{ background: var(--carpeta); border-left: 3px solid var(--sello); border-radius: 0 10px 10px 0; padding: 12px 16px; font-size: 16px; }}

  /* expedientes: una hoja por caso con su pestaña */
  .casos {{ display: grid; gap: 28px; }}
  .caso {{ background: var(--hoja); border-radius: 0 12px 12px 12px; position: relative; }}
  .pestana {{ display: flex; flex-wrap: wrap; align-items: baseline; gap: 6px 14px; background: var(--carpeta); padding: 12px 18px; border-radius: 0 12px 0 0; }}
  .pestana .num {{ font-family: var(--maquina); color: var(--sello); letter-spacing: .14em; font-size: 14px; }}
  .pestana h3 {{ font-size: 20px; }}
  .pestana .lugar {{ color: var(--suave); font-size: 15px; }}
  .cuerpo {{ display: grid; grid-template-columns: minmax(0, 5fr) minmax(0, 6fr); gap: 20px; padding: 18px; }}
  @media (max-width: 760px) {{ .cuerpo {{ grid-template-columns: minmax(0, 1fr); }} }}
  .texto {{ display: grid; gap: 14px; align-content: start; min-width: 0; }}
  .real {{ font-family: var(--maquina); font-size: 16px; line-height: 1.7; }}
  .jefe {{ display: flex; gap: 14px; align-items: center; }}
  .jefe .lcd {{ min-height: 0; padding: 10px; }}
  .jefe b {{ font-family: var(--pixel); font-weight: 400; color: var(--lcd); }}
  .fases {{ margin: 0; padding-left: 0; list-style: none; display: grid; gap: 8px; font-size: 16px; }}
  .fases b {{ font-family: var(--pixel); font-weight: 400; color: var(--lcd); font-size: 13px; margin-right: 4px; }}
  .mapa {{ font-family: var(--pixel); font-size: 14px; color: var(--lcd); }}
  .avistamientos {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 12px; }}
  details {{ background: var(--carpeta); border-radius: 12px; padding: 14px 18px; }}
  summary {{ font-family: var(--pixel); cursor: pointer; color: var(--sello); }}
  details p {{ margin-top: 12px; font-family: var(--maquina); }}
  footer {{ color: var(--suave); font-family: var(--maquina); text-align: center; }}
  @media (prefers-reduced-motion: no-preference) {{
    .tapa .ovni {{ animation: flota 4s ease-in-out infinite; }}
    @keyframes flota {{ 50% {{ transform: translateY(-8px); }} }}
  }}
</style>

<main>
  <div class="tapa">
    <div class="arriba">
      <span class="sello">{{CLASIFICADO}} · 1984</span>
      <div class="idioma" role="group" aria-label="Idioma / Language">
        <button type="button" id="es" aria-pressed="true">ES</button>
        <button type="button" id="en" aria-pressed="false">EN</button>
      </div>
    </div>
    <div class="ovni">{titulo}</div>
    <h1>ÓRBITA 84<small><span lang="es">Manual del agente</span><span lang="en">Field agent's manual</span></small></h1>
    <p class="prologo"><span lang="es">1984. Un programa secreto reúne diez casos con las mismas luces. <em>Dos expedientes tienen fecha que aún no llega.</em> Tu nave sale a cerrarlos uno por uno.</span><span lang="en">1984. A secret program gathers ten cases with the same lights. <em>Two case files are dated in a future that hasn't come yet.</em> Your ship goes out to close them one by one.</span></p>
    <div class="acciones">
      <a class="boton" href="https://darker03.itch.io/orbita-84"><span lang="es">Jugar en itch.io</span><span lang="en">Play on itch.io</span></a>
      <span class="firma"><span lang="es">Un juego de D4RK3R</span><span lang="en">A game by D4RK3R</span></span>
    </div>
  </div>

  <nav class="indice" aria-label="Índice">
    <a href="#controles"><span lang="es">Controles</span><span lang="en">Controls</span></a>
    <a href="#menu"><span lang="es">Menú</span><span lang="en">Menu</span></a>
    <a href="#naves"><span lang="es">Naves</span><span lang="en">Ships</span></a>
    <a href="#armas"><span lang="es">Armas</span><span lang="en">Weapons</span></a>
    <a href="#capsulas"><span lang="es">Cápsulas</span><span lang="en">Capsules</span></a>
    <a href="#expedientes"><span lang="es">Los diez expedientes</span><span lang="en">The ten case files</span></a>
    <a href="#avistamientos"><span lang="es">Avistamientos</span><span lang="en">Sightings</span></a>
    <a href="#reglas"><span lang="es">Reglas</span><span lang="en">Rules</span></a>
  </nav>

  <section id="controles">
    <h2><span lang="es">Controles</span><span lang="en">Controls</span></h2>
    <div class="tabla"><table>
      <thead><tr><th scope="col"></th><th scope="col"><span lang="es">Teclado</span><span lang="en">Keyboard</span></th><th scope="col"><span lang="es">Mando o consola</span><span lang="en">Gamepad or handheld</span></th><th scope="col"><span lang="es">Teléfono</span><span lang="en">Phone</span></th></tr></thead>
      <tbody>{controles}</tbody>
    </table></div>
    <p class="intro"><span lang="es">En el teléfono el juego ocupa toda la pantalla con sus propios botones: cruceta a la izquierda, A, B e Y a la derecha, START y SELECT arriba. Se juega mejor con el teléfono horizontal.</span><span lang="en">On a phone the game fills the screen with its own buttons: D-pad on the left, A, B and Y on the right, START and SELECT on top. It plays best in landscape.</span></p>
  </section>

  <section id="menu">
    <h2><span lang="es">El menú</span><span lang="en">The menu</span></h2>
    <p class="intro"><span lang="es">En la portada pulsa START o A. Te mueves con la cruceta, eliges con A y vuelves con B. START juega directo desde cualquier fila.</span><span lang="en">On the title screen press START or A. Move with the D-pad, choose with A, go back with B. START plays right away from any row.</span></p>
    <div class="lista">{menu}</div>
  </section>

  <section id="naves">
    <h2><span lang="es">Naves</span><span lang="en">Ships</span></h2>
    <p class="intro"><span lang="es">Hay dos naves para elegir en el menú. Según el expediente, la que elijas aterriza o se sumerge y cambia de forma; el especial sigue siendo el de tu nave.</span><span lang="en">There are two ships to choose from in the menu. Depending on the case, yours lands or dives and changes shape; the special stays the one of your ship.</span></p>
    <div class="fichas">{naves}</div>
  </section>

  <section id="armas">
    <h2><span lang="es">Armas</span><span lang="en">Weapons</span></h2>
    <div class="lista">{armas}</div>
  </section>

  <section id="capsulas">
    <h2><span lang="es">Cápsulas</span><span lang="en">Capsules</span></h2>
    <p class="intro"><span lang="es">Las sueltan los enemigos al caer (los más duros, más seguido) y llegan dentro de una mira de radar. Tres actúan apenas las tocas. Las otras cuatro se guardan, una a la vez, y su ícono queda en la ranura de la Y, arriba, hasta que las usas; si recoges otra, la nueva reemplaza a la guardada.</span><span lang="en">Enemies drop them when destroyed (tougher ones more often) and they arrive inside a radar sight. Three work as soon as you touch them. The other four are stored, one at a time, and their icon sits in the Y slot at the top until you use it; picking up another replaces the stored one.</span></p>
    <div class="capsulas">{capsulas}</div>
    <p class="nota"><span lang="es">Cada expediente trae su poder: sale fijo dos veces durante el nivel para que aprendas a usarlo, y la primera vez el juego te dice el botón. Escudo en Roswell, tiempo perdido en Bélgica, sonda en Phoenix, abducción en el Hangar 18. En la primera vuelta solo salen los poderes que ya conociste; desde la segunda, todos.</span><span lang="en">Each case brings its own power: it appears twice during the level so you can learn it, and the first time the game tells you the button. Shield at Roswell, lost time in Belgium, probe at Phoenix, abduction in Hangar 18. On the first round only powers you've already met can drop; from the second round on, all of them.</span></p>
  </section>

  <section id="expedientes">
    <h2><span lang="es">Los diez expedientes</span><span lang="en">The ten case files</span></h2>
    <p class="intro"><span lang="es">Cada nivel es un caso famoso. Al final espera su jefe, que pelea en tres fases con ataques fijos que se pueden aprender. Entre fase y fase se cubre con un escudo: mientras lo tenga tus tiros rebotan. Tras cada jefe se enciende una estrella de un mapa.</span><span lang="en">Each level is a famous case. Its boss waits at the end and fights in three phases with fixed attacks you can learn. Between phases it raises a shield: while it's up your shots bounce off. After each boss a star lights up on a map.</span></p>
    <div class="casos">{expedientes}</div>
  </section>

  <section id="avistamientos">
    <h2><span lang="es">Archivo de avistamientos</span><span lang="en">Sightings archive</span></h2>
    <p class="intro"><span lang="es">Los enemigos también son ovnis famosos. La portada del juego muestra sus fichas una por una.</span><span lang="en">The enemies are famous UFOs too. The title screen shows their files one by one.</span></p>
    <div class="avistamientos">{avistamientos}</div>
  </section>

  <section id="reglas">
    <h2><span lang="es">Reglas del programa</span><span lang="en">Program rules</span></h2>
    <div class="lista">
      <div class="fila-menu"><b><span lang="es">Vidas</span><span lang="en">Lives</span></b><span><span lang="es">Empiezas con tres. Vencer a un jefe da una más; vencerlo rápido, puntos extra.</span><span lang="en">You start with three. Beating a boss gives one more; beating it fast gives bonus points.</span></span></div>
      <div class="fila-menu"><b><span lang="es">Continuar</span><span lang="en">Continue</span></b><span><span lang="es">Si pierdes la última vida, pulsa A o START antes de que la cuenta llegue a cero: sigues ahí mismo con tres vidas y el puntaje en cero. Para los récords cuenta tu mejor tramo.</span><span lang="en">If you lose your last life, press A or START before the count reaches zero: you go on right there with three lives and the score at zero. Your best stretch counts for the scores.</span></span></div>
      <div class="fila-menu"><b><span lang="es">Vueltas</span><span lang="en">Rounds</span></b><span><span lang="es">Tras el décimo expediente eliges seguir con una vuelta más difícil o terminar la misión y guardar el puntaje.</span><span lang="en">After the tenth case you choose to go on with a harder round or end the mission and save your score.</span></span></div>
      <div class="fila-menu"><b><span lang="es">Récords</span><span lang="en">Scores</span></b><span><span lang="es">Los diez mejores se anotan con tres iniciales, la nave y hasta dónde llegaste (N7 es el expediente 7; 2-9, el 9 de la segunda vuelta).</span><span lang="en">The top ten are saved with three initials, the ship and how far you got (L7 is case 7; 2-9 is case 9 of the second round).</span></span></div>
      <div class="fila-menu"><b><span lang="es">Modo de prueba</span><span lang="en">Test mode</span></b><span><span lang="es">En la portada pulsa B tres veces seguidas: eliges nivel, nave, vuelta y más. Esas partidas no cuentan para los récords.</span><span lang="en">On the title screen press B three times in a row: pick the level, ship, round and more. Those runs don't count for the scores.</span></span></div>
    </div>
    <details>
      <summary><span lang="es">Lo que dice el informe final (revela el final)</span><span lang="en">What the final report says (spoiler)</span></summary>
      <p><span lang="es">Con las diez estrellas encendidas el mapa de Betty Hill queda completo y señala por dónde entran. La puerta se cierra. Y los informes de 1990 y 1997, los que tenían fecha que aún no llegaba, llevan tu firma.</span><span lang="en">With all ten stars lit, Betty Hill's map is complete and shows where they come in. The door closes. And the reports from 1990 and 1997, the ones dated in a future that hadn't come yet, bear your signature.</span></p>
    </details>
  </section>

  <footer><span lang="es">Órbita 84 · un juego de D4RK3R</span><span lang="en">Órbita 84 · a game by D4RK3R</span></footer>
</main>

<script>
  (function () {{
    var raiz = document.documentElement;
    function poner(idioma) {{
      raiz.lang = idioma;
      document.getElementById("es").setAttribute("aria-pressed", idioma === "es");
      document.getElementById("en").setAttribute("aria-pressed", idioma === "en");
      try {{ localStorage.setItem("idioma", idioma); }} catch (e) {{}}
    }}
    var guardado = null;
    try {{ guardado = localStorage.getItem("idioma"); }} catch (e) {{}}
    poner(guardado || ((navigator.language || "es").toLowerCase().indexOf("es") === 0 ? "es" : "en"));
    document.getElementById("es").addEventListener("click", function () {{ poner("es"); }});
    document.getElementById("en").addEventListener("click", function () {{ poner("en"); }});
  }})();
</script>
"""


if __name__ == "__main__":
    os.makedirs(SALIDA, exist_ok=True)
    pagina = construir().replace("{CLASIFICADO}", '<span lang="es">CLASIFICADO</span><span lang="en">CLASSIFIED</span>')
    ruta = os.path.join(SALIDA, "manual.html")
    open(ruta, "w", encoding="utf-8").write(pagina)
    print(f"Listo: {os.path.relpath(ruta, RAIZ)} ({len(pagina) // 1024} KB)")
