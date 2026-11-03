/**
 * VistaEntidades — el puente entre la simulación (World, 20 Hz) y el render (60+ fps).
 *
 * Responsabilidades:
 *  · mantiene el mapeo  id de entidad -> representación 3D
 *  · interpola posición y rotación entre el tick anterior y el actual (alfa)
 *  · elige el nivel de detalle: malla animada de cerca, InstancedMesh de lejos
 *  · anima con la fase proporcional a la velocidad REAL de cada unidad
 *  · dibuja anillos de selección, anillos de bando, barras de vida, fantasmas
 *  · atenúa los edificios propios que tapan a las unidades seleccionadas
 *
 * Reglas de rendimiento que se respetan a rajatabla:
 *  · cero asignaciones de objetos por entidad y por tick (buffers reusados)
 *  · cero materiales o geometrías creadas por frame (todo cacheado por clave|edad|jugador)
 *  · frustum culling propio: lo que no se ve, no se anima
 *  · una sola llamada de dibujo por tipo de unidad lejana
 *
 * ══════════════════ EL COLOR DE BANDO SE DECIDE ACÁ ══════════════════
 * `_pintarJugador()` es EL ÚLTIMO que toca el color de jugador: clona el
 * material que devolvió la fábrica y le escribe el color encima, así que lo que
 * hayan calculado EdificioFabrica o UnidadFabrica se pierde si acá se aplica
 * otra regla. Por eso esta clase NO tiene su propia versión de la pintura: la
 * importa de `art/PinturaBando.js`, que es la única fuente de verdad.
 *
 * La sutileza que costó cinco rondas: hay materiales que aplican la regla ELLOS
 * MISMOS en el fragment shader (los de unidad, bandera `esBando`). A ésos hay
 * que escribirles el color CRUDO; si les escribiéramos el ya pintado, la regla
 * se aplicaría dos veces y la tropa saldría lavanda gris — que es textualmente
 * lo que reportó el panel ("azul lavado y grisáceo en las unidades") mientras al
 * mismo tiempo veía las cumbreras saturadas, que es el otro extremo del mismo
 * bug. Ver `_pintarJugador`.
 */
import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';
import { ORDEN } from '../core/Ctx.js';
import { TIPO, ESTADO } from '../core/World.js';
import { bus as busGlobal } from '../core/EventBus.js';
import { clamp } from '../core/RNG.js';
import { UNIDADES } from '../data/unidades.js';
import { EDIFICIOS } from '../data/edificios.js';
import { NODOS } from '../data/recursos.js';
import { COLORES_JUGADOR } from '../data/civilizaciones.js';
import { pinturaDeBando } from '../art/PinturaBando.js';
import { uniformesCielo } from './Cielo.js';
import * as FabricaUnidad from '../art/UnidadFabrica.js';
import * as FabricaEdificio from '../art/EdificioFabrica.js';
import * as FabricaNaturaleza from '../art/NaturalezaFabrica.js';

/* ------------------------------------------------------------------ */
/* Constantes de ajuste                                                */
/* ------------------------------------------------------------------ */
const TAU = Math.PI * 2;
/** Histéresis del cambio de nivel de detalle: sin esto, parpadea en el borde. */
const D_CERCA = 58, D_LEJOS = 68;
const D_CERCA2 = D_CERCA * D_CERCA, D_LEJOS2 = D_LEJOS * D_LEJOS;
/** Más allá de esto ni barras ni anillos: no se leerían igual. */
const D_UI2 = 190 * 190;
/** Zancada media en metros: define cuántos pasos por metro da una unidad. */
const ZANCADA = 1.55;
const ALTURA_VUELO = 9.5;
/** Cuántas mallas completas se pueden construir en un mismo frame (anti-tirón). */
const ALTAS_POR_FRAME = 3;
const MAX_BARRAS = 420;
const MAX_ANILLOS = 320;
const VERTS_POR_BARRA = 12;

/**
 * ANILLO DE BANDO. El panel dijo que el color de jugador "decora edificios en
 * vez de marcar tropas": es cierto, las zonas grandes de bando están todas en la
 * arquitectura y una unidad a 40 metros son doce píxeles de paño. Este anillo
 * pone el color del jugador PEGADO AL SUELO bajo cada unidad, que es lo que
 * permite escanear el campo por color y encontrar a los tuyos sin leer siluetas.
 * De paso resuelve la otra mitad del diagnóstico —contraste local y separación
 * figura-fondo—: el anillo mete un borde cromático y una sombra de contacto
 * justo en el punto donde la unidad toca el pasto, que es donde el ojo decide si
 * algo está apoyado o flotando.
 * Tope alto porque son 200+ unidades y una sola llamada de dibujo.
 */
const MAX_ANILLOS_BANDO = 640;
/** Más lejos que esto el anillo es sub-píxel: no aporta y gasta relleno. */
const D_BANDO2 = 240 * 240;

const CLAVES_ANIMAL = new Set(['ciervo', 'jabali', 'pez']);
const CLAVES_FOLIAJE = new Set(['arbol_pino', 'arbol_roble', 'arbol_palmera', 'baya']);
const RE_JUGADOR = /jugador|equipo|bandera|estandarte|banda|insignia|penacho/i;

/* Temporales globales: se reusan, nunca se asignan por entidad. */
const _matProy = new THREE.Matrix4();
const _frustum = new THREE.Frustum();
const _esfera = new THREE.Sphere();
const _caja = new THREE.Box3();
const _color = new THREE.Color();
const _color2 = new THREE.Color();
const _v3 = new THREE.Vector3();

const lerpNum = (a, b, t) => a + (b - a) * t;

/** Interpolación angular por el arco corto: sin esto los giros pegan latigazos. */
function lerpAngulo(a, b, t) {
  let d = b - a;
  d = ((d + Math.PI) % TAU + TAU) % TAU - Math.PI;
  return a + d * t;
}

/** Escribe una matriz de yaw + escala uniforme directo en el buffer de instancias. */
function escribirMatriz(a, o, x, y, z, rot, s) {
  const c = Math.cos(rot) * s, sn = Math.sin(rot) * s;
  a[o] = c;      a[o + 1] = 0;  a[o + 2] = -sn; a[o + 3] = 0;
  a[o + 4] = 0;  a[o + 5] = s;  a[o + 6] = 0;   a[o + 7] = 0;
  a[o + 8] = sn; a[o + 9] = 0;  a[o + 10] = c;  a[o + 11] = 0;
  a[o + 12] = x; a[o + 13] = y; a[o + 14] = z;  a[o + 15] = 1;
}

/* ------------------------------------------------------------------ */
/* Sombreador del anillo de selección                                  */
/* ------------------------------------------------------------------ */
const VS_ANILLO = /* glsl */`
  #include <common>
  attribute float aAng;    // 0..1 alrededor del anillo
  attribute float aBorde;  // 0 interior · 0.5 medio · 1 exterior
  attribute float aVida;   // instanciado: fracción de vida
  varying float vAng, vBorde, vVida;
  varying vec3 vCol;
  void main() {
    vAng = aAng; vBorde = aBorde; vVida = aVida;
    #ifdef USE_INSTANCING_COLOR
      vCol = instanceColor;
    #else
      vCol = vec3(1.0);
    #endif
    vec4 p = vec4(position, 1.0);
    #ifdef USE_INSTANCING
      p = instanceMatrix * p;
    #endif
    gl_Position = projectionMatrix * modelViewMatrix * p;
  }
`;

const FS_ANILLO = /* glsl */`
  varying float vAng, vBorde, vVida;
  varying vec3 vCol;
  void main() {
    // el arco de vida arranca al frente y avanza en sentido horario
    float enArco = step(vAng, vVida);
    // perfil radial suave: anillo fino, sin escalones
    float radial = smoothstep(0.0, 0.30, vBorde) * (1.0 - smoothstep(0.70, 1.0, vBorde));
    float a = mix(0.30, 1.0, enArco) * radial;
    vec3 c = mix(vCol * 0.42, vCol * 1.30 + 0.10, enArco);
    if (a < 0.01) discard;
    gl_FragColor = vec4(c, a * 0.95);
  }
`;

/* ------------------------------------------------------------------ */
/* Sombreador del anillo de bando                                      */
/* ------------------------------------------------------------------ */
const VS_BANDO = /* glsl */`
  #include <common>
  attribute float aRad;    // radio normalizado 0..1
  varying float vRad;
  varying vec3 vCol;
  void main() {
    vRad = aRad;
    #ifdef USE_INSTANCING_COLOR
      vCol = instanceColor;
    #else
      vCol = vec3(1.0);
    #endif
    vec4 p = vec4(position, 1.0);
    #ifdef USE_INSTANCING
      p = instanceMatrix * p;
    #endif
    gl_Position = projectionMatrix * modelViewMatrix * p;
  }
`;

/**
 * Dos capas en un solo fragmento, sin un segundo draw call:
 *
 *  · SOMBRA DE CONTACTO (radio 0 → 0.55): oscurece el suelo bajo la unidad. Es
 *    lo que la despega del fondo. La sombra del sol es direccional y a mediodía
 *    cae casi debajo, pero es blanda y no marca el punto de apoyo; ésta sí.
 *  · BANDA DE BANDO (radio 0.60 → 0.92): el color del jugador.
 *  · FILO OSCURO (radio 0.86 → 1.0): un hilo negro por fuera de la banda.
 *
 * Las tres capas NO se solapan de más, a propósito. En la primera versión la
 * sombra y la banda se pisaban, y en la zona común la división por el alfa
 * combinado desaturaba el color: el conjunto salía como un halo gris claro en
 * vez de un anillo de color, o sea el mismo defecto que estamos arreglando pero
 * en el suelo.
 *
 * El FILO existe porque el anillo tiene que leerse sobre pasto oscuro Y sobre
 * arena quemada. Medido en las dos: sobre suelo oscuro trabaja el color, sobre
 * suelo claro el color solo se lava y lo que separa es el hilo negro. Un anillo
 * que sólo funciona en la mitad de los biomas no marca nada.
 *
 * `uGanancia` sube el color por encima del valor del suelo: un anillo que vale
 * lo mismo que el terreno se lee como suciedad, no como marca. Aun así queda MUY
 * por debajo del anillo de selección (que usa el color crudo, ganancia 1.3 y
 * alfa 0.95, y encima lleva el arco de vida): no hay forma de confundirlos.
 *
 * El color se multiplica por la luz dominante de Cielo.js: de noche el anillo
 * baja y se enfría con la escena en vez de quedar como una calcomanía brillante.
 * `uPisoLuz` es lo mínimo que conserva, porque una tropa que no se encuentra de
 * noche es un bug, no una decisión artística.
 */
const FS_BANDO = /* glsl */`
  uniform vec3 uColorLuz;
  uniform float uPisoLuz;
  uniform float uGanancia;
  varying float vRad;
  varying vec3 vCol;
  void main() {
    float sombra = (1.0 - smoothstep(0.05, 0.55, vRad)) * 0.24;
    float banda = smoothstep(0.60, 0.72, vRad) * (1.0 - smoothstep(0.84, 0.92, vRad)) * 0.60;
    float filo = smoothstep(0.86, 0.93, vRad) * (1.0 - smoothstep(0.97, 1.0, vRad)) * 0.30;
    float a = min(1.0, sombra + banda + filo);
    if (a < 0.006) discard;
    // nivel de luz de la escena, con piso: chroma del cielo, sin apagarse nunca
    float lum = dot(uColorLuz, vec3(0.2126, 0.7152, 0.0722));
    vec3 luz = uColorLuz / max(lum, 1e-3) * mix(uPisoLuz, 1.0, clamp(lum, 0.0, 1.0));
    // composición source-over de las tres capas: sombra y filo aportan color 0
    gl_FragColor = vec4(vCol * luz * uGanancia * (banda / a), a);
  }
`;

/* ------------------------------------------------------------------ */

export class VistaEntidades {
  constructor(ctx) {
    this.nombre = 'vista';
    this.orden = ORDEN.VISTA;
    this.ctx = ctx;
    this.bus = ctx?.bus ?? busGlobal;

    /** id -> registro */
    this.registros = new Map();
    /** los mismos registros en un array plano: iterar un array es mucho más rápido */
    this.lista = [];

    this.seleccion = new Set();
    this.altPulsado = false;

    this._tiempo = 0;
    this._tOclusion = 0;
    this._tFantasmas = 0;
    this._presupuesto = ALTAS_POR_FRAME;
    this._cola = [];          // registros esperando su malla completa
    this._moribundos = [];

    /* --- cachés (nunca se crean recursos por frame) --- */
    this._matCache = new Map();      // clave -> Material
    this._geoCache = new Map();      // clave -> BufferGeometry
    this._lotes = new Map();         // 'clave|edad' -> lote instanciado
    this._altoCache = new Map();     // 'clave|edad' -> altura en metros
    /**
     * Colores de bando en LINEAL, convertidos UNA sola vez.
     *
     * `new THREE.Color('#3d8ee8')` ya hace sRGB → lineal (ColorManagement está
     * activo). Acá se llamaba además a `convertSRGBToLinear()`, o sea que el
     * azul entraba a los materiales como (0.004, 0.059, 0.616) en vez de
     * (0.047, 0.270, 0.807): dos canales prácticamente en cero. Un canal en cero
     * no sube con el sol ni baja con la sombra, y ninguna regla de pintura
     * aplicada después puede devolver una información que ya se perdió.
     */
    this._colores = COLORES_JUGADOR.map((h) => new THREE.Color(h));
    this._colorNeutro = new THREE.Color(0xffffff);
    /* Pintura ya resuelta por jugador: la regla se evalúa 8 veces al arrancar y
       nunca más. Índice `length` = neutro (gaia). */
    this._pinturas = this._colores.map((c) => pinturaDeBando(c));
    this._pinturas.push(pinturaDeBando(this._colorNeutro));
    /* Variante para materiales CON mapa de albedo (ver REGLA_BANDO.gananciaMapa). */
    this._pinturasMapa = this._colores.map((c) => pinturaDeBando(c, { conMapa: true }));
    this._pinturasMapa.push(pinturaDeBando(this._colorNeutro, { conMapa: true }));

    /* --- raíces de escena --- */
    this.raiz = new THREE.Group();
    this.raiz.name = 'entidades';
    this.raiz.matrixAutoUpdate = false;
    this.raizInstancias = new THREE.Group();
    this.raizInstancias.name = 'entidades-lod';
    this.raizInstancias.matrixAutoUpdate = false;
    this.raizFantasmas = new THREE.Group();
    this.raizFantasmas.name = 'fantasmas';
    this.raizFantasmas.matrixAutoUpdate = false;
    ctx?.escena?.add(this.raiz, this.raizInstancias, this.raizFantasmas);

    this._construirAnillos();
    this._construirAnillosBando();
    this._construirBarras();
    this._fantasmas = new Map();

    /* objeto reusado que se le pasa a animar(): cero basura por tick */
    this._extra = {
      vel: 0, velNorm: 0, jugador: 0, veterania: 0, progreso: 0,
      herido: 0, carga: 0, cargaTipo: 0, tiempo: 0, seleccionada: 0, clase: '',
    };

    this._suscribir();

    // por si alguien pobló el mundo antes de construir la vista
    const mundo = ctx?.mundo;
    if (mundo) for (let i = 0; i < mundo.maxUsado; i++) if (mundo.vivo[i]) this.registrar(i);
  }

  /* ================================================================ */
  /* Suscripciones                                                     */
  /* ================================================================ */
  _suscribir() {
    const mundo = this.ctx?.mundo;
    this._alCrear = (id) => this.registrar(id);
    this._alDestruir = (id) => this.quitar(id);
    mundo?.alCrear?.add(this._alCrear);
    mundo?.alDestruir?.add(this._alDestruir);

    this.bus.on('seleccion:cambio', (ids) => this.setAnillosSeleccion(ids));
    this.bus.on('edad:remodelar', (d) => this.refrescarEdad(d?.jugador ?? 0, d?.edad ?? 0));
    this.bus.on('edad:avanzada', (d) => this.refrescarEdad(d?.jugador ?? 0, d?.edad ?? 0));

    this._teclaAbajo = (e) => { if (e.key === 'Alt' || e.code === 'AltLeft' || e.code === 'AltRight') this.altPulsado = true; };
    this._teclaArriba = (e) => { if (e.key === 'Alt' || e.code === 'AltLeft' || e.code === 'AltRight') this.altPulsado = false; };
    this._perderFoco = () => { this.altPulsado = false; };
    window.addEventListener('keydown', this._teclaAbajo);
    window.addEventListener('keyup', this._teclaArriba);
    window.addEventListener('blur', this._perderFoco);
  }

  dispose() {
    const mundo = this.ctx?.mundo;
    mundo?.alCrear?.delete(this._alCrear);
    mundo?.alDestruir?.delete(this._alDestruir);
    window.removeEventListener('keydown', this._teclaAbajo);
    window.removeEventListener('keyup', this._teclaArriba);
    window.removeEventListener('blur', this._perderFoco);
  }

  /* ================================================================ */
  /* Alta y baja de entidades                                          */
  /* ================================================================ */

  registrar(id) {
    if (this.registros.has(id)) return;
    const mundo = this.ctx?.mundo;
    if (!mundo || !mundo.vivo[id]) return;

    const tipo = mundo.tipo[id];
    if (tipo === TIPO.PROYECTIL || tipo === TIPO.NINGUNO) return;  // los proyectiles son de Efectos

    const def = this._defDe(tipo, mundo.defId[id]);
    const clave = def?.clave ?? 'desconocido';

    // los árboles y arbustos cosechables los dibuja Foliaje (instanciado en masa)
    if (tipo === TIPO.RECURSO && CLAVES_FOLIAJE.has(clave) && this.ctx.foliaje) return;

    const jugador = mundo.jugador[id];
    const edad = this.edadDe(jugador);
    const x = mundo.px[id], z = mundo.pz[id];
    const y = this._alturaSuelo(x, z, def);

    const reg = {
      id, tipo, def, clave, jugador, edad,
      obj: null, api: null, animar: null,
      xa: x, ya: y, za: z, rota: mundo.rot[id],
      xb: x, yb: y, zb: z, rotb: mundo.rot[id],
      x, y, z, rot: mundo.rot[id],
      fase: mundo.animFase[id] || 0,
      vel: 0, velMax: def?.velocidad || 4.5,
      alto: this._altoEstimado(tipo, def),
      radio: mundo.radio[id] > 0.01 ? mundo.radio[id] : (def?.radio || 0.55),
      estatico: tipo !== TIPO.UNIDAD && !(tipo === TIPO.RECURSO && CLAVES_ANIMAL.has(clave)),
      instanciable: tipo !== TIPO.EDIFICIO,
      lod: 'lejos',
      enCola: false,
      reconstruir: false,
      visibleReal: true,
      sucio: true,
      // construcción / daño
      enObra: tipo === TIPO.EDIFICIO && mundo.vida[id] < mundo.vidaMax[id] * 0.6,
      progreso: -1,
      nivelDanio: -1,
      humeando: false,
      // transición de remodelado por edad
      transicion: 0,
      // atenuación por oclusión
      opacidad: 1, opacidadObj: 1, matsAtenuados: null, matsOriginales: null,
      idx: this.lista.length,
    };

    this.registros.set(id, reg);
    this.lista.push(reg);

    // los edificios son pocos y estructuran la lectura del mapa: se crean ya
    if (tipo === TIPO.EDIFICIO) this._asegurarMalla(reg, true);
    return reg;
  }

  quitar(id) {
    const reg = this.registros.get(id);
    if (!reg) return;
    this.registros.delete(id);

    const ultimo = this.lista[this.lista.length - 1];
    this.lista[reg.idx] = ultimo;
    ultimo.idx = reg.idx;
    this.lista.pop();

    if (reg.obj) {
      // en vez de desaparecer de golpe: se hunde y se apaga
      this._moribundos.push({
        obj: reg.obj, t: 0,
        dur: reg.tipo === TIPO.EDIFICIO ? 1.35 : 0.75,
        y0: reg.obj.position.y,
        alto: reg.alto,
        vuelca: reg.tipo === TIPO.UNIDAD,
        giro: (reg.id % 2 ? 1 : -1),
      });
      reg.obj.matrixAutoUpdate = true;
      if (reg.tipo === TIPO.EDIFICIO) {
        this.ctx.efectos?.polvo?.(reg.x, reg.y, reg.z, 24);
      }
      reg.obj = null;
    }
    reg.api = null; reg.animar = null;
  }

  mallaDe(id) {
    const reg = this.registros.get(id);
    if (!reg) return null;
    if (!reg.obj) this._asegurarMalla(reg, true);
    return reg.obj;
  }

  setAnillosSeleccion(setIds) {
    this.seleccion = setIds instanceof Set ? setIds : new Set(setIds || []);
  }

  /** Reconstruye la estética del jugador para la edad nueva, con transición corta. */
  refrescarEdad(jugador, edad) {
    if (edad == null) return;
    for (let i = 0; i < this.lista.length; i++) {
      const reg = this.lista[i];
      if (reg.jugador !== jugador || reg.edad === edad) continue;
      reg.edad = edad;
      if (reg.tipo === TIPO.EDIFICIO) {
        this._soltarMalla(reg);
        this._asegurarMalla(reg, true);
        reg.transicion = 0.55;
        this.ctx.efectos?.polvo?.(reg.x, reg.y, reg.z, 14);
      } else if (reg.tipo === TIPO.UNIDAD) {
        // las unidades se rehacen sin apuro, cuando el presupuesto lo permita
        this._soltarMalla(reg);
        reg.reconstruir = true;
      }
    }
  }

  edadDe(jugador) {
    const e = this.ctx?.edades?.edad;
    if (!e) return 0;
    const v = Array.isArray(e) || ArrayBuffer.isView(e) ? e[jugador] : e;
    return Number.isFinite(v) ? v : 0;
  }

  /** Color de bando CRUDO en lineal (sin la regla de pintura aplicada). */
  colorJugador(j) {
    if (j == null || j < 0 || j === 255) return this._colorNeutro;
    return this._colores[j % this._colores.length];
  }

  /** El mismo color ya convertido en PINTURA (ver art/PinturaBando.js). */
  pinturaJugador(j, conMapa) {
    const tabla = conMapa ? this._pinturasMapa : this._pinturas;
    if (j == null || j < 0 || j === 255) return tabla[tabla.length - 1];
    return tabla[j % this._colores.length];
  }

  /* ================================================================ */
  /* Paso fijo (20 Hz): guarda el estado del tick para poder interpolar */
  /* ================================================================ */
  fijo(dt, ctx) {
    const mundo = ctx.mundo;
    const lista = this.lista;
    const invDt = 1 / dt;
    for (let k = 0; k < lista.length; k++) {
      const reg = lista[k];
      const id = reg.id;
      if (!mundo.vivo[id]) continue;

      reg.xa = reg.xb; reg.ya = reg.yb; reg.za = reg.zb; reg.rota = reg.rotb;

      const x = mundo.px[id], z = mundo.pz[id];
      reg.xb = x; reg.zb = z;
      reg.rotb = mundo.rot[id];
      reg.yb = this._alturaSuelo(x, z, reg.def, mundo.py[id]);

      // velocidad real medida entre ticks: es la que manda la animación
      const dx = reg.xb - reg.xa, dz = reg.zb - reg.za;
      reg.vel = Math.sqrt(dx * dx + dz * dz) * invDt;
      if (reg.vel > 40) reg.vel = 0;   // teletransporte (respawn / carga): no anima
    }
  }

  /* ================================================================ */
  /* Por frame: interpolación, LOD, animación y toda la capa visual     */
  /* ================================================================ */
  cada(dtReal, alfa, ctx) {
    const mundo = ctx.mundo, cam = ctx.camara;
    if (!cam || !mundo) return;
    this._tiempo += dtReal;
    this._presupuesto = ALTAS_POR_FRAME;
    if (alfa > 1) alfa = 1;

    cam.updateMatrixWorld();
    _matProy.multiplyMatrices(cam.projectionMatrix, cam.matrixWorldInverse);
    _frustum.setFromProjectionMatrix(_matProy);
    const cx = cam.position.x, cy = cam.position.y, cz = cam.position.z;

    // ejes de la cámara para el billboard de las barras de vida
    const me = cam.matrixWorld.elements;
    const rx = me[0], ry = me[1], rz = me[2];
    const ux = me[4], uy = me[5], uz = me[6];
    const mundoPorPixel = (2 * Math.tan(cam.fov * Math.PI / 360)) / Math.max(1, window.innerHeight);

    for (const lote of this._lotes.values()) lote.n = 0;
    this._nBarras = 0;
    this._nAnillos = 0;
    this._nBando = 0;

    const jugLocal = ctx.jugadorLocal ?? 0;
    const lista = this.lista;
    const extra = this._extra;
    extra.tiempo = this._tiempo;

    for (let k = 0; k < lista.length; k++) {
      const reg = lista[k];
      const id = reg.id;
      if (!mundo.vivo[id]) continue;

      /* --- interpolación --- */
      const x = lerpNum(reg.xa, reg.xb, alfa);
      const z = lerpNum(reg.za, reg.zb, alfa);
      const y = lerpNum(reg.ya, reg.yb, alfa);
      const rot = lerpAngulo(reg.rota, reg.rotb, alfa);
      reg.x = x; reg.y = y; reg.z = z; reg.rot = rot;

      /* --- niebla de guerra --- */
      const propio = reg.jugador === jugLocal;
      const vis = propio || mundo.visible[id] !== 0;
      reg.visibleReal = vis;

      const ddx = x - cx, ddy = y - cy, ddz = z - cz;
      const d2 = ddx * ddx + ddy * ddy + ddz * ddz;

      if (!vis) { if (reg.obj) reg.obj.visible = false; continue; }

      /* --- frustum culling propio: lo que no se ve, no se anima --- */
      _esfera.center.set(x, y + reg.alto * 0.5, z);
      _esfera.radius = reg.alto * 0.6 + reg.radio + 0.6;
      const enCamara = _frustum.intersectsSphere(_esfera);

      /* --- decisión de nivel de detalle, con histéresis --- */
      if (reg.instanciable) {
        if (reg.lod === 'lejos') { if (d2 < D_CERCA2) reg.lod = 'cerca'; }
        else if (d2 > D_LEJOS2) reg.lod = 'lejos';
      } else {
        reg.lod = 'cerca';
      }

      if (reg.lod === 'cerca' && enCamara && (!reg.obj || reg.reconstruir)) this._encolarMalla(reg);

      const escala = mundo.escala[id] || 1;
      const usaInstancia = !reg.obj || (reg.lod === 'lejos' && reg.instanciable);

      if (usaInstancia) {
        if (reg.obj) reg.obj.visible = false;
        if (enCamara) this._empujarInstancia(reg, x, y, z, rot, escala);
      } else {
        const obj = reg.obj;
        obj.visible = enCamara;
        if (enCamara) {
          obj.position.set(x, y, z);
          obj.rotation.y = rot;
          this._aplicarEstadoEdificio(reg, mundo, escala);
          if (reg.transicion > 0) {
            reg.transicion = Math.max(0, reg.transicion - dtReal);
            const t = 1 - reg.transicion / 0.55;
            const s = 0.80 + 0.24 * t - 0.04 * Math.cos(t * Math.PI * 2);
            obj.scale.multiplyScalar(s);
          }
          if (!reg.estatico) this._animar(reg, mundo, dtReal, d2, extra);
          if (!obj.matrixAutoUpdate) obj.updateMatrix();
        }
      }

      /* --- marca de bando: siempre visible, no depende de la selección --- */
      if (enCamara && reg.tipo === TIPO.UNIDAD && reg.jugador !== 255 && d2 < D_BANDO2) {
        this._empujarAnilloBando(reg, x, y, z);
      }

      /* --- capa de interfaz: anillos y barras --- */
      if (enCamara && d2 < D_UI2) {
        const vidaMax = mundo.vidaMax[id] || 1;
        const vidaFrac = clamp(mundo.vida[id] / vidaMax, 0, 1);
        const sel = this.seleccion.has(id);
        if (sel) this._empujarAnillo(reg, x, y, z, vidaFrac);
        const herida = vidaFrac < 0.999;
        if (sel || this.altPulsado || herida) {
          const dist = Math.sqrt(d2);
          this._empujarBarra(reg, x, y, z, vidaFrac, dist * mundoPorPixel, rx, ry, rz, ux, uy, uz);
        }
      }
    }

    this._cerrarLotes();
    this._cerrarAnillos();
    this._cerrarAnillosBando();
    this._cerrarBarras();
    this._procesarCola();
    this._actualizarOclusion(dtReal, cam, mundo, jugLocal);
    this._actualizarFantasmas(dtReal, jugLocal);
    this._actualizarMoribundos(dtReal);
  }

  /* ================================================================ */
  /* Animación                                                         */
  /* ================================================================ */
  _animar(reg, mundo, dtReal, d2, extra) {
    if (!reg.animar) return;
    const id = reg.id;
    const est = mundo.estado[id];

    // A más de 30 m se anima un frame sí y otro no: nadie lo nota, y ahorra la mitad.
    if (d2 > 900) {
      reg.salto = !reg.salto;
      if (reg.salto) return;
      dtReal *= 2;
    }

    let dFase;
    if (est === ESTADO.ATACANDO || est === ESTADO.RECOLECTANDO ||
        est === ESTADO.CONSTRUYENDO || est === ESTADO.REPARANDO) {
      const cad = reg.def?.cadencia > 0.2 ? reg.def.cadencia : 1.4;
      dFase = (TAU / cad) * dtReal;
    } else if (reg.vel > 0.06) {
      // la fase avanza con la velocidad REAL: una unidad lenta mueve las piernas lento
      dFase = (reg.vel / ZANCADA) * TAU * dtReal;
    } else {
      dFase = 1.4 * dtReal;   // respiración / idle
    }
    if (dFase > 0.8) dFase = 0.8;
    reg.fase += dFase;
    if (reg.fase > 1e5) reg.fase %= TAU;
    mundo.animFase[id] = reg.fase;

    extra.vel = reg.vel;
    extra.velNorm = reg.velMax > 0 ? reg.vel / reg.velMax : 0;
    extra.jugador = reg.jugador;
    extra.veterania = mundo.veterania[id];
    extra.progreso = mundo.progreso[id];
    extra.carga = mundo.cargaCant[id];
    extra.cargaTipo = mundo.cargaTipo[id];
    extra.herido = 1 - clamp(mundo.vida[id] / (mundo.vidaMax[id] || 1), 0, 1);
    extra.seleccionada = this.seleccion.has(id) ? 1 : 0;
    extra.clase = reg.def?.clase || '';

    try { reg.animar(reg.fase, est, dtReal, extra); }
    catch (e) { reg.animar = null; console.warn('[vista] animar falló en', reg.clave, e); }
  }

  /** Progreso de obra, daño y humo. Solo toca la malla cuando algo cambió de verdad. */
  _aplicarEstadoEdificio(reg, mundo, escala) {
    const obj = reg.obj;
    if (reg.tipo !== TIPO.EDIFICIO) { obj.scale.setScalar(escala); return; }
    const id = reg.id;

    if (reg.enObra) {
      const p = clamp(mundo.progreso[id], 0, 1);
      if (p >= 0.999 || mundo.vida[id] >= mundo.vidaMax[id] * 0.999) {
        reg.enObra = false; reg.progreso = 1;
        if (reg.api?.setProgreso) reg.api.setProgreso(1);
        obj.scale.setScalar(escala);
        this.ctx.efectos?.polvo?.(reg.x, reg.y, reg.z, 18);
      } else if (Math.abs(p - reg.progreso) > 0.01) {
        reg.progreso = p;
        if (reg.api?.setProgreso) { reg.api.setProgreso(p); obj.scale.setScalar(escala); }
        else obj.scale.set(escala, escala * (0.12 + 0.88 * p), escala);  // sale del suelo
        return;
      } else {
        return;
      }
    } else {
      obj.scale.setScalar(escala);
    }

    const frac = clamp(mundo.vida[id] / (mundo.vidaMax[id] || 1), 0, 1);
    const nivel = Math.round((1 - frac) * 8);
    if (nivel !== reg.nivelDanio) {
      reg.nivelDanio = nivel;
      reg.api?.setDanio?.(1 - frac);
      const debeHumear = frac < 0.55;
      if (debeHumear !== reg.humeando) {
        reg.humeando = debeHumear;
        this.ctx.efectos?.humoContinuo?.(obj, debeHumear ? (0.55 - frac) * 2.2 : 0);
      }
    }
  }

  /* ================================================================ */
  /* Construcción de mallas (con presupuesto por frame)                */
  /* ================================================================ */
  _encolarMalla(reg) {
    if (reg.enCola) return;
    reg.enCola = true;
    this._cola.push(reg);
  }

  _procesarCola() {
    const cola = this._cola;
    while (cola.length && this._presupuesto > 0) {
      const reg = cola.shift();
      reg.enCola = false;
      if (!this.registros.has(reg.id)) continue;
      if (reg.lod !== 'cerca') continue;
      this._asegurarMalla(reg, true);
      this._presupuesto--;
    }
    if (cola.length > 600) cola.length = 300;   // válvula de seguridad
  }

  _asegurarMalla(reg, forzar) {
    if (reg.obj && !reg.reconstruir) return reg.obj;
    if (reg.reconstruir) this._soltarMalla(reg);
    if (!reg.obj && !forzar) return null;

    let api = null, grupo = null;
    try {
      if (reg.tipo === TIPO.UNIDAD) {
        api = FabricaUnidad.crearMallaUnidad?.(reg.clave, reg.edad, this.ctx);
      } else if (reg.tipo === TIPO.EDIFICIO) {
        api = FabricaEdificio.crearMallaEdificio?.(reg.clave, reg.edad, this.ctx);
      } else if (reg.tipo === TIPO.RECURSO) {
        api = FabricaNaturaleza.crearNodo?.(reg.clave, this.ctx?.rng, this.ctx)
          ?? FabricaNaturaleza.crearAnimal?.(reg.clave, this.ctx?.rng, this.ctx)
          ?? (CLAVES_FOLIAJE.has(reg.clave) ? FabricaNaturaleza.crearArbol?.(reg.clave, this.ctx?.rng, this.ctx) : null);
      } else {
        api = FabricaNaturaleza.crearRoca?.(this.ctx?.rng, this.ctx);
      }
    } catch (e) {
      console.warn('[vista] fábrica falló para', reg.clave, e);
      api = null;
    }

    grupo = api?.grupo ?? (api?.isObject3D ? api : null);
    if (!grupo) { api = this._respaldo(reg); grupo = api.grupo; }

    const claveCache = `${reg.clave}|${reg.edad}|${reg.jugador}`;
    this._pintarJugador(grupo, reg.jugador, claveCache);
    this._canonizarMateriales(grupo, claveCache);

    grupo.position.set(reg.x, reg.y, reg.z);
    grupo.rotation.y = reg.rot;
    grupo.castShadow = true;
    grupo.traverse((o) => {
      if (!o.isMesh) return;
      o.castShadow = true;
      o.receiveShadow = reg.tipo === TIPO.EDIFICIO;
      o.frustumCulled = false;   // el culling lo hacemos nosotros, a nivel entidad
    });
    if (reg.estatico) grupo.matrixAutoUpdate = false;

    const alto = this._altoDe(grupo, reg);
    if (alto > 0) reg.alto = alto;

    reg.obj = grupo;
    reg.api = api;
    reg.animar = typeof api?.animar === 'function' ? api.animar.bind(api) : null;
    reg.reconstruir = false;
    reg.progreso = -1; reg.nivelDanio = -1;
    reg.matsAtenuados = null; reg.matsOriginales = null;
    if (reg.opacidad < 0.999) reg.opacidad = 1;
    this.raiz.add(grupo);
    if (reg.estatico) grupo.updateMatrix();
    return grupo;
  }

  _soltarMalla(reg) {
    if (!reg.obj) return;
    if (reg.humeando) { this.ctx.efectos?.humoContinuo?.(reg.obj, 0); reg.humeando = false; }
    this.raiz.remove(reg.obj);
    reg.obj = null; reg.api = null; reg.animar = null;
    reg.matsAtenuados = null; reg.matsOriginales = null;
  }

  /* ================================================================ */
  /* Nivel de detalle lejano: un InstancedMesh por tipo                */
  /* ================================================================ */
  _empujarInstancia(reg, x, y, z, rot, escala) {
    const lote = this._lote(reg);
    if (!lote) return;
    if (lote.n >= lote.cap) this._crecerLote(lote, lote.cap * 2);
    const i = lote.n++;
    escribirMatriz(lote.malla.instanceMatrix.array, i * 16, x, y, z, rot, escala);
    if (lote.jugRanura[i] !== reg.jugador + 1) {
      lote.jugRanura[i] = reg.jugador + 1;
      // Misma pintura que en el camino de malla completa: si el LOD lejano usara
      // el hex crudo, una unidad cambiaría de color al cruzar la banda de LOD.
      // Acá SÍ va la pintura (y no el crudo como en `_pintarJugador`): el
      // material fusionado es un MeshStandard pelado, nadie aplica la regla
      // después. Sin mapa, así que sin ganancia de mapa.
      const c = this.pinturaJugador(reg.jugador, false);
      const ca = lote.malla.instanceColor.array;
      ca[i * 3] = c.r; ca[i * 3 + 1] = c.g; ca[i * 3 + 2] = c.b;
      lote.colorSucio = true;
    }
  }

  _cerrarLotes() {
    for (const lote of this._lotes.values()) {
      const m = lote.malla;
      if (lote.n === 0 && m.count === 0) continue;
      m.count = lote.n;
      m.instanceMatrix.needsUpdate = true;
      if (lote.colorSucio) { m.instanceColor.needsUpdate = true; lote.colorSucio = false; }
      m.visible = lote.n > 0;
    }
  }

  _lote(reg) {
    const clave = `${reg.clave}|${reg.edad}`;
    let lote = this._lotes.get(clave);
    if (lote !== undefined) return lote;

    const geo = this._geoFusionada(reg);
    if (!geo) { this._lotes.set(clave, null); return null; }
    const mat = this._materialFusion(geo, clave);
    lote = { clave, geo, mat, malla: null, cap: 0, n: 0, jugRanura: null, colorSucio: true };
    this._lotes.set(clave, lote);
    this._crecerLote(lote, 32);
    return lote;
  }

  _crecerLote(lote, cap) {
    const anterior = lote.malla;
    const malla = new THREE.InstancedMesh(lote.geo, lote.mat, cap);
    malla.instanceColor = new THREE.InstancedBufferAttribute(new Float32Array(cap * 3), 3);
    malla.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    malla.instanceColor.setUsage(THREE.DynamicDrawUsage);
    malla.frustumCulled = false;           // el culling ya lo hicimos por entidad
    malla.castShadow = true;
    malla.receiveShadow = false;
    malla.count = 0;
    malla.name = `lod:${lote.clave}`;
    const jug = new Uint8Array(cap);
    if (anterior) {
      malla.instanceMatrix.array.set(anterior.instanceMatrix.array);
      malla.instanceColor.array.set(anterior.instanceColor.array);
      jug.set(lote.jugRanura);
      this.raizInstancias.remove(anterior);
      anterior.dispose();
    }
    lote.malla = malla;
    lote.cap = cap;
    lote.jugRanura = jug;
    lote.colorSucio = true;
    this.raizInstancias.add(malla);
  }

  /**
   * Geometría fusionada del tipo. Si la fábrica la ofrece, se usa; si no, se
   * construye una vez a partir de un prototipo y se hornean colores por vértice
   * más una máscara `aMascara` que marca las zonas de color del jugador.
   */
  _geoFusionada(reg) {
    const clave = `${reg.clave}|${reg.edad}`;
    const cacheada = this._geoCache.get(clave);
    if (cacheada !== undefined) return cacheada;

    let geo = null;
    try {
      if (reg.tipo === TIPO.UNIDAD) geo = FabricaUnidad.geometriaFusionadaUnidad?.(reg.clave, reg.edad, this.ctx);
      else if (reg.tipo === TIPO.RECURSO) geo = FabricaNaturaleza.geometriaFusionadaNodo?.(reg.clave, this.ctx);
    } catch (e) { geo = null; }

    if (!geo?.isBufferGeometry) geo = this._fusionarDesdePrototipo(reg);
    this._geoCache.set(clave, geo);
    return geo;
  }

  _fusionarDesdePrototipo(reg) {
    let api = null, grupo = null;
    try {
      if (reg.tipo === TIPO.UNIDAD) api = FabricaUnidad.crearMallaUnidad?.(reg.clave, reg.edad, this.ctx);
      else if (reg.tipo === TIPO.RECURSO) {
        api = FabricaNaturaleza.crearNodo?.(reg.clave, this.ctx?.rng, this.ctx)
          ?? FabricaNaturaleza.crearAnimal?.(reg.clave, this.ctx?.rng, this.ctx);
      }
    } catch (e) { api = null; }
    grupo = api?.grupo ?? (api?.isObject3D ? api : null);
    if (!grupo) grupo = this._respaldo(reg).grupo;

    // el prototipo se pinta de blanco: el color real lo pone instanceColor
    this._pintarJugador(grupo, -1, `proto|${reg.clave}|${reg.edad}`);
    grupo.updateMatrixWorld(true);

    const trozos = [];
    grupo.traverse((o) => {
      if (!o.isMesh || !o.geometry) return;
      let g = o.geometry.index ? o.geometry.toNonIndexed() : o.geometry.clone();
      g.applyMatrix4(o.matrixWorld);
      // dejamos solo lo que hace falta para que mergeGeometries no se queje
      for (const nombre of Object.keys(g.attributes)) {
        if (nombre !== 'position' && nombre !== 'normal') g.deleteAttribute(nombre);
      }
      if (!g.getAttribute('normal')) g.computeVertexNormals();
      const n = g.getAttribute('position').count;
      const mat = Array.isArray(o.material) ? o.material[0] : o.material;
      const esJugador = this._esZonaJugador(o, mat) ? 1 : 0;
      _color.set(mat?.color ? mat.color : 0xb0a898);
      const cols = new Float32Array(n * 3);
      const masc = new Float32Array(n);
      for (let i = 0; i < n; i++) {
        cols[i * 3] = _color.r; cols[i * 3 + 1] = _color.g; cols[i * 3 + 2] = _color.b;
        masc[i] = esJugador;
      }
      g.setAttribute('color', new THREE.BufferAttribute(cols, 3));
      g.setAttribute('aMascara', new THREE.BufferAttribute(masc, 1));
      trozos.push(g);
    });

    let fusion = null;
    if (trozos.length) {
      fusion = trozos.length === 1 ? trozos[0] : mergeGeometries(trozos, false);
      if (fusion !== trozos[0]) for (const g of trozos) g.dispose();
    }
    if (fusion) { fusion.computeBoundingSphere(); fusion.computeBoundingBox(); }
    return fusion;
  }

  /**
   * Material del LOD lejano: color por vértice horneado + tinte de jugador por
   * instancia, aplicado SOLO donde la máscara vale 1. Una sola llamada por tipo.
   */
  _materialFusion(geo, clave) {
    const tieneColor = !!geo.getAttribute('color');
    const mat = new THREE.MeshStandardMaterial({
      vertexColors: tieneColor,
      color: tieneColor ? 0xffffff : 0xb0a898,
      roughness: 0.84, metalness: 0.06,
    });
    mat.name = `fusion:${clave}`;
    mat.onBeforeCompile = (sh) => {
      sh.vertexShader = sh.vertexShader
        .replace('#include <common>', '#include <common>\nattribute float aMascara;')
        .replace('#include <color_vertex>', /* glsl */`
          #if defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR )
            vColor = vec4( 1.0 );
          #endif
          #ifdef USE_COLOR
            vColor.rgb *= color;
          #endif
          #ifdef USE_INSTANCING_COLOR
            vColor.rgb = mix( vColor.rgb, instanceColor.rgb, clamp( aMascara, 0.0, 1.0 ) );
          #endif
        `);
    };
    mat.customProgramCacheKey = () => 'vista-fusion-mascara';
    return mat;
  }

  /* ================================================================ */
  /* Anillos de selección                                              */
  /* ================================================================ */
  _construirAnillos() {
    const S = 56, rInt = 0.74, rMed = 0.88, rExt = 1.0;
    const radios = [rInt, rMed, rExt];
    const pos = new Float32Array((S + 1) * 3 * 3);
    const ang = new Float32Array((S + 1) * 3);
    const borde = new Float32Array((S + 1) * 3);
    for (let i = 0; i <= S; i++) {
      const t = i / S;
      // el arco arranca al frente (−Z en pantalla clásica) y avanza en horario
      const a = -t * TAU + Math.PI * 0.5;
      const ca = Math.cos(a), sa = Math.sin(a);
      for (let r = 0; r < 3; r++) {
        const o = (i * 3 + r);
        pos[o * 3] = ca * radios[r];
        pos[o * 3 + 1] = 0;
        pos[o * 3 + 2] = sa * radios[r];
        ang[o] = t;
        borde[o] = r * 0.5;
      }
    }
    const idx = [];
    for (let i = 0; i < S; i++) {
      for (let r = 0; r < 2; r++) {
        const a0 = i * 3 + r, a1 = i * 3 + r + 1, b0 = (i + 1) * 3 + r, b1 = (i + 1) * 3 + r + 1;
        idx.push(a0, b0, a1, a1, b0, b1);
      }
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('aAng', new THREE.BufferAttribute(ang, 1));
    geo.setAttribute('aBorde', new THREE.BufferAttribute(borde, 1));
    geo.setIndex(idx);

    const vida = new THREE.InstancedBufferAttribute(new Float32Array(MAX_ANILLOS), 1);
    vida.setUsage(THREE.DynamicDrawUsage);
    geo.setAttribute('aVida', vida);

    const mat = new THREE.ShaderMaterial({
      vertexShader: VS_ANILLO, fragmentShader: FS_ANILLO,
      transparent: true, depthWrite: false, side: THREE.DoubleSide,
      polygonOffset: true, polygonOffsetFactor: -4, polygonOffsetUnits: -4,
    });

    const malla = new THREE.InstancedMesh(geo, mat, MAX_ANILLOS);
    malla.instanceColor = new THREE.InstancedBufferAttribute(new Float32Array(MAX_ANILLOS * 3), 3);
    malla.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    malla.instanceColor.setUsage(THREE.DynamicDrawUsage);
    malla.frustumCulled = false;
    malla.castShadow = false; malla.receiveShadow = false;
    malla.renderOrder = 4;
    malla.count = 0;
    malla.name = 'anillos-seleccion';
    this._anillos = malla;
    this._anillosVida = vida;
    this._nAnillos = 0;
    this.ctx?.escena?.add(malla);
  }

  _empujarAnillo(reg, x, y, z, vidaFrac) {
    if (this._nAnillos >= MAX_ANILLOS) return;
    const i = this._nAnillos++;
    const r = Math.max(0.62, reg.radio * 1.45 + (reg.tipo === TIPO.EDIFICIO ? 1.1 : 0.28));
    escribirMatriz(this._anillos.instanceMatrix.array, i * 16, x, y + 0.14, z, 0, r);
    // Acá va el color CRUDO y no la pintura, a propósito: la selección es
    // interfaz, tiene que gritar. El anillo de bando, que es diegético y está
    // siempre puesto, usa la pintura apagada. Los dos juntos no se confunden:
    // éste es más ancho, más brillante y lleva el arco de vida.
    const c = this.colorJugador(reg.jugador);
    const ca = this._anillos.instanceColor.array;
    ca[i * 3] = c.r; ca[i * 3 + 1] = c.g; ca[i * 3 + 2] = c.b;
    this._anillosVida.array[i] = vidaFrac;
  }

  _cerrarAnillos() {
    const m = this._anillos;
    if (m.count === 0 && this._nAnillos === 0) return;
    m.count = this._nAnillos;
    m.visible = this._nAnillos > 0;
    m.instanceMatrix.needsUpdate = true;
    m.instanceColor.needsUpdate = true;
    this._anillosVida.needsUpdate = true;
  }

  /* ================================================================ */
  /* Anillo de bando: la marca de tropa pegada al terreno              */
  /* ================================================================ */

  /**
   * Disco de S segmentos con cinco aros radiales. El perfil (sombra de contacto
   * + banda de color) lo resuelve el fragment a partir del radio normalizado, no
   * la geometría: así se puede reafinar sin volver a teselar nada.
   */
  _construirAnillosBando() {
    const S = 40;
    // los aros se concentran donde el perfil tiene detalle (banda y filo)
    const RADIOS = [0.0, 0.40, 0.62, 0.78, 0.90, 1.0];
    const R = RADIOS.length;
    const pos = new Float32Array((S + 1) * R * 3);
    const rad = new Float32Array((S + 1) * R);
    for (let i = 0; i <= S; i++) {
      const a = (i / S) * TAU;
      const ca = Math.cos(a), sa = Math.sin(a);
      for (let r = 0; r < R; r++) {
        const o = i * R + r;
        pos[o * 3] = ca * RADIOS[r];
        pos[o * 3 + 1] = 0;
        pos[o * 3 + 2] = sa * RADIOS[r];
        rad[o] = RADIOS[r];
      }
    }
    const idx = [];
    for (let i = 0; i < S; i++) {
      for (let r = 0; r < R - 1; r++) {
        const a0 = i * R + r, a1 = i * R + r + 1;
        const b0 = (i + 1) * R + r, b1 = (i + 1) * R + r + 1;
        idx.push(a0, b0, a1, a1, b0, b1);
      }
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('aRad', new THREE.BufferAttribute(rad, 1));
    geo.setIndex(idx);

    const mat = new THREE.ShaderMaterial({
      vertexShader: VS_BANDO, fragmentShader: FS_BANDO,
      uniforms: {
        // uniform COMPARTIDO con Cielo.js: el anillo sigue al sol y a la luna sin
        // que nadie lo actualice por frame desde acá
        uColorLuz: uniformesCielo.uColorLuz,
        // medido de noche: con 0.42 el anillo conservaba demasiado brillo diurno
        // y sobre pasto oscuro leía como calcomanía; 0.32 lo baja con la escena
        // y todavía se encuentra la tropa de un vistazo
        uPisoLuz: { value: 0.32 },
        uGanancia: { value: 1.55 },
      },
      transparent: true, depthWrite: false, side: THREE.DoubleSide,
      // el mismo truco que el anillo de selección para no pelear con el terreno
      polygonOffset: true, polygonOffsetFactor: -3, polygonOffsetUnits: -3,
    });

    const malla = new THREE.InstancedMesh(geo, mat, MAX_ANILLOS_BANDO);
    malla.instanceColor = new THREE.InstancedBufferAttribute(new Float32Array(MAX_ANILLOS_BANDO * 3), 3);
    malla.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    malla.instanceColor.setUsage(THREE.DynamicDrawUsage);
    malla.frustumCulled = false;
    malla.castShadow = false; malla.receiveShadow = false;
    // por debajo del anillo de selección (4): si se solapan, manda la selección
    malla.renderOrder = 3;
    malla.count = 0;
    malla.name = 'anillos-bando';
    this._anillosBando = malla;
    this._nBando = 0;
    this.ctx?.escena?.add(malla);
  }

  /**
   * `y` viene con la altura de vuelo sumada para los aéreos: el anillo va SIEMPRE
   * en el suelo, que es donde el jugador lo busca al escanear el mapa.
   */
  _empujarAnilloBando(reg, x, y, z) {
    if (this._nBando >= MAX_ANILLOS_BANDO) return;
    const i = this._nBando++;
    // más chico que el de selección (radio*1.45 + 0.28): tienen que distinguirse
    const r = Math.max(0.52, reg.radio * 1.22 + 0.16);
    const ySuelo = reg.def?.vuela ? this._alturaSuelo(x, z, null) : y;
    // 0.09 y no menos: el disco es plano y el terreno no, y con menos margen se
    // hundía en cualquier lomada y el anillo salía cortado a la mitad
    escribirMatriz(this._anillosBando.instanceMatrix.array, i * 16, x, ySuelo + 0.09, z, 0, r);
    const c = this.pinturaJugador(reg.jugador, false);
    const ca = this._anillosBando.instanceColor.array;
    ca[i * 3] = c.r; ca[i * 3 + 1] = c.g; ca[i * 3 + 2] = c.b;
  }

  _cerrarAnillosBando() {
    const m = this._anillosBando;
    if (m.count === 0 && this._nBando === 0) return;
    m.count = this._nBando;
    m.visible = this._nBando > 0;
    m.instanceMatrix.needsUpdate = true;
    m.instanceColor.needsUpdate = true;
  }

  /* ================================================================ */
  /* Barras de vida (quads orientados a la cámara, tamaño constante)   */
  /* ================================================================ */
  _construirBarras() {
    const n = MAX_BARRAS * VERTS_POR_BARRA;
    this._barPos = new Float32Array(n * 3);
    this._barCol = new Float32Array(n * 3);
    const geo = new THREE.BufferGeometry();
    const ap = new THREE.BufferAttribute(this._barPos, 3); ap.setUsage(THREE.DynamicDrawUsage);
    const ac = new THREE.BufferAttribute(this._barCol, 3); ac.setUsage(THREE.DynamicDrawUsage);
    geo.setAttribute('position', ap);
    geo.setAttribute('color', ac);
    geo.setDrawRange(0, 0);
    const mat = new THREE.MeshBasicMaterial({
      vertexColors: true, transparent: true, opacity: 0.96,
      depthTest: false, depthWrite: false, toneMapped: false, side: THREE.DoubleSide,
    });
    const malla = new THREE.Mesh(geo, mat);
    malla.frustumCulled = false;
    malla.renderOrder = 30;
    malla.name = 'barras-vida';
    this._barras = malla;
    this._barGeo = geo;
    this._nBarras = 0;
    this.ctx?.escena?.add(malla);
  }

  _empujarBarra(reg, x, y, z, vidaFrac, mpp, rx, ry, rz, ux, uy, uz) {
    if (this._nBarras >= MAX_BARRAS) return;
    const anchoPx = reg.tipo === TIPO.EDIFICIO ? 52 : 34;
    const altoPx = reg.tipo === TIPO.EDIFICIO ? 6 : 5;
    const W = anchoPx * mpp, H = altoPx * mpp;
    const cxp = x, cyp = y + reg.alto + Math.max(0.35, W * 0.35), czp = z;

    const c = this.colorJugador(reg.jugador);
    // fondo: el color del jugador apagado — la barra se "vacía" hacia la derecha
    _color.setRGB(c.r * 0.16 + 0.02, c.g * 0.16 + 0.02, c.b * 0.16 + 0.02);
    // relleno: color del jugador, virando a rojo cuando queda poca vida
    const alarma = vidaFrac < 0.34 ? (0.34 - vidaFrac) / 0.34 : 0;
    _color2.setRGB(
      Math.min(1, c.r * 1.15 + alarma * 0.75),
      c.g * (1.15 - alarma * 0.85),
      c.b * (1.15 - alarma * 0.85)
    );

    const i = this._nBarras++;
    let o = i * VERTS_POR_BARRA * 3;
    o = this._quad(o, cxp, cyp, czp, rx, ry, rz, ux, uy, uz, -W * 0.5, W * 0.5, -H * 0.5, H * 0.5, _color);
    const xFin = -W * 0.5 + W * vidaFrac;
    this._quad(o, cxp, cyp, czp, rx, ry, rz, ux, uy, uz, -W * 0.5, xFin, -H * 0.34, H * 0.34, _color2);
  }

  _quad(o, cx, cy, cz, rx, ry, rz, ux, uy, uz, u0, u1, v0, v1, col) {
    const P = this._barPos, C = this._barCol;
    const px = [u0, u1, u1, u0, u1, u0];
    const py = [v0, v0, v1, v0, v1, v1];
    for (let k = 0; k < 6; k++) {
      const u = px[k], v = py[k];
      P[o] = cx + rx * u + ux * v;
      P[o + 1] = cy + ry * u + uy * v;
      P[o + 2] = cz + rz * u + uz * v;
      C[o] = col.r; C[o + 1] = col.g; C[o + 2] = col.b;
      o += 3;
    }
    return o;
  }

  _cerrarBarras() {
    const n = this._nBarras * VERTS_POR_BARRA;
    this._barGeo.setDrawRange(0, n);
    this._barras.visible = n > 0;
    if (n > 0) {
      this._barGeo.attributes.position.needsUpdate = true;
      this._barGeo.attributes.color.needsUpdate = true;
    }
  }

  /* ================================================================ */
  /* Oclusión: los edificios propios se hacen translúcidos si tapan    */
  /* ================================================================ */
  _actualizarOclusion(dtReal, cam, mundo, jugLocal) {
    this._tOclusion -= dtReal;
    const recalcular = this._tOclusion <= 0;
    if (recalcular) this._tOclusion = 0.09;

    const lista = this.lista;
    if (recalcular) {
      // 1) todos los edificios propios vuelven a opacos…
      for (let k = 0; k < lista.length; k++) {
        const reg = lista[k];
        if (reg.tipo === TIPO.EDIFICIO && reg.jugador === jugLocal) reg.opacidadObj = 1;
      }
      // 2) …salvo los que se cruzan entre la cámara y una unidad seleccionada
      if (this.seleccion.size) {
        const cxp = cam.position.x, cyp = cam.position.y, czp = cam.position.z;
        let muestras = 0;
        for (const id of this.seleccion) {
          if (muestras++ > 16) break;
          const uReg = this.registros.get(id);
          if (!uReg || uReg.tipo !== TIPO.UNIDAD) continue;
          const tx = uReg.x - cxp, ty = uReg.y + uReg.alto * 0.5 - cyp, tz = uReg.z - czp;
          const largo2 = tx * tx + ty * ty + tz * tz;
          if (largo2 < 1e-4) continue;
          for (let k = 0; k < lista.length; k++) {
            const reg = lista[k];
            if (reg.tipo !== TIPO.EDIFICIO || reg.jugador !== jugLocal || !reg.obj) continue;
            if (reg.opacidadObj < 1) continue;
            const bx = reg.x - cxp, by = reg.y + reg.alto * 0.5 - cyp, bz = reg.z - czp;
            let t = (bx * tx + by * ty + bz * tz) / largo2;
            if (t <= 0 || t >= 1) continue;   // detrás de la cámara o más lejos que la unidad
            const dx = bx - tx * t, dy = by - ty * t, dz = bz - tz * t;
            const r = reg.radio + reg.alto * 0.45 + 1.2;
            if (dx * dx + dy * dy + dz * dz < r * r) reg.opacidadObj = 0.32;
          }
        }
      }
    }

    // 3) transición suave y aplicación (solo donde hay diferencia)
    const k2 = 1 - Math.pow(0.0009, dtReal);
    for (let k = 0; k < lista.length; k++) {
      const reg = lista[k];
      if (reg.tipo !== TIPO.EDIFICIO || !reg.obj) continue;
      if (Math.abs(reg.opacidad - reg.opacidadObj) < 0.004) {
        if (reg.opacidad !== reg.opacidadObj) { reg.opacidad = reg.opacidadObj; this._aplicarOpacidad(reg); }
        continue;
      }
      reg.opacidad = lerpNum(reg.opacidad, reg.opacidadObj, k2);
      this._aplicarOpacidad(reg);
    }
  }

  _aplicarOpacidad(reg) {
    const opaco = reg.opacidad > 0.995;
    if (opaco && !reg.matsAtenuados) return;
    if (!reg.matsAtenuados) {
      // clonamos una sola vez por edificio, nunca por frame
      const originales = [], atenuados = [], mallas = [];
      reg.obj.traverse((o) => {
        if (!o.isMesh || Array.isArray(o.material)) return;
        mallas.push(o);
        originales.push(o.material);
        const m = o.material.clone();
        m.transparent = true; m.depthWrite = false; m.needsUpdate = true;
        atenuados.push(m);
      });
      reg.mallasOpacidad = mallas;
      reg.matsOriginales = originales;
      reg.matsAtenuados = atenuados;
    }
    const mallas = reg.mallasOpacidad;
    for (let i = 0; i < mallas.length; i++) {
      if (opaco) mallas[i].material = reg.matsOriginales[i];
      else { reg.matsAtenuados[i].opacity = reg.opacidad; mallas[i].material = reg.matsAtenuados[i]; }
    }
  }

  /* ================================================================ */
  /* Fantasmas: lo que el jugador recuerda bajo la niebla              */
  /* ================================================================ */
  _actualizarFantasmas(dtReal, jugLocal) {
    this._tFantasmas -= dtReal;
    if (this._tFantasmas > 0) return;
    this._tFantasmas = 0.8;
    const recuerdos = this.ctx?.niebla?.recuerdos?.(jugLocal);
    if (!recuerdos) {
      if (this._fantasmas.size) this._limpiarFantasmas();
      return;
    }
    const vistos = this._vistos || (this._vistos = new Set());
    vistos.clear();
    try {
      for (const r of recuerdos) {
        if (!r) continue;
        const clave = r.clave ?? EDIFICIOS[r.defId]?.clave;
        if (!clave) continue;
        const x = r.x ?? 0, z = r.z ?? 0;
        const k = `${clave}|${Math.round(x)}|${Math.round(z)}`;
        vistos.add(k);
        if (this._fantasmas.has(k)) continue;
        const obj = this._crearFantasma(clave, r.edad ?? 0, x, z, r.rot ?? 0);
        if (obj) this._fantasmas.set(k, obj);
      }
    } catch (e) { /* forma inesperada: no rompemos el frame */ }

    for (const [k, obj] of this._fantasmas) {
      if (vistos.has(k)) continue;
      this.raizFantasmas.remove(obj);
      this._fantasmas.delete(k);
    }
  }

  _limpiarFantasmas() {
    for (const obj of this._fantasmas.values()) this.raizFantasmas.remove(obj);
    this._fantasmas.clear();
  }

  _crearFantasma(clave, edad, x, z, rot) {
    let api = null;
    try { api = FabricaEdificio.crearMallaEdificio?.(clave, edad, this.ctx); } catch (e) { api = null; }
    let grupo = api?.grupo ?? (api?.isObject3D ? api : null);
    if (!grupo) grupo = this._respaldoEdificio(clave, -1).grupo;
    const mat = this._material('fantasma', () => new THREE.MeshBasicMaterial({
      color: 0x8d95a0, transparent: true, opacity: 0.30,
      depthWrite: false, fog: true, toneMapped: false,
    }));
    grupo.traverse((o) => {
      if (!o.isMesh) return;
      o.material = mat;
      o.castShadow = false; o.receiveShadow = false;
      o.frustumCulled = true;
    });
    grupo.position.set(x, this._alturaSuelo(x, z, null), z);
    grupo.rotation.y = rot;
    grupo.matrixAutoUpdate = false;
    grupo.updateMatrix();
    this.raizFantasmas.add(grupo);
    return grupo;
  }

  /* ================================================================ */
  /* Moribundos: la malla se hunde y se apaga en vez de desaparecer     */
  /* ================================================================ */
  _actualizarMoribundos(dtReal) {
    const lista = this._moribundos;
    for (let i = lista.length - 1; i >= 0; i--) {
      const m = lista[i];
      m.t += dtReal;
      const t = m.t / m.dur;
      if (t >= 1) {
        this.raiz.remove(m.obj);
        lista[i] = lista[lista.length - 1];
        lista.pop();
        continue;
      }
      const e = t * t;
      m.obj.position.y = m.y0 - e * (m.alto * 1.15 + 0.6);
      if (m.vuelca) m.obj.rotation.z = m.giro * e * 1.45;
      else m.obj.scale.setScalar(1 - e * 0.22);
    }
  }

  /* ================================================================ */
  /* Materiales y color de jugador (cacheado por clave|edad|jugador)   */
  /* ================================================================ */
  _material(clave, fabrica) {
    let m = this._matCache.get(clave);
    if (!m) { m = fabrica(); this._matCache.set(clave, m); }
    return m;
  }

  _esZonaJugador(objeto, mat) {
    if (objeto?.userData?.colorJugador) return true;
    if (mat?.userData?.colorJugador) return true;
    if (mat?.name && RE_JUGADOR.test(mat.name)) return true;
    if (objeto?.name && RE_JUGADOR.test(objeto.name)) return true;
    return false;
  }

  /**
   * Tiñe las zonas marcadas como "de jugador" reutilizando materiales cacheados.
   *
   * ESTA FUNCIÓN ES LA ÚLTIMA QUE TOCA EL COLOR DE BANDO. Clona el material que
   * devolvió la fábrica y le escribe el color encima, así que acá se decide de
   * qué color sale el ejército y de qué color salen los techos. Por eso aplica
   * la MISMA regla que la fábrica, importada de `art/PinturaBando.js` en vez de
   * reimplementada: cuando había dos copias con constantes distintas, la de acá
   * pisaba a la otra y el resultado era el del peor calibrado de los dos.
   *
   * La bifurcación de abajo es la que faltaba hace cinco rondas. Hay dos clases
   * de material de bando:
   *
   *  · los que aplican la regla EN EL SHADER (unidad, bandera `esBando`): a ésos
   *    se les escribe el color CRUDO, porque su fragment la va a aplicar sobre
   *    lo que encuentre. Si les escribiéramos el ya pintado, la regla correría
   *    dos veces en cadena y el paño terminaría a mitad de croma: lavanda gris.
   *  · los que no (edificio, respaldos): a ésos se les escribe el color ya
   *    pintado, porque nadie más lo va a hacer. Si les escribiéramos el crudo,
   *    quedarían con dos canales en cero: primario que no sombrea.
   *
   * Escribirle a los dos lo mismo produce exactamente las dos quejas simultáneas
   * de la ronda 6 ("azul lavado en las unidades" + "azul saturado en cumbreras").
   */
  _pintarJugador(raiz, jugador, claveCache) {
    const crudo = this.colorJugador(jugador);
    raiz.traverse((o) => {
      if (!o.isMesh || Array.isArray(o.material) || !o.material) return;
      if (!this._esZonaJugador(o, o.material)) return;
      const base = o.material;
      const enShader = base.esBando === true || base.userData?.pinturaEnShader === true;
      const clave = `jug|${claveCache}|${enShader ? 'sh' : 'cpu'}|${base.name || base.uuid}`;
      o.material = this._material(clave, () => {
        const m = base.clone();
        // la ganancia de mapa sólo tiene sentido cuando hay un albedo que compensar
        if (m.color) m.color.copy(enShader ? crudo : this.pinturaJugador(jugador, !!m.map));
        // Nada de emisivo en el color de bando: es tela y pintura, no un cartel.
        // Con emisivo el bando se ve igual de brillante de noche que de día y el
        // ojo lo lee como "material sin asignar", que es literalmente lo que
        // reportó el panel cuatro rondas seguidas.
        if (m.emissive) {
          m.emissive.setRGB(0, 0, 0);
          m.emissiveIntensity = 0;
          m.emissiveMap = null;   // basta un mapa de emisión heredado para reventarlo
        }
        m.userData = Object.assign({}, m.userData, { colorJugador: true });
        return m;
      });
    });
  }

  /**
   * Deduplica los materiales que devuelve la fábrica: si dos entidades del mismo
   * tipo traen materiales equivalentes, comparten una única instancia. Menos
   * cambios de estado, menos memoria, y el batcher del driver lo agradece.
   */
  _canonizarMateriales(raiz, claveCache) {
    raiz.traverse((o) => {
      if (!o.isMesh || Array.isArray(o.material) || !o.material) return;
      const m = o.material;
      if (m.userData?.canonico) return;
      const clave = `mat|${claveCache}|${m.type}|${m.name}|${m.color ? m.color.getHexString() : '-'}|` +
        `${m.roughness ?? '-'}|${m.metalness ?? '-'}|${m.opacity}|${m.transparent ? 1 : 0}|` +
        `${m.map?.uuid ?? '-'}|${m.emissive ? m.emissive.getHexString() : '-'}|${m.side}|${m.flatShading ? 1 : 0}`;
      o.material = this._material(clave, () => { m.userData.canonico = true; return m; });
    });
  }

  /* ================================================================ */
  /* Utilidades                                                        */
  /* ================================================================ */
  _defDe(tipo, defId) {
    if (tipo === TIPO.UNIDAD) return UNIDADES[defId] || null;
    if (tipo === TIPO.EDIFICIO) return EDIFICIOS[defId] || null;
    if (tipo === TIPO.RECURSO) return NODOS[defId] || null;
    return null;
  }

  _alturaSuelo(x, z, def, py) {
    const t = this.ctx?.terreno;
    const base = t?.altura ? t.altura(x, z) : 0;
    if (def?.vuela) return base + ALTURA_VUELO;
    if (py !== undefined && py > base) return py;
    return base;
  }

  _altoEstimado(tipo, def) {
    if (tipo === TIPO.EDIFICIO) {
      const c = def?.celdas ? Math.max(def.celdas[0], def.celdas[1]) : 3;
      return 3.2 + c * 1.15;
    }
    if (tipo === TIPO.UNIDAD) {
      const cl = def?.clase;
      if (cl === 'asedio' || cl === 'caballeria') return 2.6;
      if (cl === 'nave') return 3.4;
      if (cl === 'aereo') return 1.2;
      return 1.85;
    }
    return def?.radio ? def.radio * 2.2 : 1.4;
  }

  _altoDe(grupo, reg) {
    const clave = `${reg.clave}|${reg.edad}`;
    const cacheado = this._altoCache.get(clave);
    if (cacheado !== undefined) return cacheado;
    let alto = 0;
    try {
      _caja.setFromObject(grupo);
      if (_caja.isEmpty()) alto = 0;
      else alto = Math.max(0.4, _caja.max.y - Math.min(0, _caja.min.y));
    } catch (e) { alto = 0; }
    if (!Number.isFinite(alto)) alto = 0;
    this._altoCache.set(clave, alto);
    return alto;
  }

  /* ================================================================ */
  /* Respaldos: si una fábrica todavía no existe, el juego igual se ve  */
  /* ================================================================ */
  _respaldo(reg) {
    if (reg.tipo === TIPO.EDIFICIO) return this._respaldoEdificio(reg.clave, reg.jugador, reg.def);
    if (reg.tipo === TIPO.RECURSO) return this._respaldoNodo(reg.clave, reg.def);
    return this._respaldoUnidad(reg.clave, reg.jugador, reg.def);
  }

  _geoCompartida(clave, fabrica) {
    let g = this._geoCache.get(`g:${clave}`);
    if (!g) { g = fabrica(); this._geoCache.set(`g:${clave}`, g); }
    return g;
  }

  _matSimple(clave, hex, rug = 0.85, met = 0.05) {
    return this._material(`simple|${clave}`, () => new THREE.MeshStandardMaterial({
      color: hex, roughness: rug, metalness: met,
    }));
  }

  _respaldoUnidad(clave, jugador, def) {
    const grupo = new THREE.Group();
    const clase = def?.clase || 'infanteria';
    const piel = this._matSimple('piel', 0xc79a72, 0.9, 0.0);
    const ropa = this._matSimple('ropa', 0x6a6357, 0.92, 0.0);
    const metal = this._matSimple('metal', 0x4d5560, 0.42, 0.75);

    const cuerpo = new THREE.Mesh(
      this._geoCompartida('u-torso', () => new THREE.CapsuleGeometry(0.30, 0.52, 4, 10)), ropa);
    cuerpo.position.y = 1.10;
    cuerpo.name = 'equipo';           // esta pieza lleva el color del jugador
    const cabeza = new THREE.Mesh(
      this._geoCompartida('u-cabeza', () => new THREE.SphereGeometry(0.20, 12, 10)), piel);
    cabeza.position.y = 1.62;
    const geoPierna = this._geoCompartida('u-pierna', () => {
      const g = new THREE.CapsuleGeometry(0.115, 0.50, 3, 8);
      g.translate(0, -0.30, 0);
      return g;
    });
    const p1 = new THREE.Mesh(geoPierna, ropa); p1.position.set(0, 0.86, 0.13);
    const p2 = new THREE.Mesh(geoPierna, ropa); p2.position.set(0, 0.86, -0.13);
    const geoBrazo = this._geoCompartida('u-brazo', () => {
      const g = new THREE.CapsuleGeometry(0.085, 0.44, 3, 8);
      g.translate(0, -0.26, 0);
      return g;
    });
    const b1 = new THREE.Mesh(geoBrazo, ropa); b1.position.set(0.05, 1.44, 0.30);
    const b2 = new THREE.Mesh(geoBrazo, ropa); b2.position.set(0.05, 1.44, -0.30);
    const arma = new THREE.Mesh(
      this._geoCompartida('u-arma', () => new THREE.BoxGeometry(1.18, 0.07, 0.07)), metal);
    arma.position.set(0.42, 1.16, 0.30);
    arma.rotation.z = -0.12;

    grupo.add(cuerpo, cabeza, p1, p2, b1, b2, arma);
    if (clase === 'caballeria' || clase === 'asedio') {
      const casco = new THREE.Mesh(
        this._geoCompartida('u-casco', () => new THREE.BoxGeometry(1.7, 0.75, 0.95)), metal);
      casco.position.y = 0.72;
      casco.name = 'equipo';
      grupo.add(casco);
      grupo.scale.setScalar(1.12);
    }

    const animar = (fase, estado, dt) => {
      const s = Math.sin(fase), c = Math.cos(fase);
      p1.rotation.z = s * 0.62; p2.rotation.z = -s * 0.62;
      b1.rotation.z = -s * 0.42; b2.rotation.z = s * 0.42;
      cuerpo.position.y = 1.10 + Math.abs(c) * 0.035;
      if (estado === ESTADO.ATACANDO) { arma.rotation.z = -0.12 + Math.max(0, s) * 0.55; }
      else arma.rotation.z = -0.12;
    };
    return { grupo, partes: { cuerpo, cabeza, arma }, animar };
  }

  _respaldoEdificio(clave, jugador, def) {
    const grupo = new THREE.Group();
    const celdas = def?.celdas || [3, 3];
    const w = celdas[0] * 2 * 0.86, d = celdas[1] * 2 * 0.86;
    const alto = 3.0 + Math.max(celdas[0], celdas[1]) * 0.55;
    const muro = this._matSimple('muro', 0xbdae94, 0.94, 0.0);
    const techo = this._matSimple('techo', 0x77473a, 0.9, 0.0);

    const cuerpo = new THREE.Mesh(new THREE.BoxGeometry(w, alto, d), muro);
    cuerpo.position.y = alto * 0.5;
    const tapa = new THREE.Mesh(new THREE.ConeGeometry(Math.max(w, d) * 0.78, alto * 0.55, 4), techo);
    tapa.position.y = alto + alto * 0.26;
    tapa.rotation.y = Math.PI * 0.25;
    const banda = new THREE.Mesh(new THREE.BoxGeometry(w * 1.02, 0.42, d * 1.02), muro);
    banda.position.y = alto * 0.86;
    banda.name = 'equipo';
    grupo.add(cuerpo, tapa, banda);
    return { grupo, altura: alto };
  }

  _respaldoNodo(clave, def) {
    const grupo = new THREE.Group();
    if (CLAVES_ANIMAL.has(clave)) {
      const pelo = this._matSimple(clave === 'jabali' ? 'pelo-jabali' : 'pelo-ciervo',
        clave === 'jabali' ? 0x4a3b30 : 0x9a6a3c, 0.95, 0.0);
      const cuerpo = new THREE.Mesh(
        this._geoCompartida('a-cuerpo', () => new THREE.CapsuleGeometry(0.30, 0.72, 4, 10)), pelo);
      cuerpo.rotation.z = Math.PI * 0.5;
      cuerpo.position.y = 0.72;
      const cuello = new THREE.Mesh(
        this._geoCompartida('a-cuello', () => {
          const g = new THREE.CapsuleGeometry(0.13, 0.42, 3, 8); g.translate(0, 0.21, 0); return g;
        }), pelo);
      cuello.position.set(0.56, 0.78, 0);
      const geoPata = this._geoCompartida('a-pata', () => {
        const g = new THREE.CapsuleGeometry(0.075, 0.58, 3, 6); g.translate(0, -0.29, 0); return g;
      });
      const patas = [];
      for (let i = 0; i < 4; i++) {
        const p = new THREE.Mesh(geoPata, pelo);
        p.position.set(i < 2 ? 0.42 : -0.40, 0.62, (i % 2 ? 0.20 : -0.20));
        patas.push(p);
      }
      grupo.add(cuerpo, cuello, ...patas);
      const animar = (fase, estado, dt, extra) => {
        const veloz = (extra?.vel || 0) > 0.4;
        const s = Math.sin(fase);
        for (let i = 0; i < 4; i++) patas[i].rotation.z = (i % 2 ? s : -s) * (veloz ? 0.75 : 0.16);
        // pastoreo: baja la cabeza cuando está quieto
        cuello.rotation.z = veloz ? -0.25 : (0.55 + Math.sin(fase * 0.4) * 0.42);
      };
      return { grupo, animar };
    }

    if (clave === 'pozo_petroleo') {
      const metal = this._matSimple('derrick', 0x3a3d42, 0.55, 0.6);
      const torre = new THREE.Mesh(new THREE.ConeGeometry(1.1, 4.2, 4, 1, true), metal);
      torre.position.y = 2.1;
      const base = new THREE.Mesh(new THREE.CylinderGeometry(1.35, 1.5, 0.4, 10), metal);
      base.position.y = 0.2;
      grupo.add(torre, base);
      return { grupo };
    }

    const esCarbon = clave === 'carbon';
    const roca = this._matSimple(esCarbon ? 'carbon' : clave === 'veta_oro' ? 'oro' : 'roca',
      esCarbon ? 0x2b2b30 : clave === 'veta_oro' ? 0xc8a13c : 0x8d8579, 0.72, esCarbon ? 0.1 : 0.45);
    const geo = this._geoCompartida('n-roca', () => new THREE.IcosahedronGeometry(0.62, 0));
    for (let i = 0; i < 5; i++) {
      const m = new THREE.Mesh(geo, roca);
      const a = i * 1.9;
      m.position.set(Math.cos(a) * 0.62, 0.28 + (i % 2) * 0.22, Math.sin(a) * 0.62);
      m.scale.setScalar(0.65 + (i % 3) * 0.22);
      m.rotation.set(a, a * 1.7, a * 0.6);
      grupo.add(m);
    }
    return { grupo };
  }
}
