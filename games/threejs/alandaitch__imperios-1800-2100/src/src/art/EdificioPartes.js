/**
 * EdificioPartes — generadores paramétricos reutilizables de arquitectura.
 *
 * Todo lo que hay acá es PURO: entra números, sale geometría. Ni un material,
 * ni un `Math.random`, ni una referencia a `ctx`. La fábrica
 * (`EdificioFabrica.js`) es la que junta estas piezas, las fusiona por ranura de
 * material y les pone textura.
 *
 * CONVENCIONES
 *  - Metros. Y = arriba. Una celda de rejilla = 2 m.
 *  - Todas las piezas nacen apoyadas en y = 0 y centradas en XZ salvo que el
 *    nombre diga otra cosa. El frente mira a +Z.
 *  - Las funciones que necesitan más de un material devuelven un `THREE.Group`
 *    de mallas marcadas con `userData.ranura` y `userData.tinte`. La fábrica las
 *    absorbe, aplica la matriz mundial y las fusiona. Las de un solo material
 *    devuelven `BufferGeometry` pelada.
 *  - `estilo` es 0..4 = las cinco edades (vapor, eléctrica, atómica,
 *    información, sintética) y cambia proporciones, ornamento y despiece.
 *
 * RANURAS (una por material, así un edificio entero son 3–5 draw calls):
 *   muro · piedra · detalle · jugador · vidrio · emisivo
 */
import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';
import { clamp, lerp } from '../core/RNG.js';

const TAU = Math.PI * 2;
export const RANURAS = ['muro', 'piedra', 'detalle', 'jugador', 'vidrio', 'emisivo'];

/** Material fantasma: las mallas contenedoras nunca llegan a la escena. */
const MAT_NULO = new THREE.MeshBasicMaterial({ visible: false });

/* ═══════════════════════════════════════════════════════════════════════════
   0. Contenedores y utilidades de fusión
   ═══════════════════════════════════════════════════════════════════════════ */

/** Envuelve una geometría marcándole ranura de material y tinte por vértice. */
export function pieza(geo, ranura = 'muro', tinte = 0xffffff) {
  const m = new THREE.Mesh(geo, MAT_NULO);
  m.userData.ranura = ranura;
  m.userData.tinte = tinte;
  return m;
}

/** Agrupa piezas (acepta arrays anidados y nulos). */
export function conjunto(...hijos) {
  const g = new THREE.Group();
  const meter = (h) => {
    if (!h) return;
    if (Array.isArray(h)) { for (const x of h) meter(x); return; }
    g.add(h);
  };
  for (const h of hijos) meter(h);
  return g;
}

/** Coloca una malla o grupo en un solo renglón. */
export function colocar(obj, x = 0, y = 0, z = 0, ry = 0, rx = 0, rz = 0) {
  obj.position.set(x, y, z);
  if (rx || ry || rz) obj.rotation.set(rx, ry, rz);
  return obj;
}

/** Deja la geometría lista para fusionar: sin índice, con uv, sin sobras. */
export function normalizarGeo(g) {
  const x = g.index ? g.toNonIndexed() : g;
  if (!x.attributes.normal) x.computeVertexNormals();
  const n = x.attributes.position.count;
  if (!x.attributes.uv) x.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(n * 2), 2));
  for (const k of Object.keys(x.attributes)) {
    if (k !== 'position' && k !== 'normal' && k !== 'uv') x.deleteAttribute(k);
  }
  x.morphAttributes = {};
  x.clearGroups();
  return x;
}

/** Fusiona una lista de geometrías en una sola (o null si no hay nada). */
export function fusionar(geos) {
  const l = [];
  for (const g of geos) if (g) l.push(normalizarGeo(g));
  if (!l.length) return null;
  if (l.length === 1) return l[0];
  return mergeGeometries(l, false) || l[0];
}

/**
 * UV de caja en espacio local: cada cara proyecta según su normal dominante y
 * `escala` son los metros que ocupa una repetición de la textura. Sin esto el
 * ladrillo se estira y a 80 m se nota igual.
 */
export function uvCaja(geo, escala = 2) {
  const p = geo.attributes.position, n = geo.attributes.normal;
  if (!p || !n) return geo;
  const inv = 1 / Math.max(0.05, escala);
  const uv = new Float32Array(p.count * 2);
  for (let i = 0; i < p.count; i++) {
    const x = p.getX(i), y = p.getY(i), z = p.getZ(i);
    const nx = Math.abs(n.getX(i)), ny = Math.abs(n.getY(i)), nz = Math.abs(n.getZ(i));
    let u, v;
    if (ny >= nx && ny >= nz) { u = x; v = z; }
    else if (nx >= nz) { u = z; v = y; }
    else { u = x; v = y; }
    uv[i * 2] = u * inv;
    uv[i * 2 + 1] = v * inv;
  }
  geo.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
  return geo;
}

/* ═══════════════════════════════════════════════════════════════════════════
   1. Primitivas
   ═══════════════════════════════════════════════════════════════════════════ */

/** Rectángulo de esquinas redondeadas: la base de casi todo el biselado. */
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

/** Caja barata (12 triángulos). Para tornillería y relleno. */
export const caja = (sx, sy, sz) => new THREE.BoxGeometry(sx, sy, sz);
/** Caja barata ya trasladada. */
export const cajaEn = (sx, sy, sz, x = 0, y = 0, z = 0) => new THREE.BoxGeometry(sx, sy, sz).translate(x, y, z);

/**
 * Caja con bisel real (no una BoxGeometry): el chaflán agarra la luz rasante
 * del sol y es lo que separa "caja de juguete" de "sillería".
 * sx = ancho (X), sy = alto (Y), sz = fondo (Z).
 */
export function cajaBiselada(sx, sy, sz, b = 0.03, seg = 1) {
  const bb = Math.min(Math.max(0.004, b), sx * 0.3, sy * 0.3, sz * 0.45);
  const forma = formaRect(sx - 2 * bb, sy - 2 * bb, Math.max(bb * 0.9, Math.min(sx, sy) * 0.03));
  const g = new THREE.ExtrudeGeometry(forma, {
    depth: Math.max(0.002, sz - 2 * bb), bevelEnabled: true, bevelThickness: bb,
    bevelSize: bb, bevelSegments: seg, curveSegments: 1, steps: 1,
  });
  g.translate(0, 0, -(sz / 2 - bb));
  return g;
}

/**
 * `cajaMaciza(sx, sy, sz, b)` — la misma caja biselada, pero con las medidas de
 * verdad.
 *
 * `cajaBiselada` construye la forma sobre `sx - 2b` y el bisel se come el resto:
 * la pieza que sale mide `sx - 2b` de ancho y `sy - 2b` de alto, no `sx` × `sy`.
 * Con b = 0,02 eso son cuatro centímetros que faltan en cada eje, y cuatro
 * centímetros no importan en una cornisa pero SÍ importan cuando dos paños
 * tienen que encontrarse: dos piezas pedidas a tope dejan una rendija de 4 cm
 * por la que se ve el vacío interior del edificio, que se dibuja negro absoluto.
 *
 * Para todo lo que forma un PAÑO CONTINUO (bandas de antepecho, machones,
 * forros) hay que usar ésta, que compensa el bisel y entrega el tamaño pedido.
 * Para molduras y ornamento sueltos da igual y sigue valiendo `cajaBiselada`.
 */
export function cajaMaciza(sx, sy, sz, b = 0.02) {
  const bb = Math.min(Math.max(0.004, b), sx * 0.22, sy * 0.22, sz * 0.45);
  return cajaBiselada(sx + 2 * bb, sy + 2 * bb, sz, bb);
}

/** Perfil 2D ([[x,y],...]) extruido en Z y centrado. Techos, cureñas, frontones. */
export function extruirPerfil(puntos, profundidad, b = 0.02, curvas = 2) {
  const f = new THREE.Shape();
  f.moveTo(puntos[0][0], puntos[0][1]);
  for (let i = 1; i < puntos.length; i++) f.lineTo(puntos[i][0], puntos[i][1]);
  f.closePath();
  const bb = Math.max(0.0008, Math.min(b, profundidad * 0.35));
  const g = new THREE.ExtrudeGeometry(f, {
    depth: Math.max(0.002, profundidad - 2 * bb), bevelEnabled: true, bevelThickness: bb,
    bevelSize: bb, bevelSegments: 1, curveSegments: curvas, steps: 1,
  });
  g.translate(0, 0, -(profundidad / 2 - bb));
  return g;
}

export const cilindro = (rSup, rInf, alto, seg = 12, abierto = false) =>
  new THREE.CylinderGeometry(Math.max(1e-4, rSup), Math.max(1e-4, rInf), alto, seg, 1, abierto);
export const disco = (r, alto, seg = 14) => new THREE.CylinderGeometry(r, r, alto, seg);
export const esfera = (r, seg = 10) => new THREE.SphereGeometry(r, seg, Math.max(4, seg >> 1));
export const media = (r, seg = 12) => new THREE.SphereGeometry(r, seg, Math.max(4, seg >> 1), 0, TAU, 0, Math.PI / 2);
export const toro = (r, tubo, segT = 5, seg = 14, arco = TAU) => new THREE.TorusGeometry(r, tubo, segT, seg, arco);
/**
 * `aro(...)` — el mismo toro pero ACOSTADO en el plano XZ, o sea abrazando un eje
 * vertical.
 *
 * Existe porque `THREE.TorusGeometry` nace en el plano XY, es decir DE CANTO, y
 * media biblioteca lo usaba sin rotar para zunchar cilindros: los boceles de las
 * torres, los zunchos de los silos, los aros de las chimeneas y hasta las duelas
 * de los barriles quedaban parados en vertical, atravesando la pieza de lado a
 * lado y asomando por dos costados. Eso es "geometría fuera de la malla" aunque
 * el color esté bien. Un aro que se lee como aro es media distancia entre
 * "cilindro" y "cilindro construido".
 */
export const aro = (r, tubo, segT = 5, seg = 14) => toro(r, tubo, segT, seg).rotateX(Math.PI / 2);
export const roca = (r, det = 0) => new THREE.IcosahedronGeometry(r, det);

/** Sólido de revolución sobre Y a partir de un perfil [[radio, alto], ...]. */
export const revolucion = (perfil, seg = 14) =>
  new THREE.LatheGeometry(perfil.map((p) => new THREE.Vector2(Math.max(1e-4, p[0]), p[1])), seg);

/** Tubo suave por una polilínea 3D: cables, mangueras, arcos. */
export function tuboPor(puntos, radio, segR = 5) {
  const curva = new THREE.CatmullRomCurve3(puntos.map((p) => (p.isVector3 ? p : new THREE.Vector3(p[0], p[1], p[2]))));
  return new THREE.TubeGeometry(curva, Math.max(6, puntos.length * 4), radio, segR, false);
}

/** Placa fina biselada: chapas, faldones, carteles. */
export const placa = (sx, sy, sz, b = 0.008) => cajaBiselada(sx, sy, sz, b);

/* ───────────────────── Volumen para el color de bando ─────────────────────
 *
 * REGLA (la misma que se aplica a la unidad en UnidadFabrica): NINGUNA
 * superficie de la ranura `jugador` puede ser una TAPA PLANA.
 *
 * Por qué es una regla y no una preferencia. La cámara mira desde 49° de
 * elevación: de un edificio se ve sobre todo lo que apunta al cielo. Si esa
 * cara es un `disco()` o una placa horizontal, TODAS sus normales valen
 * (0,1,0), devuelven exactamente el mismo RGB en cada píxel y el resultado es
 * un color plano recortado contra el techo — indistinguible de una malla sin
 * sombrear. Es literalmente lo que el panel describió como "tapa plana sin
 * sombreado" y lo que hacía que el remate de las torres se leyera como un
 * disco de plástico pegado encima.
 *
 * Las dos piezas de acá abajo son el reemplazo: la misma silueta y la misma
 * área, pero con la normal barriendo de la vertical a la horizontal dentro de
 * la propia pieza. El gradiente sale de la forma, no de que algo le tire
 * sombra, así que funciona igual a pleno sol que bajo un nubarrón.
 */

/**
 * TAPA DE BANDO ABOMBADA — reemplaza a cualquier `disco()` de color de jugador
 * que corone una torre, un tambor o un depósito.
 *
 * Tres partes:
 *  - el casquete (jugador): la normal va de casi vertical en la clave a casi
 *    horizontal en el borde, o sea un gradiente completo en una sola pieza;
 *  - el canto (detalle): el espesor real del remate, la línea oscura que lo
 *    despega del cielo y del techo de abajo;
 *  - dos zunchos concéntricos (detalle): parten la mancha azul en tres bandas.
 *    No son decoración: a la distancia de juego el ojo promedia el azul con el
 *    gris de los zunchos, y ESA mezcla es lo que baja el croma de un plano de
 *    color hasta parecer chapa pintada de verdad.
 */
export function tapaBando(radio, opts = {}) {
  const g = new THREE.Group();
  const flecha = opts.flecha != null ? opts.flecha : radio * 0.34;
  const canto = opts.canto != null ? opts.canto : Math.max(0.09, radio * 0.09);
  const seg = opts.seg || 18;
  const perfil = [];
  const N = 6;
  for (let i = 0; i <= N; i++) {
    // de a=0 (borde, radio máximo) a a=PI/2 (clave): DE ABAJO HACIA ARRIBA, que
    // es el orden en el que LatheGeometry saca las normales hacia afuera
    const a = (i / N) * Math.PI * 0.5;
    perfil.push([radio * Math.cos(a), flecha * Math.sin(a)]);
  }
  const casq = revolucion(perfil, seg);
  // LatheGeometry deja el anillo de la clave con la normal sin normalizar, y
  // justo ese anillo es el que la cámara ve de lleno: se recalculan todas.
  casq.deleteAttribute('normal');
  casq.computeVertexNormals();
  g.add(pieza(casq, 'jugador', opts.tinte || 0xffffff));
  g.add(pieza(cilindro(radio, radio * 0.99, canto, seg), 'detalle', 0xdcdcdc).translateY(-canto / 2));
  for (const t of [0.42, 0.74]) {
    const a = t * Math.PI * 0.5;
    g.add(pieza(aro(radio * Math.cos(a), Math.max(0.02, radio * 0.028), 4, seg), 'detalle', 0xd6d6d6)
      .translateY(flecha * Math.sin(a)));
  }
  return g;
}

/**
 * ALBARDILLA DE BANDO — la pieza que corona un pretil o una cornisa.
 *
 * Corre a lo largo de Z y su sección está en XY: base recta, dos costados
 * verticales y un lomo achaflanado a dos aguas. Los dos chaflanes miran a
 * lados opuestos, así que uno agarra el sol y el otro no: una banda de 30 cm
 * vista desde arriba pasa de ser una raya de un solo valor a tener una arista
 * de luz y una cara en sombra. Es el mismo truco que la cumbrera de un techo
 * real, y por eso una cornisa de verdad nunca es una losa plana.
 */
export function albardillaBando(largo, ancho, alto = 0.16) {
  const w = ancho / 2;
  return extruirPerfil([
    [-w, 0], [w, 0],
    [w, alto * 0.42], [w * 0.34, alto],
    [-w * 0.34, alto], [-w, alto * 0.42],
  ], largo, 0.02, 1);
}

/**
 * Paño de tela ondulado, de dos caras (banderas, toldos, lonas tensadas).
 *
 * POR QUÉ SE REESCRIBIÓ ("bandera sin un solo pliegue"). El paño anterior tenía
 * DOS divisiones a lo alto: con dos filas de vértices no existe ningún pliegue
 * vertical posible, la superficie sólo puede curvarse a lo largo, y como la onda
 * era una sinusoide pura con la misma fase a toda altura, lo que salía era una
 * chapa acanalada perfecta. Desde la cámara del juego, con la tela recortada
 * contra el cielo, eso se lee como un rectángulo plano de color de bando: la
 * peor superficie posible para el único color saturado del edificio.
 *
 * Tres cosas hacen que un trapo parezca un trapo:
 *   1. LA CRESTA VIAJA EN DIAGONAL. Si la fase no cambia con la altura, todos
 *      los pliegues son verticales y paralelos y la cosa es una persiana. El
 *      desfase con `v` inclina los pliegues, que es lo que hace una bandera.
 *   2. LA AMPLITUD CRECE CON LA DISTANCIA A LA VAINA. Junto al mástil la tela
 *      está agarrada y tiesa; el batiente es el que late.
 *   3. LA TELA PESA. El borde inferior hace panza y la esquina libre cae. Sin
 *      eso el contorno sigue siendo un rectángulo aunque la superficie ondule, y
 *      la SILUETA es lo primero que mira el ojo.
 *
 * No hay animación: estas piezas las fusiona la fábrica en la malla compartida
 * de la ranura `jugador`, así que no hay dónde colgar un `cada()` sin romper el
 * presupuesto de llamadas de dibujo. `fase` existe para que dos banderas del
 * mismo edificio no salgan calcadas.
 */
export function panoOndulado(ancho, alto, amp = 0.09, segs = 18, fase = 0) {
  const cols = Math.max(8, segs | 0);
  const filas = Math.max(4, Math.round(cols * 0.42));
  const p = new THREE.PlaneGeometry(ancho, alto, cols, filas);
  const pos = p.attributes.position;
  // Cuánto escurre el borde libre. Va con el VUELO (`ancho`) y no con la altura,
  // porque lo que hace panza es la tela que cuelga lejos del agarre: si se ata a
  // `alto`, un estandarte vertical de 3,4 m se descolgaba medio metro. Y se
  // modula con la amplitud pedida, que es la manera que tiene quien llama de
  // decir si el paño está tenso —un toldo pide 0,06— o suelto al viento.
  const caida = Math.min(alto * 0.18, ancho * 0.16)
    * clamp(amp / Math.max(1e-3, ancho * 0.2), 0, 1);
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), y = pos.getY(i);
    const t = (x + ancho / 2) / ancho;          // 0 en la vaina, 1 en el batiente
    const v = y / alto + 0.5;                   // 0 abajo, 1 arriba
    const suelta = t * t * (3 - 2 * t);         // cuánta tela hay libre para ondular
    const onda = Math.sin(t * 8.6 - v * 2.3 + fase) * amp * suelta;
    // armónico corto: los pliegues chicos que se amontonan contra el batiente
    const rizo = Math.sin(t * 17.5 + v * 3.6 + fase * 1.7) * amp * 0.32 * suelta * t;
    pos.setZ(i, onda + rizo);
    // panza del borde inferior + caída de la esquina libre + el acortamiento
    // que impone el propio pliegue (la tela plegada ocupa menos que estirada)
    pos.setY(i, y - Math.sin(t * 1.9) * caida * (1.2 - v) - Math.abs(onda) * 0.22);
    pos.setX(i, x - suelta * ancho * 0.035 * Math.abs(Math.sin(t * 8.6 + fase)));
  }
  p.computeVertexNormals();

  // ESPESOR: la cara de atrás se separa por la NORMAL, no por Z. Copiando en Z
  // el canto se anulaba justo en las crestas —donde la normal ya es casi
  // horizontal— y ahí la tela volvía a tener espesor cero, que es donde más se
  // nota. Los triángulos se dan vuelta invirtiendo el índice, no espejando la
  // geometría: espejarla (lo que hacía el `scale(1,1,-1)` de antes) ponía los
  // pliegues del revés y las dos caras no coincidían.
  const atras = p.clone();
  const idx = atras.getIndex();
  const orden = idx.array;
  for (let k = 0; k < orden.length; k += 3) {
    const t0 = orden[k]; orden[k] = orden[k + 2]; orden[k + 2] = t0;
  }
  idx.needsUpdate = true;
  const pa = atras.attributes.position, na = atras.attributes.normal;
  const esp = Math.max(0.012, Math.min(0.03, ancho * 0.018));
  for (let i = 0; i < pa.count; i++) {
    pa.setXYZ(i, pa.getX(i) - na.getX(i) * esp, pa.getY(i) - na.getY(i) * esp, pa.getZ(i) - na.getZ(i) * esp);
  }
  atras.deleteAttribute('normal');
  atras.computeVertexNormals();
  return fusionar([p, atras]);
}

/**
 * `bisel(geometria, radio)` — helper para que NADA sea una caja perfecta.
 * Suelda vértices, suaviza las normales y mete cada vértice hacia adentro por
 * el normal promediado: las aristas quedan achaflanadas y las esquinas comidas.
 */
export function bisel(geometria, radio = 0.02) {
  try {
    const g = normalizarGeo(geometria.clone());
    g.computeVertexNormals();
    const p = g.attributes.position, n = g.attributes.normal;
    for (let i = 0; i < p.count; i++) {
      p.setXYZ(i, p.getX(i) - n.getX(i) * radio, p.getY(i) - n.getY(i) * radio, p.getZ(i) - n.getZ(i) * radio);
    }
    p.needsUpdate = true;
    g.computeVertexNormals();
    return g;
  } catch (e) {
    return geometria;
  }
}

/**
 * `detalleRemaches(geometria, paso)` — corrido de remaches sobre el contorno de
 * las cuatro caras verticales de la geometría. Es el detalle que hace que el
 * acero de la Edad Eléctrica no parezca plástico.
 */
export function detalleRemaches(geometria, paso = 0.4, radio = 0.035) {
  geometria.computeBoundingBox();
  const b = geometria.boundingBox;
  if (!b) return null;
  const cabeza = esfera(radio, 5);
  const trozos = [];
  const margen = radio * 2.2;
  const filas = [b.min.y + margen, b.max.y - margen];
  const empujar = (x, y, z) => {
    if (trozos.length > 160) return;
    trozos.push(cabeza.clone().translate(x, y, z));
  };
  for (const y of filas) {
    for (let x = b.min.x + margen; x <= b.max.x - margen + 1e-3; x += paso) {
      empujar(x, y, b.max.z + radio * 0.35);
      empujar(x, y, b.min.z - radio * 0.35);
    }
    for (let z = b.min.z + margen; z <= b.max.z - margen + 1e-3; z += paso) {
      empujar(b.max.x + radio * 0.35, y, z);
      empujar(b.min.x - radio * 0.35, y, z);
    }
  }
  const cols = [b.min.x + margen, b.max.x - margen];
  for (const x of cols) {
    for (let y = b.min.y + margen; y <= b.max.y - margen + 1e-3; y += paso * 1.35) {
      empujar(x, y, b.max.z + radio * 0.35);
      empujar(x, y, b.min.z - radio * 0.35);
    }
  }
  cabeza.dispose();
  return fusionar(trozos);
}

/* ═══════════════════════════════════════════════════════════════════════════
   2. Muros y ventanas
   ═══════════════════════════════════════════════════════════════════════════ */

/** Proporciones de hueco por edad: [anchoVentana, altoVentana, hundido]. */
const HUECO = [
  { fw: 0.50, fh: 0.60, hundido: 0.44, marco: 0.05, parte: 'guillotina' },
  { fw: 0.66, fh: 0.72, hundido: 0.34, marco: 0.045, parte: 'industrial' },
  { fw: 0.86, fh: 0.44, hundido: 0.50, marco: 0.06, parte: 'cinta' },
  { fw: 0.94, fh: 0.80, hundido: 0.16, marco: 0.035, parte: 'cortina' },
  { fw: 0.92, fh: 0.46, hundido: 0.12, marco: 0.02, parte: 'continua' },
];

/**
 * Muro con ventanas HUNDIDAS de geometría real (no textura): el paño se arma
 * con dinteles, antepechos y machones, y el hueco queda vacío de verdad con su
 * vidrio retranqueado, su marco y su alféizar.
 *
 * El muro se centra en X, apoya en y=0 y su cara vista mira a +Z.
 */
export function muroConVentanas(ancho, alto, espesor = 0.34, filas = 1, columnas = 3, estilo = 0, opts = {}) {
  const e = espesor;
  const h = HUECO[clamp(estilo | 0, 0, 4)];
  const g = new THREE.Group();
  const T = Object.assign({
    muro: 0xffffff, sombra: 0x9a9a9a, marco: 0xffffff, vidrio: 0xffffff,
    zocalo: 0xffffff, cornisa: 0xf0f0f0, emis: 0x8fe8ff, forro: 0x6b6158,
  }, opts.tintes || {});
  const conZocalo = opts.zocalo !== false;
  const conCornisa = opts.cornisa !== false;
  const ranuraMarco = opts.ranuraMarco || (estilo >= 3 ? 'detalle' : 'detalle');

  const hZoc = conZocalo ? Math.min(0.42, alto * 0.11) : 0;
  const hCor = conCornisa ? Math.min(0.34, alto * 0.09) : 0;
  const yBase = hZoc;
  const util = Math.max(0.4, alto - hZoc - hCor);

  // ── zócalo: piedra maciza y un bocel más claro que la remata
  //
  // Esta franja ERA color de bando. `cuerpo()` llama a este muro cuatro veces por
  // volumen y los edificios apilan dos, tres y hasta cuatro volúmenes: una sola
  // línea de código ponía hasta dieciséis franjas de bando alrededor del edificio,
  // a la altura de los ojos y encima repetidas. Es la mitad del "color plano que
  // cubre faldones enteros" que marcó el panel. El zócalo es piedra: su trabajo es
  // decir que el edificio pesa, no de quién es.
  if (conZocalo) {
    g.add(pieza(cajaBiselada(ancho + 0.16, hZoc * 0.72, e + 0.16, 0.035), 'piedra', T.muro).translateY(hZoc * 0.36));
    g.add(pieza(cajaEn(ancho + 0.2, hZoc * 0.3, e + 0.2, 0, hZoc * 0.86, 0), 'piedra', T.cornisa));
  }
  // ── cornisa volada arriba
  if (conCornisa) {
    g.add(pieza(cajaBiselada(ancho + 0.3, hCor * 0.62, e + 0.3, 0.04), 'muro', T.cornisa)
      .translateY(alto - hCor * 0.31));
    // El friso de sombra bajo la cornisa medía `hCor * 0.2` y quedaba flotando:
    // no llegaba ni a la banda de arriba del paño ni al vuelo de la cornisa, y
    // entre las tres piezas se abría un hilo de 2 cm de vacío dando la vuelta al
    // edificio entero. Un hilo de vacío sobre negro absoluto se ve igual que una
    // grieta: ahora el friso monta sobre las dos.
    g.add(pieza(cajaEn(ancho + 0.1, hCor * 0.52, e + 0.1, 0, alto - hCor * 0.72, 0), 'muro', T.sombra));
  }

  const margenX = Math.min(ancho * 0.13, 0.75);
  const anchoUtil = Math.max(0.3, ancho - margenX * 2);
  const cel = anchoUtil / Math.max(1, columnas);
  const filaH = util / Math.max(1, filas);
  const vw = cel * h.fw;
  const vh = filaH * h.fh;
  const zFrente = e / 2;
  const zHueco = zFrente - e * h.hundido;

  /* ─────────────────────── DÓNDE ABRE CADA HUECO ───────────────────────
   *
   * ESTE ERA EL AGUJERO. La fila f centra su hueco dentro de su franja de
   * `filaH`, así que abre en `f*filaH + hb/2` y cierra `vh` más arriba, con
   * `hb = filaH - vh` de masa entre filas contiguas. Las bandas macizas, en
   * cambio, se dibujaban de `f*filaH` a `f*filaH + hb`: MEDIA BANDA CORRIDA
   * HACIA ARRIBA. Consecuencia doble y medida con un escaneo de cobertura sobre
   * la cara vista del paño (`hb/2` de altura, todo el ancho, una vez por
   * entrepiso): la banda tapaba la parte de abajo del hueco de arriba, y entre
   * el machón de una fila y la banda de la siguiente quedaba una FRANJA VACÍA de
   * 53 cm en una casa de dos plantas. Contra la cámara del juego eso no es una
   * junta: es 6,9% de la fachada abierta en un edificio de dos plantas y 8,8% en
   * uno de tres (12,5% y 16,8% en la Edad Sintética, que abre huecos más altos).
   * Y como el edificio no tiene interior modelado y sus caras internas se
   * descartan por back-face culling, por ahí no se ve el interior: se ve el
   * VACÍO, que sale negro absoluto y plano (medido en las capturas: 20,20,20
   * clavados, sin una sola variación de sombreado). Eso son, literalmente, las
   * "franjas negras planas en fachada".
   *
   * Ahora las bandas se derivan de los huecos y no al revés: cada banda va desde
   * el dintel del hueco de abajo hasta el antepecho del de arriba. Por
   * construcción no puede quedar luz.
   */
  const hb = Math.max(0.05, filaH - vh);          // masa entre huecos de filas contiguas
  const huecoY0 = (f) => yBase + f * filaH + hb * 0.5;
  /**
   * Solape entre machón y banda. Dos piezas a tope se separan en cuanto una se
   * mueve un milímetro (bisel, redondeo de esquina, coma flotante), y una
   * rendija de un milímetro sobre un vacío negro se ve igual que una de diez
   * centímetros. Ocho centímetros de montaje no cuestan un vértice más.
   */
  const SOLAPE = 0.08;

  // ── bandas macizas: antepecho, fajas de entrepiso y faja bajo la cornisa
  for (let f = 0; f <= filas; f++) {
    const desde = f === 0 ? yBase - 0.02 : huecoY0(f - 1) + vh;
    const hasta = f === filas ? alto - hCor + 0.02 : huecoY0(f);
    const hBanda = Math.max(0.05, hasta - desde);
    g.add(pieza(cajaMaciza(ancho, hBanda, e, 0.02), 'muro', T.muro).translateY(desde + hBanda * 0.5));
  }
  // machones verticales entre huecos, montados sobre las bandas de arriba y abajo
  for (let f = 0; f < filas; f++) {
    const yv = huecoY0(f) + vh / 2;
    for (let c = 0; c <= columnas; c++) {
      const xc = -anchoUtil / 2 + c * cel;
      const w = c === 0 || c === columnas ? margenX + (cel - vw) * 0.5 : cel - vw;
      const x = c === 0 ? -ancho / 2 + w / 2 : c === columnas ? ancho / 2 - w / 2 : xc;
      g.add(pieza(cajaMaciza(Math.max(0.06, w), vh + SOLAPE * 2, e, 0.02), 'muro', T.muro)
        .translateY(yv).translateX(x));
    }
  }

  /* ── FORRO INTERIOR: el cinturón de seguridad ──
   *
   * Con las bandas corregidas el paño cierra, pero cerrar por cálculo no alcanza
   * cuando arriba hay una fábrica que apila volúmenes, gira muros y les cambia
   * el espesor. La regla que se adopta acá es que NINGÚN hueco del paño puede
   * dar al vacío: detrás de todo el muro corre un paño de fondo retranqueado, de
   * pardo cálido oscuro y NUNCA negro (`T.forro`), a 20-25 cm por detrás de la
   * cara vista. Si alguna vez se vuelve a abrir una junta, lo que se ve por ella
   * es penumbra de interior —tiene tono, tiene sombreado y se degrada con la
   * luz del cielo— en vez de un recorte plano de la nada. Cuesta una caja por
   * muro y se fusiona en la misma ranura que el resto del paño: cero llamadas de
   * dibujo extra.
   */
  if (opts.forro !== false) {
    g.add(pieza(cajaEn(ancho - 0.02, alto, 0.14, 0, alto * 0.5, -e * 0.5 + 0.05), 'muro', T.forro));
  }

  // ── los huecos
  for (let f = 0; f < filas; f++) {
    const yv = huecoY0(f);
    for (let c = 0; c < columnas; c++) {
      const x = -anchoUtil / 2 + cel * (c + 0.5);
      const yc = yv + vh / 2;
      // Jamba y dintel hundidos: la sombra del retranqueo, y de paso el fondo
      // del hueco. Antes volaba 4 cm sobre el borde del vano; ahora vuela 11, o
      // sea que MONTA sobre el machón y sobre la banda. El vano es el único
      // sitio donde el paño se interrumpe a propósito, así que su fondo tiene
      // que ser francamente más grande que él: si el retranqueo llega justo, el
      // pelo de junta entre jamba y machón vuelve a ser un pinchazo de vacío.
      g.add(pieza(cajaEn(vw + 0.22, vh + 0.22, 0.06, x, yc, zHueco - 0.03), 'muro', T.sombra));
      // vidrio
      g.add(pieza(cajaEn(vw, vh, 0.03, x, yc, zHueco), 'vidrio', T.vidrio));
      // marco perimetral
      const m = h.marco;
      g.add(pieza(cajaEn(vw + m * 2, m, m * 1.6, x, yc + vh / 2 + m / 2, zHueco + m * 0.5), ranuraMarco, T.marco));
      g.add(pieza(cajaEn(vw + m * 2, m, m * 1.6, x, yc - vh / 2 - m / 2, zHueco + m * 0.5), ranuraMarco, T.marco));
      g.add(pieza(cajaEn(m, vh, m * 1.6, x - vw / 2 - m / 2, yc, zHueco + m * 0.5), ranuraMarco, T.marco));
      g.add(pieza(cajaEn(m, vh, m * 1.6, x + vw / 2 + m / 2, yc, zHueco + m * 0.5), ranuraMarco, T.marco));
      // parteluz según la edad
      const pm = h.marco * 0.62;
      if (h.parte === 'guillotina') {
        g.add(pieza(cajaEn(pm, vh, pm, x, yc, zHueco + pm), ranuraMarco, T.marco));
        g.add(pieza(cajaEn(vw, pm * 1.5, pm, x, yc + vh * 0.05, zHueco + pm), ranuraMarco, T.marco));
        // alféizar y arco rebajado de ladrillo
        g.add(pieza(cajaBiselada(vw + 0.26, 0.09, e * 0.55, 0.02), 'piedra', T.cornisa)
          .translateY(yc - vh / 2 - 0.05).translateZ(zFrente - e * 0.2).translateX(x));
        g.add(pieza(extruirPerfil([[-vw / 2 - 0.09, 0], [vw / 2 + 0.09, 0], [vw / 2 + 0.05, 0.13], [0, 0.19], [-vw / 2 - 0.05, 0.13]], e * 0.5, 0.015), 'piedra', T.cornisa)
          .translateY(yc + vh / 2 + 0.01).translateZ(zFrente - e * 0.18).translateX(x));
      } else if (h.parte === 'industrial') {
        for (let i = 1; i < 3; i++) g.add(pieza(cajaEn(pm, vh, pm, x - vw / 2 + (vw * i) / 3, yc, zHueco + pm), ranuraMarco, T.marco));
        for (let i = 1; i < 4; i++) g.add(pieza(cajaEn(vw, pm, pm, x, yc - vh / 2 + (vh * i) / 4, zHueco + pm), ranuraMarco, T.marco));
        g.add(pieza(cajaEn(vw + 0.3, 0.11, e * 0.75, x, yc + vh / 2 + 0.09, zFrente - e * 0.3), 'detalle', T.marco));
      } else if (h.parte === 'cinta') {
        g.add(pieza(cajaEn(pm, vh, pm, x, yc, zHueco + pm), ranuraMarco, T.marco));
        // parasol de hormigón: la visera brutalista
        g.add(pieza(cajaBiselada(vw + 0.34, 0.1, e * 1.5, 0.02), 'muro', T.cornisa)
          .translateY(yc + vh / 2 + 0.16).translateZ(zFrente + e * 0.3).translateX(x));
        g.add(pieza(cajaBiselada(0.12, vh + 0.3, e * 1.4, 0.02), 'muro', T.cornisa)
          .translateY(yc).translateZ(zFrente + e * 0.25).translateX(x - vw / 2 - 0.2));
      } else if (h.parte === 'cortina') {
        g.add(pieza(cajaEn(pm * 1.2, vh, pm * 2.2, x, yc, zHueco + pm * 1.1), 'detalle', T.marco));
        g.add(pieza(cajaEn(vw, pm, pm * 2.0, x, yc + vh * 0.12, zHueco + pm), 'detalle', T.marco));
      } else {
        // continua: la junta desaparece y queda una línea viva
        g.add(pieza(cajaEn(vw + 0.05, 0.035, 0.05, x, yc - vh / 2 - 0.05, zHueco + 0.05), 'emisivo', T.emis));
      }
    }
  }

  // pilastras de esquina: rompen el plano y dan sombra propia
  if (opts.pilastras !== false && estilo <= 2) {
    const pw = Math.min(0.5, ancho * 0.08);
    for (const s of [-1, 1]) {
      g.add(pieza(cajaBiselada(pw, alto * 0.985, e + 0.12, 0.035), 'piedra', T.cornisa)
        .translateX(s * (ancho / 2 - pw * 0.45)).translateY(alto * 0.4925));
    }
  }
  if (estilo === 4) {
    g.add(pieza(cajaEn(ancho * 0.96, 0.05, 0.06, 0, alto * 0.5, e / 2 + 0.02), 'emisivo', T.emis));
  }
  return g;
}

/** Muro ciego (sin huecos) con textura y bisel: fondos, medianeras, bunkers. */
export function muroCiego(ancho, alto, espesor = 0.34, estilo = 0, tinte = 0xffffff) {
  const g = new THREE.Group();
  g.add(pieza(cajaBiselada(ancho, alto, espesor, estilo >= 3 ? 0.06 : 0.03), 'muro', tinte).translateY(alto / 2));
  if (estilo <= 1) {
    g.add(pieza(cajaBiselada(ancho + 0.14, 0.22, espesor + 0.14, 0.03), 'piedra', 0xf2f2f2).translateY(0.11));
    g.add(pieza(cajaBiselada(ancho + 0.2, 0.16, espesor + 0.2, 0.03), 'muro', 0xe8e8e8).translateY(alto - 0.08));
  } else if (estilo === 2) {
    for (let i = 1; i < 4; i++) {
      g.add(pieza(cajaEn(ancho, 0.05, 0.05, 0, (alto * i) / 4, espesor / 2 + 0.02), 'muro', 0x8f8f8f));
    }
  }
  return g;
}

/* ═══════════════════════════════════════════════════════════════════════════
   3. Techos
   ═══════════════════════════════════════════════════════════════════════════ */

/**
 * Techo a dos aguas. La cumbrera corre en Z.
 *
 * El faldón NO va a la ranura `jugador`. Mandar la superficie entera del techo
 * al color de bando parece la forma directa de conseguir el 30% de silueta
 * pintada que pide el género, pero desde la cámara cenital el techo ES la mitad
 * del edificio: el resultado eran cajas de plástico monocromas, todas iguales
 * entre sí, y encima el azul del jugador quedaba a un tono del azul del agua.
 * El techo lleva su material de período (teja, chapa, hormigón) y el bando se
 * cobra donde SÍ aísla: la cumbrera, el borde del alero, el estandarte y el
 * zócalo. Misma superficie de color, repartida en tres escalas en vez de una.
 */
export function techoDosAguas(ancho, largo, pendiente = 0.62, alero = 0.4, estilo = 0, opts = {}) {
  const g = new THREE.Group();
  const A = ancho / 2 + alero;
  const h = A * pendiente;
  const gr = estilo <= 1 ? 0.16 : 0.13;
  const gv = gr * Math.sqrt(1 + pendiente * pendiente);
  const largoT = largo + alero * 2;
  const tejado = extruirPerfil([
    [-A, 0], [0, h], [A, 0], [A, gv], [0, h + gv], [-A, gv],
  ], largoT, 0.02);
  g.add(pieza(tejado, opts.ranuraTecho || 'detalle', opts.tinteTecho || 0xffffff));

  /* ─────────────────── CUMBRERA CON ESPESOR DE VERDAD ───────────────────
   *
   * Antes el caballete eran dos listones —uno de 12 cm centrado en `h+gv-0.02`
   * y otro de 14 cm en `h+gv+0.03`— y los dos estaban centrados EN la línea de
   * cumbrera, así que de cada uno la mitad quedaba enterrada en el faldón. Lo
   * que asomaba por encima del vértice eran cuatro y diez centímetros: a la
   * distancia de juego, uno o dos píxeles. Eso no es una pieza, es una raya, y
   * es exactamente lo que el panel llamó "cumbrera de espesor cero".
   *
   * Ahora es un perfil extruido con sección propia: dos aguas con su vértice,
   * dos hombros, y faldas que BAJAN siguiendo la pendiente del tejado hasta 3 cm
   * por debajo de su superficie, o sea que montan sobre las dos aguas en vez de
   * apoyarse en el filo. Resultado: silueta contra el cielo, una cara al sol y
   * otra en sombra, y ni una junta abierta en la línea más visible del edificio.
   */
  const cw = Math.max(0.28, Math.min(0.62, A * 0.13));   // medio ancho del caballete
  const ch = Math.max(0.19, cw * 0.66);                  // lomo por encima del vértice
  const baja = cw * pendiente;                           // cuánto cae la falda al montar
  g.add(pieza(extruirPerfil([
    [-cw, -baja - 0.03], [-cw, -baja + 0.13], [-cw * 0.40, ch * 0.68],
    [0, ch],
    [cw * 0.40, ch * 0.68], [cw, -baja + 0.13], [cw, -baja - 0.03],
  ], largoT + 0.06, 0.02, 1), 'detalle', 0xf0f0f0).translateY(h + gv));
  // tejas de caballete: la fila de medias cañas que remata la cumbrera. Es lo
  // que hace que una arista de 20 m no sea una recta perfecta de un solo valor.
  // 6 lados y no 12: a esta distancia la media caña son cuatro píxeles de alto y
  // lo único que tiene que hacer es romper la recta, no ser redonda
  const nTejas = Math.max(4, Math.min(18, Math.round(largoT / 0.8)));
  for (let i = 0; i < nTejas; i++) {
    const z = -largoT / 2 + (largoT * (i + 0.5)) / nTejas;
    g.add(pieza(cilindro(cw * 0.40, cw * 0.46, (largoT / nTejas) * 0.92, 6).rotateX(Math.PI / 2), 'detalle', 0xe2e2e2)
      .translateY(h + gv + ch * 0.46).translateZ(z));
  }
  // cantos del alero: la cinta que corre por el borde bajo de cada agua
  for (const s of [-1, 1]) {
    g.add(pieza(cajaEn(0.24, 0.14, largoT, s * (A - 0.06), gv * 0.55, 0), 'detalle', 0xd2d2d2));
  }

  /* ──────────────── FRONTONES QUE SELLAN CONTRA EL FALDÓN ────────────────
   *
   * El hastial se dibujaba con la pendiente del MURO (cumbre en
   * `ancho/2 * pendiente`), pero el faldón arranca `alero` más afuera y por lo
   * tanto pasa `alero * pendiente` MÁS ARRIBA en todo su recorrido: quedaba una
   * cuña abierta de 28 cm a lo largo de las dos limatesas, y por ahí se veía el
   * vacío del desván. Es la diagonal negra que el panel leyó sobre el alero.
   *
   * El perfil nuevo ES la cara interior del tejado: mismo arranque (±A, 0) y
   * cumbre en `h`, con 5 cm de más para que el faldón lo tape en vez de
   * coincidir con él y pelearse por el z-buffer. Al llegar a cero justo en el
   * borde del alero, la parte que sobresale del muro es una cuña que se afina
   * hasta desaparecer: por fuera no se ve un hastial más ancho, se ve un alero
   * cerrado, que es como remata un techo de verdad.
   */
  const tri = [[-A, 0], [0, h + 0.05], [A, 0]];
  for (const s of [-1, 1]) {
    g.add(pieza(extruirPerfil(tri, 0.3, 0.02), 'muro', opts.tinteFronton || 0xffffff)
      .translateZ(s * (largo / 2 - 0.12)));
  }
  // tablas de borde en las limatesas
  for (const s of [-1, 1]) {
    g.add(pieza(cajaBiselada(0.1, 0.2, largoT, 0.02), 'detalle', 0xe6e6e6)
      .translateX(s * (A + 0.02)).translateY(0.02));
  }
  // Canecillos: puntas de viga bajo el alero, silueta pura. Nacían en
  // `ancho/2 + alero*0.35` con 1,3·alero de largo, así que su punta interior
  // entraba 3 cm DENTRO del paño del muro (el techo se pide con `ancho` ya
  // inflado, pero el muro sigue en `ancho`). Una viga que atraviesa la pared es
  // el tipo de detalle que el ojo registra aunque no sepa nombrarlo. Ahora
  // arrancan por fuera de la cara del muro y sólo vuelan hacia afuera.
  const n = Math.max(3, Math.round(largo / 0.85));
  const largoCanecillo = alero * 0.95;
  const xCanecillo = ancho / 2 + alero * 0.10 + largoCanecillo * 0.5;
  for (let i = 0; i < n; i++) {
    const z = -largo / 2 + (largo * (i + 0.5)) / n;
    for (const s of [-1, 1]) {
      g.add(pieza(cajaEn(largoCanecillo, 0.11, 0.12, s * xCanecillo, -alero * pendiente * 0.7 + 0.02, z), 'detalle', 0xdcdcdc));
    }
  }
  if (estilo === 0 && opts.buhardilla !== false && largo > 3.2) {
    // buhardilla con su ventanita: el rasgo que grita "1850"
    const bw = Math.min(1.35, ancho * 0.3);
    const yb = h * 0.35;
    const gb = conjunto(
      pieza(cajaBiselada(bw, 0.85, 1.0, 0.02), 'muro', 0xf4f4f4).translateY(0.42),
      pieza(cajaEn(bw * 0.5, 0.5, 0.05, 0, 0.46, 0.5), 'vidrio', 0xffffff),
      // el tejadillo de la buhardilla es teja como el techo grande, no bando
      pieza(extruirPerfil([[-bw / 2 - 0.12, 0], [0, 0.42], [bw / 2 + 0.12, 0], [bw / 2 + 0.12, 0.12], [0, 0.54], [-bw / 2 - 0.12, 0.12]], 1.1, 0.02), 'techo', 0xffffff).translateY(0.85),
    );
    colocar(gb, ancho * 0.22, yb, largo * 0.12);
    gb.rotation.y = 0;
    g.add(gb);
  }
  if (estilo === 1) {
    // linterna de ventilación corrida, típica de nave industrial
    g.add(pieza(cajaBiselada(ancho * 0.3, 0.34, largo * 0.62, 0.03), 'detalle', 0xdedede).translateY(h + 0.18));
    // la tapa de la linterna es chapa; el bando ya corre por el faldón
    g.add(pieza(cajaEn(ancho * 0.32, 0.12, largo * 0.64, 0, h + 0.4, 0), 'detalle', 0xc8c8c8));
  }
  return g;
}

/** Techo plano con pretil, gárgola y albardilla de color. Brutalismo y after. */
export function techoPlanoConPretil(ancho, largo, altoPretil = 0.62, opts = {}) {
  const g = new THREE.Group();
  const e = opts.espesor || 0.26;
  g.add(pieza(cajaBiselada(ancho, e, largo, 0.03), 'muro', opts.tinte || 0xf2f2f2).translateY(e / 2));
  const t = 0.2;
  for (const s of [-1, 1]) {
    g.add(pieza(cajaBiselada(ancho + 0.16, altoPretil, t, 0.03), 'muro', 0xffffff)
      .translateZ(s * (largo / 2 + t * 0.2)).translateY(e + altoPretil / 2));
    g.add(pieza(cajaBiselada(t, altoPretil, largo + 0.16, 0.03), 'muro', 0xffffff)
      .translateX(s * (ancho / 2 + t * 0.2)).translateY(e + altoPretil / 2));
    // Albardilla: la franja de color que corona el pretil, y la única del techo
    // plano. Era de canto fijo (0.36 m de vuelo) fuese el pretil de una vivienda
    // de 3,6 m o el de una ciudadela: en los edificios chicos las cuatro
    // albardillas solas se comían media azotea. Ahora vuela lo que tapa.
    //
    // Y era una LOSA PLANA: cuatro rayas horizontales del color del jugador,
    // todas con la misma normal (0,1,0) y por lo tanto todas con el mismo RGB
    // exacto de punta a punta. Vista desde la cámara del juego eso no se lee
    // como una cornisa pintada sino como una cinta adhesiva. Ahora lleva el
    // lomo a dos aguas de una albardilla de verdad (ver `albardillaBando`), que
    // reparte la misma banda en una arista de luz y una cara en sombra.
    const wAlb = t + 0.11;
    const yAlb = e + altoPretil;
    // la que corre en Z sale derecha del generador; la que corre en X se gira
    g.add(pieza(albardillaBando(largo + 0.26, wAlb), 'jugador', 0xffffff)
      .translateX(s * (ancho / 2 + t * 0.2)).translateY(yAlb));
    g.add(pieza(albardillaBando(ancho + 0.26, wAlb).rotateY(Math.PI / 2), 'jugador', 0xffffff)
      .translateZ(s * (largo / 2 + t * 0.2)).translateY(yAlb));
  }
  // gárgola / desagüe
  g.add(pieza(cilindro(0.07, 0.07, 0.4, 8).rotateX(Math.PI / 2), 'detalle', 0xcfcfcf)
    .translateY(e + 0.16).translateZ(largo / 2 + 0.18).translateX(ancho * 0.32));
  if (opts.grava !== false) {
    g.add(pieza(cajaEn(ancho - 0.5, 0.05, largo - 0.5, 0, e + 0.03, 0), 'piedra', 0xd8d8d8));
  }
  return g;
}

/** Cubierta en diente de sierra: la firma de la fábrica de la Edad Eléctrica. */
export function techoDienteSierra(ancho, largo, n = 3, opts = {}) {
  const g = new THREE.Group();
  const w = ancho / n;
  const ha = opts.alto || Math.min(1.5, w * 0.72);
  const gr = 0.12;
  for (let i = 0; i < n; i++) {
    const x0 = -ancho / 2 + i * w;
    const L = Math.sqrt(w * w + ha * ha);
    const ang = Math.atan2(ha, w);
    const faldon = cajaBiselada(L, gr, largo, 0.02);
    faldon.rotateZ(ang);
    faldon.translate(x0 + w / 2, ha / 2, 0);
    // el faldón lleva chapa; el bando va en el montante del lucernario, que es
    // la línea que se repite n veces y dibuja el diente de sierra
    g.add(pieza(faldon, 'detalle', 0xffffff));
    // paño acristalado vertical mirando al sur
    g.add(pieza(cajaEn(0.09, ha, largo - 0.16, x0 + w - 0.05, ha / 2, 0), 'vidrio', 0xffffff));
    // el dintel del lucernario es carpintería metálica: el bando de esta cubierta
    // lo pone la fábrica una sola vez por diente, en la cumbrera
    g.add(pieza(cajaEn(0.13, 0.1, largo, x0 + w - 0.05, ha - 0.04, 0), 'detalle', 0xcfcfcf));
    g.add(pieza(cajaEn(0.13, 0.1, largo, x0 + w - 0.05, 0.06, 0), 'detalle', 0xdadada));
    // montantes del vidriado
    const m = Math.max(2, Math.round(largo / 1.3));
    for (let k = 1; k < m; k++) {
      g.add(pieza(cajaEn(0.11, ha, 0.08, x0 + w - 0.05, ha / 2, -largo / 2 + (largo * k) / m), 'detalle', 0xd0d0d0));
    }
    // cercha bajo cada diente
    const c = cercha(w * 0.98, ha * 0.55, { montantes: 3 });
    g.add(pieza(c, 'detalle', 0xcccccc).translateX(x0 + w / 2).translateY(-ha * 0.5).translateZ(largo / 2 - 0.2));
    g.add(pieza(c.clone(), 'detalle', 0xcccccc).translateX(x0 + w / 2).translateY(-ha * 0.5).translateZ(-largo / 2 + 0.2));
  }
  return g;
}

/** Cubierta curva de nave / hangar (bóveda de cañón). */
export function techoBoveda(ancho, largo, alto, opts = {}) {
  const g = new THREE.Group();
  const seg = 14, gr = opts.espesor || 0.16;
  const pts = [];
  for (let i = 0; i <= seg; i++) {
    const t = i / seg, a = Math.PI * t;
    pts.push([-Math.cos(a) * (ancho / 2), Math.sin(a) * alto]);
  }
  for (let i = seg; i >= 0; i--) {
    const t = i / seg, a = Math.PI * t;
    pts.push([-Math.cos(a) * (ancho / 2 - gr), Math.sin(a) * (alto - gr)]);
  }
  // La bóveda ENTERA estaba en la ranura de jugador. Es la superficie más grande
  // de todo el hangar y desde la cámara cenital es prácticamente el edificio: un
  // cañón de veinte metros cuadrados de un único RGB, sin material debajo. Ese es
  // el "faldón entero" literal que el panel leyó como material sin asignar. Va con
  // el material del período; el bando se cobra en las bandas de arranque.
  g.add(pieza(extruirPerfil(pts, largo, 0.02, 3), opts.ranura || 'techo', opts.tinte || 0xffffff));
  const n = Math.max(3, Math.round(largo / 1.6));
  for (let i = 0; i <= n; i++) {
    const z = -largo / 2 + (largo * i) / n;
    const arco = [];
    for (let k = 0; k <= 12; k++) {
      const a = Math.PI * (k / 12);
      arco.push([-Math.cos(a) * (ancho / 2 + 0.06), Math.sin(a) * (alto + 0.05), 0]);
    }
    g.add(pieza(tuboPor(arco, 0.06, 4), 'detalle', 0xd6d6d6).translateZ(z));
  }
  return g;
}

/* ═══════════════════════════════════════════════════════════════════════════
   4. Verticales: cúpulas, chimeneas, torres, silos
   ═══════════════════════════════════════════════════════════════════════════ */

/** Cúpula con gajos, tambor y linterna. Apoya en y=0. */
export function cupula(radio, altura, gajos = 8, opts = {}) {
  const g = new THREE.Group();
  const seg = 18;
  const perfil = [];
  for (let i = 0; i <= seg; i++) {
    const t = i / seg, a = t * Math.PI * 0.5;
    const r = Math.sin(a) * radio * (1 + 0.06 * Math.cos(a * 2));
    perfil.push([r, Math.cos(a) * altura]);
  }
  perfil.push([0, altura]);
  const casc = revolucion(perfil.reverse(), 20);
  // Misma razón que en techoDosAguas: el casquete es superficie grande y vista
  // desde arriba. Va con material, y el bando se cobra en los nervios, que
  // dibujan la cúpula igual de bien y ocupan una fracción del área.
  g.add(pieza(casc, opts.ranura || 'detalle', opts.tinte || 0xffffff));
  // tambor
  //
  // OJO CON LA ORIENTACIÓN: `toro()` devuelve un TorusGeometry, que nace en el
  // plano XY, o sea DE CANTO. Este anillo estaba sin rotar, así que la cúpula
  // llevaba clavado un aro de color de bando parado en vertical, atravesándola de
  // lado a lado: es una de las "tablas azules fuera de la malla" que vio el panel.
  // Acostado (rotateX) es el bocel del tambor y abraza la cúpula.
  g.add(pieza(cilindro(radio * 1.04, radio * 1.08, 0.3, 20), 'piedra', 0xf4f4f4).translateY(0.15));
  g.add(pieza(toro(radio * 1.06, 0.06, 4, 20).rotateX(Math.PI / 2), 'jugador', 0xffffff).translateY(0.3));
  // gajos / nervios
  for (let i = 0; i < gajos; i++) {
    const r = toro(radio, 0.045, 4, 12, Math.PI / 2);
    r.rotateZ(0);
    r.scale(1, altura / Math.max(0.001, radio), 1);
    const m = pieza(r, 'jugador', 0xffffff);
    m.rotation.y = (i / gajos) * TAU;
    m.position.y = 0.3;
    g.add(m);
  }
  // linterna
  const yl = altura + 0.3;
  g.add(pieza(cilindro(radio * 0.2, radio * 0.24, 0.42, 10), 'piedra', 0xffffff).translateY(yl + 0.21));
  g.add(pieza(media(radio * 0.24, 10), 'techo', 0xffffff).translateY(yl + 0.42));
  g.add(pieza(cilindro(0.03, 0.05, 0.55, 6), 'detalle', 0xf2f2f2).translateY(yl + 0.68));
  g.add(pieza(esfera(0.09, 8), 'detalle', 0xffe9a8).translateY(yl + 0.97));
  return g;
}

/** Chimenea. Apoya en y=0; el humo sale de (0, alto, 0). */
export function chimenea(alto, ancho = 0.6, estilo = 0) {
  const g = new THREE.Group();
  if (estilo === 0) {
    g.add(pieza(cajaBiselada(ancho * 1.25, 0.3, ancho * 1.25, 0.03), 'muro', 0xf0f0f0).translateY(0.15));
    g.add(pieza(cajaBiselada(ancho, alto - 0.7, ancho, 0.025), 'muro', 0xffffff).translateY(alto / 2 - 0.05));
    // coronamiento en voladizo
    g.add(pieza(cajaBiselada(ancho * 1.3, 0.2, ancho * 1.3, 0.03), 'muro', 0xe6e6e6).translateY(alto - 0.28));
    g.add(pieza(cajaBiselada(ancho * 1.16, 0.14, ancho * 1.16, 0.02), 'piedra', 0xffffff).translateY(alto - 0.1));
    for (let i = 0; i < 2; i++) {
      g.add(pieza(cilindro(ancho * 0.17, ancho * 0.19, 0.28, 8), 'piedra', 0xdadada)
        .translateY(alto + 0.1).translateX((i - 0.5) * ancho * 0.44));
    }
  } else if (estilo === 1) {
    const r = ancho * 0.55;
    g.add(pieza(cilindro(r * 1.35, r * 1.7, 0.45, 12), 'muro', 0xf2f2f2).translateY(0.22));
    g.add(pieza(cilindro(r * 0.82, r * 1.25, alto - 0.6, 14), 'muro', 0xffffff).translateY(alto / 2 - 0.05));
    for (let i = 1; i <= 4; i++) {
      const t = i / 5;
      g.add(pieza(aro(lerp(r * 1.25, r * 0.82, t) + 0.03, 0.045, 4, 14), 'detalle', 0xdedede).translateY(0.35 + (alto - 0.7) * t));
    }
    g.add(pieza(aro(r * 0.9, 0.07, 4, 14), 'detalle', 0xcfcfcf).translateY(alto - 0.16));
    // escalerilla de gato
    for (let i = 0; i < Math.floor(alto / 0.42); i++) {
      g.add(pieza(cajaEn(0.24, 0.035, 0.035, r * 1.05, 0.5 + i * 0.42, 0), 'detalle', 0xc8c8c8));
    }
  } else if (estilo === 2) {
    // torre de refrigeración: hiperboloide de hormigón
    const perfil = [];
    const seg = 12;
    for (let i = 0; i <= seg; i++) {
      const t = i / seg;
      const r = ancho * (1.25 - 0.75 * Math.sin(t * Math.PI * 0.72)) * (1 + t * 0.42);
      perfil.push([r, t * alto]);
    }
    for (let i = seg; i >= 0; i--) {
      const t = i / seg;
      const r = ancho * (1.25 - 0.75 * Math.sin(t * Math.PI * 0.72)) * (1 + t * 0.42) - 0.1;
      perfil.push([Math.max(0.05, r), t * alto]);
    }
    g.add(pieza(revolucion(perfil, 18), 'muro', 0xf6f6f6));
    for (let i = 0; i < 10; i++) {
      const a = (i / 10) * TAU;
      g.add(pieza(cajaEn(0.12, 0.7, 0.12, Math.cos(a) * ancho * 1.18, 0.35, Math.sin(a) * ancho * 1.18), 'muro', 0xe0e0e0));
    }
    g.add(pieza(aro(ancho * 1.62, 0.08, 4, 18), 'detalle', 0xdcdcdc).translateY(alto - 0.05));
  } else if (estilo === 3) {
    g.add(pieza(cajaBiselada(ancho, alto, ancho, 0.05), 'detalle', 0xf2f2f2).translateY(alto / 2));
    g.add(pieza(cajaBiselada(ancho * 1.25, 0.16, ancho * 1.25, 0.04), 'detalle', 0xdcdcdc).translateY(alto));
    g.add(pieza(cajaEn(ancho * 1.05, 0.05, ancho * 1.05, 0, alto + 0.1, 0), 'emisivo', 0x66e6ff));
  } else {
    const perfil = [];
    for (let i = 0; i <= 10; i++) {
      const t = i / 10;
      perfil.push([ancho * (0.55 + 0.35 * Math.sin(t * Math.PI)), t * alto]);
    }
    g.add(pieza(revolucion(perfil, 16), 'muro', 0xffffff));
    g.add(pieza(aro(ancho * 0.6, 0.05, 4, 16), 'emisivo', 0xb48bff).translateY(alto * 0.82));
  }
  return g;
}

/** Torre / torreón. Apoya en y=0. La corona depende de la edad. */
export function torre(radio, alto, estilo = 0, opts = {}) {
  const g = new THREE.Group();
  if (estilo === 0) {
    g.add(pieza(cilindro(radio, radio * 1.16, alto * 0.94, 14), 'muro', 0xffffff).translateY(alto * 0.47));
    g.add(pieza(cilindro(radio * 1.2, radio * 1.3, 0.4, 14), 'piedra', 0xf4f4f4).translateY(0.2));
    g.add(pieza(aro(radio * 1.1, 0.09, 4, 16), 'piedra', 0xf0f0f0).translateY(alto * 0.62));
    // matacán y almenas
    g.add(pieza(cilindro(radio * 1.3, radio * 1.1, 0.3, 14), 'piedra', 0xffffff).translateY(alto * 0.94 + 0.15));
    const n = 10;
    for (let i = 0; i < n; i++) {
      const a = (i / n) * TAU;
      g.add(pieza(cajaEn(0.3, 0.42, 0.28, Math.cos(a) * radio * 1.16, alto * 0.94 + 0.5, Math.sin(a) * radio * 1.16), 'piedra', 0xf6f6f6));
    }
    if (opts.capitel !== false) {
      // el chapitel va con teja/pizarra: la ciudadela lleva CUATRO torreones y con
      // el cono entero pintado eran cuatro conos macizos del color del bando
      g.add(pieza(cilindro(0.02, radio * 1.14, radio * 1.5, 14), 'techo', 0xffffff).translateY(alto * 0.94 + 0.7 + radio * 0.75));
      // …y el bando queda en el aro del arranque: una línea, no un volumen
      g.add(pieza(toro(radio * 1.12, 0.055, 4, 16).rotateX(Math.PI / 2), 'jugador', 0xffffff).translateY(alto * 0.94 + 0.7));
      g.add(pieza(esfera(0.1, 8), 'detalle', 0xffe0a0).translateY(alto * 0.94 + 0.72 + radio * 1.5));
    }
    for (let i = 0; i < 3; i++) {
      g.add(pieza(cajaEn(0.22, 0.62, 0.16, 0, alto * (0.3 + i * 0.2), radio * 0.99), 'vidrio', 0xdedede));
    }
  } else if (estilo === 1) {
    // torre de celosía remachada
    const patas = 4;
    for (let i = 0; i < patas; i++) {
      const a = (i / patas) * TAU + Math.PI / 4;
      const x0 = Math.cos(a) * radio * 1.25, z0 = Math.sin(a) * radio * 1.25;
      const x1 = Math.cos(a) * radio * 0.45, z1 = Math.sin(a) * radio * 0.45;
      g.add(pieza(tuboPor([[x0, 0, z0], [lerp(x0, x1, 0.5), alto * 0.5, lerp(z0, z1, 0.5)], [x1, alto, z1]], 0.075, 4), 'detalle', 0xf0f0f0));
    }
    const niveles = Math.max(3, Math.round(alto / 1.3));
    for (let k = 1; k <= niveles; k++) {
      const t = k / niveles, r = lerp(radio * 1.25, radio * 0.45, t), y = alto * t;
      g.add(pieza(toro(r, 0.045, 4, 4).rotateX(Math.PI / 2), 'detalle', 0xe4e4e4).translateY(y));
      const tp = (k - 0.5) / niveles, rp = lerp(radio * 1.25, radio * 0.45, tp);
      for (let i = 0; i < 4; i++) {
        const a = (i / 4) * TAU + Math.PI / 4;
        const a2 = ((i + 1) / 4) * TAU + Math.PI / 4;
        g.add(pieza(tuboPor([
          [Math.cos(a) * lerp(radio * 1.25, radio * 0.45, (k - 1) / niveles), alto * ((k - 1) / niveles), Math.sin(a) * lerp(radio * 1.25, radio * 0.45, (k - 1) / niveles)],
          [Math.cos(lerp(a, a2, 0.5)) * rp, alto * tp, Math.sin(lerp(a, a2, 0.5)) * rp],
          [Math.cos(a2) * r, y, Math.sin(a2) * r]], 0.038, 4), 'detalle', 0xdcdcdc));
      }
    }
    g.add(pieza(cilindro(radio * 0.7, radio * 0.7, 0.5, 10), 'detalle', 0xf2f2f2).translateY(alto + 0.25));
    // era una placa CUADRADA de lado 1.6·radio sobre una cabina REDONDA de radio
    // 0.7·radio: las cuatro esquinas colgaban en el aire. Después fue un disco
    // del tamaño de la cabina, que apoyaba bien pero seguía siendo una tapa
    // plana: el remate de la torre entero en un único RGB. Ahora es un
    // casquete (ver `tapaBando`), misma silueta y misma área, con gradiente.
    g.add(colocar(tapaBando(radio * 0.78, { flecha: radio * 0.30, seg: 14 }), 0, alto + 0.52, 0));
  } else if (estilo === 2) {
    g.add(pieza(cilindro(radio * 0.78, radio * 1.05, alto, 14), 'muro', 0xffffff).translateY(alto / 2));
    for (let i = 1; i < 4; i++) g.add(pieza(aro(radio * lerp(1.05, 0.78, i / 4) + 0.02, 0.05, 4, 14), 'muro', 0xe2e2e2).translateY((alto * i) / 4));
    g.add(pieza(cilindro(radio * 1.5, radio * 1.5, 0.55, 14), 'muro', 0xf4f4f4).translateY(alto + 0.27));
    // ídem: placa cuadrada de 3.1·radio sobre un tambor de 1.5·radio. Volaba medio
    // metro por cada esquina y encima duplicaba el área pintada del edificio.
    //
    // Y era LA tapa plana más grande del juego: un disco de 3 m de diámetro,
    // horizontal, del color del jugador, en la pieza más alta de la Edad
    // Atómica. En las capturas del panel la torre se lee como un plato azul
    // apoyado sobre un tubo gris. Casquete rebajado, con su canto y sus dos
    // zunchos, que es como remata de verdad un depósito de agua.
    g.add(colocar(tapaBando(radio * 1.58, { flecha: radio * 0.46, seg: 20 }), 0, alto + 0.62, 0));
    for (let i = 0; i < 8; i++) {
      const a = (i / 8) * TAU;
      g.add(pieza(cajaEn(0.5, 0.3, 0.1, Math.cos(a) * radio * 1.45, alto + 0.3, Math.sin(a) * radio * 1.45).rotateY(-a), 'vidrio', 0xcfe4ff));
    }
  } else if (estilo === 3) {
    g.add(pieza(cilindro(radio * 0.55, radio * 0.75, alto, 12), 'detalle', 0xf2f2f2).translateY(alto / 2));
    g.add(pieza(cilindro(radio * 1.25, radio * 1.05, 0.85, 14), 'vidrio', 0xd8ecff).translateY(alto + 0.42));
    g.add(pieza(cilindro(radio * 1.35, radio * 1.35, 0.14, 14), 'detalle', 0xf0f0f0).translateY(alto + 0.9));
    g.add(pieza(aro(radio * 1.3, 0.04, 4, 16), 'emisivo', 0x66e6ff).translateY(alto + 0.98));
    // el collar bajo la cabina era un cilindro recto de 16 cm: su cara de
    // arriba es un anillo perfectamente horizontal, o sea otra tapa plana. Un
    // tronco de cono que se abre hacia abajo pone esa misma corona en pendiente
    // y le devuelve el lado iluminado y el lado en sombra.
    g.add(pieza(cilindro(radio * 1.1, radio * 1.36, 0.26, 14), 'jugador', 0xffffff).translateY(alto - 0.09));
    g.add(pieza(aro(radio * 1.36, 0.035, 4, 16), 'detalle', 0xdedede).translateY(alto - 0.21));
  } else {
    g.add(pieza(cilindro(radio * 0.42, radio * 0.62, alto, 14), 'muro', 0xffffff).translateY(alto / 2));
    for (let i = 0; i < 3; i++) {
      const y = alto * (0.45 + i * 0.2);
      g.add(pieza(aro(radio * (1.15 - i * 0.14), 0.075, 5, 20), 'muro', 0xffffff).translateY(y));
      g.add(pieza(aro(radio * (1.15 - i * 0.14), 0.028, 4, 20), 'emisivo', 0xb48bff).translateY(y + 0.09));
    }
    g.add(pieza(esfera(radio * 0.5, 12), 'jugador', 0xffffff).translateY(alto + radio * 0.3));
  }
  return g;
}

/** Silo cilíndrico con zunchos, cono, escalera de gato y tolva de descarga. */
export function silo(radio, alto, opts = {}) {
  const g = new THREE.Group();
  g.add(pieza(cilindro(radio, radio, alto, 16), 'muro', opts.tinte || 0xffffff).translateY(alto / 2));
  const n = Math.max(3, Math.round(alto / 1.1));
  for (let i = 1; i < n; i++) {
    g.add(pieza(aro(radio + 0.03, 0.05, 4, 16), 'detalle', 0xe0e0e0).translateY((alto * i) / n));
  }
  // el cono de coronación es chapa: el molino de la Edad Atómica planta TRES silos
  // y con el cono entero pintado eran tres sombreros macizos de color de bando
  g.add(pieza(cilindro(0.06, radio * 1.05, radio * 0.62, 16), 'techo', 0xffffff).translateY(alto + radio * 0.31));
  // el bando se queda con el zuncho del alero, que es la línea que dibuja el silo
  g.add(pieza(toro(radio * 1.03, 0.07, 4, 16).rotateX(Math.PI / 2), 'jugador', 0xffffff).translateY(alto + 0.03));
  g.add(pieza(cilindro(radio * 1.08, radio * 1.14, 0.3, 16), 'piedra', 0xf0f0f0).translateY(0.15));
  // escalera de gato con guarda-espaldas
  for (let i = 0; i < Math.floor(alto / 0.4); i++) {
    g.add(pieza(cajaEn(0.3, 0.04, 0.04, radio + 0.15, 0.4 + i * 0.4, 0), 'detalle', 0xd0d0d0));
  }
  for (const s of [-1, 1]) {
    g.add(pieza(cajaEn(0.05, alto - 0.3, 0.05, radio + 0.28, alto / 2, s * 0.16), 'detalle', 0xcccccc));
  }
  // tolva
  g.add(pieza(cilindro(0.2, radio * 0.45, 0.55, 10), 'detalle', 0xdcdcdc).translateY(0.55).translateX(radio * 0.55));
  return g;
}

/* ═══════════════════════════════════════════════════════════════════════════
   5. Estructura y circulación
   ═══════════════════════════════════════════════════════════════════════════ */

/** Escalera maciza que sube hacia +Z. Apoya en y=0, arranca en z=0. */
export function escalera(ancho, alto, escalones = 5, opts = {}) {
  const g = new THREE.Group();
  const n = Math.max(2, escalones | 0);
  const h = alto / n;
  const d = opts.huella || Math.max(0.26, h * 1.25);
  for (let i = 0; i < n; i++) {
    g.add(pieza(cajaBiselada(ancho, h * (i + 1), d, 0.018), 'piedra', i % 2 ? 0xf6f6f6 : 0xffffff)
      .translateY((h * (i + 1)) / 2).translateZ(-i * d - d / 2));
  }
  if (opts.zancas !== false) {
    for (const s of [-1, 1]) {
      g.add(pieza(extruirPerfil([[0, 0], [n * d, 0], [n * d, alto], [n * d - 0.18, alto]], 0.14, 0.02).rotateY(Math.PI / 2), 'piedra', 0xeaeaea)
        .translateX(s * (ancho / 2 + 0.07)).translateZ(0.02));
    }
  }
  return g;
}

/** Baranda de caños: 2 largueros + montantes. Corre en X, centrada. */
export function baranda(largo, alto = 0.95, opts = {}) {
  const trozos = [];
  const r = opts.radio || 0.035;
  trozos.push(cilindro(r, r, largo, 6).rotateZ(Math.PI / 2).translate(0, alto, 0));
  trozos.push(cilindro(r * 0.8, r * 0.8, largo, 6).rotateZ(Math.PI / 2).translate(0, alto * 0.52, 0));
  const n = Math.max(2, Math.round(largo / (opts.paso || 1.0)));
  for (let i = 0; i <= n; i++) {
    trozos.push(cilindro(r * 0.9, r * 0.9, alto, 6).translate(-largo / 2 + (largo * i) / n, alto / 2, 0));
  }
  if (opts.malla) {
    trozos.push(caja(largo, alto * 0.42, 0.02).translate(0, alto * 0.26, 0));
  }
  return fusionar(trozos);
}

/** Viga. Corre en X, centrada en el origen. perfil: 'I' | 'caja' | 'tubo' | 'madera'. */
export function viga(largo, perfil = 'I', alto = 0.26, ancho = 0.18) {
  if (perfil === 'tubo') return cilindro(ancho / 2, ancho / 2, largo, 8).rotateZ(Math.PI / 2);
  if (perfil === 'madera') return cajaBiselada(largo, alto, ancho, 0.02);
  if (perfil === 'caja') {
    return fusionar([
      caja(largo, alto, ancho).translate(0, 0, 0),
      caja(largo * 1.02, alto * 0.2, ancho * 1.12).translate(0, alto * 0.4, 0),
    ]);
  }
  const t = alto * 0.14;
  return fusionar([
    caja(largo, t, ancho).translate(0, alto / 2 - t / 2, 0),
    caja(largo, t, ancho).translate(0, -alto / 2 + t / 2, 0),
    caja(largo, alto - t * 2, ancho * 0.32).translate(0, 0, 0),
  ]);
}

/** Cercha triangulada. Corre en X, cordón inferior en y=0. */
export function cercha(luz, alto, opts = {}) {
  const trozos = [];
  const r = opts.radio || 0.055;
  const n = Math.max(2, (opts.montantes || Math.round(luz / 1.2)) | 0);
  trozos.push(cilindro(r, r, luz, 6).rotateZ(Math.PI / 2));
  // cordón superior a dos aguas
  const mitad = Math.sqrt((luz / 2) * (luz / 2) + alto * alto);
  for (const s of [-1, 1]) {
    const c = cilindro(r, r, mitad, 6).rotateZ(Math.PI / 2);
    c.rotateZ(s * -Math.atan2(alto, luz / 2));
    c.translate((s * luz) / 4, alto / 2, 0);
    trozos.push(c);
  }
  for (let i = 1; i < n; i++) {
    const t = i / n;
    const x = -luz / 2 + luz * t;
    const y = (1 - Math.abs(t - 0.5) * 2) * alto;
    trozos.push(cilindro(r * 0.7, r * 0.7, Math.max(0.05, y), 5).translate(x, y / 2, 0));
    const xd = -luz / 2 + luz * ((i - 0.5) / n);
    const yd = (1 - Math.abs((i - 0.5) / n - 0.5) * 2) * alto;
    const L = Math.hypot(luz / n / 2, yd);
    const d = cilindro(r * 0.6, r * 0.6, L, 5).rotateZ(Math.PI / 2);
    d.rotateZ(Math.atan2(yd, luz / n / 2) * (t < 0.5 ? 1 : -1));
    d.translate(xd, yd / 2, 0);
    trozos.push(d);
  }
  return fusionar(trozos);
}

/** Columna clásica con basa, fuste acanalado y capitel. */
export function columna(radio, alto, estilo = 0) {
  const trozos = [];
  trozos.push(cilindro(radio * 1.28, radio * 1.42, 0.22, 12).translate(0, 0.11, 0));
  trozos.push(cilindro(radio * 0.9, radio, alto - 0.5, 14).translate(0, alto / 2, 0));
  if (estilo <= 1) {
    for (let i = 0; i < 10; i++) {
      const a = (i / 10) * TAU;
      trozos.push(cilindro(radio * 0.13, radio * 0.13, alto - 0.6, 4)
        .translate(Math.cos(a) * radio * 0.92, alto / 2, Math.sin(a) * radio * 0.92));
    }
  }
  trozos.push(cilindro(radio * 1.15, radio * 0.95, 0.16, 12).translate(0, alto - 0.3, 0));
  trozos.push(caja(radio * 2.6, 0.16, radio * 2.6).translate(0, alto - 0.14, 0));
  return fusionar(trozos);
}

/* ═══════════════════════════════════════════════════════════════════════════
   6. Aparatos: paneles, antenas, parabólicas, banderas, cables, faroles
   ═══════════════════════════════════════════════════════════════════════════ */

/** Panel solar inclinado con bastidor y patas. */
export function panelSolar(ancho, largo, inclinacion = 0.5, opts = {}) {
  const g = new THREE.Group();
  const pano = conjunto(
    pieza(cajaEn(ancho, 0.045, largo, 0, 0.03, 0), 'vidrio', opts.tinte || 0x9fc6ff),
    pieza(cajaEn(ancho + 0.07, 0.06, 0.07, 0, 0.01, largo / 2), 'detalle', 0xdadada),
    pieza(cajaEn(ancho + 0.07, 0.06, 0.07, 0, 0.01, -largo / 2), 'detalle', 0xdadada),
    pieza(cajaEn(0.07, 0.06, largo, ancho / 2, 0.01, 0), 'detalle', 0xdadada),
    pieza(cajaEn(0.07, 0.06, largo, -ancho / 2, 0.01, 0), 'detalle', 0xdadada),
  );
  for (let i = 1; i < 3; i++) pano.add(pieza(cajaEn(0.035, 0.05, largo, -ancho / 2 + (ancho * i) / 3, 0.03, 0), 'detalle', 0xcccccc));
  pano.rotation.x = -inclinacion;
  pano.position.y = 0.42;
  g.add(pano);
  for (const sx of [-1, 1]) {
    g.add(pieza(cilindro(0.04, 0.04, 0.5, 6), 'detalle', 0xd4d4d4).translateX(sx * ancho * 0.4).translateZ(largo * 0.32).translateY(0.2));
    g.add(pieza(cilindro(0.04, 0.04, 0.78, 6), 'detalle', 0xd4d4d4).translateX(sx * ancho * 0.4).translateZ(-largo * 0.32).translateY(0.34));
  }
  return g;
}

/** Antena. tipo: 'latigo' | 'mastil' | 'radar' | 'sensor'. */
export function antena(alto, tipo = 'latigo') {
  const g = new THREE.Group();
  if (tipo === 'mastil') {
    for (let i = 0; i < 3; i++) {
      const a = (i / 3) * TAU;
      g.add(pieza(tuboPor([[Math.cos(a) * 0.3, 0, Math.sin(a) * 0.3], [Math.cos(a) * 0.1, alto, Math.sin(a) * 0.1]], 0.035, 4), 'detalle', 0xf0f0f0));
    }
    const n = Math.max(3, Math.round(alto / 0.8));
    for (let k = 1; k <= n; k++) {
      const t = k / n, r = lerp(0.3, 0.1, t);
      g.add(pieza(toro(r, 0.022, 3, 3).rotateX(Math.PI / 2), 'detalle', 0xe0e0e0).translateY(alto * t));
    }
    g.add(pieza(esfera(0.07, 6), 'emisivo', 0xff5a3c).translateY(alto + 0.08));
  } else if (tipo === 'radar') {
    g.add(pieza(cilindro(0.13, 0.16, alto * 0.7, 8), 'detalle', 0xf0f0f0).translateY(alto * 0.35));
    g.add(pieza(cilindro(0.3, 0.3, 0.24, 12), 'detalle', 0xe4e4e4).translateY(alto * 0.7 + 0.12));
    // la pala del radar es chapa, no bando: era literalmente una tabla de dos
    // metros del color del jugador flotando en el aire sobre un mástil finito
    const pala = cajaBiselada(2.0, 0.42, 0.12, 0.02);
    g.add(pieza(pala, 'detalle', 0xe8e8e8).translateY(alto * 0.7 + 0.36));
    for (let i = 0; i < 6; i++) {
      g.add(pieza(cajaEn(0.06, 0.34, 0.1, -0.9 + i * 0.36, alto * 0.7 + 0.36, 0.08), 'detalle', 0xdcdcdc));
    }
  } else if (tipo === 'sensor') {
    g.add(pieza(cilindro(0.06, 0.09, alto, 8), 'detalle', 0xf0f0f0).translateY(alto / 2));
    g.add(pieza(cajaBiselada(0.3, 0.3, 0.3, 0.04), 'detalle', 0xe6e6e6).translateY(alto + 0.14));
    g.add(pieza(esfera(0.09, 8), 'emisivo', 0x66e6ff).translateY(alto + 0.3));
    for (const s of [-1, 1]) g.add(pieza(cajaEn(0.5, 0.05, 0.06, s * 0.24, alto - 0.2, 0), 'detalle', 0xdedede));
  } else {
    g.add(pieza(cilindro(0.05, 0.1, 0.18, 8), 'detalle', 0xe0e0e0).translateY(0.09));
    g.add(pieza(cilindro(0.012, 0.045, alto, 6), 'detalle', 0xf4f4f4).translateY(alto / 2));
    g.add(pieza(esfera(0.055, 6), 'emisivo', 0xff5a3c).translateY(alto));
  }
  return g;
}

/** Antena parabólica con montura, contra-nervios y bocina. */
export function parabolica(radio, opts = {}) {
  const g = new THREE.Group();
  const seg = 10, prof = radio * 0.42;
  const perfil = [];
  for (let i = 0; i <= seg; i++) {
    const t = i / seg, r = radio * t;
    perfil.push([r, (r * r) / (2 * Math.max(0.001, prof)) * 0.9]);
  }
  for (let i = seg; i >= 0; i--) {
    const t = i / seg, r = radio * t;
    perfil.push([Math.max(0.02, r - 0.02), (r * r) / (2 * Math.max(0.001, prof)) * 0.9 - 0.05]);
  }
  const plato = conjunto(pieza(revolucion(perfil, 18), 'muro', opts.tinte || 0xffffff));
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * TAU;
    plato.add(pieza(cajaEn(radio * 0.94, 0.04, 0.06, radio * 0.47, -0.06, 0).rotateY(a), 'detalle', 0xdcdcdc));
  }
  // bocina en el foco
  for (let i = 0; i < 3; i++) {
    const a = (i / 3) * TAU;
    plato.add(pieza(tuboPor([[Math.cos(a) * radio * 0.8, (radio * 0.8 * radio * 0.8) / (2 * prof) * 0.9, Math.sin(a) * radio * 0.8], [0, prof * 1.55, 0]], 0.022, 4), 'detalle', 0xe8e8e8));
  }
  plato.add(pieza(cilindro(0.1, 0.13, 0.28, 8), 'detalle', 0xf0f0f0).translateY(prof * 1.6));
  plato.rotation.x = opts.elevacion != null ? opts.elevacion : -0.62;
  plato.position.y = radio * 0.85;
  g.add(plato);
  g.add(pieza(cilindro(0.11, 0.15, radio * 0.85, 10), 'detalle', 0xeaeaea).translateY(radio * 0.42));
  g.add(pieza(cilindro(0.34, 0.4, 0.16, 12), 'detalle', 0xdcdcdc).translateY(0.08));
  return g;
}

/** Bandera: mástil, paño de color de jugador y remate. Apoya en y=0. */
export function bandera(alto, opts = {}) {
  const g = new THREE.Group();
  const r = opts.radio || 0.05;
  g.add(pieza(cilindro(r * 0.7, r * 1.5, alto, 8), 'detalle', 0xf0f0f0).translateY(alto / 2));
  g.add(pieza(cilindro(r * 2.2, r * 2.8, 0.16, 8), 'piedra', 0xe8e8e8).translateY(0.08));
  g.add(pieza(esfera(r * 1.9, 8), 'detalle', 0xffe2a0).translateY(alto + r));
  const w = opts.ancho || alto * 0.42, h = opts.altoPano || alto * 0.3;
  // La onda escala con el ancho del paño y ahora vale un cuarto de ese ancho:
  // con 0,17 los pliegues medían dos centímetros en una bandera de metro y pico
  // y se los comía el antialias. Un pliegue que no llega a un par de píxeles de
  // profundidad no sombrea, y una superficie de bando que no sombrea es una
  // mancha de color plano, que es de lo que veníamos.
  const pano = panoOndulado(w, h, opts.amp || Math.max(0.14, w * 0.22), opts.segs || 18, opts.fase || 0);
  pano.rotateY(Math.PI / 2);
  pano.translate(0, alto - h * 0.62, -w / 2 - r);
  g.add(pieza(pano, 'jugador', 0xffffff));
  // vaina cosida al mástil: le da canto a la tela justo donde nace
  g.add(pieza(cilindro(r * 1.35, r * 1.35, h * 1.04, 7), 'detalle', 0xdcdcdc)
    .translateY(alto - h * 0.62).translateZ(-r * 0.6));
  return g;
}

/** Cable colgante con comba entre dos puntos. */
export function cable(desde, hasta, comba = 0.5, radio = 0.028) {
  const a = desde.isVector3 ? desde : new THREE.Vector3(desde[0], desde[1], desde[2]);
  const b = hasta.isVector3 ? hasta : new THREE.Vector3(hasta[0], hasta[1], hasta[2]);
  const m1 = a.clone().lerp(b, 0.33); m1.y -= comba * 0.85;
  const m2 = a.clone().lerp(b, 0.66); m2.y -= comba * 0.85;
  return tuboPor([a, m1, m2, b], radio, 4);
}

/** Farol / luminaria. Apoya en y=0. El foco emisivo queda en (0, alto, ~0.25). */
export function farol(alto, estilo = 0) {
  const g = new THREE.Group();
  if (estilo <= 1) {
    g.add(pieza(cilindro(0.07, 0.13, alto * 0.9, 8), 'detalle', 0xf0f0f0).translateY(alto * 0.45));
    g.add(pieza(cilindro(0.16, 0.2, 0.18, 8), 'piedra', 0xe6e6e6).translateY(0.09));
    g.add(pieza(aro(0.14, 0.028, 4, 10), 'detalle', 0xdedede).translateY(alto * 0.62));
    g.add(pieza(cilindro(0.16, 0.1, 0.34, 6), 'detalle', 0xe8e8e8).translateY(alto * 0.9 + 0.17));
    g.add(pieza(esfera(0.14, 8), 'emisivo', 0xffcf7a).translateY(alto * 0.9 + 0.12));
    g.add(pieza(cilindro(0.03, 0.09, 0.2, 6), 'detalle', 0xdcdcdc).translateY(alto * 0.9 + 0.42));
  } else if (estilo === 2) {
    g.add(pieza(cilindro(0.06, 0.1, alto, 8), 'detalle', 0xf0f0f0).translateY(alto / 2));
    g.add(pieza(tuboPor([[0, alto - 0.05, 0], [0.15, alto + 0.2, 0.15], [0.42, alto + 0.22, 0.42]], 0.05, 5), 'detalle', 0xe8e8e8));
    g.add(pieza(cajaBiselada(0.5, 0.14, 0.3, 0.03), 'detalle', 0xdcdcdc).translateY(alto + 0.16).translateX(0.5).translateZ(0.5));
    g.add(pieza(cajaEn(0.42, 0.05, 0.24, 0.5, alto + 0.08, 0.5), 'emisivo', 0xfff0c0));
  } else {
    g.add(pieza(cilindro(0.045, 0.075, alto, 8), 'detalle', 0xf4f4f4).translateY(alto / 2));
    g.add(pieza(cajaBiselada(0.14, 0.1, 0.62, 0.03), 'detalle', 0xeeeeee).translateY(alto + 0.03));
    g.add(pieza(cajaEn(0.1, 0.035, 0.55, 0, alto - 0.03, 0), 'emisivo', estilo === 4 ? 0xd8c8ff : 0xdff4ff));
  }
  return g;
}

/* ═══════════════════════════════════════════════════════════════════════════
   7. Utilería: barriles, cajones y pilas de recurso
   ═══════════════════════════════════════════════════════════════════════════ */

export function barril(r = 0.28, h = 0.72) {
  const perfil = [];
  const seg = 8;
  for (let i = 0; i <= seg; i++) {
    const t = i / seg;
    perfil.push([r * (0.82 + 0.18 * Math.sin(t * Math.PI)), t * h]);
  }
  perfil.push([0, h]);
  perfil.unshift([0, 0]);
  const trozos = [revolucion(perfil, 12)];
  for (const t of [0.2, 0.5, 0.8]) {
    trozos.push(aro(r * (0.83 + 0.18 * Math.sin(t * Math.PI)) + 0.012, 0.022, 4, 12).translate(0, t * h, 0));
  }
  return fusionar(trozos);
}

export function cajon(a = 0.6, b = 0.5, c = 0.6) {
  const trozos = [cajaBiselada(a, b, c, 0.02)];
  const t = 0.05;
  for (const s of [-1, 1]) {
    trozos.push(caja(a + t, t * 1.4, t * 1.4).translate(0, (s * b) / 2, c / 2));
    trozos.push(caja(a + t, t * 1.4, t * 1.4).translate(0, (s * b) / 2, -c / 2));
    trozos.push(caja(t * 1.4, b, t * 1.4).translate((s * a) / 2, 0, c / 2));
    trozos.push(caja(t * 1.4, b, t * 1.4).translate((s * a) / 2, 0, -c / 2));
  }
  trozos.push(caja(a * 0.85, t, t).translate(0, 0, c / 2 + t * 0.3));
  const g = fusionar(trozos);
  g.translate(0, b / 2, 0);
  return g;
}

/** Pila de troncos apilada en pirámide. Los troncos corren en Z. */
export function pilaTroncos(n = 9, rng = null, opts = {}) {
  const r = opts.radio || 0.19, L = opts.largo || 1.9;
  const trozos = [];
  let quedan = Math.max(1, n | 0), fila = 0;
  const base = Math.max(2, Math.ceil(Math.sqrt(n) + 1));
  while (quedan > 0 && fila < 6) {
    const cant = Math.max(1, base - fila);
    for (let i = 0; i < cant && quedan > 0; i++, quedan--) {
      const x = (i - (cant - 1) / 2) * r * 2.06 + (rng ? rng.float(-0.02, 0.02) : 0);
      const y = r + fila * r * 1.78;
      const t = cilindro(r * (rng ? rng.float(0.92, 1.05) : 1), r, L * (rng ? rng.float(0.9, 1.06) : 1), 8).rotateX(Math.PI / 2);
      t.translate(x, y, rng ? rng.float(-0.12, 0.12) : 0);
      trozos.push(t);
    }
    fila++;
  }
  return fusionar(trozos);
}

/** Pila de sacos: esferas achatadas apiladas con desorden determinista. */
export function pilaSacos(n = 8, rng = null) {
  const trozos = [];
  const s = 0.34;
  let quedan = Math.max(1, n | 0), fila = 0;
  while (quedan > 0 && fila < 5) {
    const cant = Math.max(1, 3 - Math.floor(fila / 2));
    for (let i = 0; i < cant && quedan > 0; i++, quedan--) {
      const g = esfera(s, 8);
      g.scale(1.25, 0.72, 0.95);
      const a = rng ? rng.float(-0.5, 0.5) : (i - 1) * 0.3;
      g.rotateY(a);
      g.translate((i - (cant - 1) / 2) * s * 2.1, s * 0.55 + fila * s * 1.05, rng ? rng.float(-0.16, 0.16) : 0);
      trozos.push(g);
    }
    fila++;
  }
  return fusionar(trozos);
}

/** Montón de mineral: bloques irregulares en talud. */
export function pilaMineral(n = 12, rng = null, opts = {}) {
  const trozos = [];
  const R = opts.radio || 1.1;
  for (let i = 0; i < n; i++) {
    const t = i / n;
    const a = rng ? rng.float(0, TAU) : t * 4.7;
    const rr = (rng ? Math.sqrt(rng.float(0, 1)) : Math.sqrt(t)) * R;
    const s = (rng ? rng.float(0.16, 0.34) : 0.24) * (1.15 - rr / (R * 1.6));
    const g = roca(s, 0);
    g.scale(1, rng ? rng.float(0.6, 0.95) : 0.78, 1);
    g.rotateY(rng ? rng.float(0, TAU) : t * 3.1);
    g.rotateX(rng ? rng.float(-0.4, 0.4) : 0);
    g.translate(Math.cos(a) * rr, s * 0.55 + Math.max(0, (1 - rr / R)) * R * 0.32, Math.sin(a) * rr);
    trozos.push(g);
  }
  return fusionar(trozos);
}

/* ═══════════════════════════════════════════════════════════════════════════
   8. Cartelería — el texto es geometría de barras, sin fuentes externas
   ═══════════════════════════════════════════════════════════════════════════ */

/** Fuente 5×7 por columnas; el bit 0 es la fila de arriba. */
const FUENTE = {
  ' ': [0, 0, 0, 0, 0], '-': [0x08, 0x08, 0x08, 0x08, 0x08], '.': [0, 0x60, 0x60, 0, 0],
  ':': [0, 0x36, 0x36, 0, 0], '/': [0x20, 0x10, 0x08, 0x04, 0x02], '+': [0x08, 0x08, 0x3E, 0x08, 0x08],
  '0': [0x3E, 0x51, 0x49, 0x45, 0x3E], '1': [0x00, 0x42, 0x7F, 0x40, 0x00],
  '2': [0x42, 0x61, 0x51, 0x49, 0x46], '3': [0x21, 0x41, 0x45, 0x4B, 0x31],
  '4': [0x18, 0x14, 0x12, 0x7F, 0x10], '5': [0x27, 0x45, 0x45, 0x45, 0x39],
  '6': [0x3C, 0x4A, 0x49, 0x49, 0x30], '7': [0x01, 0x71, 0x09, 0x05, 0x03],
  '8': [0x36, 0x49, 0x49, 0x49, 0x36], '9': [0x06, 0x49, 0x49, 0x29, 0x1E],
  A: [0x7E, 0x11, 0x11, 0x11, 0x7E], B: [0x7F, 0x49, 0x49, 0x49, 0x36],
  C: [0x3E, 0x41, 0x41, 0x41, 0x22], D: [0x7F, 0x41, 0x41, 0x22, 0x1C],
  E: [0x7F, 0x49, 0x49, 0x49, 0x41], F: [0x7F, 0x09, 0x09, 0x01, 0x01],
  G: [0x3E, 0x41, 0x49, 0x49, 0x7A], H: [0x7F, 0x08, 0x08, 0x08, 0x7F],
  I: [0x00, 0x41, 0x7F, 0x41, 0x00], J: [0x20, 0x40, 0x41, 0x3F, 0x01],
  K: [0x7F, 0x08, 0x14, 0x22, 0x41], L: [0x7F, 0x40, 0x40, 0x40, 0x40],
  M: [0x7F, 0x02, 0x0C, 0x02, 0x7F], N: [0x7F, 0x04, 0x08, 0x10, 0x7F],
  O: [0x3E, 0x41, 0x41, 0x41, 0x3E], P: [0x7F, 0x09, 0x09, 0x09, 0x06],
  Q: [0x3E, 0x41, 0x51, 0x21, 0x5E], R: [0x7F, 0x09, 0x19, 0x29, 0x46],
  S: [0x46, 0x49, 0x49, 0x49, 0x31], T: [0x01, 0x01, 0x7F, 0x01, 0x01],
  U: [0x3F, 0x40, 0x40, 0x40, 0x3F], V: [0x1F, 0x20, 0x40, 0x20, 0x1F],
  W: [0x7F, 0x20, 0x18, 0x20, 0x7F], X: [0x63, 0x14, 0x08, 0x14, 0x63],
  Y: [0x03, 0x04, 0x78, 0x04, 0x03], Z: [0x61, 0x51, 0x49, 0x45, 0x43],
};
const SIN_TILDE = { Á: 'A', É: 'E', Í: 'I', Ó: 'O', Ú: 'U', Ü: 'U', Ñ: 'N' };

/**
 * Convierte un texto en barras verticales (una por corrida de píxeles de cada
 * columna). Devuelve una BufferGeometry centrada en X, base en y=0.
 */
export function textoBarras(texto, altoLetra = 0.4, grosor = 0.05) {
  const s = String(texto || '').toUpperCase();
  const px = altoLetra / 7;
  const paso = px * 6;
  const trozos = [];
  let x = 0;
  for (const ch0 of s) {
    const ch = SIN_TILDE[ch0] || ch0;
    const gl = FUENTE[ch];
    if (!gl) { x += paso; continue; }
    for (let c = 0; c < 5; c++) {
      const col = gl[c];
      let r = 0;
      while (r < 7) {
        if (col & (1 << r)) {
          let r2 = r;
          while (r2 + 1 < 7 && (col & (1 << (r2 + 1)))) r2++;
          const h = (r2 - r + 1) * px;
          trozos.push(caja(px * 1.06, h, grosor).translate(x + c * px + px / 2, altoLetra - (r * px + h / 2), 0));
          r = r2 + 1;
        } else r++;
      }
    }
    x += paso;
  }
  const g = fusionar(trozos);
  if (g) g.translate(-x / 2 + px, 0, 0);
  return g;
}

/** Cartel: bastidor, chapa y letras. El texto va como barras, sin fuentes. */
export function cartel(ancho, alto, texto = '', estilo = 1, opts = {}) {
  const g = new THREE.Group();
  const gr = 0.07;
  // La CHAPA del cartel iba en la ranura de jugador. Casi todos los edificios
  // cuelgan uno o dos carteles, así que eran uno o dos rectángulos macizos de
  // color plano por edificio, siempre de frente a la cámara. Damos vuelta el
  // reparto: la chapa lleva material y el que se pinta es el bastidor, que asoma
  // cinco centímetros por todo el perímetro. Marco de color alrededor de una
  // superficie con textura: se lee mejor y ocupa la décima parte.
  g.add(pieza(cajaBiselada(ancho, alto, gr, 0.02), 'detalle', estilo >= 3 ? 0xe8ecee : 0xdcd6c8).translateY(alto / 2));
  g.add(pieza(cajaBiselada(ancho + 0.1, alto + 0.1, gr * 0.7, 0.02), estilo >= 3 ? 'detalle' : 'jugador', 0xffffff).translateY(alto / 2).translateZ(-0.02));
  const letras = textoBarras(texto, Math.min(alto * 0.56, (ancho * 0.9) / Math.max(1, String(texto).length * 0.72)), 0.045);
  if (letras) {
    g.add(pieza(letras, estilo >= 1 ? 'emisivo' : 'detalle', opts.tinteTexto || (estilo === 4 ? 0xd8c8ff : estilo >= 1 ? 0xffd98a : 0x4a4038))
      .translateY(alto * 0.5 - Math.min(alto * 0.56, (ancho * 0.9) / Math.max(1, String(texto).length * 0.72)) * 0.5)
      .translateZ(gr / 2 + 0.02));
  }
  if (opts.soportes !== false) {
    for (const s of [-1, 1]) {
      g.add(pieza(cilindro(0.04, 0.04, alto * 0.5, 6), 'detalle', 0xd8d8d8).translateX(s * ancho * 0.36).translateY(-alto * 0.25));
    }
  }
  return g;
}

/* ═══════════════════════════════════════════════════════════════════════════
   9. Piezas de obra y de daño
   ═══════════════════════════════════════════════════════════════════════════ */

/** Andamio tubular con tablones y red. Cubre un rectángulo ancho×largo. */
export function andamio(ancho, largo, alto, estilo = 0) {
  const g = new THREE.Group();
  const r = estilo === 0 ? 0.06 : 0.05;
  const nx = Math.max(2, Math.round(ancho / 1.6)), nz = Math.max(2, Math.round(largo / 1.6));
  const pisos = Math.max(1, Math.round(alto / 1.7));
  const perim = [];
  for (let i = 0; i <= nx; i++) { perim.push([-ancho / 2 + (ancho * i) / nx, -largo / 2]); perim.push([-ancho / 2 + (ancho * i) / nx, largo / 2]); }
  for (let k = 1; k < nz; k++) { perim.push([-ancho / 2, -largo / 2 + (largo * k) / nz]); perim.push([ancho / 2, -largo / 2 + (largo * k) / nz]); }
  const postes = [];
  for (const [x, z] of perim) postes.push(cilindro(r, r, alto, 6).translate(x, alto / 2, z));
  g.add(pieza(fusionar(postes), 'detalle', estilo === 0 ? 0xd8b184 : 0xdedede));
  const barras = [];
  for (let p = 1; p <= pisos; p++) {
    const y = (alto * p) / pisos - 0.1;
    barras.push(caja(ancho + 0.1, r * 1.2, r * 1.2).translate(0, y, largo / 2));
    barras.push(caja(ancho + 0.1, r * 1.2, r * 1.2).translate(0, y, -largo / 2));
    barras.push(caja(r * 1.2, r * 1.2, largo + 0.1).translate(ancho / 2, y, 0));
    barras.push(caja(r * 1.2, r * 1.2, largo + 0.1).translate(-ancho / 2, y, 0));
    // tablones de trabajo
    barras.push(caja(ancho + 0.5, 0.06, 0.55).translate(0, y + 0.06, largo / 2 + 0.2));
    barras.push(caja(0.55, 0.06, largo + 0.5).translate(ancho / 2 + 0.2, y + 0.06, 0));
    // cruces de san andrés
    const L = Math.hypot(ancho / nx, alto / pisos);
    for (let i = 0; i < nx; i++) {
      const c = cilindro(r * 0.6, r * 0.6, L, 5).rotateZ(Math.PI / 2);
      c.rotateZ(Math.atan2(alto / pisos, ancho / nx) * (i % 2 ? -1 : 1));
      c.translate(-ancho / 2 + (ancho * (i + 0.5)) / nx, y - alto / pisos / 2, largo / 2);
      barras.push(c);
    }
  }
  g.add(pieza(fusionar(barras), 'detalle', estilo === 0 ? 0xc9a678 : 0xd0d0d0));
  // escalerilla de acceso
  const esc = [];
  for (let i = 0; i < Math.floor(alto / 0.4); i++) esc.push(caja(0.42, 0.05, 0.05).translate(0, 0.35 + i * 0.4, 0));
  esc.push(cilindro(0.035, 0.035, alto, 5).translate(-0.2, alto / 2, 0));
  esc.push(cilindro(0.035, 0.035, alto, 5).translate(0.2, alto / 2, 0));
  g.add(pieza(fusionar(esc), 'detalle', 0xdcdcdc).translateX(ancho / 2 + 0.42).translateZ(-largo * 0.25));
  return g;
}

/** Losa de cimentación con encofrado y hierros. Es lo que se ve en progreso 0. */
export function cimientos(ancho, largo, estilo = 0, rng = null) {
  const g = new THREE.Group();
  g.add(pieza(cajaBiselada(ancho + 0.5, 0.34, largo + 0.5, 0.05), 'piedra', 0xf0f0f0).translateY(0.13));
  g.add(pieza(cajaBiselada(ancho + 0.16, 0.2, largo + 0.16, 0.04), 'piedra', 0xffffff).translateY(0.36));
  const trozos = [];
  for (const s of [-1, 1]) {
    trozos.push(caja(ancho + 0.2, 0.12, 0.1).translate(0, 0.5, (s * largo) / 2));
    trozos.push(caja(0.1, 0.12, largo + 0.2).translate((s * ancho) / 2, 0.5, 0));
  }
  g.add(pieza(fusionar(trozos), 'detalle', 0xd9c39c));
  if (estilo >= 2) {
    const hierros = [];
    const n = Math.max(2, Math.round(ancho / 1.4));
    for (let i = 0; i <= n; i++) {
      const x = -ancho / 2 + (ancho * i) / n;
      hierros.push(cilindro(0.025, 0.025, 0.6, 4).translate(x, 0.75, -largo / 2 + 0.15));
      hierros.push(cilindro(0.025, 0.025, 0.6, 4).translate(x, 0.75, largo / 2 - 0.15));
    }
    g.add(pieza(fusionar(hierros), 'detalle', 0xc98a5a));
  }
  return g;
}

/**
 * Escombro y grieta: submallas que la fábrica esconde y muestra según el daño.
 * `nivel` 1 = grietas y cascotes; 2 = boquete, vigas caídas y hollín.
 */
export function ruina(ancho, largo, alto, nivel = 1, rng = null, estilo = 0) {
  const g = new THREE.Group();
  const rnd = (a, b) => (rng ? rng.float(a, b) : (a + b) / 2);
  const n = nivel === 1 ? 7 : 14;
  for (let i = 0; i < n; i++) {
    const s = rnd(0.14, nivel === 1 ? 0.3 : 0.5);
    const a = rnd(0, TAU), d = rnd(ancho * 0.3, ancho * 0.72);
    const r = roca(s, 0);
    r.scale(1, rnd(0.5, 0.9), 1);
    r.rotateY(rnd(0, TAU));
    r.translate(Math.cos(a) * d, s * 0.5, Math.sin(a) * d * (largo / Math.max(0.1, ancho)));
    g.add(pieza(r, 'piedra', nivel === 1 ? 0xb8b0a8 : 0x8a8078));
  }
  // grietas: cuñas oscuras pegadas al muro
  for (let i = 0; i < (nivel === 1 ? 4 : 7); i++) {
    const lado = i % 4;
    const h = rnd(alto * 0.25, alto * 0.7);
    const w = rnd(0.06, 0.14);
    const geo = extruirPerfil([[0, 0], [w, h * 0.34], [w * 0.5, h * 0.68], [w * 1.6, h], [0, h * 0.72]], 0.08, 0.01);
    const m = pieza(geo, 'muro', 0x4a4038);
    const x = lado < 2 ? rnd(-ancho * 0.4, ancho * 0.4) : (lado === 2 ? -1 : 1) * (ancho / 2 + 0.02);
    const z = lado < 2 ? (lado === 0 ? 1 : -1) * (largo / 2 + 0.02) : rnd(-largo * 0.4, largo * 0.4);
    m.position.set(x, rnd(0.2, alto * 0.3), z);
    if (lado >= 2) m.rotation.y = Math.PI / 2;
    g.add(m);
  }
  if (nivel === 2) {
    // boquete: un trozo de muro reventado hacia afuera + vigas caídas
    g.add(pieza(cajaBiselada(ancho * 0.36, alto * 0.34, 0.5, 0.04), 'muro', 0x6a6058)
      .translateY(alto * 0.24).translateZ(largo / 2 - 0.1));
    for (let i = 0; i < 4; i++) {
      const v = viga(rnd(1.2, 2.4), estilo <= 0 ? 'madera' : 'I', 0.2, 0.14);
      const m = pieza(v, 'detalle', 0x6b5a48);
      m.position.set(rnd(-ancho * 0.5, ancho * 0.5), rnd(0.15, 0.6), rnd(-largo * 0.5, largo * 0.6));
      m.rotation.set(rnd(-0.4, 0.4), rnd(0, TAU), rnd(-0.5, 0.5));
      g.add(m);
    }
    g.add(pieza(cajaEn(ancho * 0.8, 0.04, largo * 0.8, 0, 0.03, 0), 'muro', 0x3a332c));
  }
  return g;
}

/** Llama estilizada para el edificio en llamas (ranura emisiva, sin costo). */
export function llama(alto = 0.9, ancho = 0.5, fase = 0) {
  const trozos = [];
  for (let k = 0; k < 3; k++) {
    const s = 1 - k * 0.26;
    const perfil = [];
    for (let i = 0; i <= 7; i++) {
      const t = i / 7;
      perfil.push([ancho * s * Math.sin(t * Math.PI * 0.92) * (1 - t * 0.55), t * alto * s]);
    }
    const g = revolucion(perfil, 7);
    g.rotateY(fase + k * 1.3);
    g.translate(Math.cos(fase + k * 2.1) * ancho * 0.22, k * alto * 0.16, Math.sin(fase + k * 2.1) * ancho * 0.22);
    trozos.push(g);
  }
  return fusionar(trozos);
}

export default {
  RANURAS, pieza, conjunto, colocar, fusionar, uvCaja, bisel, detalleRemaches, aro, cajaMaciza,
  muroConVentanas, muroCiego, techoDosAguas, techoPlanoConPretil, techoDienteSierra, techoBoveda,
  cupula, chimenea, torre, silo, escalera, baranda, viga, cercha, columna,
  panelSolar, antena, parabolica, bandera, cable, farol,
  barril, cajon, pilaTroncos, pilaSacos, pilaMineral, cartel, textoBarras,
  andamio, cimientos, ruina, llama,
};
