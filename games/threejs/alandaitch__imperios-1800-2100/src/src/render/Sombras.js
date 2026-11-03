/**
 * SOMBRAS — mapas de sombra en cascada (CSM) para el sol.
 *
 * Por qué cascadas y no una sola sombra: la cámara RTS mira desde 70–90 m con
 * ~50° de elevación, así que el frustum visible cubre 150–300 m de suelo. Un
 * único mapa ortográfico estirado sobre esa superficie da 0,3 m por téxel: los
 * bordes se ven escalonados y las unidades pierden la sombra de contacto. Con
 * 4 cascadas la primera cubre ~50 m con el mismo mapa ⇒ ~3 cm por téxel, que es
 * lo que hace que una lanza proyecte una línea y no un manchón.
 *
 * Integración con el resto del juego:
 *   · `Cielo` sigue mandando la dirección y el color del sol; acá sólo se le
 *     delega la proyección (`cielo._solDelegado = true` apaga su DirectionalLight
 *     para que no haya dos soles sumando luz).
 *   · Cualquier módulo que cree un material iluminado debe pasar por
 *     `ctx.sombras.registrarMaterial(mat)`. Además se barre la escena cada tantos
 *     frames por si alguien se olvidó: un material sin `USE_CSM` recibe las N
 *     luces de cascada a la vez y se ve quemado, así que el barrido es un seguro.
 *   · Si CSM no se puede construir se degrada a una sola DirectionalLight con la
 *     cámara de sombra encajada al frustum visible, recortado a `maxFar`, y
 *     enganchada a la grilla de téxeles (sin eso la sombra "hierve" al mover).
 *   · Además del mapa de sombras hay un segundo sistema, independiente y siempre
 *     activo: las MANCHAS DE CONTACTO (`ctx.sombras.mancha(...)`). Ver el bloque
 *     más abajo; en dos palabras, son el parchecito oscuro que pega cada
 *     edificio y cada unidad al piso cuando el GTAO no está disponible.
 *
 * POLÍTICA DE SESGO (por qué el normalBias es chico y el bias hace el trabajo):
 *   `normalBias` corre el punto que consulta el mapa a lo largo de la normal del
 *   receptor, en METROS de mundo. Con un techo de decímetros la sombra se
 *   despega de la base del objeto —peter-panning de manual— y encima el defecto
 *   es distinto por cascada, así que un molino y el pino de al lado terminan con
 *   dos leyes de sombra en el mismo cuadro. Acá el techo es de centímetros
 *   (`NORMAL_BIAS_MAX`) y el acné se combate donde corresponde: con un `bias` de
 *   profundidad afinado POR CASCADA contra su téxel real y contra el rango de
 *   profundidad real de esa cascada (que también se ajusta, en vez de dejar los
 *   1200 m del constructor, que desperdiciaban toda la precisión del depth).
 */
import * as THREE from 'three';
import { CSM } from 'three/examples/jsm/csm/CSM.js';
import { TIPO } from '../core/World.js';

const acotar = (v, a, b) => (v < a ? a : v > b ? b : v);

/**
 * Techo del corrimiento por normal, en metros. La escena está a escala real
 * (una unidad mide 1,8 m); por encima de ~5 cm el ojo ya lee la sombra
 * despegada del objeto que la tira.
 */
const NORMAL_BIAS_MAX = 0.05;

/**
 * Cuánto de la luz directa sigue entrando en la sombra (1 = negro absoluto).
 * Las sombras a 0 dejan pasar sólo el hemisférico y el cuadro se hunde: nuestras
 * capturas tenían entre 30% y 99% de los píxeles por debajo de 32 de luma. Un
 * pelo de sol filtrado (15%) levanta el piso y, sobre todo, mantiene el TINTE
 * CÁLIDO del sol dentro de la sombra en vez de dejarla azul de cielo puro.
 */
const SOMBRA_INTENSIDAD = 0.85;

/**
 * Mezcla log/uniforme del reparto de cascadas. Ver `_calcularCortes`.
 * Bajó de 0,86 a 0,5 porque los cortes ya no se reparten los 400 m del frustum
 * (donde el logarítmico era imprescindible para no regalar la cascada fina)
 * sino los ~70 m de banda de suelo, un rango tan corto que el logarítmico puro
 * amontona los tres cortes contra el borde de adelante.
 */
const LAMBDA_CORTES = 0.5;

const _arriba = new THREE.Vector3(0, 1, 0);
const _origen = new THREE.Vector3();
const _mOrient = new THREE.Matrix4();
const _mOrientInv = new THREE.Matrix4();
const _caja = new THREE.Box3();
const _centro = new THREE.Vector3();
const _tmp = new THREE.Vector3();
const _esquinas = [];
for (let i = 0; i < 8; i++) _esquinas.push(new THREE.Vector3());

/* medición de la huella real de una entidad (una vez por entidad, nunca por frame) */
const _cajaHuella = new THREE.Box3();
const _tamHuella = new THREE.Vector3();

/* temporales de las manchas de contacto: se reusan, cero asignaciones por frame */
const _mPos = new THREE.Vector3();
const _mNormal = new THREE.Vector3();
const _mEscala = new THREE.Vector3();
const _mQuat = new THREE.Quaternion();
const _mMatriz = new THREE.Matrix4();
const _mColor = new THREE.Color();
const _mCero = new THREE.Matrix4().makeScale(0, 0, 0);

/** Capacidades del atlas de instancias de manchas (una sola llamada de dibujo). */
const MANCHA_CAP_MIN = 256;
const MANCHA_CAP_MAX = 6144;
/** Umbral de movimiento para reescribir la matriz de una instancia (metros). */
const MANCHA_EPS = 0.06;

/**
 * Cuánta mancha le toca a cada tipo de entidad, indexado por `TIPO`.
 *
 * `factor` multiplica la HUELLA (ver `_radioHuella`), `fuerza` es cuánto
 * oscurece y `usaCaja` decide de dónde sale la huella.
 *
 * POR QUÉ SE ACHICÓ LA MANCHA DE LAS UNIDADES (medido, no a ojo). La versión
 * anterior sacaba la huella de la caja envolvente de la malla y la multiplicaba
 * por 1,55: un colono con el pico en la mano medía 1,9 m de caja (el pico, el
 * ala del sombrero y el brazo estirado, no los pies) y terminaba con un disco
 * de 4,3 m de lado sobre un bicho de 0,5 m de ancho. Se comprobó en vivo
 * apagando y prendiendo el InstancedMesh y midiendo el delta del cuadro: el
 * disco EXISTÍA y llegaba a oscurecer, pero repartido en cuarenta píxeles de
 * degradado suavísimo. Un degradado de cuarenta píxeles no es una sombra de
 * contacto, es una mancha de humedad: el ojo necesita un BORDE para leer que
 * dos cosas se tocan, y ese borde no estaba en ninguna parte.
 *
 * La mancha de contacto de un RTS isométrico es chica, oscura y con filo: tapa
 * poco más que los pies. De ahí que la unidad pase a usar su RADIO DE COLISIÓN
 * —que es, literalmente, cuánto piso ocupa— en vez de la caja de la malla, que
 * mide el arma.
 */
const MANCHA_POR_TIPO = [];
// 1,55 y no 1,15: `VistaEntidades` ya dibuja un anillo de color de bando de
// 0,93 m bajo cada unidad. Con la mancha en 0,60 m el disco oscuro quedaba
// ADENTRO del anillo y el conjunto se leía como una boca de tormenta: aro claro,
// pozo negro. La mancha tiene que llegar hasta el anillo y pasarlo un poco, para
// que el aro apoye SOBRE la sombra en vez de rodear un agujero.
MANCHA_POR_TIPO[TIPO.UNIDAD] = { factor: 1.55, fuerza: 0.56, usaCaja: false };
// el edificio sí se mide con su caja real (su caja ES su planta), y el factor
// por debajo de 1 deja el disco justo adentro del perímetro más un dedo de falda
MANCHA_POR_TIPO[TIPO.EDIFICIO] = { factor: 0.92, fuerza: 0.76, usaCaja: true };
// el árbol mide 5 m de copa y 0,4 m de tronco: la caja miente hacia arriba, así
// que se la corrige con el factor en vez de plantar un disco del ancho de la copa
MANCHA_POR_TIPO[TIPO.RECURSO] = { factor: 0.78, fuerza: 0.64, usaCaja: true };
MANCHA_POR_TIPO[TIPO.DECORADO] = { factor: 0.82, fuerza: 0.58, usaCaja: true };

/**
 * Cuánto del disco es núcleo lleno (el resto es falda). Ver `_texturaMancha`.
 * Subió de 0,40 a 0,52: con 0,40 la parte que asomaba fuera de la silueta ya
 * caía en la falda y valía menos del 15% del oscurecimiento nominal. Con 0,60 —
 * lo primero que se probó— el disco quedaba tan macizo que se leía como una
 * calcomanía pegada al pasto; 0,52 deja falda suficiente para que el borde
 * respire sin perder el filo.
 */
const MANCHA_NUCLEO = 0.52;

/**
 * Dónde termina la falda dentro del quad. A 1,0 el degradado moría justo en el
 * borde del plano y el filtrado bilineal dejaba ver el CUADRADO en los discos
 * grandes (la sede); a 0,94 hay un anillo de guarda que se come el artefacto.
 */
const MANCHA_BORDE = 0.94;

/**
 * Sobre-oscurecimiento del anillo de contacto respecto del centro del disco.
 *
 * La oclusión real bajo una figura parada no es un disco parejo: es más oscura
 * justo en la línea donde el cuerpo toca el piso y se afloja hacia adentro. Ese
 * anillo es lo único que el jugador VE (el centro se lo tapa el propio bicho) y
 * es lo que el panel pedía por su nombre. Cuesta cero: es un tramo distinto de
 * la misma tabla de 128 téxeles.
 *
 * El centro va apenas por debajo del anillo (0,92 contra 1,0) y no mucho: con
 * 0,84 la diferencia se veía como una ROSQUILLA en las unidades finitas, donde
 * el cuerpo no llega a tapar el medio del disco.
 */
const MANCHA_ANILLO = 1.0;
const MANCHA_CENTRO = 0.92;

/**
 * Cuánto se estira el quad respecto del radio de la huella. El degradado llega
 * a cero en `MANCHA_BORDE` de la mitad del quad, así que el disco visible mide
 * `radio * MANCHA_QUAD * MANCHA_BORDE / 2`. Bajó de 2,9 a 2,45: con el factor de
 * unidad, el disco pasa de 2,15 m a 0,80 m de radio, o sea de "niebla en el
 * pasto" a "el tipo pisa acá".
 */
const MANCHA_QUAD = 2.45;

/** Handle público de una mancha de contacto. Ver `Sombras.mancha()`. */
class ManchaContacto {
  constructor(sistema, objeto, radio, intensidad) {
    this._sis = sistema;
    this.objeto = objeto;
    this.radio = radio;
    this.intensidad = intensidad;
    this.ranura = -1;
    this.activo = true;
    this.sucia = true;
    this._x = NaN; this._y = NaN; this._z = NaN;
  }

  /** Cambiar tamaño o fuerza en caliente (obra terminada, mejora de edad…). */
  ajustar(radio, intensidad) {
    if (typeof radio === 'number' && radio > 0) this.radio = radio;
    if (typeof intensidad === 'number') this.intensidad = acotar(intensidad, 0, 1);
    this.sucia = true;
    return this;
  }

  /** Devuelve la ranura. Idempotente; llamarla dos veces no rompe nada. */
  liberar() {
    if (!this.activo) return;
    this.activo = false;
    this._sis._soltarRanura(this.ranura);
    this.ranura = -1;
    this.objeto = null;
  }
}

/** Sólo los materiales que compilan `lights_fragment_begin` necesitan CSM. */
function esIluminado(m) {
  return !!m && (m.isMeshStandardMaterial || m.isMeshPhysicalMaterial
    || m.isMeshPhongMaterial || m.isMeshLambertMaterial || m.isMeshToonMaterial);
}

export class Sombras {
  constructor(ctx) {
    this.nombre = 'sombras';
    this.orden = 99;              // después de Cielo (mismo orden, se registra después)
    this.ctx = ctx;

    this.csm = null;
    this.luzSimple = null;
    this.luzPropia = false;
    this.materiales = new Set();
    this.generacion = 1;

    this.dirLuz = new THREE.Vector3(-0.42, -0.82, -0.46).normalize();
    this._preset = this._presetDe(ctx.render?.preset ?? ctx.calidad);
    this._frames = 0;
    this._barridoPendiente = true;
    this._camNear = -1; this._camFar = -1; this._camFov = -1; this._camAspect = -1;
    this._maxFarActual = 0;
    // banda de suelo visible, reusada: se recalcula sin asignar nada
    this._banda = { cerca: 0, lejos: 0 };
    this._bandaCerca = -1; this._bandaLejos = -1;

    /* ── manchas de contacto ── */
    this.manchasMalla = null;       // InstancedMesh compartido
    this._manchaTex = null;
    this._manchaMat = null;
    this._manchaGeo = null;
    this._manchaIntensidad = null;  // fuerza escrita en cada ranura (evita subir color de más)
    this._manchaCap = 0;
    this._manchaAlto = 0;           // marca de agua: cuántas ranuras se usaron alguna vez
    this._manchaLibres = [];        // ranuras devueltas, para reusar
    this._manchaSucia = false;
    this._manchaColorSucio = false;
    this._manchasVivas = [];        // handles pedidos a mano por otros módulos
    this._manchasAuto = new Map();  // id de entidad -> entrada auto
    this._manchaPool = [];          // entradas auto recicladas
    this._manchaGen = 0;
    this._manchaVistas = 0;
    // callback fijo del barrido por tipo: se crea UNA vez, no por frame
    this._sellarSombra = (o) => {
      if (!o.isMesh || o.userData.__sombraGen === this.generacion) return;
      const m = o.material;
      const mat = Array.isArray(m) ? m[0] : m;
      // los materiales sin iluminación de esta escena son calcos, fantasmas y
      // barras de vida: no tienen volumen que proyectar
      if (!esIluminado(mat)) return;
      o.userData.__sombraGen = this.generacion;
      if (o.userData.sinProyectarSombra !== true) o.castShadow = true;
      if (o.userData.sinRecibirSombra !== true) o.receiveShadow = true;
    };

    // callback fijo para barrer el Map sin crear un closure por frame
    this._barrerAuto = (entrada, id) => {
      if (entrada.gen === this._manchaGen) return;
      this._soltarRanura(entrada.ranura);
      this._manchasAuto.delete(id);
      if (this._manchaPool.length < 256) this._manchaPool.push(entrada);
    };

    this._leerDireccion();
    this._construir();
    this._registrarEscena();
    this._engancharCalidad();
    this._engancharBus();
  }

  /* ════════════════════════════ construcción ════════════════════════════ */

  _presetDe(p) {
    if (p && typeof p === 'object') return p;
    const tabla = {
      baja: { sombras: 1024, cascadas: 2, dist: 260 },
      media: { sombras: 2048, cascadas: 3, dist: 400 },
      alta: { sombras: 2048, cascadas: 4, dist: 600 },
      ultra: { sombras: 4096, cascadas: 4, dist: 900 },
    };
    return tabla[p] || tabla.alta;
  }

  /**
   * Alcance de las cascadas. Se ata al zoom: de cerca no tiene sentido gastar
   * resolución en 600 m de terreno que igual no se ve, y de lejos hace falta que
   * la montaña del fondo siga proyectando.
   */
  _maxFar() {
    const d = this.ctx.camCtrl?.distancia ?? 78;
    const techo = Math.min(this._preset.dist ?? 600, 640);
    return acotar(d * 4.4 + 70, 170, techo);
  }

  /**
   * DÓNDE ESTÁ EL SUELO, medido en profundidad de vista (metros a lo largo del
   * eje de la cámara), que es la unidad en la que CSM parte el frustum.
   *
   * Hace falta porque en un RTS cenital entre el ojo y el primer píxel de pasto
   * hay decenas de metros de AIRE. Con la cámara canónica —78 m de órbita, 49°
   * de elevación, fov 45— el ojo va a 59 m de altura y el suelo visible arranca
   * recién a 62 m de profundidad de vista y termina a 131 m. Todo lo anterior a
   * esos 62 m es cielo.
   */
  _bandaSuelo(lejos) {
    const cam = this.ctx.camara;
    const ctrl = this.ctx.camCtrl;
    const dist = ctrl?.distancia ?? 78;
    const elev = typeof ctrl?.elevacion === 'number' ? acotar(ctrl.elevacion, 0.12, 1.5) : 0.86;
    const alto = Math.max(2, dist * Math.sin(elev));
    const medioFov = (cam?.fov ?? 45) * 0.5 * Math.PI / 180;
    // borde inferior del cuadro: el suelo más cercano que el jugador ve
    const abajo = Math.min(elev + medioFov, Math.PI * 0.5);
    // borde superior: si mira casi al horizonte se acota, si no el seno tiende a 0
    const arriba = Math.max(elev - medioFov, 0.075);
    const banda = this._banda;
    banda.cerca = acotar(alto / Math.sin(abajo), 4, lejos * 0.80);
    banda.lejos = acotar(alto / Math.sin(arriba), banda.cerca * 1.3, lejos * 0.92);
    return banda;
  }

  /**
   * Reparto de cascadas (los "cortes", normalizados contra `lejos`).
   *
   * EL DEFECTO QUE ARREGLA (medido en vivo antes de tocar nada): el reparto
   * anterior arrancaba el logarítmico en `distancia * 0.34` ≈ 26 m y cerraba la
   * primera cascada en 62 m, o sea JUSTO ANTES de que empezara el suelo. Los
   * lados de cascada que salían eran 98 / 190 / 354 / 661 m ⇒ 4,8 / 9,3 / 17,3 /
   * 32,3 cm por téxel en un mapa de 2048. La cascada 0, la fina, no tocaba un
   * solo píxel de terreno: se gastaba entera en aire. Todo lo que el jugador
   * mira caía en las cascadas 1 y 2, a 9 y 17 cm por téxel.
   *
   * A ese téxel la sombra de un soldado —1,3 m de largo por 0,4 de ancho con el
   * sol a 55°— son tres o cuatro téxeles, y entre el PCF suave, el fundido entre
   * cascadas y el sesgo se disuelve hasta desaparecer. La de un pino de 10 m con
   * 5 m de copa son cincuenta téxeles y sobrevive intacta. Ese es, literalmente,
   * el "los árboles proyectan sombra y los edificios y las unidades no" del
   * panel: no era `castShadow` (está puesto en todas las mallas, se verificó
   * objeto por objeto), era resolución de sombra tirada al cielo.
   *
   * EL REPARTO NUEVO: las primeras `cantidad - 1` cascadas se reparten LA BANDA
   * DE SUELO (mitad logarítmico, mitad uniforme) y la última se queda con el
   * horizonte, que es lo único que hay más allá. Con la cámara canónica da
   * cortes en 83 / 105 / 131 m ⇒ lados de 139 / 178 / 221 m ⇒ 6,8 / 8,7 / 10,8
   * cm por téxel sobre TODO el terreno visible. Los primeros ~42 m de suelo —el
   * tercio inferior del cuadro, donde el jugador tiene las unidades— pasan de
   * 9,3 a 6,8 cm, y el fondo del cuadro de 17,3 a 10,8. Ninguna parte jugable
   * ve ya el téxel de 32 cm, que queda para los cerros del fondo.
   *
   * Que la cascada 0 siga empezando en el near de la cámara no cuesta nada: CSM
   * dimensiona su ortográfica con la DIAGONAL DEL PLANO LEJANO del trozo, así
   * que el téxel depende del corte de adelante, no de cuánto aire hay atrás.
   */
  _calcularCortes(cantidad, cerca, lejos, salida) {
    if (cantidad <= 1) { salida.push(1); return; }
    const banda = this._bandaSuelo(lejos);
    const n = cantidad - 1;
    const razon = Math.max(1.02, banda.lejos / banda.cerca);
    let previo = 0;
    for (let i = 1; i <= n; i++) {
      const t = i / n;
      const log = banda.cerca * Math.pow(razon, t);
      const uni = banda.cerca + (banda.lejos - banda.cerca) * t;
      const d = LAMBDA_CORTES * log + (1 - LAMBDA_CORTES) * uni;
      // estrictamente creciente: dos cortes iguales le dan a CSM una cascada
      // degenerada y el mapa de esa cascada sale vacío
      previo = acotar(Math.max(d / lejos, previo + 0.004), 0.02, 0.985);
      salida.push(previo);
    }
    salida.push(1);
  }

  _leerDireccion() {
    const cielo = this.ctx.cielo;
    const dir = cielo?.dirLuzDominante || cielo?.dirSol;
    if (dir && dir.lengthSq() > 1e-6) this.dirLuz.copy(dir).multiplyScalar(-1).normalize();
    // una luz perfectamente cenital deja todo sin sombra lateral: se inclina un pelo
    if (Math.abs(this.dirLuz.y) > 0.998) this.dirLuz.set(-0.12, this.dirLuz.y, -0.08).normalize();
  }

  _construir() {
    const ctx = this.ctx;
    const cascadas = acotar(Math.round(this._preset.cascadas ?? 3), 1, 4);
    const tamMapa = acotar(this._preset.sombras ?? 2048, 512, 4096);
    this._maxFarActual = this._maxFar();

    try {
      if (!ctx.camara || !ctx.escena) throw new Error('faltan cámara o escena');
      const csm = new CSM({
        camera: ctx.camara,
        parent: ctx.escena,
        cascades: cascadas,
        maxFar: this._maxFarActual,
        // 'practical' de fábrica reparte con lambda 0,5 y arrancando desde el
        // near REAL de la cámara (0,4–2 m). En un RTS no hay nada pegado al ojo:
        // eso regalaba la primera cascada a metros de aire y dejaba el suelo que
        // el jugador mira (40–70 m) en la segunda, con el doble de téxel.
        mode: 'custom',
        customSplitsCallback: (cantidad, cerca, lejos, salida) =>
          this._calcularCortes(cantidad, cerca, lejos, salida),
        shadowMapSize: tamMapa,
        lightDirection: this.dirLuz.clone(),
        lightIntensity: 1,
        lightNear: 1,
        lightFar: 1200,
        lightMargin: 170,
      });
      // el fundido entre cascadas cuesta unos ciclos pero borra la costura, que a
      // esta distancia de cámara se lee como una raya en el pasto
      csm.fade = cascadas >= 3;
      for (const luz of csm.lights) {
        luz.name = 'sol-cascada';
        luz.shadow.intensity = SOMBRA_INTENSIDAD;
      }
      this.csm = csm;
      this.csm.updateFrustums();
      this._afinarSesgo();
      this._delegarSol(true);
    } catch (e) {
      console.warn('[Sombras] CSM no disponible, caigo a sombra direccional encajada:', e?.message || e);
      this.csm = null;
      this._construirSimple();
    }
  }

  _construirSimple() {
    const ctx = this.ctx;
    let luz = ctx.cielo?.sol;
    this.luzPropia = false;
    if (!luz || !luz.isDirectionalLight) {
      luz = new THREE.DirectionalLight(0xfff3e0, 3.2);
      luz.name = 'sol-sombra';
      luz.target.position.set(0, 0, 0);
      ctx.escena?.add(luz, luz.target);
      this.luzPropia = true;
    }
    // una sola cascada: se le da el doble de mapa para compensar
    const m = acotar((this._preset.sombras ?? 2048) * 2, 1024, 4096);
    luz.castShadow = true;
    luz.shadow.mapSize.set(m, m);
    luz.shadow.map?.dispose?.();
    luz.shadow.map = null;
    luz.shadow.camera.near = 1;
    luz.shadow.camera.far = 1200;
    luz.shadow.bias = -0.00012;
    luz.shadow.normalBias = 0.03;
    luz.shadow.intensity = SOMBRA_INTENSIDAD;
    this.luzSimple = luz;
    this._delegarSol(false);
  }

  /** Apaga (o devuelve) el DirectionalLight de Cielo. Dos soles = doble luz. */
  _delegarSol(activo) {
    const cielo = this.ctx.cielo;
    if (!cielo) return;
    cielo._solDelegado = !!activo;
    if (cielo.sol) {
      if (activo) { cielo.sol.visible = false; cielo.sol.castShadow = false; }
      else { cielo.sol.castShadow = true; }
    }
  }

  /**
   * Sesgo por cascada, derivado del téxel real de cada mapa.
   *
   *   · `normalBias` va en METROS de mundo y despega la sombra del objeto: es el
   *     peter-panning. Se lo acota a `NORMAL_BIAS_MAX` (5 cm) pase lo que pase.
   *     Antes el techo era 0,8 m y en las cascadas lejanas —o en los presets
   *     baja y media, donde el téxel es gordo— se iba al tope: la sombra del
   *     molino aterrizaba medio metro más allá de su base mientras el pino de al
   *     lado, resuelto por otra cascada, caía bien. De ahí las "dos leyes de
   *     sombra en el mismo cuadro".
   *   · El acné lo mata `bias`, que corre la comparación a lo largo del RAYO de
   *     luz (desliza la sombra, no la despega). Se expresa en metros y se
   *     normaliza contra el rango de profundidad de ESA cascada.
   *   · Ese rango también se recorta acá. El constructor pide near/far 1–1200 m
   *     para todas; una cascada cercana sólo necesita el margen de luz más su
   *     propio ancho, y pasar de 1200 m a ~300 m de rango cuadruplica la
   *     precisión del depth buffer, que es lo que permite un bias tan fino.
   */
  _afinarSesgo() {
    if (!this.csm) return;
    const margen = this.csm.lightMargin ?? 200;
    for (const luz of this.csm.lights) {
      const c = luz.shadow.camera;
      const lado = Math.max(1e-3, c.right - c.left);
      const texel = lado / this.csm.shadowMapSize;

      // el bbox en espacio de luz nunca es más profundo que el diámetro del
      // trozo de frustum, o sea `lado`; el +30 es colchón para casos oblicuos
      c.near = 1;
      c.far = Math.min(this.csm.lightFar, margen + lado * 1.05 + 30);
      c.updateProjectionMatrix();
      const rango = Math.max(1, c.far - c.near);

      // 1,75 téxeles cubren el peor gradiente que puede leer el kernel PCF
      const metros = texel * 1.75 + 0.02;
      luz.shadow.bias = -acotar(metros / rango, 1e-6, 4e-3);
      luz.shadow.normalBias = acotar(texel * 0.9, 0.004, NORMAL_BIAS_MAX);
      luz.shadow.radius = 1;
      luz.shadow.intensity = SOMBRA_INTENSIDAD;
    }
  }

  _engancharCalidad() {
    const render = this.ctx.render;
    if (!render) return;
    const previo = render.onCalidad;
    render.onCalidad = (preset) => {
      try { previo?.(preset); } catch (e) { console.error('[Sombras] onCalidad previo', e); }
      this.setCalidad(preset);
    };
  }

  _engancharBus() {
    const bus = this.ctx.bus;
    if (!bus?.on) return;
    const marcar = () => { this._barridoPendiente = true; };
    bus.on('juego:listo', marcar);
    bus.on('entidad:creada', marcar);
    bus.on('edad:avanzada', marcar);
  }

  /* ══════════════════════════ registro de materiales ══════════════════════════ */

  /**
   * Idempotente. Encadena con el `onBeforeCompile` que el material ya tuviera
   * (el foliaje mete el viento por ahí y CSM lo pisaría), salvo con el material
   * de terreno, que se encadena solo del otro lado: hacerlo dos veces le
   * duplicaría las declaraciones GLSL.
   */
  registrarMaterial(material) {
    if (!esIluminado(material) || !this.csm) return material;
    this.materiales.add(material);
    const ud = material.userData || (material.userData = {});
    if (ud.__csmGen === this.generacion) return material;
    if (ud.__csmGen !== undefined) this._restaurarMaterial(material);

    if (!ud.__csmGuardado) {
      ud.__csmObcOriginal = material.onBeforeCompile;
      ud.__csmClaveOriginal = material.customProgramCacheKey;
      ud.__csmGuardado = true;
    }
    const previo = ud.__csmObcOriginal;
    const clavePrevia = ud.__csmClaveOriginal;

    this.csm.setupMaterial(material);
    const deCSM = material.onBeforeCompile;

    // Terreno.js guarda su parche en userData y lo vuelve a aplicar él mismo.
    const seEncadenaSolo = previo && ud.alCompilarTerreno === previo;
    if (previo && !seEncadenaSolo) {
      material.onBeforeCompile = function (shader, renderizador) {
        deCSM.call(this, shader, renderizador);
        previo.call(this, shader, renderizador);
      };
    }

    const sufijo = `csm${this.csm.cascades}${this.csm.fade ? 'f' : ''}`;
    material.customProgramCacheKey = clavePrevia
      ? function () { return `${sufijo}|${clavePrevia.call(this)}`; }
      : () => sufijo;

    ud.__csmGen = this.generacion;
    material.needsUpdate = true;
    return material;
  }

  _restaurarMaterial(material) {
    const ud = material.userData || {};
    if (ud.__csmGuardado) {
      if (ud.__csmObcOriginal) material.onBeforeCompile = ud.__csmObcOriginal;
      else delete material.onBeforeCompile;
      if (ud.__csmClaveOriginal) material.customProgramCacheKey = ud.__csmClaveOriginal;
      else delete material.customProgramCacheKey;
    }
    if (material.defines) {
      delete material.defines.USE_CSM;
      delete material.defines.CSM_CASCADES;
      delete material.defines.CSM_FADE;
    }
    delete ud.__csmGen;
    material.needsUpdate = true;
  }

  /**
   * Barrido de seguridad: cualquier material iluminado que todavía no pasó.
   *
   * De paso arregla la asimetría que rompía la lectura del volumen: había mallas
   * con `castShadow` y sin `receiveShadow` (las unidades, por ejemplo). Un
   * soldado que proyecta pero no recibe queda plano y flotando cuando entra en
   * la sombra de un edificio: se ilumina como si estuviera al sol. Si tira
   * sombra, la recibe. Se puede optar por salirse con
   * `objeto.userData.sinRecibirSombra = true` (humo, banderines, calcos).
   */
  _registrarEscena() {
    const escena = this.ctx.escena;
    if (!escena) return;
    escena.traverse((o) => {
      const m = o.material;
      if (!m) return;
      if (Array.isArray(m)) {
        if (this.csm) for (let i = 0; i < m.length; i++) this.registrarMaterial(m[i]);
        if (o.castShadow && !o.receiveShadow && !o.userData?.sinRecibirSombra && esIluminado(m[0])) {
          o.receiveShadow = true;
        }
        return;
      }
      if (this.csm) this.registrarMaterial(m);
      if (o.castShadow && !o.receiveShadow && !o.userData?.sinRecibirSombra && esIluminado(m)) {
        o.receiveShadow = true;
      }
    });
  }

  /**
   * Barrido POR TIPO DE OBJETO sobre las raíces de entidades.
   *
   * `_registrarEscena` arregla el par proyectar/recibir sólo cuando la malla ya
   * proyecta. Falta el caso contrario, que es el que se cuela: mallas de
   * edificio creadas a propósito con `castShadow = false` porque nacen ocultas
   * —los estados de daño `danio1`/`danio2`, los cimientos, los andamios— y que
   * cuando el edificio se rompe o entra en obra se hacen visibles arrastrando el
   * flag apagado. Un edificio a media vida perdía media sombra.
   *
   * Se recorre sólo `vista.raiz` y `vista.raizInstancias` (no la escena entera,
   * que ya la barre el otro paso) y cada malla se sella con la generación, así
   * que después del primer frame esto es un traverse con una comparación de
   * enteros por nodo. Los fantasmas de emplazado viven en otra raíz y quedan
   * fuera a propósito: un edificio que todavía no existe no proyecta.
   *
   * Se puede optar por salirse con `userData.sinProyectarSombra` /
   * `userData.sinRecibirSombra`.
   */
  _barrerEntidades() {
    const vista = this.ctx.vista;
    if (!vista) return;
    vista.raiz?.traverse(this._sellarSombra);
    vista.raizInstancias?.traverse(this._sellarSombra);
  }

  /* ════════════════════════════ por frame ════════════════════════════ */

  cada(dtReal, alfa, ctx) {
    const cam = ctx.camara;
    if (!cam) return;
    cam.updateMatrixWorld();
    this._leerDireccion();
    this._sincronizarLuces();

    if (this.csm) {
      this.csm.lightDirection.copy(this.dirLuz);
      const objetivo = this._maxFar();
      if (this._frustumCambio(cam, objetivo)) {
        this.csm.maxFar = this._maxFarActual = objetivo;
        this.csm.updateFrustums();
        this._afinarSesgo();
      }
      this.csm.update();
    } else if (this.luzSimple) {
      this._encajarSimple(cam);
    }

    this._frames++;
    // El barrido va POR FRAME a propósito. Un material que se compila sin el
    // parche de CSM recibe las N cascadas sumadas y sale quemado a blanco; con
    // un barrido cada 30 frames, cada unidad o edificio nuevo aparecía medio
    // segundo en blanco. registrarMaterial() corta en seco si el material ya
    // está en la generación actual, así que esto es un traverse y nada más.
    this._barridoPendiente = false;
    this._registrarEscena();
    this._barrerEntidades();
    this._actualizarManchas();
  }

  /**
   * Los cortes dependen ahora de la BANDA DE SUELO, que se mueve con la
   * elevación de la cámara y no sólo con el zoom: si el jugador se acuesta sobre
   * el horizonte sin cambiar la distancia, `maxFar` no se entera pero la banda
   * se estira al doble. Sin vigilarla, las cascadas se quedaban con el reparto
   * de la elevación anterior y el suelo cercano volvía a caer en un téxel gordo.
   */
  _frustumCambio(cam, maxFar) {
    const banda = this._bandaSuelo(maxFar);
    const cambio = Math.abs(cam.near - this._camNear) > this._camNear * 0.02
      || Math.abs(cam.far - this._camFar) > 1
      || Math.abs(cam.fov - this._camFov) > 0.01
      || Math.abs(cam.aspect - this._camAspect) > 0.001
      || Math.abs(maxFar - this._maxFarActual) > this._maxFarActual * 0.04
      || Math.abs(banda.cerca - this._bandaCerca) > this._bandaCerca * 0.04
      || Math.abs(banda.lejos - this._bandaLejos) > this._bandaLejos * 0.04;
    if (cambio) {
      this._camNear = cam.near; this._camFar = cam.far;
      this._camFov = cam.fov; this._camAspect = cam.aspect;
      this._bandaCerca = banda.cerca; this._bandaLejos = banda.lejos;
    }
    return cambio;
  }

  /** Color e intensidad salen de Cielo: el amanecer tiñe también las cascadas. */
  _sincronizarLuces() {
    const sol = this.ctx.cielo?.sol;
    const intensidad = sol ? sol.intensity : 3.2;
    if (this.csm) {
      for (const luz of this.csm.lights) {
        if (sol) luz.color.copy(sol.color);
        luz.intensity = intensidad;
      }
    } else if (this.luzSimple && this.luzPropia) {
      if (sol) this.luzSimple.color.copy(sol.color);
      this.luzSimple.intensity = intensidad;
    }
  }

  /**
   * Modo simple: se toman las 8 esquinas del frustum visible recortado a maxFar,
   * se las lleva al espacio de la luz, y la ortográfica se encaja a esa caja.
   * El centro se engancha a la grilla de téxeles para que la sombra no titile.
   */
  _encajarSimple(cam) {
    const luz = this.luzSimple;
    if (!luz) return;
    const lejos = Math.min(cam.far, this._maxFar());
    const cerca = Math.max(cam.near, 0.4);
    const tanY = Math.tan(cam.fov * 0.5 * Math.PI / 180);
    const tanX = tanY * cam.aspect;
    let k = 0;
    for (let e = 0; e < 2; e++) {
      const d = e === 0 ? cerca : lejos;
      for (let sy = -1; sy <= 1; sy += 2) {
        for (let sx = -1; sx <= 1; sx += 2) {
          _esquinas[k++].set(sx * tanX * d, sy * tanY * d, -d).applyMatrix4(cam.matrixWorld);
        }
      }
    }
    _mOrient.lookAt(_origen, this.dirLuz, _arriba);
    _mOrientInv.copy(_mOrient).invert();
    _caja.makeEmpty();
    for (let i = 0; i < 8; i++) _caja.expandByPoint(_tmp.copy(_esquinas[i]).applyMatrix4(_mOrientInv));

    const c = luz.shadow.camera;
    const lado = Math.max(_caja.max.x - _caja.min.x, _caja.max.y - _caja.min.y) * 0.5 + 2;
    const mapa = luz.shadow.mapSize.x || 2048;
    const texel = (lado * 2) / mapa;
    _caja.getCenter(_centro);
    _centro.x = Math.floor(_centro.x / texel) * texel;
    _centro.y = Math.floor(_centro.y / texel) * texel;
    _centro.z = _caja.max.z + 170;
    _centro.applyMatrix4(_mOrient);

    luz.position.copy(_centro);
    luz.target.position.copy(_centro).add(this.dirLuz);
    luz.target.updateMatrixWorld();
    c.left = -lado; c.right = lado; c.top = lado; c.bottom = -lado;
    c.near = 1;
    c.far = 190 + (_caja.max.z - _caja.min.z);
    c.updateProjectionMatrix();
    // mismo criterio que en CSM: el corrimiento por normal se queda en
    // centímetros (si no, la sombra se despega de la base) y el acné lo cubre el
    // bias de profundidad, escalado al téxel y al rango real de la cámara
    luz.shadow.normalBias = acotar(texel * 0.9, 0.004, NORMAL_BIAS_MAX);
    luz.shadow.bias = -acotar((texel * 1.75 + 0.02) / Math.max(1, c.far - c.near), 1e-6, 4e-3);
    luz.shadow.intensity = SOMBRA_INTENSIDAD;
  }

  /* ═══════════════════ manchas de contacto (oclusión barata) ═══════════════════ */

  /**
   * Mancha de contacto: el parche oscuro que PEGA un objeto al piso.
   *
   * Por qué existe además del mapa de sombras: el CSM resuelve la sombra
   * proyectada del sol, pero no el oscurecimiento de contacto —el ambiente que
   * queda atrapado entre la base del objeto y el suelo—. Eso lo daba el GTAO,
   * que está APAGADO en los presets baja y media: ahí los edificios flotaban
   * sobre el pasto. Y cuando el sol pega casi de frente la sombra proyectada se
   * va lejos y tampoco ancla nada. Esto es la versión barata y siempre activa:
   * un quad con gradiente radial procedural, multiplicativo, apoyado en el
   * terreno y orientado a su normal, todo en un solo InstancedMesh (una llamada
   * de dibujo para toda la partida).
   *
   * USO desde cualquier módulo:
   *   const h = ctx.sombras.mancha(malla, 2.4, 0.55);  // objeto3D, radio m, 0..1
   *   h.ajustar(3.1, 0.6);   // si el objeto cambia de tamaño (obra terminada)
   *   h.liberar();           // al destruirlo; si te olvidás, se libera sola en
   *                          // cuanto el objeto sale de la escena (parent null)
   *
   * El objeto se sigue POR REFERENCIA: se lee su matriz mundial cada frame y la
   * mancha lo persigue, se apaga si `objeto.visible` es false y se apoya a la
   * altura y la pendiente del terreno bajo él (no a la Y del objeto: si está en
   * el aire, la mancha se abre y se desvanece, como corresponde).
   *
   * Las unidades, edificios y recursos registrados en `VistaEntidades` YA
   * reciben la suya automáticamente (`_manchasAuto`), sin que nadie llame a
   * nada: esto es para props sueltos —carretas, muros, decorados, cadáveres—.
   *
   * @param {THREE.Object3D} objeto  al que seguir
   * @param {number} radio           radio de la huella, en metros
   * @param {number} intensidad      0 = nada, 1 = negro debajo del objeto
   * @returns {ManchaContacto} handle con `.ajustar()` y `.liberar()`
   */
  mancha(objeto, radio = 1, intensidad = 0.5) {
    const h = new ManchaContacto(this, objeto, Math.max(0.2, radio), acotar(intensidad, 0, 1));
    if (objeto) this._manchasVivas.push(h);
    return h;
  }

  /**
   * Textura de la mancha: un gradiente radial generado a mano.
   *
   * EL PERFIL ES EL ARREGLO, no el tamaño. Se midió en vivo (render con el
   * InstancedMesh prendido menos render con el InstancedMesh apagado, sobre el
   * mismo cuadro): la mancha de una unidad tocaba el 3,8% de los píxeles pero
   * el 90% de esa superficie estaba por debajo de 15/255 de diferencia. O sea:
   * había mancha, no había CONTRASTE LOCAL, que es exactamente la métrica que
   * el panel dijo que teníamos que empezar a mirar. Una diferencia repartida en
   * cuarenta píxeles no la ve nadie; la misma diferencia concentrada en cinco,
   * sí.
   *
   * Perfil nuevo, de adentro hacia afuera:
   *   · centro (r < 0,55·núcleo): `MANCHA_CENTRO`. Va un pelo más claro que el
   *     anillo porque la oclusión bajo el cuerpo se rebota contra sí misma, y
   *     porque este tramo se lo tapa el propio objeto: gastar el negro acá es
   *     tirarlo.
   *   · ANILLO DE CONTACTO (0,55·núcleo … núcleo): `MANCHA_ANILLO`, el máximo.
   *     Es la línea donde el objeto se apoya y la única parte del disco que el
   *     jugador ve entera.
   *   · falda (núcleo … `MANCHA_BORDE`): cae con smoothstep al cuadrado, o sea
   *     rápido al principio y suave al final: filo sin recorte duro.
   *   · guarda (más allá de `MANCHA_BORDE`): cero, para que no se lea el quad.
   *
   * Va con un tinte que ocluye un poco más el azul que el rojo: lo que sobrevive
   * en la mancha queda cálido, que es justo lo contrario de la sombra azulada
   * que nos marcaron. Se guarda LINEAL (`NoColorSpace`): esto se multiplica
   * ANTES del tone mapping, no es un color de pantalla.
   */
  _texturaMancha() {
    if (this._manchaTex) return this._manchaTex;
    // 128 y no 64: el anillo ocupa el 23% del radio del quad y con 32 téxeles de
    // radio útil quedaba resuelto en siete, que el mipmap se comía a media
    // distancia justo cuando el jugador se aleja para mirar el ejército entero
    const N = 128;
    const datos = new Uint8Array(N * N * 4);
    const tinte = [0.94, 0.97, 1.0];
    const inicioAnillo = MANCHA_NUCLEO * 0.55;
    const falda = Math.max(1e-3, MANCHA_BORDE - MANCHA_NUCLEO);
    for (let f = 0; f < N; f++) {
      for (let c = 0; c < N; c++) {
        const x = ((c + 0.5) / N) * 2 - 1;
        const y = ((f + 0.5) / N) * 2 - 1;
        const r = Math.sqrt(x * x + y * y);
        let o;
        if (r <= inicioAnillo) {
          // subida corta del centro al anillo: sin escalón visible
          const t = r / inicioAnillo;
          o = MANCHA_CENTRO + (MANCHA_ANILLO - MANCHA_CENTRO) * t * t;
        } else if (r <= MANCHA_NUCLEO) {
          o = MANCHA_ANILLO;
        } else {
          const t = acotar((r - MANCHA_NUCLEO) / falda, 0, 1);
          const s = 1 - t * t * (3 - 2 * t);
          // exponente 1,5 y no 2: al cuadrado la falda se moría demasiado
          // rápido y el disco terminaba con canto de moneda
          o = MANCHA_ANILLO * Math.pow(s, 1.5);
        }
        const i = (f * N + c) * 4;
        datos[i] = Math.round(255 * o * tinte[0]);
        datos[i + 1] = Math.round(255 * o * tinte[1]);
        datos[i + 2] = Math.round(255 * o * tinte[2]);
        datos[i + 3] = 255;
      }
    }
    const tex = new THREE.DataTexture(datos, N, N, THREE.RGBAFormat);
    tex.colorSpace = THREE.NoColorSpace;
    tex.wrapS = tex.wrapT = THREE.ClampToEdgeWrapping;
    tex.magFilter = THREE.LinearFilter;
    tex.minFilter = THREE.LinearMipmapLinearFilter;
    tex.generateMipmaps = true;
    const maxAniso = this.ctx.renderer?.capabilities?.getMaxAnisotropy?.() ?? 1;
    tex.anisotropy = Math.min(4, maxAniso);
    tex.needsUpdate = true;
    this._manchaTex = tex;
    return tex;
  }

  /**
   * Material multiplicativo puro: `destino * (1 - fuente)`.
   *
   * No se usa alpha ni `MultiplyBlending` porque necesito modular la fuerza POR
   * INSTANCIA, y lo único por instancia que llega barato al shader es el color.
   * Con `Zero / OneMinusSrcColor` el color de la instancia ES la fuerza de la
   * mancha, y el resultado es un multiplicador honesto sobre valores LINEALES
   * HDR (el tone mapping llega después, en OutputPass: una constante pensada
   * para 0..1 acá haría desastres).
   */
  _materialMancha() {
    if (this._manchaMat) return this._manchaMat;
    this._manchaMat = new THREE.MeshBasicMaterial({
      map: this._texturaMancha(),
      color: 0xffffff,
      transparent: true,          // para que entre en la cola de transparentes
      depthWrite: false,
      depthTest: true,
      blending: THREE.CustomBlending,
      blendEquation: THREE.AddEquation,
      blendSrc: THREE.ZeroFactor,
      blendDst: THREE.OneMinusSrcColorFactor,
      blendSrcAlpha: THREE.ZeroFactor,
      blendDstAlpha: THREE.OneFactor,   // el alpha del buffer queda como estaba
      fog: false,                 // es un multiplicador, la niebla lo ensuciaría
      toneMapped: false,
      polygonOffset: true,        // seguro extra contra el z-fighting en pendiente
      polygonOffsetFactor: -2,
      polygonOffsetUnits: -2,
      side: THREE.FrontSide,
    });
    return this._manchaMat;
  }

  /** Crea (o agranda) el InstancedMesh compartido. Devuelve si hay malla usable. */
  _asegurarMalla() {
    if (this.manchasMalla) return true;
    const escena = this.ctx.escena;
    if (!escena) return false;
    this._crearMalla(MANCHA_CAP_MIN);
    return !!this.manchasMalla;
  }

  _crearMalla(cap) {
    if (!this._manchaGeo) {
      // el plano nace de pie; se lo tumba una vez en la geometría para que la
      // normal de la instancia sea +Y y la orientación se resuelva con un quat
      this._manchaGeo = new THREE.PlaneGeometry(1, 1);
      this._manchaGeo.rotateX(-Math.PI / 2);
    }
    const malla = new THREE.InstancedMesh(this._manchaGeo, this._materialMancha(), cap);
    malla.name = 'manchas-contacto';
    malla.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    malla.setColorAt(0, _mColor.setRGB(0.5, 0.5, 0.5));
    malla.instanceColor.setUsage(THREE.DynamicDrawUsage);
    malla.castShadow = false;
    malla.receiveShadow = false;
    malla.frustumCulled = false;   // es UNA llamada de dibujo: culliarla no paga
    malla.renderOrder = -2;        // después de lo opaco, antes de humo y chispas
    malla.matrixAutoUpdate = false;
    malla.count = 0;
    for (let i = 0; i < cap; i++) malla.setMatrixAt(i, _mCero);
    this.ctx.escena.add(malla);
    this.manchasMalla = malla;
    this._manchaCap = cap;
    const intensidades = new Float32Array(cap);
    if (this._manchaIntensidad) intensidades.set(this._manchaIntensidad.subarray(0, Math.min(cap, this._manchaIntensidad.length)));
    this._manchaIntensidad = intensidades;
  }

  _crecerMalla(cap) {
    const vieja = this.manchasMalla;
    if (!vieja) { this._crearMalla(cap); return; }
    const matrices = vieja.instanceMatrix.array;
    const colores = vieja.instanceColor?.array;
    this.ctx.escena?.remove(vieja);
    vieja.dispose();
    this.manchasMalla = null;
    this._crearMalla(cap);
    const nueva = this.manchasMalla;
    nueva.instanceMatrix.array.set(matrices);
    if (colores && nueva.instanceColor) nueva.instanceColor.array.set(colores);
    nueva.instanceMatrix.needsUpdate = true;
    if (nueva.instanceColor) nueva.instanceColor.needsUpdate = true;
    nueva.count = this._manchaAlto;
  }

  _pedirRanura() {
    if (!this._asegurarMalla()) return -1;
    if (this._manchaLibres.length) return this._manchaLibres.pop();
    if (this._manchaAlto >= this._manchaCap) {
      if (this._manchaCap >= MANCHA_CAP_MAX) return -1;   // techo duro: nada de crecer sin fin
      this._crecerMalla(Math.min(MANCHA_CAP_MAX, this._manchaCap * 2));
    }
    return this._manchaAlto++;
  }

  _soltarRanura(ranura) {
    if (ranura < 0 || !this.manchasMalla) return;
    this.manchasMalla.setMatrixAt(ranura, _mCero);   // escala 0: triángulo degenerado
    this._manchaSucia = true;
    this._manchaLibres.push(ranura);
  }

  /**
   * Apoya una instancia en el terreno. Nada de asignar acá: todos los temporales
   * son de módulo. Si el objeto está por encima del suelo (unidad en una rampa
   * mal clavada, proyectil, pájaro) la mancha se agranda y se desvanece en vez
   * de seguirlo en el aire.
   *
   * El disco se orienta a la NORMAL del terreno, no al plano horizontal. En una
   * ladera un disco horizontal entra en el cerro por el lado de arriba y sale
   * flotando por el de abajo: se ve media mancha recortada y media despegada.
   * Con la normal queda tangente, y encima se lo levanta un pelo proporcional a
   * la pendiente (`1 - n.y` crece con el ángulo) porque el terreno bajo el disco
   * es convexo o cóncavo, no plano, y sin ese margen el borde de arriba se
   * hunde igual.
   */
  _escribirRanura(ranura, x, y, z, radio, intensidad) {
    const malla = this.manchasMalla;
    if (!malla || ranura < 0) return;
    const terreno = this.ctx.terreno;
    const base = terreno?.altura ? terreno.altura(x, z) : y;
    if (terreno?.normal) terreno.normal(x, z, _mNormal);
    else _mNormal.set(0, 1, 0);
    if (_mNormal.lengthSq() < 1e-6) _mNormal.set(0, 1, 0);

    let r = radio, fuerza = intensidad;
    const alto = y - base;
    if (alto > 0.25) {
      const t = acotar(alto / (radio * 4 + 3), 0, 1);
      r = radio * (1 + t * 0.9);
      fuerza = intensidad * (1 - t) * (1 - t);
    }

    const pendiente = 1 - acotar(_mNormal.y, 0, 1);
    _mPos.set(x, base + 0.035 + r * 0.004 + pendiente * r * 0.62, z);
    _mQuat.setFromUnitVectors(_arriba, _mNormal);
    const lado = r * MANCHA_QUAD;
    _mEscala.set(lado, 1, lado);
    _mMatriz.compose(_mPos, _mQuat, _mEscala);
    malla.setMatrixAt(ranura, _mMatriz);
    this._manchaSucia = true;

    if (Math.abs(this._manchaIntensidad[ranura] - fuerza) > 0.004) {
      this._manchaIntensidad[ranura] = fuerza;
      malla.setColorAt(ranura, _mColor.setRGB(fuerza, fuerza, fuerza));
      this._manchaColorSucio = true;
    }
  }

  _ocultarMancha(h) {
    if (h.ranura < 0) return;
    this._soltarRanura(h.ranura);
    h.ranura = -1;
    h._x = NaN;
  }

  /** Un paso por frame: handles a mano + entidades del juego + subida a la GPU. */
  _actualizarManchas() {
    const vivas = this._manchasVivas;
    const hayEntidades = !!this.ctx.vista?.lista?.length;
    if (!this.manchasMalla && !vivas.length && !hayEntidades) return;

    /* ── 1. handles explícitos ── */
    for (let i = vivas.length - 1; i >= 0; i--) {
      const h = vivas[i];
      if (!h.activo) { vivas.splice(i, 1); continue; }
      const obj = h.objeto;
      // si el objeto salió de la escena, la mancha se limpia sola: nadie tiene
      // que acordarse de liberarla cuando muere una unidad
      if (!obj || !obj.parent) { h.liberar(); vivas.splice(i, 1); continue; }
      if (!obj.visible) { this._ocultarMancha(h); continue; }
      const e = obj.matrixWorld.elements;
      const x = e[12], y = e[13], z = e[14];
      if (h.ranura < 0) { h.ranura = this._pedirRanura(); if (h.ranura < 0) continue; h.sucia = true; }
      if (h.sucia || Math.abs(x - h._x) > MANCHA_EPS
        || Math.abs(y - h._y) > MANCHA_EPS || Math.abs(z - h._z) > MANCHA_EPS) {
        this._escribirRanura(h.ranura, x, y, z, h.radio, h.intensidad);
        h._x = x; h._y = y; h._z = z; h.sucia = false;
      }
    }

    /* ── 2. entidades del juego, automático ── */
    if (hayEntidades) this._manchasAutoEntidades();

    /* ── 3. una sola subida por frame ── */
    const malla = this.manchasMalla;
    if (!malla) return;
    if (this._manchaSucia) { malla.instanceMatrix.needsUpdate = true; this._manchaSucia = false; }
    if (this._manchaColorSucio && malla.instanceColor) {
      malla.instanceColor.needsUpdate = true; this._manchaColorSucio = false;
    }
    malla.count = this._manchaAlto;
  }

  /**
   * Manchas automáticas para todo lo que `VistaEntidades` tiene vivo y visible.
   * Se lee su lista plana (sin tocar su código) y se lleva un mapa id→ranura con
   * marca de generación: lo que no se vio este frame (murió, se lo comió la
   * niebla, quedó fuera del alcance de sombra) devuelve su ranura.
   */
  /**
   * Radio de la HUELLA de una entidad, en metros: cuánto PISO ocupa.
   *
   * Hay dos fuentes posibles y ninguna sirve para todo:
   *
   *  · La caja envolvente de la malla mide la SILUETA, no la huella. En un
   *    edificio las dos coinciden (un galpón apoya todo su rectángulo) y por eso
   *    ahí se usa. En una unidad no: la caja de un colono la fija el pico que
   *    lleva en la mano y la de un fusilero el fusil, así que medía 1,9 m para
   *    un bicho que apoya 0,45. Con esa huella la mancha salía cuatro veces más
   *    grande que el cuerpo, o sea justo lo contrario de una sombra de contacto.
   *    Lo mismo, más suave, con la copa de un árbol.
   *
   *  · El radio de colisión mide exactamente el piso que ocupa: es el radio con
   *    el que la unidad empuja a las otras. Para las unidades ES la huella. En
   *    los edificios no sirve porque viene en CELDAS de rejilla, no en metros.
   *
   * De ahí `usaCaja` en `MANCHA_POR_TIPO`. La medición de caja corre UNA vez por
   * entidad y por edad (las mallas se reconstruyen al avanzar de edad) y sólo si
   * la entidad tiene malla cercana; de lejos, resuelta por instancias, vale el
   * radio y a esa distancia nadie nota la diferencia.
   */
  _radioHuella(reg, cfg) {
    const base = reg.radio > 0 ? reg.radio : 0.55;
    if (cfg && cfg.usaCaja === false) return base;
    if (reg.__huella > 0 && reg.__huellaEdad === reg.edad) return reg.__huella;
    const obj = reg.obj;
    if (!obj || !obj.parent) return base;
    _cajaHuella.setFromObject(obj);
    if (_cajaHuella.isEmpty()) return base;
    _cajaHuella.getSize(_tamHuella);
    const medio = Math.max(_tamHuella.x, _tamHuella.z) * 0.5;
    reg.__huella = acotar(Math.max(medio, base), 0.3, 14);
    reg.__huellaEdad = reg.edad;
    return reg.__huella;
  }

  _manchasAutoEntidades() {
    const lista = this.ctx.vista.lista;
    const mundo = this.ctx.mundo;
    const cam = this.ctx.camara;
    const cx = cam ? cam.position.x : 0;
    const cz = cam ? cam.position.z : 0;
    const alcance = (this._maxFarActual > 0 ? this._maxFarActual : 400) * 1.1;
    const alcance2 = alcance * alcance;

    this._manchaGen++;
    let vistas = 0;
    for (let i = 0; i < lista.length; i++) {
      const reg = lista[i];
      if (!reg || reg.visibleReal === false) continue;
      const cfg = MANCHA_POR_TIPO[reg.tipo];
      if (!cfg) continue;
      if (mundo?.vivo && !mundo.vivo[reg.id]) continue;
      const dx = reg.x - cx, dz = reg.z - cz;
      if (dx * dx + dz * dz > alcance2) continue;   // fuera de cuadro no paga

      let ent = this._manchasAuto.get(reg.id);
      if (!ent) {
        const ranura = this._pedirRanura();
        if (ranura < 0) continue;
        ent = this._manchaPool.pop() || { ranura: -1, x: NaN, y: NaN, z: NaN, r: 0, gen: 0 };
        ent.ranura = ranura; ent.x = NaN; ent.y = NaN; ent.z = NaN; ent.r = 0;
        this._manchasAuto.set(reg.id, ent);
      }
      ent.gen = this._manchaGen;
      vistas++;

      const radio = Math.max(0.3, this._radioHuella(reg, cfg) * cfg.factor);
      if (ent.r !== radio || Math.abs(reg.x - ent.x) > MANCHA_EPS
        || Math.abs(reg.y - ent.y) > MANCHA_EPS || Math.abs(reg.z - ent.z) > MANCHA_EPS) {
        this._escribirRanura(ent.ranura, reg.x, reg.y, reg.z, radio, cfg.fuerza);
        ent.x = reg.x; ent.y = reg.y; ent.z = reg.z; ent.r = radio;
      }
    }
    // barrer sólo cuando sobra algo: el caso normal (nada murió) no itera el Map
    if (vistas < this._manchasAuto.size) this._manchasAuto.forEach(this._barrerAuto);
  }

  /* ════════════════════════════ calidad ════════════════════════════ */

  setCalidad(preset) {
    const nuevo = this._presetDe(preset);
    const antes = this._preset;
    if (antes && nuevo.sombras === antes.sombras && nuevo.cascadas === antes.cascadas
      && nuevo.dist === antes.dist) return;
    this._preset = nuevo;

    if (!this.csm) {
      if (this.luzSimple) {
        const m = acotar((nuevo.sombras ?? 2048) * 2, 1024, 4096);
        this.luzSimple.shadow.mapSize.set(m, m);
        this.luzSimple.shadow.map?.dispose?.();
        this.luzSimple.shadow.map = null;
      }
      return;
    }

    const guardados = Array.from(this.materiales);
    for (const m of guardados) this._restaurarMaterial(m);
    this.csm.remove();
    this.csm.dispose?.();
    this.csm = null;
    this.generacion++;

    this._construir();
    for (const m of guardados) this.registrarMaterial(m);
    this._barridoPendiente = true;
  }

  /** Referencia de nitidez: metros por téxel de la primera cascada. */
  get metrosPorTexel() {
    if (this.csm?.lights?.length) {
      const c = this.csm.lights[0].shadow.camera;
      return (c.right - c.left) / this.csm.shadowMapSize;
    }
    if (this.luzSimple) {
      const c = this.luzSimple.shadow.camera;
      return (c.right - c.left) / (this.luzSimple.shadow.mapSize.x || 2048);
    }
    return 0;
  }

  dispose() {
    for (const m of this.materiales) this._restaurarMaterial(m);
    this.materiales.clear();

    for (let i = 0; i < this._manchasVivas.length; i++) this._manchasVivas[i].liberar();
    this._manchasVivas.length = 0;
    this._manchasAuto.clear();
    this._manchaLibres.length = 0;
    this._manchaAlto = 0;
    if (this.manchasMalla) {
      this.ctx.escena?.remove(this.manchasMalla);
      this.manchasMalla.dispose();
      this.manchasMalla = null;
    }
    this._manchaGeo?.dispose(); this._manchaGeo = null;
    this._manchaMat?.dispose(); this._manchaMat = null;
    this._manchaTex?.dispose(); this._manchaTex = null;
    if (this.csm) { this.csm.remove(); this.csm.dispose?.(); this.csm = null; }
    this._delegarSol(false);
    if (this.luzPropia && this.luzSimple) {
      this.ctx.escena?.remove(this.luzSimple, this.luzSimple.target);
      this.luzSimple.dispose?.();
    }
    this.luzSimple = null;
  }
}
