/**
 * UnidadPartes — biblioteca de piezas de geometría para las unidades.
 *
 * Todo acá es PURO: entra un puñado de números, sale una `THREE.BufferGeometry`
 * ya trasladada a su punto de anclaje (el punto por el que la cuelga el hueso
 * que la usa). Nada de materiales, nada de colores absolutos, nada de `ctx`.
 *
 * ── Convenciones (respetalas o el esqueleto queda al revés) ──────────────
 *  · +X = ADELANTE (la unidad mira hacia +X, igual que `rot = 0` del mundo).
 *  · +Y = ARRIBA. El suelo es y = 0.
 *  · +Z = IZQUIERDA de la unidad. Los pares se espejan en Z.
 *  · Las piezas de miembro cuelgan HACIA ABAJO desde su anclaje (y = 0).
 *  · Las armas se sujetan en el origen y apuntan hacia +X.
 *
 * ── Compuestos ───────────────────────────────────────────────────────────
 * Una pieza que necesita más de un material devuelve igual UNA geometría (la
 * dominante) y cuelga las demás en `geo.userData.extra = [{ geo, rol }]`.
 * `rol` es un nombre simbólico ('metal', 'cuero', 'jugador', 'emis', ...) que
 * la fábrica traduce a tinte + slot de material según la edad. Así las piezas
 * no saben nada de paletas y sirven igual en 1800 que en 2100.
 * Las armas además publican `geo.userData.boca = [x, y, z]`: la punta del
 * cañón, donde la fábrica clava el Object3D vacío `bocaArma`.
 */
import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';

export const TAU = Math.PI * 2;
const GR = Math.PI / 180;

/* ════════════════════ 0. Utilidades de geometría ════════════════════ */

/** Cache por clave. Las piezas repetidas (eslabones, ruedas) se piden una vez. */
const CACHE = new Map();
export function cacheado(clave, fabricar) {
  let g = CACHE.get(clave);
  if (g === undefined) { g = fabricar(); CACHE.set(clave, g); }
  return g;
}
export function limpiarCachePartes() {
  for (const g of CACHE.values()) desecharCompuesto(g);
  CACHE.clear();
}
export function desecharCompuesto(geo) {
  if (!geo) return;
  const ex = geo.userData && geo.userData.extra;
  if (ex) for (const e of ex) desecharCompuesto(e.geo);
  geo.dispose?.();
}

/**
 * Hace que `translate`/`rotate*`/`scale` arrastren también a los extras y a la
 * boca del arma. Sin esto, mover un compuesto le deja la mitad de las piezas
 * en el origen: es el bug clásico de este tipo de fábricas.
 */
const _vB = new THREE.Vector3();
const _mB = new THREE.Matrix4();
function aplicarBoca(g, m) {
  const b = g.userData.boca;
  if (!b) return;
  _vB.set(b[0], b[1], b[2]).applyMatrix4(m);
  b[0] = _vB.x; b[1] = _vB.y; b[2] = _vB.z;
}
export function propagar(g) {
  if (!g || g.__propagado) return g;
  g.__propagado = true;
  const proto = THREE.BufferGeometry.prototype;
  const hijos = () => g.userData.extra || VACIAS;
  g.translate = function (x, y, z) {
    proto.translate.call(g, x, y, z);
    for (const e of hijos()) e.geo.translate(x, y, z);
    aplicarBoca(g, _mB.makeTranslation(x, y, z));
    return g;
  };
  g.rotateX = function (a) {
    proto.rotateX.call(g, a);
    for (const e of hijos()) e.geo.rotateX(a);
    aplicarBoca(g, _mB.makeRotationX(a));
    return g;
  };
  g.rotateY = function (a) {
    proto.rotateY.call(g, a);
    for (const e of hijos()) e.geo.rotateY(a);
    aplicarBoca(g, _mB.makeRotationY(a));
    return g;
  };
  g.rotateZ = function (a) {
    proto.rotateZ.call(g, a);
    for (const e of hijos()) e.geo.rotateZ(a);
    aplicarBoca(g, _mB.makeRotationZ(a));
    return g;
  };
  g.scale = function (x, y, z) {
    proto.scale.call(g, x, y, z);
    for (const e of hijos()) e.geo.scale(x, y, z);
    aplicarBoca(g, _mB.makeScale(x, y, z));
    return g;
  };
  return g;
}
const VACIAS = [];

/** Cuelga geometrías secundarias con su rol de material. */
export function marcar(geo, extras, rol) {
  if (rol) geo.userData.rol = rol;
  if (extras && extras.length) {
    const lista = geo.userData.extra || (geo.userData.extra = []);
    for (const e of extras) if (e && e.geo) lista.push(e);
  }
  return propagar(geo);
}
export const conBoca = (geo, x, y = 0, z = 0) => { geo.userData.boca = [x, y, z]; return geo; };
export const ex = (geo, rol) => ({ geo, rol });

export const mover = (g, x = 0, y = 0, z = 0) => g.translate(x, y, z);
export const girar = (g, rx = 0, ry = 0, rz = 0) => {
  if (rx) g.rotateX(rx); if (ry) g.rotateY(ry); if (rz) g.rotateZ(rz);
  return g;
};
/**
 * Deja una geometría lista para `mergeGeometries`: sin índice, con el mismo
 * juego de atributos que todas las demás. Mezclar primitivas indexadas
 * (esferas, cilindros) con extrusiones no indexadas hace fallar el merge en
 * silencio y te quedás con un cuarto del modelo.
 */
function prepararFusion(geo) {
  const g = geo.index ? geo.toNonIndexed() : geo;
  if (!g.attributes.normal) g.computeVertexNormals();
  const n = g.attributes.position.count;
  if (!g.attributes.uv) g.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(n * 2), 2));
  for (const k of Object.keys(g.attributes)) {
    if (k !== 'position' && k !== 'normal' && k !== 'uv') g.deleteAttribute(k);
  }
  g.morphAttributes = {};
  g.clearGroups();
  return g;
}

/** Fusiona sin explotar si la lista viene vacía o con nulos. */
export function fusionar(lista) {
  const l = [];
  for (const x of lista) if (x) l.push(prepararFusion(x));
  if (!l.length) return null;
  if (l.length === 1) return l[0];
  const g = mergeGeometries(l, false);
  if (g) { for (const x of l) x.dispose(); return g; }
  return l[0];
}

/* ---- primitivas ---- */

/** Rectángulo de esquinas redondeadas: la base de todo lo biselado. */
export function formaRect(sx, sy, r) {
  const x = sx / 2, y = sy / 2;
  r = Math.max(0.0005, Math.min(r, x * 0.98, y * 0.98));
  const f = new THREE.Shape();
  f.moveTo(-x + r, -y);
  f.lineTo(x - r, -y); f.quadraticCurveTo(x, -y, x, -y + r);
  f.lineTo(x, y - r); f.quadraticCurveTo(x, y, x - r, y);
  f.lineTo(-x + r, y); f.quadraticCurveTo(-x, y, -x, y - r);
  f.lineTo(-x, -y + r); f.quadraticCurveTo(-x, -y, -x + r, -y);
  return f;
}

/**
 * Caja con bisel REAL (no una BoxGeometry). sx = fondo (X), sy = alto (Y),
 * sz = ancho (Z). El bisel es lo que atrapa la luz rasante del sol: es la
 * diferencia entre "caja de juguete" y "chasis blindado".
 */
export function cajaBiselada(sx, sy, sz, bisel = 0.02, segBisel = 1) {
  const b = Math.max(0.0006, Math.min(bisel, sx * 0.24, sy * 0.24, sz * 0.45));
  const forma = formaRect(sx - 2 * b, sy - 2 * b, Math.max(b * 0.9, Math.min(sx, sy) * 0.05));
  const g = new THREE.ExtrudeGeometry(forma, {
    depth: sz - 2 * b, bevelEnabled: true, bevelThickness: b, bevelSize: b,
    bevelSegments: segBisel, curveSegments: 2, steps: 1,
  });
  g.translate(0, 0, -(sz / 2 - b));
  return g;
}

/** Perfil 2D en XY (`[[x,y], ...]`) extruido en Z y centrado. Cascos, cureñas, alas. */
export function extruirPerfil(puntos, profundidad, bisel = 0.015, curvas = 2) {
  const f = new THREE.Shape();
  f.moveTo(puntos[0][0], puntos[0][1]);
  for (let i = 1; i < puntos.length; i++) f.lineTo(puntos[i][0], puntos[i][1]);
  f.closePath();
  const b = Math.max(0.0008, Math.min(bisel, profundidad * 0.4));
  const g = new THREE.ExtrudeGeometry(f, {
    depth: profundidad - 2 * b, bevelEnabled: true, bevelThickness: b, bevelSize: b,
    bevelSegments: 1, curveSegments: curvas, steps: 1,
  });
  g.translate(0, 0, -(profundidad / 2 - b));
  return g;
}

export const capsula = (r, largo, seg = 7, cap = 3) =>
  new THREE.CapsuleGeometry(Math.max(0.002, r), Math.max(0.001, largo), cap, seg);
export const cilindroConico = (rSup, rInf, alto, seg = 9, abierto = false) =>
  new THREE.CylinderGeometry(Math.max(1e-4, rSup), Math.max(1e-4, rInf), alto, seg, 1, abierto);
export const disco = (r, alto, seg = 12) => new THREE.CylinderGeometry(r, r, alto, seg);
export const esfera = (r, seg = 9) => new THREE.SphereGeometry(r, seg, Math.max(4, seg >> 1));
export const mediaEsfera = (r, seg = 9) =>
  new THREE.SphereGeometry(r, seg, Math.max(4, seg >> 1), 0, TAU, 0, Math.PI / 2);
/** Elipsoide: cráneos, cascos, cúpulas, fuselajes. */
export function esferaAchatada(rx, ry, rz, seg = 10) {
  const g = new THREE.SphereGeometry(1, seg, Math.max(5, seg >> 1));
  g.scale(rx, ry, rz);
  return g;
}
export const toroide = (r, tuboR, segT = 6, seg = 12, arco = TAU) =>
  new THREE.TorusGeometry(r, tuboR, segT, seg, arco);
/** Revolución sobre Y desde un perfil `[[radio, alto], ...]`. */
export const revolucion = (perfil, seg = 12) =>
  new THREE.LatheGeometry(perfil.map((p) => new THREE.Vector2(Math.max(1e-4, p[0]), p[1])), seg);
/** Placa fina biselada: correajes, aletas, guardabarros, faldones. */
export const placa = (sx, sy, sz, b = 0.006) => cajaBiselada(sx, sy, sz, b);

/**
 * Tubo suave a lo largo de una polilínea 3D o de una `THREE.Curve`.
 * Correas, riendas, mangueras, antenas dobladas, cables del exoesqueleto.
 */
export function tubo(curva, radio, seg = 5) {
  let c = curva;
  if (Array.isArray(curva)) {
    c = new THREE.CatmullRomCurve3(curva.map((p) =>
      (p.isVector3 ? p : new THREE.Vector3(p[0], p[1], p[2]))));
  }
  const n = Array.isArray(curva) ? Math.max(5, curva.length * 3) : 16;
  return new THREE.TubeGeometry(c, n, Math.max(0.0008, radio), seg, false);
}

/** Barra recta entre dos puntos, sin trigonometría en el sitio de uso. */
export function barra(a, b, radio, seg = 5) {
  return tubo([a, [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2], b], radio, seg);
}

/**
 * MIEMBRO CON VOLUMEN: tronco cónico CERRADO más un casquete en la punta,
 * colgando desde y = 0 hacia abajo. Reemplaza a la cápsula en piernas y brazos.
 *
 * El porqué: una cápsula tiene radio constante, así que a 80 m se lee como un
 * palito de grosor uniforme sin ninguna pista de dónde está la rodilla. Lo que
 * hace que algo parezca una PIERNA es que el muslo sea claramente más grueso
 * que la pantorrilla; ese estrechamiento es la única sombra propia que la pieza
 * puede generar a esta distancia, y sin ella el miembro parece translúcido
 * aunque el material sea opaco (fue literalmente el diagnóstico del jurado:
 * "piernas como palitos semitransparentes").
 *
 * La tapa superior va incluida (`cilindroConico` cierra los extremos) porque el
 * hueco de una tapa faltante SÍ deja ver el interior y ahí sí se ve translúcido.
 * Sale más barato que la cápsula que reemplaza: 84 triángulos contra 98.
 */
export function miembro(rSup, rInf, largo, seg = 7) {
  const tronco = cilindroConico(rSup, rInf, largo, seg).translate(0, -largo / 2, 0);
  const punta = mediaEsfera(rInf, seg).rotateZ(Math.PI).translate(0, -largo, 0);
  return marcar(fusionar([tronco, punta]), [], 'tela');
}

/* ════════════════════ 1. Proporciones humanas ════════════════════ */

/** 1,80 m y 7,5 cabezas. Todos los humanoides cuelgan de estas medidas. */
export const H = {
  total: 1.80,
  cadera: 0.95, hombro: 1.49, cuello: 1.55, coronilla: 1.80,
  rodilla: 0.50, tobillo: 0.10,
  torso: 0.54, cabeza: 0.25,
  muslo: 0.45, pantorrilla: 0.40,
  brazo: 0.30, antebrazo: 0.26, mano: 0.10,
  hombroZ: 0.19, caderaZ: 0.105,
  anchoHombros: 0.42, anchoPecho: 0.26, anchoCintura: 0.21,
};

/* ════════════════════ 2. Anatomía ════════════════════ */

/**
 * Torso anclado en la cintura (y = 0, sube 0.54). Estilos:
 *  'casaca'  levita napoleónica con faldón y solapas (Vapor)
 *  'guerrera' guerrera con bolsillos y cinturón (Eléctrica)
 *  'chaleco' guerrera + chaleco de placas (Atómica / Información)
 *  'exo'     coraza articulada con costillas y líneas vivas (Sintética)
 *  'civil'   camisa arremangada y chaleco de faena (colono)
 *  'abrigo'  abrigo largo hasta la rodilla (agitador, hacker)
 *
 * `anchoHombros` multiplica el ancho del bloque superior (pecho, bolas de hombro
 * y cáscara del chaleco). Es la palanca principal de SILUETA POR CLASE: el
 * antitanque tiene que leerse como un trapecio ancho y el tirador como una
 * vertical fina, y eso se decide arriba, no en el color.
 *
 * REPARTO DE COLOR: acá el color de jugador va SÓLO en la prenda frontal grande
 * (peto, chaleco, coraza, abrigo). El cuerpo del torso, los faldones y las
 * solapas quedan en gama desaturada — ver la REGLA DE REPARTO en UnidadFabrica.
 */
export function torsoHumano(estilo = 'guerrera', anchoHombros = 1) {
  const A = H.anchoPecho, C = H.anchoCintura, T = H.torso;
  const K = Math.max(0.6, anchoHombros);
  const partes = [], extras = [];

  // caja torácica: perfil lateral con pecho adelante y espalda recta
  const tronco = extruirPerfil([
    [-0.085, 0.0], [0.075, 0.0], [0.095, T * 0.42], [0.088, T * 0.78],
    [0.055, T], [-0.062, T], [-0.086, T * 0.72], [-0.098, T * 0.34],
  ], C + 0.02, 0.018, 3);
  // ensanchamos hacia los hombros con una segunda cáscara
  const pecho = esferaAchatada(0.105, T * 0.30, A * 0.56 * K, 12);
  pecho.translate(0.004, T * 0.66, 0);
  const cintura = esferaAchatada(0.093, 0.10, C * 0.56, 10);
  cintura.translate(-0.004, 0.05, 0);
  partes.push(tronco, pecho, cintura);

  // hombros: dos bolas que redondean la silueta y evitan el "muñeco de palo"
  const hz = (H.hombroZ - 0.02) * K;
  const hombro = esferaAchatada(0.068, 0.068, 0.068 * Math.min(1.35, K), 9);
  partes.push(hombro.clone().translate(0, T - 0.055, hz));
  partes.push(hombro.clone().translate(0, T - 0.055, -hz));

  // cuello
  partes.push(cilindroConico(0.043, 0.055, 0.08, 8).translate(0.004, T + 0.03, 0));

  if (estilo === 'casaca') {
    // faldones: dos paños que cuelgan atrás, puro contorno a 80 m.
    // Van en tela oscura, NO en color de bando: colgados detrás y abajo son una
    // isla de color separada de la casaca y ensucian la lectura de la mancha.
    const fald = placa(0.10, 0.26, 0.115, 0.008);
    extras.push(ex(fald.clone().translate(-0.055, -0.11, 0.055), 'tela2'));
    extras.push(ex(fald.clone().translate(-0.055, -0.11, -0.055), 'tela2'));
    // PECHERA: una sola pieza ancha en vez de dos tiras separadas. Pegada al
    // manto por arriba, así que las dos suman a la MISMA mancha de bando en
    // lugar de leerse como dos rayitas de color sobre un torso gris.
    extras.push(ex(placa(0.030, T * 0.72, 0.19 * K, 0.007).translate(0.084, T * 0.42, 0), 'jugador'));
    // los vivos del cruce quedan como detalle metálico, no como color de bando
    const vivo = placa(0.010, T * 0.66, 0.016, 0.003);
    extras.push(ex(vivo.clone().translate(0.100, T * 0.42, 0.098 * K), 'acento'));
    extras.push(ex(vivo.clone().translate(0.100, T * 0.42, -0.098 * K), 'acento'));
    // charreteras
    const char = esferaAchatada(0.055, 0.022, 0.05, 8);
    extras.push(ex(char.clone().translate(0, T - 0.015, (H.hombroZ - 0.015) * K), 'acento'));
    extras.push(ex(char.clone().translate(0, T - 0.015, -(H.hombroZ - 0.015) * K), 'acento'));
    // botones
    const bot = esfera(0.011, 6);
    for (let i = 0; i < 4; i++) extras.push(ex(bot.clone().translate(0.094, 0.16 + i * 0.085, 0.03), 'acento'));
  } else if (estilo === 'guerrera') {
    const bols = placa(0.016, 0.075, 0.085, 0.005);
    partes.push(bols.clone().translate(0.088, T * 0.42, 0.062));
    partes.push(bols.clone().translate(0.088, T * 0.42, -0.062));
    const petoJug = placa(0.030, T * 0.70, 0.20 * K, 0.008);
    extras.push(ex(petoJug.translate(0.086, T * 0.44, 0), 'jugador'));
    extras.push(ex(cinturon(C + 0.03, 0.045), 'correaje'));
  } else if (estilo === 'chaleco') {
    // chaleco antibalas: es LA zona de bando de las edades modernas
    const chal = extruirPerfil([
      [-0.10, 0.06], [0.10, 0.10], [0.115, T * 0.55], [0.095, T * 0.90],
      [-0.088, T * 0.90], [-0.108, T * 0.52],
    ], (A + 0.05) * K, 0.014, 2);
    extras.push(ex(chal, 'jugador'));
    const bolsMag = placa(0.036, 0.085, 0.062, 0.007);
    partes.push(bolsMag.clone().translate(0.115, T * 0.42, 0.062));
    partes.push(bolsMag.clone().translate(0.115, T * 0.42, -0.062));
    partes.push(bolsMag.clone().translate(0.115, T * 0.42, 0));
    // radio al hombro
    partes.push(cajaBiselada(0.05, 0.10, 0.06, 0.008).translate(-0.04, T * 0.80, 0.14));
    extras.push(ex(tubo([[-0.04, T * 0.86, 0.15], [-0.02, T + 0.10, 0.17], [0.0, T + 0.22, 0.14]], 0.005, 4), 'metalOsc'));
    extras.push(ex(cinturon(C + 0.035, 0.05), 'correaje'));
  } else if (estilo === 'exo') {
    const coraza = extruirPerfil([
      [-0.108, 0.02], [0.10, 0.06], [0.128, T * 0.50], [0.10, T * 0.92],
      [-0.075, T * 0.95], [-0.118, T * 0.50],
    ], (A + 0.07) * K, 0.02, 3);
    extras.push(ex(coraza, 'jugador'));
    // costillas de servo
    for (let i = 0; i < 3; i++) {
      const c = toroide(0.10 + i * 0.006, 0.010, 5, 12);
      c.rotateY(Math.PI / 2);
      extras.push(ex(c.translate(0.0, 0.14 + i * 0.13, 0), 'metal'));
    }
    // líneas vivas: la firma de la Edad Sintética
    const linea = placa(0.006, T * 0.56, 0.012, 0.002);
    extras.push(ex(linea.clone().translate(0.132, T * 0.50, 0.085), 'emis'));
    extras.push(ex(linea.clone().translate(0.132, T * 0.50, -0.085), 'emis'));
    extras.push(ex(esferaAchatada(0.03, 0.03, 0.016, 8).translate(0.130, T * 0.72, 0), 'emis'));
    // mochila de potencia
    extras.push(ex(cajaBiselada(0.11, 0.30, 0.24, 0.02).translate(-0.16, T * 0.52, 0), 'metalOsc'));
  } else if (estilo === 'civil') {
    const chaleco = extruirPerfil([
      [-0.10, 0.02], [0.098, 0.06], [0.105, T * 0.52], [0.085, T * 0.88],
      [-0.08, T * 0.90], [-0.105, T * 0.50],
    ], (A + 0.03) * K, 0.012, 2);
    extras.push(ex(chaleco, 'jugador'));
    extras.push(ex(cinturon(C + 0.03, 0.042), 'cuero'));
    // bolsillo de herramientas
    partes.push(cajaBiselada(0.035, 0.09, 0.07, 0.008).translate(0.09, 0.02, 0.10));
  } else if (estilo === 'abrigo') {
    // el abrigo largo ES la mancha de bando del apoyo: una sola pieza de la
    // cintura a la rodilla, la silueta más "civil" del ejército
    const falda = cilindroConico(C * 0.62, C * 0.94, 0.50, 12);
    extras.push(ex(falda.translate(-0.006, -0.24, 0), 'jugador'));
    const solapa = placa(0.02, T * 0.70, 0.09, 0.006);
    extras.push(ex(solapa.clone().translate(0.086, T * 0.45, 0.06), 'tela2'));
    extras.push(ex(solapa.clone().translate(0.086, T * 0.45, -0.06), 'tela2'));
    extras.push(ex(cinturon(C + 0.03, 0.04), 'cuero'));
  }
  const g = fusionar(partes);
  return marcar(g, extras, 'tela');
}

/** Cinturón anclado en la cintura, listo para colgar de `torsoHumano`. */
export function cinturon(ancho = 0.24, alto = 0.045) {
  const c = esferaAchatada(0.108, alto * 0.5, ancho * 0.5, 12);
  const hebilla = cajaBiselada(0.02, 0.05, 0.045, 0.006).translate(0.104, 0.005, 0);
  return fusionar([c.translate(0, 0.02, 0), hebilla]);
}

/**
 * Cabeza anclada en la base del cuello (y = 0, sube 0.25). No hay cara fina:
 * hay cráneo, mandíbula, nariz y orejas. A 80 m eso alcanza y sobra para que
 * no parezca una cápsula.
 */
export function cabezaHumana(estilo = 'raso') {
  const partes = [], extras = [];
  const craneo = esferaAchatada(0.093, 0.108, 0.088, 12);
  craneo.translate(0.004, 0.135, 0);
  // mandíbula: le da mentón y perfil
  const mandi = extruirPerfil([
    [-0.072, 0.0], [0.068, 0.012], [0.078, 0.055], [0.040, 0.082],
    [-0.058, 0.078], [-0.080, 0.040],
  ], 0.135, 0.014, 3);
  mandi.translate(0.004, 0.052, 0);
  const nariz = extruirPerfil([[0, 0], [0.030, 0.010], [0.006, 0.036]], 0.028, 0.005, 1);
  nariz.translate(0.070, 0.108, 0);
  const oreja = esferaAchatada(0.011, 0.024, 0.008, 6);
  partes.push(craneo, mandi, nariz);
  partes.push(oreja.clone().translate(-0.005, 0.118, 0.086));
  partes.push(oreja.clone().translate(-0.005, 0.118, -0.086));

  if (estilo === 'barba') {
    extras.push(ex(esferaAchatada(0.072, 0.055, 0.078, 9).translate(0.006, 0.055, 0), 'oscuro'));
  } else if (estilo === 'visor') {
    // banda de visor: separa a los modernos de los de 1800 al primer vistazo
    const v = extruirPerfil([[0.02, 0], [0.085, 0.014], [0.082, 0.05], [0.015, 0.046]], 0.155, 0.006, 2);
    extras.push(ex(v.translate(0, 0.128, 0), 'vidrio'));
  } else if (estilo === 'mascara') {
    const m = extruirPerfil([
      [-0.05, 0.02], [0.082, 0.03], [0.092, 0.09], [0.05, 0.125], [-0.05, 0.12],
    ], 0.155, 0.008, 2);
    extras.push(ex(m.translate(0.006, 0.02, 0), 'metalOsc'));
    extras.push(ex(placa(0.008, 0.016, 0.11, 0.003).translate(0.096, 0.088, 0), 'emis'));
  } else {
    // pelo: casquete oscuro por detrás de la línea del casco
    const pelo = esferaAchatada(0.096, 0.104, 0.091, 10);
    extras.push(ex(pelo.translate(-0.006, 0.140, 0), 'oscuro'));
  }
  return marcar(fusionar(partes), extras, 'piel');
}

/**
 * Casco anclado en la base del cuello, igual que la cabeza.
 * tipo: 'shako' 'chaco' 'morrion' 'acero' 'kevlar' 'exo' 'obra' 'sombrero' 'capucha'
 */
export function casco(tipo = 'acero') {
  const partes = [], extras = [];
  switch (tipo) {
    case 'shako': {           // 1800: cilindro alto, visera y galleta
      partes.push(cilindroConico(0.098, 0.088, 0.20, 14).translate(0.004, 0.255, 0));
      partes.push(revolucion([[0, 0], [0.10, 0], [0.10, 0.012], [0, 0.012]], 14).translate(0.004, 0.355, 0));
      const visera = extruirPerfil([[0, 0], [0.075, 0.004], [0.072, 0.018], [0, 0.02]], 0.15, 0.005, 2);
      partes.push(visera.translate(0.058, 0.152, 0));
      // la cinta del shako va en 'acento' y no en color de bando: es un detalle
      // chico y disperso, y el bando tiene que ser UNA sola mancha grande
      extras.push(ex(toroide(0.094, 0.010, 5, 14).rotateX(Math.PI / 2).translate(0.004, 0.192, 0), 'acento'));
      extras.push(ex(esferaAchatada(0.026, 0.026, 0.012, 8).translate(0.086, 0.30, 0), 'acento'));
      break;
    }
    case 'chaco': {           // húsar: más alto, con cordones y plumero
      partes.push(cilindroConico(0.104, 0.086, 0.235, 14).translate(0.004, 0.27, 0));
      partes.push(revolucion([[0, 0], [0.108, 0], [0.108, 0.014], [0, 0.014]], 14).translate(0.004, 0.385, 0));
      const visera = extruirPerfil([[0, 0], [0.078, 0.004], [0.075, 0.02], [0, 0.022]], 0.155, 0.005, 2);
      partes.push(visera.translate(0.062, 0.155, 0));
      for (let i = 0; i < 3; i++) {
        const cord = toroide(0.098 - i * 0.004, 0.006, 5, 14);
        extras.push(ex(cord.rotateX(Math.PI / 2).translate(0.004, 0.21 + i * 0.055, 0), 'acento'));
      }
      break;
    }
    case 'morrion': {         // piquero: casco con cresta
      partes.push(revolucion([
        [0.098, 0], [0.104, 0.03], [0.092, 0.085], [0.058, 0.13], [0, 0.15],
      ], 14).translate(0.004, 0.145, 0));
      const cresta = extruirPerfil([
        [-0.09, 0], [0.09, 0], [0.055, 0.05], [-0.055, 0.05],
      ], 0.016, 0.004, 2);
      partes.push(cresta.translate(0.004, 0.265, 0));
      const ala = revolucion([[0.09, 0.004], [0.135, 0.028], [0.138, 0.038], [0.088, 0.016]], 14);
      partes.push(ala.translate(0.004, 0.142, 0));
      break;
    }
    case 'acero': {           // Atómica: campana con faldón
      partes.push(revolucion([
        [0.104, 0], [0.108, 0.026], [0.100, 0.072], [0.070, 0.115], [0.035, 0.132], [0, 0.136],
      ], 14).translate(0.004, 0.148, 0));
      partes.push(revolucion([[0.098, 0.02], [0.118, 0.0], [0.120, 0.012], [0.100, 0.034]], 14)
        .translate(0.004, 0.146, 0));
      extras.push(ex(barra([0.055, 0.16, 0.088], [0.03, 0.09, 0.075], 0.006, 4), 'cuero'));
      break;
    }
    case 'kevlar': {          // Información: casco con rieles y visor levantado
      partes.push(revolucion([
        [0.100, 0], [0.106, 0.03], [0.098, 0.080], [0.066, 0.122], [0, 0.140],
      ], 14).translate(0.004, 0.150, 0));
      const riel = placa(0.13, 0.012, 0.010, 0.003);
      partes.push(riel.clone().translate(0.01, 0.20, 0.088));
      partes.push(riel.clone().translate(0.01, 0.20, -0.088));
      // soporte de visión nocturna en la frente
      partes.push(cajaBiselada(0.05, 0.035, 0.045, 0.008).translate(0.086, 0.235, 0));
      extras.push(ex(disco(0.019, 0.05, 8).rotateZ(Math.PI / 2).translate(0.118, 0.235, 0.022), 'vidrio'));
      extras.push(ex(disco(0.019, 0.05, 8).rotateZ(Math.PI / 2).translate(0.118, 0.235, -0.022), 'vidrio'));
      break;
    }
    case 'exo': {             // Sintética: yelmo cerrado con banda viva
      partes.push(esferaAchatada(0.100, 0.115, 0.098, 12).translate(0.006, 0.140, 0));
      const barbi = extruirPerfil([
        [-0.06, 0.0], [0.086, 0.02], [0.096, 0.075], [0.04, 0.10], [-0.06, 0.09],
      ], 0.17, 0.01, 2);
      partes.push(barbi.translate(0.004, 0.045, 0));
      const cresta = extruirPerfil([[-0.085, 0], [0.09, 0], [0.06, 0.032], [-0.06, 0.032]], 0.022, 0.005, 2);
      extras.push(ex(cresta.translate(0.004, 0.235, 0), 'metalOsc'));
      extras.push(ex(placa(0.012, 0.026, 0.13, 0.004).translate(0.100, 0.115, 0), 'emis'));
      extras.push(ex(placa(0.10, 0.010, 0.012, 0.003).translate(0.03, 0.20, 0.094), 'emis'));
      extras.push(ex(placa(0.10, 0.010, 0.012, 0.003).translate(0.03, 0.20, -0.094), 'emis'));
      break;
    }
    case 'obra': {            // colono moderno: casco de obra con ala
      partes.push(revolucion([
        [0.098, 0], [0.102, 0.03], [0.086, 0.085], [0.05, 0.118], [0, 0.126],
      ], 12).translate(0.004, 0.155, 0));
      partes.push(revolucion([[0.09, 0.006], [0.132, 0.0], [0.134, 0.012], [0.092, 0.022]], 14)
        .translate(0.004, 0.152, 0));
      const nervio = placa(0.19, 0.016, 0.014, 0.004);
      partes.push(nervio.translate(0.004, 0.28, 0));
      break;
    }
    case 'sombrero': {
      // TIRADOR: el ala ancha es el rasgo que lo separa del fusilero de línea a
      // 80 m. El shako es una vertical alta y angosta; esto es un DISCO. Se
      // exagera a 0.21 de radio (contra los 0.10 del shako) justamente para que
      // las dos siluetas no se puedan confundir ni con el color apagado.
      partes.push(revolucion([[0, 0.036], [0.085, 0.03], [0.086, 0.04], [0, 0.046]], 14)
        .translate(0.004, 0.19, 0));
      partes.push(revolucion([[0.078, 0.0], [0.208, 0.020], [0.209, 0.034], [0.078, 0.016]], 16)
        .translate(0.004, 0.150, 0));
      partes.push(cilindroConico(0.084, 0.092, 0.10, 12).translate(0.004, 0.20, 0));
      extras.push(ex(toroide(0.090, 0.010, 5, 14).rotateX(Math.PI / 2).translate(0.004, 0.165, 0), 'acento'));
      break;
    }
    case 'capucha': {
      partes.push(revolucion([
        [0.108, -0.02], [0.118, 0.05], [0.106, 0.10], [0.07, 0.145], [0, 0.16],
      ], 12).translate(-0.012, 0.135, 0));
      const boca = extruirPerfil([[0.02, 0], [0.10, 0.02], [0.10, 0.10], [0.02, 0.12]], 0.14, 0.008, 2);
      extras.push(ex(boca.translate(0.02, 0.09, 0), 'oscuro'));
      break;
    }
    default: {                // gorra de plato / quepis
      partes.push(cilindroConico(0.096, 0.090, 0.075, 12).translate(0.004, 0.215, 0));
      partes.push(revolucion([[0, 0], [0.10, 0], [0.10, 0.012], [0, 0.012]], 12).translate(0.004, 0.252, 0));
      const visera = extruirPerfil([[0, 0], [0.068, 0.004], [0.065, 0.016], [0, 0.018]], 0.14, 0.004, 2);
      partes.push(visera.translate(0.058, 0.178, 0));
      extras.push(ex(toroide(0.092, 0.008, 5, 12).rotateX(Math.PI / 2).translate(0.004, 0.184, 0), 'acento'));
    }
  }
  return marcar(fusionar(partes), extras, 'tela2');
}

/** Gorra blanda (colono de las primeras edades, caravanero). */
export function gorra(tipo = 'boina') {
  if (tipo === 'paja') {
    const copa = revolucion([[0, 0.06], [0.075, 0.055], [0.08, 0.065], [0, 0.072]], 14);
    const ala = revolucion([[0.07, 0.0], [0.17, 0.018], [0.172, 0.03], [0.07, 0.014]], 16);
    return marcar(fusionar([copa.translate(0, 0.175, 0), ala.translate(0, 0.16, 0)]), [], 'acento');
  }
  const g = esferaAchatada(0.098, 0.055, 0.094, 10).translate(0.004, 0.19, 0);
  const visera = extruirPerfil([[0, 0], [0.062, 0.004], [0.06, 0.014], [0, 0.016]], 0.13, 0.004, 2);
  // 'tela2' y no 'jugador': una gorra teñida es un puntito de color arriba de
  // todo, justo lo contrario de la mancha grande y contigua que buscamos
  return marcar(fusionar([g, visera.translate(0.058, 0.185, 0)]), [], 'tela2');
}

/** Penacho anclado en su base: plumero del shako, cresta del casco. */
export function penacho(alto = 0.20, r = 0.026) {
  const p = [];
  const n = 5;
  for (let i = 0; i <= n; i++) {
    const t = i / n;
    p.push([r * (0.35 + Math.sin(t * Math.PI) * 0.9), alto * t]);
  }
  p.push([0.004, alto * 1.04]);
  const g = revolucion(p, 9);
  // leve caída hacia atrás: nada en la naturaleza está perfectamente vertical
  g.rotateZ(0.10);
  // rol por defecto 'acento' y no 'jugador': el penacho es contorno, no bando
  return marcar(g, [], 'acento');
}

/** Bota anclada en el tobillo: el pie sale hacia +X y baja hasta el suelo. */
export function bota(largo = 0.26, alto = 0.13, ancho = 0.105) {
  const suela = extruirPerfil([
    [-0.075, -0.10], [largo - 0.075, -0.093], [largo - 0.068, -0.062],
    [0.02, -0.045], [-0.078, -0.05],
  ], ancho, 0.010, 2);
  const empeine = extruirPerfil([
    [-0.072, -0.062], [largo - 0.085, -0.058], [largo * 0.42, alto - 0.10], [-0.07, alto - 0.055],
  ], ancho - 0.012, 0.012, 2);
  const cana = cilindroConico(0.062, 0.056, alto, 9).translate(-0.012, alto * 0.5 - 0.075, 0);
  return marcar(fusionar([suela, empeine, cana]), [], 'cuero');
}

/** Guante/mano anclado en la muñeca. */
export function guante(r = 0.046) {
  const palma = esferaAchatada(r * 1.25, r * 1.5, r * 0.82, 8).translate(0.008, -r * 0.9, 0);
  const pulgar = capsula(r * 0.36, r * 0.7, 6).rotateZ(0.7).translate(0.03, -r * 0.7, r * 0.6);
  const punio = toroide(r * 1.05, r * 0.28, 5, 10).rotateX(Math.PI / 2).translate(0, -0.012, 0);
  return marcar(fusionar([palma, pulgar]), [ex(punio, 'cuero')], 'piel');
}

/**
 * Mochila anclada en el centro de la espalda: crece hacia -X.
 * tipo: 'macuto' 'campana' 'tactica' 'radio' 'saco' 'energia'
 */
export function mochila(tipo = 'macuto') {
  const partes = [], extras = [];
  if (tipo === 'saco') {
    const s = esferaAchatada(0.10, 0.15, 0.115, 9).translate(-0.12, 0.06, 0);
    partes.push(s);
    extras.push(ex(tubo([[-0.06, 0.19, 0.05], [-0.12, 0.21, 0], [-0.06, 0.19, -0.05]], 0.010, 5), 'cuero'));
  } else if (tipo === 'campana') {
    partes.push(cajaBiselada(0.11, 0.24, 0.26, 0.016).translate(-0.145, 0.05, 0));
    // manta enrollada arriba: contorno inconfundible
    const manta = capsula(0.038, 0.26, 8).rotateX(Math.PI / 2).translate(-0.135, 0.185, 0);
    extras.push(ex(manta, 'tela2'));
    extras.push(ex(cajaBiselada(0.05, 0.09, 0.08, 0.008).translate(-0.14, -0.10, 0.11), 'cuero'));
  } else if (tipo === 'tactica') {
    partes.push(cajaBiselada(0.115, 0.30, 0.27, 0.022).translate(-0.15, 0.06, 0));
    extras.push(ex(placa(0.02, 0.26, 0.05, 0.006).translate(-0.212, 0.06, 0.09), 'correaje'));
    extras.push(ex(placa(0.02, 0.26, 0.05, 0.006).translate(-0.212, 0.06, -0.09), 'correaje'));
    extras.push(ex(capsula(0.035, 0.13, 8).rotateZ(Math.PI / 2).translate(-0.14, -0.10, 0.12), 'metal'));
  } else if (tipo === 'radio') {
    partes.push(cajaBiselada(0.10, 0.26, 0.22, 0.018).translate(-0.145, 0.06, 0));
    extras.push(ex(tubo([[-0.13, 0.20, 0.08], [-0.10, 0.52, 0.10], [-0.04, 0.78, 0.06]], 0.006, 4), 'metalOsc'));
    extras.push(ex(esfera(0.014, 6).translate(-0.04, 0.79, 0.06), 'emis'));
    extras.push(ex(cajaBiselada(0.03, 0.05, 0.05, 0.006).translate(-0.09, 0.20, -0.10), 'metal'));
  } else if (tipo === 'energia') {
    partes.push(cajaBiselada(0.13, 0.32, 0.26, 0.026).translate(-0.16, 0.08, 0));
    for (let i = 0; i < 3; i++) {
      extras.push(ex(placa(0.012, 0.05, 0.20, 0.004).translate(-0.228, -0.02 + i * 0.10, 0), 'emis'));
    }
    extras.push(ex(capsula(0.032, 0.24, 8).translate(-0.12, 0.10, 0.135), 'metal'));
    extras.push(ex(capsula(0.032, 0.24, 8).translate(-0.12, 0.10, -0.135), 'metal'));
  } else {
    partes.push(cajaBiselada(0.10, 0.22, 0.24, 0.016).translate(-0.14, 0.04, 0));
    extras.push(ex(placa(0.016, 0.19, 0.045, 0.005).translate(-0.196, 0.04, 0.08), 'cuero'));
    extras.push(ex(placa(0.016, 0.19, 0.045, 0.005).translate(-0.196, 0.04, -0.08), 'cuero'));
  }
  return marcar(fusionar(partes), extras, 'tela2');
}

/**
 * Correaje anclado en la cintura (y = 0 = cintura): tirantes cruzados,
 * cantimplora y cartuchera. Es el detalle que más "soldado" agrega por vértice.
 */
export function correaje(estilo = 'cruzado', alturaTorso = H.torso) {
  const T = alturaTorso, extras = [], partes = [];
  if (estilo === 'cruzado') {
    partes.push(tubo([[0.10, 0.06, -0.10], [0.10, T * 0.55, 0.02], [0.03, T - 0.03, 0.14],
      [-0.09, T * 0.60, 0.10], [-0.09, 0.08, -0.02]], 0.016, 4));
    partes.push(tubo([[0.10, 0.06, 0.10], [0.10, T * 0.55, -0.02], [0.03, T - 0.03, -0.14],
      [-0.09, T * 0.60, -0.10], [-0.09, 0.08, 0.02]], 0.016, 4));
  } else if (estilo === 'bandolera') {
    partes.push(tubo([[0.10, 0.02, -0.09], [0.11, T * 0.50, 0.02], [0.02, T - 0.02, 0.15],
      [-0.10, T * 0.55, 0.09]], 0.019, 4));
  } else if (estilo === 'arnes') {
    partes.push(tubo([[0.11, 0.10, 0.075], [0.11, T * 0.75, 0.085], [0.01, T - 0.02, 0.135]], 0.015, 4));
    partes.push(tubo([[0.11, 0.10, -0.075], [0.11, T * 0.75, -0.085], [0.01, T - 0.02, -0.135]], 0.015, 4));
    partes.push(tubo([[0.115, T * 0.44, 0.08], [0.115, T * 0.44, -0.08]], 0.012, 4));
  }
  // cantimplora y cartuchera colgando del cinto
  extras.push(ex(revolucion([[0, -0.06], [0.045, -0.055], [0.05, 0.0], [0.045, 0.055], [0, 0.06]], 10)
    .rotateZ(Math.PI / 2).translate(-0.10, -0.04, 0.115), 'metal'));
  extras.push(ex(cajaBiselada(0.05, 0.08, 0.07, 0.008).translate(-0.085, -0.03, -0.115), 'cuero'));
  return marcar(fusionar(partes), extras, 'correaje');
}

/** Faldón/capote que cuelga de la cintura: puro contorno a distancia. */
export function faldon(largo = 0.30, r0 = 0.13, r1 = 0.18) {
  const g = cilindroConico(r0, r1, largo, 12, true);
  return marcar(g.translate(0, -largo / 2, 0), [], 'jugador');
}

/* ════════════════════ 3. Armas ════════════════════ */

/**
 * Arma sujeta en el origen (la mano) apuntando a +X.
 * Devuelve la geometría de madera/cuerpo y cuelga el metal como extra.
 * `userData.boca` marca la punta del cañón.
 *
 * tipos: mosquete · cerrojo · subfusil · asalto · pesado · rifle_largo ·
 *        rifle_mira · rifle_bipode · riel · carabina · escopeta · at ·
 *        bazuca · misil · enjambre · pica · sable · hacha · martillo ·
 *        megafono · consola · red
 */
export function fusil(tipo = 'asalto') {
  const cuerpo = [], extras = [];
  let boca = 0.6;

  const culata = (x0, x1, alto = 0.075) => extruirPerfil([
    [x0, -0.075], [x0 + 0.04, -0.09], [x1 - 0.06, -0.03], [x1, 0.0],
    [x1, alto * 0.4], [x0 + 0.02, alto * 0.30],
  ], 0.036, 0.006, 2);
  const canio = (r, x0, x1, seg = 9) =>
    cilindroConico(r, r, x1 - x0, seg).rotateZ(-Math.PI / 2).translate((x0 + x1) / 2, 0, 0);
  const grip = () => extruirPerfil([
    [-0.03, -0.145], [0.03, -0.15], [0.05, -0.02], [-0.012, -0.01],
  ], 0.032, 0.006, 2);

  switch (tipo) {
    case 'mosquete': {
      cuerpo.push(culata(-0.40, 0.18, 0.09));
      cuerpo.push(extruirPerfil([[-0.05, -0.035], [0.60, -0.028], [0.60, 0.006], [-0.05, 0.012]], 0.034, 0.006, 2));
      extras.push(ex(canio(0.0125, -0.06, 0.72), 'metal'));
      // bayoneta: la silueta que grita "1800"
      extras.push(ex(extruirPerfil([[0.70, -0.006], [1.00, 0.0], [0.70, 0.018]], 0.012, 0.003, 1), 'metal'));
      extras.push(ex(toroide(0.020, 0.006, 5, 8).rotateY(Math.PI / 2).translate(0.70, 0, 0), 'metal'));
      extras.push(ex(cajaBiselada(0.09, 0.05, 0.028, 0.006).translate(0.02, -0.028, 0), 'metal'));
      extras.push(ex(barra([-0.02, -0.03, 0.02], [-0.10, -0.10, 0.02], 0.006, 4), 'metal')); // gatillo/guarda
      boca = 0.72; break;
    }
    case 'cerrojo': {
      cuerpo.push(culata(-0.38, 0.14, 0.085));
      cuerpo.push(extruirPerfil([[-0.02, -0.032], [0.46, -0.026], [0.46, 0.008], [-0.02, 0.014]], 0.032, 0.006, 2));
      extras.push(ex(canio(0.0115, -0.04, 0.66), 'metal'));
      extras.push(ex(cajaBiselada(0.13, 0.05, 0.034, 0.007).translate(0.06, -0.014, 0), 'metal'));
      // manija del cerrojo, doblada hacia abajo
      extras.push(ex(barra([0.10, 0.012, -0.018], [0.16, -0.05, -0.055], 0.008, 5), 'metal'));
      extras.push(ex(esfera(0.014, 6).translate(0.16, -0.05, -0.055), 'metal'));
      extras.push(ex(placa(0.012, 0.030, 0.010, 0.003).translate(0.30, 0.022, 0), 'metal'));
      boca = 0.66; break;
    }
    case 'subfusil': {
      cuerpo.push(grip());
      cuerpo.push(extruirPerfil([[-0.20, -0.045], [0.05, -0.05], [0.05, 0.02], [-0.20, 0.02]], 0.044, 0.008, 2));
      extras.push(ex(cajaBiselada(0.30, 0.075, 0.048, 0.008).translate(0.04, 0.0, 0), 'metal'));
      extras.push(ex(canio(0.011, 0.18, 0.36), 'metal'));
      // cargador recto hacia abajo y culata de alambre
      extras.push(ex(cajaBiselada(0.030, 0.20, 0.036, 0.005).rotateZ(-0.06).translate(0.10, -0.12, 0), 'metalOsc'));
      extras.push(ex(tubo([[-0.20, -0.02, 0.038], [-0.34, -0.03, 0.030], [-0.34, -0.03, -0.030],
        [-0.20, -0.02, -0.038]], 0.008, 4), 'metal'));
      extras.push(ex(revolucion([[0.012, 0], [0.022, 0], [0.022, 0.05], [0.012, 0.05]], 8)
        .rotateZ(Math.PI / 2).translate(0.36, 0, 0), 'metal'));
      boca = 0.40; break;
    }
    case 'asalto': {
      cuerpo.push(grip());
      cuerpo.push(extruirPerfil([[-0.30, -0.038], [0.06, -0.042], [0.06, 0.026], [-0.30, 0.022]], 0.042, 0.008, 2));
      extras.push(ex(cajaBiselada(0.34, 0.085, 0.046, 0.008).translate(0.06, 0.005, 0), 'metalOsc'));
      extras.push(ex(canio(0.010, 0.22, 0.46), 'metal'));
      extras.push(ex(cajaBiselada(0.16, 0.05, 0.05, 0.008).translate(0.32, 0.02, 0), 'metalOsc')); // guardamanos
      // cargador curvo: dos bloques con inclinación distinta
      extras.push(ex(cajaBiselada(0.036, 0.13, 0.038, 0.005).rotateZ(0.18).translate(0.10, -0.10, 0), 'metalOsc'));
      extras.push(ex(cajaBiselada(0.036, 0.10, 0.038, 0.005).rotateZ(0.42).translate(0.14, -0.20, 0), 'metalOsc'));
      // mira réflex arriba: el rasgo que lo separa del subfusil a 80 m
      extras.push(ex(cajaBiselada(0.10, 0.055, 0.036, 0.007).translate(0.06, 0.075, 0), 'metalOsc'));
      extras.push(ex(placa(0.006, 0.03, 0.028, 0.002).translate(0.108, 0.082, 0), 'emis'));
      extras.push(ex(placa(0.14, 0.014, 0.032, 0.004).translate(-0.30, 0.0, 0), 'metalOsc'));
      boca = 0.48; break;
    }
    case 'pesado': {
      cuerpo.push(grip());
      cuerpo.push(extruirPerfil([[-0.34, -0.05], [0.08, -0.055], [0.08, 0.035], [-0.34, 0.03]], 0.056, 0.010, 2));
      extras.push(ex(cajaBiselada(0.44, 0.11, 0.062, 0.012).translate(0.08, 0.01, 0), 'metal'));
      extras.push(ex(canio(0.016, 0.28, 0.62), 'metal'));
      extras.push(ex(disco(0.075, 0.055, 12).rotateX(Math.PI / 2).translate(0.06, -0.11, 0), 'metalOsc'));
      extras.push(ex(placa(0.26, 0.010, 0.014, 0.003).translate(0.10, 0.072, 0.030), 'emis'));
      extras.push(ex(placa(0.26, 0.010, 0.014, 0.003).translate(0.10, 0.072, -0.030), 'emis'));
      extras.push(ex(revolucion([[0.016, 0], [0.036, 0], [0.036, 0.07], [0.016, 0.07]], 10)
        .rotateZ(Math.PI / 2).translate(0.62, 0, 0), 'metal'));
      boca = 0.70; break;
    }
    case 'rifle_largo': {
      cuerpo.push(culata(-0.40, 0.16, 0.085));
      cuerpo.push(extruirPerfil([[-0.03, -0.03], [0.52, -0.024], [0.52, 0.008], [-0.03, 0.014]], 0.030, 0.005, 2));
      extras.push(ex(canio(0.0105, -0.04, 0.82), 'metal'));
      extras.push(ex(cajaBiselada(0.12, 0.045, 0.032, 0.006).translate(0.05, -0.012, 0), 'metal'));
      extras.push(ex(placa(0.010, 0.036, 0.010, 0.003).translate(0.74, 0.024, 0), 'metal'));
      boca = 0.82; break;
    }
    case 'rifle_mira': {
      cuerpo.push(culata(-0.40, 0.16, 0.09));
      cuerpo.push(extruirPerfil([[-0.03, -0.032], [0.50, -0.026], [0.50, 0.010], [-0.03, 0.016]], 0.032, 0.005, 2));
      extras.push(ex(canio(0.011, -0.04, 0.80), 'metal'));
      // mira telescópica larga y gruesa: silueta de francotirador
      extras.push(ex(cilindroConico(0.026, 0.030, 0.34, 10).rotateZ(-Math.PI / 2).translate(0.16, 0.075, 0), 'metalOsc'));
      extras.push(ex(disco(0.032, 0.012, 10).rotateZ(Math.PI / 2).translate(0.335, 0.075, 0), 'vidrio'));
      extras.push(ex(placa(0.02, 0.05, 0.018, 0.004).translate(0.05, 0.045, 0), 'metal'));
      extras.push(ex(placa(0.02, 0.05, 0.018, 0.004).translate(0.28, 0.045, 0), 'metal'));
      extras.push(ex(barra([0.44, -0.02, 0], [0.50, -0.18, 0.09], 0.008, 4), 'metal'));
      extras.push(ex(barra([0.44, -0.02, 0], [0.50, -0.18, -0.09], 0.008, 4), 'metal'));
      boca = 0.80; break;
    }
    case 'rifle_bipode': {
      cuerpo.push(grip());
      cuerpo.push(extruirPerfil([[-0.30, -0.042], [0.06, -0.046], [0.06, 0.028], [-0.30, 0.024]], 0.044, 0.008, 2));
      extras.push(ex(cajaBiselada(0.40, 0.09, 0.05, 0.009).translate(0.10, 0.008, 0), 'metalOsc'));
      extras.push(ex(canio(0.011, 0.30, 0.66), 'metal'));
      extras.push(ex(cilindroConico(0.024, 0.026, 0.26, 10).rotateZ(-Math.PI / 2).translate(0.16, 0.072, 0), 'metalOsc'));
      extras.push(ex(disco(0.030, 0.012, 10).rotateZ(Math.PI / 2).translate(0.29, 0.072, 0), 'vidrio'));
      extras.push(ex(cajaBiselada(0.034, 0.14, 0.038, 0.005).rotateZ(0.14).translate(0.12, -0.10, 0), 'metalOsc'));
      extras.push(ex(barra([0.40, -0.02, 0], [0.46, -0.20, 0.10], 0.008, 4), 'metal'));
      extras.push(ex(barra([0.40, -0.02, 0], [0.46, -0.20, -0.10], 0.008, 4), 'metal'));
      boca = 0.68; break;
    }
    case 'riel': {
      cuerpo.push(grip());
      cuerpo.push(extruirPerfil([[-0.34, -0.05], [0.06, -0.055], [0.06, 0.04], [-0.34, 0.035]], 0.05, 0.009, 2));
      extras.push(ex(cajaBiselada(0.32, 0.10, 0.055, 0.012).translate(0.02, 0.01, 0), 'metal'));
      // dos rieles paralelos con el hueco vivo en el medio
      extras.push(ex(placa(0.62, 0.020, 0.018, 0.005).translate(0.42, 0.030, 0.028), 'metal'));
      extras.push(ex(placa(0.62, 0.020, 0.018, 0.005).translate(0.42, 0.030, -0.028), 'metal'));
      extras.push(ex(placa(0.60, 0.008, 0.030, 0.002).translate(0.42, 0.030, 0), 'emis'));
      for (let i = 0; i < 3; i++) {
        extras.push(ex(toroide(0.045, 0.012, 5, 10).rotateY(Math.PI / 2).translate(0.20 + i * 0.20, 0.030, 0), 'metalOsc'));
      }
      extras.push(ex(cajaBiselada(0.10, 0.09, 0.07, 0.012).translate(-0.10, -0.02, 0), 'emis'));
      boca = 0.74; break;
    }
    case 'carabina': {
      cuerpo.push(culata(-0.28, 0.12, 0.075));
      cuerpo.push(extruirPerfil([[-0.02, -0.03], [0.32, -0.024], [0.32, 0.008], [-0.02, 0.014]], 0.030, 0.005, 2));
      extras.push(ex(canio(0.0105, -0.02, 0.46), 'metal'));
      extras.push(ex(cajaBiselada(0.10, 0.042, 0.030, 0.006).translate(0.04, -0.012, 0), 'metal'));
      boca = 0.46; break;
    }
    case 'escopeta': {
      cuerpo.push(culata(-0.32, 0.10, 0.08));
      cuerpo.push(extruirPerfil([[-0.02, -0.036], [0.30, -0.03], [0.30, 0.006], [-0.02, 0.014]], 0.038, 0.006, 2));
      extras.push(ex(canio(0.018, -0.02, 0.44, 10), 'metal'));
      extras.push(ex(canio(0.014, 0.02, 0.40, 8).translate(0, -0.032, 0), 'metalOsc'));
      extras.push(ex(disco(0.058, 0.075, 12).rotateZ(Math.PI / 2).translate(0.06, -0.05, 0), 'metalOsc'));
      boca = 0.44; break;
    }
    case 'at': {
      cuerpo.push(culata(-0.46, 0.10, 0.10));
      cuerpo.push(extruirPerfil([[-0.05, -0.045], [0.30, -0.038], [0.30, 0.014], [-0.05, 0.022]], 0.042, 0.007, 2));
      extras.push(ex(canio(0.018, -0.06, 1.02, 10), 'metal'));
      extras.push(ex(cajaBiselada(0.20, 0.075, 0.05, 0.008).translate(0.06, 0.0, 0), 'metal'));
      // freno de boca de dos cámaras
      extras.push(ex(revolucion([[0.018, 0], [0.042, 0], [0.042, 0.10], [0.018, 0.10]], 10)
        .rotateZ(Math.PI / 2).translate(1.02, 0, 0), 'metalOsc'));
      extras.push(ex(barra([0.56, -0.02, 0], [0.62, -0.26, 0.14], 0.010, 4), 'metal'));
      extras.push(ex(barra([0.56, -0.02, 0], [0.62, -0.26, -0.14], 0.010, 4), 'metal'));
      boca = 1.12; break;
    }
    case 'bazuca': {
      cuerpo.push(cilindroConico(0.052, 0.052, 1.05, 12).rotateZ(-Math.PI / 2).translate(0.30, 0.02, 0));
      extras.push(ex(cilindroConico(0.052, 0.085, 0.16, 12).rotateZ(-Math.PI / 2).translate(-0.30, 0.02, 0), 'metalOsc'));
      extras.push(ex(grip().translate(0.06, 0, 0), 'metalOsc'));
      extras.push(ex(grip().translate(0.30, 0, 0), 'metalOsc'));
      extras.push(ex(placa(0.10, 0.10, 0.006, 0.002).translate(0.16, 0.10, 0.045), 'metalOsc'));
      extras.push(ex(toroide(0.056, 0.010, 5, 12).rotateY(Math.PI / 2).translate(0.70, 0.02, 0), 'metal'));
      extras.push(ex(toroide(0.056, 0.010, 5, 12).rotateY(Math.PI / 2).translate(0.10, 0.02, 0), 'metal'));
      boca = 0.84; break;
    }
    case 'misil': {
      cuerpo.push(cilindroConico(0.062, 0.062, 0.92, 12).rotateZ(-Math.PI / 2).translate(0.26, 0.03, 0));
      extras.push(ex(cajaBiselada(0.24, 0.14, 0.13, 0.02).translate(0.02, 0.16, 0), 'metalOsc'));
      extras.push(ex(disco(0.045, 0.02, 10).rotateZ(Math.PI / 2).translate(0.15, 0.16, 0), 'vidrio'));
      extras.push(ex(grip().translate(0.02, -0.01, 0), 'metalOsc'));
      extras.push(ex(cajaBiselada(0.14, 0.06, 0.09, 0.012).translate(-0.14, 0.0, 0), 'metal'));
      boca = 0.72; break;
    }
    case 'enjambre': {
      cuerpo.push(cajaBiselada(0.46, 0.20, 0.20, 0.024).translate(0.20, 0.06, 0));
      // celdas hexagonales encendidas: se lee de lejos
      for (let i = 0; i < 3; i++) for (let j = 0; j < 2; j++) {
        const cel = cilindroConico(0.026, 0.026, 0.04, 6).rotateZ(-Math.PI / 2);
        extras.push(ex(cel.translate(0.42, 0.0 + j * 0.075 + 0.03, -0.062 + i * 0.062), 'emis'));
      }
      extras.push(ex(grip().translate(0.06, -0.02, 0), 'metalOsc'));
      extras.push(ex(cajaBiselada(0.10, 0.13, 0.10, 0.014).translate(-0.06, 0.06, 0), 'metal'));
      extras.push(ex(placa(0.30, 0.012, 0.014, 0.003).translate(0.22, 0.165, 0.09), 'emis'));
      extras.push(ex(placa(0.30, 0.012, 0.014, 0.003).translate(0.22, 0.165, -0.09), 'emis'));
      boca = 0.46; break;
    }
    case 'pica': {
      cuerpo.push(cilindroConico(0.017, 0.021, 3.30, 8).rotateZ(-Math.PI / 2).translate(1.30, 0, 0));
      extras.push(ex(extruirPerfil([[2.86, -0.020], [3.20, 0.0], [2.86, 0.020]], 0.016, 0.003, 1), 'metal'));
      extras.push(ex(revolucion([[0.021, 0], [0.032, 0.02], [0.021, 0.06]], 8)
        .rotateZ(-Math.PI / 2).translate(2.84, 0, 0), 'metal'));
      extras.push(ex(toroide(0.026, 0.008, 5, 8).rotateY(Math.PI / 2).translate(-0.34, 0, 0), 'metal'));
      boca = 3.20; break;
    }
    case 'sable': {
      cuerpo.push(cilindroConico(0.018, 0.023, 0.15, 8).rotateZ(-Math.PI / 2).translate(-0.06, 0, 0));
      // Hoja curva por segmentos: la curva es la firma del húsar. Alargada de
      // 0.91 a 1.24 y engrosada al doble de canto — el sable es lo que separa
      // al jinete del infante cuando las dos masas están a 80 m, y una hoja de
      // dos píxeles se pierde antes que el resto de la unidad.
      const hoja = [];
      for (let i = 0; i < 8; i++) {
        const t = i / 7, x = 0.05 + t * 1.02, y = -Math.sin(t * 1.15) * 0.21;
        hoja.push(extruirPerfil([[x, y - 0.026], [x + 0.16, y - 0.022], [x + 0.16, y + 0.010], [x, y + 0.016]], 0.016, 0.003, 1));
      }
      extras.push(ex(fusionar(hoja), 'metal'));
      extras.push(ex(toroide(0.055, 0.009, 5, 10).rotateX(Math.PI / 2).rotateZ(0.4).translate(0.03, -0.02, 0), 'acento'));
      boca = 1.05; break;
    }
    case 'hacha': {
      cuerpo.push(cilindroConico(0.017, 0.020, 0.86, 8).rotateZ(-Math.PI / 2).translate(0.30, 0, 0));
      extras.push(ex(extruirPerfil([
        [0.66, -0.02], [0.74, -0.11], [0.80, -0.10], [0.80, 0.10], [0.74, 0.11], [0.66, 0.02],
      ], 0.022, 0.005, 2), 'metal'));
      boca = 0.80; break;
    }
    case 'martillo': {
      cuerpo.push(cilindroConico(0.016, 0.019, 0.44, 8).rotateZ(-Math.PI / 2).translate(0.14, 0, 0));
      extras.push(ex(cajaBiselada(0.09, 0.055, 0.055, 0.010).translate(0.36, 0, 0), 'metal'));
      extras.push(ex(extruirPerfil([[0.30, 0.01], [0.24, 0.055], [0.20, 0.05], [0.28, -0.01]], 0.03, 0.005, 1), 'metal'));
      boca = 0.40; break;
    }
    case 'megafono': {
      cuerpo.push(revolucion([[0.028, 0], [0.030, 0.06], [0.10, 0.30], [0.105, 0.32], [0.028, 0.06]], 12)
        .rotateZ(-Math.PI / 2).translate(0.06, 0.02, 0));
      extras.push(ex(cajaBiselada(0.06, 0.05, 0.05, 0.008).translate(0.02, -0.04, 0), 'metalOsc'));
      boca = 0.38; break;
    }
    case 'consola': {
      cuerpo.push(cajaBiselada(0.20, 0.03, 0.30, 0.008).rotateZ(-0.35).translate(0.10, 0.02, 0));
      extras.push(ex(placa(0.16, 0.006, 0.25, 0.002).rotateZ(-0.35).translate(0.115, 0.036, 0), 'emis'));
      boca = 0.22; break;
    }
    case 'red': {
      cuerpo.push(cilindroConico(0.014, 0.016, 1.10, 8).rotateZ(-Math.PI / 2).translate(0.38, 0, 0));
      extras.push(ex(toroide(0.16, 0.010, 5, 14).rotateY(Math.PI / 2).translate(0.93, 0, 0), 'metal'));
      boca = 0.95; break;
    }
    default: {
      cuerpo.push(culata(-0.32, 0.12));
      extras.push(ex(canio(0.011, -0.02, 0.55), 'metal'));
      boca = 0.55;
    }
  }
  const g = fusionar(cuerpo);
  return conBoca(marcar(g, extras, tipo === 'mosquete' || tipo === 'cerrojo' ||
    tipo === 'rifle_largo' || tipo === 'rifle_mira' || tipo === 'carabina' ||
    tipo === 'escopeta' || tipo === 'at' || tipo === 'pica' || tipo === 'hacha' ||
    tipo === 'martillo' ? 'madera' : 'metalOsc'), boca, 0, 0);
}

/**
 * Tubo de artillería anclado en los muñones (y = 0), apuntando a +X.
 * `calibre` es el radio del ánima; `largo` la longitud del tubo.
 */
export function canonPieza(calibre = 0.06, largo = 1.8, frenoBoca = true) {
  const partes = [], extras = [];
  const rExt = calibre * 1.9;
  partes.push(revolucion([
    [rExt * 1.35, 0], [rExt * 1.35, 0.10], [rExt * 1.05, 0.14],
    [rExt * 0.95, largo * 0.55], [rExt * 0.82, largo - 0.06], [rExt * 0.86, largo],
    [calibre, largo],
  ], 12).rotateZ(-Math.PI / 2).translate(-0.16, 0, 0));
  // recámara
  partes.push(revolucion([
    [0, -0.02], [rExt * 1.4, -0.02], [rExt * 1.45, 0.10], [rExt * 1.2, 0.20], [0, 0.20],
  ], 12).rotateZ(Math.PI / 2).translate(-0.16, 0, 0));
  // muñones: los dos tacos que apoyan en la cureña
  const mun = disco(rExt * 0.55, 0.10, 8).rotateX(Math.PI / 2);
  extras.push(ex(mun.clone().translate(0, 0, rExt * 1.5), 'metal'));
  extras.push(ex(mun.clone().translate(0, 0, -rExt * 1.5), 'metal'));
  if (frenoBoca) {
    const boca = revolucion([
      [rExt * 0.86, 0], [rExt * 1.35, 0.01], [rExt * 1.35, 0.09], [rExt * 0.9, 0.10],
    ], 12).rotateZ(-Math.PI / 2).translate(largo - 0.16, 0, 0);
    extras.push(ex(boca, 'metalOsc'));
    const ranura = placa(0.03, rExt * 3.0, 0.012, 0.003);
    extras.push(ex(ranura.clone().translate(largo - 0.13, 0, 0), 'metalOsc'));
    extras.push(ex(ranura.clone().translate(largo - 0.09, 0, 0), 'metalOsc'));
  }
  return conBoca(marcar(fusionar(partes), extras, 'metal'), largo - 0.16 + (frenoBoca ? 0.10 : 0), 0, 0);
}

/* ════════════════════ 4. Rodaje y chapa ════════════════════ */

/**
 * Rueda con el eje en Z, centrada en el origen.
 * `radios > 0` da rueda de rayos (cureña, carro); `0` da rueda maciza de goma.
 */
export function rueda(r = 0.35, radios = 0, ancho = 0.12) {
  const partes = [], extras = [];
  const llanta = toroide(r * 0.93, r * 0.13, 6, 16).rotateY(0);
  partes.push(llanta);
  if (radios > 0) {
    extras.push(ex(toroide(r * 0.93, r * 0.055, 5, 16), 'metal'));
    for (let i = 0; i < radios; i++) {
      const a = (i / radios) * TAU;
      const rad = cilindroConico(r * 0.035, r * 0.05, r * 0.86, 5)
        .rotateZ(Math.PI / 2).rotateZ(a).translate(Math.cos(a) * r * 0.45, Math.sin(a) * r * 0.45, 0);
      partes.push(rad);
    }
    extras.push(ex(disco(r * 0.17, ancho * 1.2, 10).rotateX(Math.PI / 2), 'metal'));
    return marcar(fusionar(partes), extras, 'madera');
  }
  // neumático: banda de rodadura con tacos
  partes.length = 0;
  partes.push(disco(r, ancho, 16).rotateX(Math.PI / 2));
  const taco = cajaBiselada(0.05, 0.035, ancho * 1.06, 0.006);
  for (let i = 0; i < 10; i++) {
    const a = (i / 10) * TAU;
    partes.push(taco.clone().rotateZ(a).translate(Math.cos(a) * r * 0.99, Math.sin(a) * r * 0.99, 0));
  }
  extras.push(ex(disco(r * 0.55, ancho * 1.08, 12).rotateX(Math.PI / 2), 'metal'));
  extras.push(ex(disco(r * 0.20, ancho * 1.3, 8).rotateX(Math.PI / 2), 'metalOsc'));
  return marcar(fusionar(partes), extras, 'goma');
}

/** Rueda de rodadura de oruga (bogie), eje en Z. */
export function ruedaRodadura(r = 0.22, ancho = 0.10) {
  const disc = disco(r, ancho, 12).rotateX(Math.PI / 2);
  const banda = toroide(r * 0.97, r * 0.12, 5, 14);
  const cubo = disco(r * 0.32, ancho * 1.25, 8).rotateX(Math.PI / 2);
  return marcar(fusionar([disc, cubo]), [ex(banda, 'goma')], 'metal');
}

/** Un eslabón de oruga, centrado, ancho a lo largo de Z. */
export function eslabonOruga(ancho = 0.42, paso = 0.16, alto = 0.05) {
  const plancha = cajaBiselada(paso * 0.94, alto, ancho, 0.008);
  const diente = cajaBiselada(paso * 0.32, alto * 1.1, ancho * 0.16, 0.006).translate(0, alto * 0.85, 0);
  const nervio = placa(paso * 0.9, alto * 0.5, ancho * 0.9, 0.004).translate(0, -alto * 0.55, 0);
  return marcar(fusionar([plancha, diente, nervio]), [], 'metalOsc');
}

/** Faro apuntando a +X, anclado en su base trasera. */
export function faro(r = 0.07, protegido = true) {
  const cuerpo = cilindroConico(r, r * 0.92, r * 1.1, 10).rotateZ(-Math.PI / 2);
  const partes = [cuerpo], extras = [];
  extras.push(ex(disco(r * 0.88, 0.014, 10).rotateZ(Math.PI / 2).translate(r * 0.56, 0, 0), 'emis'));
  if (protegido) {
    extras.push(ex(toroide(r * 1.05, r * 0.10, 5, 10).rotateY(Math.PI / 2).translate(r * 0.5, 0, 0), 'metalOsc'));
    extras.push(ex(placa(0.010, r * 2.2, 0.012, 0.003).translate(r * 0.6, 0, 0), 'metalOsc'));
  }
  return marcar(fusionar(partes), extras, 'metal');
}

/** Antena corta y flexible, anclada en su base. */
export function antenaCorta(alto = 0.9, r = 0.007, curva = 0.12) {
  const g = tubo([[0, 0, 0], [curva * 0.3, alto * 0.45, 0], [curva, alto, 0]], r, 4);
  const base = cilindroConico(r * 3.5, r * 4.5, 0.035, 8).translate(0, 0.015, 0);
  return marcar(fusionar([g, base]), [], 'metalOsc');
}

/** Escotilla circular con tapa, anclada en el techo. */
export function escotilla(r = 0.28, abierta = false) {
  const aro = toroide(r, r * 0.14, 5, 14).rotateX(Math.PI / 2);
  const tapa = revolucion([[0, 0.045], [r * 0.86, 0.035], [r * 0.9, 0.005], [0, 0.0]], 14);
  const manija = tubo([[-r * 0.4, 0.05, 0], [0, 0.075, 0], [r * 0.4, 0.05, 0]], 0.012, 4);
  if (abierta) {
    tapa.rotateZ(-1.1).translate(-r * 0.9, r * 0.5, 0);
    manija.rotateZ(-1.1).translate(-r * 0.9, r * 0.5, 0);
  }
  return marcar(fusionar([aro, tapa, manija]), [], 'metal');
}

/** Hélice/rotor en el plano XZ (gira sobre Y), anclada en el cubo. */
export function helice(palas = 2, r = 0.55, cuerda = 0.075) {
  const partes = [];
  for (let i = 0; i < palas; i++) {
    const a = (i / palas) * TAU;
    const pala = extruirPerfil([
      [-cuerda * 0.5, 0.06], [cuerda * 0.5, 0.09], [cuerda * 0.32, r], [-cuerda * 0.30, r],
    ], 0.012, 0.003, 1);
    pala.rotateX(Math.PI / 2);      // acostada en XZ
    pala.rotateZ(0.0);
    pala.rotateY(a);
    partes.push(pala);
  }
  const cubo = disco(cuerda * 0.55, 0.05, 8);
  return marcar(fusionar([...partes, cubo]), [], 'metalOsc');
}

/** Rejilla/parrilla de refrigeración: placa con listones. Ancla en su centro. */
export function rejilla(sx = 0.5, sz = 0.4, listones = 6) {
  const partes = [];
  for (let i = 0; i < listones; i++) {
    const z = -sz / 2 + (i + 0.5) * (sz / listones);
    partes.push(placa(sx, 0.02, sz / listones * 0.55, 0.004).translate(0, 0, z));
  }
  return marcar(fusionar(partes), [], 'metalOsc');
}

/** Caja de herramientas / bidón sobre el guardabarros. */
export function cajaHerramientas(sx = 0.34, sy = 0.16, sz = 0.20) {
  const c = cajaBiselada(sx, sy, sz, 0.018);
  const cierre = placa(0.02, sy * 0.7, sz * 0.25, 0.004).translate(sx / 2, 0, 0);
  return marcar(fusionar([c, cierre]), [], 'metalOsc');
}

/* ════════════════════ 5. Caballo ════════════════════ */

/**
 * Caballo anclado en el suelo entre las manos y las patas (y = 0, mira a +X).
 * Devuelve el cuerpo y publica en `userData`:
 *   `patas`  geometría de una pata (anclada en la articulación superior)
 *   `anclas` [[x, y, z], ...] los 4 puntos de enganche de las patas
 *   `lomo`   altura de la silla (donde se sienta el jinete)
 */
export function caballo(estilo = 'militar') {
  const partes = [], extras = [];
  const yLomo = 1.32, yPecho = 1.05;

  // BARRIL DEL CUERPO — la masa que dice "caballería" antes que cualquier color.
  // Estaba en 0.31 de semieje Z (0.62 de ancho): a escala de juego eso da un
  // caballo de 1,1 m de ancho, o sea una tabla de canto que desde 49° de
  // elevación se lee igual que un infante. Ensanchado a 0.40 el animal ocupa un
  // óvalo horizontal claro y el jinete se le monta encima: dos masas apiladas,
  // que es la silueta inconfundible del montado.
  const cuerpo = esferaAchatada(0.66, 0.44, 0.40, 14).translate(0.02, yPecho + 0.05, 0);
  const grupa = esferaAchatada(0.40, 0.40, 0.38, 12).translate(-0.46, yPecho + 0.06, 0);
  const pecho = esferaAchatada(0.34, 0.38, 0.36, 12).translate(0.46, yPecho + 0.02, 0);
  // cruz: el bulto sobre las paletas. Levanta la línea del lomo justo delante de
  // la silla y evita que el caballo se lea como un cilindro recto.
  const cruz = esferaAchatada(0.26, 0.22, 0.30, 10).translate(0.30, yPecho + 0.30, 0);
  partes.push(cuerpo, grupa, pecho, cruz);

  // cuello: cono inclinado hacia adelante y arriba
  const cuello = cilindroConico(0.17, 0.30, 0.66, 12);
  cuello.rotateZ(-0.62).translate(0.72, yPecho + 0.38, 0);
  partes.push(cuello);

  // cabeza con testuz y hocico
  const craneo = esferaAchatada(0.15, 0.115, 0.105, 10).translate(0.99, yPecho + 0.62, 0);
  const hocico = cilindroConico(0.072, 0.095, 0.28, 10).rotateZ(-1.15).translate(1.14, yPecho + 0.50, 0);
  partes.push(craneo, hocico);
  const oreja = extruirPerfil([[-0.03, 0], [0.03, 0], [0, 0.09]], 0.022, 0.004, 1);
  partes.push(oreja.clone().translate(0.94, yPecho + 0.71, 0.055));
  partes.push(oreja.clone().translate(0.94, yPecho + 0.71, -0.055));

  // crin y cola: contorno y color de jugador en movimiento
  const crin = extruirPerfil([
    [0.30, 0.0], [0.98, 0.30], [1.00, 0.40], [0.28, 0.10],
  ], 0.05, 0.008, 2);
  extras.push(ex(crin.translate(0, yPecho + 0.30, 0), 'oscuro'));
  const cola = tubo([[-0.72, yPecho + 0.22, 0], [-0.88, yPecho - 0.05, 0],
    [-0.92, yPecho - 0.42, 0]], 0.055, 6);
  extras.push(ex(cola, 'oscuro'));

  if (estilo === 'militar') {
    // MANTILLA: la zona de bando de la caballería. Es lo único teñido del
    // caballo, mira hacia arriba (o sea que la cámara la ve de lleno) y queda
    // pegada a la capa del jinete: las dos juntas forman UNA mancha continua.
    const mantilla = cajaBiselada(0.86, 0.06, 0.92, 0.016).translate(-0.04, yLomo + 0.02, 0);
    extras.push(ex(mantilla, 'jugador'));
    const silla = esferaAchatada(0.26, 0.10, 0.24, 10).translate(-0.02, yLomo + 0.10, 0);
    extras.push(ex(silla, 'cuero'));
    extras.push(ex(extruirPerfil([[0.16, 0], [0.24, 0], [0.20, 0.11]], 0.10, 0.006, 1)
      .translate(0, yLomo + 0.10, 0), 'cuero'));
    // estribos
    extras.push(ex(toroide(0.055, 0.010, 5, 8).translate(-0.02, yLomo - 0.24, 0.38), 'metal'));
    extras.push(ex(toroide(0.055, 0.010, 5, 8).translate(-0.02, yLomo - 0.24, -0.38), 'metal'));
    // cabezada y riendas
    extras.push(ex(toroide(0.10, 0.010, 5, 10).rotateY(Math.PI / 2).rotateZ(0.4)
      .translate(1.06, yPecho + 0.56, 0), 'cuero'));
    extras.push(ex(tubo([[1.06, yPecho + 0.58, 0.09], [0.60, yPecho + 0.46, 0.14],
      [0.10, yLomo + 0.14, 0.12]], 0.010, 4), 'cuero'));
    extras.push(ex(tubo([[1.06, yPecho + 0.58, -0.09], [0.60, yPecho + 0.46, -0.14],
      [0.10, yLomo + 0.14, -0.12]], 0.010, 4), 'cuero'));
  } else if (estilo === 'tiro') {
    extras.push(ex(toroide(0.30, 0.035, 5, 12).rotateY(Math.PI / 2).rotateZ(0.25)
      .translate(0.40, yPecho + 0.22, 0), 'cuero'));
    extras.push(ex(tubo([[0.34, yPecho + 0.16, 0.24], [-0.30, yPecho + 0.02, 0.30],
      [-0.90, yPecho - 0.02, 0.30]], 0.014, 4), 'cuero'));
    extras.push(ex(tubo([[0.34, yPecho + 0.16, -0.24], [-0.30, yPecho + 0.02, -0.30],
      [-0.90, yPecho - 0.02, -0.30]], 0.014, 4), 'cuero'));
  }

  // Una pata: muslo cónico + caña + casco, anclada en la articulación.
  // Engrosada un escalón (0.105 -> 0.128 en el muslo) por el mismo motivo que
  // las piernas humanas: a esta escala una pata anatómica es un alambre.
  const muslo = cilindroConico(0.128, 0.070, 0.50, 8).translate(0, -0.25, 0);
  const cania = cilindroConico(0.056, 0.046, 0.42, 7).translate(0.02, -0.70, 0);
  const cascoP = cilindroConico(0.070, 0.060, 0.10, 8).translate(0.03, -0.95, 0);
  const pata = marcar(fusionar([muslo, cania]), [ex(cascoP, 'oscuro')], 'tela2');

  const g = fusionar(partes);
  g.userData.patas = pata;
  g.userData.anclas = [
    [0.54, yPecho - 0.04, 0.25], [0.54, yPecho - 0.04, -0.25],
    [-0.50, yPecho - 0.02, 0.26], [-0.50, yPecho - 0.02, -0.26],
  ];
  g.userData.lomo = yLomo + 0.12;
  return marcar(g, extras, 'tela2');
}

/* ════════════════════ 6. Cascos de nave ════════════════════ */

/**
 * Casco de barco anclado en la línea de flotación (y = 0, proa a +X).
 * Perfil real: proa levantada, pantoque y popa. Nada de cajas flotando.
 */
export function cascoNave(largo = 8, manga = 2.4, francobordo = 0.9, estilo = 'vela') {
  const partes = [], extras = [];
  const L = largo / 2;
  const perfil = estilo === 'moderno'
    ? [[-L, -0.55], [-L * 0.98, francobordo * 0.9], [L * 0.55, francobordo * 0.95],
      [L, francobordo * 1.15], [L * 1.02, -0.15], [L * 0.5, -0.62], [-L * 0.6, -0.66]]
    : [[-L, -0.35], [-L * 0.96, francobordo * 1.15], [L * 0.5, francobordo * 0.9],
      [L * 0.99, francobordo * 1.35], [L * 1.0, -0.10], [L * 0.4, -0.60], [-L * 0.7, -0.58]];
  partes.push(extruirPerfil(perfil, manga, 0.05, 3));
  // afinado de proa: dos cuñas que cierran el casco
  const cunia = extruirPerfil([[L * 0.45, -0.5], [L * 1.02, -0.10], [L * 0.99, francobordo],
    [L * 0.5, francobordo * 0.9]], manga * 0.45, 0.04, 2);
  partes.push(cunia);
  // cubierta
  extras.push(ex(cajaBiselada(largo * 0.92, 0.06, manga * 0.92, 0.02)
    .translate(0, francobordo * 0.96, 0), 'madera'));
  // regala
  const regala = placa(largo * 0.94, 0.10, 0.07, 0.012);
  // la regala es una tira fina que da toda la vuelta: teñida de bando sería un
  // contorno de color en vez de una mancha, así que va en gama desaturada
  extras.push(ex(regala.clone().translate(0, francobordo + 0.03, manga / 2 - 0.04), estilo === 'moderno' ? 'metal' : 'correaje'));
  extras.push(ex(regala.clone().translate(0, francobordo + 0.03, -(manga / 2 - 0.04)), estilo === 'moderno' ? 'metal' : 'correaje'));
  return marcar(fusionar(partes), extras, estilo === 'moderno' ? 'metal' : 'madera');
}

/** Mástil con vergas y velas, anclado en la cubierta. */
export function mastil(alto = 5.0, vergas = 2, ancho = 2.0) {
  const partes = [], extras = [];
  partes.push(cilindroConico(0.055, 0.085, alto, 8).translate(0, alto / 2, 0));
  for (let i = 0; i < vergas; i++) {
    const y = alto * (0.42 + i * 0.31);
    const w = ancho * (1 - i * 0.22);
    partes.push(cilindroConico(0.032, 0.032, w, 6).rotateX(Math.PI / 2).translate(0, y, 0));
    const vela = placa(0.03, alto * 0.24, w * 0.94, 0.008);
    extras.push(ex(vela.translate(0, y - alto * 0.135, 0), i === 0 ? 'jugador' : 'correaje'));
  }
  extras.push(ex(tubo([[0, alto * 0.98, 0], [0, alto * 0.6, ancho * 0.42], [0, alto * 0.12, ancho * 0.5]], 0.008, 4), 'correaje'));
  extras.push(ex(tubo([[0, alto * 0.98, 0], [0, alto * 0.6, -ancho * 0.42], [0, alto * 0.12, -ancho * 0.5]], 0.008, 4), 'correaje'));
  return marcar(fusionar(partes), extras, 'madera');
}

/* ════════════════════ 7. Extras de silueta ════════════════════ */

/** Bandera/banderín rígido: color de jugador puro, se ve desde cualquier lado. */
export function banderin(largo = 0.45, alto = 0.28, asta = 1.5) {
  const partes = [], extras = [];
  partes.push(cilindroConico(0.011, 0.014, asta, 6).translate(0, asta / 2, 0));
  extras.push(ex(cilindroConico(0.02, 0.005, 0.09, 6).translate(0, asta + 0.04, 0), 'acento'));
  const pano = extruirPerfil([
    [0, 0], [largo, 0.03], [largo * 0.78, alto * 0.5], [largo, alto], [0, alto],
  ], 0.014, 0.004, 2);
  extras.push(ex(pano.rotateY(Math.PI / 2).translate(0, asta - alto - 0.06, 0), 'jugador'));
  return marcar(fusionar(partes), extras, 'madera');
}

/** Panel solar / placa fotovoltaica de las edades tardías. */
export function panelSolar(sx = 0.7, sz = 0.45) {
  const marco = cajaBiselada(sx, 0.02, sz, 0.008);
  const celdas = placa(sx * 0.9, 0.008, sz * 0.88, 0.003).translate(0, 0.014, 0);
  return marcar(marco, [ex(celdas, 'vidrio')], 'metalOsc');
}

/** Sensor/domo óptico de las unidades autónomas. */
export function sensorDomo(r = 0.14) {
  const base = disco(r * 1.05, r * 0.35, 10).translate(0, r * 0.15, 0);
  const domo = mediaEsfera(r, 12).translate(0, r * 0.3, 0);
  const ojo = disco(r * 0.45, r * 0.1, 10).rotateZ(Math.PI / 2).translate(r * 0.9, r * 0.55, 0);
  return marcar(base, [ex(domo, 'vidrio'), ex(ojo, 'emis')], 'metalOsc');
}

/** Escape con salida hacia arriba, anclado en su base. */
export function escape(alto = 0.5, r = 0.045) {
  const t = cilindroConico(r, r * 1.15, alto, 8).translate(0, alto / 2, 0);
  const capucha = cilindroConico(r * 1.5, r * 1.5, 0.05, 8).translate(0, alto + 0.02, 0);
  const protector = toroide(r * 1.7, r * 0.18, 5, 10).rotateX(Math.PI / 2).translate(0, alto * 0.55, 0);
  return marcar(fusionar([t, capucha]), [ex(protector, 'metalOsc')], 'metalOsc');
}

/**
 * Media caña (arco de circunferencia extruido): toldos de carro, capotas,
 * túneles. El arco abre sobre Z y la caña corre por X.
 */
export function mediaCania(radio = 0.85, largo = 2.4, espesor = 0.05, seg = 12) {
  const pts = [];
  for (let i = 0; i <= seg; i++) {
    const a = (Math.PI * i) / seg;
    pts.push([Math.cos(a) * radio, Math.sin(a) * radio]);
  }
  for (let i = seg; i >= 0; i--) {
    const a = (Math.PI * i) / seg;
    pts.push([Math.cos(a) * (radio - espesor), Math.sin(a) * (radio - espesor)]);
  }
  return marcar(extruirPerfil(pts, largo, 0.008, 1).rotateY(Math.PI / 2), [], 'tela');
}

export default {
  cacheado, marcar, ex, conBoca, fusionar, mover, girar, propagar, mediaCania,
  formaRect, cajaBiselada, extruirPerfil, capsula, cilindroConico, disco, esfera,
  mediaEsfera, esferaAchatada, toroide, revolucion, placa, tubo, barra, miembro,
  H, torsoHumano, cabezaHumana, cinturon, casco, gorra, penacho, bota, guante,
  mochila, correaje, faldon, fusil, canonPieza, rueda, ruedaRodadura, eslabonOruga,
  faro, antenaCorta, escotilla, helice, rejilla, cajaHerramientas, caballo,
  cascoNave, mastil, banderin, panelSolar, sensorDomo, escape,
};
