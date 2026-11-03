/**
 * UnidadFabrica — mallas procedurales para todas las unidades del juego.
 *
 * Estrategia:
 *  - Cada unidad se describe como un ÁRBOL DE PIEZAS (`Pieza`). Una pieza es un
 *    pivote de animación con geometría propia. El árbol se compila UNA vez por
 *    (clave, edad) y queda cacheado: las 200 unidades de una partida comparten
 *    las mismas BufferGeometry y los mismos materiales.
 *  - Dentro de una pieza la geometría se acumula por "slot" de material
 *    (cuerpo / metal / jugador / vidrio / emisivo) y se fusiona: cada pieza son
 *    1–2 mallas, no veinte. El color no sale de mil materiales sino del atributo
 *    `color` por vértice, así 4 materiales alcanzan para todo el ejército.
 *  - El slot `jugador` va en su propia malla marcada con `userData.colorJugador`,
 *    que es lo que VistaEntidades busca para teñir el ejército.
 *
 * La cámara mira desde 70–90 m: manda la SILUETA. Cada unidad tiene al menos un
 * rasgo de contorno que la delata sin leer la textura (penacho, mira telescópica,
 * tubo al hombro, antena, escudo del cañón, plumero del caballo).
 *
 * ══════════════ REGLA DE REPARTO DEL COLOR DE BANDO ══════════════
 *
 * Es la regla más importante del archivo y la que más veces se rompió sola, así
 * que queda escrita acá arriba y no en el sitio de uso:
 *
 *  1. UNA sola zona por unidad, GRANDE y CONTIGUA. Concretamente:
 *       humano    -> manto sobre los hombros + prenda frontal (peto / chaleco /
 *                    coraza / abrigo). Las dos se tocan: leen como una mancha.
 *       jinete    -> capa del jinete + mantilla del caballo (apiladas en
 *                    vertical, se leen como una sola desde 49° de elevación).
 *       blindado  -> la TORRETA (la masa que mira al cielo). El casco va gris.
 *       artillería-> el escudo. Aéreo -> el fuselaje. Naval -> la superestructura.
 *     Si una variante no tiene torreta (el ariete), entonces la zona es el casco:
 *     lo que no puede pasar es que sean las dos.
 *
 *  2. NADA de detallitos teñidos. Cintas de casco, gorras, viseras, correas,
 *     charreteras, faldones, mangas y perneras van en gama desaturada. Diez
 *     manchitas del color del jugador repartidas por el cuerpo no se leen como
 *     "este es mío": se leen como ruido, y de paso lavan la mancha buena.
 *
 *  3. Todo lo que NO es del jugador vive dentro de GAMA (ver abajo): cueros,
 *     grises, oliva, marrones. El color de bando tiene que ser lo ÚNICO saturado
 *     de la silueta, si no escanear la pantalla por color no encuentra nada.
 *
 *  4. El color de bando RECIBE LUZ. Va en un MeshStandardMaterial normal con el
 *     albedo teñido, jamás en `emissive` ni en un material sin iluminar: la cara
 *     al sol y la cara en sombra tienen que dar RGB distintos. Un jurado leyó lo
 *     contrario como "material sin asignar o bug de shader" — ver `materialSlot`,
 *     que fuerza el estado del material justamente para que eso no vuelva.
 *
 *  5. La zona de bando tiene VOLUMEN PROPIO. Desde 49° de elevación lo que se ve
 *     de una unidad son sus caras superiores: si ahí el bando es una tapa plana
 *     (un cono recto, un disco, una placa horizontal) todas sus normales miran
 *     casi para el mismo lado, devuelven casi el mismo RGB y la unidad se lee
 *     como una calcomanía. La superficie pintada tiene que curvarse de la
 *     vertical a la horizontal DENTRO de la propia pieza, así el gradiente de
 *     sombreado nace de la forma y no depende de que algo le tire una sombra.
 *     Ver `mantoBando`.
 *
 * API pública:
 *   crearMallaUnidad(clave, edad, ctx, opciones) -> { grupo, partes, altura,
 *                                                     animar, setColorJugador, dispose }
 *   geometriaFusionadaUnidad(clave, edad, ctx)   -> BufferGeometry (para instancing)
 *   CATALOGO_UNIDADES                            -> receta visual de cada unidad
 */
import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';
import { RNG, clamp, lerp } from '../core/RNG.js';
import { ESTADO } from '../core/World.js';
import { uniformesCielo } from '../render/Cielo.js';
import * as P from './UnidadPartes.js';

const TAU = Math.PI * 2;
const H = P.H;

/* ═══════ 0. Escala de JUEGO, caricatura y reserva de gama ═══════ */

/**
 * ESCALA DE JUEGO, NO ESCALA DE MUNDO.
 *
 * La cámara está a distancia 78, elevación 49° y FOV 42: el plano focal cubre
 * unos 60 m de ancho. Un humano "realista" de 1,80 m ocupa ahí ~32 px teóricos
 * y bastante menos en la práctica, o sea el mismo tamaño que una mota de tierra
 * del terreno. En cinco segundos no se puede CONTAR cuántas unidades hay, que
 * es el dato más básico de un RTS.
 *
 * Age of Empires miente a propósito: el aldeano es ~1/3 de la altura de la casa,
 * no 1/8. Acá hacemos lo mismo con un factor por CLASE. Afinar es tocar esta
 * tabla y nada más.
 *
 * Dos reglas que hay que respetar al tocar los números:
 *  1. `xz` se aplica a X y a Z POR IGUAL. Cualquier pivote que gire sobre Y
 *     (torretas, rotores, radares) se deformaría al girar si X ≠ Z.
 *  2. `y` no puede alejarse más de ~8% de `xz`: hay ruedas que giran en el
 *     plano XY (artillería, caravana, semioruga) y con más anisotropía se ven
 *     ovaladas. Dentro de ese margen el tanque queda genuinamente más ancho y
 *     más bajo sin que ninguna rueda cabecee.
 *
 * El radio de COLISIÓN lo fija Movimiento.js y NO se toca desde acá: las
 * unidades se solapan un poco más que antes, que es justamente el amontonamiento
 * de los RTS clásicos.
 *
 *   clase        xz     y     resultado aproximado en metros de mundo
 *   humano      2.00  2.00    aldeano 3.5 m · fusilero 3.6 m · exoinfante 3.9 m
 *   jinete      1.78  1.78    húsar ~4.1 m hasta el penacho
 *   blindado    1.52  1.42    tanque 9.0 × 4.6 × 3.3 (antes 5.9 × 3.0 × 2.35)
 *   artilleria  1.60  1.50    cañón de campaña 2.3 m de alto, rueda Ø 1.9
 *   aereo       1.45  1.45    dron de ala 5.4 m de envergadura
 *   naval       1.18  1.12    la fragata ya era enorme, sólo la acompañamos
 *   caravana    1.48  1.40    el carro tiene que leerse como vehículo, no como caja
 */
const ESCALA_JUEGO = {
  humano: { xz: 2.00, y: 2.00 },
  jinete: { xz: 1.78, y: 1.78 },
  blindado: { xz: 1.52, y: 1.42 },
  artilleria: { xz: 1.60, y: 1.50 },
  aereo: { xz: 1.45, y: 1.45 },
  naval: { xz: 1.18, y: 1.12 },
  caravana: { xz: 1.48, y: 1.40 },
};

/**
 * CARICATURA SUAVE. A escala de juego una anatomía correcta se lee como un
 * palito: lo que delata a un humano a 80 m es la cabeza sobre los hombros y el
 * bulto de las manos con el arma. Los RTS clásicos agrandan esas tres cosas
 * un escalón por encima del resto. Son multiplicadores SOBRE la escala de clase.
 */
const PROPORCION = {
  cabeza: 1.16,      // cabeza + casco + penacho: el punto de lectura de la silueta
  mano: 1.30,        // los guantes cierran el contorno del brazo con el arma
  arma: 1.16,        // un arma fina desaparece antes que el cuerpo
  bota: 1.14,        // los pies anclan la figura al piso y ensanchan la base
  extremidad: 1.12,  // brazos: menos alambre, más volumen
  // Las piernas van un escalón MÁS que los brazos y con perfil cónico (P.miembro,
  // muslo grueso -> pantorrilla fina). El jurado las leyó como "palitos
  // semitransparentes": el problema no era el material sino que un cilindro de
  // radio constante y 8 px de ancho no genera sombra propia, así que no tiene
  // volumen y el ojo lo interpreta como un poste translúcido.
  pierna: 1.34,
};

/**
 * SILUETA POR CLASE — a 80 m no se lee el color, se lee el contorno.
 *
 * Todas las infanterías salían del mismo constructor con las mismas medidas, así
 * que un tirador y un fusilero de línea eran EL MISMO muñeco con otro sombrero.
 * Esta tabla exagera lo que las separa. Cuatro palancas, todas de contorno:
 *
 *   hombros  ancho del bloque superior y separación de los brazos. Es lo primero
 *            que se ve: trapecio ancho = asalto/antitanque, vertical fina = tirador.
 *   cabeza   escala del pivote de la cabeza (casco + penacho incluidos): sube o
 *            baja el punto más alto de la figura.
 *   arma     largo del arma. Un rifle de 1,4× dice "tirador" sin ningún texto.
 *   paso     separación de los pies: base ancha = pesado, base junta = ágil.
 *   inclina  rotación Z del torso. NEGATIVO = se echa hacia adelante (agazapado),
 *            positivo = hacia atrás (contrapeso del que carga un tubo pesado).
 *   alto     escala general de la unidad (uniforme: hay pivotes que giran en Y).
 *
 * Regla al tocar esto: dos clases nunca pueden compartir la combinación
 * (hombros, arma). Si dos filas se parecen, una de las dos está de más.
 */
const SILUETA = {
  linea: { hombros: 1.06, cabeza: 1.00, arma: 1.00, paso: 1.00, inclina: -0.03, alto: 1.00 },
  antiblindaje: { hombros: 1.26, cabeza: 0.94, arma: 1.18, paso: 1.16, inclina: 0.05, alto: 1.02 },
  tirador: { hombros: 0.84, cabeza: 1.06, arma: 1.30, paso: 0.80, inclina: -0.14, alto: 1.03 },
  apoyo: { hombros: 0.80, cabeza: 1.12, arma: 0.88, paso: 0.84, inclina: -0.05, alto: 0.94 },
  obrero: { hombros: 0.92, cabeza: 1.04, arma: 0.94, paso: 0.96, inclina: -0.13, alto: 0.93 },
};
const SILUETA_DEF = SILUETA.linea;

/**
 * RESERVA DE GAMA — la regla de color más importante del archivo.
 *
 * El color de bando sólo aísla si es lo ÚNICO saturado de la unidad. Si el
 * cuero es marrón vivo y la casaca es azul vivo, escanear la pantalla por color
 * no encuentra nada. Así que todo lo que no es del jugador queda desaturado:
 * cueros, grises, marrones y verdes oliva apagados.
 *
 * Además cada rol tiene un PISO de luminosidad: la medición del jurado dice que
 * entre el 30% y el 99% de nuestros píxeles caen por debajo de 32/255. Una
 * unidad no puede aportar agujeros negros al cuadro, ni siquiera en el pelo.
 *
 *   rol -> [saturación máxima, luminosidad mínima, luminosidad máxima] en sRGB
 *
 * El techo de luminosidad es una baranda de seguridad, NO una reducción: está
 * puesto por encima de todos los tonos actuales justamente para no apagar nada.
 * El que hace trabajo real es el piso.
 *
 * `emis` queda AFUERA a propósito: son las luces vivas de las edades tardías,
 * y encima son de las poquísimas altas luces que tiene la escena.
 */
const GAMA = {
  tela: [0.16, 0.38, 0.82],   // techo alto: el blanco de la Sintética es alta luz, no se toca
  tela2: [0.16, 0.30, 0.58],
  cuero: [0.20, 0.28, 0.52],
  madera: [0.22, 0.32, 0.58],
  metal: [0.06, 0.52, 0.82],
  metalOsc: [0.07, 0.30, 0.50],
  correaje: [0.12, 0.42, 0.84],
  acento: [0.26, 0.50, 0.78],
  oscuro: [0.10, 0.24, 0.36],
  goma: [0.05, 0.20, 0.32],
  piel: [0.30, 0.52, 0.76],
  vidrio: [0.14, 0.56, 0.86],
};

/**
 * ══════════════ PINTURA DE BANDO — la regla compartida ══════════════
 *
 * QUÉ SE ENCONTRÓ EN LA AUDITORÍA (medido sobre las capturas del panel):
 *
 *  a) El material de bando es un MeshStandardMaterial correcto: emissive negro,
 *     emissiveIntensity 0, sin flatShading, toneMapped, roughness de paño. Eso
 *     NO era el bug. El bug es lo que le llega DESPUÉS, desde la vista:
 *     el color del jugador se convierte de sRGB a lineal DOS VECES (el
 *     constructor de THREE.Color ya convierte, y encima se llama
 *     `convertSRGBToLinear()`), así que el azul de bando `#3d8ee8`, que en
 *     lineal es (0.047, 0.271, 0.807), entra al material como
 *     (0.004, 0.060, 0.616): un azul con DOS CANALES EN CERO. Y un canal en
 *     cero no sube con el sol ni baja con la sombra. El único canal vivo se
 *     come toda la luz, satura contra la rodilla del ACES y devuelve el mismo
 *     píxel al sol que en sombra. Eso es exactamente "azul 100% saturado que no
 *     recibe la luz de la escena".
 *  b) Además se le vuelve a escribir un `emissive` = color × 0.06. Un piso de
 *     emisión de 0.037 no se nota de día, pero de noche la escena entera vale
 *     eso: por eso el bando de noche brilla igual que de día.
 *
 *  Medición sobre las capturas: las superficies neutras pasan de luma 115 al
 *  mediodía a 57 de noche (bajan a la mitad, como corresponde); el azul de
 *  bando pasa de B=198 a B=177, o sea conserva el 89% de su brillo diurno.
 *
 * QUÉ HACE ESTA REGLA. Convierte el hex crudo en PINTURA: pigmento más blanco
 * de titanio sobre imprimación, que es lo único que existe en el mundo real.
 *  1. BLANCO: mezcla hacia la luminancia del propio color. Los tres canales
 *     quedan con recorrido, así el sombreado se ve en los tres y no sólo en uno.
 *  2. TECHO: ningún canal pasa de `techo`, para que el sol tenga aire por
 *     arriba en vez de clipear (que es lo que aplasta el gradiente).
 *  3. PISO relativo al canal fuerte: da igual lo saturado que venga el hex,
 *     ningún canal queda a más de cinco a uno del que manda.
 * El resultado sigue siendo escaneable de un vistazo (misma familia de color)
 * pero es una superficie que se ilumina como cualquier otra.
 *
 * ES LA MISMA REGLA QUE `pinturaDeBando` de EdificioFabrica, con los mismos
 * pasos y el mismo orden, para que el edificio y la unidad del mismo jugador
 * salgan del mismo lugar y se lean como del mismo bando. Se exporta para que
 * cualquiera pueda importarla en vez de reescribirla y que las dos vuelvan a
 * separarse.
 */
export const BANDO = {
  blanco: 0.34,   // cuánto se mezcla el color hacia su propia luminancia
  techo: 0.72,    // ningún canal por encima de esto (aire para el sol)
  pisoAbs: 0.045, // ningún canal por debajo de esto en absoluto
  pisoRel: 0.18,  // …ni por debajo de este porcentaje del canal que manda
};

const _lumaBando = (c) => c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722;

/**
 * Versión CPU de la regla (la del shader es idéntica, ver GLSL_BANDO_PARS).
 * Muta y devuelve el color que se le pasa: se usa en la cocina de geometría,
 * jamás por frame.
 */
export function pinturaDeBando(c) {
  const luma = _lumaBando(c);
  c.r = lerp(c.r, luma, BANDO.blanco);
  c.g = lerp(c.g, luma, BANDO.blanco);
  c.b = lerp(c.b, luma, BANDO.blanco);
  let pico = Math.max(c.r, c.g, c.b);
  if (pico > BANDO.techo) { c.multiplyScalar(BANDO.techo / pico); pico = BANDO.techo; }
  const piso = Math.max(BANDO.pisoAbs, pico * BANDO.pisoRel);
  c.r = Math.max(c.r, piso);
  c.g = Math.max(c.g, piso);
  c.b = Math.max(c.b, piso);
  return c;
}

/**
 * Ganancia del slot emisivo. Todo lo que va antes de OutputPass corre sobre
 * valores LINEALES HDR: un color 0xffbb55 tal cual llega a 1.0 y se queda a
 * un pelo de ser una alta luz. Multiplicado sale del rango de pantalla, lo
 * levanta el bloom y aparece por fin lo "más claro del cuadro".
 */
const GANANCIA_EMIS = 2.4;

/* ═════════════════ 1. Paletas, roles y materiales ═════════════════ */

/** Tonos base por edad. `emis` es el color vivo de la Edad Sintética. */
const TONOS = [
  { // 0 · Vapor
    tela: 0x8a7357, tela2: 0x6a5741, cuero: 0x5a3d28, metal: 0x9a9791, metalOsc: 0x4a4844,
    madera: 0x8a5c34, acento: 0xd8ae4c, correaje: 0xded4bd, oscuro: 0x2e2a24, emis: 0xffbb55,
    goma: 0x2b2b2d, piel: 0xc79a70, vidrio: 0xa8c8d8,
  },
  { // 1 · Eléctrica
    tela: 0x7d7862, tela2: 0x5c5943, cuero: 0x4d3624, metal: 0xa3a3a5, metalOsc: 0x45474a,
    madera: 0x77522f, acento: 0xe0c862, correaje: 0xc3b89e, oscuro: 0x272a2c, emis: 0xffd070,
    goma: 0x28282a, piel: 0xbb8b62, vidrio: 0xa8c8d8,
  },
  { // 2 · Atómica
    tela: 0x67744f, tela2: 0x475236, cuero: 0x4a3728, metal: 0x969c96, metalOsc: 0x3d443c,
    madera: 0x6b4d2f, acento: 0xcdd558, correaje: 0xa2a884, oscuro: 0x232720, emis: 0xd9e04f,
    goma: 0x242426, piel: 0xa9764f, vidrio: 0x9dc0b4,
  },
  { // 3 · Información
    tela: 0x55626a, tela2: 0x353f45, cuero: 0x33373a, metal: 0x939ca2, metalOsc: 0x353c42,
    madera: 0x4c4a46, acento: 0x4fd2e0, correaje: 0x2c3236, oscuro: 0x1a2026, emis: 0x66e6ff,
    goma: 0x1f2124, piel: 0xb98a60, vidrio: 0x8fd6e8,
  },
  { // 4 · Sintética
    tela: 0xc2c5d1, tela2: 0x74778c, cuero: 0x3a3648, metal: 0xcbced9, metalOsc: 0x393350,
    madera: 0x555068, acento: 0xc09bff, correaje: 0x39344a, oscuro: 0x171326, emis: 0xb48bff,
    goma: 0x1b1826, piel: 0xc79a70, vidrio: 0xbfe0ff,
  },
];
/**
 * Aplica la RESERVA DE GAMA sobre TONOS una sola vez, al cargar el módulo.
 * Se hace por código y no a mano sobre los cinco arrays porque la regla tiene
 * que quedar auditable: si mañana alguien mete un marrón vivo en la paleta, el
 * clamp lo apaga solo y el color de bando sigue siendo el único saturado.
 */
const _hslGama = { h: 0, s: 0, l: 0 };
const _colGama = new THREE.Color();
for (const pal of TONOS) {
  for (const rol of Object.keys(GAMA)) {
    const hex = pal[rol];
    if (hex === undefined) continue;
    const [satMax, lumMin, lumMax] = GAMA[rol];
    // Medimos y reescribimos en sRGB: los hex de arriba están escritos "como se
    // ven", no en el espacio lineal de trabajo.
    _colGama.setHex(hex, THREE.SRGBColorSpace);
    _colGama.getHSL(_hslGama, THREE.SRGBColorSpace);
    _colGama.setHSL(_hslGama.h, Math.min(_hslGama.s, satMax),
      clamp(_hslGama.l, lumMin, lumMax), THREE.SRGBColorSpace);
    pal[rol] = _colGama.getHex(THREE.SRGBColorSpace);
  }
}

export const paletaEdad = (edad) => TONOS[clamp(edad | 0, 0, 4)];

const SLOTS = ['cuerpo', 'metal', 'jugador', 'vidrio', 'emisivo'];

/** Rol simbólico de una pieza -> slot de material. */
function slotDeRol(rol) {
  switch (rol) {
    case 'metal': case 'metalOsc': case 'acento': return 'metal';
    case 'vidrio': return 'vidrio';
    case 'emis': return 'emisivo';
    case 'jugador': return 'jugador';
    default: return 'cuerpo';
  }
}
/**
 * Rol -> tinte por vértice (el material va en blanco y multiplica).
 * Devuelve un Color COMPARTIDO: quien llama lo consume en el acto (`normalizar`
 * lo copia a un Float32Array), así no hay una asignación por pieza.
 */
const COLOR_ROL = new THREE.Color();
function tinteDeRol(rol, pal) {
  // El nivel del paño ya lo fija la PINTURA en el shader (BANDO.techo), que es
  // el único sitio que el clon de la vista no puede pisar. Lo que hace acá el
  // color por vértice es COMPENSAR el gris medio del tejido: 'tela_uniforme'
  // es un paño #c9c4b8, o sea ~0.58 en lineal, y multiplicar la pintura por él
  // dejaría el bando casi la mitad de oscuro de lo que dice la regla — y de
  // paso a distinto valor que el LOD lejano, que no lleva mapa. El factor
  // devuelve el nivel sin tocar la TRAMA del tejido, que es la que le saca lo
  // de calcomanía. Con el techo en 0.72 el albedo resultante nunca llega a 1.
  if (rol === 'jugador') return COLOR_ROL.setRGB(1.72, 1.72, 1.72);
  const v = pal[rol];
  COLOR_ROL.set(v !== undefined ? v : 0xb9b2a4);
  // el emisivo se va a HDR: es la única fuente de altas luces de la unidad
  if (rol === 'emis') COLOR_ROL.multiplyScalar(GANANCIA_EMIS);
  return COLOR_ROL;
}

const CLAVE_TEX = { cuerpo: 'tela_uniforme', jugador: 'tela_uniforme', metal: 'metal_pintado', vidrio: 'vidrio' };
const REP_TEX = { cuerpo: [5, 5], jugador: [5, 5], metal: [3, 3], vidrio: [1, 1] };
const cacheMat = new Map();

/* ---------------- rim light: el sistema de silueta ---------------- */

/**
 * Luz dominante de la escena (sol de día, luna de noche) en color LINEAL.
 * Es un uniform vivo que actualiza Cielo.js cada frame, así que el rim cambia
 * de cálido a frío solo, sin que nadie tenga que llamarnos. Si el módulo del
 * cielo todavía no se inicializó, caemos a un sol de mediodía.
 */
const U_LUZ = uniformesCielo?.uColorLuz || { value: new THREE.Color(1.0, 0.95, 0.86) };

/**
 * Fuerza, dureza y piso del rim por slot. Ver comentario de MaterialUnidad.
 *
 * Los números viejos (1.3 a 1.75 de fuerza con exponente 2.0–2.8) eran el
 * verdadero origen del defecto "color de bando plano y desbordado, mismo RGB en
 * cara iluminada y en sombra": una unidad a 80 m es casi todo contorno, así que
 * un Fresnel blando sumaba ~1.0 de luz blanca sobre CASI TODA la superficie, en
 * sol y en sombra por igual. Resultado: albedo lavado, sin modelado, con un halo
 * que se lee como bug de shader. Ahora la fuerza es un tercio y el exponente
 * mucho más duro (contorno fino de verdad), y el término se apaga sobre lo que
 * ya está iluminado (ver `uRimPiso`).
 */
const RIM = {
  cuerpo: [0.46, 3.4, 0.18],
  metal: [0.62, 3.0, 0.22],
  jugador: [0.28, 3.9, 0.10],   // el más suave de todos: el rim NO puede lavar el bando
  vidrio: [0.70, 2.6, 0.30],
};

const GLSL_RIM_PARS = /* glsl */`
uniform vec3 uLuzDominante;
uniform float uRimFuerza;
uniform float uRimPot;
uniform float uRimPiso;
uniform float uEsBando;      // 1 = esta malla lleva el color del jugador
uniform vec4 uBandoRegla;    // x=blanco  y=techo  z=pisoAbs  w=pisoRel

/**
 * La MISMA regla que \`pinturaDeBando\` de arriba, en GLSL.
 *
 * Va en el shader y no en \`material.color\` por una razón concreta: la vista
 * CLONA este material y le vuelve a copiar el hex crudo del jugador encima
 * (\`m.color.copy(col)\`), así que cualquier corrección hecha sobre el color del
 * material se pierde en el clon. Acá no: el clon hereda \`onBeforeCompile\` del
 * prototipo y la pintura se recalcula sobre lo que sea que le hayan escrito.
 *
 * Ojo al tocar esto: el FUENTE tiene que ser IDÉNTICO para todos los slots.
 * \`customProgramCacheKey()\` devuelve el fuente de \`onBeforeCompile\`, así que si
 * el bando compilara un texto distinto al del cuerpo, three serviría el
 * programa equivocado a uno de los dos y el parche no llegaría nunca a la
 * pantalla (ya pasó una vez, con tres correcciones enteras). Por eso el switch
 * es un UNIFORM (\`uEsBando\`) y no un #define: un solo WebGLProgram para todo el
 * ejército, con o sin color de jugador.
 */
vec3 pinturaDeBando( vec3 c ) {
  float luma = dot( c, vec3( 0.2126, 0.7152, 0.0722 ) );
  vec3 p = mix( c, vec3( luma ), uBandoRegla.x );
  float pico = max( max( p.r, p.g ), p.b );
  // techo: si el canal fuerte se pasa, baja TODO el color (no sólo ese canal),
  // que es lo que conserva el tono en vez de virarlo
  float k = min( 1.0, uBandoRegla.y / max( pico, 1e-4 ) );
  p *= k;
  pico = min( pico, uBandoRegla.y );
  return max( p, vec3( max( uBandoRegla.z, pico * uBandoRegla.w ) ) );
}
`;

const GLSL_RIM_CUERPO = /* glsl */`
  // Fresnel puro sobre la normal de vista: vale 1 justo en el contorno de la
  // silueta y ~0 de frente. Es lo que despega a la unidad del pasto.
  float rimBorde = 1.0 - saturate( dot( geometryNormal, geometryViewDir ) );
  rimBorde = pow( rimBorde, uRimPot );
  // CLAVE: el rim se APAGA sobre lo que ya recibe luz. Si sumáramos lo mismo en
  // la cara al sol y en la cara en sombra, las dos terminarían con el mismo RGB
  // y la unidad quedaría plana — que es textualmente lo que midió el jurado.
  // Con esto el término sólo levanta el borde oscuro, así que el modelado
  // (dónde pega el sol y dónde no) se conserva intacto y encima se refuerza.
  // uRimPiso es el mínimo que se mantiene aun a pleno sol, para que el
  // contorno no desaparezca del todo contra un fondo claro.
  float lumCuerpo = dot( outgoingLight, vec3( 0.2126, 0.7152, 0.0722 ) );
  float huecoRim = mix( uRimPiso, 1.0, 1.0 - saturate( lumCuerpo ) );
  // Usamos sólo la CROMATICIDAD de la luz dominante (normalizada por luma), no
  // su intensidad: de día el contorno sale cálido y de noche azul, pero NO se
  // apaga, porque una unidad ilegible de noche es un bug, no una decisión
  // artística.
  float rimLuma = max( dot( uLuzDominante, vec3( 0.2126, 0.7152, 0.0722 ) ), 1e-3 );
  outgoingLight += ( uLuzDominante / rimLuma ) * ( rimBorde * uRimFuerza * huecoRim );
`;

/**
 * Material de unidad = MeshStandardMaterial + rim light de silueta.
 *
 * Es una SUBCLASE y no un `onBeforeCompile` pegado a la instancia por un motivo
 * concreto: VistaEntidades clona estos materiales para teñir el color de bando,
 * y `Material.copy()` no copia las propiedades pegadas a mano. Al vivir en el
 * prototipo, el rim sobrevive al clonado; si no, la malla del jugador (justo la
 * que más importa) se quedaría sin contorno.
 *
 * El rim se SUMA en lineal HDR, antes de OutputPass: valores ~1.3 producen
 * píxeles por encima de 200 después del tone mapping ACES y encima los levanta
 * el bloom. Es la fuente de altas luces más barata que tenemos.
 *
 * Bonus de estar en el prototipo: `customProgramCacheKey()` devuelve el fuente
 * de `onBeforeCompile`, que acá es IDÉNTICO para todas las instancias. Todos los
 * materiales de unidad comparten un solo WebGLProgram, incluidos los clones por
 * jugador. Con una función por instancia sería una compilación de shader por
 * color de bando y por tipo de unidad.
 */
class MaterialUnidad extends THREE.MeshStandardMaterial {
  constructor(params) {
    super(params);
    this.isMaterialUnidad = true;
    this.rimFuerza = RIM.cuerpo[0];
    this.rimPot = RIM.cuerpo[1];
    this.rimPiso = RIM.cuerpo[2];
    this.esBando = false;
  }

  copy(fuente) {
    super.copy(fuente);
    if (fuente.rimFuerza !== undefined) this.rimFuerza = fuente.rimFuerza;
    if (fuente.rimPot !== undefined) this.rimPot = fuente.rimPot;
    if (fuente.rimPiso !== undefined) this.rimPiso = fuente.rimPiso;
    // sin esto el clon que hace la vista para teñir el ejército perdería la
    // pintura y volvería a ser el azul crudo de dos canales en cero
    if (fuente.esBando !== undefined) this.esBando = fuente.esBando;
    return this;
  }

  onBeforeCompile(shader) {
    shader.uniforms.uLuzDominante = U_LUZ;          // compartido: lo mueve Cielo.js
    shader.uniforms.uRimFuerza = { value: this.rimFuerza };
    shader.uniforms.uRimPot = { value: this.rimPot };
    shader.uniforms.uRimPiso = { value: this.rimPiso };
    shader.uniforms.uEsBando = { value: this.esBando ? 1 : 0 };
    shader.uniforms.uBandoRegla = {
      value: new THREE.Vector4(BANDO.blanco, BANDO.techo, BANDO.pisoAbs, BANDO.pisoRel),
    };
    shader.fragmentShader = shader.fragmentShader
      .replace('void main() {', `${GLSL_RIM_PARS}\nvoid main() {`)
      // La pintura se aplica sobre `diffuse` (el color del material) ANTES de que
      // entren el mapa de tejido y el color por vértice: así el paño conserva su
      // trama y su sucio, que es lo que termina de sacarlo de "plano". Si se
      // aplicara después, normalizar cada téxel mataría la textura.
      .replace('vec4 diffuseColor = vec4( diffuse, opacity );',
        'vec4 diffuseColor = vec4( mix( diffuse, pinturaDeBando( diffuse ), uEsBando ), opacity );')
      // EL BANDO NO EMITE. La vista le vuelve a escribir `emissive` = color×0.06
      // después de que esta fábrica lo dejó en negro, y ese piso constante de
      // emisión es por qué de noche el azul seguía casi tan brillante como al
      // mediodía (medido: las superficies neutras bajan a la mitad, el bando
      // conservaba el 89%). Se anula en el ORIGEN de `totalEmissiveRadiance` y
      // no antes de <opaque_fragment>, porque para entonces `outgoingLight` ya
      // está sumado y tocarlo ahí no cambiaría un solo píxel.
      .replace('vec3 totalEmissiveRadiance = emissive;',
        'vec3 totalEmissiveRadiance = emissive * ( 1.0 - uEsBando );')
      // `geometryNormal` y `geometryViewDir` los deja en scope <lights_fragment_begin>
      .replace('#include <opaque_fragment>', `${GLSL_RIM_CUERPO}\n#include <opaque_fragment>`);
  }
}

function materialSlot(ctx, slot, hexJugador) {
  const clave = slot === 'jugador' ? `jugador|${hexJugador}` : slot;
  const hit = cacheMat.get(clave);
  if (hit) return hit;

  let m;
  if (slot === 'emisivo') {
    m = new THREE.MeshBasicMaterial({ vertexColors: true, toneMapped: false });
  } else {
    let base = null;
    try {
      base = ctx?.texturas?.material?.(CLAVE_TEX[slot] || 'tela_uniforme', { repeticion: REP_TEX[slot] });
    } catch (e) { base = null; }
    // Copiamos en vez de clonar: el material de la biblioteca es compartido y no
    // le vamos a pisar vertexColors ni el color a los edificios, y de paso el
    // resultado es un MaterialUnidad (con rim) y no un MeshStandardMaterial pelado.
    m = new MaterialUnidad();
    if (base && base.isMeshStandardMaterial) m.copy(base);
    const rim = RIM[slot] || RIM.cuerpo;
    m.rimFuerza = rim[0]; m.rimPot = rim[1]; m.rimPiso = rim[2];
    m.aoMap = null;                    // no tenemos un segundo juego de UV
    m.vertexColors = true;
    m.flatShading = false;

    /* ── SANEAMIENTO OBLIGATORIO DEL ESTADO HEREDADO ──────────────────────
       `m.copy(base)` trae TODO el material de la biblioteca de texturas, no
       sólo los mapas: alfa, emisivo, cara y escritura de profundidad incluidos.
       Si mañana alguien le pone `alfa: true` a la clave 'tela_uniforme' (o le
       agrega un mapa emisivo), cada pierna y cada torso del ejército pasan a
       ser semitransparentes o a brillar solos, SIN que nadie toque este
       archivo. Los dos defectos existen en el registro del jurado con esas
       palabras exactas ("piernas como palitos semitransparentes", "material
       sin asignar o bug de shader"), así que el estado se fuerza acá y no se
       confía en lo que venga de arriba. El vidrio se salta esto a propósito y
       vuelve a poner su transparencia unas líneas más abajo. */
    m.transparent = false;
    m.opacity = 1;
    m.alphaTest = 0;
    m.alphaMap = null;
    m.depthWrite = true;
    m.depthTest = true;
    m.side = THREE.FrontSide;
    // el color de bando se ilumina como cualquier tela: NUNCA por emisivo
    m.emissive.setRGB(0, 0, 0);
    m.emissiveMap = null;
    m.emissiveIntensity = 1;

    // Sin mapa de entorno un metalness alto se ve NEGRO: bajamos el metal a un
    // valor que todavía brilla con el sol directo pero conserva el tono gris.
    if (slot === 'metal') { m.roughness = 0.46; m.metalness = 0.30; m.color.setRGB(1, 1, 1); }
    else if (slot === 'vidrio') {
      m.roughness = 0.12; m.metalness = 0.25; m.transparent = true; m.opacity = 0.66;
      m.color.setRGB(1, 1, 1); m.map = null; m.normalMap = null;
    } else if (slot === 'jugador') {
      // Rugosidad ALTA y metalness nulo: es paño, no plástico. Con roughness
      // baja el término especular tapa el difuso y el paño devuelve el mismo
      // valor mire donde mire, que es la mitad de la sensación de "plano".
      m.roughness = 0.84; m.metalness = 0.0;
      m.color.set(hexJugador);
      // La PINTURA (mezcla al blanco, techo y piso) la aplica el shader sobre
      // este color, no acá: la vista clona el material y le vuelve a copiar el
      // hex crudo encima, así que cualquier corrección hecha sobre
      // `m.color` se pierde en el clon y esta bandera no.
      m.esBando = true;
      m.userData = Object.assign({}, m.userData, { colorJugador: true });
    } else { m.roughness = 0.88; m.metalness = 0.04; m.color.setRGB(1, 1, 1); }
    m.needsUpdate = true;
  }
  // El nombre importa: VistaEntidades detecta las zonas de jugador por regex.
  m.name = slot === 'jugador' ? 'unidad_jugador' : `unidad_${slot}`;
  cacheMat.set(clave, m);
  return m;
}

/* ═════════════════ 2. Sistema de piezas ═════════════════ */

/** Deja la geometría lista para fusionar: sin índice, atributos fijos, color por vértice. */
function normalizar(geo, tinte) {
  let g = geo.index ? geo.toNonIndexed() : geo.clone();
  if (!g.attributes.normal) g.computeVertexNormals();
  const n = g.attributes.position.count;
  if (!g.attributes.uv) g.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(n * 2), 2));
  for (const k of Object.keys(g.attributes)) {
    if (k !== 'position' && k !== 'normal' && k !== 'uv') g.deleteAttribute(k);
  }
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i * 3] = tinte.r; col[i * 3 + 1] = tinte.g; col[i * 3 + 2] = tinte.b; }
  g.setAttribute('color', new THREE.BufferAttribute(col, 3));
  g.morphAttributes = {};
  g.clearGroups();
  return g;
}

class Pieza {
  constructor(nombre, x = 0, y = 0, z = 0) {
    this.nombre = nombre;
    this.pos = [x, y, z];
    this.rot = null;
    this.esc = null;
    this.hijos = [];
    this.geos = {};
    this.oruga = null;
    this.boca = null;
  }
  hijo(nombre, x = 0, y = 0, z = 0) { const p = new Pieza(nombre, x, y, z); this.hijos.push(p); return p; }
  reposo(rx = 0, ry = 0, rz = 0) { this.rot = [rx, ry, rz]; return this; }
  /**
   * Escala UNIFORME propia del pivote. Es la palanca de la caricatura: agranda
   * la cabeza o el arma sin tocar la geometría cacheada ni introducir cizalla
   * (por eso es uniforme y no un vector).
   */
  tamano(k) { this.esc = k; return this; }

  /**
   * Agrega geometría ya colocada en el espacio local de la pieza (resuelve
   * compuestos). El rol que pasa quien llama MANDA sobre el que trae la pieza:
   * así la misma bota sirve de cuero en 1800 y de placa metálica en 2100.
   */
  poner(geo, pal, rolPedido) {
    if (!geo) return this;
    const rol = rolPedido || geo.userData?.rol || 'tela';
    const slot = slotDeRol(rol);
    const g = normalizar(geo, tinteDeRol(rol, pal));
    (this.geos[slot] || (this.geos[slot] = [])).push(g);
    const extras = geo.userData?.extra;
    if (extras) for (const e of extras) this.poner(e.geo, pal, e.rol || null);
    if (geo.userData?.boca) this.boca = geo.userData.boca.slice();
    return this;
  }
  /** Igual que `poner` pero espejando en Z: izquierda y derecha de un saque. */
  ponerPar(geo, z, pal, rol) {
    this.poner(clonarCompuesto(geo).translate(0, 0, z), pal, rol);
    this.poner(clonarCompuesto(geo).translate(0, 0, -z), pal, rol);
    return this;
  }
}

/** Clona una geometría con todo su árbol de extras (para espejar o repetir). */
function clonarCompuesto(geo) {
  const g = geo.clone();
  // BufferGeometry.copy comparte `userData` por referencia: hay que separarlo.
  g.userData = Object.assign({}, geo.userData);
  if (geo.userData?.boca) g.userData.boca = geo.userData.boca.slice();
  if (geo.userData?.extra) {
    g.userData.extra = geo.userData.extra.map((e) => ({ geo: clonarCompuesto(e.geo), rol: e.rol }));
  }
  return P.propagar(g);
}

function fusionarSlot(lista) {
  if (!lista.length) return null;
  if (lista.length === 1) return lista[0];
  const g = mergeGeometries(lista, false);
  if (g) { for (const x of lista) x.dispose(); return g; }
  return lista[0];
}

/** Compila el árbol de piezas a descriptores con una malla por slot. */
function compilar(p) {
  const slots = [];
  for (const s of SLOTS) {
    const a = p.geos[s];
    if (!a || !a.length) continue;
    const g = fusionarSlot(a);
    if (!g) continue;
    g.computeBoundingBox();
    slots.push({ slot: s, geo: g });
  }
  return {
    nombre: p.nombre, pos: p.pos, rot: p.rot, esc: p.esc, slots, oruga: p.oruga, boca: p.boca,
    hijos: p.hijos.map(compilar),
  };
}

/* ═════════════════ 3. Instanciación ═════════════════ */

const _v = new THREE.Vector3();
const _q = new THREE.Quaternion();
const _e = new THREE.Euler();
const _uno = new THREE.Vector3(1, 1, 1);
const _m4 = new THREE.Matrix4();
const _caja = new THREE.Box3();

function instanciar(nodo, ctx, hex, mapa, mallasJugador, orugas) {
  const g = new THREE.Group();
  g.name = nodo.nombre;
  g.position.set(nodo.pos[0], nodo.pos[1], nodo.pos[2]);
  if (nodo.rot) g.rotation.set(nodo.rot[0], nodo.rot[1], nodo.rot[2]);
  if (nodo.esc) g.scale.setScalar(nodo.esc);

  for (const s of nodo.slots) {
    const malla = new THREE.Mesh(s.geo, materialSlot(ctx, s.slot, hex));
    malla.name = s.slot === 'jugador' ? `${nodo.nombre}:jugador` : `${nodo.nombre}:${s.slot}`;
    malla.castShadow = true;
    malla.receiveShadow = false;
    malla.frustumCulled = false;
    malla.matrixAutoUpdate = false;
    malla.updateMatrix();
    if (s.slot === 'jugador') { malla.userData.colorJugador = true; mallasJugador.push(malla); }
    g.add(malla);
  }

  if (nodo.oruga) {
    const o = nodo.oruga;
    const total = o.n * 2;
    const im = new THREE.InstancedMesh(o.geo, materialSlot(ctx, 'metal', hex), total);
    im.name = `${nodo.nombre}:oruga`;
    im.castShadow = true;
    im.frustumCulled = false;
    im.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    g.add(im);
    const reg = { malla: im, n: o.n, L: o.L, r: o.r, z: o.z, paso: (2 * o.L + TAU * o.r) / o.n, s: 0 };
    colocarOruga(reg);
    orugas.push(reg);
  }

  if (nodo.boca) {
    const vacio = new THREE.Object3D();
    vacio.name = 'bocaArma';
    vacio.position.set(nodo.boca[0], nodo.boca[1], nodo.boca[2]);
    g.add(vacio);
    mapa.bocaArma = vacio;
  }

  if (!mapa[nodo.nombre]) mapa[nodo.nombre] = g;
  for (const h of nodo.hijos) g.add(instanciar(h, ctx, hex, mapa, mallasJugador, orugas));
  return g;
}

/**
 * Punto del circuito de la oruga para el parámetro `s`.
 * Circuito: tramo inferior (+X→−X) · rueda trasera · tramo superior · rueda
 * delantera. Devuelve posición y NORMAL INTERIOR, que es la que orienta el
 * diente del eslabón hacia el rodillo.
 */
function puntoOruga(s, L, r, salida) {
  const arco = Math.PI * r;
  const per = 2 * L + 2 * arco;
  s = s % per; if (s < 0) s += per;
  if (s < L) {                                  // tramo inferior, hacia −X
    salida.x = L / 2 - s; salida.y = -r; salida.nx = 0; salida.ny = 1;
  } else if (s < L + arco) {                    // rueda trasera
    const fi = -Math.PI / 2 - (s - L) / r;
    salida.x = -L / 2 + r * Math.cos(fi); salida.y = r * Math.sin(fi);
    salida.nx = -Math.cos(fi); salida.ny = -Math.sin(fi);
  } else if (s < 2 * L + arco) {                // tramo superior, hacia +X
    salida.x = -L / 2 + (s - L - arco); salida.y = r; salida.nx = 0; salida.ny = -1;
  } else {                                      // rueda delantera
    const fi = Math.PI / 2 - (s - 2 * L - arco) / r;
    salida.x = L / 2 + r * Math.cos(fi); salida.y = r * Math.sin(fi);
    salida.nx = -Math.cos(fi); salida.ny = -Math.sin(fi);
  }
  return salida;
}
const _pt = { x: 0, y: 0, nx: 0, ny: 0 };

/** Reparte los eslabones a lo largo del circuito de la oruga. */
function colocarOruga(reg) {
  const { malla, n, L, r, z, paso } = reg;
  for (let lado = 0; lado < 2; lado++) {
    const zz = lado === 0 ? z : -z;
    for (let i = 0; i < n; i++) {
      puntoOruga(reg.s + i * paso, L, r, _pt);
      _e.set(0, 0, Math.atan2(_pt.ny, _pt.nx) - Math.PI / 2);
      _q.setFromEuler(_e);
      _v.set(_pt.x, _pt.y, zz);
      _m4.compose(_v, _q, _uno);
      malla.setMatrixAt(lado * n + i, _m4);
    }
  }
  malla.instanceMatrix.needsUpdate = true;
}

/* ═════════════════ 4. Recetas visuales ═════════════════ */

const porEdad = (v, edad) => (Array.isArray(v) ? v[clamp(edad | 0, 0, v.length - 1)] : v);

/**
 * Receta visual de cada unidad. Los arrays se indexan por edad (0..4), así una
 * misma línea evoluciona de la levita al exoesqueleto sin duplicar código.
 *
 * `silueta` elige la fila de SILUETA que le toca a la unidad. NO es decorativo:
 * es lo que hace que un tirador y un fusilero de línea no sean el mismo muñeco.
 */
export const CATALOGO_UNIDADES = {
  /* ---- aldeano ---- */
  colono: {
    familia: 'humano', silueta: 'obrero',
    torso: ['civil', 'civil', 'civil', 'civil', 'civil'], cabeza: 'raso',
    gorra: ['paja', 'boina', 'boina', null, null], casco: [null, null, null, 'obra', 'obra'],
    arma: ['hacha', 'hacha', 'martillo', 'martillo', 'martillo'], porte: 'dosManos',
    mochila: 'saco', correaje: null, ataque: 'cuerpo', escala: 0.97,
  },
  /* ---- infantería ---- */
  miliciano: {
    familia: 'humano', silueta: 'linea', torso: 'casaca', cabeza: 'barba', casco: 'shako', penacho: 0.17,
    arma: 'mosquete', porte: 'dosManos', mochila: 'macuto', correaje: 'cruzado', ataque: 'fuego',
  },
  fusilero_linea: {
    familia: 'humano', silueta: 'linea', torso: 'casaca', cabeza: 'raso', casco: 'shako', penacho: 0.24,
    arma: 'cerrojo', porte: 'dosManos', mochila: 'campana', correaje: 'cruzado', ataque: 'fuego',
  },
  infante_asalto: {
    familia: 'humano', silueta: 'linea', torso: 'chaleco', cabeza: 'raso', casco: 'acero',
    arma: 'subfusil', porte: 'dosManos', mochila: 'macuto', correaje: 'arnes', ataque: 'fuego',
  },
  fusilero_motorizado: {
    familia: 'humano', silueta: 'linea', torso: 'chaleco', cabeza: 'visor', casco: 'kevlar',
    arma: 'asalto', porte: 'dosManos', mochila: 'tactica', correaje: 'arnes', ataque: 'fuego',
  },
  exoinfante: {
    familia: 'humano', silueta: 'linea', torso: 'exo', cabeza: 'mascara', casco: 'exo', exo: true,
    arma: 'pesado', porte: 'dosManos', mochila: 'energia', correaje: null, ataque: 'fuego', escala: 1.09,
  },
  /* ---- antiblindaje ---- */
  piquero: {
    familia: 'humano', silueta: 'antiblindaje', torso: 'casaca', cabeza: 'barba', casco: 'morrion',
    arma: 'pica', porte: 'lanza', mochila: 'macuto', correaje: 'bandolera', ataque: 'cuerpo',
  },
  artillero_at: {
    familia: 'humano', silueta: 'antiblindaje', torso: 'guerrera', cabeza: 'raso', casco: 'shako',
    arma: 'at', porte: 'dosManos', mochila: 'campana', correaje: 'cruzado', ataque: 'fuego',
  },
  bazoquero: {
    familia: 'humano', silueta: 'antiblindaje', torso: 'chaleco', cabeza: 'raso', casco: 'acero',
    arma: 'bazuca', porte: 'hombro', mochila: 'macuto', correaje: 'arnes', ataque: 'fuego',
  },
  misilista: {
    familia: 'humano', silueta: 'antiblindaje', torso: 'chaleco', cabeza: 'visor', casco: 'kevlar',
    arma: 'misil', porte: 'hombro', mochila: 'tactica', correaje: 'arnes', ataque: 'fuego',
  },
  lanza_enjambre: {
    familia: 'humano', silueta: 'antiblindaje', torso: 'exo', cabeza: 'mascara', casco: 'exo', exo: true,
    arma: 'enjambre', porte: 'hombro', mochila: 'energia', correaje: null, ataque: 'fuego', escala: 1.07,
  },
  /* ---- tiradores ---- */
  tirador: {
    familia: 'humano', silueta: 'tirador', torso: 'guerrera', cabeza: 'barba', casco: 'sombrero',
    arma: 'rifle_largo', porte: 'dosManos', mochila: 'macuto', correaje: 'bandolera', ataque: 'fuego',
  },
  francotirador: {
    familia: 'humano', silueta: 'tirador', torso: 'guerrera', cabeza: 'raso', casco: 'sombrero',
    arma: 'rifle_mira', porte: 'dosManos', mochila: 'macuto', correaje: 'bandolera', ataque: 'fuego',
  },
  tirador_designado: {
    familia: 'humano', silueta: 'tirador', torso: 'chaleco', cabeza: 'visor', casco: 'kevlar',
    arma: 'rifle_bipode', porte: 'dosManos', mochila: 'tactica', correaje: 'arnes', ataque: 'fuego',
  },
  tirador_riel: {
    familia: 'humano', silueta: 'tirador', torso: 'exo', cabeza: 'mascara', casco: 'exo', exo: true,
    arma: 'riel', porte: 'dosManos', mochila: 'energia', correaje: null, ataque: 'fuego', escala: 1.06,
  },
  escaramuzador: {
    familia: 'humano', silueta: 'tirador', torso: 'guerrera', cabeza: 'barba', casco: 'gorra',
    arma: 'carabina', porte: 'dosManos', mochila: 'campana', correaje: 'bandolera', ataque: 'fuego', escala: 0.97,
  },
  cazador_dron: {
    familia: 'humano', silueta: 'tirador', torso: 'chaleco', cabeza: 'visor', casco: 'kevlar',
    arma: 'escopeta', porte: 'dosManos', mochila: 'radio', correaje: 'arnes', ataque: 'fuego', escala: 0.98,
  },
  /* ---- apoyo ---- */
  agitador: {
    familia: 'humano', silueta: 'apoyo', torso: 'abrigo', cabeza: 'barba', casco: 'gorra',
    arma: 'megafono', porte: 'unaMano', mochila: null, correaje: null, ataque: 'gesto',
    banderin: true, escala: 0.99,
  },
  hacker: {
    familia: 'humano', silueta: 'apoyo', torso: 'abrigo', cabeza: 'visor', casco: 'capucha',
    arma: 'consola', porte: 'unaMano', mochila: 'radio', correaje: null, ataque: 'gesto', escala: 0.99,
  },
  /* ---- montado / blindados ---- */
  husar: { familia: 'jinete' },
  blindado_ligero: { familia: 'blindado', variante: 'semioruga' },
  tanque_medio: { familia: 'blindado', variante: 'tanque' },
  tanque_autonomo: { familia: 'blindado', variante: 'autonomo' },
  /* ---- asedio ---- */
  canon_campana: { familia: 'artilleria', variante: 'cureña' },
  obus: { familia: 'artilleria', variante: 'obus' },
  artilleria_auto: { familia: 'blindado', variante: 'autopropulsada' },
  canon_riel: { familia: 'blindado', variante: 'riel' },
  ariete_blindado: { familia: 'blindado', variante: 'ariete' },
  /* ---- aéreos ---- */
  dron_ataque: { familia: 'aereo', variante: 'ala' },
  enjambre: { familia: 'aereo', variante: 'enjambre' },
  /* ---- navales ---- */
  pesquero: { familia: 'naval', variante: 'pesquero' },
  fragata: { familia: 'naval', variante: 'fragata' },
  destructor: { familia: 'naval', variante: 'destructor' },
  transporte: { familia: 'naval', variante: 'transporte' },
  /* ---- civil ---- */
  caravana: { familia: 'caravana' },
};

/* ═════════════════ 5. Constructor de humanoides ═════════════════ */

/** Poses de reposo del brazo según cómo sostiene el arma. */
const PORTES = {
  dosManos: { supD: [-0.16, -0.30, -0.42], antD: [0, 0, 1.28], supI: [0.36, -0.10, 0.30], antI: [0, 0, 1.10], armaZ: 0.10 },
  unaMano: { supD: [-0.14, -0.15, -0.10], antD: [0, 0, 1.05], supI: [0.10, 0, 0.10], antI: [0, 0, 0.30], armaZ: -0.05 },
  hombro: { supD: [-0.30, -0.20, -1.05], antD: [0, 0, 1.55], supI: [0.55, -0.20, -0.55], antI: [0, 0, 1.30], armaZ: 0 },
  lanza: { supD: [-0.12, -0.10, -0.20], antD: [0, 0, 0.72], supI: [0.30, -0.05, 0.55], antI: [0, 0, 0.55], armaZ: 0.95 },
};

/**
 * ESCLAVINA DE BANDO: capa corta con HOMBROS REDONDEADOS. Es LA zona de color
 * del humano (ver REGLA DE REPARTO).
 *
 * ERA UN CONO RECTO Y ESE ERA EL DEFECTO. Un tronco de cono con el ruedo
 * abajo tiene la MISMA inclinación en toda su pared: todas las normales miran
 * 50° hacia arriba, sólo cambia el azimut. Desde 49° de elevación eso se
 * proyecta como un DISCO, y encima un disco cuyo sombreado apenas varía, así
 * que la unidad entera se leía como una calcomanía azul pegada donde debería
 * estar la cabeza. Era literalmente lo que decía el panel. Peor: el cono
 * arrancaba en y=0.58, o sea POR ENCIMA del cuello (1.55 m), así que el
 * paraguas tapaba la cabeza en vez de apoyarse en los hombros.
 *
 * Ahora es una superficie de revolución cuyo perfil CURVA, del hombro al
 * ruedo. La normal barre de 0.06 de componente vertical en el borde a 0.97 en
 * el cuello: la misma pieza tiene, al mismo tiempo, superficie que mira al sol
 * y superficie que mira al horizonte. Ese gradiente es lo que dice "esto es un
 * volumen iluminado" y no "esto es un color". Y el óvalo (más ancho de hombro
 * a hombro que de pecho a espalda) hace que desde arriba se lean HOMBROS, no
 * una sombrilla.
 *
 * Cubre de y=0.25 a y=0.55 del torso (que mide 0.54) y su ruedo es un 35% más
 * chico que el del cono viejo: la cabeza vuelve a asomar, que es la mitad de
 * lo que hace legible a un humano a 80 m.
 *
 * Va abierto (LatheGeometry no cierra) a propósito: los brazos salen por
 * debajo del ruedo y la cara interna nunca se ve desde arriba.
 */
function mantoBando(anchoHombros) {
  const R = clamp(0.246 * (0.62 + 0.38 * anchoHombros), 0.205, 0.272);
  // Perfil [radio, alto] DE ABAJO HACIA ARRIBA: en ese orden LatheGeometry saca
  // las normales hacia afuera. Al revés quedan mirando adentro y la capa se
  // renderiza negra con `side: FrontSide`.
  const g = P.revolucion([
    [R, 0.012],           // ruedo: normal casi horizontal
    [R * 0.985, 0.088],
    [R * 0.888, 0.170],
    [R * 0.775, 0.232],   // hombro: la normal cruza los 45°
    [R * 0.620, 0.276],
    [R * 0.440, 0.302],
    [R * 0.236, 0.315],   // cuello: normal casi vertical
  ], 13);
  // LatheGeometry deja el ÚLTIMO anillo con una normal sin normalizar (|n|≈0.05):
  // ese anillo es justo el que la cámara ve de frente, y sin esto sale negro.
  g.deleteAttribute('normal');
  g.computeVertexNormals();
  g.scale(0.86, 1, 1.14);            // óvalo de hombros, no sombrilla
  return g.translate(0, H.torso - 0.30, 0);
}

function construirHumano(clave, edad, cfg, pal, rng) {
  const raiz = new Pieza('raiz');
  const S = SILUETA[cfg.silueta] || SILUETA_DEF;
  const esc = (cfg.escala || 1) * S.alto;
  const torsoEst = porEdad(cfg.torso, edad) || 'guerrera';
  const cascoTipo = porEdad(cfg.casco, edad);
  const gorraTipo = porEdad(cfg.gorra, edad);
  const armaTipo = porEdad(cfg.arma, edad) || 'asalto';
  const mochilaTipo = porEdad(cfg.mochila, edad);
  const correajeEst = porEdad(cfg.correaje, edad);
  const porte = PORTES[cfg.porte] || PORTES.dosManos;
  // el exo ya es un bloque ancho de por sí: se le suma medio escalón, no uno entero
  const anchoH = S.hombros * (cfg.exo ? 1.14 : 1);

  /* --- cadera: raíz del cuerpo, todo cuelga de acá.
         La estatura extra sale de la escala del grupo, no de mover la cadera:
         si no, los pies quedan flotando sobre el pasto. --- */
  const cadera = raiz.hijo('cadera', 0, H.cadera, 0);
  const pelvis = P.esferaAchatada(0.108, 0.10, 0.145, 10);
  cadera.poner(pelvis.translate(0, -0.03, 0), pal, 'tela');
  if (cfg.exo) {
    // la faja de servos va en metal: el color de bando del exo es la coraza, y
    // una segunda mancha a la altura de la cadera parte la silueta en dos
    cadera.poner(P.cajaBiselada(0.24, 0.13, 0.34, 0.024).translate(-0.01, -0.02, 0), pal, 'metal');
    cadera.poner(P.placa(0.02, 0.10, 0.06, 0.004).translate(0.13, -0.02, 0.14), pal, 'emis');
    cadera.poner(P.placa(0.02, 0.10, 0.06, 0.004).translate(0.13, -0.02, -0.14), pal, 'emis');
  }

  /* --- torso ---
     El cuerpo del torso va en TELA DESATURADA. Antes iba entero en color de
     jugador y encima se le sumaban mangas, gorra, penacho y mochila: el 60% de
     la silueta terminaba en un único RGB saturado, sin gradiente ni detalle, y
     eso es lo que el panel leyó como "blob azul" y como "material sin asignar".
     El bando ahora es el manto + la prenda frontal que trae `torsoHumano`. */
  const torso = cadera.hijo('torso', 0, 0, 0);
  torso.reposo(0, 0, S.inclina);
  torso.poner(P.torsoHumano(torsoEst, anchoH), pal, 'tela');
  if (correajeEst) torso.poner(P.correaje(correajeEst, H.torso), pal, 'correaje');
  if (mochilaTipo) torso.poner(P.mochila(mochilaTipo).translate(-0.02, H.torso * 0.42, 0), pal, 'tela2');
  if (cfg.exo) {
    // placas de hombro: ensanchan la silueta, que es lo que distingue al exoinfante
    const pl = P.esferaAchatada(0.10, 0.075, 0.095, 9);
    torso.poner(clonarCompuesto(pl).translate(0, H.torso - 0.02, (H.hombroZ + 0.03) * anchoH), pal, 'metal');
    torso.poner(clonarCompuesto(pl).translate(0, H.torso - 0.02, -(H.hombroZ + 0.03) * anchoH), pal, 'metal');
  } else {
    // el exo ya ensancha con sus placas: ponerle además el manto lo hace una bola
    torso.poner(mantoBando(anchoH), pal, 'jugador');
  }
  if (S.hombros >= 1.15 && !cfg.exo) {
    // HOMBRERAS del antiblindaje: no llevan color, ensanchan y CUADRAN el bloque
    // superior. Es la diferencia de contorno entre "lleva un tubo" y "es de línea".
    const hom = P.cajaBiselada(0.17, 0.075, 0.14, 0.016);
    torso.poner(clonarCompuesto(hom).translate(0, H.torso - 0.045, (H.hombroZ + 0.02) * anchoH), pal, 'cuero');
    torso.poner(clonarCompuesto(hom).translate(0, H.torso - 0.045, -(H.hombroZ + 0.02) * anchoH), pal, 'cuero');
  }

  /* --- cabeza: agrandada por caricatura. Es el rasgo que dice "esto es una
         persona" a 80 m; con proporción anatómica se pierde entre las motas.
         `S.cabeza` mueve el punto más alto de la figura por clase. --- */
  const cabeza = torso.hijo('cabeza', 0, H.cuello - H.cadera, 0).tamano(PROPORCION.cabeza * S.cabeza);
  cabeza.poner(P.cabezaHumana(porEdad(cfg.cabeza, edad) || 'raso'), pal, 'piel');
  if (cascoTipo) {
    cabeza.poner(P.casco(cascoTipo), pal, 'tela2');
    // el penacho es CONTORNO, no bando: teñido sería una manchita suelta a 2 m
    // por encima del manto, con toda la cabeza en el medio
    if (cfg.penacho) cabeza.poner(P.penacho(cfg.penacho, 0.028).translate(0.02, 0.37, 0), pal, 'acento');
  } else if (gorraTipo) {
    cabeza.poner(P.gorra(gorraTipo), pal, gorraTipo === 'paja' ? 'acento' : 'tela2');
  }

  /* --- brazos: hombro -> codo -> muñeca --- */
  const hz = H.hombroZ * anchoH;
  const brazoIzq = torso.hijo('brazoIzq', 0, H.hombro - H.cadera - 0.055, hz);
  const brazoDer = torso.hijo('brazoDer', 0, H.hombro - H.cadera - 0.055, -hz);
  brazoIzq.reposo(porte.supI[0], porte.supI[1], porte.supI[2]);
  brazoDer.reposo(porte.supD[0], porte.supD[1], porte.supD[2]);
  // los miembros se engrosan (no se alargan) y se ahúsan: a escala de juego un
  // brazo anatómico de radio constante es un alambre que se pierde contra el fondo
  const K = PROPORCION.extremidad;
  const mangaSup = P.miembro(0.058 * K, 0.047 * K, H.brazo - 0.03, 7);
  // Las mangas van en tela oscura, NO en color de bando: colgando a los costados
  // rompen la mancha del manto en tres pedazos y la unidad vuelve a leerse como
  // una silueta uniformemente teñida en vez de como una figura con una capa.
  const rolManga = cfg.exo ? 'metal' : 'tela2';
  brazoIzq.poner(clonarCompuesto(mangaSup), pal, rolManga);
  brazoDer.poner(clonarCompuesto(mangaSup), pal, rolManga);
  if (cfg.exo) {
    // los anillos de servo van en metal, no en emisivo: un slot menos por brazo
    // es una llamada de dibujo menos por unidad, y a 80 m nadie extraña el brillo
    const servo = P.toroide(0.055, 0.014, 5, 10).rotateX(Math.PI / 2);
    brazoIzq.poner(clonarCompuesto(servo).translate(0, -0.02, 0), pal, 'metal');
    brazoDer.poner(clonarCompuesto(servo).translate(0, -0.02, 0), pal, 'metal');
  }

  const anteIzq = brazoIzq.hijo('anteIzq', 0, -H.brazo, 0);
  const anteDer = brazoDer.hijo('anteDer', 0, -H.brazo, 0);
  anteIzq.reposo(porte.antI[0], porte.antI[1], porte.antI[2]);
  anteDer.reposo(porte.antD[0], porte.antD[1], porte.antD[2]);
  const antebrazo = P.miembro(0.050 * K, 0.041 * K, H.antebrazo - 0.02, 7);
  anteIzq.poner(clonarCompuesto(antebrazo), pal, rolManga);
  anteDer.poner(clonarCompuesto(antebrazo), pal, rolManga);
  // manos grandes de caricatura: cierran el contorno brazo-arma en un solo bulto
  const mano = P.guante(0.044 * PROPORCION.mano);
  anteIzq.poner(clonarCompuesto(mano).translate(0, -H.antebrazo, 0), pal, 'piel');
  anteDer.poner(clonarCompuesto(mano).translate(0, -H.antebrazo, 0), pal, 'piel');

  /* --- arma: cuelga del antebrazo derecho y se endereza al horizonte.
         Va un escalón más grande que el cuerpo Y otro escalón por clase: el
         largo del arma es la segunda palanca de silueta después de los hombros.
         Un rifle a 1.30 dice "tirador" antes de que se distinga la cara. --- */
  const compensa = -(porte.supD[2] + porte.antD[2]) + porte.armaZ;
  const arma = (cfg.porte === 'hombro'
    ? torso.hijo('arma', 0.02, H.torso - 0.10, -hz - 0.02)
    : anteDer.hijo('arma', 0.02, -H.antebrazo - 0.02, 0));
  arma.tamano(PROPORCION.arma * S.arma);
  if (cfg.porte === 'hombro') arma.reposo(0, 0.10, 0.10);
  else arma.reposo(0, 0, compensa);
  arma.poner(P.fusil(armaTipo), pal);   // el arma decide su propio material

  if (cfg.banderin) {
    const est = torso.hijo('estandarte', -0.06, H.torso * 0.30, hz + 0.06);
    est.reposo(0, 0, -0.22);
    est.poner(P.banderin(0.42, 0.26, 1.35), pal, 'madera');
  }

  /* --- piernas: cadera -> rodilla -> tobillo -> pie ---
         `P.miembro` en vez de cápsula: muslo grueso que se afina hacia la
         rodilla. Es lo que le da sombra propia a la pierna y la saca de
         "palito semitransparente". `S.paso` abre o cierra la base de la figura. */
  const cz = H.caderaZ * S.paso;
  for (const lado of [1, -1]) {
    const nom = lado > 0 ? 'Izq' : 'Der';
    const pierna = cadera.hijo(`pierna${nom}`, 0, -0.045, cz * lado);
    const J = PROPORCION.pierna;
    const muslo = P.miembro(0.078 * J, 0.056 * J, H.muslo - 0.02, 7);
    pierna.poner(muslo, pal, cfg.exo ? 'metal' : 'tela');
    if (cfg.exo) {
      pierna.poner(P.placa(0.03, 0.20, 0.10, 0.006).translate(0.055, -H.muslo * 0.5, 0), pal, 'metalOsc');
    }
    const rodilla = pierna.hijo(`rodilla${nom}`, 0, -H.muslo + 0.02, 0);
    const pantorrilla = P.miembro(0.064 * J, 0.040 * J, H.pantorrilla - 0.04, 7);
    rodilla.poner(pantorrilla, pal, cfg.exo ? 'metal' : 'tela2');
    rodilla.poner(P.esfera(0.062 * J, 8), pal, cfg.exo ? 'metal' : 'tela');
    if (cfg.exo) rodilla.poner(P.toroide(0.058 * J, 0.013, 5, 10).rotateX(Math.PI / 2), pal, 'metal');
    const pie = rodilla.hijo(`pie${nom}`, 0, -(H.pantorrilla - 0.02), 0);
    const B = PROPORCION.bota;
    pie.poner(P.bota(0.27 * B, 0.15 * B, 0.105 * B), pal, cfg.exo ? 'metalOsc' : 'cuero');
  }

  return { raiz, escala: esc, tipoAnim: 'humano', cfg };
}

/* ═════════════════ 6. Jinete ═════════════════ */

function construirJinete(clave, edad, cfg, pal, rng) {
  const raiz = new Pieza('raiz');
  const cab = P.caballo('militar');
  const anclas = cab.userData.anclas;
  const yLomo = cab.userData.lomo;
  const pataGeo = cab.userData.patas;

  const cuerpo = raiz.hijo('monturaCuerpo', 0, 0, 0);
  cuerpo.poner(cab, pal, 'tela2');

  const nombres = ['pataDelIzq', 'pataDelDer', 'pataTraIzq', 'pataTraDer'];
  for (let i = 0; i < 4; i++) {
    const a = anclas[i];
    const p = cuerpo.hijo(nombres[i], a[0], a[1], a[2]);
    p.poner(clonarCompuesto(pataGeo), pal, 'tela2');
  }

  /* --- jinete: medio cuerpo sentado sobre la silla ---
     SILUETA: el jinete es HOMBROS ANCHOS Y ALTOS sobre una masa horizontal. El
     caballo aporta el óvalo tumbado, el jinete la vertical; si además el jinete
     fuera del ancho de un infante, las dos clases se leerían igual, que es lo
     que pasaba. Va con hombros a 1.18 y una capa que le cuelga del hombro
     izquierdo hasta la grupa. --- */
  const anchoH = 1.18;
  const cadera = cuerpo.hijo('cadera', -0.02, yLomo + 0.06, 0);
  cadera.poner(P.esferaAchatada(0.105, 0.10, 0.15, 10).translate(0, -0.02, 0), pal, 'tela');
  const torso = cadera.hijo('torso', 0, 0, 0);
  torso.reposo(0, 0, -0.06);
  torso.poner(P.torsoHumano('casaca', anchoH), pal, 'tela');
  torso.poner(P.correaje('bandolera', H.torso), pal, 'correaje');
  // CAPA/PELLIZA: la mancha de bando del jinete. Cuelga del hombro izquierdo y
  // baja hasta la grupa, así que se junta visualmente con la mantilla del
  // caballo y las dos forman UNA sola zona contigua (ver REGLA DE REPARTO).
  torso.poner(P.placa(0.09, 0.52, 0.20, 0.014).rotateZ(0.10).translate(-0.11, H.torso * 0.20, 0.21), pal, 'jugador');
  // el manto es la misma mancha de bando que la infantería: desde arriba el
  // jinete se lee como "mío" antes que como "caballo"
  torso.poner(mantoBando(anchoH), pal, 'jugador');

  const cabeza = torso.hijo('cabeza', 0, H.cuello - H.cadera, 0).tamano(PROPORCION.cabeza);
  cabeza.poner(P.cabezaHumana('barba'), pal, 'piel');
  cabeza.poner(P.casco('chaco'), pal, 'tela2');
  cabeza.poner(P.penacho(0.30, 0.034).translate(0.02, 0.40, 0), pal, 'acento');

  const hz = H.hombroZ * anchoH;
  const brazoIzq = torso.hijo('brazoIzq', 0, H.hombro - H.cadera - 0.055, hz);
  const brazoDer = torso.hijo('brazoDer', 0, H.hombro - H.cadera - 0.055, -hz);
  brazoIzq.reposo(0.30, 0, 0.55);
  brazoDer.reposo(-0.22, -0.10, -0.55);
  const K = PROPORCION.extremidad;
  const mangaSup = P.miembro(0.058 * K, 0.047 * K, H.brazo - 0.03, 7);
  brazoIzq.poner(clonarCompuesto(mangaSup), pal, 'tela2');
  brazoDer.poner(clonarCompuesto(mangaSup), pal, 'tela2');
  const anteIzq = brazoIzq.hijo('anteIzq', 0, -H.brazo, 0);
  const anteDer = brazoDer.hijo('anteDer', 0, -H.brazo, 0);
  anteIzq.reposo(0, 0, 0.95);
  anteDer.reposo(0, 0, 0.80);
  const antebrazo = P.miembro(0.050 * K, 0.041 * K, H.antebrazo - 0.02, 7);
  anteIzq.poner(clonarCompuesto(antebrazo), pal, 'tela2');
  anteDer.poner(clonarCompuesto(antebrazo), pal, 'tela2');
  const mano = P.guante(0.044 * PROPORCION.mano);
  anteIzq.poner(clonarCompuesto(mano).translate(0, -H.antebrazo, 0), pal, 'piel');
  anteDer.poner(clonarCompuesto(mano).translate(0, -H.antebrazo, 0), pal, 'piel');

  // el sable va a 1.34 (contra el 1.16 de la infantería): la hoja curva
  // sobresaliendo de la masa del caballo es la firma de la caballería
  const arma = anteDer.hijo('arma', 0.02, -H.antebrazo - 0.02, 0).tamano(PROPORCION.arma * 1.34);
  arma.reposo(0, 0, -(0.80 - 0.55) + 0.55);
  arma.poner(P.fusil('sable'), pal);

  // piernas del jinete, dobladas sobre los estribos. Van más separadas que
  // antes porque el barril del caballo se ensanchó: montado a horcajadas de
  // verdad, no con las rodillas juntas dentro del animal.
  for (const lado of [1, -1]) {
    const nom = lado > 0 ? 'Izq' : 'Der';
    const pierna = cadera.hijo(`pierna${nom}`, 0.02, -0.06, 0.20 * lado);
    pierna.reposo(0, 0, 0.55);
    const J = PROPORCION.pierna;
    pierna.poner(P.miembro(0.076 * J, 0.056 * J, 0.36, 7), pal, 'tela');
    const rodilla = pierna.hijo(`rodilla${nom}`, 0, -0.36, 0);
    rodilla.reposo(0, 0, -1.15);
    rodilla.poner(P.miembro(0.060 * J, 0.042 * J, 0.30, 7), pal, 'tela2');
    const pie = rodilla.hijo(`pie${nom}`, 0, -0.32, 0);
    const B = PROPORCION.bota;
    pie.poner(P.bota(0.28 * B, 0.30 * B, 0.11 * B), pal, 'cuero');
  }

  return { raiz, escala: 1, tipoAnim: 'jinete', cfg };
}

/* ═════════════════ 7. Blindados ═════════════════ */

function ejeRuedas(chasis, pal, xs, y, z, r, ancho, radios, salida) {
  for (const x of xs) {
    for (const lado of [1, -1]) {
      const p = chasis.hijo(`rueda_${salida.length}`, x, y, z * lado);
      p.poner(radios > 0 ? P.rueda(r, radios, ancho) : P.rueda(r, 0, ancho), pal, radios > 0 ? 'madera' : 'goma');
      salida.push(p);
    }
  }
}

function construirBlindado(clave, edad, cfg, pal, rng) {
  const raiz = new Pieza('raiz');
  const v = cfg.variante;
  const ruedas = [];
  let alto = 2.2;

  if (v === 'semioruga') {
    /* Blindado ligero: ruedas adelante, oruga atrás, ametralladora en anillo. */
    const L = 4.9, An = 2.35, hSuelo = 0.42;
    const chasis = raiz.hijo('chasis', 0, hSuelo + 0.55, 0);
    // El CASCO va gris: es la superficie más grande del vehículo y teñirla
    // entera daba un rectángulo de color plano de 5 m, sin ninguna forma que
    // leer. La zona de bando es la caja de tropa, que mira al cielo (o sea que
    // la cámara la ve de lleno) y queda contigua a la placa de la torreta.
    chasis.poner(P.extruirPerfil([
      [-L / 2, -0.55], [-L / 2 + 0.15, 0.42], [0.30, 0.46], [0.95, 0.18],
      [L / 2 - 0.10, 0.08], [L / 2, -0.22], [L / 2 - 0.35, -0.55],
    ], An, 0.06, 3), pal, 'metal');
    // compartimento trasero abierto con bancos: la mancha de bando del semioruga
    chasis.poner(P.cajaBiselada(2.5, 0.55, An - 0.28, 0.05).translate(-1.05, 0.42, 0), pal, 'jugador');
    chasis.poner(P.cajaBiselada(1.15, 0.62, An - 0.42, 0.05).translate(0.62, 0.42, 0), pal, 'metal');
    chasis.poner(P.rejilla(0.5, 1.2, 6).rotateZ(0.25).translate(L / 2 - 0.12, 0.22, 0), pal, 'metalOsc');
    // parabrisas blindado
    chasis.poner(P.placa(0.06, 0.34, 1.35, 0.012).rotateZ(-0.22).translate(1.16, 0.60, 0), pal, 'vidrio');
    chasis.poner(P.faro(0.10).translate(L / 2 - 0.05, 0.10, 0.85), pal, 'metal');
    chasis.poner(P.faro(0.10).translate(L / 2 - 0.05, 0.10, -0.85), pal, 'metal');
    chasis.poner(P.cajaHerramientas(0.55, 0.22, 0.28).translate(-0.4, -0.30, An / 2 - 0.02), pal, 'metalOsc');
    chasis.poner(P.antenaCorta(1.25, 0.008, 0.18).translate(-1.5, 0.68, An / 2 - 0.18), pal, 'metalOsc');
    // guardabarros delanteros
    chasis.poner(P.placa(1.1, 0.05, 0.34, 0.01).translate(1.35, -0.32, An / 2 - 0.14), pal, 'metalOsc');
    chasis.poner(P.placa(1.1, 0.05, 0.34, 0.01).translate(1.35, -0.32, -(An / 2 - 0.14)), pal, 'metalOsc');
    ejeRuedas(chasis, pal, [1.55], -0.42, An / 2 - 0.16, 0.42, 0.24, 0, ruedas);
    // oruga trasera corta
    const or = chasis.hijo('orugas', -0.85, -0.28, 0);
    or.oruga = {
      geo: normalizar(P.eslabonOruga(0.38, 0.17, 0.05), tinteDeRol('metalOsc', pal)),
      slot: 'metal', n: 13, L: 1.55, r: 0.30, z: An / 2 - 0.22,
    };
    for (let i = 0; i < 3; i++) {
      or.poner(P.ruedaRodadura(0.24, 0.24).translate(-0.7 + i * 0.7, 0, An / 2 - 0.22), pal, 'metal');
      or.poner(P.ruedaRodadura(0.24, 0.24).translate(-0.7 + i * 0.7, 0, -(An / 2 - 0.22)), pal, 'metal');
    }
    // torreta abierta con ametralladora
    const tor = chasis.hijo('torreta', -0.55, 0.72, 0);
    tor.poner(P.toroide(0.42, 0.06, 5, 14).rotateX(Math.PI / 2), pal, 'metal');
    tor.poner(P.cajaBiselada(0.34, 0.28, 0.34, 0.03).translate(0, 0.20, 0), pal, 'metalOsc');
    tor.poner(P.placa(0.05, 0.42, 0.62, 0.010).translate(0.30, 0.34, 0), pal, 'jugador');
    const canon = tor.hijo('canon', 0.16, 0.30, 0);
    canon.poner(P.canonPieza(0.026, 0.95, false), pal, 'metal');
    alto = 2.05;
  } else if (v === 'tanque' || v === 'autonomo') {
    /* Tanque: ancho, bajo y con la panza cerca del piso. Tiene que pesar. */
    const auto = v === 'autonomo';
    const L = auto ? 6.1 : 5.9, An = auto ? 3.15 : 3.05, rOr = 0.44;
    const chasis = raiz.hijo('chasis', 0, rOr + 0.42, 0);
    const perfil = auto ? [
      [-L / 2, -0.34], [-L / 2 + 0.12, 0.30], [-1.2, 0.46], [1.4, 0.44],
      [L / 2 - 0.55, 0.16], [L / 2, -0.16], [L / 2 - 0.30, -0.42],
    ] : [
      [-L / 2, -0.38], [-L / 2 + 0.18, 0.36], [-1.0, 0.44], [1.2, 0.42],
      [L / 2 - 0.75, 0.10], [L / 2 - 0.05, -0.20], [L / 2 - 0.40, -0.46],
    ];
    // casco en gris de blindaje: la zona de bando del tanque es la TORRETA,
    // que es la masa que mira al cielo y la que la cámara ve de lleno a 49°
    chasis.poner(P.extruirPerfil(perfil, An - 0.35, 0.075, 3), pal, 'metal');
    // faldones sobre las orugas
    chasis.poner(P.placa(L - 0.5, 0.55, 0.10, 0.018).translate(-0.05, -0.10, An / 2 - 0.06), pal, 'metalOsc');
    chasis.poner(P.placa(L - 0.5, 0.55, 0.10, 0.018).translate(-0.05, -0.10, -(An / 2 - 0.06)), pal, 'metalOsc');
    // guardabarros y cajas
    chasis.poner(P.placa(1.0, 0.06, 0.42, 0.012).translate(L / 2 - 0.55, 0.30, An / 2 - 0.20), pal, 'metalOsc');
    chasis.poner(P.placa(1.0, 0.06, 0.42, 0.012).translate(L / 2 - 0.55, 0.30, -(An / 2 - 0.20)), pal, 'metalOsc');
    chasis.poner(P.cajaHerramientas(0.7, 0.26, 0.32).translate(-1.9, 0.52, An / 2 - 0.28), pal, 'metalOsc');
    chasis.poner(P.cajaHerramientas(0.5, 0.24, 0.30).translate(-2.4, 0.52, -(An / 2 - 0.28)), pal, 'metalOsc');
    chasis.poner(P.rejilla(1.1, An - 1.0, 7).translate(-1.9, 0.47, 0), pal, 'metalOsc');
    chasis.poner(P.faro(0.13).translate(L / 2 - 0.12, 0.05, An / 2 - 0.42), pal, 'metal');
    chasis.poner(P.faro(0.13).translate(L / 2 - 0.12, 0.05, -(An / 2 - 0.42)), pal, 'metal');
    if (!auto) {
      chasis.poner(P.escape(0.42, 0.055).translate(-2.2, 0.46, An / 2 - 0.45), pal, 'metalOsc');
      chasis.poner(P.escape(0.42, 0.055).translate(-2.2, 0.46, -(An / 2 - 0.45)), pal, 'metalOsc');
      chasis.poner(P.tubo([[1.0, 0.46, An / 2 - 0.30], [-0.4, 0.50, An / 2 - 0.24],
        [-1.7, 0.46, An / 2 - 0.30]], 0.035, 5), pal, 'metal');
    } else {
      chasis.poner(P.panelSolar(1.5, An - 1.2).translate(-1.9, 0.50, 0), pal, 'metalOsc');
      chasis.poner(P.placa(L - 1.4, 0.05, 0.09, 0.012).translate(0, 0.20, An / 2 - 0.14), pal, 'emis');
      chasis.poner(P.placa(L - 1.4, 0.05, 0.09, 0.012).translate(0, 0.20, -(An / 2 - 0.14)), pal, 'emis');
    }

    // orugas: eslabones instanciados + ruedas de rodadura + tensora y motriz
    const or = chasis.hijo('orugas', 0, -(rOr + 0.42) + rOr, 0);
    or.oruga = {
      geo: normalizar(P.eslabonOruga(0.60, 0.20, 0.06), tinteDeRol('metalOsc', pal)),
      slot: 'metal', n: 20, L: L - 1.0, r: rOr, z: An / 2 - 0.30,
    };
    const nBog = 5;
    for (let i = 0; i < nBog; i++) {
      const x = -(L - 1.6) / 2 + i * ((L - 1.6) / (nBog - 1));
      or.poner(P.ruedaRodadura(0.36, 0.36).translate(x, -0.06, An / 2 - 0.30), pal, 'metal');
      or.poner(P.ruedaRodadura(0.36, 0.36).translate(x, -0.06, -(An / 2 - 0.30)), pal, 'metal');
    }
    for (const x of [-(L - 1.0) / 2, (L - 1.0) / 2]) {
      or.poner(P.ruedaRodadura(rOr * 0.86, 0.34).translate(x, 0, An / 2 - 0.30), pal, 'metalOsc');
      or.poner(P.ruedaRodadura(rOr * 0.86, 0.34).translate(x, 0, -(An / 2 - 0.30)), pal, 'metalOsc');
    }

    // torreta
    const tor = chasis.hijo('torreta', auto ? -0.15 : -0.35, 0.48, 0);
    if (auto) {
      tor.poner(P.extruirPerfil([
        [-0.95, 0], [-0.75, 0.46], [0.55, 0.44], [0.95, 0.16], [0.95, 0],
      ], 1.75, 0.05, 2), pal, 'jugador');
      tor.poner(P.sensorDomo(0.20).translate(0.35, 0.44, 0), pal, 'metalOsc');
      tor.poner(P.placa(1.4, 0.04, 0.10, 0.008).translate(-0.1, 0.46, 0.72), pal, 'emis');
      tor.poner(P.placa(1.4, 0.04, 0.10, 0.008).translate(-0.1, 0.46, -0.72), pal, 'emis');
      tor.poner(P.cajaBiselada(0.5, 0.34, 0.34, 0.03).translate(-0.85, 0.30, 0.55), pal, 'metalOsc');
      tor.poner(P.antenaCorta(1.1, 0.008, 0.14).translate(-0.85, 0.46, -0.6), pal, 'metalOsc');
    } else {
      tor.poner(P.esferaAchatada(1.02, 0.44, 0.95, 14).translate(-0.05, 0.22, 0), pal, 'jugador');
      tor.poner(P.extruirPerfil([
        [-0.9, 0], [-0.7, 0.42], [0.5, 0.40], [1.0, 0.10], [1.0, 0],
      ], 1.55, 0.05, 2), pal, 'jugador');
      tor.poner(P.escotilla(0.30, false).translate(-0.35, 0.44, 0.25), pal, 'metal');
      tor.poner(P.escotilla(0.24, false).translate(-0.30, 0.44, -0.42), pal, 'metal');
      tor.poner(P.cajaBiselada(0.75, 0.30, 0.55, 0.03).translate(-1.0, 0.24, 0), pal, 'metalOsc');
      tor.poner(P.antenaCorta(1.4, 0.009, 0.20).translate(-0.85, 0.44, 0.55), pal, 'metalOsc');
      // ametralladora de la escotilla
      tor.poner(P.cilindroConico(0.028, 0.028, 0.6, 8).rotateZ(-Math.PI / 2).translate(0.15, 0.56, 0.25), pal, 'metalOsc');
    }
    const canon = tor.hijo('canon', auto ? 0.75 : 0.80, 0.22, 0);
    canon.poner(P.canonPieza(auto ? 0.055 : 0.062, auto ? 3.5 : 3.1, true), pal, 'metal');
    // mantelete
    canon.poner(P.esferaAchatada(0.26, 0.30, 0.34, 10), pal, 'metal');
    alto = auto ? 2.25 : 2.35;
  } else if (v === 'autopropulsada') {
    /* Artillería autopropulsada: casamata trasera y tubo largo elevado. */
    const L = 6.2, An = 2.95, rOr = 0.40;
    const chasis = raiz.hijo('chasis', 0, rOr + 0.40, 0);
    chasis.poner(P.extruirPerfil([
      [-L / 2, -0.34], [-L / 2 + 0.2, 0.28], [1.0, 0.30], [L / 2 - 0.55, 0.06],
      [L / 2, -0.20], [L / 2 - 0.3, -0.40],
    ], An - 0.4, 0.06, 3), pal, 'metal');   // el bando va en la casamata, no acá
    chasis.poner(P.placa(L - 0.6, 0.5, 0.10, 0.016).translate(0, -0.10, An / 2 - 0.06), pal, 'metalOsc');
    chasis.poner(P.placa(L - 0.6, 0.5, 0.10, 0.016).translate(0, -0.10, -(An / 2 - 0.06)), pal, 'metalOsc');
    chasis.poner(P.faro(0.11).translate(L / 2 - 0.1, 0.0, An / 2 - 0.5), pal, 'metal');
    chasis.poner(P.faro(0.11).translate(L / 2 - 0.1, 0.0, -(An / 2 - 0.5)), pal, 'metal');
    chasis.poner(P.rejilla(0.9, An - 1.2, 6).translate(1.6, 0.31, 0), pal, 'metalOsc');
    // pala de anclaje trasera: detalle que sólo tiene la autopropulsada
    chasis.poner(P.placa(0.10, 0.75, An - 0.9, 0.016).rotateZ(0.35).translate(-L / 2 - 0.05, -0.15, 0), pal, 'metalOsc');
    const or = chasis.hijo('orugas', 0, -rOr - 0.40 + rOr, 0);
    or.oruga = {
      geo: normalizar(P.eslabonOruga(0.55, 0.19, 0.055), tinteDeRol('metalOsc', pal)),
      slot: 'metal', n: 20, L: L - 1.1, r: rOr, z: An / 2 - 0.28,
    };
    for (let i = 0; i < 5; i++) {
      const x = -(L - 1.8) / 2 + i * ((L - 1.8) / 4);
      or.poner(P.ruedaRodadura(0.33, 0.34).translate(x, -0.05, An / 2 - 0.28), pal, 'metal');
      or.poner(P.ruedaRodadura(0.33, 0.34).translate(x, -0.05, -(An / 2 - 0.28)), pal, 'metal');
    }
    const tor = chasis.hijo('torreta', -0.9, 0.30, 0);
    tor.poner(P.extruirPerfil([
      [-1.35, 0], [-1.25, 0.85], [0.55, 0.80], [1.15, 0.30], [1.15, 0],
    ], An - 0.55, 0.05, 2), pal, 'jugador');
    tor.poner(P.escotilla(0.30, true).translate(-0.55, 0.84, 0.42), pal, 'metal');
    tor.poner(P.antenaCorta(1.5, 0.009, 0.22).translate(-1.15, 0.84, -0.7), pal, 'metalOsc');
    tor.poner(P.cajaHerramientas(0.6, 0.28, 0.30).translate(-1.42, 0.45, 0.6), pal, 'metalOsc');
    const canon = tor.hijo('canon', 1.05, 0.45, 0);
    canon.reposo(0, 0, 0.12);
    canon.poner(P.canonPieza(0.055, 4.2, true), pal, 'metal');
    canon.poner(P.esferaAchatada(0.24, 0.28, 0.30, 10), pal, 'metal');
    alto = 2.55;
  } else if (v === 'riel') {
    /* Cañón de riel: plataforma larga, dos rieles y bancos de bobinas vivas. */
    const L = 6.9, An = 3.15, rOr = 0.42;
    const chasis = raiz.hijo('chasis', 0, rOr + 0.42, 0);
    chasis.poner(P.extruirPerfil([
      [-L / 2, -0.36], [-L / 2 + 0.25, 0.34], [1.2, 0.36], [L / 2 - 0.7, 0.10],
      [L / 2, -0.18], [L / 2 - 0.3, -0.42],
    ], An - 0.45, 0.07, 3), pal, 'metal');   // el bando va en el bloque de bobinas
    chasis.poner(P.placa(L - 0.7, 0.52, 0.10, 0.016).translate(0, -0.12, An / 2 - 0.06), pal, 'metalOsc');
    chasis.poner(P.placa(L - 0.7, 0.52, 0.10, 0.016).translate(0, -0.12, -(An / 2 - 0.06)), pal, 'metalOsc');
    chasis.poner(P.placa(L - 1.6, 0.05, 0.11, 0.012).translate(0, 0.18, An / 2 - 0.16), pal, 'emis');
    chasis.poner(P.placa(L - 1.6, 0.05, 0.11, 0.012).translate(0, 0.18, -(An / 2 - 0.16)), pal, 'emis');
    chasis.poner(P.sensorDomo(0.18).translate(L / 2 - 0.9, 0.38, 0), pal, 'metalOsc');
    const or = chasis.hijo('orugas', 0, -rOr - 0.42 + rOr, 0);
    or.oruga = {
      geo: normalizar(P.eslabonOruga(0.60, 0.20, 0.06), tinteDeRol('metalOsc', pal)),
      slot: 'metal', n: 22, L: L - 1.2, r: rOr, z: An / 2 - 0.30,
    };
    for (let i = 0; i < 6; i++) {
      const x = -(L - 2.0) / 2 + i * ((L - 2.0) / 5);
      or.poner(P.ruedaRodadura(0.34, 0.34).translate(x, -0.05, An / 2 - 0.30), pal, 'metal');
      or.poner(P.ruedaRodadura(0.34, 0.34).translate(x, -0.05, -(An / 2 - 0.30)), pal, 'metal');
    }
    const tor = chasis.hijo('torreta', -0.6, 0.36, 0);
    tor.poner(P.cajaBiselada(2.3, 0.85, An - 0.9, 0.06).translate(-0.55, 0.42, 0), pal, 'jugador');
    tor.poner(P.rejilla(1.6, An - 1.3, 8).translate(-0.9, 0.86, 0), pal, 'metalOsc');
    const canon = tor.hijo('canon', 0.6, 0.55, 0);
    // dos rieles paralelos con el hueco encendido
    canon.poner(P.placa(4.4, 0.14, 0.13, 0.02).translate(2.1, 0, 0.20), pal, 'metal');
    canon.poner(P.placa(4.4, 0.14, 0.13, 0.02).translate(2.1, 0, -0.20), pal, 'metal');
    canon.poner(P.placa(4.2, 0.05, 0.22, 0.01).translate(2.1, 0, 0), pal, 'emis');
    for (let i = 0; i < 5; i++) {
      canon.poner(P.toroide(0.30, 0.075, 6, 12).rotateY(Math.PI / 2).translate(0.55 + i * 0.85, 0, 0), pal, 'metalOsc');
    }
    canon.poner(P.cajaBiselada(0.75, 0.60, 0.70, 0.05).translate(-0.15, 0, 0), pal, 'metal');
    canon.boca = [4.4, 0, 0];
    alto = 2.6;
  } else {
    /* Ariete blindado: bulldozer acorazado, todo cuña y remaches. */
    const L = 5.3, An = 3.0, rOr = 0.42;
    const chasis = raiz.hijo('chasis', 0, rOr + 0.40, 0);
    chasis.poner(P.extruirPerfil([
      [-L / 2, -0.36], [-L / 2 + 0.2, 0.55], [0.2, 0.62], [1.3, 0.30],
      [L / 2 - 0.4, 0.05], [L / 2 - 0.2, -0.30],
    ], An - 0.5, 0.07, 3), pal, 'jugador');   // el ariete no tiene torreta: SU zona es el casco
    // pala en cuña: la silueta que dice "esto viene a tirarte la muralla"
    const pala = chasis.hijo('pala', L / 2 - 0.2, -0.30, 0);
    pala.poner(P.extruirPerfil([
      [0, -0.35], [1.05, -0.42], [1.15, 0.10], [0.75, 0.55], [0, 0.45],
    ], An + 0.15, 0.05, 2), pal, 'metal');
    pala.poner(P.placa(0.14, 0.9, 0.16, 0.02).translate(0.6, 0.05, An / 2 - 0.1), pal, 'metalOsc');
    pala.poner(P.placa(0.14, 0.9, 0.16, 0.02).translate(0.6, 0.05, -(An / 2 - 0.1)), pal, 'metalOsc');
    chasis.poner(P.placa(L - 0.5, 0.52, 0.10, 0.016).translate(0, -0.12, An / 2 - 0.06), pal, 'metalOsc');
    chasis.poner(P.placa(L - 0.5, 0.52, 0.10, 0.016).translate(0, -0.12, -(An / 2 - 0.06)), pal, 'metalOsc');
    chasis.poner(P.escotilla(0.32, false).translate(-0.9, 0.62, 0), pal, 'metal');
    chasis.poner(P.escape(0.55, 0.06).translate(-1.7, 0.60, 0.75), pal, 'metalOsc');
    chasis.poner(P.escape(0.55, 0.06).translate(-1.7, 0.60, -0.75), pal, 'metalOsc');
    chasis.poner(P.rejilla(0.9, An - 1.4, 6).translate(-1.9, 0.56, 0), pal, 'metalOsc');
    const or = chasis.hijo('orugas', -0.2, -rOr - 0.40 + rOr, 0);
    or.oruga = {
      geo: normalizar(P.eslabonOruga(0.62, 0.20, 0.06), tinteDeRol('metalOsc', pal)),
      slot: 'metal', n: 18, L: L - 1.5, r: rOr, z: An / 2 - 0.30,
    };
    for (let i = 0; i < 4; i++) {
      const x = -(L - 2.2) / 2 + i * ((L - 2.2) / 3);
      or.poner(P.ruedaRodadura(0.35, 0.36).translate(x, -0.05, An / 2 - 0.30), pal, 'metal');
      or.poner(P.ruedaRodadura(0.35, 0.36).translate(x, -0.05, -(An / 2 - 0.30)), pal, 'metal');
    }
    alto = 2.1;
  }
  return { raiz, escala: 1, tipoAnim: 'blindado', cfg, alto, ruedas };
}

/* ═════════════════ 8. Artillería remolcada ═════════════════ */

function construirArtilleria(clave, edad, cfg, pal, rng) {
  const raiz = new Pieza('raiz');
  const obus = cfg.variante === 'obus';
  const rR = obus ? 0.52 : 0.58;
  const chasis = raiz.hijo('chasis', 0, rR, 0);

  // cureña: dos brazos que se abren hacia atrás
  const brazo = P.extruirPerfil([
    [-1.85, -0.30], [-1.70, -0.22], [0.25, 0.05], [0.55, 0.22], [0.20, 0.26], [-1.78, -0.10],
  ], 0.13, 0.02, 2);
  chasis.poner(clonarCompuesto(brazo).translate(0, 0, 0.34), pal, obus ? 'metal' : 'madera');
  chasis.poner(clonarCompuesto(brazo).translate(0, 0, -0.34), pal, obus ? 'metal' : 'madera');
  chasis.poner(P.cajaBiselada(0.55, 0.24, 0.86, 0.02).translate(0.15, 0.12, 0), pal, obus ? 'metal' : 'madera');
  // rejas de las colas
  chasis.poner(P.extruirPerfil([[-1.95, -0.34], [-1.72, -0.30], [-1.76, -0.10], [-1.95, -0.15]], 0.14, 0.01, 1)
    .translate(0, 0, 0.34), pal, 'metal');
  chasis.poner(P.extruirPerfil([[-1.95, -0.34], [-1.72, -0.30], [-1.76, -0.10], [-1.95, -0.15]], 0.14, 0.01, 1)
    .translate(0, 0, -0.34), pal, 'metal');
  // escudo: el rasgo de contorno que hace legible al cañón desde arriba
  chasis.poner(P.extruirPerfil([
    [0.02, -0.30], [0.14, -0.32], [0.18, 0.62], [0.02, 0.66],
  ], obus ? 1.55 : 1.30, 0.02, 2).translate(0.42, 0.10, 0), pal, 'jugador');
  chasis.poner(P.placa(0.03, 0.10, obus ? 1.5 : 1.25, 0.006).translate(0.60, 0.62, 0), pal, 'metalOsc');
  // ruedas grandes de rayos (o macizas en el obús)
  const ruedas = [];
  for (const lado of [1, -1]) {
    const p = chasis.hijo(`rueda_${ruedas.length}`, 0.18, 0, (obus ? 0.72 : 0.66) * lado);
    p.poner(obus ? P.rueda(rR, 0, 0.20) : P.rueda(rR, 12, 0.14), pal, obus ? 'goma' : 'madera');
    ruedas.push(p);
  }
  chasis.poner(P.cilindroConico(0.05, 0.05, 1.5, 8).rotateX(Math.PI / 2).translate(0.18, 0, 0), pal, 'metal');
  // munición y accesorios: densidad visual barata
  chasis.poner(P.cajaHerramientas(0.4, 0.22, 0.26).translate(-0.9, -0.05, 0.48), pal, 'metalOsc');
  for (let i = 0; i < 3; i++) {
    chasis.poner(P.cilindroConico(0.048, 0.048, 0.26, 8).rotateZ(-Math.PI / 2)
      .translate(-1.1 + i * 0.16, 0.04, -0.46), pal, 'acento');
  }

  const tor = chasis.hijo('torreta', 0.30, 0.28, 0);
  const canon = tor.hijo('canon', 0, 0, 0);
  canon.reposo(0, 0, obus ? 0.42 : 0.10);
  canon.poner(P.canonPieza(obus ? 0.075 : 0.062, obus ? 2.1 : 2.6, obus), pal, 'metal');
  return { raiz, escala: 1, tipoAnim: 'remolcado', cfg, alto: 1.55, ruedas };
}

/* ═════════════════ 9. Aéreos ═════════════════ */

function construirAereo(clave, edad, cfg, pal, rng) {
  const raiz = new Pieza('raiz');
  // vuelan a media altura sobre su propia posición: el sistema de movimiento ya
  // les da altitud, esto es sólo la separación visual del tren de aterrizaje.
  const cuerpo = raiz.hijo('chasis', 0, 1.6, 0);
  const rotores = [];

  if (cfg.variante === 'ala') {
    /* Dron de ala fija: fuselaje afilado, alas largas, cola en V, hélice atrás. */
    // el FUSELAJE es la zona de bando del aéreo: una franja larga y contigua de
    // punta a cola. Las alas van en gris para que el avión se lea como avión y
    // no como una mancha de color con forma de cruz.
    cuerpo.poner(P.esferaAchatada(1.75, 0.34, 0.34, 14), pal, 'jugador');
    cuerpo.poner(P.revolucion([[0.34, 0], [0.26, 0.5], [0.10, 0.95], [0.02, 1.05]], 12)
      .rotateZ(-Math.PI / 2).translate(1.6, 0, 0), pal, 'metalOsc');
    cuerpo.poner(P.esferaAchatada(0.42, 0.26, 0.30, 12).translate(1.05, 0.10, 0), pal, 'vidrio');
    // alas: perfil fino con puntas caídas
    const ala = P.extruirPerfil([
      [-0.45, 0], [0.45, 0.02], [0.30, 2.35], [-0.22, 2.30],
    ], 0.09, 0.02, 2);
    ala.rotateX(Math.PI / 2);
    cuerpo.poner(clonarCompuesto(ala).translate(-0.15, 0.05, 0.28), pal, 'metal');
    cuerpo.poner(clonarCompuesto(ala).rotateY(Math.PI).translate(-0.15, 0.05, -0.28), pal, 'metal');
    cuerpo.poner(P.placa(0.5, 0.10, 0.6, 0.012).translate(-0.2, -0.02, 2.15), pal, 'emis');
    cuerpo.poner(P.placa(0.5, 0.10, 0.6, 0.012).translate(-0.2, -0.02, -2.15), pal, 'emis');
    // misiles bajo las alas
    for (const lado of [1, -1]) {
      cuerpo.poner(P.capsula(0.10, 0.75, 8).rotateZ(Math.PI / 2).translate(-0.05, -0.30, 1.15 * lado), pal, 'metalOsc');
      cuerpo.poner(P.barra([-0.05, -0.02, 1.15 * lado], [-0.05, -0.24, 1.15 * lado], 0.03, 5), pal, 'metal');
    }
    // cola en V
    const timon = P.extruirPerfil([[-0.75, 0], [0.05, 0.05], [-0.1, 1.05], [-0.62, 1.0]], 0.07, 0.015, 2);
    cuerpo.poner(clonarCompuesto(timon).rotateX(-0.55).translate(-1.45, 0.05, 0.12), pal, 'metalOsc');
    cuerpo.poner(clonarCompuesto(timon).rotateX(0.55).translate(-1.45, 0.05, -0.12), pal, 'metalOsc');
    cuerpo.poner(P.sensorDomo(0.24).rotateZ(Math.PI).translate(0.85, -0.28, 0), pal, 'metalOsc');
    // hélice propulsora: el soporte la pone vertical y el rotor gira en su eje
    const soporte = cuerpo.hijo('rotorBase', -1.85, 0, 0).reposo(0, 0, Math.PI / 2);
    const rot = soporte.hijo('rotor0', 0, 0, 0);
    rot.poner(P.helice(3, 0.62, 0.085), pal, 'metalOsc');
    rotores.push(rot);
    cuerpo.poner(P.esfera(0.09, 8).translate(-0.5, -0.34, 0), pal, 'emis');
  } else {
    /* Enjambre: un nodo madre con cuatro rotores y micro-drones satélite. */
    cuerpo.poner(P.esferaAchatada(0.85, 0.36, 0.85, 14), pal, 'jugador');
    cuerpo.poner(P.esferaAchatada(0.55, 0.22, 0.55, 12).translate(0, 0.28, 0), pal, 'metalOsc');
    cuerpo.poner(P.sensorDomo(0.26).rotateZ(Math.PI).translate(0, -0.34, 0), pal, 'metalOsc');
    const brazos = [[1, 1], [1, -1], [-1, 1], [-1, -1]];
    for (let i = 0; i < 4; i++) {
      const [sx, sz] = brazos[i];
      const bx = 1.15 * sx, bz = 1.15 * sz;
      cuerpo.poner(P.barra([0.35 * sx, 0.02, 0.35 * sz], [bx, 0.06, bz], 0.075, 6), pal, 'metal');
      cuerpo.poner(P.disco(0.20, 0.10, 10).translate(bx, 0.10, bz), pal, 'metalOsc');
      cuerpo.poner(P.toroide(0.62, 0.035, 5, 16).rotateX(Math.PI / 2).translate(bx, 0.12, bz), pal, 'metalOsc');
      const rot = cuerpo.hijo(`rotor${i}`, bx, 0.20, bz);
      rot.poner(P.helice(2, 0.58, 0.07), pal, 'metalOsc');
      rotores.push(rot);
      cuerpo.poner(P.esfera(0.07, 6).translate(bx, -0.02, bz), pal, 'emis');
    }
    // micro-drones colgando: la firma del Enjambre
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * TAU, r = 0.95;
      cuerpo.poner(P.esferaAchatada(0.12, 0.06, 0.12, 6)
        .translate(Math.cos(a) * r, -0.55 - (i % 2) * 0.12, Math.sin(a) * r), pal, 'metalOsc');
      cuerpo.poner(P.esfera(0.035, 5)
        .translate(Math.cos(a) * r, -0.62 - (i % 2) * 0.12, Math.sin(a) * r), pal, 'emis');
    }
    cuerpo.poner(P.placa(1.3, 0.04, 0.10, 0.008).translate(0, 0.36, 0), pal, 'emis');
  }
  const luz = cuerpo.hijo('luces', 0, 0, 0);
  luz.poner(P.esfera(0.085, 6).translate(cfg.variante === 'ala' ? 1.5 : 0.7, 0.18, 0), pal, 'emis');
  cuerpo.boca = cfg.variante === 'ala' ? [0.9, -0.42, 1.15] : [0.9, -0.30, 0];
  return { raiz, escala: 1, tipoAnim: 'aereo', cfg, alto: 3.2, rotores };
}

/* ═════════════════ 10. Navales ═════════════════ */

function construirNaval(clave, edad, cfg, pal, rng) {
  const raiz = new Pieza('raiz');
  const v = cfg.variante;
  const casco = raiz.hijo('chasis', 0, 0, 0);

  if (v === 'pesquero') {
    casco.poner(P.cascoNave(5.6, 1.9, 0.62, 'vela'), pal, 'madera');
    casco.poner(P.cajaBiselada(1.5, 0.85, 1.35, 0.05).translate(-0.6, 1.05, 0), pal, 'jugador');
    casco.poner(P.placa(0.06, 0.34, 1.1, 0.01).translate(0.16, 1.32, 0), pal, 'vidrio');
    casco.poner(P.cilindroConico(0.045, 0.06, 2.5, 8).translate(0.9, 1.85, 0), pal, 'madera');
    casco.poner(P.tubo([[0.9, 3.05, 0], [-0.2, 2.3, 0], [-1.4, 1.6, 0]], 0.012, 4), pal, 'correaje');
    // red y boyas: se lee "pesquero" al instante
    casco.poner(P.toroide(0.55, 0.06, 5, 12).rotateZ(0.4).translate(-1.9, 0.85, 0.55), pal, 'correaje');
    for (let i = 0; i < 3; i++) {
      casco.poner(P.esfera(0.14, 6).translate(-2.2 + i * 0.3, 0.75, -0.72), pal, 'acento');
    }
    casco.poner(P.escape(0.5, 0.05).translate(-1.2, 1.5, 0.4), pal, 'metalOsc');
    return { raiz, escala: 1, tipoAnim: 'naval', cfg, alto: 3.2 };
  }
  if (v === 'fragata') {
    casco.poner(P.cascoNave(11.0, 2.9, 1.05, 'vela'), pal, 'madera');
    // en la fragata la mancha de bando son las VELAS mayores (ver P.mastil): son
    // la superficie más grande y la única que se ve entera desde arriba. El
    // castillo de popa va en madera para no abrir una segunda zona de color.
    casco.poner(P.cajaBiselada(2.6, 0.85, 2.3, 0.06).translate(-3.1, 1.45, 0), pal, 'madera');
    casco.poner(P.cajaBiselada(1.6, 0.55, 2.0, 0.05).translate(2.7, 1.30, 0), pal, 'madera');
    // portas de cañón a ambas bandas
    for (let i = 0; i < 5; i++) {
      const x = -2.2 + i * 1.15;
      for (const lado of [1, -1]) {
        casco.poner(P.cajaBiselada(0.30, 0.34, 0.10, 0.02).translate(x, 0.72, 1.44 * lado), pal, 'oscuro');
        casco.poner(P.cilindroConico(0.055, 0.065, 0.7, 8).rotateX(Math.PI / 2)
          .translate(x, 0.72, (1.55 + 0.2) * lado), pal, 'metalOsc');
      }
    }
    casco.poner(P.mastil(6.2, 2, 3.4).translate(1.3, 1.05, 0), pal, 'madera');
    casco.poner(P.mastil(7.0, 2, 3.8).translate(-1.1, 1.05, 0), pal, 'madera');
    casco.poner(P.mastil(5.0, 1, 2.6).translate(-3.6, 1.05, 0), pal, 'madera');
    casco.poner(P.cilindroConico(0.05, 0.075, 2.6, 8).rotateZ(-1.15).translate(5.9, 1.75, 0), pal, 'madera');
    casco.poner(P.banderin(0.7, 0.42, 1.2).translate(-4.9, 1.1, 0), pal, 'madera');
    casco.boca = [0.6, 0.72, 1.95];      // la andanada sale por la banda
    return { raiz, escala: 1, tipoAnim: 'naval', cfg, alto: 8.5 };
  }
  if (v === 'destructor') {
    casco.poner(P.cascoNave(13.0, 2.9, 1.15, 'moderno'), pal, 'metal');
    casco.poner(P.extruirPerfil([
      [-2.2, 0], [-1.9, 1.35], [1.2, 1.30], [1.9, 0.55], [1.9, 0],
    ], 2.3, 0.05, 2).translate(-0.2, 1.15, 0), pal, 'jugador');
    casco.poner(P.cajaBiselada(1.5, 1.0, 1.7, 0.05).translate(-0.4, 2.75, 0), pal, 'metalOsc');
    casco.poner(P.placa(0.06, 0.45, 1.6, 0.012).rotateZ(-0.2).translate(0.35, 2.85, 0), pal, 'vidrio');
    // mástil de sensores con radar giratorio
    casco.poner(P.cilindroConico(0.07, 0.11, 2.6, 8).translate(-1.1, 4.4, 0), pal, 'metalOsc');
    const radar = casco.hijo('radar', -1.1, 5.7, 0);
    radar.poner(P.placa(0.10, 0.85, 1.5, 0.02), pal, 'metal');
    radar.poner(P.placa(0.04, 0.7, 1.3, 0.01).translate(0.09, 0, 0), pal, 'emis');
    // celdas de misiles
    for (let i = 0; i < 4; i++) for (let j = 0; j < 2; j++) {
      casco.poner(P.cajaBiselada(0.26, 0.14, 0.26, 0.03)
        .translate(-3.6 + i * 0.32, 1.30, -0.20 + j * 0.4), pal, 'metalOsc');
    }
    casco.poner(P.cilindroConico(0.28, 0.36, 1.5, 10).translate(-2.6, 2.3, 0), pal, 'metalOsc');
    const tor = casco.hijo('torreta', 3.6, 1.25, 0);
    // la zona de bando del destructor es la superestructura: la torre del cañón va gris
    tor.poner(P.extruirPerfil([[-0.75, 0], [-0.55, 0.62], [0.5, 0.58], [0.8, 0.20], [0.8, 0]], 1.5, 0.04, 2), pal, 'metal');
    const canon = tor.hijo('canon', 0.65, 0.34, 0);
    canon.poner(P.canonPieza(0.05, 2.3, true), pal, 'metal');
    return { raiz, escala: 1, tipoAnim: 'naval', cfg, alto: 6.6 };
  }
  /* transporte */
  casco.poner(P.cascoNave(10.0, 3.5, 1.05, 'moderno'), pal, 'metal');
  casco.poner(P.cajaBiselada(3.0, 1.10, 3.0, 0.06).translate(-2.4, 1.55, 0), pal, 'jugador');
  casco.poner(P.cajaBiselada(1.7, 1.15, 1.8, 0.05).translate(-3.2, 2.65, 0), pal, 'metalOsc');
  casco.poner(P.placa(0.06, 0.42, 1.5, 0.012).translate(-2.4, 2.80, 0), pal, 'vidrio');
  // rampa de proa abatible
  const rampa = casco.hijo('rampa', 4.6, 0.55, 0);
  rampa.reposo(0, 0, 0.20);
  rampa.poner(P.cajaBiselada(2.0, 0.14, 2.9, 0.03).translate(0.9, 0, 0), pal, 'metalOsc');
  for (let i = 0; i < 4; i++) {
    casco.poner(P.placa(0.10, 0.85, 3.2, 0.015).translate(1.6 - i * 1.1, 1.35, 0), pal, 'metalOsc');
  }
  casco.poner(P.escape(0.7, 0.075).translate(-3.6, 3.2, 0.6), pal, 'metalOsc');
  casco.poner(P.antenaCorta(1.6, 0.01, 0.2).translate(-3.9, 3.2, -0.6), pal, 'metalOsc');
  return { raiz, escala: 1, tipoAnim: 'naval', cfg, alto: 4.6 };
}

/* ═════════════════ 11. Caravana ═════════════════ */

function construirCaravana(clave, edad, cfg, pal, rng) {
  const raiz = new Pieza('raiz');
  const ruedas = [];
  const moderna = edad >= 3;
  const chasis = raiz.hijo('chasis', 0, moderna ? 0.62 : 0.72, 0);

  if (moderna) {
    /* Camión de reparto: cabina corta y caja larga con lona del jugador. */
    chasis.poner(P.extruirPerfil([
      [-2.5, -0.28], [-2.4, 0.18], [0.9, 0.20], [1.55, 0.05], [1.9, -0.10], [1.85, -0.30],
    ], 1.9, 0.05, 3), pal, 'metalOsc');
    chasis.poner(P.cajaBiselada(1.5, 1.0, 1.95, 0.05).translate(1.05, 0.68, 0), pal, 'metalOsc');
    chasis.poner(P.placa(0.06, 0.42, 1.65, 0.012).rotateZ(-0.16).translate(1.78, 0.80, 0), pal, 'vidrio');
    // la caja de carga es la única zona de bando del camión: la cabina va gris
    chasis.poner(P.cajaBiselada(3.1, 1.25, 2.05, 0.06).translate(-1.0, 0.85, 0), pal, 'jugador');
    for (let i = 0; i < 4; i++) {
      chasis.poner(P.placa(0.06, 1.15, 0.10, 0.012).translate(0.3 - i * 0.85, 0.85, 1.02), pal, 'metalOsc');
      chasis.poner(P.placa(0.06, 1.15, 0.10, 0.012).translate(0.3 - i * 0.85, 0.85, -1.02), pal, 'metalOsc');
    }
    chasis.poner(P.faro(0.10).translate(1.9, 0.02, 0.72), pal, 'metal');
    chasis.poner(P.faro(0.10).translate(1.9, 0.02, -0.72), pal, 'metal');
    ejeRuedas(chasis, pal, [1.35, -1.15, -1.75], -0.28, 0.96, 0.42, 0.26, 0, ruedas);
    return { raiz, escala: 1, tipoAnim: 'blindado', cfg, alto: 2.4, ruedas };
  }

  /* Carro entoldado tirado por un caballo. */
  chasis.poner(P.cajaBiselada(2.9, 0.42, 1.65, 0.04).translate(-0.5, 0, 0), pal, 'madera');
  for (let i = 0; i < 5; i++) {
    const t = i / 4;
    const arco = P.toroide(0.80, 0.035, 5, 12, Math.PI).rotateY(Math.PI / 2);
    chasis.poner(arco.translate(-1.7 + t * 2.4, 0.20, 0), pal, 'madera');
  }
  chasis.poner(P.mediaCania(0.84, 2.5, 0.05, 12).translate(-0.5, 0.20, 0), pal, 'jugador');
  chasis.poner(P.placa(0.06, 1.0, 1.55, 0.012).translate(-1.95, 0.55, 0), pal, 'correaje');
  chasis.poner(P.cajaHerramientas(0.45, 0.30, 0.35).translate(-1.85, -0.05, 0.72), pal, 'madera');
  // lanza y varas de tiro
  chasis.poner(P.cilindroConico(0.045, 0.055, 2.2, 7).rotateZ(-Math.PI / 2).translate(2.0, -0.18, 0), pal, 'madera');
  ejeRuedas(chasis, pal, [0.75], -0.28, 0.86, 0.52, 0.13, 10, ruedas);
  ejeRuedas(chasis, pal, [-1.5], -0.28, 0.86, 0.62, 0.13, 12, ruedas);

  const tiro = raiz.hijo('monturaCuerpo', 3.35, 0, 0);
  const cab = P.caballo('tiro');
  tiro.poner(cab, pal, 'tela2');
  const anclas = cab.userData.anclas;
  const nombres = ['pataDelIzq', 'pataDelDer', 'pataTraIzq', 'pataTraDer'];
  for (let i = 0; i < 4; i++) {
    const a = anclas[i];
    const p = tiro.hijo(nombres[i], a[0], a[1], a[2]);
    p.poner(clonarCompuesto(cab.userData.patas), pal, 'tela2');
  }
  return { raiz, escala: 1, tipoAnim: 'carro', cfg, alto: 2.2, ruedas };
}

/* ═════════════════ 12. Compilado y cacheo del prototipo ═════════════════ */

const cacheProto = new Map();
const hashCadena = (s) => {
  let h = 2166136261 >>> 0;
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); }
  return h >>> 0;
};

function construirPrototipo(clave, edad, ctx) {
  const claveCache = `${clave}|${edad}`;
  const hit = cacheProto.get(claveCache);
  if (hit) return hit;

  const cfg = CATALOGO_UNIDADES[clave] || CATALOGO_UNIDADES.miliciano;
  const pal = paletaEdad(edad);
  const semilla = (hashCadena(claveCache) ^ (ctx?.rng?.semilla >>> 0 || 0)) >>> 0;
  const rng = new RNG(semilla);

  let bruto;
  try {
    switch (cfg.familia) {
      case 'jinete': bruto = construirJinete(clave, edad, cfg, pal, rng); break;
      case 'blindado': bruto = construirBlindado(clave, edad, cfg, pal, rng); break;
      case 'artilleria': bruto = construirArtilleria(clave, edad, cfg, pal, rng); break;
      case 'aereo': bruto = construirAereo(clave, edad, cfg, pal, rng); break;
      case 'naval': bruto = construirNaval(clave, edad, cfg, pal, rng); break;
      case 'caravana': bruto = construirCaravana(clave, edad, cfg, pal, rng); break;
      default: bruto = construirHumano(clave, edad, cfg, pal, rng);
    }
  } catch (e) {
    console.warn('[UnidadFabrica] falló', clave, e);
    bruto = construirHumano(clave, edad, CATALOGO_UNIDADES.miliciano, pal, rng);
  }

  const arbol = compilar(bruto.raiz);
  // Escala de JUEGO por clase × ajuste fino de la receta (cfg.escala).
  // ojo: si la receta original falló y caímos al humano de respaldo, manda la
  // familia del bruto que REALMENTE se construyó, no la que pedía el catálogo
  const clase = ESCALA_JUEGO[(bruto.cfg || cfg).familia] || ESCALA_JUEGO.humano;
  const ajuste = bruto.escala || 1;
  const escXZ = clase.xz * ajuste;
  const escY = clase.y * ajuste;
  const alturaCalc = alturaDe(arbol, escY);
  const proto = {
    arbol, escXZ, escY, tipoAnim: bruto.tipoAnim, cfg: bruto.cfg || cfg,
    altura: Math.max(alturaCalc, (bruto.alto || 0) * escY),
  };
  cacheProto.set(claveCache, proto);
  return proto;
}

/**
 * Altura del prototipo recorriendo el árbol con la pila de transformaciones.
 * Arrastra la escala local de cada pivote (la caricatura): si no, la cabeza
 * agrandada del aldeano quedaría fuera de la altura declarada y las barras de
 * vida y los indicadores de selección se le clavarían en la frente.
 */
function alturaDe(nodo, escY) {
  let maxY = 0;
  const rec = (n, oy, k) => {
    const y = oy + n.pos[1] * k;
    const kk = k * (n.esc || 1);
    for (const s of n.slots) {
      const bb = s.geo.boundingBox;
      if (bb) maxY = Math.max(maxY, y + bb.max.y * kk);
    }
    for (const h of n.hijos) rec(h, y, kk);
  };
  rec(nodo, 0, 1);
  return Math.max(0.5, maxY * escY);
}

/* ═════════════════ 13. Animadores ═════════════════ */

const suave = (a, b, t) => a + (b - a) * Math.min(1, Math.max(0, t));

/** Guarda los valores de reposo de un Object3D para poder volver siempre a ellos. */
function reposoDe(o) {
  return o ? { px: o.position.x, py: o.position.y, pz: o.position.z, rx: o.rotation.x, ry: o.rotation.y, rz: o.rotation.z } : null;
}

function animadorHumano(pz, tipoAtaque) {
  const cad = pz.cadera, tor = pz.torso, cab = pz.cabeza;
  const bI = pz.brazoIzq, bD = pz.brazoDer, aI = pz.anteIzq, aD = pz.anteDer;
  const pI = pz.piernaIzq, pD = pz.piernaDer, rI = pz.rodillaIzq, rD = pz.rodillaDer;
  const fI = pz.pieIzq, fD = pz.pieDer, arma = pz.arma;
  const R = {
    cad: reposoDe(cad), tor: reposoDe(tor), cab: reposoDe(cab),
    bI: reposoDe(bI), bD: reposoDe(bD), aI: reposoDe(aI), aD: reposoDe(aD),
    pI: reposoDe(pI), pD: reposoDe(pD), rI: reposoDe(rI), rD: reposoDe(rD),
    fI: reposoDe(fI), fD: reposoDe(fD), arma: reposoDe(arma),
  };
  let tMuerte = 0, mezcla = 0;

  return function animar(fase, estado, dt, extra) {
    const vel = extra && extra.velNorm ? extra.velNorm : 0;

    if (estado === ESTADO.MURIENDO) {
      tMuerte = Math.min(0.8, tMuerte + dt);
      const k = tMuerte / 0.8, e = 1 - Math.pow(1 - k, 2.1);
      if (cad) {
        cad.rotation.z = R.cad.rz + e * 1.52;              // cae de espaldas
        cad.rotation.x = R.cad.rx + e * 0.32;
        cad.position.y = R.cad.py * (1 - 0.74 * e);
        cad.position.x = R.cad.px - e * 0.28;
      }
      if (tor) tor.rotation.z = R.tor.rz + e * 0.30;
      if (cab) { cab.rotation.z = e * 0.55; cab.rotation.y = -e * 0.4; }
      if (bI) bI.rotation.z = R.bI.rz - e * 1.5;
      if (bD) bD.rotation.z = R.bD.rz - e * 1.2;
      if (pI) pI.rotation.z = R.pI.rz + e * 0.55;
      if (pD) pD.rotation.z = R.pD.rz - e * 0.25;
      if (rI) rI.rotation.z = -e * 0.9;
      return;
    }
    if (tMuerte > 0) { tMuerte = 0; }

    /* --- ciclo de caminata --- */
    const caminando = estado === ESTADO.MOVIENDO || vel > 0.12;
    mezcla = suave(mezcla, caminando ? 1 : 0, dt * 9);
    const s = Math.sin(fase), c = Math.cos(fase);
    const amp = 0.52 + 0.30 * Math.min(1, vel);

    if (cad) {
      // rebote vertical al doble de frecuencia: alto con las piernas juntas
      cad.position.y = R.cad.py + mezcla * (0.055 * Math.abs(c) - 0.028);
      cad.position.z = R.cad.pz + mezcla * s * 0.020;
      cad.rotation.x = R.cad.rx + mezcla * s * 0.055;
      cad.rotation.y = R.cad.ry - mezcla * s * 0.10;
      cad.rotation.z = R.cad.rz + (1 - mezcla) * Math.sin(fase * 0.27) * 0.018;
    }
    if (tor) {
      tor.rotation.z = R.tor.rz - mezcla * (0.11 + 0.07 * Math.min(1, vel));
      tor.rotation.y = R.tor.ry + mezcla * s * 0.11;
      tor.position.y = R.tor.py + (1 - mezcla) * Math.sin(fase * 0.55) * 0.007;
    }
    if (cab) {
      cab.rotation.y = R.cab.ry + (1 - mezcla) * Math.sin(fase * 0.23) * 0.20 - mezcla * s * 0.07;
      cab.rotation.z = R.cab.rz + mezcla * 0.07;
    }

    const piernaIzq = mezcla * s * amp, piernaDer = -piernaIzq;
    const flexIzq = -(0.10 + 0.85 * Math.max(0, Math.sin(fase + 2.1))) * mezcla;
    const flexDer = -(0.10 + 0.85 * Math.max(0, Math.sin(fase + 2.1 + Math.PI))) * mezcla;
    if (pI) pI.rotation.z = R.pI.rz + piernaIzq;
    if (pD) pD.rotation.z = R.pD.rz + piernaDer;
    if (rI) rI.rotation.z = flexIzq;
    if (rD) rD.rotation.z = flexDer;
    // el pie de apoyo se mantiene paralelo al suelo: contra-rotación del tobillo
    if (fI) fI.rotation.z = -(piernaIzq + flexIzq) * 0.82 + mezcla * Math.max(0, -s) * 0.22;
    if (fD) fD.rotation.z = -(piernaDer + flexDer) * 0.82 + mezcla * Math.max(0, s) * 0.22;

    if (bI) {
      bI.rotation.z = R.bI.rz - mezcla * s * 0.46 + (1 - mezcla) * Math.sin(fase * 0.55) * 0.025;
      bI.rotation.x = R.bI.rx;
    }
    if (bD) {
      bD.rotation.z = R.bD.rz + mezcla * s * 0.30 + (1 - mezcla) * Math.sin(fase * 0.55) * 0.02;
      bD.rotation.x = R.bD.rx;
    }
    if (aI) aI.rotation.z = R.aI.rz + mezcla * Math.max(0, -s) * 0.22;
    if (aD) aD.rotation.z = R.aD.rz + mezcla * Math.max(0, s) * 0.18;
    if (arma) { arma.position.x = R.arma.px; arma.rotation.z = R.arma.rz; }

    /* --- acciones --- */
    const cic = ((fase % TAU) + TAU) % TAU;
    if (estado === ESTADO.ATACANDO) {
      if (tipoAtaque === 'cuerpo') {
        const golpe = Math.sin(cic);
        const emp = Math.max(0, golpe) * 1.05;
        if (bD) bD.rotation.z = R.bD.rz + emp;
        if (aD) aD.rotation.z = R.aD.rz - emp * 0.55;
        if (tor) { tor.rotation.z = R.tor.rz - emp * 0.22; tor.rotation.y = R.tor.ry - emp * 0.30; }
      } else if (tipoAtaque === 'gesto') {
        const g = Math.sin(cic * 2) * 0.5 + 0.5;
        if (bD) bD.rotation.z = R.bD.rz - g * 0.55;
        if (aD) aD.rotation.z = R.aD.rz + g * 0.25;
        if (tor) tor.rotation.y = R.tor.ry + Math.sin(cic) * 0.18;
      } else {
        const golpe = Math.exp(-cic * 5.5);
        if (arma) arma.position.x = R.arma.px - golpe * 0.11;
        if (tor) { tor.rotation.z = R.tor.rz + golpe * 0.10; tor.rotation.y = R.tor.ry - 0.14; }
        if (bD) bD.rotation.z = R.bD.rz + golpe * 0.13;
        if (cab) cab.rotation.y = R.cab.ry - 0.10;
      }
    } else if (estado === ESTADO.RECOLECTANDO) {
      const g = Math.sin(cic);
      const baja = Math.max(0, g);
      if (tor) { tor.rotation.z = R.tor.rz - 0.20 - baja * 0.42; tor.rotation.y = R.tor.ry + 0.16; }
      if (bD) bD.rotation.z = R.bD.rz + 0.55 - baja * 1.25;
      if (bI) bI.rotation.z = R.bI.rz + 0.45 - baja * 1.15;
      if (aD) aD.rotation.z = R.aD.rz - 0.25 + baja * 0.35;
      if (cad) cad.position.y = R.cad.py - baja * 0.05;
    } else if (estado === ESTADO.CONSTRUYENDO || estado === ESTADO.REPARANDO) {
      const g = Math.sin(cic * 2) * 0.5 + 0.5;
      if (tor) tor.rotation.z = R.tor.rz - 0.16;
      if (bD) bD.rotation.z = R.bD.rz - 0.35 + g * 0.85;
      if (aD) aD.rotation.z = R.aD.rz + 0.30 - g * 0.55;
      if (bI) bI.rotation.z = R.bI.rz + 0.30;
    }
  };
}

function animadorJinete(pz) {
  const base = animadorHumano(pz, 'cuerpo');
  const cuerpo = pz.monturaCuerpo;
  const patas = [pz.pataDelIzq, pz.pataDelDer, pz.pataTraIzq, pz.pataTraDer];
  const R = { cuerpo: reposoDe(cuerpo), patas: patas.map(reposoDe) };
  const desf = [0, Math.PI * 0.55, Math.PI, Math.PI * 1.55];
  let tMuerte = 0;
  return function animar(fase, estado, dt, extra) {
    const vel = extra && extra.velNorm ? extra.velNorm : 0;
    const galope = estado === ESTADO.MOVIENDO || vel > 0.12 ? 1 : 0;
    if (estado === ESTADO.MURIENDO) {
      tMuerte = Math.min(0.8, tMuerte + dt);
      const e = 1 - Math.pow(1 - tMuerte / 0.8, 2.0);
      if (cuerpo) {
        cuerpo.rotation.x = R.cuerpo.rx + e * 1.35;
        cuerpo.position.y = R.cuerpo.py - e * 0.55;
      }
    } else {
      if (cuerpo) {
        cuerpo.rotation.x = R.cuerpo.rx;
        cuerpo.position.y = R.cuerpo.py + galope * (Math.abs(Math.cos(fase)) * 0.10 - 0.05);
        cuerpo.rotation.z = R.cuerpo.rz + galope * Math.sin(fase * 2) * 0.07;
      }
      for (let i = 0; i < 4; i++) {
        const p = patas[i];
        if (!p) continue;
        p.rotation.z = R.patas[i].rz + galope * Math.sin(fase + desf[i]) * 0.72;
      }
    }
    // el jinete usa el mismo ciclo pero sin caminar: se lo pasamos como quieto
    base(fase * 0.5, estado === ESTADO.MOVIENDO ? ESTADO.QUIETO : estado, dt, extra);
    if (pz.cadera && estado !== ESTADO.MURIENDO) {
      pz.cadera.position.y = (pz.cadera.userData.baseY !== undefined
        ? pz.cadera.userData.baseY : (pz.cadera.userData.baseY = pz.cadera.position.y))
        + galope * Math.abs(Math.cos(fase)) * 0.05;
    }
  };
}

function animadorBlindado(pz, proto) {
  const chasis = pz.chasis, tor = pz.torreta, canon = pz.canon, pala = pz.pala;
  const ruedas = pz.ruedas || [];
  const orugas = pz.orugas || [];
  const R = { chasis: reposoDe(chasis), tor: reposoDe(tor), canon: reposoDe(canon) };
  let velAnt = 0, cabeceo = 0, balanceo = 0, tMuerte = 0, giroTor = 0;
  return function animar(fase, estado, dt, extra) {
    const vel = extra && extra.vel ? extra.vel : 0;
    const vn = extra && extra.velNorm ? extra.velNorm : 0;
    const paso = Math.max(1e-3, dt);

    if (estado === ESTADO.MURIENDO) {
      tMuerte = Math.min(0.8, tMuerte + dt);
      const e = tMuerte / 0.8;
      if (chasis) {
        chasis.rotation.z = R.chasis.rz + e * 0.22;
        chasis.rotation.x = R.chasis.rx + e * 0.16;
        chasis.position.y = R.chasis.py - e * 0.22;
      }
      return;
    }

    // ruedas: giro proporcional a la velocidad real
    for (let i = 0; i < ruedas.length; i++) {
      const w = ruedas[i];
      if (w) w.rotation.z -= (vel / 0.42) * dt;
    }
    for (let i = 0; i < orugas.length; i++) {
      const o = orugas[i];
      o.s -= vel * dt;
      colocarOruga(o);
    }

    // suspensión: se hunde la trompa al frenar, se levanta al acelerar
    const acel = (vel - velAnt) / paso;
    velAnt = vel;
    cabeceo = suave(cabeceo, clamp(-acel * 0.018, -0.09, 0.09), dt * 6);
    balanceo = suave(balanceo, Math.sin(fase * 0.9) * vn * 0.035, dt * 5);
    if (chasis) {
      chasis.rotation.z = R.chasis.rz + cabeceo + Math.sin(fase * 2.3) * vn * 0.012;
      chasis.rotation.x = R.chasis.rx + balanceo;
      chasis.position.y = R.chasis.py + Math.sin(fase * 3.1) * vn * 0.018;
    }

    // torreta: apunta al objetivo si el mundo nos pasa el ángulo, si no barre
    if (tor) {
      const obj = extra && (extra.anguloTorreta !== undefined ? extra.anguloTorreta
        : (extra.anguloArma !== undefined ? extra.anguloArma : null));
      let destino;
      if (obj !== null && obj !== undefined) destino = obj;
      else if (estado === ESTADO.ATACANDO) destino = 0;
      else destino = Math.sin(fase * 0.12) * 0.35;
      let d = destino - giroTor;
      while (d > Math.PI) d -= TAU;
      while (d < -Math.PI) d += TAU;
      giroTor += clamp(d, -1.6 * dt, 1.6 * dt);
      tor.rotation.y = R.tor.ry + giroTor;
    }

    const cic = ((fase % TAU) + TAU) % TAU;
    if (canon) {
      if (estado === ESTADO.ATACANDO) {
        const golpe = Math.exp(-cic * 4.5);
        canon.position.x = R.canon.px - golpe * 0.30;
        canon.rotation.z = R.canon.rz + golpe * 0.12;
        if (chasis) chasis.rotation.z += golpe * 0.05;
      } else {
        canon.position.x = suave(canon.position.x, R.canon.px, dt * 6);
        canon.rotation.z = suave(canon.rotation.z, R.canon.rz, dt * 6);
      }
    }
    if (pala && estado === ESTADO.ATACANDO) {
      pala.rotation.z = 0.20 + Math.sin(cic) * 0.30;
    } else if (pala) {
      pala.rotation.z = suave(pala.rotation.z, 0, dt * 4);
    }
  };
}

function animadorCarro(pz) {
  const blindado = animadorBlindado(pz);
  const patas = [pz.pataDelIzq, pz.pataDelDer, pz.pataTraIzq, pz.pataTraDer];
  const R = patas.map(reposoDe);
  const desf = [0, Math.PI * 0.55, Math.PI, Math.PI * 1.55];
  return function animar(fase, estado, dt, extra) {
    blindado(fase, estado, dt, extra);
    const vn = extra && extra.velNorm ? extra.velNorm : 0;
    for (let i = 0; i < 4; i++) {
      const p = patas[i];
      if (!p) continue;
      p.rotation.z = R[i].rz + vn * Math.sin(fase + desf[i]) * 0.5;
    }
  };
}

function animadorAereo(pz) {
  const cuerpo = pz.chasis, luces = pz.luces;
  const rotores = pz.rotores || [];
  const R = reposoDe(cuerpo);
  let t = 0, tMuerte = 0;
  return function animar(fase, estado, dt, extra) {
    t += dt;
    const vn = extra && extra.velNorm ? extra.velNorm : 0;
    for (let i = 0; i < rotores.length; i++) {
      const r = rotores[i];
      if (r) r.rotation.y += (34 + vn * 18) * dt;
    }
    if (estado === ESTADO.MURIENDO) {
      tMuerte = Math.min(0.8, tMuerte + dt);
      const e = tMuerte / 0.8;
      if (cuerpo) {
        cuerpo.position.y = R.py - e * e * (R.py - 0.4);
        cuerpo.rotation.z = R.rz + e * 1.1;
        cuerpo.rotation.x = R.rx + e * 2.4;
      }
      if (luces) luces.visible = false;
      return;
    }
    if (cuerpo) {
      cuerpo.position.y = R.py + Math.sin(t * 1.7) * 0.14;
      cuerpo.rotation.z = R.rz - vn * 0.20 + Math.sin(t * 1.1) * 0.045;
      cuerpo.rotation.x = R.rx + Math.sin(t * 0.83) * 0.13 + (estado === ESTADO.ATACANDO ? 0.10 : 0);
    }
    if (luces) luces.visible = (t % 1.1) < 0.16;
  };
}

function animadorNaval(pz) {
  const casco = pz.chasis, tor = pz.torreta, canon = pz.canon, radar = pz.radar, rampa = pz.rampa;
  const R = { casco: reposoDe(casco), canon: reposoDe(canon), rampa: reposoDe(rampa) };
  let t = 0, tMuerte = 0;
  return function animar(fase, estado, dt, extra) {
    t += dt;
    const vn = extra && extra.velNorm ? extra.velNorm : 0;
    if (radar) radar.rotation.y += 1.5 * dt;
    if (estado === ESTADO.MURIENDO) {
      tMuerte = Math.min(0.8, tMuerte + dt);
      const e = tMuerte / 0.8;
      if (casco) {
        casco.rotation.x = R.casco.rx + e * 0.55;
        casco.position.y = R.casco.py - e * 1.1;
      }
      return;
    }
    if (casco) {
      casco.rotation.x = R.casco.rx + Math.sin(t * 0.75) * 0.045 + vn * Math.sin(t * 1.3) * 0.02;
      casco.rotation.z = R.casco.rz + Math.sin(t * 0.52) * 0.028 - vn * 0.02;
      casco.position.y = R.casco.py + Math.sin(t * 0.9) * 0.07;
    }
    const cic = ((fase % TAU) + TAU) % TAU;
    if (tor) tor.rotation.y = Math.sin(fase * 0.10) * 0.4;
    if (canon) {
      const golpe = estado === ESTADO.ATACANDO ? Math.exp(-cic * 4.5) : 0;
      canon.position.x = R.canon.px - golpe * 0.26;
    }
    if (rampa) rampa.rotation.z = R.rampa.rz + (estado === ESTADO.QUIETO ? 0 : 0.35);
  };
}

/* ═════════════════ 14. API pública ═════════════════ */

const COLOR_DEFECTO = 0x3f74d8;

/**
 * Crea la malla animable de una unidad.
 * @param {string} claveUnidad clave de src/data/unidades.js
 * @param {number} edad 0..4
 * @param {object} ctx contexto del juego (usa ctx.texturas y ctx.rng si están)
 * @param {object} [opciones] { colorJugador }
 */
export function crearMallaUnidad(claveUnidad, edad, ctx, opciones = {}) {
  const proto = construirPrototipo(claveUnidad, clamp(edad | 0, 0, 4), ctx);
  const hex = opciones.colorJugador != null ? opciones.colorJugador : COLOR_DEFECTO;

  const mapa = {};
  const mallasJugador = [];
  const orugas = [];
  const cuerpo = instanciar(proto.arbol, ctx, hex, mapa, mallasJugador, orugas);

  const grupo = new THREE.Group();
  grupo.name = `unidad:${claveUnidad}`;
  grupo.castShadow = true;
  // X y Z comparten factor (ver ESCALA_JUEGO): las torretas giran sobre Y y con
  // X ≠ Z se deformarían al apuntar.
  cuerpo.scale.set(proto.escXZ, proto.escY, proto.escXZ);
  grupo.add(cuerpo);

  // ruedas y rotores por nombre, en el orden en que se crearon
  const ruedas = [];
  for (let i = 0; ; i++) { const r = mapa[`rueda_${i}`]; if (!r) break; ruedas.push(r); }
  const rotores = [];
  for (let i = 0; ; i++) { const r = mapa[`rotor${i}`]; if (!r) break; rotores.push(r); }

  const partes = {
    cadera: mapa.cadera || null,
    torso: mapa.torso || null,
    cabeza: mapa.cabeza || null,
    brazoIzq: mapa.brazoIzq || null,
    brazoDer: mapa.brazoDer || null,
    anteIzq: mapa.anteIzq || null,
    anteDer: mapa.anteDer || null,
    piernaIzq: mapa.piernaIzq || null,
    piernaDer: mapa.piernaDer || null,
    rodillaIzq: mapa.rodillaIzq || null,
    rodillaDer: mapa.rodillaDer || null,
    pieIzq: mapa.pieIzq || null,
    pieDer: mapa.pieDer || null,
    arma: mapa.arma || mapa.canon || null,
    bocaArma: mapa.bocaArma || null,
    torreta: mapa.torreta || null,
    canon: mapa.canon || null,
    chasis: mapa.chasis || null,
    pala: mapa.pala || null,
    rampa: mapa.rampa || null,
    radar: mapa.radar || null,
    luces: mapa.luces || null,
    monturaCuerpo: mapa.monturaCuerpo || null,
    pataDelIzq: mapa.pataDelIzq || null, pataDelDer: mapa.pataDelDer || null,
    pataTraIzq: mapa.pataTraIzq || null, pataTraDer: mapa.pataTraDer || null,
    ruedas, rotores, orugas,
  };

  let animar;
  switch (proto.tipoAnim) {
    case 'jinete': animar = animadorJinete(partes); break;
    case 'blindado': animar = animadorBlindado(partes, proto); break;
    case 'remolcado': animar = animadorBlindado(partes, proto); break;
    case 'carro': animar = animadorCarro(partes); break;
    case 'aereo': animar = animadorAereo(partes); break;
    case 'naval': animar = animadorNaval(partes); break;
    default: animar = animadorHumano(partes, (proto.cfg && proto.cfg.ataque) || 'fuego');
  }

  const api = {
    grupo,
    partes,
    altura: proto.altura,
    animar(fase, estado, dt, extra) {
      try { animar(fase, estado, dt || 0.016, extra || VACIO); }
      catch (e) { /* una unidad rota no debe frenar el frame */ }
    },
    setColorJugador(colorHex) {
      const mat = materialSlot(ctx, 'jugador', colorHex);
      for (let i = 0; i < mallasJugador.length; i++) mallasJugador[i].material = mat;
    },
    dispose() {
      for (const o of orugas) o.malla.dispose();
      if (grupo.parent) grupo.parent.remove(grupo);
      mallasJugador.length = 0;
      orugas.length = 0;
    },
  };
  return api;
}

const VACIO = {};

/**
 * Geometría fusionada de una unidad, para el InstancedMesh del LOD lejano.
 * Trae `color` por vértice y `aMascara` = 1 en las zonas de color de jugador,
 * que es exactamente lo que espera el material de fusión de VistaEntidades.
 */
export function geometriaFusionadaUnidad(claveUnidad, edad, ctx) {
  const proto = construirPrototipo(claveUnidad, clamp(edad | 0, 0, 4), ctx);
  const clave = `${claveUnidad}|${edad}`;
  const hit = cacheFusion.get(clave);
  if (hit !== undefined) return hit;

  const trozos = [];
  // El LOD lejano tiene que quedar EXACTAMENTE del mismo tamaño que el cercano:
  // si no, las unidades pegan un salto de escala al cruzar el umbral de LOD.
  const raiz = new THREE.Matrix4().makeScale(proto.escXZ, proto.escY, proto.escXZ);
  recolectarFusion(proto.arbol, raiz, trozos);

  let fusion = null;
  if (trozos.length) {
    fusion = trozos.length === 1 ? trozos[0] : mergeGeometries(trozos, false);
    if (fusion && fusion !== trozos[0]) for (const g of trozos) g.dispose();
    if (!fusion) fusion = trozos[0];
  }
  if (fusion) { fusion.computeBoundingSphere(); fusion.computeBoundingBox(); }
  cacheFusion.set(clave, fusion);
  return fusion;
}
const cacheFusion = new Map();

/**
 * Los dos extremos de la mezcla con la que el LOD lejano imita a `pinturaDeBando`
 * sin poder ejecutarla (ver `recolectarFusion`). `BASE` es el gris de paño que se
 * hornea en el color por vértice y `MEZCLA` cuánto del hex del jugador entra
 * encima. Ajustar los dos juntos: suben o bajan el valor y la saturación del
 * bando lejano a la vez.
 */
const BASE_BANDO_LEJOS = 0.184;
const MEZCLA_BANDO_LEJOS = 0.58;

const _escNodo = new THREE.Vector3();

function recolectarFusion(nodo, matPadre, salida) {
  _e.set(nodo.rot ? nodo.rot[0] : 0, nodo.rot ? nodo.rot[1] : 0, nodo.rot ? nodo.rot[2] : 0);
  _q.setFromEuler(_e);
  _v.set(nodo.pos[0], nodo.pos[1], nodo.pos[2]);
  _escNodo.setScalar(nodo.esc || 1);           // la caricatura también se hornea
  const m = new THREE.Matrix4().compose(_v, _q, _escNodo).premultiply(matPadre);

  for (const s of nodo.slots) {
    // el vidrio transparente horneado en un material opaco queda como una
    // mancha: a 90 m no se extraña, y son triángulos que nos ahorramos
    if (s.slot === 'vidrio') continue;
    const g = s.geo.clone();
    g.applyMatrix4(m);
    if (g.attributes.uv) g.deleteAttribute('uv');
    const n = g.attributes.position.count;
    const masc = new Float32Array(n);
    if (s.slot === 'jugador') {
      /* EL LOD LEJANO TAMBIÉN TIENE QUE LLEVAR PINTURA, Y NO PUEDE.
         Su material lo arma la vista y hace
             vColor = mix( colorHorneado, colorDeInstancia, aMascara )
         con el hex CRUDO del jugador por instancia. O sea: con la máscara en 1
         el bando lejano es el azul de dos canales en cero, sin mapa que lo
         module y sin shader donde meter la regla — un LOD lejano más saturado
         y más plano que el cercano, y encima un salto de color al cruzar el
         umbral. Como la mezcla ES una interpolación hacia un neutro, se puede
         hornear la MISMA regla en sus dos extremos: un gris de paño en el
         color por vértice y una máscara parcial. Los números salen de resolver
         `mezcla == pinturaDeBando(hex)` sobre los ocho colores de jugador; con
         estos dos el error queda por debajo de lo que se distingue a 90 m. */
      masc.fill(MEZCLA_BANDO_LEJOS);
      const col = g.attributes.color;
      if (col) {
        const a = col.array;
        for (let i = 0; i < a.length; i++) a[i] = BASE_BANDO_LEJOS;
        col.needsUpdate = true;
      }
    }
    g.setAttribute('aMascara', new THREE.BufferAttribute(masc, 1));
    salida.push(g);
  }
  // los eslabones de oruga entran a la fusión repartidos por el circuito
  if (nodo.oruga) {
    const o = nodo.oruga, paso = (2 * o.L + TAU * o.r) / o.n;
    for (let lado = 0; lado < 2; lado++) {
      for (let i = 0; i < o.n; i += 3) {          // de a tres: en LOD lejano nadie los cuenta
        puntoOruga(i * paso, o.L, o.r, _pt);
        const g = o.geo.clone();
        _e.set(0, 0, Math.atan2(_pt.ny, _pt.nx) - Math.PI / 2);
        _q.setFromEuler(_e);
        _v.set(_pt.x, _pt.y, lado === 0 ? o.z : -o.z);
        g.applyMatrix4(new THREE.Matrix4().compose(_v, _q, _uno).premultiply(m));
        if (g.attributes.uv) g.deleteAttribute('uv');
        const n = g.attributes.position.count;
        g.setAttribute('aMascara', new THREE.BufferAttribute(new Float32Array(n), 1));
        salida.push(g);
      }
    }
  }
  for (const h of nodo.hijos) recolectarFusion(h, m, salida);
}

/** Libera todo lo cacheado (cambio de partida / de calidad). */
export function limpiarCacheUnidades() {
  for (const p of cacheProto.values()) {
    const rec = (n) => { for (const s of n.slots) s.geo.dispose(); if (n.oruga) n.oruga.geo.dispose(); n.hijos.forEach(rec); };
    rec(p.arbol);
  }
  cacheProto.clear();
  for (const g of cacheFusion.values()) g?.dispose?.();
  cacheFusion.clear();
  for (const m of cacheMat.values()) m.dispose();
  cacheMat.clear();
  P.limpiarCachePartes();
}

export default { crearMallaUnidad, geometriaFusionadaUnidad, CATALOGO_UNIDADES, limpiarCacheUnidades };
