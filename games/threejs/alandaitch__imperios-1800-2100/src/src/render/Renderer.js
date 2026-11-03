/**
 * Pipeline de render: WebGL2, color linear-sRGB, ACES filmic, sombras cascada (CSM),
 * y una cadena de post-proceso con presets de calidad.
 *
 * ORDEN DE LA CADENA (y por qué):
 *
 *   RenderPass → GTAO → Bloom → OutputPass → SMAA → gradeoFinal(+nitidez) → pantalla
 *
 * OutputPass es quien aplica el tone mapping ACES y la codificación a sRGB. Todo lo
 * que corre ANTES de él trabaja sobre radiancia LINEAL HDR (el pasto a pleno sol ronda
 * 0.33, la nieve 1.14, el disco solar pasa de 3); todo lo que corre DESPUÉS trabaja
 * sobre 0..1 de pantalla. Meter constantes de LDR antes de OutputPass es el error que
 * nos hundía la imagen entera:
 *
 *   - el gradeo hacía `(c - 0.18) * contraste + 0.18` con el pivote de gris medio de
 *     PANTALLA aplicado sobre lineal, o sea que oscurecía todo lo que estuviera por
 *     debajo de 0.18 lineal, que es casi el cuadro completo;
 *   - la viñeta multiplicaba radiancia antes del tone mapping, hundiendo los bordes de
 *     forma irrecuperable;
 *   - el grano se sumaba en lineal: ±0.0175 lineal son ±0.14 en sRGB dentro de las
 *     sombras, y eso es exactamente el "damero cuantizado" que se veía en las zonas
 *     oscuras;
 *   - SMAA detecta bordes por diferencia de color y esperaba LDR, no HDR lineal.
 *
 * Ahora SMAA y el gradeo van después de OutputPass, que es donde sus constantes tienen
 * sentido, y el gradeo cierra la cadena (es el pase que va a pantalla).
 */
import * as THREE from 'three';
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { GTAOPass } from 'three/examples/jsm/postprocessing/GTAOPass.js';
import { UnrealBloomPass } from 'three/examples/jsm/postprocessing/UnrealBloomPass.js';
import { SMAAPass } from 'three/examples/jsm/postprocessing/SMAAPass.js';
import { OutputPass } from 'three/examples/jsm/postprocessing/OutputPass.js';
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';
import { ORDEN } from '../core/Ctx.js';

export const PRESETS = {
  baja:  { sombras: 1024, cascadas: 2, ao: false, bloom: false, smaa: false, pixelRatio: 1.0, foliaje: 0.35, dist: 260 },
  media: { sombras: 2048, cascadas: 3, ao: false, bloom: true,  smaa: true,  pixelRatio: 1.0, foliaje: 0.6,  dist: 400 },
  alta:  { sombras: 2048, cascadas: 4, ao: true,  bloom: true,  smaa: true,  pixelRatio: 1.25, foliaje: 1.0, dist: 600 },
  ultra: { sombras: 4096, cascadas: 4, ao: true,  bloom: true,  smaa: true,  pixelRatio: 1.5,  foliaje: 1.4, dist: 900 },
};

/**
 * Exposición de referencia por momento del día. Cielo mueve `exposicionObjetivo`
 * (o llama a `setExposicion`) y el Renderer interpola solo, así los amaneceres no
 * pegan saltos de brillo.
 *
 * `dia = 1.55` sale de medir el problema: con la exposición vieja (1.05) el cuadro
 * tenía media de luma ~50/255, el 40% de los píxeles por debajo de 32 y CERO por
 * encima de 200. Con 1.55 + la curva de display de abajo, el mismo contenido queda
 * en media ~120, 0% por debajo de 32 y ~4% por encima de 200, que es la zona donde
 * juega Age of Empires II (media 110-136, <2% oscuro, 3-10% de altas luces).
 */
export const EXPOSICION = {
  // Valores MEDIDOS sobre el juego corriendo (histograma de luma Rec.709 del cuadro
  // a 480x270), no estimados. La banda objetivo es la de Age of Empires II: DE:
  // media 110-136, menos del 2% de píxeles bajo 32, entre 3% y 10% por encima de 200.
  //   dia   0.80 -> media 133.1 · 0.6% oscuro · 7.6% altas luces  (1.55 daba 162.8 y 23.3%)
  //   noche 1.35 -> media 113.2 · 1.4% oscuro · 7.8% altas luces
  // La noche necesita MÁS exposición que el día: la escena nocturna tiene una
  // fracción de la radiancia y es la exposición la que la trae a rango jugable.
  // RE-MEDIDO tras bajar el albedo del terreno para ganar separación de valor:
  // el suelo más oscuro arrastró la media del cuadro fuera de banda por abajo.
  //   dia 0.80 -> 108.3 · 1.3% oscuro · 6.8% altas luces
  //   dia 0.95 -> 115.7 · 0.9% · 8.8%   <- elegido
  //   dia 1.25 -> 128.0 · 0.5% · 12.0%  (se pasa de altas luces)
  dia: 0.95,
  ocaso: 1.15,
  // La noche cae a propósito por debajo de la banda diurna —Age of Empires II no
  // tiene ciclo nocturno, así que su banda no es el objetivo acá— pero tampoco
  // puede tener medio cuadro en negro o deja de ser jugable. Medido:
  //   1.05 -> 47.7 · 48.0% de píxeles bajo 32   (injugable)
  //   1.80 -> 60.5 · 27.7%                       <- elegido
  //   2.10 -> 64.7 · 22.5%  (ya empieza a parecer atardecer)
  noche: 1.80,
  min: 0.20,
  max: 3.20,
};

// Convergencia exponencial de la exposición: llega al 95% del objetivo en ~0.5 s.
// Suficientemente rápido para que el arnés de capturas no mida un estado intermedio,
// suficientemente lento para que un cambio de hora no parpadee.
const VELOCIDAD_EXPOSICION = 6.0;

/**
 * GRADEO FINAL + NITIDEZ. Corre en espacio de display (0..1 sRGB), último de la cadena.
 *
 * La curva tonal es, en orden: balance por canal → gamma de levante → curva S suave →
 * levante de medios → hombro compresivo → saturación → viñeta → piso de negro +
 * ganancia → grano.
 *
 * Los números están elegidos midiendo, no a ojo. Anclas de la curva (entrada display
 * de OutputPass → salida en 0..255):
 *
 *      0.00 → 20    (piso: la sombra más profunda NUNCA clipea a 0)
 *      0.05 → 50
 *      0.12 → 76
 *      0.25 → 113
 *      0.40 → 151
 *      0.55 → 182
 *      0.70 → 206
 *      1.00 → 240
 *
 * El hombro (uRodilla/uHombro) es el seguro: comprime todo lo que pasa de 0.66 en vez
 * de recortarlo, así que si la escena se aclara un 60% el pasto al sol pasa de 217 a
 * 225 en vez de saturar a 255 y perder toda la textura.
 *
 * ── RONDA 5: SEPARACIÓN DE VALOR ──────────────────────────────────────────────
 * El defecto repetido en doce votos fue "todo el cuadro en una sola banda". Medido:
 * a mediodía el pasto al sol caía en luma 197 y la piedra de un edificio en 222.
 * Veinticinco niveles entre el fondo y el protagonista.
 *
 * El grueso de la corrección va en el albedo del terreno (src/world/TerrenoShader.js),
 * que es donde tiene que ir: bajar el suelo, no subir todo. Acá se hacen tres cosas y
 * ninguna es "más exposición":
 *
 *   1. uGamma 0.60 → 0.62. Parece nada y no lo es: el gradeo trabaja sobre una señal
 *      YA codificada a sRGB por OutputPass, así que la gamma efectiva desde radiancia
 *      lineal era 1/2.2 · 0.60 ≈ 1/3.7. Con esa compresión dos albedos que difieren un
 *      100% terminan a 25 niveles uno del otro. Cada centésima de gamma que se
 *      recupera son niveles de separación arriba, donde vive el contenido.
 *   2. uLevante 1.04 (nuevo) + uPiso 0.060 → 0.082. El suelo más oscuro baja la media
 *      del cuadro y hay que devolverla SIN volver a comprimir. El levante entra antes
 *      del hombro —así el hombro absorbe lo que sube en las altas luces en vez de
 *      clipearlo— y el piso es aditivo, o sea que conserva intactas las DIFERENCIAS
 *      que acabamos de ganar. Un levante después del hombro habría vuelto a aplastar
 *      los edificios contra el blanco.
 *   3. uBalance de cálido a casi neutro y uSaturacion 1.26 → 1.31. El sol de mediodía
 *      del Cielo es muy rojo (1.35,0.84,0.33): con el balance cálido el canal rojo del
 *      suelo llegaba a 199-214 y saturaba, y ESE era el amarillo del que se quejó el
 *      panel. El pasto pasa de (199,206,104) a (156,186,61): manda el verde.
 *
 * Resultado medido sobre las cuatro capturas del panel (media de luma / % bajo 32 /
 * % sobre 200; banda de la referencia: 110-136, <2%, 3-10%):
 *
 *      aldea vapor  119.6/0.48/5.6  →  110.8/0.36/5.5
 *      eléctrica    120.5/0.19/3.5  →  111.5/0.12/3.4
 *      atómica      133.7/0.04/4.0  →  127.5/0.01/5.5
 *
 * y la escalera pasa de pasto 197 vs piedra 222 (25 niveles) a 171 vs 232 (61).
 */
const ShaderGradeoFinal = {
  uniforms: {
    tDiffuse: { value: null },
    uTexel: { value: new THREE.Vector2(1 / 1920, 1 / 1080) },
    uSemilla: { value: 0 },
    // Gamma < 1: abre sombras y medios. Es el que sube la media del cuadro de 50 a 120.
    // 0.62 y no 0.60: cada centésima devuelve separación tonal en las altas luces,
    // que es donde el suelo y los edificios se estaban confundiendo (ver cabecera).
    uGamma: { value: 0.62 },
    // Curva S suave alrededor de 0.5. Devuelve algo del contraste que se lleva la gamma
    // sin volver a cerrar los negros (mezcla con smoothstep, monótona y sin clipeo).
    // Subida a 0.16: el pivote cae justo entre el suelo en sombra y el suelo al sol,
    // así que lo que gana es contraste SOL/SOMBRA sobre el terreno — el relieve y las
    // sombras proyectadas se leen, que es medio "foco" ganado gratis.
    uCurvaS: { value: 0.16 },
    // Levante de medios, ANTES del hombro. Compensa la media que pierde el cuadro al
    // oscurecer el albedo del terreno, sin tocar la exposición (que está medida y en
    // banda) y sin comprimir: lo que sube de la rodilla lo absorbe el hombro.
    uLevante: { value: 1.04 },
    uRodilla: { value: 0.66 },
    uHombro: { value: 0.95 },
    // La gamma comprime las razones entre canales (una razón 2 queda en 2^0.6 = 1.52),
    // o sea que desatura. Con el suelo más oscuro hace falta un poco más para que el
    // verde siga leyendo como verde y el azul de jugador siga cantando.
    uSaturacion: { value: 1.31 },
    // Viñeta MUY suave y en display: multiplica 0.87 en las esquinas, no 0.58 como antes.
    uVineta: { value: 0.13 },
    // Piso de negro: la sombra más oscura del cuadro queda en 0.082 (21/255). Es
    // aditivo, así que recupera media sin achatar ninguna diferencia de valor.
    uPiso: { value: 0.082 },
    uGanancia: { value: 0.945 },
    // Grano proporcional a la luminancia: máximo en los medios, casi nulo en negros y
    // blancos. ±0.01 en display = ±2.5/255, apenas textura de película.
    uGrano: { value: 0.020 },
    // Unsharp de cruz. La referencia tiene micro-contraste 21-23 y nosotros 16-17;
    // SMAA además come bordes, así que la nitidez va después y se lo devuelve.
    uNitidez: { value: 0.40 },
    // Balance de canal levemente cálido, como el sol de una campaña.
    uBalance: { value: new THREE.Vector3(1.015, 1.000, 0.982) },
  },
  vertexShader: /* glsl */`
    varying vec2 vUv;
    void main(){ vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }
  `,
  fragmentShader: /* glsl */`
    uniform sampler2D tDiffuse;
    uniform vec2 uTexel;
    uniform float uSemilla, uGamma, uCurvaS, uRodilla, uHombro;
    uniform float uSaturacion, uVineta, uPiso, uGanancia, uGrano, uNitidez;
    uniform vec3 uBalance;
    varying vec2 vUv;

    const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

    // Hash sin sin(): el clásico fract(sin(dot(p,k))*43758.5) pierde precisión con
    // coordenadas grandes y degenera en un damero diagonal visible justo donde más
    // molesta, en las sombras. Este (Hoskins) se mantiene blanco a 4K.
    float ruidoBlanco(vec2 p){
      vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
      q += dot(q, q.yzx + 33.33);
      return fract((q.x + q.y) * q.z);
    }

    // Parte puramente tonal de la curva. Se aplica también a los vecinos para que el
    // unsharp mida el contraste en el MISMO espacio en el que se va a ver: si se
    // afilara antes de la gamma, la gamma amplificaría el realce en las sombras
    // (derivada ~1.9 en oscuros) y aparecería ruido de borde en las zonas negras.
    vec3 curvaTonal(vec3 c){
      c = max(c, 0.0) * uBalance;
      c = pow(c, vec3(uGamma));
      c = mix(c, c * c * (3.0 - 2.0 * c), uCurvaS);
      vec3 e = max(c - uRodilla, 0.0);
      return min(c, vec3(uRodilla)) + e / (1.0 + e * uHombro);
    }

    void main(){
      vec3 c = curvaTonal(texture2D(tDiffuse, vUv).rgb);

      // ── NITIDEZ (unsharp de cruz, 4 taps) ──────────────────────────────────────
      vec3 prom = 0.25 * (
          curvaTonal(texture2D(tDiffuse, vUv + vec2(uTexel.x, 0.0)).rgb)
        + curvaTonal(texture2D(tDiffuse, vUv - vec2(uTexel.x, 0.0)).rgb)
        + curvaTonal(texture2D(tDiffuse, vUv + vec2(0.0, uTexel.y)).rgb)
        + curvaTonal(texture2D(tDiffuse, vUv - vec2(0.0, uTexel.y)).rgb));
      // El clamp es lo que evita los halos: por muy brutal que sea el borde (silueta
      // de un edificio contra el cielo) la corrección no puede pasar de ±0.05, así
      // que no aparece el ribete blanco de "sharpen de televisor".
      c += clamp((c - prom) * uNitidez, -0.05, 0.05);

      // ── SATURACIÓN ─────────────────────────────────────────────────────────────
      float l = dot(c, LUMA);
      c = max(mix(vec3(l), c, uSaturacion), 0.0);

      // ── VIÑETA ─────────────────────────────────────────────────────────────────
      // r2 vale 0 en el centro y 1 en la esquina; al cuadrado deja el centro intacto
      // y solo cierra el borde extremo. Va ANTES del piso para no romper el negro mínimo.
      vec2 d = vUv - 0.5;
      float r2 = dot(d, d) * 2.0;
      c *= 1.0 - uVineta * r2 * r2;

      // ── PISO DE NEGRO + GANANCIA ───────────────────────────────────────────────
      c = uPiso + c * uGanancia;

      // ── GRANO ──────────────────────────────────────────────────────────────────
      // 4*l*(1-l) es una campana: 1 en los medios, 0 en negro y en blanco puro.
      float lg = dot(c, LUMA);
      float peso = 4.0 * lg * (1.0 - lg);
      float g = ruidoBlanco(gl_FragCoord.xy + uSemilla) - 0.5;
      c += g * uGrano * peso;

      gl_FragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
    }
  `,
};

export class Renderer {
  constructor(lienzo, calidad = 'alta') {
    this.nombre = 'render';
    this.orden = ORDEN.RENDER;
    this.calidad = calidad;
    this.preset = PRESETS[calidad];

    const renderer = new THREE.WebGLRenderer({
      canvas: lienzo, antialias: false, powerPreference: 'high-performance',
      stencil: false, alpha: false, logarithmicDepthBuffer: false,
    });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, this.preset.pixelRatio));
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.shadowMap.autoUpdate = true;
    renderer.info.autoReset = false;
    this.renderer = renderer;

    /** Exposición ACES actual y a dónde va. Cielo escribe `exposicionObjetivo`. */
    this.exposicion = EXPOSICION.dia;
    this.exposicionObjetivo = EXPOSICION.dia;
    renderer.toneMappingExposure = this.exposicion;

    this.escena = new THREE.Scene();
    this.camara = new THREE.PerspectiveCamera(42, window.innerWidth / window.innerHeight, 0.6, 3000);
    this.camara.position.set(60, 55, 60);
    this.camara.lookAt(0, 0, 0);

    this.composer = null;
    this.pases = {};
    this._construirComposer();

    this._resizeObs = () => this.redimensionar();
    window.addEventListener('resize', this._resizeObs);
  }

  /** Relación de píxel efectiva: la que usan de verdad los buffers del composer. */
  get _ratio() {
    return Math.min(window.devicePixelRatio, this.preset.pixelRatio);
  }

  _construirComposer() {
    const { renderer, escena, camara, preset } = this;
    const w = window.innerWidth, h = window.innerHeight;
    const objetivo = new THREE.WebGLRenderTarget(w, h, {
      type: THREE.HalfFloatType, samples: preset.ao ? 0 : 4,
      colorSpace: THREE.LinearSRGBColorSpace,
    });
    const composer = new EffectComposer(renderer, objetivo);
    composer.setPixelRatio(this._ratio);
    composer.setSize(w, h);

    const rp = new RenderPass(escena, camara);
    composer.addPass(rp);
    this.pases.render = rp;

    if (preset.ao) {
      const ao = new GTAOPass(escena, camara, w, h);
      ao.output = GTAOPass.OUTPUT.Default;
      ao.updateGtaoMaterial({
        radius: 0.85, distanceExponent: 1.4, thickness: 0.6, scale: 1.0,
        samples: 16, distanceFallOff: 1.0, screenSpaceRadius: false,
      });
      // Por encima de ~0.6 el GTAO tiñe de azul las sombras del terreno y se come
      // el contraste del pasto. Acá solo tiene que marcar el contacto.
      ao.blendIntensity = 0.5;
      composer.addPass(ao);
      this.pases.ao = ao;
    }

    if (preset.bloom) {
      // Sigue corriendo en lineal HDR (antes de OutputPass), que es lo correcto: la
      // luz se suma en lineal. Pero el umbral hay que reencuadrarlo con la exposición
      // nueva. Con exposición 1.55 el reparto de radiancias es:
      //     pasto al sol ≈ 0.33   arena ≈ 0.66   nieve ≈ 1.14   sol/emisivos > 3
      // Umbral 0.80 deja fuera el suelo difuso y adentro los brillos de verdad:
      // especulares de metal y agua, nieve al sol, fuego, ventanas encendidas y el
      // disco solar. El 2.2 anterior era tan alto que no florecía absolutamente nada.
      // Umbral MEDIDO: con 0.80 el 28.4% del cuadro terminaba por encima de 200 y la
      // aldea se llenaba de estrellas blancas sobre los techos y el pasto. Con 2.0 el
      // bloom vuelve a hacer lo suyo —brillos metálicos, agua al sol, fuego, emisivos—
      // y el cuadro cae en 7.6% de altas luces, dentro de la banda de la referencia.
      const bloom = new UnrealBloomPass(new THREE.Vector2(w, h), 0.45, 0.72, 2.0);
      composer.addPass(bloom);
      this.pases.bloom = bloom;
    }

    // A partir de acá TODO es 0..1 sRGB de pantalla.
    const out = new OutputPass();
    composer.addPass(out);
    this.pases.salida = out;

    if (preset.smaa) {
      // SMAA después del tone mapping: su detección de bordes trabaja con umbrales
      // sobre diferencias de color perceptuales, que en HDR lineal no significan nada.
      const smaa = new SMAAPass(w, h);
      composer.addPass(smaa);
      this.pases.smaa = smaa;
    }

    // Último de la cadena → EffectComposer le pone renderToScreen y es el que va a
    // pantalla. Además así la nitidez recupera el micro-contraste que SMAA suaviza,
    // y el grano no queda emborronado por el antialias.
    const gradeo = new ShaderPass(ShaderGradeoFinal);
    composer.addPass(gradeo);
    this.pases.gradeo = gradeo;
    this.pases.grade = gradeo; // alias histórico

    this.composer = composer;
    this._actualizarTexel(w, h);
  }

  /** Tamaño de téxel para el unsharp: hay que usar el tamaño EFECTIVO del buffer. */
  _actualizarTexel(w, h) {
    const r = this._ratio;
    this.pases.gradeo?.uniforms.uTexel.value.set(1 / Math.max(1, w * r), 1 / Math.max(1, h * r));
  }

  /**
   * Libera los pases del composer viejo (EffectComposer.dispose solo tira sus render
   * targets). El Set es porque `gradeo` y `grade` apuntan al mismo pase y llamar
   * dispose() dos veces sobre el mismo material rompe en algunos drivers.
   */
  _liberarPases() {
    const vistos = new Set();
    for (const p of Object.values(this.pases)) {
      if (!p || vistos.has(p)) continue;
      vistos.add(p);
      p.dispose?.();
    }
    this.pases = {};
  }

  /**
   * Exposición ACES objetivo. Cielo la mueve por hora del día; el valor real
   * converge suave salvo que se pida inmediato (arranque, teletransporte de hora).
   */
  setExposicion(v, inmediato = false) {
    const e = Math.min(Math.max(v, EXPOSICION.min), EXPOSICION.max);
    this.exposicionObjetivo = e;
    if (inmediato) {
      this.exposicion = e;
      this.renderer.toneMappingExposure = e;
    }
  }

  setCalidad(calidad) {
    if (calidad === this.calidad) return;
    this.calidad = calidad;
    this.preset = PRESETS[calidad];
    this.renderer.setPixelRatio(this._ratio);
    if (this.composer) this.composer.dispose?.();
    this._liberarPases();
    this._construirComposer();
    this.onCalidad?.(this.preset);
  }

  redimensionar() {
    const w = window.innerWidth, h = window.innerHeight;
    this.camara.aspect = w / h;
    this.camara.updateProjectionMatrix();
    this.renderer.setSize(w, h);
    this.composer.setSize(w, h);
    this._actualizarTexel(w, h);
  }

  cada(dtReal, alfa, ctx) {
    this.renderer.info.reset();

    // Exposición: convergencia exponencial hacia el objetivo que fija Cielo.
    // dt acotado para que un frame perdido (pestaña en segundo plano) no pegue un salto.
    const dt = dtReal > 0.25 ? 0.25 : (dtReal > 0 ? dtReal : 0);
    const obj = Math.min(Math.max(this.exposicionObjetivo, EXPOSICION.min), EXPOSICION.max);
    this.exposicion += (obj - this.exposicion) * (1 - Math.exp(-dt * VELOCIDAD_EXPOSICION));
    this.renderer.toneMappingExposure = this.exposicion;

    const gradeo = this.pases.gradeo;
    if (gradeo) {
      // Semilla envuelta: si se acumulara sin límite, a los pocos minutos el hash
      // pierde precisión y el grano se congela en un patrón fijo.
      const s = gradeo.uniforms.uSemilla.value + dt * 137.0;
      gradeo.uniforms.uSemilla.value = s > 4096.0 ? s - 4096.0 : s;
    }

    this.composer.render(dtReal);
    const info = this.renderer.info;
    ctx.motor.stats.dibujos = info.render.calls;
    ctx.motor.stats.triangulos = info.render.triangles;
  }
}
