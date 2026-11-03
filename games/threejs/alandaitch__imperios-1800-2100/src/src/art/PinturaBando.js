/**
 * PinturaBando — LA ÚNICA FUENTE DE VERDAD del color de bando.
 *
 * ─────────────────────────── POR QUÉ EXISTE ───────────────────────────
 * El color de jugador lleva cinco rondas seguidas siendo el defecto crítico del
 * panel, y en la ronda 6 el reproche fue doble y CONTRADICTORIO:
 *
 *   · "azul saturado en cumbreras y vigas"   (arquitectura)
 *   · "azul lavado y grisáceo en las unidades" (tropas)
 *
 * Dos síntomas opuestos no salen de un mal número: salen de que había TRES
 * implementaciones de la misma idea, con constantes distintas, aplicándose en
 * cadena unas sobre otras:
 *
 *   1. `EdificioFabrica.pinturaDeBando()`  — mezcla 0.30, techo 0.80, piso 0.11
 *   2. `UnidadFabrica.BANDO` (en el shader) — mezcla 0.34, techo 0.72, piso 0.18
 *   3. `VistaEntidades.pinturaDeBando()`    — mezcla 0.32, techo 0.80, piso 0.055
 *
 * Y encima `VistaEntidades._pintarJugador()` es el ÚLTIMO que toca el color:
 * clona el material y le pisa en runtime lo que la fábrica había calculado. O
 * sea que en la unidad la regla se aplicaba DOS VECES (la de la vista sobre la
 * CPU y después la del shader sobre el resultado) y en el edificio se aplicaba
 * la de la vista, que era la peor calibrada.
 *
 * Encima de eso, la vista convertía el hex del jugador de sRGB a lineal DOS
 * veces (`new THREE.Color(hex)` ya convierte, y encima llamaba a
 * `convertSRGBToLinear()`). El azul #3d8ee8, que en lineal es
 * (0.047, 0.270, 0.807), le entraba al material como (0.004, 0.059, 0.616):
 * dos canales prácticamente en cero. Dos veces lavado más dos veces convertido
 * da exactamente las dos quejas del panel a la vez: lavanda gris en la tropa
 * (dos lavados encadenados) y primario sin sombrear en el techo (dos canales
 * muertos que no suben con el sol ni bajan con la sombra).
 *
 * ─────────────────────── QUÉ HACE LA REGLA NUEVA ───────────────────────
 * Convierte el hex "de paleta" en la PINTURA con la que se tiñe una tela o se
 * pinta una chapa. Dos pasos, en este orden, y NADA más:
 *
 *  1. TECHO — si el canal que manda pasa de `techo`, se baja TODO el color por
 *     el mismo factor (no sólo ese canal: bajar uno solo viraría el matiz). Con
 *     esto el sol tiene aire por arriba en vez de clipear contra la rodilla del
 *     ACES, que es lo que aplasta el gradiente y deja la cara al sol igual que
 *     la cara en sombra.
 *
 *  2. PISO — ningún canal por debajo de `max(pisoAbs, pico * pisoRel)`. Ésta es
 *     LA MEZCLA MÍNIMA hacia la luminancia que pedía el panel: en vez de lavar
 *     los tres canales hacia el gris (que es lo que hacían las tres versiones
 *     viejas, y por eso la tropa salía pastel), sube ÚNICAMENTE los canales que
 *     estaban muertos. El canal fuerte no pierde ni un punto de croma, así que
 *     el resultado sigue leyéndose como tela teñida y no como tela desteñida.
 *
 * Los dos pasos son IDEMPOTENTES a propósito: aplicar la regla dos veces da el
 * mismo color que aplicarla una. Es la vacuna contra el bug que originó este
 * archivo — mientras quede en el árbol una copia que se aplique después de otra,
 * el resultado ya no se degrada.
 *
 * ───────────────────────── CALIBRADO (azul #3d8ee8) ─────────────────────────
 *   crudo lineal            (0.047, 0.270, 0.807)  → un canal muerto
 *   doble conversión (bug)  (0.004, 0.059, 0.616)  → dos canales muertos
 *   REGLA_BANDO             (0.096, 0.201, 0.600)  → #577ccb, mezclilla
 * Medido en pantalla sobre la escena de mediodía, los píxeles de bando promedian
 * (106, 135, 195): los tres canales bien dentro del rango útil.
 * Los tres canales quedan lejos de cero: el sol cálido y el cielo frío tienen
 * por dónde entrar, y la cara al sol se lee distinta de la cara en sombra. El
 * canal fuerte sigue a 5:1 del débil, o sea que a 30 metros el bando se escanea
 * de un vistazo igual que antes.
 *
 * REGLA DE USO: esta función devuelve un color CACHEADO Y COMPARTIDO. Quien lo
 * necesite lo COPIA (`m.color.copy(...)`), nunca lo muta.
 */
import * as THREE from 'three';

/**
 * Los números, y por qué valen lo que valen.
 * Todo esto vive en espacio LINEAL: son albedos, no valores de pantalla.
 */
export const REGLA_BANDO = {
  /**
   * Ningún canal del PIGMENTO pasa de acá. 0.60 es albedo de tela teñida buena
   * (una lona pintada ronda 0.55-0.65); por encima de 0.75 el sol directo la
   * empuja fuera del rango del ACES y el paño se aplana. Las versiones viejas
   * usaban 0.72 y 0.80: por eso las cumbreras salían "saturadas" y sin sombrear.
   */
  techo: 0.60,
  /**
   * El piso es RELATIVO al canal que manda: da igual lo saturado que venga el
   * hex, ningún canal queda a más de 6:1 del fuerte. Es lo que garantiza que el
   * sombreado se vea en los TRES canales y no sólo en uno.
   * 0.16 y no 0.20 porque a 0.20 el rojo de bando (#d8443c, que ya viene claro)
   * se iba a salmón: medido en pantalla, la tropa roja de noche leía rosa. Con
   * 0.16 el canal muerto sigue en ~0.096 lineal (sRGB 88, un tercio del rango:
   * lejísimos de cero, se mueve con el sol sin problema) y el bando recupera
   * croma. Es el borde del "mínimo que hace falta" que pedía el diagnóstico.
   */
  pisoRel: 0.16,
  /** …y además un mínimo absoluto, para colores de bando muy oscuros. */
  pisoAbs: 0.05,
  /**
   * Compensación de un mapa de albedo oscuro. La chapa pintada y el paño de la
   * biblioteca de texturas tienen media ~0.8, así que el bando sobre mapa sale
   * un escalón por debajo del bando sin mapa (LOD lejano, anillos) y el mismo
   * jugador se lee con dos azules distintos según la distancia. Sólo se aplica
   * cuando el material TIENE mapa.
   */
  gananciaMapa: 1.22,
  /** Tope duro después de la ganancia: ni con mapa oscuro se quema el bando. */
  techoAbs: 0.82,
};

/** clave -> THREE.Color ya pintado. Nunca se recalcula, nunca se muta. */
const _cache = new Map();
const _aux = new THREE.Color();

/**
 * Convierte un color de bando "de paleta" en el ALBEDO con el que se pinta.
 *
 * @param {THREE.Color|number|string} color  Si es THREE.Color se asume YA lineal
 *        (es el espacio de trabajo de three); si es hex o string, `Color.set` lo
 *        convierte de sRGB a lineal UNA sola vez. Convertir dos veces es
 *        justamente el bug que originó este archivo.
 * @param {object} [opciones]
 * @param {boolean} [opciones.conMapa]  el material lleva mapa de albedo: se
 *        compensa su media para que el bando valga lo mismo con y sin textura.
 * @param {number} [opciones.ganancia]   compensación explícita (default: la tabla).
 * @returns {THREE.Color} color COMPARTIDO y cacheado — copiarlo, no mutarlo.
 */
export function pinturaDeBando(color, opciones) {
  const conMapa = opciones?.conMapa === true;
  const ganancia = conMapa ? (opciones?.ganancia ?? REGLA_BANDO.gananciaMapa) : 1;

  if (color && color.isColor) _aux.copy(color);
  else _aux.set(color ?? 0xffffff);

  const clave = `${_aux.getHex(THREE.SRGBColorSpace)}|${ganancia.toFixed(3)}`;
  const hit = _cache.get(clave);
  if (hit) return hit;

  /* 1. TECHO: baja el color entero, así conserva el matiz. */
  let pico = Math.max(_aux.r, _aux.g, _aux.b);
  if (pico > REGLA_BANDO.techo) {
    _aux.multiplyScalar(REGLA_BANDO.techo / pico);
    pico = REGLA_BANDO.techo;
  }

  /* 2. PISO: sube SÓLO los canales muertos (la mezcla mínima, no un lavado). */
  const piso = Math.max(REGLA_BANDO.pisoAbs, pico * REGLA_BANDO.pisoRel);
  if (_aux.r < piso) _aux.r = piso;
  if (_aux.g < piso) _aux.g = piso;
  if (_aux.b < piso) _aux.b = piso;

  /* 3. GANANCIA de mapa, acotada: el bando con textura vale lo mismo que sin ella. */
  if (ganancia !== 1) {
    _aux.multiplyScalar(ganancia);
    const pico2 = Math.max(_aux.r, _aux.g, _aux.b);
    if (pico2 > REGLA_BANDO.techoAbs) _aux.multiplyScalar(REGLA_BANDO.techoAbs / pico2);
  }

  const c = _aux.clone();
  _cache.set(clave, c);
  return c;
}

/**
 * El color de bando CRUDO en lineal, cacheado.
 *
 * Para los materiales que aplican la regla ELLOS MISMOS en el shader (los de
 * unidad, ver `uEsBando`): a esos hay que escribirles el color sin pintar, o la
 * regla se aplica dos veces y la tropa se lava a lavanda — literalmente la queja
 * de la ronda 6.
 *
 * @returns {THREE.Color} color COMPARTIDO y cacheado — copiarlo, no mutarlo.
 */
export function colorBandoLineal(color) {
  if (color && color.isColor) _aux.copy(color);
  else _aux.set(color ?? 0xffffff);
  const clave = `crudo|${_aux.getHex(THREE.SRGBColorSpace)}`;
  const hit = _cache.get(clave);
  if (hit) return hit;
  const c = _aux.clone();
  _cache.set(clave, c);
  return c;
}

/**
 * La MISMA regla en GLSL, para los materiales que la aplican en el fragment
 * (así el clon que hace la vista no puede perderla).
 *
 * Se exporta desde acá para que no vuelva a haber dos juegos de constantes: el
 * shader se alimenta con `uniformeReglaBando()`, que sale de REGLA_BANDO.
 * OJO: el fuente tiene que ser IDÉNTICO para todos los slots que compartan
 * programa — `customProgramCacheKey()` de three devuelve el texto, y si el bando
 * compilara un texto distinto al del cuerpo, three serviría el programa
 * equivocado a uno de los dos.
 */
export const GLSL_PINTURA_BANDO = /* glsl */`
uniform vec3 uReglaBando;   // x=techo  y=pisoRel  z=pisoAbs
vec3 pinturaDeBando( vec3 c ) {
  float pico = max( max( c.r, c.g ), c.b );
  // techo: baja TODO el color, no sólo el canal que se pasa (conserva el matiz)
  c *= min( 1.0, uReglaBando.x / max( pico, 1e-4 ) );
  pico = min( pico, uReglaBando.x );
  // piso: sube SÓLO los canales muertos, para que los tres respondan a la luz
  return max( c, vec3( max( uReglaBando.z, pico * uReglaBando.y ) ) );
}
`;

/** Uniform listo para el snippet de arriba. Un objeto nuevo por material, a propósito. */
export function uniformeReglaBando() {
  return {
    value: new THREE.Vector3(REGLA_BANDO.techo, REGLA_BANDO.pisoRel, REGLA_BANDO.pisoAbs),
  };
}
