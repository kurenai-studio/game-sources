/**
 * EdificioFabrica — mallas procedurales de TODOS los edificios, por edad.
 *
 * La arquitectura es lo que hace sentir el paso de 1800 a 2100: el mismo
 * cuartel es galpón de ladrillo con techo de teja en la Edad del Vapor, nave de
 * acero remachado con diente de sierra en la Eléctrica, bunker de hormigón
 * visto en la Atómica, caja de muro cortina en la de la Información y volumen
 * continuo con biofachada en la Sintética.
 *
 * ESTRATEGIA
 *  - Cada edificio se arma con los generadores puros de `EdificioPartes.js` y
 *    se acumula en BOLSAS por ranura de material.
 *  - Al final cada bolsa se fusiona en UNA BufferGeometry con UV de caja en
 *    escala de mundo: 3 a 5 draw calls por edificio, no doscientos.
 *  - El plan compilado se cachea por (clave, edad): veinte viviendas comparten
 *    la misma geometría y los mismos materiales; sólo se crean `Mesh` nuevas.
 *  - El color de jugador vive en su propia ranura (techos, banderas, franja del
 *    zócalo, marcos de puerta) con material aparte y nombre `jugador_*`, que es
 *    lo que `VistaEntidades` busca para teñir.
 */
import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';
import { RNG, clamp, lerp } from '../core/RNG.js';
import { defEdificio } from '../data/edificios.js';
import * as P from './EdificioPartes.js';

const {
  pieza, conjunto, colocar, uvCaja, caja, cajaEn, cajaBiselada, extruirPerfil,
  cilindro, disco, esfera, media, toro, roca, revolucion, tuboPor, placa,
  muroConVentanas, muroCiego, techoDosAguas, techoPlanoConPretil, techoDienteSierra,
  techoBoveda, cupula, chimenea, torre, silo, escalera, baranda, viga, cercha,
  columna, panelSolar, antena, parabolica, bandera, cable, farol, barril, cajon,
  pilaTroncos, pilaSacos, pilaMineral, cartel, textoBarras, andamio, cimientos,
  ruina, llama, panoOndulado, fusionar,
} = P;

const TAU = Math.PI * 2;
const CELDA = 2;  // metros por celda de rejilla

/* ═══════════════════════════════════════════════════════════════════════════
   1. Los cinco vocabularios
   ═══════════════════════════════════════════════════════════════════════════ */

/**
 * NOTA DE COLOR (vale para toda la tabla)
 *
 * 1. `ganancia` es un multiplicador POR CANAL en espacio LINEAL, y hace dos
 *    trabajos a la vez. Sube el albedo: el ladrillo procedural es oscuro de
 *    fábrica (sus rojos rondan #8e3a29, 0.05 de luminancia lineal) y encima le
 *    aplicábamos un tinte 0xc79a86, así que el muro terminaba por debajo del
 *    pasto y lo único que se leía del edificio era el trim de color. Y lo
 *    desatura: no alcanza con desaturar el tinte porque el rojo vive en la
 *    TEXTURA, así que la ganancia sube más el verde y el azul que el rojo.
 *    Esa es la RESERVA DE GAMA: material neutro afuera, saturación adentro del
 *    color de bando, que es lo único que puede tener rojo o azul plenos.
 * 2. Nada de esto "quema": todo esto ocurre antes del OutputPass, que es quien
 *    hace el tone mapping ACES. Un albedo 1.3 acá es una alta luz, no un clip.
 * 3. `techo` es una ranura nueva que NO tiene material propio: viaja fusionada
 *    en la bolsa del muro con su tinte de compensación, así que el techo puede
 *    dejar de ser color de jugador sin costar un draw call más.
 * 4. El color de bando usa siempre `metal_pintado` porque su mapa es gris
 *    neutro (#c8ccd0 con juntas y remaches): multiplicado por el hex del
 *    jugador devuelve ese hex limpio. Con `teja` o `chapa_ondulada` debajo, un
 *    azul de bando salía verdoso y dejaba de ser escaneable.
 */
export const ESTILOS_EDAD = [
  {
    id: 0, clave: 'vapor', nombre: 'Edad del Vapor',
    tex: { muro: 'ladrillo', piedra: 'roca', detalle: 'madera_vieja', jugador: 'metal_pintado', techo: 'teja', vidrio: 'vidrio' },
    tinte: { muro: 0xffffff, piedra: 0xffffff, detalle: 0xffffff, jugador: 0xffffff, techo: 0xffffff, vidrio: 0xcfdde6 },
    uv: { muro: 1.9, piedra: 2.3, detalle: 1.7, jugador: 1.6, techo: 1.9, vidrio: 1.6, emisivo: 1 },
    // ladrillo cocido, cálido pero ya lavado; madera gris de intemperie
    ganancia: { muro: [1.42, 1.80, 2.05], piedra: [1.45, 1.45, 1.50], detalle: [1.70, 1.95, 2.35], jugador: [1.20, 1.20, 1.20] },
    techo: 'dosaguas', pendiente: 0.66, alturaPiso: 3.5, espesor: 0.4,
    lampara: 0xffc878, vidrioEmis: 0xffb35a, emisFuerza: 0.35,
    // piedra y techo viajan en la bolsa del muro con su tinte: dos draw calls menos
    fusion: { piedra: 'muro', techo: 'muro' },
    tinteFusion: { piedra: 0xc6d2e0, techo: 0x9a8f8a },
  },
  {
    id: 1, clave: 'electrica', nombre: 'Edad Eléctrica',
    tex: { muro: 'ladrillo', piedra: 'hormigon', detalle: 'metal_oxidado', jugador: 'metal_pintado', techo: 'chapa_ondulada', vidrio: 'vidrio' },
    tinte: { muro: 0xffffff, piedra: 0xffffff, detalle: 0xffffff, jugador: 0xffffff, techo: 0xffffff, vidrio: 0xd2e0e6 },
    uv: { muro: 2.1, piedra: 2.4, detalle: 1.8, jugador: 2.0, techo: 2.1, vidrio: 1.9, emisivo: 1 },
    // el mismo ladrillo pero más frío y hollinado; el óxido va bien neutralizado
    ganancia: { muro: [1.30, 1.82, 2.30], piedra: [1.35, 1.35, 1.40], detalle: [1.45, 1.80, 2.30], jugador: [1.20, 1.20, 1.20] },
    techo: 'dosaguas', pendiente: 0.44, alturaPiso: 3.9, espesor: 0.38,
    lampara: 0xffd89a, vidrioEmis: 0xffcf80, emisFuerza: 0.4,
    fusion: { piedra: 'muro', techo: 'muro' },
    tinteFusion: { piedra: 0xd2dae2, techo: 0x8e9298 },
  },
  {
    id: 2, clave: 'atomica', nombre: 'Edad Atómica',
    tex: { muro: 'hormigon', piedra: 'hormigon', detalle: 'metal_pintado', jugador: 'metal_pintado', techo: 'hormigon', vidrio: 'vidrio' },
    tinte: { muro: 0xffffff, piedra: 0xffffff, detalle: 0xdfe6d2, jugador: 0xffffff, techo: 0xffffff, vidrio: 0xd8e6e2 },
    uv: { muro: 2.6, piedra: 2.6, detalle: 2.0, jugador: 2.0, techo: 2.6, vidrio: 2.2, emisivo: 1 },
    // hormigón visto: ya es neutro, sólo hay que levantarlo para que sea el
    // valor claro del cuadro y no un gris de sombra
    ganancia: { muro: [1.30, 1.30, 1.34], piedra: [1.26, 1.26, 1.30], detalle: [1.15, 1.18, 1.15], jugador: [1.20, 1.20, 1.20] },
    techo: 'plano', pendiente: 0.3, alturaPiso: 3.4, espesor: 0.46,
    lampara: 0xfff0c0, vidrioEmis: 0xd9e04f, emisFuerza: 0.42,
    fusion: { piedra: 'muro', techo: 'muro' },
    tinteFusion: { piedra: 0xeaeaea, techo: 0xb8b6ae },
  },
  {
    id: 3, clave: 'informacion', nombre: 'Edad de la Información',
    tex: { muro: 'panel_compuesto', piedra: 'hormigon', detalle: 'metal_pintado', jugador: 'metal_pintado', techo: 'panel_compuesto', vidrio: 'vidrio' },
    tinte: { muro: 0xffffff, piedra: 0xffffff, detalle: 0xffffff, jugador: 0xffffff, techo: 0xffffff, vidrio: 0x9fc4dc },
    uv: { muro: 2.2, piedra: 2.6, detalle: 2.0, jugador: 2.0, techo: 2.2, vidrio: 2.6, emisivo: 1 },
    ganancia: { muro: [1.24, 1.26, 1.30], piedra: [1.24, 1.24, 1.28], detalle: [1.18, 1.18, 1.20], jugador: [1.18, 1.18, 1.18] },
    techo: 'plano', pendiente: 0.22, alturaPiso: 3.3, espesor: 0.28,
    lampara: 0xdff4ff, vidrioEmis: 0x66e6ff, emisFuerza: 0.55,
    fusion: { piedra: 'muro', techo: 'muro' },
    tinteFusion: { piedra: 0xe6ecee, techo: 0xc4c8cc },
  },
  {
    id: 4, clave: 'sintetica', nombre: 'Edad Sintética',
    tex: { muro: 'marmol', piedra: 'marmol', detalle: 'metal_pintado', jugador: 'metal_pintado', techo: 'marmol', vidrio: 'vidrio' },
    tinte: { muro: 0xffffff, piedra: 0xffffff, detalle: 0xffffff, jugador: 0xffffff, techo: 0xffffff, vidrio: 0xc0b4e0 },
    uv: { muro: 3.2, piedra: 3.2, detalle: 2.4, jugador: 2.6, techo: 3.2, vidrio: 3.0, emisivo: 1 },
    ganancia: { muro: [1.10, 1.10, 1.12], piedra: [1.10, 1.10, 1.12], detalle: [1.14, 1.14, 1.16], jugador: [1.16, 1.16, 1.16] },
    techo: 'organico', pendiente: 0.18, alturaPiso: 3.2, espesor: 0.24,
    lampara: 0xe8dcff, vidrioEmis: 0xb48bff, emisFuerza: 0.7,
    fusion: { piedra: 'muro', techo: 'muro' },
    tinteFusion: { piedra: 0xf0eef4, techo: 0xdcd8e4 },
  },
];

/**
 * REALCE DE MAMPOSTERÍA — el edificio tiene que ser más claro que el suelo.
 *
 * Medido sobre las capturas del panel: los muros caían en luma 123-135 y el
 * pasto al sol del primer plano en 113. Doce niveles de diferencia entre el
 * fondo y el protagonista, cuando la referencia tiene sesenta. Ése es el
 * "todo el cuadro en una sola banda" que el panel repitió cuatro rondas
 * seguidas, y no se puede cerrar bajando más el suelo: bajarlo tira la media
 * del cuadro fuera de banda. Hay que SUBIR la piedra.
 *
 * Va como factor aparte y no editando las cinco paletas a mano porque el
 * balance de canal de cada edad (el ladrillo cálido del Vapor, el hormigón
 * frío de la Atómica) está afinado y no se toca: acá sólo se escala.
 */
const REALCE_MAMPOSTERIA = 1.34;
for (const e of ESTILOS_EDAD) {
  for (const k of ['muro', 'piedra']) {
    if (e.ganancia?.[k]) e.ganancia[k] = e.ganancia[k].map((v) => v * REALCE_MAMPOSTERIA);
  }
}

const estiloDe = (edad) => ESTILOS_EDAD[clamp(edad | 0, 0, 4)];

/* ═══════════════════════════════════════════════════════════════════════════
   2. Materiales (cacheados a nivel módulo: los comparten todos los edificios)
   ═══════════════════════════════════════════════════════════════════════════ */

const cacheMateriales = new Map();

/**
 * Aplica la ganancia por canal (ver la nota de color de ESTILOS_EDAD).
 * El color del material multiplica al mapa de albedo, así que subir este color
 * por encima de 1 es subir el albedo del material, y subirlo desparejo entre
 * canales es desaturar la textura sin tener que regenerarla.
 */
function subirAlbedo(color, ganancia) {
  if (!ganancia) return color;
  color.r *= ganancia[0];
  color.g *= ganancia[1];
  color.b *= ganancia[2];
  return color;
}

/**
 * Convierte el hex crudo del jugador en la PINTURA con la que se pinta un muro.
 *
 * POR QUÉ EXISTE ESTA FUNCIÓN. El panel escribió "mismo RGB en cara iluminada y
 * en sombra… un jurado lo leyó como material sin asignar". No había material sin
 * asignar: había un color imposible de sombrear. Un hex de bando puro (0x0000ff,
 * 0xff0000) tiene DOS CANALES EN CERO, y un canal en cero no sube con el sol ni
 * baja con la sombra — cero por la luz que sea sigue siendo cero. El único canal
 * vivo, encima, arrancaba con albedo 1.2 por la ganancia de la tabla y saturaba
 * contra el tone mapping ACES en cuanto le pegaba el sol. O sea: la cara al sol y
 * la cara en sombra devolvían casi el mismo píxel. Eso es exactamente lo que se
 * ve cuando una malla no está sombreada, y por eso lo leyeron así.
 *
 * La pintura real no es un primario de monitor: es pigmento MÁS blanco de titanio
 * sobre una imprimación. Reproducimos eso en tres pasos:
 *  1. BLANCO: mezclamos hacia la luminancia del propio color, así los tres
 *     canales quedan con recorrido y el sombreado se ve en los tres.
 *  2. TECHO: ningún canal pasa de 0.80 lineal, para que el sol tenga aire por
 *     arriba en vez de clipear.
 *  3. PISO: ningún canal baja de 0.045, para que la sombra tenga tono y no
 *     colapse a negro plano.
 * El resultado sigue siendo escaneable de un vistazo (es la misma familia de
 * color) pero ahora es una superficie que recibe luz como cualquier otra.
 */
function pinturaDeBando(hex, ganancia, conMapa) {
  const c = new THREE.Color(hex);   // Color.set ya lo pasa de sRGB a lineal
  const luma = c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722;
  const BLANCO = 0.30, TECHO = 0.80, PISO_ABS = 0.05, PISO_REL = 0.11;
  c.r = lerp(c.r, luma, BLANCO);
  c.g = lerp(c.g, luma, BLANCO);
  c.b = lerp(c.b, luma, BLANCO);
  // la ganancia sólo compensa un mapa de albedo oscuro: sin mapa, quemaría
  if (conMapa) subirAlbedo(c, ganancia);
  let pico = Math.max(c.r, c.g, c.b);
  if (pico > TECHO) { c.multiplyScalar(TECHO / pico); pico = TECHO; }
  // el piso es absoluto Y relativo al canal fuerte: da igual lo saturado que sea
  // el color del bando, ningún canal queda a más de nueve a uno del que manda, y
  // por lo tanto los tres se mueven cuando se mueve la luz
  const piso = Math.max(PISO_ABS, pico * PISO_REL);
  c.r = Math.max(c.r, piso);
  c.g = Math.max(c.g, piso);
  c.b = Math.max(c.b, piso);
  return c;
}

function materialRanura(ctx, est, ranura, hexJugador = 0xffffff) {
  const clave = ranura === 'jugador' ? `jug|${est.id}|${hexJugador}` : `${ranura}|${est.id}`;
  const hit = cacheMateriales.get(clave);
  if (hit) return hit;

  let m;
  if (ranura === 'emisivo') {
    m = new THREE.MeshBasicMaterial({ vertexColors: true, toneMapped: false });
    m.name = 'edif_emisivo';
  } else {
    let base = null;
    try { base = ctx?.texturas?.material?.(est.tex[ranura] || 'hormigon'); } catch (e) { base = null; }
    m = base && base.isMeshStandardMaterial ? base.clone() : new THREE.MeshStandardMaterial();
    m.vertexColors = true;
    if (ranura === 'jugador') {
      m.color = pinturaDeBando(hexJugador, est.ganancia && est.ganancia.jugador, !!m.map);
    } else {
      m.color = new THREE.Color(est.tinte[ranura] || 0xffffff);
      // la ganancia existe para compensar un mapa de albedo oscuro: si por lo que
      // sea no hay mapa, aplicarla dejaría el muro blanco quemado
      if (ranura !== 'vidrio' && m.map) subirAlbedo(m.color, est.ganancia && est.ganancia[ranura]);
    }
    if (ranura === 'vidrio') {
      m.transparent = true; m.opacity = 0.66; m.depthWrite = true;
      m.roughness = 0.09; m.metalness = 0.55;
      m.emissive = new THREE.Color(est.vidrioEmis);
      m.emissiveIntensity = est.emisFuerza;
      m.name = 'edif_vidrio';
    } else if (ranura === 'detalle') {
      m.roughness = est.id >= 2 ? 0.55 : 0.78; m.metalness = est.id >= 1 ? 0.55 : 0.08;
      m.name = 'edif_detalle';
    } else if (ranura === 'jugador') {
      // El bando es UNA SUPERFICIE MÁS del edificio y tiene que sombrear como
      // tal. Lo dejamos explícito porque el material sale clonado del de la
      // época y bastaba con que esa textura trajera mapa de emisión para que la
      // pintura se iluminara sola y quedara igual al sol que en sombra: el bug
      // que el panel leyó como material sin asignar. Nada de emisivo, nada de
      // transparencia, nada de sombreado plano, nada de saltarse el tone mapping.
      m.roughness = 0.62; m.metalness = est.id >= 2 ? 0.22 : 0.04;
      m.emissive = new THREE.Color(0x000000);
      m.emissiveIntensity = 0;
      m.emissiveMap = null;
      m.toneMapped = true;
      m.flatShading = false;
      m.transparent = false; m.opacity = 1; m.depthWrite = true;
      m.side = THREE.FrontSide;
      m.name = 'jugador_edificio';
      m.userData = Object.assign({}, m.userData, { colorJugador: true });
    } else {
      m.roughness = 0.92; m.metalness = 0.02;
      m.name = `edif_${ranura}`;
    }
    m.needsUpdate = true;
  }
  cacheMateriales.set(clave, m);
  return m;
}

/* ═══════════════════════════════════════════════════════════════════════════
   3. La obra: bolsas por ranura, transformadas y tinte por vértice
   ═══════════════════════════════════════════════════════════════════════════ */

const COL = new THREE.Color();
const MAT_AUX = new THREE.Matrix4();
const EUL_AUX = new THREE.Euler();
const QUAT_AUX = new THREE.Quaternion();
const V_AUX = new THREE.Vector3();
const V_ESC = new THREE.Vector3();

function matrizDe(tr) {
  EUL_AUX.set(tr.rx || 0, tr.ry || 0, tr.rz || 0);
  QUAT_AUX.setFromEuler(EUL_AUX);
  V_AUX.set(tr.x || 0, tr.y || 0, tr.z || 0);
  const s = tr.s != null ? tr.s : 1;
  V_ESC.set(tr.sx != null ? tr.sx : s, tr.sy != null ? tr.sy : s, tr.sz != null ? tr.sz : s);
  return MAT_AUX.compose(V_AUX, QUAT_AUX, V_ESC).clone();
}

function mezclarTinte(a, b) {
  if (a === 0xffffff) return b;
  if (b === 0xffffff) return a;
  const r = (((a >> 16) & 255) * ((b >> 16) & 255)) / 255;
  const g = (((a >> 8) & 255) * ((b >> 8) & 255)) / 255;
  const bl = ((a & 255) * (b & 255)) / 255;
  return (Math.round(r) << 16) | (Math.round(g) << 8) | Math.round(bl);
}

/**
 * Devuelve el tinte por vértice a la proporción con la que fue escrito.
 *
 * Todos los tintes de este archivo (0x9a9a9a para una jamba hundida, 0x686058
 * para un forjado) fueron elegidos "a ojo de pantalla", o sea como fracciones
 * LDR: 0x9a9a9a quería decir "el 60% del muro". Pero `Color.set(hex)` los pasa
 * a lineal y 0x9a9a9a se convierte en 0.32, la mitad de lo que el autor quiso.
 * Encadenados con el mapa de albedo y con el tinte del material, ese factor de
 * más era buena parte de por qué el edificio salía casi negro. Deshacemos la
 * conversión sobre el TINTE (no sobre la textura, que sí es sRGB de verdad).
 */
function tinteLdrALineal(c) {
  c.r = Math.pow(c.r, 1 / 2.2);
  c.g = Math.pow(c.g, 1 / 2.2);
  c.b = Math.pow(c.b, 1 / 2.2);
  return c;
}

/** Normaliza atributos y clava el tinte como color por vértice. */
function prepararGeo(g, hex, ranura) {
  const x = g.index ? g.toNonIndexed() : g;
  if (!x.attributes.normal) x.computeVertexNormals();
  const n = x.attributes.position.count;
  if (!x.attributes.uv) x.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(n * 2), 2));
  for (const k of Object.keys(x.attributes)) {
    if (k !== 'position' && k !== 'normal' && k !== 'uv') x.deleteAttribute(k);
  }
  COL.set(hex);
  // el emisivo pinta fuego y neones: ahí el hex sí es el color final que quiero
  if (ranura !== 'emisivo') tinteLdrALineal(COL);
  const c = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { c[i * 3] = COL.r; c[i * 3 + 1] = COL.g; c[i * 3 + 2] = COL.b; }
  x.setAttribute('color', new THREE.BufferAttribute(c, 3));
  x.morphAttributes = {};
  x.clearGroups();
  return x;
}

class Obra {
  constructor(est, rng) {
    this.est = est;
    this.rng = rng;
    this.bolsas = { cuerpo: new Map(), cim: new Map(), d1: new Map(), d2: new Map(), fuego: new Map() };
    this.activa = this.bolsas.cuerpo;
    this.puntos = { puerta: null, chimeneas: [], banderas: [], luces: [], canon: null };
    // desvío activo del color de bando (ver conBando)
    this.desvio = null;
    // La regla de las tres escalas dice UNA zona grande por edificio, no una por
    // volumen. El ministerio apila cuatro cuerpos, la ciudadela tres, el
    // rascacielos cuatro: con el friso saliendo en cada llamada a `cuerpo()` el
    // mismo edificio terminaba con cuatro cinturones del mismo color, uno arriba
    // del otro. Esta bandera hace que el friso se cobre una sola vez, en el
    // primer volumen que se levanta y en el que lo corona. Dos cinturones (el
    // del basamento y el del remate) son cornisa; cuatro son un edificio
    // pintado de arriba abajo.
    this.frisos = 0;
  }

  /**
   * Ejecuta `fn` desviando a otra ranura todo lo que las piezas de biblioteca
   * marcan como color de jugador.
   *
   * REGLA DE REPARTO: el bando tiene que ocupar entre el 12% y el 25% del área
   * visible, repartido en tres escalas (zona grande, media y chica). Piezas como
   * `techoDosAguas` o `techoDienteSierra` mandan el TECHO ENTERO a la ranura de
   * jugador, y con eso solo ya se comían más de la mitad de la fachada: el
   * edificio dejaba de tener material y quedaba una caja azul de plástico.
   * Acá el techo vuelve al material del período y el bando se lo devolvemos a
   * mano, y sólo al faldón, al marco de la puerta, al estandarte y al zócalo.
   */
  conBando(ranuraDestino, tinte, fn) {
    const antes = this.desvio;
    this.desvio = ranuraDestino ? { ranura: ranuraDestino, tinte: tinte || 0xffffff } : null;
    try { fn(); } finally { this.desvio = antes; }
    return this;
  }

  usar(nombre) { this.activa = this.bolsas[nombre] || this.bolsas.cuerpo; return this; }

  _push(geo, ranura, tinte, M) {
    if (!geo || !geo.attributes || !geo.attributes.position) return;
    let g = geo;
    if (M) { g = geo.clone(); g.applyMatrix4(M); }
    const lista = this.activa.get(ranura) || [];
    lista.push(prepararGeo(g, tinte, ranura));
    this.activa.set(ranura, lista);
  }

  /**
   * Agrega geometría o un grupo de piezas.
   * @param {THREE.BufferGeometry|THREE.Object3D} cosa
   * @param {string|null} ranura   null = respetar la del propio pieza
   * @param {number} tinte         multiplica al tinte de cada pieza
   * @param {object|null} tr       { x,y,z,rx,ry,rz,s,sx,sy,sz }
   */
  add(cosa, ranura = null, tinte = 0xffffff, tr = null) {
    if (!cosa) return this;
    const M = tr ? matrizDe(tr) : null;
    if (cosa.isBufferGeometry) {
      const [r, t] = this._resolver(ranura || 'muro', tinte);
      this._push(cosa, r, t, M || null);
      return this;
    }
    if (cosa.isObject3D) {
      cosa.updateMatrixWorld(true);
      cosa.traverse((n) => {
        if (!n.isMesh || !n.geometry) return;
        const g = n.geometry.clone();
        g.applyMatrix4(n.matrixWorld);
        if (M) g.applyMatrix4(M);
        const [r, t] = this._resolver(ranura || n.userData.ranura || 'muro',
          mezclarTinte(tinte, n.userData.tinte || 0xffffff));
        this._push(g, r, t, null);
      });
    }
    return this;
  }

  /** Algunas ranuras viajan fusionadas en otra bolsa con un tinte de compensación. */
  _resolver(ranura, tinte) {
    let r = ranura, t = tinte;
    // primero el desvío del bando, después la fusión: un techo desviado sigue
    // teniendo que viajar en la bolsa que le toque a su ranura de destino
    if (r === 'jugador' && this.desvio) {
      t = mezclarTinte(t, this.desvio.tinte);
      r = this.desvio.ranura;
    }
    const f = this.est.fusion && this.est.fusion[r];
    if (!f) return [r, t];
    return [f, mezclarTinte(t, (this.est.tinteFusion && this.est.tinteFusion[r]) || 0xffffff)];
  }

  /** Igual que add pero espejado en X (fachadas simétricas en dos renglones). */
  par(cosa, ranura, tinte, tr, ejeX) {
    this.add(cosa, ranura, tinte, Object.assign({}, tr, { x: ejeX }));
    this.add(cosa, ranura, tinte, Object.assign({}, tr, { x: -ejeX, ry: -(tr && tr.ry ? tr.ry : 0) }));
    return this;
  }

  chimeneaEn(x, y, z) { this.puntos.chimeneas.push(new THREE.Vector3(x, y, z)); return this; }
  banderaEn(x, y, z) { this.puntos.banderas.push(new THREE.Vector3(x, y, z)); return this; }
  luzEn(x, y, z) { this.puntos.luces.push(new THREE.Vector3(x, y, z)); return this; }

  compilar() {
    const salida = {};
    for (const nombre of Object.keys(this.bolsas)) {
      const partes = [];
      for (const [ranura, geos] of this.bolsas[nombre]) {
        if (!geos.length) continue;
        let g;
        try { g = geos.length === 1 ? geos[0] : mergeGeometries(geos, false); } catch (e) { g = geos[0]; }
        if (!g) continue;
        uvCaja(g, this.est.uv[ranura] || 2);
        g.computeBoundingBox(); g.computeBoundingSphere();
        partes.push({ ranura, geo: g });
      }
      salida[nombre] = partes;
    }
    return salida;
  }
}

export default { crearMallaEdificio, crearAndamio, ESTILOS_EDAD };

/* ═══════════════════════════════════════════════════════════════════════════
   4. Bloques compuestos compartidos por todos los edificios
   ═══════════════════════════════════════════════════════════════════════════ */

/** Zócalo, cuatro fachadas con huecos hundidos y forjado de cierre arriba. */
function cuerpo(o, A, L, h, est, opts = {}) {
  const e = opts.espesor != null ? opts.espesor : est.espesor;
  const y = opts.y || 0;
  const cx = opts.x || 0, cz = opts.z || 0;
  const filas = opts.filas != null ? opts.filas : (h > 5.6 ? 2 : 1);
  const cf = opts.colsFrente != null ? opts.colsFrente : Math.max(2, Math.round(A / 2.1));
  const cl = opts.colsLado != null ? opts.colsLado : Math.max(2, Math.round(L / 2.1));
  const cfg = { zocalo: opts.zocalo, cornisa: opts.cornisa, pilastras: opts.pilastras };
  const t = opts.tinte || 0xffffff;
  o.add(muroConVentanas(A, h, e, filas, cf, est.id, cfg), null, t, { y, x: cx, z: cz + L / 2 - e / 2 });
  o.add(muroConVentanas(A, h, e, filas, cf, est.id, cfg), null, t, { y, x: cx, z: cz - (L / 2 - e / 2), ry: Math.PI });
  o.add(muroConVentanas(L, h, e, filas, cl, est.id, cfg), null, t, { y, x: cx + A / 2 - e / 2, z: cz, ry: Math.PI / 2 });
  o.add(muroConVentanas(L, h, e, filas, cl, est.id, cfg), null, t, { y, x: cx - (A / 2 - e / 2), z: cz, ry: -Math.PI / 2 });
  // FRISO: la banda de bando de escala grande. Corre por las cuatro caras justo
  // debajo de la cornisa, o sea en el borde superior de la silueta, que es
  // donde el ojo busca a quién pertenece el edificio. Van cuatro chapas finas y
  // no un prisma: un prisma agregaría una tapa horizontal que nadie ve.
  if (opts.friso !== false && o.frisos < 2) {
    o.frisos++;
    const hCor = opts.cornisa === false ? 0 : Math.min(0.34, h * 0.09);
    const yf = y + h - hCor - 0.24;
    const hf = Math.min(0.46, h * 0.13);
    for (const s of [-1, 1]) {
      o.add(cajaEn(A + 0.14, hf, 0.07, cx, yf, cz + s * (L / 2 + 0.04)), 'jugador', 0xffffff);
      o.add(cajaEn(0.07, hf, L + 0.14, cx + s * (A / 2 + 0.04), yf, cz), 'jugador', 0xffffff);
    }
  }
  // forjado: tapa la caja para que no se vea el interior desde la cámara alta
  o.add(cajaEn(A - e, 0.26, L - e, cx, y + h - 0.13, cz), 'muro', 0x8b8278);
  o.add(cajaEn(A - e, 0.2, L - e, cx, y + 0.1, cz), 'piedra', 0xa8a49c);
  // el volumen de planta baja de la Edad Atómica nunca puede quedar en prisma
  if (est.id === 2 && opts.brutalismo !== false && A >= 4.2 && y < 0.01) {
    vocabularioAtomico(o, A, L, h, o.rng, { x: cx, z: cz });
  }
  return y + h;
}

/**
 * Vocabulario brutalista de la Edad Atómica.
 *
 * POR QUÉ: la captura de esta edad se leía como cajas. Un prisma de hormigón
 * liso no tiene con qué atrapar la luz rasante, así que todo el volumen queda
 * en un solo valor plano y la única información del cuadro pasa a ser el trim
 * de color. Acá le metemos las cinco cosas que el hormigón visto sí tiene:
 * juntas de encofrado, parasoles, alero con ménsulas, núcleo de escalera que
 * pasa el techo y un anexo bajo. Todo cae en las bolsas que ya existen (muro,
 * detalle, jugador, vidrio), así que no agrega ni una llamada de dibujo.
 */
function vocabularioAtomico(o, A, L, h, rng, opts = {}) {
  const cx = opts.x || 0, cz = opts.z || 0;

  // 1. ENCOFRADO: cada tongada de hormigón deja una junta horizontal. Un solo
  //    prisma perimetral por junta (el interior lo tapa el forjado): 2 cajas.
  for (let yj = 1.15; yj < h - 0.45; yj += 1.15) {
    o.add(cajaEn(A + 0.13, 0.08, L + 0.13, cx, yj, cz), 'muro', 0xa8a49a);       // sombra de la junta
    o.add(cajaEn(A + 0.16, 0.05, L + 0.16, cx, yj + 0.1, cz), 'muro', 0xfaf8f2); // labio que agarra el sol
  }

  // 2. PARASOLES: aletas verticales de hormigón. Son la textura de sombra que
  //    convierte un paño plano en un paño con ritmo.
  const hP = Math.min(h * 0.5, 2.3);
  const yP = h - 0.75 - hP / 2;
  const nL = Math.max(3, Math.round(L / 1.35));
  for (let i = 0; i < nL; i++) {
    const z = cz - L / 2 + (L * (i + 0.5)) / nL;
    for (const s of [-1, 1]) {
      o.add(cajaBiselada(0.42, hP, 0.14, 0.02), 'muro', 0xf6f3ec, { x: cx + s * (A / 2 + 0.19), y: yP, z });
    }
  }
  const nA = Math.max(2, Math.round(A / 1.6));
  for (let i = 0; i < nA; i++) {
    const x = cx - A / 2 + (A * (i + 0.5)) / nA;
    if (Math.abs(x - cx) < 1.75) continue;               // el hueco de la puerta manda
    o.add(cajaBiselada(0.14, hP, 0.42, 0.02), 'muro', 0xf6f3ec, { x, y: yP, z: cz + L / 2 + 0.19 });
  }

  // 3. ALERO con ménsulas: la sombra dura que le da cornisa al volumen
  const yAl = h - 0.42;
  for (const s of [-1, 1]) {
    o.add(cajaBiselada(0.72, 0.17, L + 0.55, 0.03), 'muro', 0xfaf8f2, { x: cx + s * (A / 2 + 0.3), y: yAl, z: cz });
    for (let i = 0; i < 3; i++) {
      o.add(cajaEn(0.6, 0.36, 0.17, cx + s * (A / 2 + 0.26), yAl - 0.26, cz + (i - 1) * (L * 0.32)), 'muro', 0xb4b0a8);
    }
  }

  // 4. NÚCLEO DE ESCALERA: pasa el techo y quiebra la silueta en dos alturas
  const wn = Math.min(2.7, A * 0.32);
  const hn = h + 1.4 + (rng ? rng.float(0, 0.8) : 0.35);
  const nx = cx + A / 2 - wn * 0.45, nz = cz - (L / 2 - wn * 0.45);
  o.add(cajaBiselada(wn, hn, wn, 0.05), 'muro', 0xf0ede5, { x: nx, y: hn / 2, z: nz });
  o.add(cajaEn(0.22, hn * 0.66, 0.09, nx - wn * 0.22, hn * 0.5, nz - (wn / 2 + 0.02)), 'vidrio', 0xffffff);
  o.add(cajaBiselada(wn + 0.34, 0.2, wn + 0.34, 0.03), 'muro', 0xfaf8f2, { x: nx, y: hn + 0.1, z: nz });
  // esta tapa era 'jugador': tres metros por tres de color plano mirando al
  // cielo, o sea a la cámara. El núcleo ya tiene su cornisa; la coronación va
  // con material y el bando de este edificio se cobra en el friso y la puerta.
  o.add(cajaEn(wn + 0.4, 0.14, wn + 0.4, nx, hn + 0.27, nz), 'muro', 0xfaf8f2);
  o.add(antena(1.7, 'latigo'), null, 0xffffff, { x: nx + wn * 0.28, y: hn + 0.34, z: nz });
  // escalera de gato hasta el núcleo: silueta calada contra el cielo
  for (let i = 0; i < 6; i++) {
    o.add(cajaEn(0.44, 0.05, 0.05, nx, h * 0.35 + i * 0.34, nz + wn / 2 + 0.12), 'detalle', 0xd6d2c8);
  }
  for (const s of [-1, 1]) {
    o.add(cajaEn(0.05, hn - h * 0.3, 0.05, nx + s * 0.22, h * 0.35 + (hn - h * 0.3) / 2 - 0.2, nz + wn / 2 + 0.12), 'detalle', 0xd6d2c8);
  }

  // 5. ANEXO BAJO: un segundo cuerpo, más bajo y saliente, para que la planta
  //    deje de ser un rectángulo perfecto
  const ha = Math.max(1.5, h * 0.44);
  const wa = Math.min(3.2, L * 0.46);
  const ax = cx + (A / 2 + 0.24), az = cz - L * 0.08;
  o.add(cajaBiselada(0.95, ha, wa, 0.04), 'muro', 0xece9e1, { x: ax, y: ha / 2, z: az });
  o.add(cajaBiselada(1.16, 0.2, wa + 0.2, 0.03), 'muro', 0xfaf8f2, { x: ax, y: ha + 0.1, z: az });
  o.add(cajaEn(1.22, 0.13, wa + 0.26, ax, ha + 0.26, az), 'muro', 0xfaf8f2);
  o.add(cajaEn(0.07, ha * 0.38, wa * 0.68, ax + 0.46, ha * 0.6, az), 'vidrio', 0xffffff);

  // 6. PINTURA MILITAR descascarada en el zócalo (sin tocar el frente, que es
  //    donde está la puerta) + numeral estarcido
  for (const s of [-1, 1]) {
    o.add(cajaEn(0.1, 0.86, L * 0.92, cx + s * (A / 2 + 0.04), 0.53, cz), 'detalle', 0xe6ead8);
  }
  o.add(cajaEn(A * 0.92, 0.86, 0.1, cx, 0.53, cz - (L / 2 + 0.04)), 'detalle', 0xe6ead8);
  for (let i = 0; i < 4; i++) {
    const t = rng ? rng.float(-0.4, 0.4) : (i - 1.5) * 0.22;
    o.add(cajaEn(0.11, 0.3 + Math.abs(t), L * 0.16, cx - (A / 2 + 0.05), 0.9 + t * 0.3, cz + (i - 1.5) * (L * 0.2)), 'muro', 0xffffff);
  }
  o.add(textoBarras('07', 0.46, 0.05), 'detalle', 0xfcfbf6,
    { x: cx + A / 2 + 0.09, y: 1.62, z: cz + L * 0.26, ry: Math.PI / 2 });
}

/** Techo según la edad. Devuelve la cota superior alcanzada. */
function techoPorEdad(o, A, L, yTop, est, opts = {}) {
  const tipo = opts.tipo || est.techo;
  if (tipo === 'dosaguas') {
    const p = opts.pendiente != null ? opts.pendiente : est.pendiente;
    const alero = opts.alero != null ? opts.alero : 0.45;
    // el tejado entero vuelve al material del período (teja / pizarra)
    o.conBando('techo', 0xffffff, () => {
      o.add(techoDosAguas(A + 0.2, L + 0.1, p, alero, est.id, {
        buhardilla: opts.buhardilla !== false && A > 5,
      }), null, 0xffffff, { y: yTop });
    });
    // …y el bando se queda con la CENEFA DEL ALERO: la franja que corre por el
    // borde bajo del faldón, donde el ojo lee la silueta contra el pasto.
    //
    // Antes esta franja medía medio faldón (`vuelo * 0.5`, hasta metro y medio de
    // ancho por todo el largo del techo). Sumado a la cumbrera y a los dos cantos
    // que ponía `techoDosAguas`, el tejado quedaba pintado de punta a punta: ese
    // es el "faldón entero" del informe. Una cenefa es una cenefa: 20 cm de chapa
    // doblada sobre el borde, no la mitad del agua.
    const vuelo = (A + 0.2) / 2 + alero;
    const gv = (est.id <= 1 ? 0.16 : 0.13) * Math.sqrt(1 + p * p);
    const largoT = L + 0.1 + alero * 2;
    const ang = Math.atan(p);
    const ancho = Math.min(1.15, vuelo * 0.42);
    const dx = (ancho * Math.cos(ang)) / 2;
    for (const s of [-1, 1]) {
      const xc = s * (vuelo - dx);
      o.add(caja(ancho, 0.08, largoT * 0.99), 'jugador', 0xffffff,
        { x: xc, y: yTop + (vuelo - Math.abs(xc)) * p + gv + 0.04, rz: -s * ang });
    }
    return yTop + (A / 2 + alero) * p + 0.3;
  }
  if (tipo === 'sierra') {
    const n = opts.dientes || Math.max(2, Math.round(A / 2.6));
    const anchoT = A + 0.15;
    const w = anchoT / n;
    const ha = opts.alto || Math.min(1.5, w * 0.72);
    // idem: los dientes son el techo entero, no pueden ser todos color de bando
    o.conBando('techo', 0xffffff, () => {
      o.add(techoDienteSierra(anchoT, L + 0.1, n, { alto: opts.alto }), null, 0xffffff, { y: yTop });
    });
    // el bando se lleva la cumbrera de cada diente: rayas paralelas, muy legibles
    for (let i = 0; i < n; i++) {
      o.add(caja(Math.min(0.46, w * 0.3), 0.12, L + 0.14), 'jugador', 0xffffff,
        { x: -anchoT / 2 + (i + 1) * w - 0.16, y: yTop + ha + 0.03 });
    }
    return yTop + Math.min(1.5, (A / n) * 0.72) + 0.2;
  }
  if (tipo === 'boveda') {
    const h = opts.alto || A * 0.42;
    o.conBando('techo', 0xffffff, () => {
      o.add(techoBoveda(A + 0.2, L + 0.2, h), null, 0xffffff, { y: yTop });
    });
    // franja de arranque de la bóveda a cada lado: el bando por el borde
    // el cañón entero volvió al material del período, así que el bando de un
    // hangar tiene que vivir acá: dos cintas de arranque, una por costado, con
    // ancho suficiente para leerse desde la cámara y no medio metro de altura
    // en un galpón de doce metros.
    const wArr = Math.min(0.85, h * 0.42);
    for (const s of [-1, 1]) {
      o.add(cajaEn(0.34, wArr, L + 0.24, s * ((A + 0.2) / 2 - 0.1), yTop + wArr / 2 + 0.04, 0), 'jugador', 0xffffff);
    }
    return yTop + h;
  }
  if (tipo === 'organico') {
    // superficie continua sin juntas: casquete achatado + junta luminosa
    const h = opts.alto || Math.min(1.7, A * 0.2);
    const cap = media(1, 16);
    cap.scale(A * 0.53, h, L * 0.53);
    o.add(cap, 'muro', 0xffffff, { y: yTop - 0.05 });
    o.add(toro(Math.min(A, L) * 0.44, 0.05, 4, 26), 'emisivo', est.id === 4 ? 0xb48bff : 0x66e6ff, { y: yTop + h * 0.36, rx: Math.PI / 2, sx: A / Math.min(A, L) * 1.02, sy: L / Math.min(A, L) * 1.02 });
    o.add(cajaBiselada(A + 0.12, 0.18, L + 0.12, 0.08), 'muro', 0xffffff, { y: yTop - 0.09 });
    // CORONA. Estaba a `yTop + h*0.72` con radio 0.3·lado: a esa altura el propio
    // casquete todavía mide 0.37·lado de radio, así que el disco quedaba ENTERRADO
    // adentro de la cúpula y no se veía un solo píxel de color de bando en toda la
    // edad Sintética. Va donde corona de verdad: el óculo del vértice, más un aro
    // proud sobre el paralelo del casquete (escalado como la elipse del techo).
    o.add(disco(Math.min(A, L) * 0.15, 0.12, 20), 'jugador', 0xffffff, { y: yTop - 0.05 + h - 0.04 });
    o.add(toro(Math.min(A, L) * 0.545, 0.085, 5, 26), 'jugador', 0xffffff, {
      y: yTop + h * 0.3, rx: Math.PI / 2,
      sx: (A / Math.min(A, L)) * 1.02, sy: (L / Math.min(A, L)) * 1.02,
    });
    return yTop + h;
  }
  const hp = opts.pretil || (est.id >= 3 ? 0.5 : 0.75);
  o.add(techoPlanoConPretil(A + 0.1, L + 0.1, hp, { espesor: 0.28 }), null, 0xffffff, { y: yTop });
  // ACÁ HABÍA DOS FRANJAS PINTADAS SOBRE LA LOSA. La idea era buena (la cámara
  // del RTS mira desde arriba y en techo plano la cubierta es la fachada que más
  // se ve) pero la ejecución no: eran dos rectángulos de un solo RGB, del ancho
  // entero del edificio, apoyados sobre una losa que ya lleva su albardilla de
  // bando en los cuatro lados del pretil. Tres capas del mismo color sobre la
  // misma superficie. Queda la albardilla, que además dibuja el contorno.
  // Queda UNA franja pintada, del ancho de un pasillo de servicio y corrida por
  // el fondo de la losa, que es la escala grande de las edades de techo plano.
  const wFr = Math.min(L * 0.22, 1.15);
  o.add(cajaEn(A - 0.7, 0.05, wFr, 0, yTop + 0.315, L * 0.5 - wFr * 0.75), 'jugador', 0xffffff);
  // A cambio la losa se gana el equipo que toda azotea tiene y ésta no tenía:
  // machones de ventilación, que son los que le dan sombra propia al plano.
  const nv = Math.max(2, Math.round(Math.min(A, L) / 2.2));
  for (let i = 0; i < nv; i++) {
    const x = -A * 0.3 + (i * (A * 0.6)) / Math.max(1, nv - 1);
    o.add(cajaBiselada(0.5, 0.42, 0.5, 0.04), 'muro', 0xf0ede6, { x, y: yTop + 0.49, z: -L * 0.22 });
    o.add(cajaEn(0.58, 0.07, 0.58, x, yTop + 0.72, -L * 0.22), 'detalle', 0xd8d8d8);
  }
  return yTop + hp + 0.3;
}

/** Puerta principal: hueco hundido, marco de color de jugador, gradas y faroles. */
function puertaEdad(o, A, L, est, opts = {}) {
  const w = opts.ancho || Math.min(2.3, A * 0.3);
  const h = opts.alto || Math.min(3.0, est.alturaPiso * 0.82);
  const z = L / 2;
  const y = opts.y || 0;
  o.add(cajaEn(w + 0.5, h + 0.45, 0.35, 0, y + (h + 0.45) / 2, z - 0.1), 'muro', 0x9a9a9a);
  o.add(cajaEn(w, h, 0.3, 0, y + h / 2, z - 0.22), 'detalle', 0x574a3c);
  // marco: la pieza de color de jugador que más se lee de frente
  // las jambas eran de ancho FIJO: en una puerta de casa de 1,05 m el marco se
  // comía media fachada. Van proporcionales al hueco, como cualquier carpintería.
  const jm = Math.max(0.15, Math.min(0.26, w * 0.13));
  o.add(cajaEn(jm, h + 0.5, 0.42, -(w / 2 + jm / 2), y + (h + 0.5) / 2, z + 0.02), 'jugador', 0xffffff);
  o.add(cajaEn(jm, h + 0.5, 0.42, w / 2 + jm / 2, y + (h + 0.5) / 2, z + 0.02), 'jugador', 0xffffff);
  o.add(cajaEn(w + jm * 2 + 0.2, jm * 1.15, 0.5, 0, y + h + jm * 0.6 + 0.14, z + 0.04), 'jugador', 0xffffff);
  if (est.id <= 1) {
    // dintel de arco rebajado con clave
    o.add(extruirPerfil([[-w / 2 - 0.2, 0], [w / 2 + 0.2, 0], [w / 2 + 0.12, 0.26], [0, 0.4], [-w / 2 - 0.12, 0.26]], 0.5, 0.02), 'piedra', 0xffffff, { y: y + h + 0.56, z: z + 0.04 });
    o.add(cajaBiselada(0.26, 0.36, 0.5, 0.02), 'piedra', 0xf6f6f6, { y: y + h + 0.72, z: z + 0.06 });
  } else if (est.id === 2) {
    o.add(cajaBiselada(w + 1.5, 0.28, 1.5, 0.04), 'muro', 0xf0f0f0, { y: y + h + 0.75, z: z + 0.6 });
    for (const s of [-1, 1]) o.add(cilindro(0.09, 0.09, h + 0.6, 8), 'detalle', 0xdcdcdc, { x: s * (w / 2 + 0.5), y: y + (h + 0.6) / 2, z: z + 1.25 });
  } else {
    o.add(cajaEn(w + 0.8, 0.06, 0.09, 0, y + h + 0.62, z + 0.16), 'emisivo', est.id === 4 ? 0xd8c8ff : 0x8fe8ff);
    o.add(cajaBiselada(w + 1.8, 0.16, 1.7, 0.05), 'muro', 0xffffff, { y: y + h + 0.8, z: z + 0.75 });
  }
  // gradas
  o.add(escalera(w + 0.9, 0.34, 2, { huella: 0.34 }), null, 0xffffff, { y, z: z + 0.72, ry: Math.PI });
  o.puntos.puerta = new THREE.Vector3(0, y, z + 1.2);
  // faroles a los lados
  const est_f = est.id;
  for (const s of [-1, 1]) {
    o.add(farol(est_f <= 1 ? 2.3 : 2.6, est_f), null, 0xffffff, { x: s * (w / 2 + 1.0), z: z + 0.55 });
    o.luzEn(s * (w / 2 + 1.0), 2.5, z + 0.75);
  }
  return h;
}

/** Remate: lo que corona el edificio y le da silueta contra el cielo. */
function remateEdad(o, A, L, yTop, est, rng, opts = {}) {
  const id = est.id;
  if (id === 0) {
    const n = opts.chimeneas || 2;
    for (let i = 0; i < n; i++) {
      const x = (i - (n - 1) / 2) * A * 0.42;
      const z = rng.float(-L * 0.2, L * 0.2);
      const h = rng.float(1.5, 2.3);
      o.add(chimenea(h, 0.55, 0), null, 0xffffff, { x, y: yTop - 0.5, z });
      o.chimeneaEn(x, yTop - 0.5 + h, z);
    }
    o.add(cilindro(0.03, 0.03, 1.5, 5), 'detalle', 0xe0e0e0, { x: -A * 0.3, y: yTop + 0.6, z: L * 0.28 });
  } else if (id === 1) {
    const h = opts.chimeneaAlta || 3.2;
    o.add(chimenea(h, 0.6, 1), null, 0xffffff, { x: A * 0.3, y: yTop - 0.4, z: -L * 0.26 });
    o.chimeneaEn(A * 0.3, yTop - 0.4 + h, -L * 0.26);
    o.add(cajaBiselada(1.4, 0.7, 1.0, 0.05), 'detalle', 0xe4e4e4, { x: -A * 0.24, y: yTop + 0.35, z: L * 0.2 });
    o.add(cable([-A * 0.24, yTop + 0.7, L * 0.2], [A * 0.5 + 1.6, yTop + 0.2, L * 0.5 + 1.6], 0.45), 'detalle', 0xbdbdbd);
    o.add(antena(1.6, 'latigo'), null, 0xffffff, { x: -A * 0.34, y: yTop + 0.4, z: -L * 0.3 });
  } else if (id === 2) {
    o.add(cajaBiselada(1.9, 0.85, 1.5, 0.05), 'muro', 0xeeeeee, { x: -A * 0.22, y: yTop + 0.42, z: -L * 0.2 });
    for (let i = 0; i < 3; i++) o.add(cilindro(0.26, 0.26, 0.5, 10), 'detalle', 0xd6d6d6, { x: -A * 0.22 - 0.55 + i * 0.55, y: yTop + 1.1, z: -L * 0.2 });
    o.add(parabolica(0.95), null, 0xffffff, { x: A * 0.28, y: yTop + 0.3, z: L * 0.22, ry: -0.5 });
    o.add(antena(2.6, 'mastil'), null, 0xffffff, { x: A * 0.32, y: yTop + 0.3, z: -L * 0.3 });
    o.chimeneaEn(-A * 0.22, yTop + 1.6, -L * 0.2);
  } else if (id === 3) {
    o.add(panelSolar(2.4, 1.5, 0.55), null, 0xffffff, { x: -A * 0.2, y: yTop + 0.2, z: -L * 0.18 });
    o.add(panelSolar(2.4, 1.5, 0.55), null, 0xffffff, { x: A * 0.2, y: yTop + 0.2, z: -L * 0.18 });
    o.add(cajaBiselada(1.5, 0.8, 1.2, 0.05), 'detalle', 0xe8e8e8, { x: A * 0.24, y: yTop + 0.6, z: L * 0.22 });
    o.add(toro(0.42, 0.06, 4, 12), 'detalle', 0xd0d0d0, { x: A * 0.24, y: yTop + 1.04, z: L * 0.22, rx: Math.PI / 2 });
    o.add(antena(2.2, 'sensor'), null, 0xffffff, { x: -A * 0.34, y: yTop + 0.2, z: L * 0.3 });
    o.chimeneaEn(A * 0.24, yTop + 1.2, L * 0.22);
  } else {
    o.add(toro(Math.min(A, L) * 0.3, 0.11, 5, 22), 'muro', 0xffffff, { y: yTop + 1.15, rx: Math.PI / 2 });
    o.add(toro(Math.min(A, L) * 0.3, 0.045, 4, 22), 'emisivo', 0xb48bff, { y: yTop + 1.15, rx: Math.PI / 2 });
    for (const s of [-1, 1]) o.add(cilindro(0.07, 0.1, 1.1, 8), 'detalle', 0xe0e0e0, { x: s * Math.min(A, L) * 0.3, y: yTop + 0.55 });
    o.add(antena(1.8, 'sensor'), null, 0xffffff, { x: -A * 0.3, y: yTop + 0.1, z: -L * 0.3 });
    o.chimeneaEn(0, yTop + 1.3, 0);
  }
}

/** Banderas / estandartes en el frente. */
function banderasEdad(o, A, L, yTop, est, n = 2, opts = {}) {
  const h = opts.alto || Math.min(4.2, yTop * 0.55 + 1.6);
  const yb = opts.y != null ? opts.y : yTop;
  for (let i = 0; i < n; i++) {
    const x = n === 1 ? 0 : (i - (n - 1) / 2) * (A * 0.82);
    o.add(bandera(h, { fase: i * 1.7, ancho: h * 0.44, altoPano: h * 0.3 }), null, 0xffffff, { x, y: yb, z: opts.z != null ? opts.z : L * 0.34 });
    o.banderaEn(x, yb + h, opts.z != null ? opts.z : L * 0.34);
  }
}

/** Utilería alrededor del edificio: densidad, que es la mitad del "se ve caro". */
function entornoEdad(o, A, L, est, rng, opts = {}) {
  const id = est.id;
  const borde = (fx, fz) => ({ x: fx * (A / 2 + rng.float(0.35, 0.9)), z: fz * (L / 2 + rng.float(0.3, 0.85)) });
  if (id === 0) {
    let p = borde(-1, 0.5);
    o.add(barril(0.28, 0.7), 'detalle', 0xd0b48a, { x: p.x, z: p.z, ry: rng.float(0, TAU) });
    o.add(barril(0.26, 0.66), 'detalle', 0xc8a87e, { x: p.x + 0.6, z: p.z + 0.25, ry: rng.float(0, TAU) });
    p = borde(1, -0.4);
    o.add(cajon(0.72, 0.56, 0.66), 'detalle', 0xd9c096, { x: p.x, z: p.z, ry: rng.float(-0.5, 0.5) });
    o.add(cajon(0.56, 0.44, 0.52), 'detalle', 0xcbb185, { x: p.x + 0.2, y: 0.56, z: p.z + 0.1, ry: rng.float(-0.6, 0.6) });
    o.add(pilaTroncos(4, rng, { radio: 0.14, largo: 1.3 }), 'detalle', 0xa98156, { x: -A * 0.1, z: -(L / 2 + 0.7), ry: rng.float(-0.3, 0.3) });
  } else if (id === 1) {
    let p = borde(1, 0.5);
    for (let i = 0; i < 3; i++) o.add(cilindro(0.27, 0.27, 0.82, 10), 'detalle', i % 2 ? 0xc9b06a : 0xb8695a, { x: p.x + i * 0.6, y: 0.41, z: p.z });
    o.add(cajaBiselada(1.6, 0.3, 1.1, 0.03), 'detalle', 0xc9a678, { x: -A * 0.5 - 0.7, y: 0.15, z: L * 0.2 });
    o.add(cartel(1.5, 0.7, opts.cartel || '', 1), null, 0xffffff, { x: 0, y: 2.2, z: L / 2 + 0.14 });
    // caño de servicio corrido por la fachada
    o.add(cilindro(0.09, 0.09, L * 0.8, 8).rotateX(Math.PI / 2), 'detalle', 0xbdbdbd, { x: A / 2 + 0.2, y: 1.4 });
  } else if (id === 2) {
    const p = borde(-1, -0.4);
    for (let i = 0; i < 3; i++) o.add(cilindro(0.3, 0.3, 0.9, 10), 'detalle', 0x8f9a6a, { x: p.x, y: 0.45, z: p.z + i * 0.7 });
    // sacos terreros
    for (let i = 0; i < 6; i++) {
      const g = esfera(0.26, 6); g.scale(1.3, 0.62, 0.9);
      o.add(g, 'detalle', 0xa39a78, { x: A * 0.2 + (i % 3) * 0.6, y: 0.17 + Math.floor(i / 3) * 0.3, z: L / 2 + 0.55, ry: rng.float(-0.2, 0.2) });
    }
    o.add(escalera(1.0, 2.2, 8), null, 0xffffff, { x: -A / 2 - 0.55, z: -L * 0.1, ry: Math.PI / 2 });
    o.add(baranda(2.4, 0.95), 'detalle', 0xd8d8d8, { x: -A / 2 - 1.05, y: 2.2, z: -L * 0.1, ry: Math.PI / 2 });
  } else if (id === 3) {
    for (const s of [-1, 1]) {
      o.add(cajaBiselada(0.9, 0.5, 0.9, 0.06), 'muro', 0xdfe4e8, { x: s * (A / 2 + 0.8), y: 0.25, z: L * 0.3 });
      o.add(esfera(0.42, 8), 'detalle', 0x6a8a55, { x: s * (A / 2 + 0.8), y: 0.62, z: L * 0.3, sy: 0.7 });
    }
    for (let i = 0; i < 4; i++) {
      o.add(cilindro(0.07, 0.09, 0.7, 8), 'detalle', 0xd8d8d8, { x: -A * 0.4 + i * (A * 0.27), y: 0.35, z: L / 2 + 1.1 });
      o.add(esfera(0.08, 6), 'emisivo', 0x8fe8ff, { x: -A * 0.4 + i * (A * 0.27), y: 0.72, z: L / 2 + 1.1 });
    }
  } else {
    for (const s of [-1, 1]) {
      o.add(cilindro(0.5, 0.62, 0.34, 14), 'muro', 0xffffff, { x: s * (A / 2 + 0.9), y: 0.17, z: L * 0.24 });
      const mata = esfera(0.5, 8); mata.scale(1, 0.75, 1);
      o.add(mata, 'detalle', 0x5f8f52, { x: s * (A / 2 + 0.9), y: 0.5, z: L * 0.24 });
      o.add(toro(0.55, 0.03, 4, 16), 'emisivo', 0xb48bff, { x: s * (A / 2 + 0.9), y: 0.36, z: L * 0.24, rx: Math.PI / 2 });
    }
    o.add(cajaEn(A * 0.9, 0.04, 0.12, 0, 0.03, L / 2 + 0.9), 'emisivo', 0xb48bff);
  }
}

/** Cimientos + andamio: lo que se ve mientras la obra está en curso. */
function obraEnCurso(o, A, L, alto, est, rng) {
  o.usar('cim');
  o.add(cimientos(A, L, est.id, rng));
  o.usar('cuerpo');
}

/** Grietas, cascotes y llamas. */
function danios(o, A, L, alto, est, rng) {
  o.usar('d1');
  o.add(ruina(A, L, alto, 1, rng, est.id));
  o.usar('d2');
  o.add(ruina(A, L, alto, 2, rng, est.id));
  o.usar('fuego');
  const focos = o.puntos.chimeneas.length ? o.puntos.chimeneas : [new THREE.Vector3(0, alto * 0.9, 0)];
  for (let i = 0; i < Math.min(3, focos.length + 1); i++) {
    const f = focos[i % focos.length];
    o.add(llama(1.35, 0.62, i * 2.1), 'emisivo', i % 2 ? 0xff8a2a : 0xffc23c, {
      x: f.x + rng.float(-0.3, 0.3), y: Math.min(f.y, alto) - 0.2, z: f.z + rng.float(-0.3, 0.3),
    });
  }
  o.add(llama(1.1, 0.5, 1.1), 'emisivo', 0xff7a22, { x: rng.float(-A * 0.3, A * 0.3), y: alto * 0.55, z: L / 2 - 0.2 });
  o.usar('cuerpo');
}

/* ═══════════════════════════════════════════════════════════════════════════
   5. Los edificios — uno por clave de src/data/edificios.js
   ═══════════════════════════════════════════════════════════════════════════ */

const PLANOS = {};

/* ---------------------------------------------------------------- SEDE 5×5 */
PLANOS.sede = (o, est, rng) => {
  const A = 9.6, L = 9.6, id = est.id;
  const h1 = id <= 1 ? 4.3 : 4.6;
  obraEnCurso(o, A, L, 10, est, rng);
  cuerpo(o, A, L, h1, est, { filas: 1, colsFrente: 4, colsLado: 4 });
  // cuerpo alto retranqueado
  const A2 = A * 0.6, L2 = L * 0.6, h2 = id <= 1 ? 3.2 : 3.8;
  o.add(cajaBiselada(A2 + 0.7, 0.36, L2 + 0.7, 0.06), 'piedra', 0xf2f2f2, { y: h1 + 0.18 });
  cuerpo(o, A2, L2, h2, est, { filas: 1, colsFrente: 3, colsLado: 3, y: h1 + 0.36, zocalo: false });
  let top = techoPorEdad(o, A2, L2, h1 + 0.36 + h2, est, { pendiente: 0.7, buhardilla: false });
  // pórtico de acceso: columnas, entablamento y frontón
  const wp = A * 0.46;
  if (id <= 2) {
    for (let i = 0; i < 4; i++) {
      const x = (i - 1.5) * (wp / 3);
      o.add(columna(0.26, h1 - 0.6, id), 'piedra', 0xffffff, { x, y: 0.34, z: L / 2 + 1.15 });
    }
    o.add(cajaBiselada(wp + 1.0, 0.42, 1.9, 0.05), 'piedra', 0xf6f6f6, { y: h1 - 0.05, z: L / 2 + 1.05 });
    // el tímpano es piedra tallada y el bando se queda con la faja del
    // entablamento: una línea sobre el borde del pórtico. Antes eran las dos
    // cosas, y la segunda era una losa de 5 × 2 m vista desde arriba.
    o.add(extruirPerfil([[-(wp + 1.0) / 2, 0], [0, 0.95], [(wp + 1.0) / 2, 0]], 1.7, 0.03), 'piedra', 0xf4f4f4, { y: h1 + 0.16, z: L / 2 + 1.05 });
    o.add(cajaEn(wp + 1.2, 0.19, 0.22, 0, h1 + 0.13, L / 2 + 1.95), 'jugador', 0xffffff);
  } else {
    o.add(cajaBiselada(wp + 1.6, 0.28, 2.6, 0.07), 'muro', 0xffffff, { y: h1 - 0.1, z: L / 2 + 1.2 });
    for (const s of [-1, 1]) o.add(cilindro(0.11, 0.14, h1 - 0.1, 10), 'detalle', 0xe4e4e4, { x: s * wp * 0.52, y: (h1 - 0.1) / 2, z: L / 2 + 2.2 });
    o.add(cajaEn(wp + 1.7, 0.07, 0.12, 0, h1 - 0.28, L / 2 + 2.45), 'emisivo', id === 4 ? 0xd8c8ff : 0x8fe8ff);
  }
  puertaEdad(o, A, L, est, { ancho: 2.4, alto: 3.1 });
  // torre de esquina: reloj, tanque, radar o anillo según edad
  const tx = -A / 2 + 1.3, tz = -L / 2 + 1.3;
  const ht = id <= 1 ? 7.4 : 8.2;
  o.add(torre(1.25, ht, id), null, 0xffffff, { x: tx, z: tz });
  top = Math.max(top, ht + 2.4);
  if (id === 0) {
    o.add(disco(0.62, 0.16, 16), 'piedra', 0xf6f6f6, { x: tx, y: ht * 0.72, z: tz + 1.2, rx: Math.PI / 2 });
    o.add(disco(0.5, 0.2, 16), 'jugador', 0xffffff, { x: tx, y: ht * 0.72, z: tz + 1.22, rx: Math.PI / 2 });
    o.add(cajaEn(0.06, 0.36, 0.06, tx, ht * 0.72 + 0.16, tz + 1.32), 'detalle', 0x3a332c);
    o.add(cajaEn(0.24, 0.06, 0.06, tx + 0.1, ht * 0.72, tz + 1.32), 'detalle', 0x3a332c);
  } else if (id === 1) {
    o.add(cartel(2.0, 0.85, 'SEDE', 1), null, 0xffffff, { x: 0, y: h1 + 0.9, z: L2 / 2 + 0.2 });
  } else if (id >= 3) {
    o.add(cilindro(1.9, 1.9, 0.14, 20), 'muro', 0xe8e8e8, { x: A * 0.22, y: top + 0.07, z: L * 0.2 });
    o.add(toro(1.55, 0.05, 4, 22), 'emisivo', id === 4 ? 0xd8c8ff : 0x8fe8ff, { x: A * 0.22, y: top + 0.16, z: L * 0.2, rx: Math.PI / 2 });
  }
  remateEdad(o, A2, L2, h1 + 0.36 + h2, est, rng, { chimeneas: 2 });
  banderasEdad(o, A, L, h1 + 0.36, est, 2, { alto: 4.4, z: L * 0.42 });
  entornoEdad(o, A, L, est, rng, { cartel: 'SEDE' });
  danios(o, A, L, top, est, rng);
  return top;
};

/* ------------------------------------------------------------ VIVIENDA 2×2 */
PLANOS.vivienda = (o, est, rng) => {
  const A = 3.6, L = 3.6, id = est.id;
  const h = id <= 1 ? 2.9 : id === 4 ? 3.0 : 3.1;
  obraEnCurso(o, A, L, h + 1.6, est, rng);
  cuerpo(o, A, L, h, est, { filas: 1, colsFrente: 2, colsLado: 2, espesor: 0.3, pilastras: false });
  let top = techoPorEdad(o, A, L, h, est, { pendiente: id === 0 ? 0.78 : 0.6, buhardilla: false, alero: 0.4, pretil: 0.42 });
  puertaEdad(o, A, L, est, { ancho: 1.05, alto: 2.05 });
  if (id === 0) {
    const hc = 1.5;
    o.add(chimenea(hc, 0.42, 0), null, 0xffffff, { x: A * 0.28, y: h + 0.9, z: -L * 0.2 });
    o.chimeneaEn(A * 0.28, h + 0.9 + hc, -L * 0.2);
    // cerco de madera y ropa tendida
    for (let i = 0; i < 5; i++) o.add(cajaEn(0.1, 0.8, 0.08, -A / 2 + i * (A / 4), 0.4, L / 2 + 1.1), 'detalle', 0xb58d5c);
    o.add(cajaEn(A + 0.1, 0.08, 0.06, 0, 0.62, L / 2 + 1.1), 'detalle', 0xa87f50);
    o.add(cable([-A / 2 - 0.1, h + 0.2, -L / 2 - 0.2], [A / 2 + 0.9, h - 0.5, -L / 2 - 0.9], 0.3), 'detalle', 0xd8d8d8);
    o.add(barril(0.24, 0.6), 'detalle', 0xc9a678, { x: -A / 2 - 0.5, z: L * 0.2 });
  } else if (id === 1) {
    const hc = 1.7;
    o.add(chimenea(hc, 0.4, 1), null, 0xffffff, { x: -A * 0.3, y: h + 0.5, z: L * 0.1 });
    o.chimeneaEn(-A * 0.3, h + 0.5 + hc, L * 0.1);
    o.add(cable([A / 2, h + 0.4, 0], [A / 2 + 2.4, h + 1.0, 1.2], 0.35), 'detalle', 0x9a9a9a);
    o.add(cajon(0.5, 0.4, 0.46), 'detalle', 0xc3a172, { x: A / 2 + 0.5, z: -L * 0.3 });
  } else if (id === 2) {
    o.add(cajaBiselada(1.1, 0.5, 0.9, 0.05), 'muro', 0xe8e8e8, { x: A * 0.2, y: top + 0.2, z: 0 });
    o.add(antena(1.5, 'latigo'), null, 0xffffff, { x: -A * 0.3, y: top, z: -L * 0.25 });
    o.add(cilindro(0.34, 0.34, 0.9, 10), 'detalle', 0xc9cbb8, { x: A / 2 + 0.55, y: 0.45, z: L * 0.25 });
    o.chimeneaEn(A * 0.2, top + 0.7, 0);
  } else if (id === 3) {
    o.add(panelSolar(2.2, 1.3, 0.5), null, 0xffffff, { y: top + 0.05, z: -L * 0.1 });
    o.add(parabolica(0.42), null, 0xffffff, { x: A * 0.36, y: top + 0.05, z: L * 0.3, ry: 0.5 });
    o.chimeneaEn(0, top + 0.6, 0);
  } else {
    o.add(toro(1.15, 0.07, 4, 20), 'muro', 0xffffff, { y: top + 0.55, rx: Math.PI / 2 });
    o.add(toro(1.15, 0.03, 4, 20), 'emisivo', 0xb48bff, { y: top + 0.62, rx: Math.PI / 2 });
    const mata = esfera(0.55, 8); mata.scale(1.5, 0.5, 1.5);
    o.add(mata, 'detalle', 0x5f8f52, { x: -A * 0.2, y: top + 0.05, z: L * 0.2 });
    o.chimeneaEn(0, top + 0.5, 0);
  }
  banderasEdad(o, A, L, h, est, 1, { alto: 2.6, z: L * 0.4 });
  danios(o, A, L, top, est, rng);
  return top;
};

/* -------------------------------------------------------------- GRANJA 3×3 */
PLANOS.granja = (o, est, rng) => {
  const A = 5.7, L = 5.7, id = est.id;
  o.usar('cim');
  o.add(cajaEn(A + 0.4, 0.16, L + 0.4, 0, 0.08, 0), 'piedra', 0xbfa07a);
  o.usar('cuerpo');
  // parcela labrada
  o.add(cajaBiselada(A, 0.22, L, 0.05), 'piedra', 0xa8825c, { y: 0.11 });
  const surcos = [];
  const nf = 7;
  for (let i = 0; i < nf; i++) {
    const z = -L / 2 + (L * (i + 0.5)) / nf;
    surcos.push(caja(A - 0.5, 0.14, 0.28).translate(0, 0.29, z));
  }
  o.add(fusionar(surcos), 'piedra', 0x8f6a48);
  // cultivo
  const plantas = [];
  const filas = id >= 3 ? 5 : 6, porFila = id >= 3 ? 7 : 9;
  for (let f = 0; f < filas; f++) {
    for (let i = 0; i < porFila; i++) {
      const x = -A / 2 + 0.5 + (i * (A - 1.0)) / (porFila - 1) + rng.float(-0.08, 0.08);
      const z = -L / 2 + 0.55 + (f * (L - 1.1)) / (filas - 1) + rng.float(-0.06, 0.06);
      const alt = rng.float(0.35, 0.62);
      const g = cilindro(0.16, 0.02, alt, 5);
      g.rotateY(rng.float(0, TAU));
      g.translate(x, 0.36 + alt / 2, z);
      plantas.push(g);
    }
  }
  o.add(fusionar(plantas), 'detalle', id >= 3 ? 0x86c25a : 0xa8b34a);
  // cerco perimetral
  const cerco = [];
  const np = 7;
  for (let i = 0; i <= np; i++) {
    const t = -A / 2 + (A * i) / np;
    for (const s of [-1, 1]) {
      cerco.push(caja(0.09, 0.86, 0.09).translate(t, 0.43, s * (L / 2 + 0.2)));
      cerco.push(caja(0.09, 0.86, 0.09).translate(s * (A / 2 + 0.2), 0.43, t));
    }
  }
  for (const s of [-1, 1]) {
    cerco.push(caja(A + 0.5, 0.07, 0.06).translate(0, 0.42, s * (L / 2 + 0.2)));
    cerco.push(caja(0.06, 0.07, L + 0.5).translate(s * (A / 2 + 0.2), 0.42, 0));
  }
  o.add(fusionar(cerco), 'detalle', id <= 1 ? 0xbb9463 : 0xcfcfcf);
  // El LISTÓN SUPERIOR del cerco es la zona grande de bando de la granja.
  //
  // POR QUÉ ACÁ: la granja no tiene cuerpo ni techo, así que se quedaba con un
  // banderín y nada más — medía 0,4% de color de bando y desde arriba no había
  // forma de saber de quién era la parcela. El listón de arriba corre por los
  // cuatro lados a la altura justa para verse contra la tierra labrada, es una
  // línea y no una mancha, y es lo único de la granja que un jugador mira.
  const liston = [];
  for (const s of [-1, 1]) {
    liston.push(caja(A + 0.62, 0.13, 0.15).translate(0, 0.76, s * (L / 2 + 0.2)));
    liston.push(caja(0.15, 0.13, L + 0.62).translate(s * (A / 2 + 0.2), 0.76, 0));
  }
  o.add(fusionar(liston), 'jugador', 0xffffff);
  // caseta / equipamiento por edad
  if (id === 0) {
    o.add(muroCiego(1.5, 1.4, 0.24, 0, 0xffffff), null, 0xffffff, { x: -A / 2 + 0.8, z: -L / 2 + 0.8 });
    o.add(techoDosAguas(1.7, 1.6, 0.7, 0.2, 0, { buhardilla: false }), null, 0xffffff, { x: -A / 2 + 0.8, y: 1.4, z: -L / 2 + 0.8 });
    o.add(pilaSacos(4, rng), 'detalle', 0xc6b487, { x: A / 2 - 0.8, z: -L / 2 + 0.7 });
    // espantapájaros
    o.add(cilindro(0.05, 0.05, 1.5, 5), 'detalle', 0xb08c5e, { x: 0, y: 0.75, z: 0 });
    o.add(cilindro(0.04, 0.04, 0.9, 5).rotateZ(Math.PI / 2), 'detalle', 0xb08c5e, { y: 1.2 });
    o.add(esfera(0.16, 7), 'detalle', 0xd8c08a, { y: 1.6 });
    o.add(cilindro(0.02, 0.26, 0.22, 7), 'jugador', 0xffffff, { y: 1.76 });
  } else if (id === 1) {
    o.add(silo(0.62, 2.8), null, 0xffffff, { x: -A / 2 + 0.9, z: -L / 2 + 0.9 });
    o.add(cajon(0.6, 0.5, 0.55), 'detalle', 0xc3a172, { x: A / 2 - 0.7, z: -L / 2 + 0.7 });
    o.add(cartel(1.2, 0.55, '', 1), null, 0xffffff, { x: A * 0.25, y: 1.0, z: L / 2 + 0.25 });
  } else if (id === 2) {
    // pivote de riego
    o.add(cilindro(0.24, 0.3, 1.5, 10), 'detalle', 0xd8d8d8, { y: 0.75 });
    o.add(cilindro(0.07, 0.07, A * 0.92, 8).rotateZ(Math.PI / 2), 'detalle', 0xdcdcdc, { y: 1.5, x: A * 0.2 });
    for (let i = 0; i < 4; i++) o.add(cilindro(0.05, 0.05, 0.7, 6), 'detalle', 0xd0d0d0, { x: -0.4 + i * 0.9, y: 1.15 });
    for (const s of [-1, 1]) o.add(cilindro(0.22, 0.22, 0.16, 10).rotateZ(Math.PI / 2), 'detalle', 0x3c3c3c, { x: A * 0.62, y: 0.22, z: s * 0.28 });
    o.add(cilindro(0.4, 0.4, 1.0, 10), 'muro', 0xc9cbb8, { x: -A / 2 + 0.7, y: 0.5, z: -L / 2 + 0.7 });
  } else if (id === 3) {
    // invernadero: arcos de vidrio sobre la parcela
    for (let i = 0; i < 4; i++) {
      const z = -L / 2 + 0.9 + i * ((L - 1.8) / 3);
      const arco = [];
      for (let k = 0; k <= 10; k++) { const a = Math.PI * (k / 10); arco.push([-Math.cos(a) * (A * 0.44), Math.sin(a) * 1.5 + 0.4, 0]); }
      o.add(tuboPor(arco, 0.05, 4), 'detalle', 0xdedede, { z });
    }
    o.add(cajaEn(A * 0.9, 1.6, 0.05, 0, 1.2, -L / 2 + 0.9), 'vidrio', 0xd8ecff);
    o.add(cajaEn(A * 0.9, 1.6, 0.05, 0, 1.2, L / 2 - 0.9), 'vidrio', 0xd8ecff);
    o.add(panelSolar(1.6, 1.0, 0.5), null, 0xffffff, { x: -A / 2 + 0.9, z: -L / 2 + 0.7 });
    o.add(cajaBiselada(0.8, 0.9, 0.7, 0.05), 'muro', 0xdfe4e8, { x: A / 2 - 0.7, y: 0.45, z: -L / 2 + 0.7 });
  } else {
    // bandejas hidropónicas apiladas con luz de crecimiento
    for (let n = 0; n < 3; n++) {
      const y = 0.55 + n * 0.62;
      o.add(cajaBiselada(A * 0.92, 0.1, 0.9, 0.03), 'muro', 0xffffff, { y, z: -L * 0.28 + n * 0.02 });
      o.add(cajaEn(A * 0.88, 0.05, 0.7, 0, y + 0.28, -L * 0.28), 'emisivo', 0xd06aff);
      o.add(cajaBiselada(A * 0.92, 0.1, 0.9, 0.03), 'muro', 0xffffff, { y, z: L * 0.28 });
      o.add(cajaEn(A * 0.88, 0.05, 0.7, 0, y + 0.28, L * 0.28), 'emisivo', 0xd06aff);
    }
    for (const s of [-1, 1]) for (const t of [-1, 1]) o.add(cilindro(0.07, 0.09, 2.3, 8), 'detalle', 0xe0e0e0, { x: s * A * 0.44, y: 1.15, z: t * L * 0.28 });
    o.add(cajaBiselada(1.0, 1.1, 0.9, 0.08), 'muro', 0xffffff, { x: 0, y: 0.55, z: 0 });
    o.add(toro(0.5, 0.03, 4, 16), 'emisivo', 0xb48bff, { y: 1.15, rx: Math.PI / 2 });
  }
  banderasEdad(o, A, L, 0, est, 1, { alto: 2.2, z: L / 2 + 0.2 });
  o.puntos.puerta = new THREE.Vector3(0, 0, L / 2 + 0.7);
  danios(o, A, L, 1.6, est, rng);
  return id === 0 ? 2.4 : 3.0;
};

/* -------------------------------------------------------------- MOLINO 3×3 */
PLANOS.molino = (o, est, rng) => {
  const A = 5.6, L = 5.6, id = est.id;
  obraEnCurso(o, A, L, 6, est, rng);
  let top;
  if (id === 0) {
    // molino de torre: base de piedra, cuerpo de tablas y cuatro aspas
    o.add(cilindro(1.75, 2.1, 1.5, 16), 'piedra', 0xffffff, { y: 0.75 });
    o.add(toro(1.78, 0.09, 4, 18), 'piedra', 0xf0f0f0, { y: 1.5, rx: Math.PI / 2 });
    o.add(cilindro(1.25, 1.72, 3.0, 16), 'muro', 0xffffff, { y: 3.0 });
    for (let i = 0; i < 3; i++) o.add(toro(lerp(1.72, 1.25, (i + 1) / 4) + 0.03, 0.05, 4, 18), 'detalle', 0xd8bb90, { y: 1.5 + 0.75 * (i + 1), rx: Math.PI / 2 });
    o.add(cilindro(0.06, 1.3, 1.1, 16), 'jugador', 0xffffff, { y: 5.05 });
    o.add(cajaEn(0.7, 1.1, 0.14, 0, 2.4, 1.62), 'detalle', 0x6a4c30);
    o.add(cajaEn(0.5, 0.6, 0.1, 0, 3.7, 1.5), 'vidrio', 0xdedede);
    // eje y aspas
    o.add(cilindro(0.12, 0.16, 0.8, 8).rotateX(Math.PI / 2), 'detalle', 0xc9a678, { y: 4.5, z: 1.5 });
    for (let a = 0; a < 4; a++) {
      const ang = (a / 4) * TAU;
      const aspa = conjunto(
        pieza(cajaEn(0.16, 3.1, 0.12, 0, 1.75, 0), 'detalle', 0xd8b184),
        // la vela es LONA: cuatro rectángulos de bando de 2,5 m girando en el
        // aire eran las "tablas azules" más literales del informe
        pieza(cajaEn(0.62, 2.5, 0.05, 0.38, 1.85, 0.05), 'detalle', 0xe4dcc6),
      );
      for (let k = 0; k < 5; k++) aspa.add(pieza(cajaEn(0.66, 0.06, 0.09, 0.38, 0.9 + k * 0.55, 0.08), 'detalle', 0xc09060));
      aspa.rotation.z = ang;
      o.add(aspa, null, 0xffffff, { y: 4.5, z: 1.85 });
    }
    o.add(pilaSacos(7, rng), 'detalle', 0xd0bd90, { x: -A / 2 + 0.5, z: L / 2 - 0.5 });
    o.add(cajon(0.7, 0.55, 0.6), 'detalle', 0xc9a678, { x: A / 2 - 0.6, z: L / 2 - 0.6 });
    top = 6.1;
  } else if (id === 1) {
    const h = 3.6;
    cuerpo(o, A * 0.72, L * 0.85, h, est, { filas: 1, colsFrente: 2, colsLado: 3, tinte: 0xffffff });
    top = techoPorEdad(o, A * 0.72, L * 0.85, h, est, { tipo: 'dosaguas', pendiente: 0.42 });
    o.add(silo(1.05, 5.0), null, 0xffffff, { x: A / 2 - 0.95, z: -L / 2 + 1.05 });
    o.add(silo(0.72, 3.8), null, 0xffffff, { x: A / 2 - 0.95, z: L / 2 - 1.3 });
    o.add(cilindro(0.2, 0.2, 3.2, 8).rotateZ(Math.PI / 2), 'detalle', 0xcfcfcf, { x: 0.4, y: 3.9, rz: -0.35 });
    o.add(cartel(2.0, 0.8, 'MOLINO', 1), null, 0xffffff, { y: 2.6, z: L * 0.43 + 0.1 });
    o.add(pilaSacos(6, rng), 'detalle', 0xcfc39a, { x: -A / 2 + 0.6, z: L / 2 - 0.7 });
    top = Math.max(top, 5.4);
  } else if (id === 2) {
    o.add(silo(1.15, 5.4), null, 0xffffff, { x: -1.4, z: -0.9 });
    o.add(silo(1.15, 4.6), null, 0xffffff, { x: 1.4, z: -0.9 });
    o.add(silo(0.85, 3.6), null, 0xffffff, { x: 0, z: 1.5 });
    o.add(cajaBiselada(A * 0.9, 1.6, 1.6, 0.06), 'muro', 0xffffff, { y: 0.8, z: L / 2 - 1.0 });
    // cubierta del anexo con material y sólo la cornisa del frente pintada
    o.add(cajaEn(A * 0.94, 0.2, 1.7, 0, 1.6, L / 2 - 1.0), 'muro', 0xf2f0ea);
    o.add(cajaEn(A * 0.94, 0.17, 0.3, 0, 1.72, L / 2 - 0.2), 'jugador', 0xffffff);
    for (let i = 0; i < 3; i++) o.add(cilindro(0.14, 0.14, 2.6, 8).rotateZ(Math.PI / 2), 'detalle', 0xdcdcdc, { x: 0, y: 3.4 + i * 0.35, z: -0.9, rz: 0 });
    o.add(escalera(0.9, 2.4, 9), null, 0xffffff, { x: -2.6, z: 0.6, ry: Math.PI / 2 });
    o.add(pilaSacos(6, rng), 'detalle', 0xb9b48c, { x: A / 2 - 0.7, z: L / 2 - 0.7 });
    top = 6.0;
  } else if (id === 3) {
    const h = 3.4;
    cuerpo(o, A * 0.85, L * 0.8, h, est, { filas: 1, colsFrente: 3, colsLado: 3 });
    top = techoPorEdad(o, A * 0.85, L * 0.8, h, est, { pretil: 0.45 });
    o.add(silo(0.95, 4.4), null, 0xffffff, { x: A / 2 - 0.85, z: -L / 2 + 1.0 });
    o.add(panelSolar(2.6, 1.5, 0.5), null, 0xffffff, { y: top - 0.15, z: -0.4 });
    o.add(cartel(2.2, 0.7, 'AGRO', 3), null, 0xffffff, { y: h + 0.55, z: L * 0.4 });
    o.add(cajaBiselada(1.2, 1.0, 1.2, 0.06), 'muro', 0xdfe4e8, { x: -A / 2 + 0.8, y: 0.5, z: L / 2 - 0.8 });
    o.add(pilaSacos(5, rng), 'detalle', 0xd8dce0, { x: -A / 2 + 0.7, z: L / 2 - 0.8 });
    top += 0.6;
  } else {
    const h = 3.0;
    cuerpo(o, A * 0.8, L * 0.8, h, est, { filas: 1, colsFrente: 3, colsLado: 3 });
    top = techoPorEdad(o, A * 0.8, L * 0.8, h, est, { tipo: 'organico' });
    for (let i = 0; i < 3; i++) {
      const a = (i / 3) * TAU;
      o.add(cilindro(0.55, 0.62, 3.2, 14), 'muro', 0xffffff, { x: Math.cos(a) * 2.0, y: 1.6, z: Math.sin(a) * 2.0 });
      o.add(toro(0.6, 0.035, 4, 16), 'emisivo', 0x86e07a, { x: Math.cos(a) * 2.0, y: 2.4, z: Math.sin(a) * 2.0, rx: Math.PI / 2 });
      o.add(media(0.58, 12), 'muro', 0xffffff, { x: Math.cos(a) * 2.0, y: 3.2, z: Math.sin(a) * 2.0 });
    }
    o.add(pilaSacos(5, rng), 'detalle', 0xe0dcec, { x: A / 2 - 0.6, z: L / 2 - 0.6 });
    top = Math.max(top, 3.9);
  }
  o.puntos.puerta = new THREE.Vector3(0, 0, L / 2 + 0.7);
  banderasEdad(o, A, L, 0, est, 1, { alto: 3.0, z: L / 2 + 0.15 });
  danios(o, A, L, top, est, rng);
  return top;
};

/* ---------------------------------------------------------- ASERRADERO 3×3 */
PLANOS.aserradero = (o, est, rng) => {
  const A = 5.6, L = 5.6, id = est.id;
  const h = id <= 1 ? 3.2 : 3.4;
  obraEnCurso(o, A, L, h + 2, est, rng);
  // cobertizo abierto: tres muros y el frente en pórtico
  o.add(muroConVentanas(A, h, est.espesor, 1, 3, id, {}), null, 0xffffff, { z: -(L / 2 - 0.2), ry: Math.PI });
  o.add(muroConVentanas(L * 0.9, h, est.espesor, 1, 2, id, {}), null, 0xffffff, { x: A / 2 - 0.2, ry: Math.PI / 2 });
  o.add(muroConVentanas(L * 0.9, h, est.espesor, 1, 2, id, {}), null, 0xffffff, { x: -(A / 2 - 0.2), ry: -Math.PI / 2 });
  for (const s of [-1, 1]) o.add(cajaBiselada(0.3, h, 0.34, 0.03), 'detalle', 0xffffff, { x: s * (A / 2 - 0.25), y: h / 2, z: L / 2 - 0.25 });
  o.add(cajaBiselada(A - 0.2, 0.34, 0.36, 0.03), 'detalle', 0xffffff, { y: h - 0.17, z: L / 2 - 0.25 });
  o.add(cercha(A - 0.5, 0.85, { montantes: 4 }), 'detalle', 0xf0f0f0, { y: h - 0.1, z: L / 2 - 0.6 });
  o.add(cercha(A - 0.5, 0.85, { montantes: 4 }), 'detalle', 0xf0f0f0, { y: h - 0.1, z: -L / 2 + 0.6 });
  let top = techoPorEdad(o, A + 0.3, L + 0.3, h, est, {
    tipo: id === 1 ? 'sierra' : id === 0 ? 'dosaguas' : est.techo, pendiente: 0.42, dientes: 2, buhardilla: false,
  });
  // banco de sierra
  o.add(cajaBiselada(2.2, 0.75, 1.1, 0.04), 'detalle', 0xd0d0d0, { y: 0.38, x: -0.5, z: 0.4 });
  o.add(disco(0.62, 0.06, 20), 'detalle', 0xe8e8e8, { x: 0.5, y: 0.95, z: 0.4, rz: Math.PI / 2, rx: Math.PI / 2 });
  for (let i = 0; i < 12; i++) {
    const a = (i / 12) * TAU;
    o.add(caja(0.09, 0.07, 0.05), 'detalle', 0xf4f4f4, { x: 0.5, y: 0.95 + Math.sin(a) * 0.64, z: 0.4 + Math.cos(a) * 0.64 });
  }
  // pilas de recurso bien visibles
  o.add(pilaTroncos(10, rng, { radio: 0.21, largo: 2.3 }), 'detalle', 0xa87e52, { x: -A / 2 - 1.0, z: -0.3, ry: 0.12 });
  o.add(pilaTroncos(6, rng, { radio: 0.19, largo: 2.0 }), 'detalle', 0x9c754c, { x: A / 2 + 0.95, z: 0.6, ry: -0.2 });
  const tablas = [];
  for (let i = 0; i < 8; i++) tablas.push(caja(2.0, 0.09, 0.42).translate(rng.float(-0.1, 0.1), 0.06 + i * 0.1, (i % 2) * 0.46));
  o.add(fusionar(tablas), 'detalle', 0xd6b184, { x: 0.4, z: L / 2 + 1.05, ry: rng.float(-0.15, 0.15) });
  if (id === 0) {
    const hc = 1.6;
    o.add(chimenea(hc, 0.42, 0), null, 0xffffff, { x: -A * 0.3, y: h + 0.6, z: -L * 0.2 });
    o.chimeneaEn(-A * 0.3, h + 0.6 + hc, -L * 0.2);
    // rueda hidráulica
    o.add(toro(1.1, 0.1, 4, 18), 'detalle', 0xb08c5e, { x: -A / 2 - 0.75, y: 1.2, z: 1.4, ry: Math.PI / 2 });
    o.add(toro(0.7, 0.08, 4, 16), 'detalle', 0xb08c5e, { x: -A / 2 - 0.75, y: 1.2, z: 1.4, ry: Math.PI / 2 });
    for (let i = 0; i < 10; i++) {
      const a = (i / 10) * TAU;
      o.add(caja(0.2, 0.34, 0.9), 'detalle', 0xc09a68, { x: -A / 2 - 0.75, y: 1.2 + Math.sin(a) * 0.92, z: 1.4 + Math.cos(a) * 0.92, rx: -a });
    }
    top = Math.max(top, h + 2.2);
  } else if (id === 1) {
    o.add(cilindro(0.55, 0.75, 2.4, 12), 'detalle', 0xd8d8d8, { x: A / 2 - 0.5, y: h + 1.2, z: -L / 2 + 0.8 });
    o.add(cilindro(0.24, 0.24, 2.6, 8), 'detalle', 0xcccccc, { x: A / 2 - 0.5, y: h - 0.4, z: -L / 2 + 0.2 });
    o.chimeneaEn(A / 2 - 0.5, h + 2.4, -L / 2 + 0.8);
    o.add(cartel(1.8, 0.7, 'MADERA', 1), null, 0xffffff, { y: h + 0.6, z: L / 2 - 0.1 });
  } else if (id >= 3) {
    o.add(cajaBiselada(1.5, 1.1, 1.1, 0.06), 'muro', 0xffffff, { x: A / 2 - 0.9, y: top + 0.5, z: 0 });
    o.add(cajaEn(1.3, 0.06, 0.9, A / 2 - 0.9, top + 1.06, 0), 'emisivo', id === 4 ? 0xb48bff : 0x66e6ff);
    o.add(antena(1.8, 'sensor'), null, 0xffffff, { x: -A / 2 + 0.8, y: top });
    o.chimeneaEn(A / 2 - 0.9, top + 1.2, 0);
  } else {
    o.add(cilindro(0.5, 0.6, 2.2, 12), 'muro', 0xf0f0f0, { x: A / 2 - 0.7, y: top + 1.1, z: -L / 2 + 0.9 });
    o.chimeneaEn(A / 2 - 0.7, top + 2.2, -L / 2 + 0.9);
  }
  o.puntos.puerta = new THREE.Vector3(0, 0, L / 2 + 0.8);
  banderasEdad(o, A, L, 0, est, 1, { alto: 3.2, z: L / 2 + 0.3 });
  danios(o, A, L, top, est, rng);
  return top;
};

/* ---------------------------------------------------------------- MINA 3×3 */
PLANOS.mina = (o, est, rng) => {
  const A = 5.6, L = 5.6, id = est.id;
  obraEnCurso(o, A, L, 6, est, rng);
  // bocamina: portal apuntalado sobre un talud
  o.add(cajaBiselada(3.0, 1.9, 1.5, 0.06), 'piedra', 0xffffff, { y: 0.95, z: -L / 2 + 0.9 });
  o.add(cajaEn(1.5, 1.5, 0.5, 0, 0.75, -L / 2 + 1.5), 'muro', 0x2a2622);
  for (const s of [-1, 1]) o.add(viga(1.7, id <= 0 ? 'madera' : 'I', 0.28, 0.22).rotateZ(Math.PI / 2), 'detalle', 0xffffff, { x: s * 0.85, y: 0.85, z: -L / 2 + 1.35 });
  o.add(viga(2.1, id <= 0 ? 'madera' : 'I', 0.3, 0.24), 'detalle', 0xffffff, { y: 1.75, z: -L / 2 + 1.35 });
  // faja sobre la bocamina: es la única fachada que tiene una mina, y sin ella
  // el edificio no declaraba de quién era
  o.add(cajaEn(3.12, 0.24, 0.5, 0, 1.98, -L / 2 + 1.4), 'jugador', 0xffffff);
  // castillete de extracción
  const ht = id <= 1 ? 5.4 : 5.0;
  if (id <= 1) {
    for (const sx of [-1, 1]) for (const sz of [-1, 1]) {
      o.add(tuboPor([[sx * 1.1, 0, sz * 1.0], [sx * 0.45, ht, sz * 0.42]], 0.1, 5), 'detalle', 0xffffff, { z: 0.3 });
    }
    for (let k = 1; k <= 4; k++) {
      const t = k / 4, r = lerp(1.05, 0.45, t);
      o.add(caja(r * 2.1, 0.09, 0.09), 'detalle', 0xe4e4e4, { y: ht * t, z: 0.3 + r * 0.95 });
      o.add(caja(r * 2.1, 0.09, 0.09), 'detalle', 0xe4e4e4, { y: ht * t, z: 0.3 - r * 0.95 });
      o.add(caja(0.09, 0.09, r * 2.0), 'detalle', 0xe4e4e4, { x: r * 1.0, y: ht * t, z: 0.3 });
      o.add(caja(0.09, 0.09, r * 2.0), 'detalle', 0xe4e4e4, { x: -r * 1.0, y: ht * t, z: 0.3 });
    }
    o.add(disco(0.85, 0.16, 18), 'jugador', 0xffffff, { y: ht + 0.1, z: 0.3, rz: Math.PI / 2, rx: Math.PI / 2 });
    o.add(disco(0.6, 0.18, 16), 'detalle', 0xdcdcdc, { y: ht + 0.1, z: 0.3, rz: Math.PI / 2, rx: Math.PI / 2 });
    o.add(cable([0, ht + 0.05, 0.3], [0, 1.9, -L / 2 + 1.4], 0.15, 0.035), 'detalle', 0x9a9a9a);
    o.add(tuboPor([[0.85, ht, 0.3], [2.0, 1.2, 1.5]], 0.08, 5), 'detalle', 0xdcdcdc);
  } else {
    o.add(cilindro(0.75, 1.0, 4.2, 14), 'muro', 0xffffff, { y: 2.1, z: 0.3 });
    o.add(cilindro(1.35, 1.35, 0.5, 14), 'muro', 0xf0f0f0, { y: 4.4, z: 0.3 });
    o.add(cilindro(1.42, 1.42, 0.16, 14), 'muro', 0xf0ede6, { y: 4.72, z: 0.3 });
    o.add(toro(1.44, 0.09, 4, 16), 'jugador', 0xffffff, { y: 4.76, z: 0.3, rx: Math.PI / 2 });
    o.add(antena(1.6, id >= 3 ? 'sensor' : 'latigo'), null, 0xffffff, { y: 4.8, z: 0.3 });
    for (let i = 0; i < 4; i++) {
      const a = (i / 4) * TAU + 0.4;
      o.add(tuboPor([[Math.cos(a) * 1.5, 0, 0.3 + Math.sin(a) * 1.5], [Math.cos(a) * 0.85, 2.6, 0.3 + Math.sin(a) * 0.85]], 0.07, 4), 'detalle', 0xe0e0e0);
    }
    o.chimeneaEn(0, 5.2, 0.3);
  }
  // cinta transportadora hacia la pila
  o.add(cajaBiselada(0.9, 0.2, 3.4, 0.03), 'detalle', 0xd8d8d8, { x: A / 2 - 0.4, y: 1.5, z: 0.4, rx: -0.38 });
  for (const s of [-1, 1]) o.add(cilindro(0.08, 0.08, 1.5, 6), 'detalle', 0xcccccc, { x: A / 2 - 0.4 + s * 0.4, y: 0.75, z: 1.5 });
  // pilas de mineral: el recurso tiene que verse
  o.add(pilaMineral(16, rng, { radio: 1.25 }), 'piedra', id >= 3 ? 0xb0b6c0 : 0x9a8f80, { x: A / 2 + 0.9, z: 1.5 });
  o.add(pilaMineral(9, rng, { radio: 0.9 }), 'piedra', 0x8a8478, { x: -A / 2 - 0.8, z: L / 2 - 0.6 });
  // vagoneta y vía
  const via = [];
  for (let i = 0; i < 9; i++) via.push(caja(1.1, 0.06, 0.1).translate(0, 0.03, -L / 2 + 1.6 + i * 0.42));
  via.push(caja(0.08, 0.09, 4.0).translate(-0.42, 0.08, -L / 2 + 3.2));
  via.push(caja(0.08, 0.09, 4.0).translate(0.42, 0.08, -L / 2 + 3.2));
  o.add(fusionar(via), 'detalle', id <= 0 ? 0x8a6a45 : 0xb0b0b0, { x: -1.4 });
  o.add(cajaBiselada(0.85, 0.6, 1.1, 0.04), 'detalle', 0xc08a5a, { x: -1.4, y: 0.42, z: L / 2 - 1.2 });
  o.add(pilaMineral(4, rng, { radio: 0.32 }), 'piedra', 0x9a8f80, { x: -1.4, y: 0.6, z: L / 2 - 1.2 });
  for (const s of [-1, 1]) o.add(disco(0.16, 0.07, 10), 'detalle', 0x6a5a48, { x: -1.4 + s * 0.44, y: 0.16, z: L / 2 - 1.2, rz: Math.PI / 2 });
  if (id === 0) {
    o.add(farol(2.2, 0), null, 0xffffff, { x: -1.9, z: -L / 2 + 2.0 });
    o.luzEn(-1.9, 2.3, -L / 2 + 2.0);
  } else if (id === 1) {
    o.add(cartel(1.6, 0.65, 'MINA', 1), null, 0xffffff, { x: 0, y: 2.3, z: -L / 2 + 1.75 });
  }
  o.puntos.puerta = new THREE.Vector3(0, 0, L / 2 + 0.6);
  banderasEdad(o, A, L, 0, est, 1, { alto: 3.0, z: L / 2 - 0.2 });
  danios(o, A, L, ht, est, rng);
  return ht + 0.6;
};

/* ------------------------------------------------------------- CUARTEL 4×4 */
PLANOS.cuartel = (o, est, rng) => {
  const A = 7.6, L = 7.6, id = est.id;
  const h = id <= 1 ? 4.0 : 3.8;
  obraEnCurso(o, A, L, h + 2, est, rng);
  cuerpo(o, A, L, h, est, { filas: 1, colsFrente: 4, colsLado: 4 });
  let top = techoPorEdad(o, A, L, h, est, { pendiente: 0.5, buhardilla: id === 0, pretil: 0.8 });
  puertaEdad(o, A, L, est, { ancho: 2.0, alto: 2.9 });
  // patio de armas: banderas, atril y armero
  banderasEdad(o, A, L, 0, est, 2, { alto: 4.6, z: L / 2 + 1.0 });
  if (id <= 1) {
    // marquesina de guardia con dos garitas
    for (const s of [-1, 1]) {
      o.add(cajaBiselada(0.95, 2.1, 0.95, 0.04), 'muro', 0xffffff, { x: s * (A / 2 - 0.4), y: 1.05, z: L / 2 + 1.5 });
      o.add(cilindro(0.05, 0.72, 0.55, 6), 'jugador', 0xffffff, { x: s * (A / 2 - 0.4), y: 2.35, z: L / 2 + 1.5 });
      o.add(cajaEn(0.5, 0.9, 0.06, s * (A / 2 - 0.4), 1.35, L / 2 + 1.98), 'muro', 0x2a2622);
    }
    // caballete de armas
    const rack = [];
    for (let i = 0; i < 5; i++) rack.push(cilindro(0.035, 0.035, 1.5, 5).translate(-0.35 + i * 0.18, 0.75, 0).rotateZ(0.12 * (i - 2)));
    o.add(fusionar(rack), 'detalle', 0x8a6a45, { x: -A / 2 - 0.9, z: -0.6 });
    o.add(barril(0.3, 0.75), 'detalle', 0xc9a678, { x: A / 2 + 0.75, z: -1.0 });
    if (id === 0) {
      const hc = 1.8;
      o.add(chimenea(hc, 0.5, 0), null, 0xffffff, { x: -A * 0.28, y: h + 0.8, z: -L * 0.22 });
      o.chimeneaEn(-A * 0.28, h + 0.8 + hc, -L * 0.22);
    } else {
      o.add(cartel(2.6, 0.9, 'CUARTEL', 1), null, 0xffffff, { y: h + 0.5, z: L / 2 - 0.05 });
    }
  } else if (id === 2) {
    // parapeto de hormigón y sacos terreros
    for (const s of [-1, 1]) {
      o.add(cajaBiselada(2.2, 1.0, 0.55, 0.05), 'muro', 0xf0f0f0, { x: s * (A / 2 - 1.0), y: 0.5, z: L / 2 + 1.4 });
      o.add(cajaEn(2.3, 0.14, 0.65, s * (A / 2 - 1.0), 1.05, L / 2 + 1.4), 'jugador', 0xffffff);
    }
    o.add(cartel(3.0, 0.9, 'CUARTEL', 2), null, 0xffffff, { y: h + 0.9, z: L / 2 - 0.1 });
    o.add(antena(2.4, 'mastil'), null, 0xffffff, { x: A / 2 - 0.9, y: top - 0.2, z: -L / 2 + 0.9 });
  } else if (id === 3) {
    o.add(cajaBiselada(A * 0.94, 0.24, 2.4, 0.06), 'muro', 0xffffff, { y: h - 0.2, z: L / 2 + 1.1 });
    for (const s of [-1, 1]) o.add(cilindro(0.1, 0.13, h - 0.2, 10), 'detalle', 0xe0e0e0, { x: s * A * 0.4, y: (h - 0.2) / 2, z: L / 2 + 2.1 });
    o.add(cartel(3.0, 0.8, 'CUARTEL', 3), null, 0xffffff, { y: h + 0.7, z: L / 2 - 0.05 });
    o.add(cajaEn(A * 0.9, 0.07, 0.1, 0, h - 0.42, L / 2 + 2.28), 'emisivo', 0x66e6ff);
  } else {
    o.add(cartel(3.0, 0.8, 'CUARTEL', 4), null, 0xffffff, { y: h + 0.8, z: L / 2 - 0.05 });
    for (const s of [-1, 1]) {
      o.add(cilindro(0.14, 0.2, 2.6, 12), 'muro', 0xffffff, { x: s * (A / 2 - 0.5), y: 1.3, z: L / 2 + 1.5 });
      o.add(toro(0.34, 0.04, 4, 14), 'emisivo', 0xb48bff, { x: s * (A / 2 - 0.5), y: 2.7, z: L / 2 + 1.5, rx: Math.PI / 2 });
    }
  }
  remateEdad(o, A, L, top, est, rng, { chimeneas: 1 });
  entornoEdad(o, A, L, est, rng, { cartel: 'CUARTEL' });
  danios(o, A, L, top, est, rng);
  return top;
};

/* ---------------------------------------------------------- EMPALIZADA 1×1 */
PLANOS.empalizada = (o, est, rng) => {
  const A = 2.0, id = est.id;
  const h = id <= 1 ? 2.1 : 2.4;
  if (id <= 1) {
    // troncos aguzados con travesaños y refuerzo
    const troncos = [];
    const n = 7;
    for (let i = 0; i < n; i++) {
      const x = -A / 2 + 0.16 + (i * (A - 0.32)) / (n - 1);
      const hh = h * rng.float(0.92, 1.05);
      troncos.push(cilindro(0.13, 0.15, hh, 7).translate(x, hh / 2, rng.float(-0.03, 0.03)));
      troncos.push(cilindro(0.01, 0.13, 0.24, 7).translate(x, hh + 0.12, 0));
    }
    o.add(fusionar(troncos), 'detalle', 0xb8865a);
    o.add(caja(A + 0.06, 0.1, 0.1), 'detalle', 0x9a6f47, { y: h * 0.35, z: -0.16 });
    // el travesaño de arriba pintado: una empalizada no tiene dónde más llevar el
    // bando, y sin él un tramo de muro no se distingue del de un vecino
    o.add(caja(A + 0.1, 0.12, 0.12), 'jugador', 0xffffff, { y: h * 0.72, z: -0.17 });
    o.add(cilindro(0.05, 0.05, h * 1.15, 5), 'detalle', 0x8a6a45, { x: -A / 2 + 0.2, y: h * 0.5, z: -0.35, rx: 0.5 });
    o.add(cajaEn(0.5, 0.22, 0.1, 0, h * 0.78, -0.2), 'jugador', 0xffffff);
  } else {
    o.add(cajaBiselada(A, h * 0.9, 0.42, 0.04), 'muro', 0xffffff, { y: h * 0.45 });
    o.add(cajaBiselada(A + 0.1, 0.12, 0.5, 0.03), 'jugador', 0xffffff, { y: h * 0.9 });
    o.add(cajaBiselada(A + 0.2, 0.26, 0.62, 0.04), 'piedra', 0xffffff, { y: 0.13 });
    for (const s of [-1, 1]) o.add(cilindro(0.04, 0.04, h, 5), 'detalle', 0xd0d0d0, { x: s * (A / 2 - 0.08), y: h / 2, z: 0.24 });
    if (id >= 3) o.add(cajaEn(A * 0.8, 0.05, 0.06, 0, h * 0.62, 0.23), 'emisivo', id === 4 ? 0xb48bff : 0x66e6ff);
  }
  o.usar('d1');
  o.add(ruina(A, A, h, 1, rng, id));
  o.usar('cuerpo');
  return h + 0.2;
};

/* ----------------------------------------------------------- ASTILLERO 4×3 */
PLANOS.astillero = (o, est, rng) => {
  const A = 7.6, L = 5.6, id = est.id;
  const h = id <= 1 ? 3.6 : 3.4;
  obraEnCurso(o, A, L, h + 2, est, rng);
  // muelle de tablones hacia el frente
  const muelle = [];
  for (let i = 0; i < 12; i++) muelle.push(caja(A + 1.6, 0.12, 0.4).translate(0, 0.5, L / 2 + 0.4 + i * 0.46));
  o.add(fusionar(muelle), 'detalle', id <= 1 ? 0xc79a68 : 0xcfcfcf);
  for (let i = 0; i < 5; i++) for (const s of [-1, 1]) {
    o.add(cilindro(0.17, 0.19, 1.1, 8), 'detalle', id <= 1 ? 0x8a6a45 : 0xa8a8a8, { x: s * (A / 2 + 0.5), y: 0.0, z: L / 2 + 0.7 + i * 1.15 });
  }
  o.add(baranda(A + 1.6, 0.9), 'detalle', 0xd0d0d0, { y: 0.56, z: L / 2 + 5.7 });
  // nave con grada abierta al agua
  o.add(muroConVentanas(A, h, est.espesor, 1, 4, id, {}), null, 0xffffff, { z: -(L / 2 - 0.2), ry: Math.PI });
  o.add(muroConVentanas(L, h, est.espesor, 1, 2, id, {}), null, 0xffffff, { x: A / 2 - 0.2, ry: Math.PI / 2 });
  o.add(muroConVentanas(L, h, est.espesor, 1, 2, id, {}), null, 0xffffff, { x: -(A / 2 - 0.2), ry: -Math.PI / 2 });
  for (const s of [-1, 1]) o.add(cajaBiselada(1.5, h, 0.4, 0.04), 'muro', 0xffffff, { x: s * (A / 2 - 0.75), y: h / 2, z: L / 2 - 0.2 });
  o.add(cajaBiselada(A, 0.5, 0.42, 0.04), 'jugador', 0xffffff, { y: h - 0.25, z: L / 2 - 0.2 });
  let top = techoPorEdad(o, A + 0.2, L + 0.2, h, est, { tipo: id <= 1 ? 'dosaguas' : id === 2 ? 'plano' : 'boveda', pendiente: 0.45, buhardilla: false, alto: 1.7 });
  // casco en grada
  const casco = extruirPerfil([[-2.3, 0], [2.3, 0], [2.9, 0.5], [2.5, 1.1], [-2.5, 1.1], [-2.9, 0.5]], 1.5, 0.06);
  o.add(casco, 'detalle', id <= 1 ? 0x9a6f47 : 0xb8bcc0, { y: 0.75, z: L / 2 + 2.4, ry: Math.PI / 2 });
  o.add(cajaEn(1.1, 0.3, 4.6, 0, 1.45, L / 2 + 2.4), 'detalle', 0xc8ccd0);
  for (let i = 0; i < 4; i++) o.add(cajaEn(0.22, 0.7, 1.4, 0, 0.35, L / 2 + 0.9 + i * 1.0), 'detalle', 0x8a7a68);
  if (id <= 1) {
    o.add(cilindro(0.09, 0.11, 3.6, 8), 'detalle', 0xc9a678, { y: 3.0, z: L / 2 + 2.4 });
    o.add(cilindro(0.06, 0.06, 1.6, 6).rotateZ(Math.PI / 2), 'detalle', 0xc9a678, { y: 4.1, z: L / 2 + 2.4 });
    o.add(panoOndulado(1.4, 1.3, 0.08, 8, 0.6).rotateY(Math.PI / 2), 'jugador', 0xffffff, { x: 0.02, y: 3.4, z: L / 2 + 3.1 });
    top = Math.max(top, 4.9);
  } else {
    o.add(cilindro(0.12, 0.15, 3.2, 8), 'detalle', 0xdcdcdc, { y: 2.9, z: L / 2 + 2.4 });
    o.add(antena(1.2, id >= 3 ? 'sensor' : 'latigo'), null, 0xffffff, { y: 4.4, z: L / 2 + 2.4 });
    top = Math.max(top, 5.2);
  }
  // grúa pórtico
  const hg = id <= 1 ? 4.4 : 5.2;
  for (const s of [-1, 1]) o.add(cilindro(0.11, 0.15, hg, 8), 'detalle', 0xe0e0e0, { x: s * (A / 2 + 0.4), y: hg / 2, z: L / 2 + 1.4 });
  // la viga de la grúa es acero: eran nueve metros de tabla de color plano
  // colgados en el aire por encima del agua, sin nada de material debajo
  o.add(caja(A + 1.4, 0.28, 0.4), 'detalle', 0xe0e0e0, { y: hg + 0.1, z: L / 2 + 1.4 });
  o.add(cajaBiselada(0.6, 0.42, 0.55, 0.03), 'detalle', 0xd0d0d0, { x: 1.2, y: hg - 0.28, z: L / 2 + 1.4 });
  o.add(cable([1.2, hg - 0.45, L / 2 + 1.4], [1.2, 1.4, L / 2 + 1.4], 0.02, 0.025), 'detalle', 0x8a8a8a);
  o.add(cajaBiselada(0.7, 0.35, 0.6, 0.03), 'detalle', 0xc8c8c8, { x: 1.2, y: 1.3, z: L / 2 + 1.4 });
  top = Math.max(top, hg + 0.4);
  o.add(barril(0.3, 0.72), 'detalle', 0xc9a678, { x: -A / 2 - 0.6, z: -L * 0.2 });
  o.add(pilaTroncos(5, rng, { radio: 0.17, largo: 2.0 }), 'detalle', 0xa87e52, { x: A / 2 + 0.9, z: -L * 0.15, ry: 0.2 });
  o.puntos.puerta = new THREE.Vector3(0, 0, L / 2 + 0.8);
  banderasEdad(o, A, L, 0, est, 1, { alto: 3.6, z: -L / 2 - 0.5 });
  danios(o, A, L, top, est, rng);
  return top;
};

/* ------------------------------------------------------------- MERCADO 4×4 */
PLANOS.mercado = (o, est, rng) => {
  const A = 7.6, L = 7.6, id = est.id;
  const h = id <= 1 ? 3.8 : 3.6;
  obraEnCurso(o, A, L, h + 2, est, rng);
  // cuerpo en U: nave central y dos alas bajas
  cuerpo(o, A * 0.62, L * 0.7, h, est, { filas: 1, colsFrente: 3, colsLado: 3, y: 0 });
  let top = techoPorEdad(o, A * 0.62, L * 0.7, h, est, { pendiente: 0.5, buhardilla: false, pretil: 0.6 });
  for (const s of [-1, 1]) {
    const ax = s * (A * 0.37);
    cuerpo(o, A * 0.24, L * 0.55, h * 0.62, est, { filas: 1, colsFrente: 1, colsLado: 2, espesor: 0.3, pilastras: false, x: ax });
    // la losa medía más que el ala (A*0.3 contra A*0.24) y volaba por los cuatro
    // costados: cubierta con material, y de bando sólo la cornisa del frente
    o.add(cajaBiselada(A * 0.26, 0.2, L * 0.57, 0.04), 'muro', 0xf2f0ea, { x: ax, y: h * 0.62 + 0.1 });
    o.add(cajaEn(A * 0.29, 0.17, 0.32, ax, h * 0.62 + 0.24, L * 0.275), 'jugador', 0xffffff);
  }
  // puestos con toldos rayados
  for (let i = 0; i < 3; i++) {
    const x = -A * 0.34 + i * (A * 0.34);
    const z = L / 2 + 1.2;
    o.add(cajaBiselada(1.5, 0.85, 0.9, 0.03), 'detalle', id <= 1 ? 0xc9a678 : 0xd4d4d4, { x, y: 0.42, z });
    o.add(cajaEn(1.6, 0.1, 1.0, x, 0.9, z), 'detalle', 0xb8935f);
    for (const s of [-1, 1]) o.add(cilindro(0.045, 0.045, 2.1, 6), 'detalle', 0xcfcfcf, { x: x + s * 0.7, y: 1.05, z: z + 0.4 });
    // Tres toldos del color del bando era un tercio del mercado en un solo RGB.
    // Además un mercado con las tres lonas idénticas no parece un mercado: el
    // puesto del medio lleva el toldo de la casa y los otros dos, lona cruda.
    const toldo = panoOndulado(1.75, 1.35, 0.06, 8, i * 1.2);
    toldo.rotateX(-1.05);
    o.add(toldo, i === 1 ? 'jugador' : 'detalle', i === 1 ? 0xffffff : (i ? 0xe8dcc4 : 0xdcd2bc), { x, y: 1.95, z: z + 0.55 });
    o.add(barril(0.2, 0.5), 'detalle', 0xc4a071, { x: x + 0.85, z: z - 0.6 });
    o.add(cajon(0.42, 0.34, 0.4), 'detalle', 0xd8bd90, { x: x - 0.8, z: z - 0.55 });
    for (let k = 0; k < 5; k++) o.add(esfera(0.1, 6), 'detalle', k % 2 ? 0xd85a3c : 0xd8b03c, { x: x - 0.5 + k * 0.24, y: 0.94, z });
  }
  if (id <= 1) {
    o.add(cartel(2.4, 0.85, 'MERCADO', id), null, 0xffffff, { y: h + 0.5, z: L * 0.35 + 0.1 });
    // balanza
    o.add(cilindro(0.07, 0.09, 1.5, 6), 'detalle', 0xcfcfcf, { x: -A / 2 - 0.7, y: 0.75, z: 0.4 });
    o.add(caja(0.9, 0.05, 0.05), 'detalle', 0xdcdcdc, { x: -A / 2 - 0.7, y: 1.5, z: 0.4 });
    for (const s of [-1, 1]) o.add(cilindro(0.16, 0.13, 0.08, 8), 'detalle', 0xe4e4e4, { x: -A / 2 - 0.7 + s * 0.42, y: 1.28, z: 0.4 });
  } else if (id === 2) {
    o.add(cartel(3.0, 1.0, 'MERCADO', 2), null, 0xffffff, { y: h + 0.8, z: L * 0.35 + 0.1 });
    o.add(parabolica(0.7), null, 0xffffff, { x: -A * 0.3, y: top, z: -L * 0.2, ry: 0.6 });
  } else {
    o.add(cartel(3.2, 0.9, id === 4 ? 'INTERCAMBIO' : 'MERCADO', id), null, 0xffffff, { y: h + 0.9, z: L * 0.35 + 0.1 });
    for (let i = 0; i < 3; i++) o.add(cajaEn(2.4, 0.06, 0.09, 0, 1.0 + i * 0.45, L * 0.35 + 0.2), 'emisivo', id === 4 ? 0xb48bff : 0x66e6ff);
  }
  remateEdad(o, A * 0.62, L * 0.7, top, est, rng, { chimeneas: 1 });
  banderasEdad(o, A, L, 0, est, 2, { alto: 4.0, z: -L / 2 - 0.4 });
  entornoEdad(o, A, L, est, rng, { cartel: 'MERCADO' });
  o.puntos.puerta = new THREE.Vector3(0, 0, L / 2 + 2.4);
  danios(o, A, L, top, est, rng);
  return top;
};

/* ----------------------------------------------------------- FUNDICION 3×3 */
PLANOS.fundicion = (o, est, rng) => {
  const A = 5.6, L = 5.6, id = est.id;
  const h = id <= 1 ? 3.6 : 3.4;
  obraEnCurso(o, A, L, h + 3, est, rng);
  cuerpo(o, A, L, h, est, { filas: 1, colsFrente: 3, colsLado: 3 });
  let top = techoPorEdad(o, A, L, h, est, { tipo: id === 1 ? 'sierra' : est.techo, dientes: 2, pendiente: 0.42, buhardilla: false });
  // horno: cono truncado con boca incandescente
  const hh = id <= 1 ? 3.4 : 3.0;
  o.add(cilindro(0.75, 1.3, hh, 14), 'muro', 0xffffff, { x: -A * 0.22, y: top + hh / 2 - 0.3, z: -L * 0.18 });
  for (let i = 1; i < 4; i++) o.add(toro(lerp(1.3, 0.75, i / 4) + 0.04, 0.06, 4, 16), 'detalle', 0xcfa07a, { x: -A * 0.22, y: top - 0.3 + (hh * i) / 4, z: -L * 0.18, rx: Math.PI / 2 });
  o.add(cilindro(0.78, 0.78, 0.2, 14), 'emisivo', 0xff7a22, { x: -A * 0.22, y: top + hh - 0.28, z: -L * 0.18 });
  o.chimeneaEn(-A * 0.22, top + hh - 0.2, -L * 0.18);
  // chimenea alta
  const hc = id <= 1 ? 4.2 : 3.4;
  o.add(chimenea(hc, 0.62, id), null, 0xffffff, { x: A * 0.26, y: top - 0.35, z: L * 0.16 });
  o.chimeneaEn(A * 0.26, top - 0.35 + hc, L * 0.16);
  top = Math.max(top + hh, top - 0.35 + hc) + 0.2;
  // boca de colada y cuchara
  o.add(cajaEn(1.5, 1.35, 0.25, 0, 0.68, L / 2 + 0.02), 'emisivo', 0xff6a18);
  o.add(cajaBiselada(1.9, 1.7, 0.5, 0.05), 'muro', 0x9a9a9a, { y: 0.85, z: L / 2 + 0.05 });
  o.add(cilindro(0.42, 0.5, 0.72, 12), 'detalle', 0x8a8a8a, { x: 1.5, y: 0.36, z: L / 2 + 1.1, rz: 0.35 });
  o.add(cilindro(0.36, 0.36, 0.08, 12), 'emisivo', 0xffaa33, { x: 1.5, y: 0.72, z: L / 2 + 1.1 });
  // lingotes y mineral
  o.add(pilaMineral(10, rng, { radio: 0.85 }), 'piedra', 0x8f8578, { x: -A / 2 - 0.85, z: L * 0.2 });
  const lingotes = [];
  for (let i = 0; i < 6; i++) lingotes.push(caja(0.7, 0.14, 0.26).translate((i % 3) * 0.02, 0.07 + Math.floor(i / 3) * 0.15, (i % 3) * 0.3));
  o.add(fusionar(lingotes), 'detalle', 0xd8b26a, { x: A / 2 + 0.8, z: -L * 0.1 });
  if (id === 1) {
    o.add(cartel(1.8, 0.7, 'ACERO', 1), null, 0xffffff, { y: h + 0.55, z: L / 2 - 0.02 });
    o.add(cilindro(0.11, 0.11, L * 0.9, 8).rotateX(Math.PI / 2), 'detalle', 0xbdbdbd, { x: A / 2 + 0.22, y: 2.2 });
  } else if (id >= 3) {
    o.add(cajaEn(A * 0.8, 0.07, 0.11, 0, h + 0.35, L / 2 + 0.05), 'emisivo', id === 4 ? 0xb48bff : 0x66e6ff);
    o.add(antena(1.9, 'sensor'), null, 0xffffff, { x: A * 0.3, y: top - 1.0, z: -L * 0.3 });
  }
  o.puntos.puerta = new THREE.Vector3(0, 0, L / 2 + 0.8);
  banderasEdad(o, A, L, 0, est, 1, { alto: 3.4, z: L / 2 + 0.6 });
  entornoEdad(o, A, L, est, rng, { cartel: 'ACERO' });
  danios(o, A, L, top, est, rng);
  return top;
};

/* ------------------------------------------------------------ POLIGONO 4×4 */
PLANOS.poligono = (o, est, rng) => {
  const A = 7.6, L = 7.6, id = est.id;
  const h = id <= 1 ? 3.2 : 3.0;
  obraEnCurso(o, A, L, h + 2, est, rng);
  // galería de tiro: nave larga y baja al fondo
  cuerpo(o, A, L * 0.45, h, est, { filas: 1, colsFrente: 4, colsLado: 2, y: 0 });
  let top = techoPorEdad(o, A, L * 0.45, h, est, { pendiente: 0.42, buhardilla: false, pretil: 0.55 });
  o.add(cajaEn(A - 0.4, 0.2, L * 0.45 - 0.4, 0, 0.1, 0), 'piedra', 0xc0b8a8, { z: -L * 0.275 });
  // línea de tiro techada
  const zl = L * 0.1;
  // dieciséis metros cuadrados de chapa: va con material. El bando de esta zona
  // queda en los cuatro capiteles de los puestos, que son el ritmo que se lee.
  o.add(cajaBiselada(A, 0.24, 2.2, 0.05), 'detalle', 0xdcdcdc, { y: 2.5, z: zl });
  for (let i = 0; i < 4; i++) {
    const x = -A / 2 + 0.6 + i * ((A - 1.2) / 3);
    o.add(cilindro(0.09, 0.11, 2.5, 8), 'detalle', 0xffffff, { x, y: 1.25, z: zl + 0.9 });
    o.add(cajaBiselada(1.0, 0.95, 0.5, 0.04), 'muro', 0xffffff, { x, y: 0.48, z: zl + 0.9 });
    o.add(cajaEn(1.05, 0.12, 0.6, x, 0.98, zl + 0.9), 'jugador', 0xffffff);
  }
  // terraplén y blancos
  const berma = extruirPerfil([[-A / 2 - 0.4, 0], [A / 2 + 0.4, 0], [A / 2 - 0.2, 1.5], [-A / 2 + 0.2, 1.5]], 1.4, 0.05);
  o.add(berma, 'piedra', 0xa89878, { y: 0, z: L / 2 + 1.2, rx: 0 });
  for (let i = 0; i < 4; i++) {
    const x = -A / 2 + 0.7 + i * ((A - 1.4) / 3);
    o.add(cajaEn(0.09, 1.3, 0.09, x, 0.65, L / 2 + 0.55), 'detalle', 0x8a6a45);
    o.add(disco(0.42, 0.07, 14), 'muro', 0xffffff, { x, y: 1.5, z: L / 2 + 0.55, rx: Math.PI / 2 });
    o.add(disco(0.26, 0.09, 12), 'jugador', 0xffffff, { x, y: 1.5, z: L / 2 + 0.57, rx: Math.PI / 2 });
    o.add(disco(0.1, 0.11, 10), 'detalle', 0x2a2622, { x, y: 1.5, z: L / 2 + 0.59, rx: Math.PI / 2 });
  }
  if (id <= 1) {
    o.add(cartel(2.2, 0.75, 'TIRO', id), null, 0xffffff, { y: h + 0.5, z: -L * 0.45 - 0.05, ry: Math.PI });
    const rack = [];
    for (let i = 0; i < 6; i++) rack.push(cilindro(0.03, 0.03, 1.4, 5).translate(-0.45 + i * 0.18, 0.7, 0).rotateZ(0.1 * (i - 2.5)));
    o.add(fusionar(rack), 'detalle', 0x8a6a45, { x: A / 2 + 0.8, z: -L * 0.1 });
    o.add(barril(0.28, 0.7), 'detalle', 0xc9a678, { x: -A / 2 - 0.7, z: -L * 0.05 });
  } else if (id === 2) {
    o.add(antena(2.6, 'mastil'), null, 0xffffff, { x: -A * 0.32, y: top - 0.2, z: -L * 0.32 });
    for (let i = 0; i < 4; i++) o.add(cajaBiselada(0.6, 0.9, 0.6, 0.04), 'muro', 0xe8e8e8, { x: -A * 0.35 + i * (A * 0.23), y: 0.45, z: -L * 0.44 });
  } else {
    o.add(cartel(2.6, 0.8, 'TIRO', id), null, 0xffffff, { y: h + 0.7, z: -L * 0.45 - 0.05, ry: Math.PI });
    for (let i = 0; i < 4; i++) {
      const x = -A / 2 + 0.7 + i * ((A - 1.4) / 3);
      o.add(cajaEn(0.5, 0.06, 0.08, x, 2.1, L / 2 + 0.6), 'emisivo', id === 4 ? 0xb48bff : 0x66e6ff);
    }
    o.add(antena(2.0, 'sensor'), null, 0xffffff, { x: A * 0.36, y: top - 0.2, z: -L * 0.3 });
  }
  o.puntos.puerta = new THREE.Vector3(0, 0, -L * 0.45 - 0.8);
  banderasEdad(o, A, L, 0, est, 2, { alto: 3.6, z: -L * 0.4 });
  danios(o, A, L, top, est, rng);
  return top;
};

/* ------------------------------------------------------------- ESTABLO 4×4 */
PLANOS.establo = (o, est, rng) => {
  const A = 7.6, L = 7.6, id = est.id;
  const h = id <= 1 ? 3.6 : 3.8;
  obraEnCurso(o, A, L, h + 2, est, rng);
  cuerpo(o, A, L * 0.72, h, est, { filas: 1, colsFrente: 3, colsLado: 3 });
  let top = techoPorEdad(o, A, L * 0.72, h, est, { pendiente: 0.62, buhardilla: id <= 1, pretil: 0.6 });
  // portones: en 1800 de madera partida, después mecánicos
  const zp = L * 0.36;
  for (let i = 0; i < 2; i++) {
    const x = (i - 0.5) * 2.5;
    o.add(cajaEn(2.2, 2.5, 0.3, x, 1.25, zp - 0.12), 'detalle', id <= 1 ? 0x7a5636 : 0xb8bcc0);
    o.add(cajaEn(2.35, 0.22, 0.42, x, 2.55, zp), 'jugador', 0xffffff);
    o.add(cajaEn(0.14, 2.5, 0.42, x - 1.15, 1.25, zp), 'jugador', 0xffffff);
    o.add(cajaEn(0.14, 2.5, 0.42, x + 1.15, 1.25, zp), 'jugador', 0xffffff);
    if (id <= 1) {
      o.add(cajaEn(2.1, 0.11, 0.36, x, 1.35, zp + 0.02), 'detalle', 0x9a7048);
      o.add(cajaEn(0.11, 2.4, 0.36, x, 1.25, zp + 0.02), 'detalle', 0x9a7048);
    } else {
      for (let k = 0; k < 5; k++) o.add(cajaEn(2.1, 0.1, 0.36, x, 0.35 + k * 0.5, zp + 0.02), 'detalle', 0x9fa5aa);
    }
  }
  // corral
  const cerco = [];
  for (let i = 0; i <= 8; i++) {
    const x = -A / 2 + (A * i) / 8;
    cerco.push(caja(0.11, 1.05, 0.11).translate(x, 0.52, L / 2 + 1.6));
  }
  for (const s of [-1, 1]) for (let i = 0; i <= 2; i++) cerco.push(caja(0.11, 1.05, 0.11).translate(s * A / 2, 0.52, L * 0.42 + i * 0.6));
  for (const y of [0.5, 0.85]) {
    cerco.push(caja(A + 0.1, 0.08, 0.07).translate(0, y, L / 2 + 1.6));
    for (const s of [-1, 1]) cerco.push(caja(0.07, 0.08, 1.3).translate(s * A / 2, y, L * 0.55));
  }
  o.add(fusionar(cerco), 'detalle', id <= 1 ? 0xb8865a : 0xcfcfcf);
  // bebedero y forraje
  o.add(cajaBiselada(1.6, 0.42, 0.6, 0.04), 'detalle', id <= 1 ? 0x9a7048 : 0xc0c4c8, { x: -A * 0.28, y: 0.21, z: L / 2 + 1.0 });
  o.add(cajaEn(1.45, 0.06, 0.48, -A * 0.28, 0.4, L / 2 + 1.0), 'vidrio', 0x9fc6dc);
  if (id <= 1) {
    const heno = [];
    for (let i = 0; i < 3; i++) heno.push(caja(0.85, 0.6, 0.7).translate((i % 2) * 0.15, 0.3 + Math.floor(i / 2) * 0.62, i * 0.12));
    o.add(fusionar(heno), 'detalle', 0xd8bd6a, { x: A * 0.3, z: L / 2 + 1.1, ry: 0.2 });
    if (id === 0) {
      const hc = 1.5;
      o.add(chimenea(hc, 0.4, 0), null, 0xffffff, { x: -A * 0.3, y: h + 0.9, z: -L * 0.15 });
      o.chimeneaEn(-A * 0.3, h + 0.9 + hc, -L * 0.15);
    } else {
      o.add(cartel(2.2, 0.75, 'ESTABLO', 1), null, 0xffffff, { y: h + 0.5, z: zp + 0.06 });
    }
  } else {
    // surtidor / punto de carga
    o.add(cajaBiselada(0.55, 1.5, 0.5, 0.05), 'muro', 0xffffff, { x: A * 0.34, y: 0.75, z: L / 2 + 1.1 });
    o.add(cajaEn(0.42, 0.32, 0.06, A * 0.34, 1.25, L / 2 + 1.38), 'emisivo', id === 4 ? 0xb48bff : id === 3 ? 0x66e6ff : 0xd9e04f);
    o.add(tuboPor([[A * 0.34 + 0.25, 1.3, L / 2 + 1.1], [A * 0.34 + 0.8, 0.9, L / 2 + 1.4], [A * 0.34 + 0.7, 0.3, L / 2 + 1.9]], 0.05, 4), 'detalle', 0x6a6a6a);
    for (let i = 0; i < 4; i++) o.add(cilindro(0.3, 0.3, 0.85, 10), 'detalle', i % 2 ? 0x8f9a6a : 0xb0b4a8, { x: -A / 2 - 0.7, y: 0.42, z: -L * 0.3 + i * 0.7 });
    if (id === 2) o.add(cartel(2.6, 0.85, 'BLINDADOS', 2), null, 0xffffff, { y: h + 0.8, z: zp + 0.06 });
    else o.add(cartel(2.6, 0.8, id === 4 ? 'AUTONOMOS' : 'VEHICULOS', id), null, 0xffffff, { y: h + 0.8, z: zp + 0.06 });
  }
  remateEdad(o, A, L * 0.72, top, est, rng, { chimeneas: 1 });
  banderasEdad(o, A, L, 0, est, 2, { alto: 3.8, z: -L * 0.34 });
  o.puntos.puerta = new THREE.Vector3(0, 0, zp + 1.2);
  danios(o, A, L, top, est, rng);
  return top;
};

/* -------------------------------------------------------------- TALLER 4×4 */
PLANOS.taller = (o, est, rng) => {
  const A = 7.6, L = 7.6, id = est.id;
  const h = id <= 1 ? 4.0 : 3.8;
  obraEnCurso(o, A, L, h + 2, est, rng);
  cuerpo(o, A, L * 0.68, h, est, { filas: 1, colsFrente: 2, colsLado: 3 });
  let top = techoPorEdad(o, A, L * 0.68, h, est, { tipo: id === 1 ? 'sierra' : est.techo, dientes: 3, pendiente: 0.44, buhardilla: false });
  // portón de nave + pórtico de grúa exterior
  const zp = L * 0.34;
  o.add(cajaEn(3.4, 3.1, 0.32, 0, 1.55, zp - 0.12), 'detalle', id <= 1 ? 0x7a5636 : 0x9fa5aa);
  o.add(cajaEn(3.6, 0.24, 0.44, 0, 3.2, zp), 'jugador', 0xffffff);
  for (const s of [-1, 1]) o.add(cajaEn(0.18, 3.2, 0.44, s * 1.8, 1.6, zp), 'jugador', 0xffffff);
  const hg = 4.6;
  for (const s of [-1, 1]) o.add(cilindro(0.12, 0.16, hg, 8), 'detalle', 0xe0e0e0, { x: s * (A / 2 - 0.3), y: hg / 2, z: L / 2 + 1.3 });
  o.add(viga(A - 0.4, 'I', 0.35, 0.24), 'detalle', 0xf0f0f0, { y: hg + 0.1, z: L / 2 + 1.3 });
  o.add(cajaEn(A - 0.3, 0.14, 0.3, 0, hg + 0.36, L / 2 + 1.3), 'jugador', 0xffffff);
  o.add(cable([-0.8, hg - 0.15, L / 2 + 1.3], [-0.8, 1.3, L / 2 + 1.3], 0.02, 0.025), 'detalle', 0x8a8a8a);
  o.add(cajaBiselada(0.55, 0.4, 0.5, 0.03), 'detalle', 0xc8c8c8, { x: -0.8, y: 1.1, z: L / 2 + 1.3 });
  top = Math.max(top, hg + 0.5);
  // pieza de artillería en montaje
  if (id <= 1) {
    o.add(extruirPerfil([[-1.1, 0], [1.1, 0], [0.9, 0.7], [-0.7, 0.75]], 0.22, 0.03), 'detalle', 0xa87a4c, { x: 1.2, y: 0.35, z: L / 2 + 1.9, ry: 0.35 });
    for (const s of [-1, 1]) o.add(toro(0.52, 0.09, 4, 14), 'detalle', 0xb8905c, { x: 1.2 + s * 0.02, y: 0.52, z: L / 2 + 1.9 + s * 0.42, ry: 0.35 });
    o.add(cilindro(0.14, 0.19, 2.1, 10).rotateZ(Math.PI / 2), 'detalle', 0x8a8a8a, { x: 2.0, y: 0.95, z: L / 2 + 1.9, ry: 0.35, rz: -0.12 });
    o.add(pilaMineral(5, rng, { radio: 0.35 }), 'piedra', 0x6a6a6a, { x: -A / 2 - 0.6, z: L / 2 + 1.0 });
  } else {
    o.add(cajaBiselada(2.6, 0.85, 1.4, 0.06), 'detalle', 0x9aa08a, { x: 1.4, y: 0.6, z: L / 2 + 2.0, ry: 0.3 });
    o.add(cilindro(0.16, 0.2, 2.6, 10).rotateZ(Math.PI / 2), 'detalle', 0x8a8f80, { x: 2.5, y: 1.2, z: L / 2 + 2.2, ry: 0.3, rz: 0.08 });
    for (let i = 0; i < 4; i++) o.add(disco(0.34, 0.22, 12), 'detalle', 0x3a3a3a, { x: 0.5 + i * 0.6, y: 0.34, z: L / 2 + 1.5, rz: Math.PI / 2, ry: 0.3 });
  }
  // bancos, cajones y ruedas
  o.add(cajaBiselada(2.0, 0.9, 0.7, 0.04), 'detalle', id <= 1 ? 0xb8935f : 0xcfcfcf, { x: -A * 0.3, y: 0.45, z: L / 2 + 1.5 });
  o.add(cajon(0.65, 0.5, 0.6), 'detalle', 0xc9a678, { x: -A * 0.3 + 1.2, z: L / 2 + 1.6, ry: 0.3 });
  if (id === 1) o.add(cartel(2.4, 0.8, 'TALLER', 1), null, 0xffffff, { y: h + 0.55, z: zp + 0.06 });
  else if (id >= 3) o.add(cartel(2.6, 0.8, 'TALLER', id), null, 0xffffff, { y: h + 0.8, z: zp + 0.06 });
  remateEdad(o, A, L * 0.68, top - 0.6, est, rng, { chimeneas: 1, chimeneaAlta: 3.4 });
  banderasEdad(o, A, L, 0, est, 1, { alto: 3.8, z: -L * 0.32 });
  o.puntos.puerta = new THREE.Vector3(0, 0, zp + 1.4);
  danios(o, A, L, top, est, rng);
  return top;
};

/* ------------------------------------------------------------- TORRETA 2×2 */
PLANOS.torreta = (o, est, rng) => {
  const A = 3.6, L = 3.6, id = est.id;
  obraEnCurso(o, A, L, 8, est, rng);
  const ht = id === 0 ? 6.2 : id === 1 ? 6.6 : id === 2 ? 5.6 : id === 3 ? 6.4 : 6.8;
  o.add(cajaBiselada(A + 0.5, 0.5, L + 0.5, 0.08), 'piedra', 0xffffff, { y: 0.25 });
  if (id <= 1) {
    o.add(torre(1.35, ht - 1.5, id, { capitel: false }), null, 0xffffff, { y: 0.45 });
    // matacán y garita
    o.add(cilindro(1.7, 1.45, 0.45, 14), 'piedra', 0xffffff, { y: ht - 0.8 });
    o.add(cilindro(1.55, 1.55, 0.25, 14), 'jugador', 0xffffff, { y: ht - 0.45 });
    const n = 8;
    for (let i = 0; i < n; i++) {
      const a = (i / n) * TAU;
      o.add(cajaEn(0.4, 0.55, 0.34, Math.cos(a) * 1.5, ht - 0.05, Math.sin(a) * 1.5), 'piedra', 0xffffff, { ry: -a });
    }
    o.add(cilindro(0.02, 0.9, 1.1, 12), 'jugador', 0xffffff, { y: ht + 0.85 });
  } else if (id === 2) {
    o.add(cajaBiselada(A, 3.2, L, 0.12), 'muro', 0xffffff, { y: 1.9 });
    o.add(cajaBiselada(A + 0.4, 0.35, L + 0.4, 0.06), 'muro', 0xf0f0f0, { y: 3.6 });
    o.add(cilindro(1.5, 1.65, 1.5, 14), 'muro', 0xffffff, { y: 4.4 });
    o.add(cilindro(1.55, 1.4, 0.25, 14), 'jugador', 0xffffff, { y: 5.25 });
    for (let i = 0; i < 4; i++) {
      const a = (i / 4) * TAU + 0.4;
      o.add(cajaEn(1.1, 0.35, 0.16, Math.cos(a) * 1.75, 2.6, Math.sin(a) * 1.75), 'muro', 0x2a2622, { ry: -a });
    }
  } else {
    o.add(cilindro(0.75, 1.05, ht - 1.9, 14), 'detalle', 0xffffff, { y: (ht - 1.9) / 2 + 0.4 });
    // sin rx estos aros quedaban VERTICALES, atravesando la torre de lado a lado
    for (let i = 0; i < 3; i++) o.add(toro(0.9 - i * 0.06, 0.05, 4, 16), 'jugador', 0xffffff, { y: 1.4 + i * 1.3, rx: Math.PI / 2 });
    o.add(cilindro(1.5, 1.2, 0.9, 14), 'muro', 0xffffff, { y: ht - 1.1 });
    // collarín bajo la cabina: la torreta no tiene cuerpo ni friso, y con los
    // tres aros finos del fuste no llegaba ni al 1% de color de bando
    o.add(cilindro(1.58, 1.58, 0.3, 14), 'jugador', 0xffffff, { y: ht - 1.7 });
    o.add(toro(1.45, 0.05, 4, 18), 'emisivo', id === 4 ? 0xb48bff : 0x66e6ff, { y: ht - 1.4, rx: Math.PI / 2 });
  }
  // el arma
  const yc = ht - (id <= 1 ? 0.2 : id === 2 ? 0.9 : 0.6);
  const cuna = conjunto(
    pieza(cajaBiselada(0.85, 0.5, 1.0, 0.05), 'detalle', 0xffffff).translateY(0.25),
    pieza(cilindro(0.13, 0.17, id <= 0 ? 1.9 : 2.4, 10).rotateX(Math.PI / 2), 'detalle', 0xdcdcdc).translateY(0.35).translateZ(id <= 0 ? 1.1 : 1.4),
    pieza(cajaEn(0.95, 0.62, 0.14, 0, 0.32, 0.52), 'jugador', 0xffffff),
  );
  if (id >= 3) {
    for (const s of [-1, 1]) cuna.add(pieza(cajaEn(0.22, 0.42, 1.1, s * 0.5, 0.4, 0.5), 'detalle', 0xe0e0e0));
    cuna.add(pieza(esfera(0.1, 8), 'emisivo', id === 4 ? 0xb48bff : 0x66e6ff).translateY(0.6).translateZ(0.2));
  } else if (id <= 0) {
    for (const s of [-1, 1]) cuna.add(pieza(toro(0.3, 0.06, 4, 12), 'detalle', 0xb8905c).translateX(s * 0.45).translateY(0.2));
  }
  o.add(cuna, null, 0xffffff, { y: yc });
  o.puntos.canon = new THREE.Vector3(0, yc + 0.35, id <= 0 ? 2.0 : 2.6);
  o.banderaEn(0, ht + 1.8, 0);
  if (id <= 1) o.add(bandera(1.6, { ancho: 0.75, altoPano: 0.5 }), null, 0xffffff, { y: ht + 0.4 });
  o.add(farol(1.9, Math.min(id, 4)), null, 0xffffff, { x: A / 2 + 0.35, z: L / 2 + 0.35 });
  o.luzEn(A / 2 + 0.35, 2.1, L / 2 + 0.35);
  o.puntos.puerta = new THREE.Vector3(0, 0, L / 2 + 0.5);
  o.chimeneaEn(0, ht - 0.4, 0);
  danios(o, A, L, ht, est, rng);
  return ht + 1.2;
};

/* ------------------------------------------------------- MURO HORMIGON 1×1 */
PLANOS.muro_hormigon = (o, est, rng) => {
  const A = 2.0, id = est.id;
  const h = id >= 4 ? 2.8 : 2.6;
  o.add(cajaBiselada(A, h * 0.88, 0.62, 0.05), 'muro', 0xffffff, { y: h * 0.44 });
  o.add(cajaBiselada(A + 0.24, 0.34, 0.85, 0.05), 'piedra', 0xffffff, { y: 0.17 });
  o.add(cajaBiselada(A + 0.1, 0.15, 0.72, 0.04), 'jugador', 0xffffff, { y: h * 0.88 + 0.06 });
  // juntas de encofrado y agujeros de amarre
  for (let i = 1; i < 3; i++) o.add(cajaEn(A, 0.05, 0.66, 0, (h * 0.88 * i) / 3, 0), 'muro', 0x9a9a9a);
  for (let i = 0; i < 4; i++) for (const s of [-1, 1]) {
    o.add(cilindro(0.05, 0.05, 0.68, 6).rotateX(Math.PI / 2), 'muro', 0x8a8a8a, { x: -A / 2 + 0.35 + i * 0.45, y: h * (0.25 + (i % 2) * 0.35) });
  }
  for (const s of [-1, 1]) o.add(cajaBiselada(0.18, h * 0.9, 0.7, 0.03), 'piedra', 0xf2f2f2, { x: s * (A / 2 - 0.05), y: h * 0.45 });
  if (id >= 3) {
    o.add(cajaEn(A * 0.85, 0.05, 0.06, 0, h * 0.72, 0.33), 'emisivo', id === 4 ? 0xb48bff : 0x66e6ff);
    for (const s of [-1, 1]) o.add(cilindro(0.035, 0.035, 0.5, 5), 'detalle', 0xd0d0d0, { x: s * (A / 2 - 0.2), y: h * 0.95 + 0.25 });
  } else {
    // alambrada superior
    for (const s of [-1, 1]) o.add(cilindro(0.03, 0.03, 0.55, 5), 'detalle', 0xc0c0c0, { x: s * (A / 2 - 0.15), y: h + 0.2, rz: s * 0.4 });
    for (let i = 0; i < 3; i++) o.add(caja(A, 0.03, 0.03), 'detalle', 0xbdbdbd, { y: h + 0.16 + i * 0.14, z: 0.1 });
  }
  o.usar('d1');
  o.add(ruina(A, 1.0, h, 1, rng, id));
  o.usar('cuerpo');
  return h + 0.5;
};

/* ----------------------------------------------------------- CIUDADELA 6×6 */
PLANOS.ciudadela = (o, est, rng) => {
  const A = 11.6, L = 11.6, id = est.id;
  const h = id <= 1 ? 6.4 : 6.0;
  obraEnCurso(o, A, L, 14, est, rng);
  // basamento en talud: lo que hace que se vea inexpugnable
  o.add(extruirPerfil([[-A / 2 - 0.9, 0], [A / 2 + 0.9, 0], [A / 2 + 0.2, 1.5], [-A / 2 - 0.2, 1.5]], L + 1.8, 0.06), 'piedra', 0xffffff);
  o.add(cajaBiselada(A + 0.5, 0.3, L + 0.5, 0.06), 'piedra', 0xf0f0f0, { y: 1.6 });
  // muralla
  const yb = 1.75;
  cuerpo(o, A, L, h, est, { filas: 1, colsFrente: 3, colsLado: 3, y: yb, espesor: 0.8, cornisa: false });
  // adarve y almenas
  o.add(cajaBiselada(A + 0.9, 0.4, L + 0.9, 0.06), 'piedra', 0xffffff, { y: yb + h + 0.2 });
  // ERA UNA LOSA MACIZA de 12,6 × 12,6 m en color de bando, o sea ciento sesenta
  // metros cuadrados de un único RGB, y encima es lo primero que ve la cámara
  // cenital de este edificio. La albardilla de un adarve es perimetral: cuatro
  // bandas de sesenta centímetros dibujan el mismo contorno por el 20% del área.
  const wAlb = 0.85, yAlb = yb + h + 0.5;
  for (const s of [-1, 1]) {
    o.add(cajaEn(A + 1.0, 0.22, wAlb, 0, yAlb, s * ((L + 1.0 - wAlb) / 2)), 'jugador', 0xffffff);
    o.add(cajaEn(wAlb, 0.22, L + 1.0 - wAlb * 2, s * ((A + 1.0 - wAlb) / 2), yAlb, 0), 'jugador', 0xffffff);
  }
  const nm = 9;
  for (let i = 0; i < nm; i++) {
    const t = -A / 2 + 0.35 + (i * (A - 0.7)) / (nm - 1);
    for (const s of [-1, 1]) {
      o.add(cajaBiselada(0.62, 0.7, 0.4, 0.04), 'piedra', 0xffffff, { x: t, y: yb + h + 0.95, z: s * (L / 2 + 0.45) });
      o.add(cajaBiselada(0.4, 0.7, 0.62, 0.04), 'piedra', 0xffffff, { x: s * (A / 2 + 0.45), y: yb + h + 0.95, z: t });
    }
  }
  // ménsulas del matacán
  for (let i = 0; i < 12; i++) {
    const t = -A / 2 + 0.5 + (i * (A - 1.0)) / 11;
    for (const s of [-1, 1]) {
      o.add(extruirPerfil([[0, 0], [0.34, 0.34], [0, 0.34]], 0.28, 0.02), 'piedra', 0xf4f4f4, { x: t, y: yb + h - 0.34, z: s * (L / 2 + 0.14), rx: 0, ry: s > 0 ? 0 : Math.PI });
    }
  }
  // cuatro torreones
  let top = yb + h + 1.7;
  const ht = h + (id <= 1 ? 3.4 : 2.8);
  for (const sx of [-1, 1]) for (const sz of [-1, 1]) {
    o.add(torre(1.5, ht, id), null, 0xffffff, { x: sx * (A / 2 - 0.2), y: yb - 0.1, z: sz * (L / 2 - 0.2) });
  }
  top = Math.max(top, yb + ht + 2.6);
  // torre del homenaje / núcleo
  const hn = h + (id <= 1 ? 4.6 : 4.0);
  cuerpo(o, A * 0.42, L * 0.42, hn, est, { filas: 2, colsFrente: 2, colsLado: 2, y: yb, espesor: 0.6, zocalo: false });
  const yn = yb + hn;
  if (id <= 1) {
    o.add(cajaBiselada(A * 0.48, 0.35, L * 0.48, 0.05), 'piedra', 0xffffff, { y: yn + 0.17 });
    for (let i = 0; i < 6; i++) {
      const t = -A * 0.21 + (i * (A * 0.42)) / 5;
      for (const s of [-1, 1]) {
        o.add(cajaEn(0.42, 0.55, 0.3, t, yn + 0.62, s * (L * 0.24)), 'piedra', 0xffffff);
        o.add(cajaEn(0.3, 0.55, 0.42, s * (A * 0.24), yn + 0.62, t), 'piedra', 0xffffff);
      }
    }
    // la cúpula es piedra; el bando va al tambor y a la linterna, no al casquete
    o.add(cupula(A * 0.2, A * 0.22, 8, { ranura: 'techo' }), null, 0xffffff, { y: yn + 0.9 });
    o.add(cilindro(A * 0.21, A * 0.21, 0.34, 16), 'jugador', 0xffffff, { y: yn + 0.9 });
    top = Math.max(top, yn + A * 0.22 + 2.2);
  } else if (id === 2) {
    o.add(techoPlanoConPretil(A * 0.46, L * 0.46, 0.7), null, 0xffffff, { y: yn });
    o.add(parabolica(1.3), null, 0xffffff, { x: -0.6, y: yn + 0.4, z: 0.6, ry: -0.7 });
    o.add(antena(3.2, 'mastil'), null, 0xffffff, { x: 1.2, y: yn + 0.4, z: -0.8 });
    top = Math.max(top, yn + 3.8);
  } else {
    o.add(cupula(A * 0.2, A * 0.16, 10, { ranura: 'muro' }), null, 0xffffff, { y: yn });
    o.add(toro(A * 0.2, 0.06, 4, 22), 'emisivo', id === 4 ? 0xb48bff : 0x66e6ff, { y: yn + A * 0.09, rx: Math.PI / 2 });
    o.add(antena(2.4, 'sensor'), null, 0xffffff, { y: yn + A * 0.16 });
    top = Math.max(top, yn + A * 0.16 + 2.6);
  }
  // portada fortificada
  o.add(cajaBiselada(4.2, 4.6, 1.6, 0.07), 'piedra', 0xffffff, { y: yb + 2.3, z: L / 2 + 0.5 });
  o.add(cajaEn(2.2, 3.0, 0.6, 0, yb + 1.5, L / 2 + 1.15), 'detalle', id <= 1 ? 0x5a4230 : 0x8a8f92);
  o.add(cajaEn(2.55, 0.3, 0.75, 0, yb + 3.1, L / 2 + 1.2), 'jugador', 0xffffff);
  for (const s of [-1, 1]) o.add(cajaEn(0.3, 3.1, 0.75, s * 1.28, yb + 1.55, L / 2 + 1.2), 'jugador', 0xffffff);
  if (id <= 1) for (let i = 0; i < 6; i++) o.add(cilindro(0.06, 0.06, 3.0, 5), 'detalle', 0xb0b0b0, { x: -0.95 + i * 0.38, y: yb + 1.55, z: L / 2 + 1.35 });
  o.add(escalera(4.6, yb, 5, { huella: 0.55 }), null, 0xffffff, { z: L / 2 + 4.2, ry: Math.PI });
  o.puntos.puerta = new THREE.Vector3(0, 0, L / 2 + 4.6);
  // cañón principal
  const yc = yb + h + 1.2;
  o.add(cajaBiselada(1.5, 0.7, 1.7, 0.06), 'detalle', 0xffffff, { y: yc, z: L / 2 - 0.4 });
  o.add(cilindro(0.2, 0.26, 3.0, 12).rotateX(Math.PI / 2), 'detalle', 0xdcdcdc, { y: yc + 0.3, z: L / 2 + 1.3, rx: -0.1 });
  o.add(cajaEn(1.7, 0.9, 0.16, 0, yc + 0.28, L / 2 + 0.5), 'jugador', 0xffffff);
  o.puntos.canon = new THREE.Vector3(0, yc + 0.3, L / 2 + 2.8);
  banderasEdad(o, A, L, yb + h + 0.6, est, 2, { alto: 4.6, z: L / 2 - 0.3 });
  banderasEdad(o, A * 0.5, L, yb + h + 0.6, est, 2, { alto: 4.0, z: -L / 2 + 0.3 });
  entornoEdad(o, A, L, est, rng, { cartel: 'CIUDADELA' });
  danios(o, A, L, top, est, rng);
  return top;
};

/* ----------------------------------------------------------- INSTITUTO 4×4 */
PLANOS.instituto = (o, est, rng) => {
  const A = 7.6, L = 7.6, id = est.id;
  const h = id <= 1 ? 4.6 : 4.2;
  obraEnCurso(o, A, L, h + 3, est, rng);
  cuerpo(o, A, L, h, est, { filas: id <= 1 ? 2 : 1, colsFrente: 4, colsLado: 4 });
  let top = techoPorEdad(o, A, L, h, est, { pendiente: 0.5, buhardilla: false, pretil: 0.7 });
  // pórtico de acceso con columnas
  if (id <= 2) {
    for (let i = 0; i < 4; i++) o.add(columna(0.24, h * 0.72, id), 'piedra', 0xffffff, { x: (i - 1.5) * 1.35, z: L / 2 + 1.0 });
    o.add(cajaBiselada(5.0, 0.4, 1.6, 0.05), 'piedra', 0xf6f6f6, { y: h * 0.72 + 0.2, z: L / 2 + 1.0 });
    o.add(extruirPerfil([[-2.5, 0], [0, 0.85], [2.5, 0]], 1.5, 0.03), 'jugador', 0xffffff, { y: h * 0.72 + 0.4, z: L / 2 + 1.0 });
  } else {
    o.add(cajaBiselada(5.4, 0.3, 2.4, 0.07), 'muro', 0xffffff, { y: h * 0.7, z: L / 2 + 1.2 });
    o.add(cajaEn(5.0, 0.07, 0.12, 0, h * 0.7 - 0.22, L / 2 + 2.3), 'emisivo', id === 4 ? 0xb48bff : 0x66e6ff);
    for (const s of [-1, 1]) o.add(cilindro(0.1, 0.13, h * 0.7, 10), 'detalle', 0xe0e0e0, { x: s * 2.4, y: h * 0.35, z: L / 2 + 2.2 });
  }
  puertaEdad(o, A, L, est, { ancho: 1.8, alto: 2.7 });
  // observatorio: cúpula giratoria con tronera
  const rc = 1.55;
  o.add(cilindro(rc + 0.15, rc + 0.3, 1.0, 16), 'muro', 0xffffff, { x: -A * 0.2, y: top + 0.5, z: -L * 0.18 });
  // casquete de material y anillo de bando abajo: el bando marca, no cubre
  o.add(cupula(rc, rc * 0.85, id <= 1 ? 8 : 6, { ranura: id >= 3 ? 'muro' : 'techo' }), null, 0xffffff, { x: -A * 0.2, y: top + 1.0, z: -L * 0.18 });
  o.add(cilindro(rc + 0.08, rc + 0.08, 0.28, 16), 'jugador', 0xffffff, { x: -A * 0.2, y: top + 1.02, z: -L * 0.18 });
  o.add(cajaEn(0.55, rc * 1.5, 0.2, -A * 0.2, top + 1.6, -L * 0.18 + rc * 0.92), 'detalle', 0x2a2622);
  o.add(cilindro(0.14, 0.2, 1.9, 10), 'detalle', 0xdcdcdc, { x: -A * 0.2, y: top + 1.8, z: -L * 0.18 + 0.35, rx: -0.75 });
  top = Math.max(top, top + 1.0 + rc * 0.85 + 0.9);
  // pizarrón / cartel y biblioteca
  if (id === 0) {
    o.add(cartel(2.2, 0.7, 'INSTITUTO', 0), null, 0xffffff, { y: h * 0.72 + 1.1, z: L / 2 + 1.05 });
    o.add(farol(2.4, 0), null, 0xffffff, { x: -A / 2 - 0.6, z: L / 2 + 0.5 });
  } else if (id === 1) {
    o.add(cartel(2.6, 0.8, 'INSTITUTO', 1), null, 0xffffff, { y: h + 0.5, z: L / 2 - 0.02 });
    o.add(parabolica(0.85), null, 0xffffff, { x: A * 0.26, y: top - 2.4, z: L * 0.2, ry: 0.5 });
  } else {
    o.add(cartel(3.0, 0.8, 'INSTITUTO', id), null, 0xffffff, { y: h + 0.7, z: L / 2 - 0.02 });
    o.add(parabolica(1.05), null, 0xffffff, { x: A * 0.26, y: h + 0.9, z: L * 0.2, ry: 0.55 });
  }
  remateEdad(o, A, L, h + 0.9, est, rng, { chimeneas: 1 });
  banderasEdad(o, A, L, 0, est, 2, { alto: 4.2, z: L / 2 + 1.9 });
  entornoEdad(o, A, L, est, rng, { cartel: 'CIENCIA' });
  danios(o, A, L, top, est, rng);
  return top;
};

/* ---------------------------------------------------------- MINISTERIO 4×4 */
PLANOS.ministerio = (o, est, rng) => {
  const A = 7.6, L = 7.6, id = est.id;
  const h = 4.2;
  obraEnCurso(o, A, L, h + 5, est, rng);
  cuerpo(o, A, L, h, est, { filas: 1, colsFrente: 4, colsLado: 4 });
  // torre escalonada art déco en el centro
  const pisos = [[A * 0.6, 3.4], [A * 0.42, 3.0], [A * 0.28, 2.4]];
  let y = h, top = h;
  for (let i = 0; i < pisos.length; i++) {
    const [w, hp] = pisos[i];
    o.add(cajaBiselada(w + 0.55, 0.3, w + 0.55, 0.05), 'piedra', 0xf6f6f6, { y: y + 0.15 });
    // faja sobre la cornisa de cada retranqueo: es lo que encadena los tres
    // cuerpos en una sola torre y de paso reparte el bando en altura
    o.add(cajaEn(w + 0.62, 0.13, w + 0.62, 0, y + 0.36, 0), 'jugador', 0xffffff);
    cuerpo(o, w, w, hp, est, { filas: 1, colsFrente: 2, colsLado: 2, espesor: 0.34, y: y + 0.3, zocalo: false, pilastras: false });
    // Nervaduras verticales: la firma déco. Iban en color de bando y son cinco
    // por cara, cuatro caras, tres pisos: sesenta barras de tres metros del mismo
    // RGB envolviendo la torre entera. El informe habla de "faldones enteros";
    // esto era lo mismo pero en vertical. Van en metal pintado (el bronce déco) y
    // el bando de esta torre queda en el remate, los estandartes y la puerta.
    const nn = 5;
    for (let k = 0; k < nn; k++) {
      const t = -w / 2 + 0.25 + (k * (w - 0.5)) / (nn - 1);
      for (const s of [-1, 1]) {
        o.add(cajaBiselada(0.16, hp, 0.22, 0.02), 'detalle', 0xd8c8a0, { x: t, y: y + 0.3 + hp / 2, z: s * (w / 2 + 0.06) });
        o.add(cajaBiselada(0.22, hp, 0.16, 0.02), 'detalle', 0xd8c8a0, { x: s * (w / 2 + 0.06), y: y + 0.3 + hp / 2, z: t });
      }
    }
    y += 0.3 + hp;
    top = y;
  }
  o.add(cajaBiselada(A * 0.3, 0.4, A * 0.3, 0.05), 'jugador', 0xffffff, { y: top + 0.2 });
  o.add(cilindro(0.08, 0.28, 2.6, 8), 'detalle', 0xf0f0f0, { y: top + 1.7 });
  o.add(esfera(0.16, 8), 'emisivo', id >= 3 ? 0x66e6ff : 0xffd070, { y: top + 3.05 });
  top += 3.2;
  puertaEdad(o, A, L, est, { ancho: 2.2, alto: 3.0 });
  // altavoces / pantallas de propaganda
  const yA = h + 0.6;
  for (const s of [-1, 1]) {
    if (id <= 2) {
      o.add(cilindro(0.42, 0.16, 0.75, 10).rotateX(-Math.PI / 2), 'detalle', 0xdcdcdc, { x: s * A * 0.34, y: yA, z: L * 0.42 });
      o.add(cilindro(0.06, 0.06, 0.9, 6), 'detalle', 0xcfcfcf, { x: s * A * 0.34, y: yA - 0.5, z: L * 0.42 });
    } else {
      o.add(cajaBiselada(1.5, 0.95, 0.14, 0.03), 'detalle', 0xe0e0e0, { x: s * A * 0.3, y: yA, z: L * 0.46 });
      o.add(cajaEn(1.35, 0.82, 0.06, s * A * 0.3, yA, L * 0.46 + 0.1), 'emisivo', id === 4 ? 0xb48bff : 0x66e6ff);
    }
  }
  o.add(cartel(3.2, 0.9, 'MINISTERIO', id), null, 0xffffff, { y: h + 0.55, z: L / 2 - 0.02 });
  // estandartes colgantes: mucha superficie de color
  for (const s of [-1, 1]) {
    const p = panoOndulado(1.1, 3.4, 0.06, 6, s);
    o.add(p, 'jugador', 0xffffff, { x: s * A * 0.22, y: h - 0.3, z: L / 2 + 0.14 });
    o.add(cajaEn(1.25, 0.1, 0.2, s * A * 0.22, h + 1.42, L / 2 + 0.14), 'detalle', 0xd8d8d8);
  }
  remateEdad(o, A * 0.28, A * 0.28, top - 3.0, est, rng, { chimeneas: 1 });
  banderasEdad(o, A, L, 0, est, 2, { alto: 4.4, z: L / 2 + 1.3 });
  entornoEdad(o, A, L, est, rng, { cartel: 'PRENSA' });
  danios(o, A, L, top, est, rng);
  return top;
};

/* ----------------------------------------------------------- AERODROMO 5×4 */
PLANOS.aerodromo = (o, est, rng) => {
  const A = 9.6, L = 7.6, id = est.id;
  obraEnCurso(o, A, L, 8, est, rng);
  // plataforma de hormigón con señalética pintada
  o.add(cajaBiselada(A + 1.6, 0.22, L + 2.6, 0.06), 'piedra', 0xffffff, { y: 0.11, z: 0.6 });
  const pista = [];
  for (let i = 0; i < 7; i++) pista.push(caja(0.5, 0.04, 1.1).translate(0, 0.24, -L / 2 - 0.6 + i * 1.5));
  o.add(fusionar(pista), 'jugador', 0xffffff, { z: 1.2 });
  for (const s of [-1, 1]) o.add(caja(0.24, 0.04, L + 2.2), 'muro', 0xf0f0f0, { x: s * (A / 2 + 0.55), y: 0.24, z: 0.6 });
  // hangar de bóveda con portón de lamas
  const hh = id <= 2 ? 3.4 : 3.2;
  o.add(muroConVentanas(A, hh, 0.4, 1, 4, id, {}), null, 0xffffff, { z: -(L / 2 - 0.2), ry: Math.PI, y: 0.22 });
  o.add(muroConVentanas(L * 0.8, hh, 0.4, 1, 3, id, {}), null, 0xffffff, { x: A / 2 - 0.2, ry: Math.PI / 2, y: 0.22, z: -L * 0.1 });
  o.add(muroConVentanas(L * 0.8, hh, 0.4, 1, 3, id, {}), null, 0xffffff, { x: -(A / 2 - 0.2), ry: -Math.PI / 2, y: 0.22, z: -L * 0.1 });
  const zf = L * 0.3;
  for (const s of [-1, 1]) o.add(cajaBiselada(1.6, hh, 0.45, 0.05), 'muro', 0xffffff, { x: s * (A / 2 - 0.8), y: 0.22 + hh / 2, z: zf });
  for (let i = 0; i < 8; i++) o.add(cajaEn(A - 3.2, 0.3, 0.22, 0, 0.4 + i * 0.42, zf), 'detalle', 0xc8ccd0);
  o.add(cajaEn(A + 0.2, 0.4, 0.5, 0, 0.22 + hh - 0.2, zf), 'jugador', 0xffffff);
  let top = techoPorEdad(o, A + 0.2, L * 0.82, 0.22 + hh, est, { tipo: 'boveda', alto: id <= 1 ? 2.4 : 2.0 });
  // torre de control
  const ht = 6.4;
  o.add(torre(1.1, ht, Math.max(1, id), { capitel: false }), null, 0xffffff, { x: -A / 2 - 1.2, y: 0.22, z: -L / 2 + 1.2 });
  top = Math.max(top, ht + 1.8);
  // manga de viento
  o.add(cilindro(0.05, 0.07, 3.2, 6), 'detalle', 0xf0f0f0, { x: A / 2 + 1.1, y: 1.8, z: -L / 2 + 0.8 });
  const manga = cilindro(0.34, 0.16, 1.1, 8).rotateZ(Math.PI / 2);
  o.add(manga, 'jugador', 0xffffff, { x: A / 2 + 1.7, y: 3.3, z: -L / 2 + 0.8, ry: 0.4 });
  // helipuerto y balizas
  o.add(disco(2.1, 0.06, 22), 'muro', 0xf4f4f4, { x: 0, y: 0.26, z: L / 2 + 1.8 });
  o.add(toro(1.75, 0.07, 4, 24), 'jugador', 0xffffff, { x: 0, y: 0.3, z: L / 2 + 1.8, rx: Math.PI / 2 });
  o.add(textoBarras('H', 1.5, 0.05).rotateX(-Math.PI / 2), 'jugador', 0xffffff, { y: 0.31, z: L / 2 + 2.55 });
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * TAU;
    o.add(esfera(0.09, 6), 'emisivo', id >= 3 ? 0x66e6ff : 0xffd070, { x: Math.cos(a) * 2.2, y: 0.34, z: L / 2 + 1.8 + Math.sin(a) * 2.2 });
    o.luzEn(Math.cos(a) * 2.2, 0.34, L / 2 + 1.8 + Math.sin(a) * 2.2);
  }
  // aparato estacionado
  if (id === 3) {
    o.add(cajaBiselada(0.6, 0.28, 2.2, 0.06), 'detalle', 0xdadada, { x: A * 0.28, y: 0.9, z: -L * 0.05 });
    for (const s of [-1, 1]) {
      o.add(cajaEn(2.4, 0.08, 0.35, A * 0.28, 0.95, -L * 0.05 + s * 0.7), 'detalle', 0xe4e4e4);
      for (const t of [-1, 1]) o.add(toro(0.28, 0.05, 4, 10), 'detalle', 0xcfcfcf, { x: A * 0.28 + s * 1.05, y: 0.95, z: -L * 0.05 + t * 0.7, rx: Math.PI / 2 });
    }
    o.add(cilindro(0.1, 0.1, 0.5, 6), 'detalle', 0xd0d0d0, { x: A * 0.28, y: 0.62, z: -L * 0.05 });
  } else if (id === 4) {
    o.add(esfera(0.75, 12), 'muro', 0xffffff, { x: A * 0.28, y: 1.2, z: -L * 0.05, sy: 0.55 });
    o.add(toro(1.0, 0.06, 4, 18), 'emisivo', 0xb48bff, { x: A * 0.28, y: 1.1, z: -L * 0.05, rx: Math.PI / 2 });
  } else {
    o.add(cajaBiselada(0.7, 0.6, 3.0, 0.06), 'detalle', 0xd8d8d8, { x: A * 0.28, y: 0.8, z: -L * 0.05 });
    o.add(cajaEn(4.2, 0.1, 0.7, A * 0.28, 0.95, -L * 0.05), 'detalle', 0xdcdcdc);
    o.add(cilindro(0.3, 0.16, 0.3, 10).rotateX(Math.PI / 2), 'detalle', 0xcfcfcf, { x: A * 0.28, y: 0.8, z: -L * 0.05 - 1.6 });
  }
  o.add(cartel(2.8, 0.8, 'AERO', id), null, 0xffffff, { y: 0.22 + hh + 0.5, z: zf + 0.05 });
  remateEdad(o, A * 0.6, L * 0.5, 0.22 + hh + 0.2, est, rng, { chimeneas: 1 });
  banderasEdad(o, A, L, 0, est, 2, { alto: 4.0, z: -L / 2 - 0.4 });
  o.puntos.puerta = new THREE.Vector3(0, 0, zf + 1.2);
  danios(o, A, L, top, est, rng);
  return top;
};

/* ------------------------------------------------------------- CENTRAL 4×4 */
PLANOS.central = (o, est, rng) => {
  const A = 7.6, L = 7.6, id = est.id;
  const h = 3.6;
  obraEnCurso(o, A, L, h + 4, est, rng);
  cuerpo(o, A, L * 0.62, h, est, { filas: 1, colsFrente: 4, colsLado: 2 });
  let top = techoPorEdad(o, A, L * 0.62, h, est, { tipo: id === 1 ? 'sierra' : est.techo, dientes: 3, pendiente: 0.4, buhardilla: false });
  // el corazón: calderas, reactor o fusión según la edad
  if (id <= 1) {
    for (let i = 0; i < 2; i++) {
      const x = (i - 0.5) * 3.0;
      o.add(cilindro(0.95, 0.95, 3.2, 14).rotateZ(Math.PI / 2), 'muro', 0xffffff, { x, y: 1.4, z: L * 0.3, ry: Math.PI / 2 });
      o.add(toro(0.98, 0.07, 4, 16), 'detalle', 0xcfa07a, { x, y: 1.4, z: L * 0.3 + 1.1, rx: Math.PI / 2, ry: Math.PI / 2 });
      o.add(cilindro(0.5, 0.5, 0.28, 12).rotateX(Math.PI / 2), 'emisivo', 0xff7a22, { x, y: 1.4, z: L * 0.3 + 1.62 });
    }
    const hc = 4.6;
    o.add(chimenea(hc, 0.7, id), null, 0xffffff, { x: -A * 0.3, y: top - 0.4, z: -L * 0.16 });
    o.chimeneaEn(-A * 0.3, top - 0.4 + hc, -L * 0.16);
    o.add(chimenea(hc * 0.8, 0.6, id), null, 0xffffff, { x: A * 0.3, y: top - 0.4, z: -L * 0.16 });
    o.chimeneaEn(A * 0.3, top - 0.4 + hc * 0.8, -L * 0.16);
    top = top - 0.4 + hc;
  } else if (id === 2) {
    // cúpula de reactor y torre de refrigeración
    o.add(cilindro(2.1, 2.3, 2.2, 18), 'muro', 0xffffff, { x: -A * 0.16, y: 1.1, z: L * 0.32 });
    o.add(cupula(2.1, 1.7, 8, { ranura: 'muro' }), null, 0xffffff, { x: -A * 0.16, y: 2.2, z: L * 0.32 });
    // sin rx era un aro VERTICAL de 4,3 m de diámetro clavado en la cúpula
    o.add(toro(2.15, 0.09, 4, 20), 'jugador', 0xffffff, { x: -A * 0.16, y: 2.25, z: L * 0.32, rx: Math.PI / 2 });
    o.add(chimenea(4.2, 1.1, 2), null, 0xffffff, { x: A * 0.32, y: 0, z: -L * 0.28 });
    o.chimeneaEn(A * 0.32, 4.2, -L * 0.28);
    top = Math.max(top, 4.6);
  } else if (id === 3) {
    o.add(cilindro(1.9, 2.1, 2.6, 16), 'muro', 0xffffff, { x: -A * 0.16, y: 1.3, z: L * 0.32 });
    o.add(toro(2.0, 0.07, 4, 20), 'emisivo', 0x66e6ff, { x: -A * 0.16, y: 2.3, z: L * 0.32, rx: Math.PI / 2 });
    o.add(cilindro(1.55, 1.9, 0.5, 16), 'jugador', 0xffffff, { x: -A * 0.16, y: 2.85, z: L * 0.32 });
    o.add(panelSolar(3.2, 1.8, 0.55), null, 0xffffff, { x: A * 0.22, y: top, z: -L * 0.1 });
    o.add(panelSolar(3.2, 1.8, 0.55), null, 0xffffff, { x: A * 0.22, y: top, z: L * 0.18 });
    o.chimeneaEn(-A * 0.16, 3.2, L * 0.32);
    top = Math.max(top, 4.0);
  } else {
    // toroide de fusión levitando
    o.add(cilindro(1.6, 2.0, 0.6, 18), 'muro', 0xffffff, { x: -A * 0.1, y: 0.3, z: L * 0.28 });
    o.add(toro(1.55, 0.42, 8, 24), 'muro', 0xffffff, { x: -A * 0.1, y: 2.6, z: L * 0.28, rx: Math.PI / 2 });
    o.add(toro(1.55, 0.14, 6, 24), 'emisivo', 0xd8a0ff, { x: -A * 0.1, y: 2.6, z: L * 0.28, rx: Math.PI / 2 });
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * TAU;
      o.add(cajaBiselada(0.24, 1.6, 0.5, 0.04), 'detalle', 0xe0e0e0, { x: -A * 0.1 + Math.cos(a) * 1.55, y: 1.5, z: L * 0.28 + Math.sin(a) * 1.55, ry: -a });
    }
    o.chimeneaEn(-A * 0.1, 3.4, L * 0.28);
    top = Math.max(top, 4.2);
  }
  // transformadores, torre de línea y cables
  for (let i = 0; i < 3; i++) {
    const x = -A / 2 + 0.9 + i * 1.4;
    o.add(cajaBiselada(1.0, 1.2, 0.9, 0.05), 'detalle', 0xc8ccc0, { x, y: 0.6, z: -L / 2 - 0.9 });
    for (let k = 0; k < 3; k++) o.add(cilindro(0.12, 0.14, 0.5, 8), 'vidrio', 0xd8e0d0, { x: x - 0.3 + k * 0.3, y: 1.45, z: -L / 2 - 0.9 });
    o.add(toro(0.14, 0.04, 4, 10), 'detalle', 0xb0b0b0, { x, y: 1.75, z: -L / 2 - 0.9, rx: Math.PI / 2 });
  }
  const hp = 6.2;
  o.add(antena(hp, 'mastil'), null, 0xffffff, { x: A / 2 + 1.1, z: -L / 2 - 0.6 });
  for (let i = 0; i < 3; i++) {
    o.add(cable([A / 2 + 1.1, hp - 0.4 - i * 0.5, -L / 2 - 0.6], [-A / 2 + 0.9 + i * 1.4, 1.75, -L / 2 - 0.9], 0.5), 'detalle', 0x9a9a9a);
  }
  top = Math.max(top, hp);
  o.add(cartel(2.6, 0.8, 'ENERGIA', id), null, 0xffffff, { y: h + 0.55, z: L * 0.31 + 0.05 });
  banderasEdad(o, A, L, 0, est, 1, { alto: 3.6, z: L * 0.31 + 0.6 });
  entornoEdad(o, A, L, est, rng, { cartel: 'ENERGIA' });
  o.puntos.puerta = new THREE.Vector3(0, 0, L * 0.31 + 1.0);
  danios(o, A, L, top, est, rng);
  return top;
};

/* ============================ MARAVILLA 8×8 ================================
   Una por edad, y cada una tiene que aguantar cinco minutos de mirada fija.
   ========================================================================= */

/** 1800 · Palacio de Cristal: nave de hierro y vidrio con crucero y fuente. */
function maravillaCristal(o, est, rng) {
  const A = 15.4, L = 15.4;
  o.add(cajaBiselada(A + 1.4, 0.55, L + 1.4, 0.09), 'piedra', 0xffffff, { y: 0.27 });
  o.add(cajaBiselada(A + 0.4, 0.3, L + 0.4, 0.06), 'piedra', 0xf2f2f2, { y: 0.68 });
  const hb = 5.4;
  // nave longitudinal: tres crujías de vidrio entre pies derechos de fundición
  for (const s of [-1, 1]) {
    for (let i = 0; i < 7; i++) {
      const z = -L / 2 + 1.1 + i * ((L - 2.2) / 6);
      o.add(columna(0.28, hb, 0), 'detalle', 0xf0f0f0, { x: s * (A / 2 - 0.6), y: 0.83, z });
      o.add(cajaEn(0.3, hb - 1.0, 2.0, s * (A / 2 - 0.6), 0.83 + hb / 2, z + 1.1), 'vidrio', 0xdff0f6);
      if (i < 6) {
        const arco = [];
        for (let k = 0; k <= 8; k++) { const a = Math.PI * (k / 8); arco.push([0, Math.sin(a) * 0.55, -Math.cos(a) * ((L - 2.2) / 12)]); }
        o.add(tuboPor(arco, 0.05, 4), 'detalle', 0xe4e4e4, { x: s * (A / 2 - 0.6), y: 0.83 + hb - 0.2, z: z + (L - 2.2) / 12 });
      }
    }
    o.add(cajaEn(0.55, 0.5, L - 1.0, s * (A / 2 - 0.6), 0.83 + hb, 0), 'jugador', 0xffffff);
  }
  for (const s of [-1, 1]) {
    for (let i = 0; i < 7; i++) {
      const x = -A / 2 + 1.1 + i * ((A - 2.2) / 6);
      o.add(columna(0.28, hb, 0), 'detalle', 0xf0f0f0, { x, y: 0.83, z: s * (L / 2 - 0.6) });
      o.add(cajaEn(2.0, hb - 1.0, 0.3, x + 1.1, 0.83 + hb / 2, s * (L / 2 - 0.6)), 'vidrio', 0xdff0f6);
    }
    o.add(cajaEn(A - 1.0, 0.5, 0.55, 0, 0.83 + hb, s * (L / 2 - 0.6)), 'jugador', 0xffffff);
  }
  // bóveda de cañón central + crucero
  const y0 = 0.83 + hb + 0.25;
  o.add(techoBoveda(A * 0.44, L - 1.2, 2.9, { tinte: 0xffffff }), null, 0xffffff, { y: y0 });
  o.add(techoBoveda(L * 0.44, A - 1.2, 2.9, { tinte: 0xffffff }), null, 0xffffff, { y: y0, ry: Math.PI / 2 });
  // faldones laterales acristalados
  for (const s of [-1, 1]) {
    o.add(cajaBiselada(A * 0.28, 0.14, L - 1.2, 0.03), 'vidrio', 0xdff0f6, { x: s * A * 0.36, y: y0 + 0.55, z: 0, rz: s * -0.34 });
    o.add(cajaBiselada(L * 0.28, 0.14, A - 1.2, 0.03), 'vidrio', 0xdff0f6, { z: s * L * 0.36, y: y0 + 0.55, ry: Math.PI / 2, rz: s * -0.34 });
  }
  // linterna y cúpula de crucero
  o.add(cilindro(2.6, 2.8, 1.1, 20), 'detalle', 0xf0f0f0, { y: y0 + 2.9 });
  for (let i = 0; i < 16; i++) {
    const a = (i / 16) * TAU;
    o.add(cajaEn(0.2, 1.0, 0.2, Math.cos(a) * 2.7, y0 + 3.45, Math.sin(a) * 2.7), 'detalle', 0xe8e8e8);
    o.add(cajaEn(0.5, 0.9, 0.06, Math.cos(a) * 2.72, y0 + 3.45, Math.sin(a) * 2.72), 'vidrio', 0xdff0f6, { ry: -a });
  }
  o.add(cupula(2.7, 2.9, 12, { ranura: 'vidrio', tinte: 0xdff0f6 }), null, 0xffffff, { y: y0 + 4.0 });
  o.add(cilindro(0.06, 0.14, 2.0, 8), 'detalle', 0xf4f4f4, { y: y0 + 7.6 });
  o.add(esfera(0.24, 10), 'emisivo', 0xffd070, { y: y0 + 8.7 });
  // pórtico de entrada con escalinata y fuente
  o.add(cajaBiselada(6.0, 0.45, 2.2, 0.06), 'piedra', 0xffffff, { y: 0.83 + hb - 0.2, z: L / 2 + 0.6 });
  for (let i = 0; i < 4; i++) o.add(columna(0.32, hb - 0.4, 0), 'piedra', 0xffffff, { x: (i - 1.5) * 1.7, y: 0.83, z: L / 2 + 0.6 });
  o.add(extruirPerfil([[-3.0, 0], [0, 1.15], [3.0, 0]], 2.0, 0.04), 'jugador', 0xffffff, { y: 0.83 + hb + 0.25, z: L / 2 + 0.6 });
  o.add(escalera(6.4, 0.83, 4, { huella: 0.5 }), null, 0xffffff, { z: L / 2 + 3.6, ry: Math.PI });
  o.add(cilindro(1.5, 1.7, 0.4, 18), 'piedra', 0xffffff, { y: 0.2, z: L / 2 + 5.2 });
  o.add(cilindro(1.25, 1.25, 0.16, 18), 'vidrio', 0xa8d8e8, { y: 0.42, z: L / 2 + 5.2 });
  o.add(cilindro(0.16, 0.26, 1.3, 10), 'piedra', 0xffffff, { y: 1.0, z: L / 2 + 5.2 });
  o.add(cilindro(0.7, 0.06, 0.22, 14), 'piedra', 0xf6f6f6, { y: 1.6, z: L / 2 + 5.2 });
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * TAU;
    o.add(farol(2.6, 0), null, 0xffffff, { x: Math.cos(a) * (A / 2 + 1.6), z: Math.sin(a) * (L / 2 + 1.6) });
    o.luzEn(Math.cos(a) * (A / 2 + 1.6), 2.7, Math.sin(a) * (L / 2 + 1.6));
  }
  o.chimeneaEn(0, y0 + 6.0, 0);
  return y0 + 8.9;
}

/** 1900 · Torre de acero remachado: cuatro pies, arcos y tres plataformas. */
function maravillaTorre(o, est, rng) {
  const A = 15.4, H = 26.0;
  o.add(cajaBiselada(A + 1.2, 0.5, A + 1.2, 0.08), 'piedra', 0xffffff, { y: 0.25 });
  const R0 = 6.2, R1 = 2.6, R2 = 0.95;
  const nivel = (t) => (t < 0.42 ? lerp(R0, R1, t / 0.42) : lerp(R1, R2, (t - 0.42) / 0.58));
  // cuatro pies curvos
  for (let i = 0; i < 4; i++) {
    const sx = i < 2 ? 1 : -1, sz = i % 2 ? 1 : -1;
    const pts = [];
    for (let k = 0; k <= 8; k++) {
      const t = k / 8, r = nivel(t);
      pts.push([sx * r, 0.5 + t * H, sz * r]);
    }
    o.add(tuboPor(pts, 0.34, 6), 'detalle', 0xffffff);
    o.add(tuboPor(pts.map((p) => [p[0] * 0.82, p[1], p[2] * 0.82]), 0.2, 5), 'detalle', 0xf0f0f0);
  }
  // celosía entre pies
  const cel = [];
  for (let k = 0; k < 22; k++) {
    const t0 = k / 22, t1 = (k + 1) / 22;
    const r0 = nivel(t0), r1 = nivel(t1), y0 = 0.5 + t0 * H, y1 = 0.5 + t1 * H;
    for (let i = 0; i < 4; i++) {
      const a0 = (i / 4) * TAU + Math.PI / 4, a1 = ((i + 1) / 4) * TAU + Math.PI / 4;
      const p0 = [Math.cos(a0) * r0 * 1.41, y0, Math.sin(a0) * r0 * 1.41];
      const p1 = [Math.cos(a1) * r1 * 1.41, y1, Math.sin(a1) * r1 * 1.41];
      const p2 = [Math.cos(a1) * r0 * 1.41, y0, Math.sin(a1) * r0 * 1.41];
      const p3 = [Math.cos(a0) * r1 * 1.41, y1, Math.sin(a0) * r1 * 1.41];
      cel.push(tuboPor([p0, p1], 0.075, 4));
      cel.push(tuboPor([p2, p3], 0.075, 4));
      cel.push(tuboPor([p2, p0], 0.09, 4));
    }
  }
  o.add(fusionar(cel), 'detalle', 0xededed);
  // arcos decorados del primer nivel
  for (let i = 0; i < 4; i++) {
    const a = (i / 4) * TAU + Math.PI / 4;
    const arco = [];
    for (let k = 0; k <= 10; k++) {
      const t = k / 10, ang = Math.PI * t;
      arco.push([Math.cos(a) * 0 + (t - 0.5) * R0 * 2.0, 4.2 + Math.sin(ang) * 2.4, 0]);
    }
    const m = tuboPor(arco, 0.22, 5);
    o.add(m, 'jugador', 0xffffff, { ry: (i / 4) * TAU, z: R0 * 0.98 });
  }
  // plataformas
  const plats = [[0.42, R1 * 1.7], [0.72, 1.9], [1.0, 1.35]];
  let top = 0;
  for (const [t, r] of plats) {
    const y = 0.5 + t * H;
    o.add(cilindro(r, r, 0.3, 4).rotateY(Math.PI / 4), 'muro', 0xffffff, { y });
    o.add(cilindro(r * 1.1, r * 1.1, 0.14, 4).rotateY(Math.PI / 4), 'jugador', 0xffffff, { y: y + 0.2 });
    for (let i = 0; i < 4; i++) {
      o.add(baranda(r * 1.9, 0.95), 'detalle', 0xe8e8e8, { y: y + 0.27, z: r * 0.98, ry: (i / 4) * TAU });
    }
    if (t < 1) {
      o.add(cajaBiselada(r * 0.9, 1.5, r * 0.9, 0.06), 'muro', 0xf2f2f2, { y: y + 1.0 });
      o.add(cajaEn(r * 0.8, 0.9, 0.06, 0, y + 1.05, r * 0.46), 'vidrio', 0xdff0f6);
    }
    top = y;
  }
  // linterna y farola de remate
  o.add(cilindro(0.7, 0.95, 1.6, 12), 'muro', 0xffffff, { y: top + 0.9 });
  o.add(cupula(0.75, 0.7, 8), null, 0xffffff, { y: top + 1.7 });
  o.add(cilindro(0.06, 0.12, 2.6, 8), 'detalle', 0xf4f4f4, { y: top + 3.6 });
  o.add(esfera(0.28, 10), 'emisivo', 0xffd070, { y: top + 5.0 });
  o.add(bandera(3.2, { ancho: 1.5, altoPano: 1.0 }), null, 0xffffff, { y: top + 0.5, x: 1.0 });
  o.banderaEn(1.0, top + 3.7, 0);
  o.chimeneaEn(0, top + 1.2, 0);
  return top + 5.2;
}

/** 1950 · Cohete en su plataforma, con torre de servicio y tanques. */
function maravillaCohete(o, est, rng) {
  const A = 15.4, L = 15.4;
  o.add(cajaBiselada(A, 1.1, L, 0.1), 'muro', 0xffffff, { y: 0.55 });
  o.add(cajaBiselada(A + 1.0, 0.4, L + 1.0, 0.08), 'piedra', 0xf0f0f0, { y: 0.2 });
  // trinchera de llamas
  o.add(cajaEn(3.0, 0.9, L, 0, 0.65, 0), 'muro', 0x4a4640);
  o.add(cajaEn(2.4, 0.1, L - 1.0, 0, 0.16, 0), 'piedra', 0x2e2a26);
  const y0 = 1.1;
  // mesa de lanzamiento
  o.add(cilindro(3.1, 3.4, 0.7, 16), 'muro', 0xffffff, { y: y0 + 0.35 });
  // idem: sin rx, un aro de 6,3 m parado de canto sobre la mesa de lanzamiento
  o.add(toro(3.15, 0.12, 4, 20), 'jugador', 0xffffff, { y: y0 + 0.68, rx: Math.PI / 2 });
  for (let i = 0; i < 4; i++) {
    const a = (i / 4) * TAU + Math.PI / 4;
    o.add(cajaBiselada(0.5, 2.2, 0.5, 0.05), 'detalle', 0xdcdcdc, { x: Math.cos(a) * 2.6, y: y0 + 1.8, z: Math.sin(a) * 2.6 });
  }
  // el cohete
  const yc = y0 + 0.7;
  const H = 16.5, R = 1.35;
  o.add(cilindro(R, R * 1.06, H * 0.62, 20), 'muro', 0xffffff, { y: yc + H * 0.31 });
  o.add(cilindro(R * 0.78, R, H * 0.2, 20), 'muro', 0xffffff, { y: yc + H * 0.72 });
  o.add(cilindro(R * 0.72, R * 0.78, H * 0.1, 20), 'jugador', 0xffffff, { y: yc + H * 0.87 });
  const ojiva = [];
  for (let i = 0; i <= 10; i++) { const t = i / 10; ojiva.push([R * 0.72 * Math.cos(t * Math.PI * 0.5), t * H * 0.14]); }
  o.add(revolucion(ojiva, 20), 'muro', 0xffffff, { y: yc + H * 0.92 });
  o.add(cilindro(0.02, 0.09, 1.4, 8), 'detalle', 0xe8e8e8, { y: yc + H * 1.06 + 0.7 });
  // bandas y remaches
  for (let i = 1; i < 6; i++) o.add(toro(R * 1.02, 0.07, 4, 22), 'detalle', 0xdcdcdc, { y: yc + (H * 0.62 * i) / 6, rx: Math.PI / 2 });
  for (let i = 0; i < 4; i++) {
    const a = (i / 4) * TAU;
    o.add(cajaEn(0.5, H * 0.35, 0.14, Math.cos(a) * R * 1.02, yc + H * 0.3, Math.sin(a) * R * 1.02), 'detalle', 0xd8d8d8, { ry: -a });
  }
  o.add(textoBarras('01', 1.1, 0.06), 'jugador', 0xffffff, { y: yc + H * 0.72, z: R * 1.04 });
  // aletas
  for (let i = 0; i < 4; i++) {
    const a = (i / 4) * TAU + Math.PI / 4;
    const aleta = extruirPerfil([[0, 0], [2.0, 0], [0.15, 3.4]], 0.18, 0.03);
    o.add(aleta, 'jugador', 0xffffff, { x: Math.cos(a) * R * 0.9, y: yc + 0.05, z: Math.sin(a) * R * 0.9, ry: -a + Math.PI / 2 });
  }
  // toberas
  for (let i = 0; i < 4; i++) {
    const a = (i / 4) * TAU;
    o.add(cilindro(0.28, 0.52, 0.9, 12), 'detalle', 0x8a8a8a, { x: Math.cos(a) * 0.55, y: yc - 0.35, z: Math.sin(a) * 0.55 });
  }
  o.chimeneaEn(0, yc - 0.6, 0);
  // torre de servicio con brazos y ascensor
  const xt = -5.2, ht = H * 0.95;
  for (const sx of [-1, 1]) for (const sz of [-1, 1]) {
    o.add(cilindro(0.16, 0.2, ht, 8), 'detalle', 0xf0f0f0, { x: xt + sx * 1.1, y: y0 + ht / 2, z: sz * 1.1 });
  }
  for (let k = 1; k <= 12; k++) {
    const y = y0 + (ht * k) / 12;
    o.add(caja(2.4, 0.12, 0.12), 'detalle', 0xe4e4e4, { x: xt, y, z: 1.1 });
    o.add(caja(2.4, 0.12, 0.12), 'detalle', 0xe4e4e4, { x: xt, y, z: -1.1 });
    o.add(caja(0.12, 0.12, 2.4), 'detalle', 0xe4e4e4, { x: xt + 1.1, y, z: 0 });
    o.add(caja(0.12, 0.12, 2.4), 'detalle', 0xe4e4e4, { x: xt - 1.1, y, z: 0 });
    if (k % 3 === 0) {
      o.add(cajaBiselada(3.4, 0.22, 1.6, 0.04), 'detalle', 0xdcdcdc, { x: xt + 2.3, y: y + 0.1, z: 0 });
      o.add(baranda(3.2, 0.9), 'detalle', 0xdcdcdc, { x: xt + 2.3, y: y + 0.2, z: 0.75 });
    }
  }
  o.add(cajaBiselada(1.3, 1.6, 1.3, 0.05), 'detalle', 0xdcdcdc, { x: xt - 1.4, y: y0 + ht * 0.5, z: 0 });
  o.add(antena(3.0, 'mastil'), null, 0xffffff, { x: xt, y: y0 + ht });
  // tanques criogénicos y sala de control
  for (let i = 0; i < 2; i++) {
    o.add(silo(1.15, 4.4), null, 0xffffff, { x: 5.6, z: -3.0 + i * 4.2 });
  }
  o.add(cajaBiselada(4.0, 2.2, 3.0, 0.08), 'muro', 0xffffff, { x: 5.0, y: y0 + 1.1, z: L / 2 + 1.6 });
  o.add(cajaEn(3.6, 0.9, 0.1, 5.0, y0 + 1.5, L / 2 + 3.15), 'vidrio', 0xd8e6e2);
  o.add(cajaBiselada(4.4, 0.3, 3.4, 0.05), 'jugador', 0xffffff, { x: 5.0, y: y0 + 2.35, z: L / 2 + 1.6 });
  o.add(parabolica(1.2), null, 0xffffff, { x: 5.0, y: y0 + 2.5, z: L / 2 + 1.6, ry: 0.6 });
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * TAU;
    o.add(farol(3.0, 2), null, 0xffffff, { x: Math.cos(a) * (A / 2 + 1.2), z: Math.sin(a) * (L / 2 + 1.2), ry: -a });
    o.luzEn(Math.cos(a) * (A / 2 + 1.2), 3.1, Math.sin(a) * (L / 2 + 1.2));
  }
  return yc + H * 1.06 + 1.5;
}

/** 2000 · Rascacielos: retranqueos, muro cortina y aguja. */
function maravillaRascacielos(o, est, rng) {
  const A = 15.4, L = 15.4;
  o.add(cajaBiselada(A + 1.6, 0.4, L + 1.6, 0.08), 'piedra', 0xffffff, { y: 0.2 });
  // basamento público con marquesina
  const hb = 4.6;
  cuerpo(o, A * 0.9, L * 0.9, hb, est, { filas: 1, colsFrente: 5, colsLado: 5, y: 0.4 });
  o.add(cajaBiselada(A + 0.8, 0.26, L + 0.8, 0.06), 'muro', 0xffffff, { y: 0.4 + hb + 0.13 });
  o.add(cajaBiselada(A * 0.55, 0.22, 3.2, 0.05), 'muro', 0xffffff, { y: 3.4, z: L * 0.48 });
  o.add(cajaEn(A * 0.5, 0.08, 0.14, 0, 3.2, L * 0.48 + 1.5), 'emisivo', 0x66e6ff);
  // torre con dos retranqueos
  let y = 0.4 + hb + 0.26;
  const cuerpos = [[A * 0.62, 8.2, 4], [A * 0.44, 6.4, 3], [A * 0.3, 4.6, 2]];
  for (const [w, hh, cols] of cuerpos) {
    cuerpo(o, w, w, hh, est, { filas: Math.max(2, Math.round(hh / 3.2)), colsFrente: cols, colsLado: cols, y, espesor: 0.26, zocalo: false, cornisa: false });
    // montantes verticales continuos: lo que hace que se lea "torre" y no "caja"
    const nn = cols + 1;
    for (let k = 0; k < nn; k++) {
      const t = -w / 2 + (k * w) / (nn - 1);
      for (const s of [-1, 1]) {
        o.add(cajaBiselada(0.16, hh, 0.3, 0.02), 'detalle', 0xffffff, { x: t, y: y + hh / 2, z: s * (w / 2 + 0.1) });
        o.add(cajaBiselada(0.3, hh, 0.16, 0.02), 'detalle', 0xffffff, { x: s * (w / 2 + 0.1), y: y + hh / 2, z: t });
      }
    }
    o.add(cajaBiselada(w + 0.5, 0.3, w + 0.5, 0.05), 'jugador', 0xffffff, { y: y + hh + 0.15 });
    y += hh + 0.3;
  }
  // corona: helipuerto, antenas y aguja
  o.add(cilindro(2.2, 2.2, 0.14, 20), 'muro', 0xf0f0f0, { x: 0, y: y + 0.07 });
  o.add(toro(1.8, 0.07, 4, 24), 'jugador', 0xffffff, { y: y + 0.16, rx: Math.PI / 2 });
  o.add(textoBarras('H', 1.4, 0.05).rotateX(-Math.PI / 2), 'jugador', 0xffffff, { y: y + 0.17, z: 0.7 });
  for (let i = 0; i < 4; i++) {
    const a = (i / 4) * TAU + Math.PI / 4;
    o.add(cilindro(0.09, 0.11, 1.6, 8), 'detalle', 0xe0e0e0, { x: Math.cos(a) * 2.0, y: y + 0.8, z: Math.sin(a) * 2.0 });
    o.add(esfera(0.09, 6), 'emisivo', 0xff5a3c, { x: Math.cos(a) * 2.0, y: y + 1.6, z: Math.sin(a) * 2.0 });
  }
  o.add(cilindro(0.5, 0.85, 2.0, 12), 'muro', 0xffffff, { y: y + 1.1 });
  o.add(cilindro(0.06, 0.4, 6.5, 10), 'detalle', 0xf0f0f0, { y: y + 5.3 });
  for (let i = 0; i < 4; i++) o.add(toro(0.28 - i * 0.05, 0.045, 4, 12), 'emisivo', 0x66e6ff, { y: y + 3.4 + i * 1.4, rx: Math.PI / 2 });
  o.add(esfera(0.16, 8), 'emisivo', 0xff5a3c, { y: y + 8.7 });
  // fachada este: paneles solares y jardín en la marquesina
  o.add(panelSolar(4.0, 2.2, 0.5), null, 0xffffff, { x: -A * 0.25, y: 0.4 + hb + 0.3, z: -L * 0.3 });
  o.add(panelSolar(4.0, 2.2, 0.5), null, 0xffffff, { x: A * 0.25, y: 0.4 + hb + 0.3, z: -L * 0.3 });
  for (const s of [-1, 1]) {
    o.add(cajaBiselada(2.6, 0.5, 1.2, 0.06), 'muro', 0xdfe4e8, { x: s * A * 0.34, y: 0.65, z: L / 2 + 1.4 });
    const mata = esfera(0.6, 8); mata.scale(1.6, 0.7, 0.8);
    o.add(mata, 'detalle', 0x5f8f52, { x: s * A * 0.34, y: 1.15, z: L / 2 + 1.4 });
  }
  o.add(cartel(5.0, 1.1, 'IMPERIO', 3), null, 0xffffff, { y: 0.4 + hb - 1.2, z: A * 0.45 + 0.1 });
  o.chimeneaEn(0, y + 1.5, 0);
  o.banderaEn(0, y + 8.9, 0);
  return y + 8.9;
}

/** 2100 · Anillo orbital anclado: el anillo levita sobre tres mástiles. */
function maravillaAnillo(o, est, rng) {
  const A = 15.4;
  o.add(cilindro(7.6, 8.2, 0.7, 28), 'muro', 0xffffff, { y: 0.35 });
  o.add(toro(7.7, 0.14, 5, 30), 'emisivo', 0xb48bff, { y: 0.72, rx: Math.PI / 2 });
  o.add(cilindro(5.4, 5.4, 0.24, 28), 'piedra', 0xffffff, { y: 0.82 });
  // núcleo: prisma continuo con biofachada
  const hn = 7.5;
  const perfilN = [];
  for (let i = 0; i <= 12; i++) {
    const t = i / 12;
    perfilN.push([2.6 * (1 - 0.32 * Math.sin(t * Math.PI * 0.9)), t * hn]);
  }
  o.add(revolucion(perfilN, 22), 'muro', 0xffffff, { y: 0.9 });
  for (let i = 0; i < 5; i++) {
    o.add(toro(2.35 - i * 0.05, 0.04, 4, 24), 'emisivo', 0xb48bff, { y: 1.6 + i * 1.35, rx: Math.PI / 2 });
  }
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * TAU;
    const jardin = esfera(0.65, 8); jardin.scale(1.1, 0.55, 0.9);
    o.add(jardin, 'detalle', 0x5f8f52, { x: Math.cos(a) * 2.2, y: 1.1 + (i % 3) * 2.2, z: Math.sin(a) * 2.2 });
    o.add(cajaEn(1.1, 1.7, 0.1, Math.cos(a) * 2.3, 3.2 + (i % 2) * 1.8, Math.sin(a) * 2.3), 'vidrio', 0xc8b4f0, { ry: -a });
  }
  // tres mástiles de amarre
  const hm = 13.5;
  for (let i = 0; i < 3; i++) {
    const a = (i / 3) * TAU + 0.5;
    const x = Math.cos(a) * 5.4, z = Math.sin(a) * 5.4;
    o.add(cilindro(0.3, 0.72, hm, 12), 'muro', 0xffffff, { x, y: hm / 2 + 0.9, z });
    o.add(toro(0.42, 0.05, 4, 14), 'emisivo', 0xb48bff, { x, y: hm * 0.75, z, rx: Math.PI / 2 });
    o.add(toro(0.52, 0.05, 4, 14), 'emisivo', 0xb48bff, { x, y: hm * 0.45, z, rx: Math.PI / 2 });
    // tirante tensado al anillo
    o.add(tuboPor([[x, hm + 0.9, z], [x * 1.25, hm + 3.4, z * 1.25]], 0.07, 5), 'detalle', 0xe0e0e0);
  }
  // el anillo, levitando
  const yA = hm + 4.4, RA = 7.0;
  o.add(toro(RA, 0.62, 10, 40), 'muro', 0xffffff, { y: yA, rx: Math.PI / 2 });
  o.add(toro(RA, 0.2, 6, 44), 'emisivo', 0xd8a0ff, { y: yA - 0.5, rx: Math.PI / 2 });
  o.add(toro(RA, 0.12, 5, 44), 'jugador', 0xffffff, { y: yA + 0.55, rx: Math.PI / 2 });
  for (let i = 0; i < 12; i++) {
    const a = (i / 12) * TAU;
    o.add(cajaBiselada(1.3, 0.55, 0.85, 0.06), 'jugador', 0xffffff, { x: Math.cos(a) * RA, y: yA + 0.6, z: Math.sin(a) * RA, ry: -a });
    o.add(cajaEn(1.0, 0.24, 0.1, Math.cos(a) * (RA + 0.42), yA + 0.6, Math.sin(a) * (RA + 0.42)), 'emisivo', 0xb48bff, { ry: -a });
  }
  // radios del anillo hacia el cubo suspendido
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * TAU;
    o.add(cajaBiselada(RA - 1.2, 0.16, 0.34, 0.03), 'detalle', 0xffffff, { x: Math.cos(a) * RA * 0.5, y: yA, z: Math.sin(a) * RA * 0.5, ry: -a });
  }
  o.add(esfera(1.35, 16), 'muro', 0xffffff, { y: yA });
  o.add(toro(1.55, 0.07, 4, 22), 'emisivo', 0xd8a0ff, { y: yA, rx: Math.PI / 2 });
  o.add(toro(1.55, 0.07, 4, 22), 'emisivo', 0xd8a0ff, { y: yA, rz: Math.PI / 2 });
  // haz de anclaje
  o.add(cilindro(0.34, 0.6, yA - hn - 1.6, 14), 'emisivo', 0x8a6ad0, { y: (yA + hn + 1.6) / 2 });
  // plaza y accesos
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * TAU + 0.3;
    o.add(farol(2.6, 4), null, 0xffffff, { x: Math.cos(a) * 7.0, z: Math.sin(a) * 7.0 });
    o.luzEn(Math.cos(a) * 7.0, 2.7, Math.sin(a) * 7.0);
  }
  o.add(escalera(4.6, 0.9, 4, { huella: 0.55 }), null, 0xffffff, { z: 8.6, ry: Math.PI });
  o.add(cartel(4.0, 0.9, 'ORBITAL', 4), null, 0xffffff, { y: 4.6, z: 2.55 });
  o.chimeneaEn(0, hn + 1.0, 0);
  o.banderaEn(0, yA + 1.6, 0);
  return yA + 1.8;
}

PLANOS.maravilla = (o, est, rng) => {
  const A = 15.4, L = 15.4, id = est.id;
  obraEnCurso(o, A, L, 18, est, rng);
  let top;
  if (id === 0) top = maravillaCristal(o, est, rng);
  else if (id === 1) top = maravillaTorre(o, est, rng);
  else if (id === 2) top = maravillaCohete(o, est, rng);
  else if (id === 3) top = maravillaRascacielos(o, est, rng);
  else top = maravillaAnillo(o, est, rng);
  banderasEdad(o, A * 0.8, L, 0, est, 2, { alto: 5.4, z: L / 2 + 1.2 });
  o.puntos.puerta = new THREE.Vector3(0, 0, L / 2 + 2.0);
  danios(o, A, L, Math.min(top, 14), est, rng);
  return top;
};

/* ═══════════════════════════════════════════════════════════════════════════
   6. Plan por defecto y compilación cacheada
   ═══════════════════════════════════════════════════════════════════════════ */

/** Si un edificio no tiene plano propio, sale un bloque digno igual. */
function planoGenerico(o, est, rng, def) {
  const cel = (def && def.celdas) || [3, 3];
  const A = cel[0] * CELDA - 0.4, L = cel[1] * CELDA - 0.4;
  const h = est.alturaPiso * (cel[0] >= 5 ? 1.5 : 1.1);
  obraEnCurso(o, A, L, h + 2, est, rng);
  cuerpo(o, A, L, h, est, {});
  const top = techoPorEdad(o, A, L, h, est, {});
  puertaEdad(o, A, L, est, {});
  remateEdad(o, A, L, top, est, rng, {});
  banderasEdad(o, A, L, 0, est, 1, { alto: 3.4, z: L / 2 + 0.5 });
  entornoEdad(o, A, L, est, rng, {});
  danios(o, A, L, top, est, rng);
  return top;
}

const cachePlanes = new Map();
const hashCadena = (s) => {
  let h = 2166136261 >>> 0;
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); }
  return h >>> 0;
};

/**
 * Compila (y cachea) el plan de un edificio: geometrías fusionadas por ranura,
 * puntos de anclaje y altura. Se hace UNA vez por (clave, edad).
 */
function planDe(claveEdificio, edad, ctx) {
  const est = estiloDe(edad);
  const clave = `${claveEdificio}|${est.id}`;
  const hit = cachePlanes.get(clave);
  if (hit) return hit;

  // Determinista y sin consumir el flujo global: derivamos de la semilla de ctx.rng.
  const semillaBase = (ctx && ctx.rng && ctx.rng.semilla) || 1337;
  const rng = new RNG((semillaBase ^ hashCadena(claveEdificio) ^ Math.imul(est.id + 1, 2654435761)) >>> 0);

  let def = null;
  try { def = defEdificio(claveEdificio); } catch (e) { def = null; }
  const o = new Obra(est, rng);
  let alto = 0;
  try {
    const plano = PLANOS[claveEdificio];
    alto = plano ? plano(o, est, rng, def) : planoGenerico(o, est, rng, def);
  } catch (e) {
    console.warn('[EdificioFabrica] falló el plano de', claveEdificio, e);
    try { alto = planoGenerico(new Obra(est, rng), est, rng, def); } catch (e2) { alto = 4; }
  }

  const partes = o.compilar();
  // altura real por caja envolvente (más fiable que lo que devuelve el plano)
  let maxY = 0;
  for (const p of partes.cuerpo) if (p.geo.boundingBox) maxY = Math.max(maxY, p.geo.boundingBox.max.y);
  const cel = (def && def.celdas) || [3, 3];

  const plan = {
    partes,
    altura: Math.max(1.2, maxY || alto || 4),
    ancho: cel[0] * CELDA,
    largo: cel[1] * CELDA,
    puntos: o.puntos,
    est,
  };
  cachePlanes.set(clave, plan);
  return plan;
}

/* ═══════════════════════════════════════════════════════════════════════════
   7. API pública
   ═══════════════════════════════════════════════════════════════════════════ */

/** Andamio suelto (lo usa la vista de obra y el fantasma de emplazado). */
const cacheAndamios = new Map();

export function crearAndamio(celdas, altura, ctx) {
  const c = Array.isArray(celdas) ? celdas : [celdas || 2, celdas || 2];
  const A = Math.max(1.4, (c[0] || 2) * CELDA - 0.3);
  const L = Math.max(1.4, (c[1] || 2) * CELDA - 0.3);
  const h = Math.max(1.4, altura || 3);
  const est = estiloDe(ctx && ctx.edades && ctx.edades.edad ? ctx.edades.edad[ctx.jugadorLocal || 0] : 0);
  const claveCache = `${Math.round(A * 4)}|${Math.round(L * 4)}|${Math.round(h * 2)}|${est.id}`;
  const guardado = cacheAndamios.get(claveCache);
  if (guardado) {
    const g = new THREE.Group();
    g.name = 'andamio';
    for (const p of guardado) {
      const m = new THREE.Mesh(p.geo, materialRanura(ctx, est, p.ranura));
      m.castShadow = true; m.receiveShadow = true;
      g.add(m);
    }
    return g;
  }
  const rng = new RNG(((c[0] * 73856093) ^ (c[1] * 19349663) ^ Math.round(h * 1000)) >>> 0);

  const o = new Obra(est, rng);
  o.add(andamio(A + 0.7, L + 0.7, h + 0.4, est.id));
  o.add(cimientos(A, L, est.id, rng));
  // materiales de obra al pie
  o.add(pilaTroncos(4, rng, { radio: 0.13, largo: 1.4 }), 'detalle', 0xb8865a, { x: A / 2 + 0.9, z: -L * 0.2, ry: 0.3 });
  o.add(cajon(0.6, 0.48, 0.55), 'detalle', 0xc9a678, { x: -A / 2 - 0.8, z: L * 0.25, ry: -0.4 });
  o.add(barril(0.24, 0.6), 'detalle', 0xd0b48a, { x: -A / 2 - 0.85, z: -L * 0.25 });

  const partes = o.compilar();
  const lista = partes.cuerpo.concat(partes.cim);
  cacheAndamios.set(claveCache, lista);
  const grupo = new THREE.Group();
  grupo.name = 'andamio';
  for (const p of lista) {
    const m = new THREE.Mesh(p.geo, materialRanura(ctx, est, p.ranura));
    m.castShadow = true; m.receiveShadow = true;
    grupo.add(m);
  }
  return grupo;
}

/**
 * Crea la representación de un edificio.
 * @returns {{grupo:THREE.Group, altura:number, puntos:object,
 *            setColorJugador:Function, setProgreso:Function,
 *            setDanio:Function, dispose:Function}}
 */
export function crearMallaEdificio(claveEdificio, edad, ctx, opciones = {}) {
  const plan = planDe(claveEdificio, edad, ctx);
  const est = plan.est;
  const hexJugador = opciones.colorJugador != null ? opciones.colorJugador : 0xffffff;

  const grupo = new THREE.Group();
  grupo.name = `edificio_${claveEdificio}`;

  const nCuerpo = new THREE.Group(); nCuerpo.name = 'cuerpo';
  const nCim = new THREE.Group(); nCim.name = 'cimientos';
  const nD1 = new THREE.Group(); nD1.name = 'danio1'; nD1.visible = false;
  const nD2 = new THREE.Group(); nD2.name = 'danio2'; nD2.visible = false;
  const nFuego = new THREE.Group(); nFuego.name = 'fuego'; nFuego.visible = false;
  const nAndamio = new THREE.Group(); nAndamio.name = 'andamios'; nAndamio.visible = false;

  const mallasJugador = [];
  const armar = (destino, partes, sombra = true) => {
    for (const p of partes) {
      const mat = materialRanura(ctx, est, p.ranura, p.ranura === 'jugador' ? hexJugador : 0xffffff);
      const m = new THREE.Mesh(p.geo, mat);
      m.name = p.ranura === 'jugador' ? `jugador_${p.ranura}` : `edif_${p.ranura}`;
      m.castShadow = sombra && p.ranura !== 'emisivo';
      m.receiveShadow = sombra;
      if (p.ranura === 'jugador') { m.userData.colorJugador = true; mallasJugador.push(m); }
      destino.add(m);
    }
  };
  armar(nCuerpo, plan.partes.cuerpo);
  armar(nCim, plan.partes.cim);
  nCim.visible = false;   // sólo se ven mientras hay obra
  armar(nD1, plan.partes.d1, false);
  armar(nD2, plan.partes.d2, false);
  armar(nFuego, plan.partes.fuego, false);
  nCuerpo.add(nD1, nD2, nFuego);

  // marcadores de humo en las chimeneas (los usa Efectos.humoContinuo)
  const marcadores = [];
  for (const c of plan.puntos.chimeneas) {
    const n = new THREE.Object3D();
    n.name = 'chimenea';
    n.position.copy(c);
    nCuerpo.add(n);
    marcadores.push(n);
  }

  grupo.add(nCim, nCuerpo, nAndamio);

  let progreso = 1, danio = 0, humoActual = -1, andamioListo = false;

  const api = {
    grupo,
    altura: plan.altura,
    ancho: plan.ancho,
    largo: plan.largo,
    edad: est.id,
    puntos: {
      puerta: plan.puntos.puerta ? plan.puntos.puerta.clone() : new THREE.Vector3(0, 0, plan.largo / 2),
      chimeneas: plan.puntos.chimeneas.map((v) => v.clone()),
      banderas: plan.puntos.banderas.map((v) => v.clone()),
      luces: plan.puntos.luces.map((v) => v.clone()),
      canon: plan.puntos.canon ? plan.puntos.canon.clone() : null,
    },

    /** Cambia el material de las zonas de color de jugador (cacheado por color). */
    setColorJugador(hex) {
      if (hex == null) return;
      const mat = materialRanura(ctx, est, 'jugador', hex);
      for (const m of mallasJugador) m.material = mat;
    },

    /** 0 = cimientos y andamios; el edificio crece en Y hasta 1. */
    setProgreso(t) {
      const p = clamp(t, 0, 1);
      if (Math.abs(p - progreso) < 0.004) return;
      progreso = p;
      nCuerpo.visible = p > 0.015;
      nCuerpo.scale.set(1, Math.max(0.02, 0.05 + 0.95 * p), 1);
      const enObra = p < 0.995;
      nCim.visible = enObra;
      if (enObra && !andamioListo) {
        // el andamio se arma la primera vez que hace falta, no en cada edificio
        andamioListo = true;
        try {
          const g = crearAndamio([plan.ancho / CELDA, plan.largo / CELDA], Math.min(plan.altura, 9) + 0.3, ctx);
          for (const h of g.children.slice()) nAndamio.add(h);
        } catch (e) { /* sin andamio, pero no rompemos la obra */ }
      }
      nAndamio.visible = enObra;
      if (enObra) nAndamio.scale.set(1, clamp(0.3 + 0.8 * p, 0.3, 1), 1);
    },

    /** Grietas, boquetes, humo por las chimeneas y fuego arriba de 0.7. */
    setDanio(t) {
      const d = clamp(t, 0, 1);
      if (Math.abs(d - danio) < 0.01) return;
      danio = d;
      nD1.visible = d > 0.3;
      nD2.visible = d > 0.62;
      nFuego.visible = d > 0.7;
      if (nFuego.visible) nFuego.scale.setScalar(0.75 + (d - 0.7) * 1.6);
      const inten = d > 0.42 ? Math.min(1.6, (d - 0.42) * 2.4) : 0;
      if (Math.abs(inten - humoActual) > 0.12) {
        humoActual = inten;
        try { for (const m of marcadores) ctx?.efectos?.humoContinuo?.(m, inten); } catch (e) { /* sin efectos */ }
      }
    },

    /** Las geometrías y materiales son compartidos: acá sólo soltamos las mallas. */
    dispose() {
      try { for (const m of marcadores) ctx?.efectos?.humoContinuo?.(m, 0); } catch (e) { /* nada */ }
      grupo.removeFromParent();
      grupo.clear();
      nCuerpo.clear(); nCim.clear(); nD1.clear(); nD2.clear(); nFuego.clear(); nAndamio.clear();
      mallasJugador.length = 0;
      marcadores.length = 0;
    },
  };

  if (opciones.colorJugador != null) api.setColorJugador(opciones.colorJugador);
  if (opciones.progreso != null) api.setProgreso(opciones.progreso);
  return api;
}

/** Libera todo lo cacheado (cambio de partida / de calidad). */
export function limpiarCacheEdificios() {
  for (const plan of cachePlanes.values()) {
    for (const nombre of Object.keys(plan.partes)) {
      for (const p of plan.partes[nombre]) p.geo?.dispose?.();
    }
  }
  cachePlanes.clear();
  for (const lista of cacheAndamios.values()) for (const p of lista) p.geo?.dispose?.();
  cacheAndamios.clear();
  for (const m of cacheMateriales.values()) m.dispose?.();
  cacheMateriales.clear();
}
