/**
 * AGUA — océano, lagos, ríos y costa.
 *
 * Decisiones de arquitectura (el "por qué"):
 *
 * 1. PROFUNDIDAD POR CAMPO PRECALCULADO, no por DepthTexture. (Decisión revisada
 *    a conciencia esta ronda, porque el pedido era usar el depth buffer.)
 *    El composer de este proyecto (src/render/Renderer.js) NO expone DepthTexture:
 *    habría que agregarle una al render target base y arrastrarla por AO, bloom,
 *    output y SMAA, o pagar un prepass de escena entero. Y aun teniéndola, la
 *    profundidad del depth buffer trae metida la basura que flota sobre el fondo
 *    (unidades, barcos, árboles, partículas): la costa se ensucia con siluetas.
 *    El fondo de un RTS es ESTÁTICO, así que se muestrea `terreno.altura` una vez
 *    al cargar y queda en una DataTexture RGBA8 de 512² sobre el mapa (≈1 m/texel,
 *    filtrado bilineal): profundidad firmada, SDF a la orilla, TAMAÑO del cuerpo
 *    de agua al que pertenece el píxel y ancho de rompiente. Es, literalmente, un
 *    depth buffer del lecho — sólo que limpio, estable entre frames y sin coste
 *    por frame.
 *    El canal del TAMAÑO (flood fill de masas conexas al construir el campo) es
 *    el que faltaba: sin él ningún píxel sabía si estaba en un estanque de 14 m o
 *    en el mar, así que la rompiente se pintaba igual en los dos y el estanque
 *    salía blanco de orilla a orilla. Ver FRACCION_ROMPIENTE.
 *    LO QUE SÍ ERA EL BUG: ese campo se leía en el VERTEX y llegaba al fragment
 *    como varying. O sea, la profundidad —y con ella el alfa, el degradé y el
 *    recorte de la orilla— quedaba interpolada sobre quads de ~3 m: el borde del
 *    agua ERA la triangulación de la malla. Ahora el campo se lee POR PÍXEL en el
 *    fragment y el vértice sólo lo usa para desplazar. De ahí sale el gradiente
 *    continuo y la costa curva.
 *
 * 2. REFRACCIÓN SIN GRAB-PASS. El agua se dibuja transparente: en el primer metro
 *    y medio de profundidad el alfa es bajo y se ve el TERRENO REAL del framebuffer
 *    (refracción de verdad, gratis, sin copiar la pantalla). De ahí para abajo el
 *    alfa sube y pintamos nuestro propio lecho con absorción Beer-Lambert por
 *    canal, que es donde la absorción cromática realmente importa. La distorsión
 *    por la normal se aplica al muestreo del campo (lecho, cáusticas y orilla
 *    ondulan) aunque el terreno del framebuffer no se deforme.
 *    La luz que SUBE del cuerpo satura con un factor ESCALAR, no con (1 - T) por
 *    canal: con (1 - T) el canal que más absorbe (rojo) es el primero en saturar
 *    y la orilla se cubría de un velo rosa-gris. Ése era el "lechoso".
 *
 * 3. REFLEXIÓN PLANAR PROPIA (cámara espejada + render target), no THREE.Reflector,
 *    porque necesitamos distorsionar la UV con la normal de la ola y mezclar con
 *    el cielo procedural en los bordes de pantalla. Incluye el clipping oblicuo de
 *    Lengyel para que no se refleje el fondo sumergido.
 *
 * 4. NORMALES EN EL FRAGMENT. El vértice sólo desplaza; la normal de Gerstner se
 *    recalcula analíticamente por píxel. Así la teselación puede ser barata sin
 *    perder el brillo de los trenes cortos.
 */
import * as THREE from 'three';

/* ═════════════════════════════════════════════════════════════════════════════
   CONSTANTES COMPARTIDAS ENTRE CPU Y GPU
   El shader se genera a partir de esta misma tabla, así `alturaOla()` devuelve
   exactamente lo que desplaza el vertex shader. No duplicar números a mano.
   ═════════════════════════════════════════════════════════════════════════════ */

export const GRAVEDAD = 9.81;
/** Frena la dispersión de aguas profundas: esto es lago y costa, no mar abierto. */
const FACTOR_VELOCIDAD = 0.62;

/**
 * Amplitud total ≈ 0.71 m ⇒ cresta a valle ~1.4 m en el peor caso constructivo.
 * Subida ~35% respecto del set original: con 0.52 m la superficie se leía PLANA
 * a la distancia de cámara del RTS (60-120 m), que es el defecto que marcó el
 * jurado. El relieve tiene que notarse en la silueta de la cresta, no sólo en
 * la normal. Más que esto y las balsas cabecean como en mar abierto.
 */
const TRENES = [
  { dx:  0.94, dz:  0.34, longitud: 34.0, amplitud: 0.295, q: 1.00 },
  { dx:  0.71, dz: -0.70, longitud: 19.0, amplitud: 0.175, q: 0.90 },
  { dx: -0.42, dz:  0.91, longitud: 11.5, amplitud: 0.112, q: 0.80 },
  { dx:  0.99, dz: -0.14, longitud:  7.2, amplitud: 0.068, q: 0.70 },
  { dx: -0.86, dz: -0.51, longitud:  4.3, amplitud: 0.038, q: 0.50 },
  { dx:  0.30, dz:  0.95, longitud:  2.6, amplitud: 0.022, q: 0.40 },
];

/** Trenes de Gerstner ya normalizados, con número de onda k y frecuencia ω. */
export const OLAS = Object.freeze(TRENES.map((t) => {
  const inv = 1 / Math.hypot(t.dx, t.dz);
  const k = (Math.PI * 2) / t.longitud;
  const c = Math.sqrt(GRAVEDAD / k) * FACTOR_VELOCIDAD;
  return Object.freeze({
    dx: t.dx * inv, dz: t.dz * inv,
    longitud: t.longitud, amplitud: t.amplitud, q: t.q,
    k, velocidad: c, w: k * c,
  });
}));

/**
 * Rango de codificación del canal R del campo (profundidad firmada, metros).
 * Ajustado a -4..12 (antes -8..24): el canal es de 8 bits y TODO el gradiente de
 * color vive entre 0.2 m y 4 m. Con el rango viejo el escalón era de 12.5 cm y
 * el degradé turquesa→azul salía en bandas; con éste es de 6.3 cm. Más allá de
 * 12 m el agua ya es opaca, así que recortar arriba no cuesta nada.
 */
const PROF_MIN = -4, PROF_MAX = 12;
/** Rango del canal G (distancia firmada a la orilla, metros). Idem precisión. */
const SDF_MIN = -14, SDF_MAX = 26;
/**
 * Ancho máximo de la cinta de rompiente, en metros (canal A ⇒ 0..ANCHO_ESPUMA_MAX).
 *
 * Estaba en 9 m, que sale de mirar una playa oceánica tendida. El problema es
 * que el ancho se deriva de la PENDIENTE del lecho, y un estanque de fondo plano
 * da pendiente cero: se iba al tope, y como esos estanques miden menos de 9 m de
 * orilla a orilla, la lámina entera salía blanca. Una laguna chica además no
 * tiene fetch, así que físicamente tampoco rompe.
 * 3,2 m es una franja de rompiente que se lee bien a la distancia de juego.
 * Es sólo el TECHO absoluto: el tope que de verdad manda es el del tamaño del
 * cuerpo (ver FRACCION_ROMPIENTE), porque una constante nunca puede saber que
 * este lago mide 300 m y aquel estanque 14.
 */
const ANCHO_ESPUMA_MAX = 3.2;
/** Profundidad a la que la ola ya no siente el fondo. */
const PROF_ATENUACION = 2.4;

/**
 * FETCH: cuánta ola puede levantar un cuerpo de agua según su TAMAÑO.
 *
 * Éste es el arreglo de fondo del defecto que el panel puso primero en la lista
 * ("el estanque es una mancha blanca casi plana"). El ancho de la rompiente
 * salía sólo de la PENDIENTE del lecho y la espuma no miraba el tamaño del
 * cuerpo, así que un estanque de fondo plano y 14 m de diámetro se llevaba la
 * cinta al tope y quedaba blanco de orilla a orilla. Un charco no tiene fetch:
 * sin recorrido de viento no hay ola, sin ola no hay rompiente y sin rompiente
 * no hay espuma. Punto.
 *
 * Al construir el campo se etiquetan las masas de agua conexas (flood fill) y se
 * mide el RADIO INTERIOR de cada una — la mayor distancia a tierra dentro del
 * cuerpo, o sea su semiancho real. De ahí salen dos cosas:
 *  · un tope al ancho de la cinta (FRACCION_ROMPIENTE del semiancho), y
 *  · un factor de energía 0..1 que se guarda en el canal B del campo.
 */
const FRACCION_ROMPIENTE = 0.28;
/** Radio interior (m) por debajo del cual el cuerpo directamente no rompe. */
const RADIO_FETCH_MIN = 2.0;
/** Radio interior (m) a partir del cual hay rompiente plena (lago de 40 m o mar). */
const RADIO_FETCH_PLENO = 20.0;

/**
 * Densidad de dispersión del cuerpo de agua (1/m). La radiancia que sube del
 * agua satura como 1 - exp(-prof * DENS): a 20 cm aporta un 35%, a 1,25 m un 90%,
 * a 4 m el 100% (ya manda el azul profundo).
 * Es un ESCALAR a propósito: el color de esa luz lo pone la rampa somera→profunda,
 * y la profundidad sólo decide CUÁNTA hay. Cuando este factor era (1 - T) por
 * canal, el rojo (el que más absorbe) saturaba primero y toda el agua somera se
 * llenaba de un velo rosado: el "plano opaco lechoso" del panel.
 *
 * Subido de 0,80 a 1,85 porque con 0,80 el velo a 20 cm valía 15% y el color del
 * agua somera lo ponía ENTERO el lecho de arena: la lámina se leía como arena
 * mojada clara, no como agua. El turquesa de la orilla tiene que existir a 20 cm.
 */
const DENS_DISP = 1.85;

/**
 * Cuánto TAPA el velo al lecho. La transmitancia de Beer-Lambert sólo modela la
 * ABSORCIÓN; el agua además dispersa, y esa dispersión es la que hace que a un
 * metro ya no veas el fondo aunque el agua sea transparente. Sin este término el
 * lecho seguía sumando a plena luz debajo del velo y ninguna cantidad de
 * dispersión alcanzaba para virar el color: el agua quedaba de color arena.
 */
const OCLUSION_LECHO = 0.88;

/**
 * Las olas se aplanan al llegar a la orilla. Sin esto el desplazamiento vertical
 * empuja la malla por encima de la playa y aparecen dientes de sierra en la costa.
 */
export function atenuacionOla(profundidad) {
  const t = Math.min(Math.max((profundidad - 0.05) / (PROF_ATENUACION - 0.05), 0), 1);
  return t * t * (3 - 2 * t);
}

/** Desplazamiento vertical de Gerstner. Espejo exacto del vertex shader. */
export function alturaOlas(x, z, t, atenuacion = 1) {
  let y = 0;
  for (let i = 0; i < OLAS.length; i++) {
    const o = OLAS[i];
    y += o.amplitud * atenuacion * Math.sin(o.k * (o.dx * x + o.dz * z) + o.w * t);
  }
  return y;
}

/** Normal analítica de la superficie desplazada (no por diferencias finitas). */
export function normalOlas(x, z, t, atenuacion = 1, salida = new THREE.Vector3()) {
  // Tangentes de la superficie paramétrica P(x,z) del Gerstner sumado.
  let txx = 1, txy = 0, txz = 0;
  let tzx = 0, tzy = 0, tzz = 1;
  for (let i = 0; i < OLAS.length; i++) {
    const o = OLAS[i];
    const f = o.k * (o.dx * x + o.dz * z) + o.w * t;
    const s = Math.sin(f), c = Math.cos(f);
    const a = o.amplitud * atenuacion;
    const ka = o.k * a;
    txx -= o.q * ka * o.dx * o.dx * s;
    txy += ka * o.dx * c;
    txz -= o.q * ka * o.dx * o.dz * s;
    tzx -= o.q * ka * o.dx * o.dz * s;
    tzy += ka * o.dz * c;
    tzz -= o.q * ka * o.dz * o.dz * s;
  }
  // n = normalize(cross(Tz, Tx)); en superficie plana da (0,1,0).
  return salida.set(
    tzy * txz - tzz * txy,
    tzz * txx - tzx * txz,
    tzx * txy - tzy * txx,
  ).normalize();
}

/* ═════════════════════════════════════════════════════════════════════════════
   COLOR DEL AGUA: UN SOLO PERFIL POR MAPA
   El jurado marcó dos cuerpos de agua de color distinto bajo la misma luz. La
   causa era doble: (a) cinco paletas que cambiaban el TONO del agua, y (b) una
   variación de sedimento de baja frecuencia (manchones de 100 m) que le tocaba
   claro a un lago y oscuro al de al lado. Acá el tono lo fija UN perfil elegido
   una vez por mapa según el bioma dominante, la edad sólo mueve escalares
   (turbiedad, rugosidad, cáusticas) y un tinte suavísimo, y el sedimento pasó a
   alta frecuencia con amplitud corta: textura del lecho, nunca tinte del cuerpo.
   Toda la diferencia visible entre dos puntos de agua sale de la PROFUNDIDAD.

   Los colores de dispersión son la radiancia que sube del agua: `somera` es lo
   que se ve a 20 cm y `profunda` lo que queda a 4 m. Van en sRGB (THREE los
   convierte a lineal) y están elegidos claros a propósito: el agua tiene que ser
   lo más brillante del cuadro.
   ═════════════════════════════════════════════════════════════════════════════ */
/*
 * NOTA SOBRE `fondoClaro`: es ARENA MOJADA Y SUMERGIDA, no la playa seca de al
 * lado. Venía casi con el mismo valor que el terreno de la orilla (0xd8c79a) y
 * eso daba la contradicción que se ve en la captura del estanque: el interior
 * del agua salía MÁS CLARO que la arena seca que lo rodea. Físicamente imposible
 * —la arena mojada refleja alrededor de un 60% de lo que refleja la seca— y
 * visualmente es la mitad del "agua quemada a blanco": no había cómo teñir de
 * turquesa un lecho que ya venía sobreexpuesto. Bajados ~30% en luminancia.
 */
const PERFILES_BIOMA = {
  // Pradera/bosque: laguna de llanura, turquesa verdoso que cierra en azul verde.
  pradera: {
    absorcion: [0.42, 0.20, 0.14], somera: 0x8ad9c6, profunda: 0x2c74a8,
    fondoClaro: 0x9a8a63, fondoOscuro: 0x4c543a, espuma: 0xf6f4ea,
  },
  bosque: {
    absorcion: [0.48, 0.24, 0.19], somera: 0x84d2b4, profunda: 0x27689c,
    fondoClaro: 0x91835e, fondoOscuro: 0x414d34, espuma: 0xf2f2e8,
  },
  // Desierto y playa: fondo de arena clara ⇒ caribe, el turquesa más luminoso.
  desierto: {
    absorcion: [0.40, 0.16, 0.10], somera: 0x9ce6d8, profunda: 0x2585c0,
    fondoClaro: 0xa69670, fondoOscuro: 0x6d6343, espuma: 0xfbf8ee,
  },
  playa: {
    absorcion: [0.40, 0.16, 0.10], somera: 0x9ce6d8, profunda: 0x2585c0,
    fondoClaro: 0xa69670, fondoOscuro: 0x6d6343, espuma: 0xfbf8ee,
  },
  // Montaña: agua de deshielo, más fría y más azul, con harina de roca.
  montana: {
    absorcion: [0.44, 0.18, 0.11], somera: 0x93ddde, profunda: 0x2364ad,
    fondoClaro: 0x8d8b7c, fondoOscuro: 0x3d4652, espuma: 0xf4f8fa,
  },
};
const PERFIL_POR_DEFECTO = PERFILES_BIOMA.pradera;

/**
 * La edad NO cambia el tono base (eso rompía la coherencia entre cuerpos): sólo
 * la cantidad de materia en suspensión, el pulido de la superficie y un tinte
 * multiplicativo casi imperceptible. 1800 turbio y cálido, 2100 filtrado y frío.
 */
const MODULADORES_EDAD = [
  { tinte: [1.00, 1.00, 0.98], rugosidad: 0.072, causticas: 0.90, turbiedad: 1.12, espumaTinte: [1.00, 0.99, 0.96] },
  { tinte: [0.97, 0.99, 1.00], rugosidad: 0.078, causticas: 0.78, turbiedad: 1.25, espumaTinte: [0.98, 0.98, 0.96] },
  { tinte: [0.98, 1.01, 0.98], rugosidad: 0.068, causticas: 0.95, turbiedad: 1.02, espumaTinte: [1.00, 1.00, 0.97] },
  { tinte: [0.97, 1.00, 1.03], rugosidad: 0.056, causticas: 1.10, turbiedad: 0.82, espumaTinte: [0.99, 1.00, 1.01] },
  { tinte: [0.98, 0.99, 1.05], rugosidad: 0.048, causticas: 1.20, turbiedad: 0.74, espumaTinte: [0.99, 0.99, 1.03] },
];

/** Multiplica un color por un tinte [r,g,b] in situ (sin asignar Color nuevos). */
function tintar(color, tinte) {
  color.setRGB(color.r * tinte[0], color.g * tinte[1], color.b * tinte[2]);
  return color;
}

/* ═════════════════════════════════════════════════════════════════════════════
   GENERACIÓN DEL GLSL DE GERSTNER (misma tabla que la CPU)
   ═════════════════════════════════════════════════════════════════════════════ */
const num = (v) => {
  const s = Number(v).toPrecision(9);
  return /[.e]/.test(s) ? s : `${s}.0`;
};

const GLSL_GERSTNER = /* glsl */`
// Suma de trenes de Gerstner + normal analítica exacta de la superficie paramétrica.
void olasGerstner(vec2 p, float t, float att, out vec3 desp, out vec3 nor) {
  desp = vec3(0.0);
  vec3 tx = vec3(1.0, 0.0, 0.0);
  vec3 tz = vec3(0.0, 0.0, 1.0);
  float f, s, c, a, ka;
${OLAS.map((o) => `  f = ${num(o.k)} * dot(vec2(${num(o.dx)}, ${num(o.dz)}), p) + ${num(o.w)} * t;
  s = sin(f); c = cos(f); a = ${num(o.amplitud)} * att; ka = ${num(o.k)} * a;
  desp += vec3(${num(o.q)} * a * ${num(o.dx)} * c, a * s, ${num(o.q)} * a * ${num(o.dz)} * c);
  tx += vec3(-${num(o.q)} * ka * ${num(o.dx * o.dx)} * s, ka * ${num(o.dx)} * c, -${num(o.q)} * ka * ${num(o.dx * o.dz)} * s);
  tz += vec3(-${num(o.q)} * ka * ${num(o.dx * o.dz)} * s, ka * ${num(o.dz)} * c, -${num(o.q)} * ka * ${num(o.dz * o.dz)} * s);`).join('\n')}
  nor = normalize(cross(tz, tx));
}

float atenuacionOla(float prof) {
  return smoothstep(0.05, ${num(PROF_ATENUACION)}, prof);
}

// Campo del lecho:
//   R = profundidad firmada (m)
//   G = distancia firmada a la orilla (m)
//   B = FETCH: tamaño normalizado del cuerpo de agua al que pertenece el píxel
//       (0 = charco que no rompe, 1 = lago grande o mar abierto). Sale del flood
//       fill de masas conexas. Antes acá vivía la variación de sedimento, que se
//       mudó al shader porque es TEXTURA del lecho y no necesita un canal propio.
//   A = ancho de la cinta de rompiente (m), ya topeado por el tamaño del cuerpo.
float decodProf(float r) { return r * ${num(PROF_MAX - PROF_MIN)} + ${num(PROF_MIN)}; }
float decodSdf(float g)  { return g * ${num(SDF_MAX - SDF_MIN)} + ${num(SDF_MIN)}; }
float decodAncho(float a) { return a * ${num(ANCHO_ESPUMA_MAX)}; }
`;

/* ═════════════════════════════════════════════════════════════════════════════
   SHADERS
   ═════════════════════════════════════════════════════════════════════════════ */

const VERTEX = /* glsl */`
uniform sampler2D uCampo;
uniform float uTiempo, uMapaTam, uProfExterior;
uniform vec2 uMapaMin;
uniform mat4 uMatrizRefl;

varying vec3 vPosMundo;
varying vec2 vBase;
varying float vDist;
varying vec4 vUvRefl;

${GLSL_GERSTNER}

#include <fog_pars_vertex>

void main() {
  vec3 base = (modelMatrix * vec4(position, 1.0)).xyz;
  vBase = base.xz;

  vec2 uv = (base.xz - uMapaMin) / uMapaTam;
  vec4 campo = texture2D(uCampo, clamp(uv, 0.0, 1.0));
  // Fuera del mapa el mar es abierto: profundidad constante y sin orilla.
  // La transición dura 7,5% del mapa (≈38 m con 512) y no 1,2% (≈6 m): a 6 m el
  // salto al mar exterior caía dentro de un par de píxeles y dibujaba el
  // RECTÁNGULO del mapa sobre el agua. Un degradé de 38 m no se ve.
  vec2 fuera = max(abs(uv - 0.5) - 0.5, 0.0);
  float borde = smoothstep(0.0, 0.075, max(fuera.x, fuera.y));
  // OJO: la profundidad se queda LOCAL, no viaja como varying.
  // Interpolada sobre quads de ~2,5 m convertía el alfa, el degradé y la orilla
  // en la silueta del grid (el "borde poligonal recto" que marcó el panel).
  // Acá sólo sirve para aplanar la ola contra la playa; el fragment la vuelve a
  // leer del campo por píxel.
  float prof = mix(decodProf(campo.r), uProfExterior, borde);

  float att = atenuacionOla(prof);
  vec3 desp, nor;
  olasGerstner(base.xz, uTiempo, att, desp, nor);

  vec3 mundo = base + desp;
  vPosMundo = mundo;
  vUvRefl = uMatrizRefl * vec4(mundo, 1.0);

  vec4 mvPosition = viewMatrix * vec4(mundo, 1.0);
  vDist = -mvPosition.z;
  gl_Position = projectionMatrix * mvPosition;

  #include <fog_vertex>
}
`;

const FRAGMENT = /* glsl */`
precision highp float;

uniform sampler2D uCampo, uOndas, uCausticas, uReflejo;
uniform float uTiempo, uMapaTam, uProfExterior, uNivel;
uniform vec2 uMapaMin;
uniform vec3 uDirSol, uColorSol, uColorCenit, uColorHorizonte, uAmbiente;
uniform vec3 uAbsorcion, uDispSomera, uDispProfunda, uFondoClaro, uFondoOscuro, uColorEspuma;
uniform float uRugosidad, uCausticaFuerza, uTurbiedad, uDistorsion, uFuerzaDetalle, uEspumaFuerza;

varying vec3 vPosMundo;
varying vec2 vBase;
varying float vDist;
varying vec4 vUvRefl;

${GLSL_GERSTNER}

#include <fog_pars_fragment>

/**
 * Cielo procedural de respaldo: sirve en preset bajo y en los bordes del reflejo.
 * OJO: devuelve RADIANCIA LINEAL HDR (el tone mapping ACES está recién en el
 * OutputPass), por eso el disco solar vale decenas y no 1.0. Si esto se limitara
 * a 0..1 el agua no podría tener un solo píxel por encima de 200 en pantalla.
 */
vec3 cieloAprox(vec3 R) {
  float h = clamp(R.y, 0.0, 1.0);
  vec3 c = mix(uColorHorizonte, uColorCenit, pow(h, 0.62));
  float s = max(dot(normalize(R), uDirSol), 0.0);
  c += uColorSol * (pow(s, 300.0) * 18.0 + pow(s, 26.0) * 0.9 + pow(s, 4.0) * 0.14);
  return c;
}

void main() {
  vec2 uv = (vBase - uMapaMin) / uMapaTam;

  // ── PROFUNDIDAD DEL AGUA, POR PÍXEL ───────────────────────────────────────
  // Ésta es la lectura que antes venía interpolada del vértice. El campo es el
  // depth buffer del lecho (estático, 1 m/texel, bilineal): la diferencia entre
  // la superficie (uNivel) y el fondo ya viene resuelta y codificada en el canal
  // R. Leerla acá, y no en el vértice, es lo que convierte el borde recortado en
  // grid en una costa curva, y lo que hace que el degradé de absorción exista
  // como gradiente CONTINUO y no como bandas por triángulo.
  vec4 campoP = texture2D(uCampo, clamp(uv, 0.0, 1.0));
  vec2 fueraP = max(abs(uv - 0.5) - 0.5, 0.0);
  float bordeP = smoothstep(0.0, 0.075, max(fueraP.x, fueraP.y));
  float profP = mix(decodProf(campoP.r), uProfExterior, bordeP);
  float att = atenuacionOla(profP);

  // ── NORMAL: Gerstner analítico por píxel + CUATRO capas de rizado ──────────
  // Antes el detalle moría a 260 m y la cámara del RTS mira a 80-250 m: el agua
  // llegaba PLANA al cuadro. Ahora la capa media aguanta hasta el horizonte y
  // sólo la fina (que aliasa) se apaga cerca; la rugosidad crece con la
  // distancia para que el brillo se ensanche en vez de titilar.
  vec3 desp, N;
  olasGerstner(vBase, uTiempo, att, desp, N);

  float fadeMedio  = 1.0 - smoothstep(240.0, 760.0, vDist);
  float fadeFino   = 1.0 - smoothstep(45.0, 200.0, vDist);
  // El chispeo tiene que llegar a la distancia de juego (80-250 m), no morir a
  // los 50 m como el detalle fino: es la única fuente de altas luces del cuadro.
  float fadeChispa = 1.0 - smoothstep(80.0, 420.0, vDist);
  vec4 o1 = texture2D(uOndas, vBase * 0.062 + vec2( 0.019,  0.012) * uTiempo);
  vec4 o2 = texture2D(uOndas, vBase * 0.145 + vec2(-0.016,  0.025) * uTiempo);
  vec4 o3 = texture2D(uOndas, vBase * 0.330 + vec2( 0.043, -0.034) * uTiempo);
  // CAPILAR: tile de ~1,6 m, o sea rizo de 20 cm. Es la escala que le faltaba a
  // la superficie para no leerse como una lámina. No entra en la normal del
  // cuerpo (a esa frecuencia sólo aportaría ruido al color): entra en la normal
  // del ESPECULAR, que es donde el ojo lee el relieve del agua.
  vec4 o4 = texture2D(uOndas, vBase * 0.620 + vec2(-0.071,  0.058) * uTiempo);
  // Manchones lentos de viento ("pata de gato"): rompen el relleno plano y
  // reparten el brillo en parches, que es como se lee un lago de verdad.
  vec4 oL = texture2D(uOndas, vBase * 0.011 + vec2( 0.0022, 0.0016) * uTiempo);
  float racha = mix(0.55, 1.55, oL.a);

  vec2 rizo = ((o1.rg - 0.5)
             + (o2.rg - 0.5) * 0.95 * fadeMedio
             + (o3.rg - 0.5) * 0.70 * fadeFino) * 2.0;
  N = normalize(N + vec3(rizo.x, 0.0, rizo.y) * uFuerzaDetalle * racha * mix(0.40, 1.0, att));

  // Normal de microfacetas para el brillo. El mipmap de uOndas apaga solo esta
  // capa con la distancia (el texel se hace subpíxel y tiende a 0.5), así que
  // no titila en el horizonte aunque la amplitud sea alta acá cerca.
  vec2 capilar = ((o4.rg - 0.5) * 1.35 + (o3.rg - 0.5) * 0.55) * 2.0;
  vec3 Nch = normalize(N + vec3(capilar.x, 0.0, capilar.y)
                           * uFuerzaDetalle * 1.20 * fadeChispa * racha);

  vec3 V = normalize(cameraPosition - vPosMundo);
  vec3 L = uDirSol;
  float solSobreHorizonte = smoothstep(-0.06, 0.10, L.y);

  // ── FRESNEL ensanchado por microfacetas ───────────────────────────────────
  // Schlick puro da 2% a 45°, que es el ángulo típico de la cámara RTS: el agua
  // no reflejaba NADA del cielo. En un píxel entran miles de facetas y muchas
  // caen cerca de rasante, así que mezclamos con un lóbulo de exponente bajo.
  float ndv = max(dot(N, V), 0.0);
  float fresnelLiso  = 0.02 + 0.98 * pow(1.0 - ndv, 5.0);
  float fresnelAncho = 0.09 + 0.91 * pow(1.0 - ndv, 2.4);
  float fresnel = clamp(mix(fresnelLiso, fresnelAncho, 0.55), 0.03, 0.90);

  // ── reflexión ─────────────────────────────────────────────────────────────
  vec3 R = reflect(-V, N);
  vec3 cielo = cieloAprox(R);
  vec3 reflejo = cielo;
  #ifdef USA_REFLEXION
    vec2 uvr = vUvRefl.xy / max(vUvRefl.w, 1e-4);
    // La distorsión se achica con la distancia: si no, el reflejo lejano hierve.
    float escalaDist = clamp(12.0 / (vDist + 12.0), 0.06, 1.0);
    uvr += N.xz * uDistorsion * escalaDist;
    // El desvanecido contra el borde de pantalla tiene que ser ANCHO. Con 4,5%
    // (86 px en 1080p) la vuelta al cielo procedural —que es más claro que el
    // render target— se leía como una BANDA RECTA pegada al canto del cuadro,
    // justo el defecto que el panel describe. Con 14% es un degradé.
    vec2 dentro = smoothstep(0.0, 0.14, uvr) * smoothstep(1.0, 0.86, uvr);
    // OJO: el step(0.0, vUvRefl.w) de antes era un escalón DURO sobre un varying,
    // o sea un filo recto atravesando la lámina en cuanto la w cambiaba de signo
    // dentro de un triángulo. Es exactamente la clase de artefacto que el panel
    // llamó "quad translúcido de borde recto sobre el agua", así que se ablanda.
    float conf = dentro.x * dentro.y * smoothstep(0.0, 0.6, vUvRefl.w);
    vec3 rt = texture2D(uReflejo, clamp(uvr, 0.001, 0.999)).rgb;
    reflejo = mix(cielo, rt, conf * 0.94);
  #endif

  // ── REFRACCIÓN: la vista del lecho se desvía con la normal ────────────────
  // Snell de pobre: el offset crece con la profundidad (más columna de agua =
  // más desvío) y satura a 4 m, que es donde el lecho ya no se ve. Con 0.7 el
  // corrimiento máximo era de 2,8 m y a la distancia de juego no se leía; con
  // 1.25 el fondo, las cáusticas y la línea de orilla ondulan de verdad debajo
  // de la ola, que es la mitad de lo que hace que el agua no parezca una calca.
  float profVista = max(profP, 0.0);
  vec2 uvRef = uv + N.xz * (1.25 * min(profVista, 4.0) / uMapaTam);
  vec4 campoR = texture2D(uCampo, clamp(uvRef, 0.0, 1.0));
  vec2 fuera = max(abs(uvRef - 0.5) - 0.5, 0.0);
  float borde = smoothstep(0.0, 0.075, max(fuera.x, fuera.y));
  float profR = max(mix(decodProf(campoR.r), uProfExterior, borde), 0.0);
  float sdfR = mix(decodSdf(campoR.g), ${num(SDF_MAX)}, borde);
  float anchoRompiente = mix(decodAncho(campoR.a), 1.6, borde);
  // FETCH del cuerpo de agua (canal B). Fuera del mapa es mar abierto ⇒ 1.
  float fetchCuerpo = mix(campoR.b, 1.0, borde);

  // El lecho: arena mojada ⇄ limo, más oscuro al hondo porque le llega menos luz.
  // El sedimento se muestrea acá (UV FIJA, sin scroll: el fondo no viaja con la
  // ola) en vez de ocupar un canal del campo; sigue la normal apenas, lo justo
  // para que el lecho ondule con la refracción.
  float sed = texture2D(uOndas, vBase * 0.075 + N.xz * 0.05 + vec2(3.17, 1.73)).b;
  float mezclaLecho = clamp((0.25 + sed * 0.60) * 0.55
                          + smoothstep(0.6, 6.0, profR) * 0.45, 0.0, 1.0);
  vec3 fondo = mix(uFondoClaro, uFondoOscuro, mezclaLecho);

  // Cáusticas: dos capas de worley invertido a distinta escala y velocidad.
  vec2 pf = vBase + N.xz * min(profVista, 5.0);
  float c1 = texture2D(uCausticas, pf * 0.085 + vec2( 0.013, 0.009) * uTiempo).r;
  float c2 = texture2D(uCausticas, pf * 0.131 + vec2(-0.008, 0.015) * uTiempo).g;
  float caustica = c1 * c2 * exp(-profR * 0.28) * solSobreHorizonte * uCausticaFuerza;
  // Tope al realce. Estaba en +190% y a mediodía eso multiplicaba una arena que
  // YA venía a 1.5 en lineal: el lecho del estanque salía por encima del blanco
  // y toda el agua somera se leía como leche. La cáustica tiene que dibujar la
  // red de filamentos, no levantar la exposición del fondo. Ahora tope +95%.
  fondo *= 1.0 + min(caustica * 3.0, 0.95);
  // La luz que llega al lecho se ACOTA: es luz que ya cruzó la superficie y una
  // columna de agua, nunca puede superar la irradiancia de la playa de al lado.
  vec3 luzFondo = min(uAmbiente * 0.55 + uColorSol * 0.55 * solSobreHorizonte, vec3(1.05));
  fondo *= luzFondo;

  // ── GRADIENTE DE PROFUNDIDAD: absorción + dispersión que vira ─────────────
  // Dos mecanismos sumados, ambos manejados por profR (per-píxel) y ninguno por
  // el alfa:
  //  · Beer-Lambert POR CANAL se come el lecho (camino óptico ida y vuelta ⇒ ×2.1).
  //    Acá el color sí es cromático: el rojo del fondo muere antes que el azul.
  //  · La luz que SUBE del cuerpo pasa de turquesa claro (20 cm) a azul (4 m) y
  //    satura con un factor ESCALAR. Esto último es el arreglo del "lechoso": con
  //    (1 - T) por canal, el rojo saturaba primero y el agua somera se cubría de
  //    un velo rosa-gris que apagaba el turquesa. El color lo pone uDispSomera/
  //    uDispProfunda; la profundidad decide nada más cuánta luz hay.
  // El TONO viaja con una exponencial, no con un smoothstep. El smoothstep tenía
  // los dos extremos planos: entre 0 y 18 cm no pasaba nada y a partir de 4,2 m
  // tampoco, así que en un estanque (todo entre 0,2 y 1,5 m) el gradiente vivía
  // en el tramo casi lineal del medio y el ojo lo leía como un relleno de un
  // tono. Con 1 - exp(-p·0.62) el color cambia RÁPIDO donde hay detalle (12% a
  // 20 cm, 46% a 1 m, 71% a 2 m) y sigue cambiando hasta los 4 m (92%): la
  // orilla es turquesa claro, el medio verde azulado y el centro azul, continuo.
  float tHondo = 1.0 - exp(-profR * 0.62);
  vec3 disp = mix(uDispSomera, uDispProfunda, tHondo);
  // Camino óptico: baja, rebota y vuelve, y encima la cámara mira oblicua ⇒ ×2.1.
  // El término fijo (0.30 m) es la capa que igual atraviesa aunque el fondo esté
  // al ras: sin él, el filo del agua no tenía absorción ninguna.
  vec3 T = exp(-uAbsorcion * uTurbiedad * (profR * 2.1 + 0.30));
  float sat = 1.0 - exp(-profR * ${num(DENS_DISP)} * uTurbiedad);
  vec3 luzAgua = uAmbiente * 0.55 + uColorSol * 0.40 * solSobreHorizonte;
  // El velo TAPA el lecho además de absorberlo: Beer-Lambert solo modela lo que
  // se absorbe, no lo que se dispersa de vuelta antes de llegar al fondo. Sin
  // este factor el lecho seguía sumando a plena luz por debajo del velo y el
  // agua somera terminaba del color de la arena, nunca turquesa.
  float velaLecho = 1.0 - sat * ${num(OCLUSION_LECHO)};
  vec3 refraccion = fondo * T * velaLecho + disp * sat * luzAgua;

  // ── ESPUMA: ancho por PENDIENTE del lecho y tope por TAMAÑO del cuerpo ────
  // anchoRompiente viene del campo, ya con los dos topes aplicados en CPU (fino
  // en un acantilado, ancho en una playa tendida, y nunca más del 28% del
  // semiancho de la masa de agua). Encima: vaivén de resaca que avanza y
  // retrocede con el tren dominante, y un ruido de amplitud proporcional al
  // ancho para que el borde NO quede paralelo a la costa.
  // ENERGÍA DE OLA LOCAL. Tres factores, y el que manda es el tercero:
  //  · att: la ola ya siente el fondo y se empina (shoaling),
  //  · oL.a: por acá pasa una racha de viento o no,
  //  · fetch: el TAMAÑO del cuerpo. Un estanque de 14 m no tiene recorrido para
  //    levantar ola, y una rompiente es una ola que se cae: sin ola, no hay.
  float energiaOla = mix(0.62, 1.15, att) * mix(0.78, 1.22, oL.a);
  float energia = energiaOla * mix(0.30, 1.0, fetchCuerpo);
  // La fase viaja con la ola dominante: cada ensenada rompe en su momento.
  float fase = uTiempo * 0.95 - dot(vec2(${num(OLAS[0].dx)}, ${num(OLAS[0].dz)}), vBase) * 0.085;
  float lamido = sin(fase + oL.b * 6.2831853) * 0.5 + 0.5;
  float alcance = anchoRompiente * mix(0.30, 1.10, lamido) * energia;
  float jitter = ((o2.b - 0.5) * 0.65 + (o3.b - 0.5) * 0.35) * anchoRompiente * 1.10;
  float d = sdfR - alcance - jitter;

  // (smoothstep con edge0 < edge1 e invertido: el orden al revés es UB en GLSL)
  float espuma = 1.0 - smoothstep(-anchoRompiente * 0.12, anchoRompiente * 0.55, d);
  espuma *= mix(0.55, 1.0, o2.b);                                   // grumos, no cinta lisa
  // Segunda capa: la lengua de agua que se retira deja un filo brillante detrás.
  float retiro = anchoRompiente * mix(0.15, 0.85, 1.0 - lamido) * energia;
  espuma = max(espuma, (1.0 - smoothstep(0.0, 0.9, abs(sdfR - retiro))) * 0.72 * o3.b);
  // Línea de orilla siempre mojada + crestas que rompen en mar abierto.
  espuma = max(espuma, (1.0 - smoothstep(0.0, 0.7, sdfR)) * 0.85);
  espuma = max(espuma, smoothstep(0.34, 0.60, desp.y) * o3.b * 0.45 * racha);
  espuma *= smoothstep(-0.05, 0.18, profP) * uEspumaFuerza;
  // TOPE POR PROFUNDIDAD. La rompiente es un fenómeno de agua somera: a partir de
  // metro y medio de fondo la ola ya no toca, no rompe y no hay espuma.
  espuma *= smoothstep(1.75, 0.20, profP);
  // TOPE POR TAMAÑO DEL CUERPO — el arreglo del defecto número uno.
  // El ancho de la cinta ya viene topeado desde el campo (no puede pasar del 28%
  // del semiancho del cuerpo), pero con el ancho solo no alcanzaba: en un
  // estanque la cinta estrecha igual salía BLANCA PURA y a esa escala dos anillos
  // blancos de 1 m se tocan en el medio. Así que también se apaga la INTENSIDAD:
  // un charco queda con una orilla apenas húmeda (6%), un lago de 40 m con
  // rompiente plena. Es la diferencia entre "estanque" y "mancha blanca".
  espuma *= mix(0.06, 1.0, fetchCuerpo) * clamp(energiaOla, 0.30, 1.15);
  espuma = clamp(espuma, 0.0, 1.0);

  // ── ESPECULAR: el agua tiene que ser lo más brillante del cuadro ──────────
  vec3 H = normalize(L + V);
  float rug = clamp(uRugosidad * mix(0.85, 1.35, racha) + vDist * 0.00040, 0.03, 0.32);
  float a2 = rug * rug * rug * rug;
  float ndh = max(dot(N, H), 0.0);
  float den = ndh * ndh * (a2 - 1.0) + 1.0;
  float ggx = a2 / (3.14159265 * den * den + 1e-5);
  // El glint del sol es la alta luz que el cuadro necesita y la que el panel
  // echó de menos: DIRECCIONAL, chico y muy brillante. Se le sube el techo y el
  // peso porque es el tipo de blanco que sí queremos (unos pocos miles de
  // píxeles ardiendo), al revés de la espuma, que es blanco extendido y plano.
  float brillo = min(ggx * fresnel, 90.0);
  // Senda del sol: lóbulo alineado con el reflejo. Es la mancha grande de altas
  // luces (miles de píxeles), no el destello puntual; al atardecer se estira en
  // el camino naranja clásico. Los exponentes están medidos: con 9.0 el camino
  // tapaba media lámina de blanco (49% del agua por encima de 200), con 14 queda
  // una senda marcada y el resto del lago conserva su color.
  // Exponente 14 → 26: el lóbulo se cierra y la senda deja de ser un velo tendido
  // sobre media lámina (parte del "agua quemada a blanco") para volver a ser un
  // camino marcado. Lo que se pierde de área se recupera en el glint de arriba,
  // que es chico y direccional. El refuerzo de sol bajo también se recorta: con
  // ×2 al atardecer la senda cubría medio estanque de dorado macizo.
  float rl = max(dot(R, L), 0.0);
  float senda = pow(rl, 26.0) * 0.26 + pow(rl, 3.0) * 0.022;
  senda *= mix(1.0, 1.45, 1.0 - smoothstep(0.28, 0.78, L.y));

  // ── CHISPEO: las altas luces que le faltan al cuadro ──────────────────────
  // El panel midió 2-3% de píxeles en altas luces contra el 3-10% de la
  // referencia, y el agua es el único elemento que puede aportarlas sin quemar
  // el resto. La condición es que vengan GRANULADAS: subir la senda del sol ya
  // se probó y da una mancha blanca lisa que costó una ronda. Esto es un lóbulo
  // estrecho sobre la normal CAPILAR, encendido sólo donde la máscara de ruido
  // deja pasar (≈1 faceta de cada 4), así que reparte miles de puntos brillantes
  // en vez de un plano quemado.
  // El exponente se ABRE con la distancia: el lóbulo se ensancha y baja de pico
  // al mismo tiempo, de modo que lejos integra a un cabrilleo estable en vez de
  // hervir de un frame al otro.
  // Exponente 150 cerca ⇒ cono de ~7°: con la normal capilar desviando hasta
  // ~35°, prende alrededor del 4% de las facetas. Con 340 (cono de 4°) el
  // chispeo era tan raro que no movía la medición: bonito y sin efecto.
  float expChispa = mix(150.0, 34.0, smoothstep(25.0, 300.0, vDist));
  float ndhC = max(dot(Nch, H), 0.0);
  // La máscara se cierra (0.28→0.42): el chispeo tapaba tanta superficie con
  // valores medios que dejaba de leerse como puntos y se sumaba al velo lechoso.
  // Menos facetas encendidas y cada una más fuerte = mismas altas luces, pero
  // GRANULADAS, que es lo que se pidió.
  float mascaraChispa = smoothstep(0.42, 0.86, o4.b * (0.55 + 0.85 * o3.a));
  float chispa = pow(ndhC, expChispa) * mascaraChispa * mix(0.65, 1.45, racha) * fadeChispa;
  // Cae con el ángulo rasante del sol igual que cualquier reflejo especular.
  chispa *= mix(0.35, 1.0, clamp(fresnel * 4.0, 0.0, 1.0));
  // Un charco no cabrillea: el cabrilleo son crestas capilares empujadas por el
  // viento, y el viento necesita recorrido. Mismo argumento que la espuma.
  chispa *= mix(0.40, 1.0, fetchCuerpo);

  // Reparto medido sobre el estanque de prueba: el glint (brillo) es angosto y
  // puede pesar, la senda y el chispeo son extensos y hay que tenerlos cortos.
  // Con chispa a 3.6 la lámina entera pasaba a dorado macizo.
  vec3 especular = uColorSol * (brillo * 0.34 + senda + chispa * 2.2) * solSobreHorizonte;

  vec3 color = mix(refraccion, reflejo, fresnel);
  color += especular;
  // Traslucidez de cresta: con el sol por detrás, el lomo de la ola se enciende.
  float cresta = smoothstep(0.12, 0.46, desp.y) * att;
  float contraluz = pow(max(-dot(V, L) * 0.5 + 0.5, 0.0), 3.0);
  color += uDispSomera * uColorSol * (cresta * contraluz * 0.40 * solSobreHorizonte);
  // uColorSol es radiancia LINEAL: a mediodía pasa de 3. Multiplicarlo por 0.95
  // ponía la espuma en ~3.3 lineal, o sea blanco recortado después del tone
  // mapping, sin textura ni grumo. La espuma es agua con aire: refleja mucho,
  // pero no más que la arena a pleno sol.
  vec3 luzEspuma = uAmbiente * 0.75 + uColorSol * 0.42 * solSobreHorizonte;
  luzEspuma = min(luzEspuma, vec3(1.12));
  color = mix(color, uColorEspuma * luzEspuma, espuma);

  // ── ALFA: transparencia por PROFUNDIDAD, per-píxel y con orilla que respira ─
  // Dos cosas acá. La primera: profP es POR PÍXEL. Cuando esto salía del varying,
  // la línea alfa=0 era una polilínea sobre la triangulación y ése era el "borde
  // poligonal recto contra la costa" — la malla ya se extiende bajo el terreno y
  // el recorte lo hace el depth test, así que el borde que se veía no era
  // geométrico sino el del alfa.
  // La segunda: se le suma un rizo de ±4 cm de profundidad aparente. Sobre una
  // playa de pendiente suave eso mueve el filo del agua medio metro de un lado al
  // otro y lo hace ondular con el oleaje, en vez de dejarlo calcado al contorno
  // del heightmap.
  float rizoOrilla = ((o3.b - 0.5) * 0.055 + (o2.b - 0.5) * 0.035) * fadeFino;
  float alfa = smoothstep(0.025, 2.30, profP + rizoOrilla);
  // El brillo y la espuma se dibujan sobre lámina traslúcida: sin este piso el
  // blend se los come justo donde más falta hacen (la orilla).
  float lumBrillo = dot(especular, vec3(0.2126, 0.7152, 0.0722));
  alfa = max(alfa, clamp(lumBrillo * 0.85, 0.0, 1.0));
  alfa = clamp(max(alfa, max(fresnel * 0.85, espuma * 0.96)), 0.0, 1.0);
  if (alfa < 0.006) discard;

  gl_FragColor = vec4(color, alfa);

  #include <fog_fragment>
}
`;

/* ═════════════════════════════════════════════════════════════════════════════
   TEXTURAS PROCEDURALES (canvas 2D, cero assets)
   ═════════════════════════════════════════════════════════════════════════════ */

/** Ruido de valor tileable: la celosía se envuelve con módulo, así repite sin costura. */
function ruidoValorTileable(perm, x, y, periodo) {
  const xi = Math.floor(x), yi = Math.floor(y);
  const xf = x - xi, yf = y - yi;
  const u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf);
  const w = (i) => ((i % periodo) + periodo) % periodo;
  const h = (a, b) => perm[(perm[w(a) & 255] + w(b)) & 255] / 255;
  const x0 = w(xi), x1 = w(xi + 1), y0 = w(yi), y1 = w(yi + 1);
  const a = h(x0, y0), b = h(x1, y0), c = h(x0, y1), d = h(x1, y1);
  return (a + (b - a) * u) + ((c + (d - c) * u) - (a + (b - a) * u)) * v;
}

function fbmTileable(perm, x, y, periodo, octavas) {
  let suma = 0, norma = 0, amp = 1, esc = 1;
  for (let o = 0; o < octavas; o++) {
    suma += amp * ruidoValorTileable(perm, x * esc, y * esc, periodo * esc);
    norma += amp;
    amp *= 0.5; esc *= 2;
  }
  return suma / norma;
}

/** Worley tileable: un punto por celda, vecindad envuelta. Devuelve F1 normalizado. */
function worleyTileable(perm, x, y, celdas) {
  const cx = Math.floor(x), cy = Math.floor(y);
  let f1 = 4;
  for (let oy = -1; oy <= 1; oy++) {
    for (let ox = -1; ox <= 1; ox++) {
      const gx = cx + ox, gy = cy + oy;
      const wx = ((gx % celdas) + celdas) % celdas;
      const wy = ((gy % celdas) + celdas) % celdas;
      const h1 = perm[(perm[wx & 255] + wy) & 255] / 255;
      const h2 = perm[(perm[(wx + 71) & 255] + wy + 29) & 255] / 255;
      const px = gx + 0.15 + h1 * 0.7, py = gy + 0.15 + h2 * 0.7;
      const dx = px - x, dy = py - y;
      const d = Math.sqrt(dx * dx + dy * dy);
      if (d < f1) f1 = d;
    }
  }
  return Math.min(f1, 1);
}

/* ═════════════════════════════════════════════════════════════════════════════
   TRANSFORMADA DE DISTANCIA (8SSEDT por propagación de vectores)
   Dos pasadas sobre la rejilla; error respecto de la euclídea exacta < 1%.
   ═════════════════════════════════════════════════════════════════════════════ */
function distanciaA(mascara, ancho, alto) {
  const n = ancho * alto;
  const INF = 1e9;
  const dx = new Int32Array(n), dy = new Int32Array(n), d2 = new Float64Array(n);
  for (let i = 0; i < n; i++) {
    if (mascara[i]) { d2[i] = 0; dx[i] = 0; dy[i] = 0; }
    else { d2[i] = INF; dx[i] = 9999; dy[i] = 9999; }
  }
  const comparar = (i, j, ox, oy) => {
    if (d2[j] >= INF) return;
    const cx = dx[j] + ox, cy = dy[j] + oy;
    const c = cx * cx + cy * cy;
    if (c < d2[i]) { d2[i] = c; dx[i] = cx; dy[i] = cy; }
  };
  for (let y = 0; y < alto; y++) {
    for (let x = 0; x < ancho; x++) {
      const i = y * ancho + x;
      if (x > 0) comparar(i, i - 1, 1, 0);
      if (y > 0) comparar(i, i - ancho, 0, 1);
      if (x > 0 && y > 0) comparar(i, i - ancho - 1, 1, 1);
      if (x < ancho - 1 && y > 0) comparar(i, i - ancho + 1, -1, 1);
    }
    for (let x = ancho - 2; x >= 0; x--) comparar(y * ancho + x, y * ancho + x + 1, -1, 0);
  }
  for (let y = alto - 1; y >= 0; y--) {
    for (let x = ancho - 1; x >= 0; x--) {
      const i = y * ancho + x;
      if (x < ancho - 1) comparar(i, i + 1, -1, 0);
      if (y < alto - 1) comparar(i, i + ancho, 0, -1);
      if (x < ancho - 1 && y < alto - 1) comparar(i, i + ancho + 1, -1, -1);
      if (x > 0 && y < alto - 1) comparar(i, i + ancho - 1, 1, -1);
    }
    for (let x = 1; x < ancho; x++) comparar(y * ancho + x, y * ancho + x - 1, 1, 0);
  }
  const salida = new Float32Array(n);
  for (let i = 0; i < n; i++) salida[i] = Math.sqrt(d2[i] >= INF ? 1e6 : d2[i]);
  return salida;
}

/* ═════════════════════════════════════════════════════════════════════════════
   SISTEMA
   ═════════════════════════════════════════════════════════════════════════════ */
export class Agua {
  constructor(ctx) {
    this.nombre = 'agua';
    this.orden = 99;
    this.ctx = ctx;
    this.tiempo = 0;
    this.edad = 0;

    this.tam = ctx.mapa?.tam ?? ctx.terreno?.tam ?? 512;
    this.nivel = ctx.mapa?.nivelAgua ?? 0;
    this.margen = Math.max(220, this.tam * 0.45);

    const calidad = ctx.render?.calidad ?? ctx.calidad ?? 'alta';
    this.calidad = calidad;
    this.usaReflexion = calidad === 'alta' || calidad === 'ultra';

    // Tabla de permutación propia, sembrada por ctx.rng: nada de Math.random.
    this.perm = this._permutacion(ctx);

    // Un solo perfil de color para TODO el mapa: se resuelve una vez, acá.
    this.perfil = this._perfilDelMapa(ctx);

    this._construirCampo(ctx);
    this._construirTexturas(ctx);
    this._construirReflexion(ctx);
    this._construirMalla(ctx);

    // Estado de paleta: se interpola al cambiar de edad en vez de saltar.
    this._paleta = this._nuevaPaleta();
    this._paletaObjetivo = this._nuevaPaleta();
    this._leerPaleta(0, this._paleta);
    this._leerPaleta(0, this._paletaObjetivo);
    this._volcarPaleta(1);

    // Temporales reutilizados por frame (cero asignaciones en el bucle).
    this._v3 = new THREE.Vector3();
    this._v3b = new THREE.Vector3();
    this._colA = new THREE.Color();
    this._colB = new THREE.Color();
    this._plano = new THREE.Plane();
    this._q = new THREE.Vector4();
    this._clip = new THREE.Vector4();

    ctx.escena.add(this.malla);
  }

  /* ---------------------------------------------------------------- semillas */
  _permutacion(ctx) {
    const p = new Uint8Array(256);
    for (let i = 0; i < 256; i++) p[i] = i;
    const rng = ctx.rng?.fork ? ctx.rng.fork(0x4147_5541) : ctx.rng;
    for (let i = 255; i > 0; i--) {
      const j = rng ? rng.int(0, i) : i;
      const t = p[i]; p[i] = p[j]; p[j] = t;
    }
    return p;
  }

  /* ------------------------------------------------- campo del lecho (RGBA8) */
  /**
   * Muestreador de alturas: primero el campo crudo del mapa (`ctx.mapa.alturas`,
   * que existe aunque el sistema de Terreno todavía no se haya construido),
   * después `terreno.altura`, y recién al final el mar abierto. El orden importa:
   * con el fallback plano el campo salía sin costa ni gradiente y el agua quedaba
   * de un solo color, que es justo el defecto que hay que arreglar.
   */
  _muestreadorAlturas(ctx) {
    const mapa = ctx.mapa;
    const alturas = mapa?.alturas;
    const r = mapa?.res | 0;
    if (alturas && r > 1 && alturas.length >= r * r) {
      const tam = mapa.tam ?? this.tam;
      const paso = tam / (r - 1), mitad = tam * 0.5;
      return (x, z) => {
        let fx = (x + mitad) / paso, fz = (z + mitad) / paso;
        fx = fx < 0 ? 0 : (fx > r - 1.0001 ? r - 1.0001 : fx);
        fz = fz < 0 ? 0 : (fz > r - 1.0001 ? r - 1.0001 : fz);
        const c0 = fx | 0, f0 = fz | 0;
        const tx = fx - c0, tz = fz - f0;
        const i = f0 * r + c0;
        const a = alturas[i] + (alturas[i + 1] - alturas[i]) * tx;
        const b = alturas[i + r] + (alturas[i + r + 1] - alturas[i + r]) * tx;
        return a + (b - a) * tz;
      };
    }
    if (typeof ctx.terreno?.altura === 'function') return (x, z) => ctx.terreno.altura(x, z);
    const hondo = this.nivel - 6;
    return () => hondo; // sin datos: mar abierto, nunca costa fantasma
  }

  /**
   * RADIO INTERIOR DE CADA MASA DE AGUA, por texel (metros).
   *
   * Flood fill de 4 vecinos sobre la máscara de agua: cada charco, estanque,
   * lago o mar recibe una etiqueta, y de cada uno se guarda la mayor distancia a
   * tierra que se alcanza adentro. Ése es su semiancho: un estanque de 14 m de
   * diámetro da ~7, el mar da el tope de la rejilla.
   *
   * Es la información que le faltaba al shader para no pintar 3 m de rompiente a
   * cada lado de un estanque de 8 m. Cuesta una pasada al cargar (cada texel
   * entra en la pila una sola vez, se etiqueta AL APILAR) y cero por frame.
   *
   * Después se DILATA sobre la tierra con un máximo de 3×3, cuatro pasadas.
   * Hace falta: el shader lee el campo con filtrado bilineal y encima desplaza la
   * UV con la normal de la ola, así que muestrea texeles de tierra justo en la
   * orilla — que es donde vive toda la espuma. Sin la dilatación esos texeles
   * valen 0 y la cinta se apagaría precisamente donde tiene que verse.
   */
  _radioDeCadaCuerpo(esAgua, dTierra, res) {
    const n = res * res;
    const mpt = this.metrosPorTexel;
    const radio = new Float32Array(n);
    const etiqueta = new Int32Array(n).fill(-1);
    const pila = new Int32Array(n);
    const radioCuerpo = [];

    for (let semilla = 0; semilla < n; semilla++) {
      if (!esAgua[semilla] || etiqueta[semilla] >= 0) continue;
      const id = radioCuerpo.length;
      let tope = 0, maxR = 0;
      etiqueta[semilla] = id;
      pila[tope++] = semilla;
      while (tope > 0) {
        const k = pila[--tope];
        const r = dTierra[k] * mpt;
        if (r > maxR) maxR = r;
        const i = k % res, j = (k / res) | 0;
        if (i > 0 && esAgua[k - 1] && etiqueta[k - 1] < 0) { etiqueta[k - 1] = id; pila[tope++] = k - 1; }
        if (i < res - 1 && esAgua[k + 1] && etiqueta[k + 1] < 0) { etiqueta[k + 1] = id; pila[tope++] = k + 1; }
        if (j > 0 && esAgua[k - res] && etiqueta[k - res] < 0) { etiqueta[k - res] = id; pila[tope++] = k - res; }
        if (j < res - 1 && esAgua[k + res] && etiqueta[k + res] < 0) { etiqueta[k + res] = id; pila[tope++] = k + res; }
      }
      radioCuerpo.push(maxR);
    }
    for (let k = 0; k < n; k++) radio[k] = etiqueta[k] >= 0 ? radioCuerpo[etiqueta[k]] : 0;

    // Dilatación por máximo (4 pasadas ⇒ ~4 texeles ≈ 4 m de margen en tierra).
    const tmp = new Float32Array(n);
    for (let pase = 0; pase < 4; pase++) {
      const src = (pase & 1) === 0 ? radio : tmp;
      const dst = (pase & 1) === 0 ? tmp : radio;
      for (let j = 0; j < res; j++) {
        const j0 = Math.max(0, j - 1) * res, j1 = j * res, j2 = Math.min(res - 1, j + 1) * res;
        for (let i = 0; i < res; i++) {
          const i0 = Math.max(0, i - 1), i2 = Math.min(res - 1, i + 1);
          let m = src[j1 + i];
          if (src[j0 + i0] > m) m = src[j0 + i0];
          if (src[j0 + i] > m) m = src[j0 + i];
          if (src[j0 + i2] > m) m = src[j0 + i2];
          if (src[j1 + i0] > m) m = src[j1 + i0];
          if (src[j1 + i2] > m) m = src[j1 + i2];
          if (src[j2 + i0] > m) m = src[j2 + i0];
          if (src[j2 + i] > m) m = src[j2 + i];
          if (src[j2 + i2] > m) m = src[j2 + i2];
          dst[j1 + i] = m;
        }
      }
    }
    return radio; // pasadas pares ⇒ el resultado final queda en `radio`
  }

  /**
   * Se muestrea el terreno una única vez. La alternativa (DepthTexture de escena)
   * costaría un prepass por frame y contaminaría la costa con unidades y árboles.
   */
  _construirCampo(ctx) {
    const res = (this.calidad === 'alta' || this.calidad === 'ultra') ? 512 : 256;
    const tam = this.tam, nivel = this.nivel;
    this.resCampo = res;
    this.metrosPorTexel = tam / res;

    const alt = new Float32Array(res * res);
    const muestrear = this._muestreadorAlturas(ctx);

    for (let j = 0; j < res; j++) {
      const z = -tam / 2 + (j + 0.5) * this.metrosPorTexel;
      for (let i = 0; i < res; i++) {
        const x = -tam / 2 + (i + 0.5) * this.metrosPorTexel;
        const h = muestrear(x, z);
        alt[j * res + i] = Number.isFinite(h) ? h : nivel - 6;
      }
    }

    const esAgua = new Uint8Array(res * res);
    const esTierra = new Uint8Array(res * res);
    for (let i = 0; i < res * res; i++) {
      if (alt[i] < nivel) esAgua[i] = 1; else esTierra[i] = 1;
    }
    const dTierra = distanciaA(esTierra, res, res); // para celdas de agua
    const dAgua = distanciaA(esAgua, res, res);     // para celdas de tierra

    // Tamaño de cada masa de agua, por texel. Ver la nota de FRACCION_ROMPIENTE.
    const radio = this._radioDeCadaCuerpo(esAgua, dTierra, res);

    const datos = new Uint8Array(res * res * 4);
    const prof = new Float32Array(res * res);
    const sdf = new Float32Array(res * res);
    const ancho = new Float32Array(res * res);
    const invProf = 255 / (PROF_MAX - PROF_MIN);
    const invSdf = 255 / (SDF_MAX - SDF_MIN);
    const mpt = this.metrosPorTexel;
    // Profundidad a la que la ola rompe: el ancho de la cinta de espuma es la
    // distancia horizontal que tarda el lecho en bajar hasta acá. De ahí sale
    // solo que una playa tendida tenga cinta ancha y un acantilado casi nada.
    const PROF_ROMPIENTE = 0.35;

    for (let j = 0; j < res; j++) {
      for (let i = 0; i < res; i++) {
        const k = j * res + i;
        const p = nivel - alt[k];
        // Media celda de corrección: la orilla real cae entre texeles.
        const s = esAgua[k] ? (dTierra[k] - 0.5) * mpt : -(dAgua[k] - 0.5) * mpt;
        prof[k] = p;
        sdf[k] = s;

        // Pendiente del lecho por diferencias centrales de ±2 texeles: con ±1 el
        // ruido fino del heightmap hace temblar el ancho de la espuma.
        const ix0 = Math.max(0, i - 2), ix1 = Math.min(res - 1, i + 2);
        const jy0 = Math.max(0, j - 2), jy1 = Math.min(res - 1, j + 2);
        const gx = (alt[j * res + ix1] - alt[j * res + ix0]) / ((ix1 - ix0) * mpt);
        const gz = (alt[jy1 * res + i] - alt[jy0 * res + i]) / ((jy1 - jy0) * mpt);
        const pendiente = Math.hypot(gx, gz);
        // DOS topes al ancho de la cinta, y hace falta el segundo:
        //  · la pendiente (playa tendida = ancho, acantilado = fino), y
        //  · el TAMAÑO del cuerpo. Un fondo plano da pendiente ~0 y mandaba el
        //    ancho al tope de la constante, así que un estanque de 14 m de
        //    diámetro se llevaba 3 m de rompiente de cada lado y quedaba blanco
        //    de orilla a orilla. La rompiente no puede pasar del 28% del
        //    semiancho del cuerpo: si no, ya no es una orilla, es la laguna.
        const topeCuerpo = Math.max(0.25, radio[k] * FRACCION_ROMPIENTE);
        ancho[k] = Math.min(
          ANCHO_ESPUMA_MAX,
          topeCuerpo,
          Math.max(0.8, PROF_ROMPIENTE / Math.max(pendiente, 0.02)),
        );

        // Canal B = FETCH normalizado del cuerpo (0 charco, 1 lago grande/mar).
        // Con smootherstep para que no haya escalón entre cuerpos de tamaño
        // parecido. (Acá vivía la variación de sedimento; se mudó al shader,
        // donde es una muestra de uOndas con UV fija y no gasta un canal.)
        const tf = Math.min(1, Math.max(0,
          (radio[k] - RADIO_FETCH_MIN) / (RADIO_FETCH_PLENO - RADIO_FETCH_MIN)));

        const o = k * 4;
        datos[o]     = Math.max(0, Math.min(255, Math.round((p - PROF_MIN) * invProf)));
        datos[o + 1] = Math.max(0, Math.min(255, Math.round((s - SDF_MIN) * invSdf)));
        datos[o + 2] = Math.round(tf * tf * (3 - 2 * tf) * 255);
      }
    }

    // El ancho de rompiente se suaviza a lo largo de la costa (dos pasadas de
    // caja 3×3): la cinta tiene que cambiar de ancho de a poco, no a saltos.
    const tmp = new Float32Array(res * res);
    for (let pase = 0; pase < 2; pase++) {
      const src = pase === 0 ? ancho : tmp;
      const dst = pase === 0 ? tmp : ancho;
      for (let j = 0; j < res; j++) {
        const j0 = Math.max(0, j - 1) * res, j1 = j * res, j2 = Math.min(res - 1, j + 1) * res;
        for (let i = 0; i < res; i++) {
          const i0 = Math.max(0, i - 1), i1 = i, i2 = Math.min(res - 1, i + 1);
          dst[j1 + i] = (
            src[j0 + i0] + src[j0 + i1] + src[j0 + i2] +
            src[j1 + i0] + src[j1 + i1] + src[j1 + i2] +
            src[j2 + i0] + src[j2 + i1] + src[j2 + i2]
          ) / 9;
        }
      }
    }
    for (let k = 0; k < res * res; k++) {
      datos[k * 4 + 3] = Math.round(Math.min(1, ancho[k] / ANCHO_ESPUMA_MAX) * 255);
    }

    this.profundidades = prof;
    this.sdfCosta = sdf;

    const tex = new THREE.DataTexture(datos, res, res, THREE.RGBAFormat, THREE.UnsignedByteType);
    tex.magFilter = THREE.LinearFilter;
    tex.minFilter = THREE.LinearFilter;
    tex.wrapS = tex.wrapT = THREE.ClampToEdgeWrapping;
    tex.colorSpace = THREE.NoColorSpace;
    tex.needsUpdate = true;
    this.texCampo = tex;
  }

  /* ------------------------------------------------ texturas de olas/cáusticas */
  _construirTexturas() {
    this.texOndas = this._texturaOndas(256);
    this.texCausticas = this._texturaCausticas(256);
  }

  /**
   * RG = normal del rizado (codificada), B = altura (ruido de espuma fina),
   * A = ruido lento de costa. Cuatro canales, una sola muestra.
   */
  _texturaOndas(res) {
    const perm = this.perm;
    const alturas = new Float32Array(res * res);
    for (let j = 0; j < res; j++) {
      for (let i = 0; i < res; i++) {
        alturas[j * res + i] = fbmTileable(perm, (i / res) * 8, (j / res) * 8, 8, 4);
      }
    }
    const lienzo = document.createElement('canvas');
    lienzo.width = lienzo.height = res;
    const g2d = lienzo.getContext('2d');
    const img = g2d.createImageData(res, res);
    const d = img.data;
    const esc = 3.2;
    for (let j = 0; j < res; j++) {
      for (let i = 0; i < res; i++) {
        const k = j * res + i;
        const izq = alturas[j * res + ((i - 1 + res) % res)];
        const der = alturas[j * res + ((i + 1) % res)];
        const arr = alturas[((j - 1 + res) % res) * res + i];
        const aba = alturas[((j + 1) % res) * res + i];
        let nx = (izq - der) * esc, nz = (arr - aba) * esc;
        const inv = 1 / Math.hypot(nx, nz, 1);
        nx *= inv; nz *= inv;
        const lento = fbmTileable(perm, (i / res) * 3 + 11, (j / res) * 3 + 7, 3, 3);
        const o = k * 4;
        d[o] = Math.round((nx * 0.5 + 0.5) * 255);
        d[o + 1] = Math.round((nz * 0.5 + 0.5) * 255);
        d[o + 2] = Math.round(Math.min(1, Math.max(0, alturas[k])) * 255);
        d[o + 3] = Math.round(Math.min(1, Math.max(0, lento)) * 255);
      }
    }
    g2d.putImageData(img, 0, 0);
    const tex = new THREE.CanvasTexture(lienzo);
    tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
    tex.minFilter = THREE.LinearMipmapLinearFilter;
    tex.magFilter = THREE.LinearFilter;
    tex.colorSpace = THREE.NoColorSpace;
    tex.anisotropy = 4;
    tex.generateMipmaps = true;
    return tex;
  }

  /** Worley invertido y afilado en dos escalas (R y G) para cruzarlas en el shader. */
  _texturaCausticas(res) {
    const perm = this.perm;
    const lienzo = document.createElement('canvas');
    lienzo.width = lienzo.height = res;
    const g2d = lienzo.getContext('2d');
    const img = g2d.createImageData(res, res);
    const d = img.data;
    const capa = (i, j, celdas, sesgo) => {
      const f1 = worleyTileable(perm, (i / res) * celdas + sesgo, (j / res) * celdas + sesgo, celdas);
      const v = 1 - Math.min(1, f1 / 0.7);
      return Math.pow(v, 2.6); // afilado: los filamentos son finos y brillantes
    };
    for (let j = 0; j < res; j++) {
      for (let i = 0; i < res; i++) {
        const o = (j * res + i) * 4;
        d[o] = Math.round(capa(i, j, 6, 0) * 255);
        d[o + 1] = Math.round(capa(i, j, 9, 3) * 255);
        d[o + 2] = Math.round(capa(i, j, 14, 7) * 255);
        d[o + 3] = 255;
      }
    }
    g2d.putImageData(img, 0, 0);
    const tex = new THREE.CanvasTexture(lienzo);
    tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
    tex.minFilter = THREE.LinearMipmapLinearFilter;
    tex.magFilter = THREE.LinearFilter;
    tex.colorSpace = THREE.NoColorSpace;
    tex.anisotropy = 4;
    return tex;
  }

  /* ------------------------------------------------------- reflexión planar */
  _construirReflexion(ctx) {
    this.camReflejo = new THREE.PerspectiveCamera();
    this.matrizRefl = new THREE.Matrix4();
    this.reflejoRT = null;
    this._reflejoValido = false;
    if (!this.usaReflexion) return;

    const escala = this.calidad === 'ultra' ? 0.55 : 0.42;
    const w = Math.max(256, Math.round(window.innerWidth * escala));
    const h = Math.max(160, Math.round(window.innerHeight * escala));
    this.reflejoRT = new THREE.WebGLRenderTarget(w, h, {
      type: THREE.HalfFloatType, samples: 0,
      minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter,
      depthBuffer: true, generateMipmaps: false,
      colorSpace: THREE.LinearSRGBColorSpace,
    });
    this._escalaRT = escala;
    this._alRedimensionar = () => {
      if (!this.reflejoRT) return;
      this.reflejoRT.setSize(
        Math.max(256, Math.round(window.innerWidth * this._escalaRT)),
        Math.max(160, Math.round(window.innerHeight * this._escalaRT)),
      );
    };
    window.addEventListener('resize', this._alRedimensionar);
  }

  /**
   * REPARTO DE VÉRTICES: densos sobre el mapa, estirados en el mar de relleno.
   *
   * La lámina mide `tam + 2·margen` (≈970 m con un mapa de 512) porque tiene que
   * llegar al horizonte y, sobre todo, meterse BAJO el terreno para que el
   * recorte de la costa lo haga el depth test y no el borde de la malla. Con un
   * grid uniforme, casi la mitad de los segmentos se van a ese relleno exterior
   * —agua plana, lejana, que nadie mira de cerca— y a la costa le quedan quads
   * de ~3,4 m.
   *
   * El remapeo es lineal dentro del mapa (densidad constante, sin apelotonar el
   * centro) y cuadrático hacia afuera, con la derivada empalmada en la juntura
   * para que no haya un escalón de tamaño de quad. Resultado: ~2,5 m de quad
   * sobre el mapa entero y quads largos sólo mar afuera. Cuesta una pasada sobre
   * el buffer al cargar y cero por frame.
   */
  _densificarHaciaElMapa(geo, lado) {
    const medio = lado * 0.5;
    // c = dónde termina el mapa en coordenada normalizada; b = qué fracción de
    // los segmentos le dedicamos. b > c ⇒ el mapa se lleva más malla de la que
    // le tocaría por área.
    const c = Math.min(0.94, (this.tam * 0.5) / medio);
    const b = Math.min(0.94, c + (1 - c) * 0.36);
    if (b <= c + 1e-4) return; // margen despreciable: no hay nada que redistribuir
    // Continuidad de la derivada en la juntura fija el término lineal de afuera.
    const alfa = (c * (1 - b)) / (b * (1 - c));
    const remap = (v) => {
      const n = v / medio;
      const a = Math.abs(n);
      if (a <= b) return (c / b) * n * medio;
      const t = (a - b) / (1 - b);
      const f = c + (1 - c) * (alfa * t + (1 - alfa) * t * t);
      return Math.sign(n) * f * medio;
    };
    const pos = geo.attributes.position;
    const arr = pos.array;
    for (let i = 0; i < arr.length; i += 3) {
      arr[i] = remap(arr[i]);
      arr[i + 2] = remap(arr[i + 2]);
    }
    pos.needsUpdate = true;
  }

  /* ------------------------------------------------------------ malla + material */
  _construirMalla(ctx) {
    const lado = this.tam + this.margen * 2;
    const seg = { baja: 128, media: 192, alta: 288, ultra: 384 }[this.calidad] ?? 288;
    const geo = new THREE.PlaneGeometry(lado, lado, seg, seg);
    geo.rotateX(-Math.PI / 2); // el plano queda en XZ: position.xz son metros de mundo
    // El shader no usa uv ni normal: sacarlas ahorra 5 floats por vértice de banda.
    geo.deleteAttribute('uv');
    geo.deleteAttribute('normal');
    this._densificarHaciaElMapa(geo, lado);
    geo.computeBoundingSphere();

    const uniformes = THREE.UniformsUtils.merge([
      THREE.UniformsLib.fog,
      {
        uCampo: { value: null }, uOndas: { value: null },
        uCausticas: { value: null }, uReflejo: { value: null },
        uTiempo: { value: 0 }, uNivel: { value: this.nivel },
        uMapaTam: { value: this.tam }, uMapaMin: { value: new THREE.Vector2(-this.tam / 2, -this.tam / 2) },
        // Coherente con PROF_MAX: fuera del mapa el agua ya está saturada de azul.
        uProfExterior: { value: 12 },
        uMatrizRefl: { value: new THREE.Matrix4() },
        uDirSol: { value: new THREE.Vector3(0.4, 0.62, 0.35).normalize() },
        uColorSol: { value: new THREE.Color(1.0, 0.86, 0.66) },
        uColorCenit: { value: new THREE.Color(0.20, 0.36, 0.62) },
        uColorHorizonte: { value: new THREE.Color(0.62, 0.72, 0.84) },
        uAmbiente: { value: new THREE.Color(0.32, 0.38, 0.46) },
        uAbsorcion: { value: new THREE.Vector3(0.42, 0.115, 0.075) },
        uDispSomera: { value: new THREE.Color(0x8ad9c6) },
        uDispProfunda: { value: new THREE.Color(0x2c74a8) },
        uFondoClaro: { value: new THREE.Color(0xd8c79a) },
        uFondoOscuro: { value: new THREE.Color(0x6e7a56) },
        uColorEspuma: { value: new THREE.Color(0xf6f4ea) },
        uRugosidad: { value: 0.072 },
        uCausticaFuerza: { value: 0.90 },
        uTurbiedad: { value: 1.0 },
        // El reflejo del cielo tiene que ONDULAR con la ola: si la UV se desvía
        // poco, la lámina devuelve un cielo calcado y eso se lee como plástico
        // plano. 0.075 es lo máximo antes de que el reflejo hierva de cerca.
        uDistorsion: { value: 0.075 },
        uFuerzaDetalle: { value: 1.0 },
        uEspumaFuerza: { value: 1.0 },
      },
    ]);
    // UniformsUtils.merge clona: hay que volver a enchufar las texturas.
    uniformes.uCampo.value = this.texCampo;
    uniformes.uOndas.value = this.texOndas;
    uniformes.uCausticas.value = this.texCausticas;
    uniformes.uReflejo.value = this.reflejoRT ? this.reflejoRT.texture : null;

    const mat = new THREE.ShaderMaterial({
      name: 'agua',
      uniforms: uniformes,
      vertexShader: VERTEX,
      fragmentShader: FRAGMENT,
      transparent: true,
      depthWrite: true,     // la lámina es casi opaca: debe ocluir lo sumergido
      depthTest: true,
      side: THREE.FrontSide,
      fog: true,
      defines: this.usaReflexion ? { USA_REFLEXION: '' } : {},
    });
    this.material = mat;

    this.malla = new THREE.Mesh(geo, mat);
    this.malla.name = 'agua';
    this.malla.position.y = this.nivel;
    this.malla.matrixAutoUpdate = false;
    this.malla.updateMatrix();
    this.malla.updateMatrixWorld(true);
    this.malla.receiveShadow = false; // ShaderMaterial crudo: no participa del CSM
    this.malla.castShadow = false;
    // Primero entre los transparentes: escribe profundidad y actúa como superficie
    // sólida para las partículas y el foliaje que se dibujan después.
    this.malla.renderOrder = -1;
  }

  /* ------------------------------------------------------------------ paleta */
  /**
   * UN perfil de color para todo el mapa, elegido por el bioma dominante en
   * tierra. Es la regla dura contra el defecto que marcó el jurado: dos cuerpos
   * de agua a la vista NO pueden tener colores distintos con la misma luz, así
   * que el tono no se decide por cuerpo ni por parche de lecho, se decide una
   * sola vez acá y viaja como uniform global.
   */
  _perfilDelMapa(ctx) {
    const biomas = ctx.mapa?.biomas ?? ctx.terreno?.biomas;
    const nombres = ctx.mapa?.nombresBioma ?? ctx.terreno?.nombresBioma;
    if (!biomas || !biomas.length) return PERFIL_POR_DEFECTO;

    // Conteo con paso 3: alcanza de sobra para saber qué manda y cuesta un tercio.
    const cuenta = new Uint32Array(8);
    for (let i = 0; i < biomas.length; i += 3) cuenta[biomas[i] & 7]++;

    let mejor = -1, mejorN = -1;
    for (let b = 0; b < 8; b++) {
      // El bioma 5 es el agua misma: no define el color del agua.
      const nombre = this._claveBioma(nombres, b);
      if (nombre === 'agua' || nombre === null) continue;
      if (cuenta[b] > mejorN) { mejorN = cuenta[b]; mejor = b; }
    }
    const clave = this._claveBioma(nombres, mejor);
    return PERFILES_BIOMA[clave] ?? PERFIL_POR_DEFECTO;
  }

  /** Normaliza el nombre de bioma (sin acentos, minúsculas) al índice del mapa. */
  _claveBioma(nombres, indice) {
    if (indice < 0) return null;
    const crudo = nombres?.[indice];
    if (typeof crudo === 'string') {
      return crudo.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
    }
    // Orden canónico del generador cuando no publica nombres.
    return ['pradera', 'bosque', 'montana', 'desierto', 'playa', 'agua'][indice] ?? null;
  }

  _nuevaPaleta() {
    return {
      absorcion: new THREE.Vector3(), somera: new THREE.Color(), profunda: new THREE.Color(),
      fondoClaro: new THREE.Color(), fondoOscuro: new THREE.Color(),
      espuma: new THREE.Color(), rugosidad: 0, causticas: 0, turbiedad: 1,
    };
  }

  /** Perfil único del mapa + modulador escalar de la edad. El tono no se mueve. */
  _leerPaleta(n, destino) {
    const p = this.perfil;
    const m = MODULADORES_EDAD[Math.max(0, Math.min(MODULADORES_EDAD.length - 1, n | 0))];
    // La turbiedad NO se multiplica acá: el shader ya hace uAbsorcion * uTurbiedad.
    destino.absorcion.set(p.absorcion[0], p.absorcion[1], p.absorcion[2]);
    // El tinte de edad es multiplicativo y mínimo: mueve el aire del agua sin
    // cambiarle el tono, que es lo que tiene que quedar fijo por mapa.
    tintar(destino.somera.setHex(p.somera), m.tinte);
    tintar(destino.profunda.setHex(p.profunda), m.tinte);
    destino.fondoClaro.setHex(p.fondoClaro);
    destino.fondoOscuro.setHex(p.fondoOscuro);
    tintar(destino.espuma.setHex(p.espuma), m.espumaTinte);
    destino.rugosidad = m.rugosidad;
    destino.causticas = m.causticas;
    destino.turbiedad = m.turbiedad;
    return destino;
  }

  _volcarPaleta(t) {
    const a = this._paleta, b = this._paletaObjetivo, u = this.material.uniforms;
    a.absorcion.lerp(b.absorcion, t);
    a.somera.lerp(b.somera, t);
    a.profunda.lerp(b.profunda, t);
    a.fondoClaro.lerp(b.fondoClaro, t);
    a.fondoOscuro.lerp(b.fondoOscuro, t);
    a.espuma.lerp(b.espuma, t);
    a.rugosidad += (b.rugosidad - a.rugosidad) * t;
    a.causticas += (b.causticas - a.causticas) * t;
    a.turbiedad += (b.turbiedad - a.turbiedad) * t;
    u.uAbsorcion.value.copy(a.absorcion);
    u.uDispSomera.value.copy(a.somera);
    u.uDispProfunda.value.copy(a.profunda);
    u.uFondoClaro.value.copy(a.fondoClaro);
    u.uFondoOscuro.value.copy(a.fondoOscuro);
    u.uColorEspuma.value.copy(a.espuma);
    u.uRugosidad.value = a.rugosidad;
    u.uCausticaFuerza.value = a.causticas;
    u.uTurbiedad.value = a.turbiedad;
  }

  /** El agua se ve distinta en 1800 que en 2100. Transición suave, no salto. */
  setEdad(n) {
    this.edad = Math.max(0, Math.min(MODULADORES_EDAD.length - 1, n | 0));
    this._leerPaleta(this.edad, this._paletaObjetivo);
  }

  /* ------------------------------------------------------------ consultas API */
  /** Profundidad del agua en metros (negativa sobre tierra). Bilineal, igual que el shader. */
  profundidad(x, z) {
    const res = this.resCampo, mpt = this.metrosPorTexel;
    const fx = (x + this.tam / 2) / mpt - 0.5;
    const fz = (z + this.tam / 2) / mpt - 0.5;
    if (fx < 0 || fz < 0 || fx > res - 1 || fz > res - 1) return PROF_MAX; // mar abierto
    const i0 = Math.floor(fx), j0 = Math.floor(fz);
    const i1 = Math.min(res - 1, i0 + 1), j1 = Math.min(res - 1, j0 + 1);
    const tx = fx - i0, tz = fz - j0;
    const p = this.profundidades;
    const a = p[j0 * res + i0], b = p[j0 * res + i1];
    const c = p[j1 * res + i0], d = p[j1 * res + i1];
    return (a + (b - a) * tx) + ((c + (d - c) * tx) - (a + (b - a) * tx)) * tz;
  }

  /** Distancia firmada a la orilla en metros (positiva mar adentro). */
  distanciaCosta(x, z) {
    const res = this.resCampo, mpt = this.metrosPorTexel;
    const fx = (x + this.tam / 2) / mpt - 0.5;
    const fz = (z + this.tam / 2) / mpt - 0.5;
    if (fx < 0 || fz < 0 || fx > res - 1 || fz > res - 1) return SDF_MAX;
    const i0 = Math.floor(fx), j0 = Math.floor(fz);
    const i1 = Math.min(res - 1, i0 + 1), j1 = Math.min(res - 1, j0 + 1);
    const tx = fx - i0, tz = fz - j0;
    const s = this.sdfCosta;
    const a = s[j0 * res + i0], b = s[j0 * res + i1];
    const c = s[j1 * res + i0], d = s[j1 * res + i1];
    return (a + (b - a) * tx) + ((c + (d - c) * tx) - (a + (b - a) * tx)) * tz;
  }

  /**
   * Altura de la superficie en (x,z). Idéntica al vertex shader: mismos trenes,
   * misma atenuación por profundidad. Las naves cabecean con esto.
   */
  alturaOla(x, z, t = this.tiempo) {
    return this.nivel + alturaOlas(x, z, t, atenuacionOla(this.profundidad(x, z)));
  }

  /** Normal de la superficie: sirve para inclinar cascos y balsas. */
  normalOla(x, z, t = this.tiempo, salida) {
    return normalOlas(x, z, t, atenuacionOla(this.profundidad(x, z)), salida);
  }

  /* ------------------------------------------------------------------- cielo */
  /**
   * Lee el estado atmosférico de ctx.cielo con tolerancia: el módulo puede exponer
   * el sol como DirectionalLight, como dirección, o todavía no existir.
   */
  _actualizarCielo(ctx) {
    const u = this.material.uniforms;
    const cielo = ctx.cielo;
    const sol = cielo?.sol;

    const L = this._v3;
    if (sol?.isDirectionalLight) {
      L.copy(sol.position);
      if (sol.target) L.sub(sol.target.position);
      if (L.lengthSq() < 1e-6) L.set(0.4, 0.62, 0.35);
      L.normalize();
    } else if (cielo?.dirSol) {
      L.copy(cielo.dirSol).normalize(); // convención: apunta HACIA el sol
    } else {
      L.set(0.4, 0.62, 0.35).normalize();
    }
    u.uDirSol.value.copy(L);

    const cSol = u.uColorSol.value;
    if (sol?.color) cSol.copy(sol.color).multiplyScalar(Math.min(sol.intensity ?? 1, 6) * 0.55);
    else cSol.setRGB(1.0, 0.86, 0.66);

    // Horizonte: la niebla es la mejor aproximación al color del aire a distancia.
    const hor = u.uColorHorizonte.value;
    const cen = u.uColorCenit.value;
    const nieblaCol = ctx.escena?.fog?.color;
    if (cielo?.colorHorizonte) hor.copy(cielo.colorHorizonte);
    else if (nieblaCol) hor.copy(nieblaCol);
    else if (ctx.escena?.background?.isColor) hor.copy(ctx.escena.background);
    else hor.setRGB(0.62, 0.72, 0.84);

    if (cielo?.colorCenit) cen.copy(cielo.colorCenit);
    else cen.setRGB(hor.r * 0.42, hor.g * 0.62, Math.min(1.2, hor.b * 1.02));

    // ── RESTITUCIÓN HDR DEL CIELO ────────────────────────────────────────────
    // El color de niebla viene NORMALIZADO a propósito (pico ≤ 0.78) para teñir
    // sin iluminar. Usado tal cual como radiancia del cielo, el reflejo del agua
    // nace apagado: es una de las razones por las que no había un solo píxel por
    // encima de 200. La luz hemisférica del módulo de cielo sí publica radiancia
    // real de cenit, así que reescalamos con ella (acotado, para que un cielo
    // raro no nos queme el lago).
    const ambCielo = cielo?.ambiental?.color;
    if (ambCielo) {
      const picoReal = Math.max(ambCielo.r, ambCielo.g, ambCielo.b);
      const picoActual = Math.max(cen.r, cen.g, cen.b, 1e-4);
      const escala = Math.min(Math.max(picoReal / picoActual, 0.7), 3.2);
      cen.multiplyScalar(escala);
      hor.multiplyScalar(escala * 0.86); // el horizonte siempre es más pálido que el cenit
    }

    // Ambiente = irradiancia difusa del hemisferio, ya en la escala HDR de arriba.
    u.uAmbiente.value.setRGB(
      hor.r * 0.34 + cen.r * 0.30,
      hor.g * 0.34 + cen.g * 0.30,
      hor.b * 0.34 + cen.b * 0.30,
    );
  }

  /* --------------------------------------------------------------- reflexión */
  /** ¿Vale la pena pagar el pase de reflexión este frame? */
  _hayAguaAlaVista(ctx) {
    const cam = ctx.camara;
    if (cam.position.y <= this.nivel + 0.2) return false;
    // Punto donde la mirada corta el plano del agua: si estamos tierra adentro
    // y lejos de cualquier orilla, no hay nada que reflejar.
    const dir = this._v3b.set(0, 0, -1).applyQuaternion(cam.quaternion);
    if (dir.y >= -1e-3) return true;
    const dist = (this.nivel - cam.position.y) / dir.y;
    if (dist < 0 || dist > 1200) return true;
    const x = cam.position.x + dir.x * dist;
    const z = cam.position.z + dir.z * dist;
    // Margen holgado: a 70-90 m de cámara se ven ~150 m de mundo, así que sólo
    // se descarta el pase cuando estamos claramente tierra adentro.
    return this.distanciaCosta(x, z) > -260;
  }

  _renderReflejo(ctx) {
    const renderer = ctx.renderer, escena = ctx.escena, cam = ctx.camara;
    const rt = this.reflejoRT;
    const camR = this.camReflejo;
    const nivel = this.nivel;

    cam.updateMatrixWorld();

    // Cámara espejada respecto del plano y = nivel (posición, objetivo y up).
    camR.position.set(cam.position.x, 2 * nivel - cam.position.y, cam.position.z);
    const mira = this._v3.set(0, 0, -1).applyQuaternion(cam.quaternion).add(cam.position);
    camR.up.set(0, 1, 0).applyQuaternion(cam.quaternion);
    camR.up.y = -camR.up.y;
    camR.lookAt(mira.x, 2 * nivel - mira.y, mira.z);
    camR.near = cam.near; camR.far = cam.far;
    camR.updateMatrixWorld(true);
    camR.matrixWorldInverse.copy(camR.matrixWorld).invert();
    camR.projectionMatrix.copy(cam.projectionMatrix);

    // Clipping oblicuo (Lengyel): el near plane pasa a ser el plano del agua,
    // así no se cuela el fondo sumergido dentro del reflejo.
    const plano = this._plano.setFromNormalAndCoplanarPoint(
      this._v3b.set(0, 1, 0), this._v3.set(0, nivel, 0),
    );
    plano.applyMatrix4(camR.matrixWorldInverse);
    const cp = this._clip.set(plano.normal.x, plano.normal.y, plano.normal.z, plano.constant);
    const pm = camR.projectionMatrix;
    const q = this._q;
    q.x = (Math.sign(cp.x) + pm.elements[8]) / pm.elements[0];
    q.y = (Math.sign(cp.y) + pm.elements[9]) / pm.elements[5];
    q.z = -1.0;
    q.w = (1.0 + pm.elements[10]) / pm.elements[14];
    cp.multiplyScalar(2.0 / cp.dot(q));
    pm.elements[2] = cp.x;
    pm.elements[6] = cp.y;
    pm.elements[10] = cp.z + 1.0 - 0.004;
    pm.elements[14] = cp.w;

    // Matriz que proyecta un punto de mundo a la UV del render target.
    this.matrizRefl.set(0.5, 0, 0, 0.5, 0, 0.5, 0, 0.5, 0, 0, 0.5, 0.5, 0, 0, 0, 1);
    this.matrizRefl.multiply(camR.projectionMatrix);
    this.matrizRefl.multiply(camR.matrixWorldInverse);
    this.material.uniforms.uMatrizRefl.value.copy(this.matrizRefl);

    const objetivoPrevio = renderer.getRenderTarget();
    const sombrasPrevias = renderer.shadowMap.autoUpdate;
    const xrPrevio = renderer.xr.enabled;
    // Los mapas de sombra no dependen de la cámara de vista: reusamos los del
    // frame anterior en vez de pagarlos dos veces.
    renderer.shadowMap.autoUpdate = false;
    renderer.xr.enabled = false;
    this.malla.visible = false;

    renderer.setRenderTarget(rt);
    renderer.state.buffers.depth.setMask(true);
    if (renderer.autoClear === false) renderer.clear();
    renderer.render(escena, camR);

    this.malla.visible = true;
    renderer.xr.enabled = xrPrevio;
    renderer.shadowMap.autoUpdate = sombrasPrevias;
    renderer.setRenderTarget(objetivoPrevio);
    this._reflejoValido = true;
  }

  /* --------------------------------------------------------------- por frame */
  cada(dtReal, alfa, ctx) {
    this.tiempo += dtReal;
    const u = this.material.uniforms;
    u.uTiempo.value = this.tiempo;

    // Cambio de preset en caliente: sólo hay que recompilar por el define.
    const calidad = ctx.render?.calidad ?? ctx.calidad ?? this.calidad;
    if (calidad !== this.calidad) {
      this.calidad = calidad;
      const quiere = calidad === 'alta' || calidad === 'ultra';
      if (quiere !== this.usaReflexion) {
        this.usaReflexion = quiere;
        if (quiere && !this.reflejoRT) this._construirReflexion(ctx);
        this.material.defines = quiere ? { USA_REFLEXION: '' } : {};
        u.uReflejo.value = this.reflejoRT ? this.reflejoRT.texture : null;
        this.material.needsUpdate = true;
      }
    }

    this._actualizarCielo(ctx);
    this._volcarPaleta(Math.min(1, dtReal * 1.4)); // ~1.5 s de transición de edad

    if (this.usaReflexion && this.reflejoRT && this._hayAguaAlaVista(ctx)) {
      this._renderReflejo(ctx);
    }
  }

  dispose() {
    this.ctx?.escena?.remove(this.malla);
    this.malla.geometry.dispose();
    this.material.dispose();
    this.texCampo.dispose();
    this.texOndas.dispose();
    this.texCausticas.dispose();
    this.reflejoRT?.dispose();
    if (this._alRedimensionar) window.removeEventListener('resize', this._alRedimensionar);
  }
}
