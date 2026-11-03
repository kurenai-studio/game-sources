/**
 * EFECTOS — partículas, fogonazos, explosiones, ondas de choque, escombros,
 * estelas, haces y marcas de suelo.
 *
 * Filosofía (vara: Age of Empires II DE, pero con pólvora de verdad):
 *  - Todo se simula en el VERTEX SHADER en función del tiempo. La CPU solo
 *    escribe los atributos de la partícula nueva y avanza un puntero circular:
 *    cero trabajo por partícula por frame, cero asignaciones por frame.
 *  - Cada familia de partícula es UNA sola malla instanciada (una llamada de
 *    dibujo) con miles de instancias preasignadas. Nunca se crean materiales,
 *    geometrías ni objetos durante el juego.
 *  - Aditivo para fuego, chispas y destellos. Alfa normal para humo y polvo.
 *  - Presupuesto por distancia a cámara: lo que pasa lejos se emite a la mitad
 *    o directamente no se emite.
 *
 * Contrato de sistema: { nombre:'efectos', orden:80, cada(dtReal, alfa, ctx) }
 */
import * as THREE from 'three';
import { ORDEN } from '../core/Ctx.js';
import { RNG, clamp } from '../core/RNG.js';
import { bus } from '../core/EventBus.js';

/* ------------------------------------------------------------------ */
/* Presupuesto por calidad                                             */
/* ------------------------------------------------------------------ */

const CAPACIDADES = {
  baja: {
    humo: 1200, polvo: 1200, fuego: 800, chispa: 1200, destello: 128, estallido: 128,
    escombros: 180, tiras: 256, planos: 24, luces: 0, detalle: 0.4, dist: 190,
  },
  media: {
    humo: 3000, polvo: 2600, fuego: 1800, chispa: 3000, destello: 192, estallido: 192,
    escombros: 420, tiras: 512, planos: 40, luces: 2, detalle: 0.7, dist: 240,
  },
  alta: {
    humo: 6000, polvo: 5000, fuego: 3600, chispa: 6000, destello: 320, estallido: 320,
    escombros: 800, tiras: 1024, planos: 64, luces: 4, detalle: 1.0, dist: 300,
  },
  ultra: {
    humo: 9000, polvo: 7000, fuego: 5000, chispa: 9000, destello: 448, estallido: 448,
    escombros: 1200, tiras: 1536, planos: 96, luces: 6, detalle: 1.35, dist: 380,
  },
};

/** Modos de simulación que entiende el shader. */
const MODO = { LIBRE: 0, BRASA: 1, HOJA: 3 };

/** Tinte del polvo según el suelo que se levanta. */
const POLVO_BIOMA = {
  pradera:  [1.05, 0.92, 0.64],
  bosque:   [0.80, 0.70, 0.50],
  montana:  [0.95, 0.93, 0.88],
  desierto: [1.35, 1.16, 0.78],
  playa:    [1.45, 1.30, 0.98],
  agua:     [1.10, 1.22, 1.28],
};

/** Colores de las marcas de orden en el suelo. */
const COLOR_MARCA = {
  mover:       [0.35, 1.30, 0.45],
  atacar:      [1.50, 0.30, 0.20],
  recolectar:  [1.35, 0.85, 0.22],
  construir:   [0.45, 0.85, 1.40],
  reunion:     [1.20, 1.05, 0.55],
  alerta:      [1.50, 0.55, 0.15],
};

/* ------------------------------------------------------------------ */
/* Geometrías base compartidas                                         */
/* ------------------------------------------------------------------ */

const QUAD = new THREE.PlaneGeometry(1, 1);
const CAJA = new THREE.BoxGeometry(1, 0.72, 0.86);

/* ------------------------------------------------------------------ */
/* Shaders                                                             */
/* ------------------------------------------------------------------ */

const VS_PARTICULA = /* glsl */`
  uniform float uTiempo;
  uniform vec2  uViento;
  uniform vec3  uLuz;
  uniform float uEntrada;      // fracción de vida que tarda en aparecer
  uniform float uSalida;       // fracción de vida a partir de la cual se apaga
  uniform float uEscala;       // escala global del pool
  uniform float uEstirar;      // 1 = el quad se alarga según la velocidad
  uniform float uNieblaDens;

  attribute vec3 aPos0;
  attribute vec3 aVel;
  attribute vec2 aTiempo;      // nacimiento, duración
  attribute vec2 aTam;         // radio inicial, radio final
  attribute vec3 aColor;
  attribute vec4 aFis;         // gravedad, arrastre, rotación inicial, vel. de rotación
  attribute vec4 aExtra;       // modo, opacidad, turbulencia, semilla

  varying vec2  vUv;
  varying vec3  vColor;
  varying float vAlfa;
  varying float vNiebla;

  void main() {
    vUv = uv;
    float dur  = max(aTiempo.y, 0.0001);
    float edad = uTiempo - aTiempo.x;
    float k    = edad / dur;

    if (k < 0.0 || k > 1.0) {
      vColor = vec3(0.0); vAlfa = 0.0; vNiebla = 0.0;
      gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
      return;
    }

    float sem = aExtra.w;
    float turb = aExtra.z;
    float modo = aExtra.x;

    // integración analítica: velocidad con arrastre exponencial + gravedad
    float arr = max(aFis.y, 0.001);
    float integral = (1.0 - exp(-arr * edad)) / arr;
    vec3 p = aPos0 + aVel * integral;
    p.y -= 0.5 * aFis.x * edad * edad;

    if (turb > 0.0) {
      float f = 6.2831 * sem;
      p.x += sin(edad * (1.15 + sem) + f) * turb * edad * 0.55;
      p.z += cos(edad * (0.95 + sem) + f * 1.7) * turb * edad * 0.55;
      p.y += sin(edad * 1.8 + f * 2.3) * turb * edad * 0.16;
      p.xz += uViento * edad * edad * turb * 0.45;
    }
    if (modo > 2.5) {                       // hoja: aletea al caer
      p.x += sin(edad * 3.1 + sem * 6.2831) * 0.42;
      p.z += cos(edad * 2.4 + sem * 5.1130) * 0.34;
    }

    float kc  = 1.0 - (1.0 - k) * (1.0 - k);        // crece rápido y desacelera
    float tam = mix(aTam.x, aTam.y, kc) * uEscala;
    float rot = aFis.z + aFis.w * edad;

    vAlfa  = smoothstep(0.0, uEntrada, k) * (1.0 - smoothstep(uSalida, 1.0, k)) * aExtra.y;
    vColor = aColor * uLuz;
    if (modo > 0.5 && modo < 2.5) {         // brasa: blanco caliente -> naranja -> ceniza
      vec3 caliente = vec3(2.10, 1.75, 1.35);
      vec3 apagado  = vec3(0.26, 0.10, 0.05);
      vColor = aColor * mix(caliente, apagado, smoothstep(0.04, 0.88, k));
    }

    vec4 mv = modelViewMatrix * vec4(p, 1.0);

    if (uEstirar > 0.5) {
      // billboard alineado con la velocidad instantánea: la chispa se ve como traza
      vec3 v = aVel * exp(-arr * edad) - vec3(0.0, aFis.x * edad, 0.0);
      vec3 vv = (modelViewMatrix * vec4(v, 0.0)).xyz;
      float largo = length(vv.xy);
      vec2 e = largo > 1e-4 ? vv.xy / largo : vec2(0.0, 1.0);
      float estira = tam * (1.0 + min(largo * 0.18, 7.0));
      mv.xy += e * position.y * 2.0 * estira + vec2(-e.y, e.x) * position.x * 2.0 * tam;
    } else {
      float c = cos(rot), s = sin(rot);
      vec2 q = vec2(position.x * c - position.y * s, position.x * s + position.y * c);
      mv.xy += q * 2.0 * tam;
    }

    float d = -mv.z;
    vNiebla = 1.0 - exp(-uNieblaDens * uNieblaDens * d * d);
    gl_Position = projectionMatrix * mv;
  }
`;

const FS_PARTICULA = /* glsl */`
  uniform sampler2D uMapa;
  uniform vec3  uNieblaColor;
  uniform float uMezclaNiebla;   // 1 = tiñe (alfa normal) · 0 = se apaga (aditivo)
  uniform float uProcedural;     // 1 = gota analítica en vez de textura
  uniform float uOpacidad;

  varying vec2  vUv;
  varying vec3  vColor;
  varying float vAlfa;
  varying float vNiebla;

  void main() {
    vec4 tex = texture2D(uMapa, vUv);
    float r = length(vUv - 0.5) * 2.0;
    float gota = pow(max(1.0 - r, 0.0), 1.9);
    vec4 muestra = mix(tex, vec4(1.0, 1.0, 1.0, gota), uProcedural);

    float a = muestra.a * vAlfa * uOpacidad;
    if (a < 0.004) discard;

    vec3 c = muestra.rgb * vColor;
    c = mix(c, uNieblaColor, vNiebla * uMezclaNiebla);
    a *= mix(1.0 - vNiebla, 1.0, uMezclaNiebla);
    gl_FragColor = vec4(c, a);
  }
`;

const VS_ESCOMBRO = /* glsl */`
  uniform float uTiempo;
  uniform vec3  uDirSol;
  uniform vec3  uColorSol;
  uniform vec3  uAmbiente;
  uniform float uNieblaDens;

  attribute vec3 aPos0;
  attribute vec3 aVel;
  attribute vec2 aTiempo;
  attribute vec4 aGiro;    // eje.xyz + velocidad angular
  attribute vec3 aColor;
  attribute vec4 aExtra;   // escala, altura del suelo, rebote, brasa

  varying vec3  vColor;
  varying float vAlfa;
  varying float vNiebla;

  vec3 girar(vec3 v, vec3 eje, float ang) {
    float c = cos(ang), s = sin(ang);
    return v * c + cross(eje, v) * s + eje * dot(eje, v) * (1.0 - c);
  }

  void main() {
    float dur  = max(aTiempo.y, 0.0001);
    float edad = uTiempo - aTiempo.x;
    float k    = edad / dur;
    if (k < 0.0 || k > 1.0) {
      vColor = vec3(0.0); vAlfa = 0.0; vNiebla = 0.0;
      gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
      return;
    }

    const float G = 24.0;
    float suelo = aExtra.y;
    float caida = max(aPos0.y - suelo, 0.0);
    float t1 = (aVel.y + sqrt(max(aVel.y * aVel.y + 2.0 * G * caida, 0.0))) / G;
    float t  = min(edad, t1);

    vec3 p = aPos0 + aVel * t;
    p.y -= 0.5 * G * t * t;
    float giro = aGiro.w * edad;

    if (edad > t1) {                       // ya tocó el suelo: rebota y se frena
      float dt = edad - t1;
      float amort = exp(-2.8 * dt);
      p.xz += aVel.xz * (1.0 - amort) * 0.28;
      p.y = suelo + abs(sin(dt * 9.5)) * aExtra.z * amort;
      giro = aGiro.w * t1 + aGiro.w * (1.0 - amort) * 0.4;
    }

    vec3 eje = normalize(aGiro.xyz + vec3(0.0001, 0.0002, 0.0001));
    vec3 loc = girar(position * aExtra.x, eje, giro);
    vec3 nor = girar(normal, eje, giro);

    vec4 mv = modelViewMatrix * vec4(p + loc, 1.0);
    float nl = max(dot(nor, uDirSol), 0.0);
    // los cascotes salen al rojo vivo y se enfrían: si no, son puntos negros
    // adentro de la bola de fuego
    float brasa = aExtra.w * max(1.0 - k * 3.6, 0.0);
    vColor = aColor * (uAmbiente + uColorSol * nl) + vec3(2.0, 0.70, 0.16) * brasa;
    vAlfa  = 1.0 - smoothstep(0.7, 1.0, k);
    float d = -mv.z;
    vNiebla = 1.0 - exp(-uNieblaDens * uNieblaDens * d * d);
    gl_Position = projectionMatrix * mv;
  }
`;

const FS_ESCOMBRO = /* glsl */`
  uniform vec3 uNieblaColor;
  varying vec3  vColor;
  varying float vAlfa;
  varying float vNiebla;
  void main() {
    if (vAlfa < 0.01) discard;
    gl_FragColor = vec4(mix(vColor, uNieblaColor, vNiebla), vAlfa);
  }
`;

const VS_TIRA = /* glsl */`
  uniform float uTiempo;
  uniform float uNieblaDens;

  attribute vec3 aA;
  attribute vec3 aB;
  attribute vec2 aTiempo;
  attribute vec2 aAnchos;
  attribute vec3 aColor;
  attribute vec4 aExtra;   // opacidad, dureza, adelgaza, semilla

  varying vec2  vUv;
  varying vec3  vColor;
  varying float vAlfa;
  varying float vDureza;
  varying float vNiebla;

  void main() {
    float dur  = max(aTiempo.y, 0.0001);
    float edad = uTiempo - aTiempo.x;
    float k    = edad / dur;
    if (k < 0.0 || k > 1.0) {
      vColor = vec3(0.0); vAlfa = 0.0; vUv = vec2(0.5); vDureza = 1.0; vNiebla = 0.0;
      gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
      return;
    }

    float u = position.x + 0.5;
    vec3 p = mix(aA, aB, u);
    vec4 mv = modelViewMatrix * vec4(p, 1.0);
    vec3 ejeV = (modelViewMatrix * vec4(aB - aA, 0.0)).xyz;
    float lg = length(ejeV.xy);
    vec2 lado = lg > 1e-5 ? vec2(-ejeV.y, ejeV.x) / lg : vec2(1.0, 0.0);

    float ancho = mix(aAnchos.x, aAnchos.y, u) * mix(1.0, 1.0 - k, aExtra.z);
    mv.xy += lado * position.y * 2.0 * ancho;

    vUv = uv;
    vColor = aColor;
    vDureza = aExtra.y;
    vAlfa = (1.0 - k) * aExtra.x;
    float d = -mv.z;
    vNiebla = 1.0 - exp(-uNieblaDens * uNieblaDens * d * d);
    gl_Position = projectionMatrix * mv;
  }
`;

const FS_TIRA = /* glsl */`
  varying vec2  vUv;
  varying vec3  vColor;
  varying float vAlfa;
  varying float vDureza;
  varying float vNiebla;
  void main() {
    float d = abs(vUv.y * 2.0 - 1.0);
    float borde  = pow(max(1.0 - d, 0.0), vDureza);
    float nucleo = pow(max(1.0 - d, 0.0), vDureza * 7.0);
    float a = (borde * 0.55 + nucleo * 0.9) * vAlfa * (1.0 - vNiebla);
    if (a < 0.004) discard;
    vec3 c = mix(vColor, vec3(1.4), nucleo * 0.65);
    gl_FragColor = vec4(c, a);
  }
`;

const VS_PLANO = /* glsl */`
  uniform float uTiempo;
  uniform float uNieblaDens;

  attribute vec3 aCentro;
  attribute vec2 aTiempo;
  attribute vec2 aRadios;
  attribute vec3 aColor;
  attribute vec4 aExtra;   // opacidad, tipo, curva, semilla

  varying vec2  vUv;
  varying vec3  vColor;
  varying float vAlfa;
  varying float vTipo;
  varying float vNiebla;

  void main() {
    float dur  = max(aTiempo.y, 0.0001);
    float edad = uTiempo - aTiempo.x;
    float k    = edad / dur;
    if (k < 0.0 || k > 1.0) {
      vColor = vec3(0.0); vAlfa = 0.0; vUv = vec2(0.5); vTipo = 0.0; vNiebla = 0.0;
      gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
      return;
    }

    float ke = 1.0 - pow(1.0 - k, max(aExtra.z, 0.2));
    float r  = mix(aRadios.x, aRadios.y, ke);
    vec3 p = aCentro + vec3(position.x * 2.0 * r, 0.0, -position.y * 2.0 * r);
    p.y += 0.06 + r * 0.012;

    vUv = uv;
    vColor = aColor;
    vTipo = aExtra.y;
    vAlfa = aExtra.x * (1.0 - smoothstep(0.25, 1.0, k)) * smoothstep(0.0, 0.08, k);
    vec4 mv = modelViewMatrix * vec4(p, 1.0);
    float d = -mv.z;
    vNiebla = 1.0 - exp(-uNieblaDens * uNieblaDens * d * d);
    gl_Position = projectionMatrix * mv;
  }
`;

const FS_PLANO = /* glsl */`
  uniform sampler2D uMapa;
  varying vec2  vUv;
  varying vec3  vColor;
  varying float vAlfa;
  varying float vTipo;
  varying float vNiebla;
  void main() {
    vec4 tex = texture2D(uMapa, vUv);
    float r = length(vUv - 0.5) * 2.0;
    float anillo = smoothstep(1.02, 0.90, r) * smoothstep(0.60, 0.80, r);
    float interior = smoothstep(0.58, 0.36, r) * 0.16;
    float a = mix(tex.a, anillo + interior, vTipo) * vAlfa * (1.0 - vNiebla);
    if (a < 0.004) discard;
    vec3 c = mix(tex.rgb, vec3(1.0), vTipo) * vColor;
    gl_FragColor = vec4(c, a);
  }
`;

/* ------------------------------------------------------------------ */
/* Utilidades de pools                                                 */
/* ------------------------------------------------------------------ */

function atributo(n, tam) {
  const a = new THREE.InstancedBufferAttribute(new Float32Array(n * tam), tam);
  a.setUsage(THREE.DynamicDrawUsage);
  return a;
}

/** Base común: puntero circular, rango sucio y subida parcial a GPU. */
class PoolBase {
  constructor(capacidad) {
    this.capacidad = capacidad;
    this.puntero = 0;
    this.usados = 0;
    this.vacioEn = -1;
    this.atributos = [];
    this._i0 = Infinity;
    this._i1 = -1;
  }

  /** Reserva el próximo hueco del anillo. Devuelve el índice. */
  _reservar(ahora, vida) {
    const i = this.puntero;
    this.puntero = i + 1 >= this.capacidad ? 0 : i + 1;
    if (i >= this.usados) this.usados = i + 1;
    if (i < this._i0) this._i0 = i;
    if (i > this._i1) this._i1 = i;
    const fin = ahora + vida;
    if (fin > this.vacioEn) this.vacioEn = fin;
    return i;
  }

  /** Sube a GPU solo el tramo que se tocó desde el último frame. */
  subir(tiempo) {
    if (this._i1 >= this._i0) {
      const desde = this._i0, cuantos = this._i1 - this._i0 + 1;
      for (let a = 0; a < this.atributos.length; a++) {
        const at = this.atributos[a];
        if (at.clearUpdateRanges) {
          at.clearUpdateRanges();
          at.addUpdateRange(desde * at.itemSize, cuantos * at.itemSize);
        }
        at.needsUpdate = true;
      }
      this._i0 = Infinity; this._i1 = -1;
    }
    const viva = tiempo <= this.vacioEn;
    this.malla.visible = viva && this.usados > 0;
    this.geo.instanceCount = viva ? this.usados : 0;
  }

  /** Que la pasada de AO/normales no meta las partículas en el buffer de profundidad. */
  _blindarAO() {
    const geo = this.geo;
    let guardado = 0;
    this.malla.onBeforeRender = (r, escena) => {
      if (escena && escena.overrideMaterial) { guardado = geo.instanceCount; geo.instanceCount = 0; }
    };
    this.malla.onAfterRender = (r, escena) => {
      if (escena && escena.overrideMaterial) geo.instanceCount = guardado;
    };
  }
}

/* ------------------------------------------------------------------ */
/* Pool de partículas (una llamada de dibujo, miles de instancias)     */
/* ------------------------------------------------------------------ */

class PoolParticulas extends PoolBase {
  /**
   * @param {object} o { capacidad, mapa, aditivo, procedural, estirar, entrada,
   *                     salida, escala, opacidad, orden }
   */
  constructor(o) {
    super(o.capacidad);
    const n = this.capacidad;

    this.aPos0   = atributo(n, 3);
    this.aVel    = atributo(n, 3);
    this.aTiempo = atributo(n, 2);
    this.aTam    = atributo(n, 2);
    this.aColor  = atributo(n, 3);
    this.aFis    = atributo(n, 4);
    this.aExtra  = atributo(n, 4);
    this.atributos = [this.aPos0, this.aVel, this.aTiempo, this.aTam, this.aColor, this.aFis, this.aExtra];

    const geo = new THREE.InstancedBufferGeometry();
    geo.index = QUAD.index;
    geo.setAttribute('position', QUAD.attributes.position);
    geo.setAttribute('uv', QUAD.attributes.uv);
    geo.setAttribute('aPos0', this.aPos0);
    geo.setAttribute('aVel', this.aVel);
    geo.setAttribute('aTiempo', this.aTiempo);
    geo.setAttribute('aTam', this.aTam);
    geo.setAttribute('aColor', this.aColor);
    geo.setAttribute('aFis', this.aFis);
    geo.setAttribute('aExtra', this.aExtra);
    geo.instanceCount = 0;
    geo.boundingSphere = new THREE.Sphere(new THREE.Vector3(), 1e5);
    this.geo = geo;

    this.material = new THREE.ShaderMaterial({
      uniforms: {
        uTiempo: { value: 0 },
        uViento: { value: new THREE.Vector2(0.5, 0.2) },
        uLuz: { value: new THREE.Vector3(1, 1, 1) },
        uEntrada: { value: o.entrada != null ? o.entrada : 0.12 },
        uSalida: { value: o.salida != null ? o.salida : 0.45 },
        uEscala: { value: o.escala != null ? o.escala : 1 },
        uEstirar: { value: o.estirar ? 1 : 0 },
        uProcedural: { value: o.procedural ? 1 : 0 },
        uOpacidad: { value: o.opacidad != null ? o.opacidad : 1 },
        uMapa: { value: o.mapa },
        uNieblaColor: { value: new THREE.Vector3(0.62, 0.70, 0.78) },
        uNieblaDens: { value: 0.0035 },
        uMezclaNiebla: { value: o.aditivo ? 0 : 1 },
      },
      vertexShader: VS_PARTICULA,
      fragmentShader: FS_PARTICULA,
      transparent: true,
      depthWrite: false,
      depthTest: true,
      side: THREE.DoubleSide,
      blending: o.aditivo ? THREE.AdditiveBlending : THREE.NormalBlending,
      toneMapped: false,
    });
    this.material.name = `mat_particulas_${o.nombre || ''}`;

    this.malla = new THREE.Mesh(geo, this.material);
    this.malla.name = `efectos_${o.nombre || 'particulas'}`;
    this.malla.frustumCulled = false;
    this.malla.castShadow = false;
    this.malla.receiveShadow = false;
    this.malla.renderOrder = o.orden != null ? o.orden : 5;
    this.malla.matrixAutoUpdate = false;
    this._blindarAO();
  }

  /**
   * Emite una partícula. `d` es un descriptor reutilizado (cero basura).
   */
  emitir(d, ahora) {
    const i = this._reservar(ahora, d.vida);
    const i2 = i * 2, i3 = i * 3, i4 = i * 4;
    const p = this.aPos0.array, v = this.aVel.array, t = this.aTiempo.array;
    const s = this.aTam.array, c = this.aColor.array, f = this.aFis.array, e = this.aExtra.array;
    p[i3] = d.x; p[i3 + 1] = d.y; p[i3 + 2] = d.z;
    v[i3] = d.vx; v[i3 + 1] = d.vy; v[i3 + 2] = d.vz;
    t[i2] = ahora; t[i2 + 1] = d.vida;
    s[i2] = d.tam0; s[i2 + 1] = d.tam1;
    c[i3] = d.r; c[i3 + 1] = d.g; c[i3 + 2] = d.b;
    f[i4] = d.grav; f[i4 + 1] = d.arrastre; f[i4 + 2] = d.rot; f[i4 + 3] = d.vrot;
    e[i4] = d.modo; e[i4 + 1] = d.op; e[i4 + 2] = d.turb; e[i4 + 3] = d.sem;
  }
}

/* ------------------------------------------------------------------ */
/* Pool de escombros (cajitas con balística y rebote)                  */
/* ------------------------------------------------------------------ */

class PoolEscombros extends PoolBase {
  constructor(capacidad) {
    super(capacidad);
    const n = capacidad;
    this.aPos0   = atributo(n, 3);
    this.aVel    = atributo(n, 3);
    this.aTiempo = atributo(n, 2);
    this.aGiro   = atributo(n, 4);
    this.aColor  = atributo(n, 3);
    this.aExtra  = atributo(n, 4);
    this.atributos = [this.aPos0, this.aVel, this.aTiempo, this.aGiro, this.aColor, this.aExtra];

    const geo = new THREE.InstancedBufferGeometry();
    geo.index = CAJA.index;
    geo.setAttribute('position', CAJA.attributes.position);
    geo.setAttribute('normal', CAJA.attributes.normal);
    geo.setAttribute('aPos0', this.aPos0);
    geo.setAttribute('aVel', this.aVel);
    geo.setAttribute('aTiempo', this.aTiempo);
    geo.setAttribute('aGiro', this.aGiro);
    geo.setAttribute('aColor', this.aColor);
    geo.setAttribute('aExtra', this.aExtra);
    geo.instanceCount = 0;
    geo.boundingSphere = new THREE.Sphere(new THREE.Vector3(), 1e5);
    this.geo = geo;

    this.material = new THREE.ShaderMaterial({
      uniforms: {
        uTiempo: { value: 0 },
        uDirSol: { value: new THREE.Vector3(0.4, 0.8, 0.45) },
        uColorSol: { value: new THREE.Vector3(1.1, 1.0, 0.86) },
        uAmbiente: { value: new THREE.Vector3(0.30, 0.34, 0.40) },
        uNieblaColor: { value: new THREE.Vector3(0.62, 0.70, 0.78) },
        uNieblaDens: { value: 0.0035 },
      },
      vertexShader: VS_ESCOMBRO,
      fragmentShader: FS_ESCOMBRO,
      transparent: true,
      depthWrite: true,
      side: THREE.FrontSide,
      toneMapped: false,
    });
    this.material.name = 'mat_escombros';

    this.malla = new THREE.Mesh(geo, this.material);
    this.malla.name = 'efectos_escombros';
    this.malla.frustumCulled = false;
    this.malla.renderOrder = 3;
    this.malla.matrixAutoUpdate = false;
    this._blindarAO();
  }

  emitir(d, ahora) {
    const i = this._reservar(ahora, d.vida);
    const i2 = i * 2, i3 = i * 3, i4 = i * 4;
    const p = this.aPos0.array, v = this.aVel.array, t = this.aTiempo.array;
    const g = this.aGiro.array, c = this.aColor.array, e = this.aExtra.array;
    p[i3] = d.x; p[i3 + 1] = d.y; p[i3 + 2] = d.z;
    v[i3] = d.vx; v[i3 + 1] = d.vy; v[i3 + 2] = d.vz;
    t[i2] = ahora; t[i2 + 1] = d.vida;
    g[i4] = d.ex; g[i4 + 1] = d.ey; g[i4 + 2] = d.ez; g[i4 + 3] = d.vrot;
    c[i3] = d.r; c[i3 + 1] = d.g; c[i3 + 2] = d.b;
    e[i4] = d.escala; e[i4 + 1] = d.suelo; e[i4 + 2] = d.rebote; e[i4 + 3] = d.brasa;
  }
}

/* ------------------------------------------------------------------ */
/* Pool de tiras (estelas y haces)                                     */
/* ------------------------------------------------------------------ */

class PoolTiras extends PoolBase {
  constructor(capacidad) {
    super(capacidad);
    const n = capacidad;
    this.aA      = atributo(n, 3);
    this.aB      = atributo(n, 3);
    this.aTiempo = atributo(n, 2);
    this.aAnchos = atributo(n, 2);
    this.aColor  = atributo(n, 3);
    this.aExtra  = atributo(n, 4);
    this.atributos = [this.aA, this.aB, this.aTiempo, this.aAnchos, this.aColor, this.aExtra];

    const geo = new THREE.InstancedBufferGeometry();
    geo.index = QUAD.index;
    geo.setAttribute('position', QUAD.attributes.position);
    geo.setAttribute('uv', QUAD.attributes.uv);
    geo.setAttribute('aA', this.aA);
    geo.setAttribute('aB', this.aB);
    geo.setAttribute('aTiempo', this.aTiempo);
    geo.setAttribute('aAnchos', this.aAnchos);
    geo.setAttribute('aColor', this.aColor);
    geo.setAttribute('aExtra', this.aExtra);
    geo.instanceCount = 0;
    geo.boundingSphere = new THREE.Sphere(new THREE.Vector3(), 1e5);
    this.geo = geo;

    this.material = new THREE.ShaderMaterial({
      uniforms: {
        uTiempo: { value: 0 },
        uNieblaDens: { value: 0.0035 },
      },
      vertexShader: VS_TIRA,
      fragmentShader: FS_TIRA,
      transparent: true,
      depthWrite: false,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      toneMapped: false,
    });
    this.material.name = 'mat_tiras';

    this.malla = new THREE.Mesh(geo, this.material);
    this.malla.name = 'efectos_estelas';
    this.malla.frustumCulled = false;
    this.malla.renderOrder = 7;
    this.malla.matrixAutoUpdate = false;
    this._blindarAO();
  }

  emitir(d, ahora) {
    const i = this._reservar(ahora, d.vida);
    const i2 = i * 2, i3 = i * 3, i4 = i * 4;
    const A = this.aA.array, B = this.aB.array, t = this.aTiempo.array;
    const w = this.aAnchos.array, c = this.aColor.array, e = this.aExtra.array;
    A[i3] = d.ax; A[i3 + 1] = d.ay; A[i3 + 2] = d.az;
    B[i3] = d.bx; B[i3 + 1] = d.by; B[i3 + 2] = d.bz;
    t[i2] = ahora; t[i2 + 1] = d.vida;
    w[i2] = d.w0; w[i2 + 1] = d.w1;
    c[i3] = d.r; c[i3 + 1] = d.g; c[i3 + 2] = d.b;
    e[i4] = d.op; e[i4 + 1] = d.dureza; e[i4 + 2] = d.adelgaza; e[i4 + 3] = d.sem;
  }
}

/* ------------------------------------------------------------------ */
/* Pool de planos (ondas de choque y marcas de suelo)                  */
/* ------------------------------------------------------------------ */

class PoolPlanos extends PoolBase {
  constructor(capacidad, mapa) {
    super(capacidad);
    const n = capacidad;
    this.aCentro = atributo(n, 3);
    this.aTiempo = atributo(n, 2);
    this.aRadios = atributo(n, 2);
    this.aColor  = atributo(n, 3);
    this.aExtra  = atributo(n, 4);
    this.atributos = [this.aCentro, this.aTiempo, this.aRadios, this.aColor, this.aExtra];

    const geo = new THREE.InstancedBufferGeometry();
    geo.index = QUAD.index;
    geo.setAttribute('position', QUAD.attributes.position);
    geo.setAttribute('uv', QUAD.attributes.uv);
    geo.setAttribute('aCentro', this.aCentro);
    geo.setAttribute('aTiempo', this.aTiempo);
    geo.setAttribute('aRadios', this.aRadios);
    geo.setAttribute('aColor', this.aColor);
    geo.setAttribute('aExtra', this.aExtra);
    geo.instanceCount = 0;
    geo.boundingSphere = new THREE.Sphere(new THREE.Vector3(), 1e5);
    this.geo = geo;

    this.material = new THREE.ShaderMaterial({
      uniforms: {
        uTiempo: { value: 0 },
        uMapa: { value: mapa },
        uNieblaDens: { value: 0.0035 },
      },
      vertexShader: VS_PLANO,
      fragmentShader: FS_PLANO,
      transparent: true,
      depthWrite: false,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      toneMapped: false,
    });
    this.material.name = 'mat_planos_efecto';
    this.material.polygonOffset = true;
    this.material.polygonOffsetFactor = -4;
    this.material.polygonOffsetUnits = -4;

    this.malla = new THREE.Mesh(geo, this.material);
    this.malla.name = 'efectos_anillos';
    this.malla.frustumCulled = false;
    this.malla.renderOrder = 6;
    this.malla.matrixAutoUpdate = false;
    this._blindarAO();
  }

  emitir(d, ahora) {
    const i = this._reservar(ahora, d.vida);
    const i2 = i * 2, i3 = i * 3, i4 = i * 4;
    const p = this.aCentro.array, t = this.aTiempo.array, r = this.aRadios.array;
    const c = this.aColor.array, e = this.aExtra.array;
    p[i3] = d.x; p[i3 + 1] = d.y; p[i3 + 2] = d.z;
    t[i2] = ahora; t[i2 + 1] = d.vida;
    r[i2] = d.r0; r[i2 + 1] = d.r1;
    c[i3] = d.r; c[i3 + 1] = d.g; c[i3 + 2] = d.b;
    e[i4] = d.op; e[i4 + 1] = d.tipo; e[i4 + 2] = d.curva; e[i4 + 3] = d.sem;
  }
}

/* ------------------------------------------------------------------ */
/* Descriptores reutilizados (cero asignaciones por emisión)           */
/* ------------------------------------------------------------------ */

const DP = {
  x: 0, y: 0, z: 0, vx: 0, vy: 0, vz: 0, vida: 1,
  tam0: 0.2, tam1: 0.4, r: 1, g: 1, b: 1,
  grav: 0, arrastre: 1.2, rot: 0, vrot: 0,
  modo: 0, op: 1, turb: 0, sem: 0,
};
const DE = {
  x: 0, y: 0, z: 0, vx: 0, vy: 0, vz: 0, vida: 2.4,
  ex: 0, ey: 1, ez: 0, vrot: 4, r: 0.4, g: 0.35, b: 0.3,
  escala: 0.2, suelo: 0, rebote: 0.4, brasa: 0,
};
const DT = {
  ax: 0, ay: 0, az: 0, bx: 0, by: 0, bz: 0, vida: 0.3,
  w0: 0.1, w1: 0.1, r: 1, g: 1, b: 1, op: 1, dureza: 1.6, adelgaza: 1, sem: 0,
};
const DA = {
  x: 0, y: 0, z: 0, vida: 0.5, r0: 0.4, r1: 3,
  r: 1, g: 1, b: 1, op: 1, tipo: 0, curva: 2.4, sem: 0,
};

/* ------------------------------------------------------------------ */
/* EFECTOS                                                             */
/* ------------------------------------------------------------------ */

export class Efectos {
  constructor(ctx) {
    this.nombre = 'efectos';
    this.orden = ORDEN.VISTA;
    this.ctx = ctx;

    const calidad = ctx?.calidad || ctx?.render?.calidad || 'alta';
    const cap = CAPACIDADES[calidad] || CAPACIDADES.alta;
    this.cap = cap;
    this.detalle = cap.detalle;
    this.distMax = cap.dist;
    this.dist2Max = cap.dist * cap.dist;

    this.rng = new RNG(((ctx?.mapa?.semilla ?? 20260728) ^ 0x5eed1) >>> 0);
    this.tiempo = 0;
    this._acumViento = 0;

    const blanca = new THREE.DataTexture(new Uint8Array([255, 255, 255, 255]), 1, 1);
    blanca.needsUpdate = true;
    this._blanca = blanca;

    const tex = (clave) => {
      try { return ctx?.texturas?.obtener?.(clave)?.map || blanca; }
      catch (e) { return blanca; }
    };

    /* ---- pools de partículas ---- */
    this.pHumo = new PoolParticulas({
      nombre: 'humo', capacidad: cap.humo, mapa: tex('particula_humo'),
      aditivo: false, entrada: 0.14, salida: 0.32, orden: 5, opacidad: 0.9,
    });
    this.pPolvo = new PoolParticulas({
      nombre: 'polvo', capacidad: cap.polvo, mapa: tex('particula_polvo'),
      aditivo: false, entrada: 0.10, salida: 0.30, orden: 4, opacidad: 0.95,
    });
    this.pFuego = new PoolParticulas({
      nombre: 'fuego', capacidad: cap.fuego, mapa: tex('particula_fuego'),
      aditivo: true, entrada: 0.05, salida: 0.22, orden: 8, opacidad: 1,
    });
    this.pChispa = new PoolParticulas({
      nombre: 'chispa', capacidad: cap.chispa, mapa: blanca,
      aditivo: true, procedural: true, estirar: true,
      entrada: 0.02, salida: 0.30, orden: 9, opacidad: 1,
    });
    this.pDestello = new PoolParticulas({
      nombre: 'destello', capacidad: cap.destello, mapa: tex('destello'),
      aditivo: true, entrada: 0.06, salida: 0.15, orden: 10, opacidad: 1,
    });
    this.pEstallido = new PoolParticulas({
      nombre: 'estallido', capacidad: cap.estallido, mapa: tex('chispa'),
      aditivo: true, entrada: 0.03, salida: 0.14, orden: 9, opacidad: 1,
    });

    this.pEscombros = new PoolEscombros(cap.escombros);
    this.pTiras = new PoolTiras(cap.tiras);
    this.pPlanos = new PoolPlanos(cap.planos, tex('anillo_choque'));

    this.pools = [
      this.pPolvo, this.pHumo, this.pFuego, this.pChispa,
      this.pDestello, this.pEstallido, this.pEscombros, this.pTiras, this.pPlanos,
    ];

    this.raiz = new THREE.Group();
    this.raiz.name = 'efectos';
    this.raiz.matrixAutoUpdate = false;
    for (const p of this.pools) this.raiz.add(p.malla);
    ctx?.escena?.add?.(this.raiz);

    /* ---- pool de luces cortas ---- */
    this.luces = [];
    for (let i = 0; i < cap.luces; i++) {
      const l = new THREE.PointLight(0xffd9a0, 0, 44, 2);
      l.name = `efecto_luz_${i}`;
      l.castShadow = false;
      l.visible = true;          // nunca se apaga: apagarla recompila shaders
      ctx?.escena?.add?.(l);
      this.luces.push({ luz: l, hasta: -1, desde: 0, base: 0 });
    }

    /* ---- humo continuo por objeto ---- */
    this.emisores = new Map();

    /* ---- anti-duplicado de eventos del bus ---- */
    this._selloH = new Int32Array(64);
    this._selloT = new Float32Array(64);
    this._selloP = 0;
    for (let i = 0; i < 64; i++) this._selloT[i] = -999;

    this._bajas = [];
    this._suscribir();
  }

  /* ================================================================ */
  /* Bus                                                              */
  /* ================================================================ */

  _suscribir() {
    const b = this.ctx?.bus || bus;
    if (!b?.on) return;
    this._bajas.push(b.on('combate:disparo', (c) => {
      if (!c || this._reciente(c.x, c.z, 1)) return;
      this.disparo(c.x, c.y, c.z, 0, 0, 0, c.tipo);
    }));
    this._bajas.push(b.on('combate:impacto', (c) => {
      if (!c || this._reciente(c.x, c.z, 2)) return;
      this.impacto(c.x, c.y, c.z, c.tipo, clamp((c.danio || 10) / 40, 0.3, 2));
    }));
    this._bajas.push(b.on('entidad:muerta', (c) => {
      const M = this.ctx?.mundo;
      const id = typeof c === 'number' ? c : c?.id;
      if (M == null || id == null || !M.px) return;
      const x = M.px[id], z = M.pz[id];
      if (!isFinite(x) || !isFinite(z)) return;
      if (this._reciente(x, z, 3)) return;
      this.polvo(x, (M.py[id] || 0) + 0.2, z, 8);
    }));
  }

  /** Sello espacial barato: evita que un evento del bus duplique un efecto directo. */
  _sellar(x, z, cod) {
    const h = ((Math.round(x * 3) * 73856093) ^ (Math.round(z * 3) * 19349663) ^ (cod * 83492791)) | 0;
    const p = this._selloP;
    this._selloH[p] = h;
    this._selloT[p] = this.tiempo;
    this._selloP = p + 1 >= 64 ? 0 : p + 1;
  }

  _reciente(x, z, cod) {
    const h = ((Math.round(x * 3) * 73856093) ^ (Math.round(z * 3) * 19349663) ^ (cod * 83492791)) | 0;
    const t = this.tiempo;
    for (let i = 0; i < 64; i++) {
      if (this._selloH[i] === h && t - this._selloT[i] < 0.25) return true;
    }
    return false;
  }

  /* ================================================================ */
  /* Presupuesto                                                      */
  /* ================================================================ */

  /** 0 = ni lo emitas · 1 = detalle completo. Cae con la distancia a cámara. */
  _peso(x, z) {
    const cam = this.ctx?.camara;
    if (!cam) return this.detalle;
    const dx = cam.position.x - x, dz = cam.position.z - z;
    const d2 = dx * dx + dz * dz;
    if (d2 > this.dist2Max) return 0;
    const f = 1 - (d2 / this.dist2Max) * 0.72;
    return f * this.detalle;
  }

  /** Cantidad efectiva de partículas: redondeo estocástico para no perder los 1. */
  _cant(n, peso) {
    const v = n * peso;
    const e = Math.floor(v);
    return e + (this.rng.r() < v - e ? 1 : 0);
  }

  _suelo(x, z) {
    const t = this.ctx?.terreno;
    const h = t?.altura?.(x, z);
    return typeof h === 'number' && isFinite(h) ? h : 0;
  }

  _tinteSuelo(x, z, salida) {
    const bioma = this.ctx?.terreno?.bioma?.(x, z);
    const c = POLVO_BIOMA[bioma] || POLVO_BIOMA.pradera;
    salida[0] = c[0]; salida[1] = c[1]; salida[2] = c[2];
    return salida;
  }

  /* ================================================================ */
  /* Luces de pool                                                    */
  /* ================================================================ */

  _luz(x, y, z, color, intensidad, radio, duracion) {
    if (!this.luces.length) return;
    let mejor = null, menor = Infinity;
    for (const e of this.luces) {
      if (e.hasta <= this.tiempo) { mejor = e; break; }
      if (e.hasta < menor) { menor = e.hasta; mejor = e; }
    }
    if (!mejor) return;
    mejor.luz.position.set(x, y, z);
    mejor.luz.color.setHex(color);
    mejor.luz.distance = radio;
    mejor.base = intensidad;
    mejor.desde = this.tiempo;
    mejor.hasta = this.tiempo + duracion;
    mejor.luz.intensity = intensidad;
  }

  /* ================================================================ */
  /* API pública                                                      */
  /* ================================================================ */

  /**
   * Fogonazo de boca de fuego, humo de disparo y casquillo.
   * Acepta las dos firmas que usa el juego:
   *   disparo(x,y,z, dirX,dirY,dirZ, tipo)  ·  disparo(x,y,z, dirX,dirZ, tipo)
   */
  disparo(x, y, z, dirX, dirY, dirZ, tipo) {
    if (typeof dirZ === 'string' || (tipo === undefined && typeof dirZ !== 'number')) {
      tipo = dirZ; dirZ = dirY; dirY = 0;
    }
    dirX = dirX || 0; dirY = dirY || 0; dirZ = dirZ || 0;
    const largo = Math.hypot(dirX, dirY, dirZ);
    if (largo > 1e-4) { dirX /= largo; dirY /= largo; dirZ /= largo; }
    else { dirX = 1; dirY = 0; dirZ = 0; }

    const peso = this._peso(x, z);
    if (peso <= 0) return;
    this._sellar(x, z, 1);

    const rng = this.rng;
    const t = tipo || 'bala';
    const grande = t === 'obus' || t === 'cohete' || t === 'misil';
    const frio = t === 'riel';
    const raro = t === 'enjambre';

    const fuerza = grande ? 1.0 : frio ? 0.55 : 0.42;
    const px = x + dirX * 0.25, py = y + dirY * 0.25, pz = z + dirZ * 0.25;

    /* fogonazo: estrella orientada a cámara, 60 ms */
    const d = DP;
    d.x = px; d.y = py; d.z = pz;
    d.vx = dirX * 2.2; d.vy = dirY * 2.2; d.vz = dirZ * 2.2;
    d.vida = grande ? 0.10 : 0.065;
    d.tam0 = 0.30 + fuerza * 0.75; d.tam1 = 0.44 + fuerza * 1.25;
    if (frio) { d.r = 0.55; d.g = 1.90; d.b = 2.40; }
    else if (raro) { d.r = 1.55; d.g = 0.85; d.b = 2.40; }
    else { d.r = 2.35; d.g = 1.45; d.b = 0.60; }
    d.grav = 0; d.arrastre = 6; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-6, 6);
    d.modo = MODO.LIBRE; d.op = 1; d.turb = 0; d.sem = rng.r();
    this.pDestello.emitir(d, this.tiempo);

    if (grande) {                       // segundo pétalo, más ancho y corto
      d.vida = 0.075; d.tam0 = 1.1; d.tam1 = 2.1;
      d.rot = rng.float(0, 6.283); d.op = 0.75;
      this.pDestello.emitir(d, this.tiempo);
    }

    /* chispas de pólvora en cono hacia adelante */
    const nCh = this._cant(grande ? 16 : frio ? 8 : 6, peso);
    for (let i = 0; i < nCh; i++) {
      const disp = grande ? 0.45 : 0.30;
      const vel = rng.float(6, grande ? 26 : 15);
      d.x = px; d.y = py; d.z = pz;
      d.vx = (dirX + rng.gauss(0, disp)) * vel;
      d.vy = (dirY + rng.float(0.02, 0.34)) * vel;
      d.vz = (dirZ + rng.gauss(0, disp)) * vel;
      d.vida = rng.float(0.16, grande ? 0.65 : 0.34);
      d.tam0 = rng.float(0.050, 0.115); d.tam1 = d.tam0 * 0.35;
      if (frio) { d.r = 0.7; d.g = 2.2; d.b = 2.8; }
      else if (raro) { d.r = 1.7; d.g = 0.9; d.b = 2.6; }
      else { d.r = 2.7; d.g = 1.5; d.b = 0.45; }
      d.grav = 9; d.arrastre = 1.6; d.rot = 0; d.vrot = 0;
      d.op = 1; d.turb = 0; d.sem = rng.r();
      this.pChispa.emitir(d, this.tiempo);
    }

    /* humo de boca (la pólvora ensucia; el riel no) */
    if (!frio) {
      const nH = this._cant(grande ? 9 : 3, peso);
      for (let i = 0; i < nH; i++) {
        const vel = rng.float(1.2, grande ? 7.5 : 3.4);
        d.x = px + rng.gauss(0, 0.12); d.y = py + rng.gauss(0, 0.1); d.z = pz + rng.gauss(0, 0.12);
        d.vx = dirX * vel + rng.gauss(0, 0.5);
        d.vy = dirY * vel + rng.float(0.4, 1.5);
        d.vz = dirZ * vel + rng.gauss(0, 0.5);
        d.vida = rng.float(0.9, grande ? 2.6 : 1.5);
        d.tam0 = rng.float(0.16, 0.34) * (grande ? 1.8 : 1);
        d.tam1 = d.tam0 * rng.float(3.2, 5.4);
        const gris = rng.float(0.95, 1.30);
        d.r = gris; d.g = gris * 0.98; d.b = gris * 0.94;
        d.grav = -0.5; d.arrastre = 1.5; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-1.1, 1.1);
        d.op = rng.float(0.35, 0.6); d.turb = 0.5; d.sem = rng.r();
        this.pHumo.emitir(d, this.tiempo);
      }
    }

    /* casquillo: una cajita de latón que salta y rebota */
    if (!grande && !frio && peso > 0.55 && rng.bool(0.75)) {
      const e = DE;
      const lx = -dirZ, lz = dirX;             // perpendicular al cañón
      e.x = px; e.y = py; e.z = pz;
      e.vx = lx * rng.float(1.6, 3.4) + rng.gauss(0, 0.4);
      e.vy = rng.float(2.4, 4.2);
      e.vz = lz * rng.float(1.6, 3.4) + rng.gauss(0, 0.4);
      e.vida = rng.float(1.6, 2.6);
      e.ex = rng.gauss(0, 1); e.ey = rng.gauss(0, 1); e.ez = rng.gauss(0, 1);
      e.vrot = rng.float(-22, 22);
      e.r = 1.35; e.g = 0.95; e.b = 0.32;
      e.escala = rng.float(0.045, 0.07);
      e.suelo = this._suelo(px, pz) + 0.02;
      e.rebote = 0.22; e.brasa = 0;
      this.pEscombros.emitir(e, this.tiempo);
    }

    /* polvo levantado si el arma es pesada y está cerca del suelo */
    if (grande) {
      const suelo = this._suelo(x, z);
      if (y - suelo < 3.2) this._anilloPolvo(x, suelo, z, 1.5, peso, 7);
    }

    this._luz(px, py + 0.2, pz,
      frio ? 0x8fe6ff : raro ? 0xc79dff : 0xffc46a,
      grande ? 260 : 70, grande ? 26 : 13, grande ? 0.10 : 0.06);
  }

  /**
   * Impacto puntual. `tipo` puede ser una clave de proyectil ('bala','obus',
   * 'misil','cohete','enjambre','riel') o un estado ('cuerpo','muerte','cura',
   * 'conversion','ascenso').
   */
  impacto(x, y, z, tipo, fuerza = 1) {
    const peso = this._peso(x, z);
    if (peso <= 0) return;
    const f = clamp(fuerza || 1, 0.2, 3);
    const rng = this.rng;
    const d = DP;
    this._sellar(x, z, 2);

    switch (tipo) {
      /* --------------------------------------------- efectos de apoyo */
      case 'cura':      this._motas(x, y, z, 0.35, 1.45, 0.55, peso, f); return;
      case 'ascenso':   this._motas(x, y, z, 1.55, 1.25, 0.35, peso, f * 1.4); return;
      case 'conversion':this._motas(x, y, z, 1.20, 0.55, 1.70, peso, f * 1.6); return;

      /* --------------------------------------------- muerte y cuerpo */
      case 'muerte':
        this.sangre(x, y, z, rng.gauss(0, 1), rng.gauss(0, 1));
        this.polvo(x, this._suelo(x, z), z, 10 * f);
        this._sellar(x, z, 3);
        return;

      case 'cuerpo': {
        const n = this._cant(5 + 5 * f, peso);
        for (let i = 0; i < n; i++) {
          const vel = rng.float(3, 11) * f;
          d.x = x; d.y = y; d.z = z;
          d.vx = rng.gauss(0, 1) * vel; d.vy = rng.float(0.6, 4) * f; d.vz = rng.gauss(0, 1) * vel;
          d.vida = rng.float(0.12, 0.34);
          d.tam0 = rng.float(0.045, 0.10); d.tam1 = d.tam0 * 0.3;
          d.r = 2.6; d.g = 1.7; d.b = 0.7;
          d.grav = 11; d.arrastre = 2.2; d.rot = 0; d.vrot = 0;
          d.modo = MODO.LIBRE; d.op = 1; d.turb = 0; d.sem = rng.r();
          this.pChispa.emitir(d, this.tiempo);
        }
        if (f > 0.8 && rng.bool(0.5)) this.sangre(x, y, z, rng.gauss(0, 1), rng.gauss(0, 1));
        return;
      }

      /* --------------------------------------------- balística */
      default: break;
    }

    const frio = tipo === 'riel';
    const raro = tipo === 'enjambre';

    /* destello del golpe */
    d.x = x; d.y = y; d.z = z;
    d.vx = 0; d.vy = 0; d.vz = 0;
    d.vida = frio ? 0.14 : 0.09;
    d.tam0 = 0.20 * f + 0.16; d.tam1 = 0.55 * f + 0.30;
    if (frio) { d.r = 0.6; d.g = 2.0; d.b = 2.6; }
    else if (raro) { d.r = 1.6; d.g = 0.8; d.b = 2.5; }
    else { d.r = 2.4; d.g = 1.7; d.b = 0.9; }
    d.grav = 0; d.arrastre = 4; d.rot = rng.float(0, 6.283); d.vrot = 0;
    d.modo = MODO.LIBRE; d.op = 1; d.turb = 0; d.sem = rng.r();
    this.pDestello.emitir(d, this.tiempo);

    /* estallido de esquirlas (sprite de chispazos) */
    const nE = this._cant(1 + f, peso);
    for (let i = 0; i < nE; i++) {
      d.vida = rng.float(0.12, 0.26);
      d.tam0 = (0.4 + f * 0.5) * rng.float(0.8, 1.3); d.tam1 = d.tam0 * 1.9;
      d.rot = rng.float(0, 6.283); d.vrot = rng.float(-3, 3);
      d.op = 0.9; d.sem = rng.r();
      this.pEstallido.emitir(d, this.tiempo);
    }

    /* chispas */
    const nCh = this._cant((frio ? 16 : 9) * (0.6 + f), peso);
    for (let i = 0; i < nCh; i++) {
      const vel = rng.float(4, 16) * (0.6 + f * 0.6);
      d.x = x; d.y = y; d.z = z;
      d.vx = rng.gauss(0, 1) * vel; d.vy = Math.abs(rng.gauss(0, 1)) * vel * 0.8 + 1.5; d.vz = rng.gauss(0, 1) * vel;
      d.vida = rng.float(0.18, 0.55);
      d.tam0 = rng.float(0.045, 0.115); d.tam1 = d.tam0 * 0.3;
      if (frio) { d.r = 0.8; d.g = 2.3; d.b = 3.0; }
      else if (raro) { d.r = 1.8; d.g = 0.9; d.b = 2.7; }
      else { d.r = 2.8; d.g = 1.5; d.b = 0.5; }
      d.grav = 13; d.arrastre = 1.5; d.rot = 0; d.vrot = 0;
      d.op = 1; d.turb = 0; d.sem = rng.r();
      this.pChispa.emitir(d, this.tiempo);
    }

    /* tierra y humo del golpe */
    const suelo = this._suelo(x, z);
    if (y - suelo < 1.6) this._anilloPolvo(x, suelo, z, 0.9 * f, peso, Math.round(5 * f) + 3);
    else this.polvo(x, y, z, 3 * f);

    if (!frio) {
      const nH = this._cant(2 + 2 * f, peso);
      for (let i = 0; i < nH; i++) {
        d.x = x + rng.gauss(0, 0.15); d.y = y + rng.gauss(0, 0.12); d.z = z + rng.gauss(0, 0.15);
        d.vx = rng.gauss(0, 0.8); d.vy = rng.float(0.6, 2.0); d.vz = rng.gauss(0, 0.8);
        d.vida = rng.float(0.8, 1.9);
        d.tam0 = rng.float(0.14, 0.30) * f; d.tam1 = d.tam0 * rng.float(3, 5);
        const gris = rng.float(0.62, 0.95);
        d.r = gris; d.g = gris * 0.97; d.b = gris * 0.93;
        d.grav = -0.6; d.arrastre = 1.4; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-1, 1);
        d.op = rng.float(0.3, 0.55); d.turb = 0.55; d.sem = rng.r();
        this.pHumo.emitir(d, this.tiempo);
      }
    }

    if (f > 0.7) {
      this._luz(x, y + 0.3, z, frio ? 0x9fe8ff : 0xffb060, 70 * f, 14, 0.07);
    }
  }

  /**
   * Explosión completa: bola de fuego que se enfría, onda de choque, escombros
   * con rebote, humo negro que sube y flash de luz.
   */
  explosion(x, y, z, radio = 3) {
    const peso = this._peso(x, z);
    const R = clamp(radio || 3, 0.6, 30);
    if (peso <= 0) {
      // aunque no se vea, la quemadura del terreno queda
      if (R > 2) this.ctx?.terreno?.pintarDecal?.(x, z, R * 0.8, 'quemadura');
      return;
    }
    const rng = this.rng;
    const d = DP;
    const suelo = this._suelo(x, z);
    this._sellar(x, z, 2);

    /* ---- núcleo blanco: dura un suspiro ---- */
    d.x = x; d.y = y; d.z = z;
    d.vx = 0; d.vy = 0; d.vz = 0;
    d.vida = 0.09 + R * 0.010;
    d.tam0 = R * 0.26; d.tam1 = R * 0.68;
    d.r = 2.5; d.g = 1.90; d.b = 1.15;
    d.grav = 0; d.arrastre = 3; d.rot = rng.float(0, 6.283); d.vrot = 0;
    d.modo = MODO.LIBRE; d.op = 1; d.turb = 0; d.sem = rng.r();
    this.pDestello.emitir(d, this.tiempo);

    /* ---- bola de fuego: brasas que van de blanco a naranja a ceniza ---- */
    const nF = this._cant(9 + R * 2.6, peso);
    for (let i = 0; i < nF; i++) {
      const ang = rng.float(0, 6.283);
      const rad = rng.float(0, R * 0.45);
      const vel = rng.float(1.5, 5.5) * (0.6 + R * 0.14);
      d.x = x + Math.cos(ang) * rad;
      d.y = y + rng.float(-0.2, 0.6) * R * 0.3;
      d.z = z + Math.sin(ang) * rad;
      d.vx = Math.cos(ang) * vel * 0.7;
      d.vy = rng.float(0.8, 4.2) + R * 0.3;
      d.vz = Math.sin(ang) * vel * 0.7;
      d.vida = rng.float(0.32, 0.62) + R * 0.035;
      d.tam0 = R * rng.float(0.18, 0.36); d.tam1 = d.tam0 * rng.float(1.8, 3.0);
      d.r = 1.0; d.g = 0.62; d.b = 0.30;
      d.grav = -1.6; d.arrastre = 1.9; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-1.6, 1.6);
      d.modo = MODO.BRASA; d.op = 1; d.turb = 0.35; d.sem = rng.r();
      this.pFuego.emitir(d, this.tiempo);
    }
    d.modo = MODO.LIBRE;

    /* ---- onda de choque: anillo achatado que se abre ---- */
    const a = DA;
    a.x = x; a.y = suelo; a.z = z;
    a.vida = 0.26 + R * 0.022;
    a.r0 = R * 0.22; a.r1 = R * 2.5;
    a.r = 1.55; a.g = 1.42; a.b = 1.20;
    a.op = clamp(0.15 + R * 0.025, 0.14, 0.40); a.tipo = 0; a.curva = 3.4; a.sem = rng.r();
    this.pPlanos.emitir(a, this.tiempo);

    /* ---- polvo al ras, empujado hacia afuera ---- */
    this._anilloPolvo(x, suelo, z, R * 0.8, peso, Math.round(8 + R * 3));

    /* ---- escombros ---- */
    const nEsc = this._cant(5 + R * 2.2, peso);
    const e = DE;
    for (let i = 0; i < nEsc; i++) {
      const ang = rng.float(0, 6.283);
      const vel = rng.float(3, 9) * (0.7 + R * 0.16);
      e.x = x + rng.gauss(0, R * 0.15);
      e.y = y + rng.float(0, 0.5);
      e.z = z + rng.gauss(0, R * 0.15);
      e.vx = Math.cos(ang) * vel;
      e.vy = rng.float(4, 12) + R * 0.5;
      e.vz = Math.sin(ang) * vel;
      e.vida = rng.float(1.8, 3.4);
      e.ex = rng.gauss(0, 1); e.ey = rng.gauss(0, 1); e.ez = rng.gauss(0, 1);
      e.vrot = rng.float(-16, 16);
      const g = rng.float(0.16, 0.34);
      e.r = g * rng.float(0.9, 1.25); e.g = g; e.b = g * rng.float(0.7, 0.95);
      e.escala = rng.float(0.08, 0.16) * (0.7 + R * 0.14);
      e.suelo = this._suelo(e.x, e.z) + 0.02;
      e.rebote = rng.float(0.3, 0.9); e.brasa = rng.float(0.35, 1.15);
      this.pEscombros.emitir(e, this.tiempo);
    }

    /* ---- humo negro que sube y se lo lleva el viento ---- */
    const nH = this._cant(6 + R * 2.4, peso);
    for (let i = 0; i < nH; i++) {
      const ang = rng.float(0, 6.283);
      const rad = rng.float(0, R * 0.5);
      d.x = x + Math.cos(ang) * rad;
      d.y = y + rng.float(0, R * 0.4);
      d.z = z + Math.sin(ang) * rad;
      d.vx = Math.cos(ang) * rng.float(0.5, 2.4);
      d.vy = rng.float(1.4, 4.0);
      d.vz = Math.sin(ang) * rng.float(0.5, 2.4);
      d.vida = rng.float(2.2, 4.6) + R * 0.08;
      d.tam0 = R * rng.float(0.22, 0.42); d.tam1 = d.tam0 * rng.float(2.6, 4.4);
      const gris = rng.float(0.10, 0.26);
      d.r = gris * 1.06; d.g = gris; d.b = gris * 0.94;
      d.grav = -0.75; d.arrastre = 0.8; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-0.8, 0.8);
      d.op = rng.float(0.5, 0.85); d.turb = 0.9; d.sem = rng.r();
      this.pHumo.emitir(d, this.tiempo);
    }

    /* ---- esquirlas al aire ---- */
    const nCh = this._cant(10 + R * 4, peso);
    for (let i = 0; i < nCh; i++) {
      const vel = rng.float(6, 26) * (0.6 + R * 0.12);
      d.x = x; d.y = y; d.z = z;
      d.vx = rng.gauss(0, 1) * vel;
      d.vy = Math.abs(rng.gauss(0, 1)) * vel * 0.9 + 2;
      d.vz = rng.gauss(0, 1) * vel;
      d.vida = rng.float(0.3, 1.0);
      d.tam0 = rng.float(0.055, 0.14); d.tam1 = d.tam0 * 0.3;
      d.r = 2.9; d.g = 1.6; d.b = 0.5;
      d.grav = 14; d.arrastre = 1.1; d.rot = 0; d.vrot = 0;
      d.op = 1; d.turb = 0; d.sem = rng.r();
      this.pChispa.emitir(d, this.tiempo);
    }

    /* ---- flash + marca en el suelo ---- */
    this._luz(x, y + R * 0.3, z, 0xffb060, clamp(R * R * 55, 150, 2600), R * 12, 0.16);
    const terr = this.ctx?.terreno;
    if (terr?.pintarDecal) {
      terr.pintarDecal(x, z, Math.max(1, R * 0.85), 'quemadura');
      if (R >= 3.5) terr.pintarDecal(x, z, Math.max(0.8, R * 0.45), 'crater');
    }
  }

  /** Polvo genérico (pasos, obras, derrumbes). */
  polvo(x, y, z, cantidad = 10) {
    const peso = this._peso(x, z);
    if (peso <= 0) return;
    const rng = this.rng;
    const d = DP;
    const c = this._tinteSuelo(x, z, TMP3);
    const n = this._cant(cantidad, peso);
    for (let i = 0; i < n; i++) {
      const ang = rng.float(0, 6.283);
      const vel = rng.float(0.2, 1.7);
      d.x = x + rng.gauss(0, 0.22);
      d.y = y + rng.float(0.02, 0.30);
      d.z = z + rng.gauss(0, 0.22);
      d.vx = Math.cos(ang) * vel; d.vy = rng.float(0.25, 1.15); d.vz = Math.sin(ang) * vel;
      d.vida = rng.float(0.8, 2.0);
      d.tam0 = rng.float(0.12, 0.30); d.tam1 = d.tam0 * rng.float(2.2, 3.6);
      const v = rng.float(0.85, 1.15);
      d.r = c[0] * v; d.g = c[1] * v; d.b = c[2] * v;
      d.grav = 0.55; d.arrastre = 1.7; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-1.2, 1.2);
      d.modo = MODO.LIBRE; d.op = rng.float(0.28, 0.55); d.turb = 0.35; d.sem = rng.r();
      this.pPolvo.emitir(d, this.tiempo);
    }
  }

  /** Anillo de polvo que se abre pegado al piso (impactos y explosiones). */
  _anilloPolvo(x, suelo, z, radio, peso, cantidad) {
    const rng = this.rng;
    const d = DP;
    const c = this._tinteSuelo(x, z, TMP3);
    const n = this._cant(cantidad, peso);
    for (let i = 0; i < n; i++) {
      const ang = rng.float(0, 6.283);
      const vel = rng.float(2.5, 7) * (0.5 + radio * 0.4);
      d.x = x + Math.cos(ang) * radio * 0.3;
      d.y = suelo + rng.float(0.05, 0.35);
      d.z = z + Math.sin(ang) * radio * 0.3;
      d.vx = Math.cos(ang) * vel; d.vy = rng.float(0.4, 1.8); d.vz = Math.sin(ang) * vel;
      d.vida = rng.float(1.1, 2.4);
      d.tam0 = rng.float(0.18, 0.42) * (0.7 + radio * 0.4);
      d.tam1 = d.tam0 * rng.float(2.6, 4.2);
      const v = rng.float(0.8, 1.2);
      d.r = c[0] * v; d.g = c[1] * v; d.b = c[2] * v;
      d.grav = 0.7; d.arrastre = 2.1; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-1, 1);
      d.modo = MODO.LIBRE; d.op = rng.float(0.32, 0.62); d.turb = 0.4; d.sem = rng.r();
      this.pPolvo.emitir(d, this.tiempo);
    }
  }

  /** Motas ascendentes de colorcito (curación, ascenso, conversión). */
  _motas(x, y, z, r, g, b, peso, fuerza) {
    const rng = this.rng;
    const d = DP;
    const n = this._cant(6 + 6 * fuerza, peso);
    for (let i = 0; i < n; i++) {
      const ang = rng.float(0, 6.283);
      const rad = rng.float(0.15, 0.75);
      d.x = x + Math.cos(ang) * rad;
      d.y = y - 0.6 + rng.float(0, 0.4);
      d.z = z + Math.sin(ang) * rad;
      d.vx = Math.cos(ang) * 0.25; d.vy = rng.float(1.1, 2.6); d.vz = Math.sin(ang) * 0.25;
      d.vida = rng.float(0.6, 1.3);
      d.tam0 = rng.float(0.05, 0.13); d.tam1 = d.tam0 * 0.5;
      d.r = r; d.g = g; d.b = b;
      d.grav = -0.6; d.arrastre = 1.1; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-2, 2);
      d.modo = MODO.LIBRE; d.op = 1; d.turb = 0.5; d.sem = rng.r();
      this.pDestello.emitir(d, this.tiempo);
    }
    const a = DA;
    a.x = x; a.y = this._suelo(x, z); a.z = z;
    a.vida = 0.75; a.r0 = 0.3; a.r1 = 1.6 + fuerza * 0.6;
    a.r = r; a.g = g; a.b = b;
    a.op = 0.7; a.tipo = 1; a.curva = 1.8; a.sem = rng.r();
    this.pPlanos.emitir(a, this.tiempo);
  }

  /**
   * Humo continuo colgado de un objeto (edificio dañado, motor, chimenea).
   * Llamar con intensidad 0 lo apaga. Devuelve un manejador.
   */
  humoContinuo(objeto3D, intensidad = 1) {
    if (!objeto3D) return null;
    if (!(intensidad > 0.001)) {
      this.emisores.delete(objeto3D);
      return null;
    }
    let em = this.emisores.get(objeto3D);
    if (!em) {
      em = {
        objeto: objeto3D, intensidad, acum: 0, alto: 1.4,
        detener: () => this.emisores.delete(objeto3D),
      };
      this.emisores.set(objeto3D, em);
    } else {
      em.intensidad = intensidad;
    }
    return em;
  }

  /** Segmento de estela detrás de un proyectil. */
  estela(desde, hasta, tipo = 'humo') {
    if (!desde || !hasta) return;
    const peso = this._peso(hasta.x, hasta.z);
    if (peso <= 0) return;
    const rng = this.rng;
    const t = DT;
    t.ax = desde.x; t.ay = desde.y; t.az = desde.z;
    t.bx = hasta.x; t.by = hasta.y; t.bz = hasta.z;
    t.sem = rng.r();
    t.adelgaza = 1;

    if (tipo === 'riel') {
      t.vida = 0.28; t.w0 = 0.10; t.w1 = 0.10;
      t.r = 0.55; t.g = 1.9; t.b = 2.6; t.op = 1; t.dureza = 1.1;
    } else if (tipo === 'fuego' || tipo === 'cohete' || tipo === 'misil') {
      t.vida = 0.34; t.w0 = 0.05; t.w1 = 0.16;
      t.r = 2.2; t.g = 1.1; t.b = 0.35; t.op = 0.95; t.dureza = 1.5;
    } else if (tipo === 'enjambre') {
      t.vida = 0.40; t.w0 = 0.04; t.w1 = 0.12;
      t.r = 1.5; t.g = 0.7; t.b = 2.4; t.op = 0.9; t.dureza = 1.4;
    } else {
      t.vida = 0.45; t.w0 = 0.04; t.w1 = 0.14;
      t.r = 0.8; t.g = 0.78; t.b = 0.74; t.op = 0.55; t.dureza = 2.2;
    }
    this.pTiras.emitir(t, this.tiempo);

    if ((tipo === 'humo' || tipo === 'misil' || tipo === 'cohete') && peso > 0.5 && rng.bool(0.34)) {
      const d = DP;
      d.x = hasta.x; d.y = hasta.y; d.z = hasta.z;
      d.vx = rng.gauss(0, 0.35); d.vy = rng.float(0.2, 0.9); d.vz = rng.gauss(0, 0.35);
      d.vida = rng.float(0.8, 1.8);
      d.tam0 = rng.float(0.10, 0.22); d.tam1 = d.tam0 * rng.float(2.6, 4.2);
      const gris = rng.float(0.80, 1.15);
      d.r = gris; d.g = gris * 0.98; d.b = gris * 0.95;
      d.grav = -0.4; d.arrastre = 1.3; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-1, 1);
      d.modo = MODO.LIBRE; d.op = rng.float(0.22, 0.45); d.turb = 0.5; d.sem = rng.r();
      this.pHumo.emitir(d, this.tiempo);
    }
  }

  /** Haz recto y luminoso (riel, rayo, guía). */
  haz(desde, hasta, color = 0x9fe8ff, duracion = 0.22) {
    if (!desde || !hasta) return;
    if (this._peso(hasta.x, hasta.z) <= 0 && this._peso(desde.x, desde.z) <= 0) return;
    COLOR_AUX.setHex(color);
    const t = DT;
    t.ax = desde.x; t.ay = desde.y; t.az = desde.z;
    t.bx = hasta.x; t.by = hasta.y; t.bz = hasta.z;
    t.vida = duracion; t.sem = this.rng.r();
    t.r = COLOR_AUX.r * 2.2; t.g = COLOR_AUX.g * 2.2; t.b = COLOR_AUX.b * 2.2;

    t.w0 = 0.26; t.w1 = 0.26; t.op = 0.55; t.dureza = 1.0; t.adelgaza = 1;
    this.pTiras.emitir(t, this.tiempo);           // halo ancho
    t.w0 = 0.075; t.w1 = 0.075; t.op = 1; t.dureza = 1.8; t.adelgaza = 0.6;
    this.pTiras.emitir(t, this.tiempo);           // núcleo

    this._luz(hasta.x, hasta.y, hasta.z, color, 160, 18, Math.min(duracion, 0.14));
  }

  /** Salpicadura de sangre con dirección. */
  sangre(x, y, z, dirX = 0, dirZ = 0) {
    const peso = this._peso(x, z);
    if (peso <= 0) return;
    const rng = this.rng;
    const largo = Math.hypot(dirX, dirZ);
    const ux = largo > 1e-3 ? dirX / largo : 0;
    const uz = largo > 1e-3 ? dirZ / largo : 0;
    const d = DP;
    const n = this._cant(11, peso);
    for (let i = 0; i < n; i++) {
      const vel = rng.float(1.6, 6.5);
      d.x = x + rng.gauss(0, 0.1);
      d.y = y + rng.gauss(0, 0.15);
      d.z = z + rng.gauss(0, 0.1);
      d.vx = (ux * 0.9 + rng.gauss(0, 0.6)) * vel;
      d.vy = rng.float(0.8, 3.4);
      d.vz = (uz * 0.9 + rng.gauss(0, 0.6)) * vel;
      d.vida = rng.float(0.45, 0.95);
      d.tam0 = rng.float(0.035, 0.10); d.tam1 = d.tam0 * 0.75;
      const v = rng.float(0.75, 1.15);
      d.r = 0.42 * v; d.g = 0.035 * v; d.b = 0.03 * v;
      d.grav = 15; d.arrastre = 0.9; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-3, 3);
      d.modo = MODO.LIBRE; d.op = rng.float(0.75, 1); d.turb = 0; d.sem = rng.r();
      this.pPolvo.emitir(d, this.tiempo);
    }
    // una nubecita roja que se queda flotando un instante
    d.x = x; d.y = y; d.z = z;
    d.vx = ux * 0.6; d.vy = 0.35; d.vz = uz * 0.6;
    d.vida = 0.55; d.tam0 = 0.16; d.tam1 = 0.44;
    d.r = 0.34; d.g = 0.03; d.b = 0.025;
    d.grav = 2.2; d.arrastre = 2.4; d.op = 0.55; d.turb = 0.2; d.sem = rng.r();
    this.pPolvo.emitir(d, this.tiempo);
  }

  /** Chispazo suelto (metal contra metal, cortocircuito, herrería). */
  chispas(x, y, z, cantidad = 12) {
    const peso = this._peso(x, z);
    if (peso <= 0) return;
    const rng = this.rng;
    const d = DP;
    const n = this._cant(cantidad, peso);
    for (let i = 0; i < n; i++) {
      const vel = rng.float(3, 13);
      d.x = x; d.y = y; d.z = z;
      d.vx = rng.gauss(0, 1) * vel;
      d.vy = Math.abs(rng.gauss(0, 1)) * vel * 0.7 + 1;
      d.vz = rng.gauss(0, 1) * vel;
      d.vida = rng.float(0.2, 0.6);
      d.tam0 = rng.float(0.042, 0.10); d.tam1 = d.tam0 * 0.3;
      d.r = 2.8; d.g = 1.55; d.b = 0.45;
      d.grav = 13; d.arrastre = 1.4; d.rot = 0; d.vrot = 0;
      d.modo = MODO.LIBRE; d.op = 1; d.turb = 0; d.sem = rng.r();
      this.pChispa.emitir(d, this.tiempo);
    }
    this._luz(x, y, z, 0xffc070, 40, 9, 0.06);
  }

  /** Marca en el suelo al dar una orden. */
  marcaOrden(x, z, tipo = 'mover') {
    const c = COLOR_MARCA[tipo] || COLOR_MARCA.mover;
    const y = this._suelo(x, z);
    const rng = this.rng;
    const a = DA;
    a.x = x; a.y = y; a.z = z;
    a.r = c[0]; a.g = c[1]; a.b = c[2];
    a.tipo = 1; a.sem = rng.r();

    a.vida = 0.55; a.r0 = 1.5; a.r1 = 0.55; a.op = 1; a.curva = 2.2;
    this.pPlanos.emitir(a, this.tiempo);
    a.vida = 0.85; a.r0 = 0.3; a.r1 = 1.9; a.op = 0.5; a.curva = 3.0;
    this.pPlanos.emitir(a, this.tiempo);

    const d = DP;
    const n = this._cant(6, 1);
    for (let i = 0; i < n; i++) {
      const ang = rng.float(0, 6.283);
      d.x = x + Math.cos(ang) * rng.float(0.1, 0.5);
      d.y = y + 0.05;
      d.z = z + Math.sin(ang) * rng.float(0.1, 0.5);
      d.vx = Math.cos(ang) * 0.4; d.vy = rng.float(0.7, 1.9); d.vz = Math.sin(ang) * 0.4;
      d.vida = rng.float(0.35, 0.7);
      d.tam0 = rng.float(0.05, 0.1); d.tam1 = d.tam0 * 0.4;
      d.r = c[0]; d.g = c[1]; d.b = c[2];
      d.grav = -0.4; d.arrastre = 1.6; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-3, 3);
      d.modo = MODO.LIBRE; d.op = 1; d.turb = 0.3; d.sem = rng.r();
      this.pDestello.emitir(d, this.tiempo);
    }
  }

  /** Hojas que saltan al talar o al pasar entre la maleza. */
  hoja(x, y, z, cantidad = 5) {
    const peso = this._peso(x, z);
    if (peso <= 0) return;
    const rng = this.rng;
    const d = DP;
    const n = this._cant(cantidad, peso);
    for (let i = 0; i < n; i++) {
      const ang = rng.float(0, 6.283);
      d.x = x + rng.gauss(0, 0.35);
      d.y = y + rng.float(-0.2, 0.6);
      d.z = z + rng.gauss(0, 0.35);
      d.vx = Math.cos(ang) * rng.float(0.4, 1.6);
      d.vy = rng.float(0.2, 1.4);
      d.vz = Math.sin(ang) * rng.float(0.4, 1.6);
      d.vida = rng.float(1.6, 3.4);
      d.tam0 = rng.float(0.07, 0.15); d.tam1 = d.tam0;
      const v = rng.float(0.7, 1.2);
      d.r = 0.20 * v; d.g = 0.42 * v; d.b = 0.13 * v;
      d.grav = 1.1; d.arrastre = 1.6; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-3.5, 3.5);
      d.modo = MODO.HOJA; d.op = 1; d.turb = 0.25; d.sem = rng.r();
      this.pPolvo.emitir(d, this.tiempo);
    }
  }

  /** Burbujas bajo el agua o al hundirse algo. */
  burbujas(x, y, z, cantidad = 8) {
    const peso = this._peso(x, z);
    if (peso <= 0) return;
    const rng = this.rng;
    const d = DP;
    const n = this._cant(cantidad, peso);
    for (let i = 0; i < n; i++) {
      d.x = x + rng.gauss(0, 0.3);
      d.y = y + rng.float(-0.4, 0.1);
      d.z = z + rng.gauss(0, 0.3);
      d.vx = rng.gauss(0, 0.15); d.vy = rng.float(0.5, 1.5); d.vz = rng.gauss(0, 0.15);
      d.vida = rng.float(0.7, 1.6);
      d.tam0 = rng.float(0.04, 0.11); d.tam1 = d.tam0 * 1.3;
      d.r = 1.05; d.g = 1.25; d.b = 1.35;
      d.grav = -1.4; d.arrastre = 1.2; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-1, 1);
      d.modo = MODO.LIBRE; d.op = rng.float(0.35, 0.7); d.turb = 0.45; d.sem = rng.r();
      this.pHumo.emitir(d, this.tiempo);
    }
  }

  /* ================================================================ */
  /* Bucle                                                            */
  /* ================================================================ */

  cada(dtReal, alfa, ctx) {
    const dt = Math.min(dtReal || 0, 0.1);
    this.tiempo += dt;
    const t = this.tiempo;

    /* --- viento suave, común a humo y polvo --- */
    this._acumViento += dt * 0.12;
    const vx = 0.55 + Math.sin(this._acumViento) * 0.35;
    const vz = 0.22 + Math.cos(this._acumViento * 0.73) * 0.30;

    /* --- luz ambiente para el humo (que no brille de noche) --- */
    const sol = ctx?.cielo?.sol;
    const inten = sol ? clamp(sol.intensity / 3.6, 0.05, 1.2) : 1;
    const cs = sol ? sol.color : null;
    const lr = clamp((cs ? cs.r : 1) * inten * 0.72 + 0.30, 0.12, 1.6);
    const lg = clamp((cs ? cs.g : 1) * inten * 0.72 + 0.31, 0.12, 1.6);
    const lb = clamp((cs ? cs.b : 1) * inten * 0.72 + 0.34, 0.12, 1.6);

    /* --- niebla de la escena, para que las partículas lejanas se fundan --- */
    const fog = ctx?.escena?.fog;
    const dens = fog && fog.density != null ? fog.density : 0.0035;
    let fr = 0.62, fg = 0.70, fb = 0.78;
    if (fog && fog.color) { fr = fog.color.r; fg = fog.color.g; fb = fog.color.b; }

    for (let i = 0; i < this.pools.length; i++) {
      const u = this.pools[i].material.uniforms;
      u.uTiempo.value = t;
      if (u.uNieblaDens) u.uNieblaDens.value = dens;
      if (u.uNieblaColor) u.uNieblaColor.value.set(fr, fg, fb);
      if (u.uViento) u.uViento.value.set(vx, vz);
      if (u.uLuz) {
        // los aditivos no se apagan con la luz ambiente: son emisivos
        if (u.uMezclaNiebla && u.uMezclaNiebla.value < 0.5) u.uLuz.value.set(1, 1, 1);
        else u.uLuz.value.set(lr, lg, lb);
      }
    }

    /* --- escombros: iluminación simple con el sol real --- */
    const ue = this.pEscombros.material.uniforms;
    const dirSol = ctx?.cielo?.dirSol;
    if (dirSol) ue.uDirSol.value.set(dirSol.x, dirSol.y, dirSol.z);
    ue.uColorSol.value.set(lr * 1.15, lg * 1.1, lb * 0.95);
    ue.uAmbiente.value.set(lr * 0.34, lg * 0.36, lb * 0.42);

    /* --- humo continuo colgado de objetos --- */
    if (this.emisores.size) this._actualizarEmisores(dt);

    /* --- luces de pool: se apagan solas --- */
    for (let i = 0; i < this.luces.length; i++) {
      const e = this.luces[i];
      if (e.hasta <= t) { if (e.luz.intensity !== 0) e.luz.intensity = 0; continue; }
      const k = (t - e.desde) / Math.max(e.hasta - e.desde, 1e-4);
      const caida = (1 - k) * (1 - k);
      e.luz.intensity = e.base * caida;
    }

    /* --- una sola subida parcial a GPU por pool --- */
    for (let i = 0; i < this.pools.length; i++) this.pools[i].subir(t);
  }

  _actualizarEmisores(dt) {
    const rng = this.rng;
    const d = DP;
    for (const [obj, em] of this.emisores) {
      if (!obj.parent) { this.emisores.delete(obj); continue; }
      const m = obj.matrixWorld.elements;
      const x = m[12], y = m[13], z = m[14];
      const peso = this._peso(x, z);
      if (peso <= 0) continue;
      em.acum += dt * (2.5 + em.intensidad * 7) * peso;
      let brotes = Math.floor(em.acum);
      if (brotes <= 0) continue;
      em.acum -= brotes;
      if (brotes > 4) brotes = 4;
      const alto = em.alto;
      for (let i = 0; i < brotes; i++) {
        d.x = x + rng.gauss(0, 0.45);
        d.y = y + alto + rng.float(0, 0.6);
        d.z = z + rng.gauss(0, 0.45);
        d.vx = rng.gauss(0, 0.35); d.vy = rng.float(0.9, 2.3); d.vz = rng.gauss(0, 0.35);
        d.vida = rng.float(2.2, 4.2);
        d.tam0 = rng.float(0.28, 0.55); d.tam1 = d.tam0 * rng.float(2.8, 4.6);
        const gris = clamp(0.78 - em.intensidad * 0.32, 0.13, 0.95) * rng.float(0.85, 1.15);
        d.r = gris * 1.05; d.g = gris; d.b = gris * 0.95;
        d.grav = -0.65; d.arrastre = 1.0; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-0.7, 0.7);
        d.modo = MODO.LIBRE; d.op = clamp(0.25 + em.intensidad * 0.3, 0.2, 0.7); d.turb = 0.85; d.sem = rng.r();
        this.pHumo.emitir(d, this.tiempo);
      }
      // brasas cuando el daño es fuerte
      if (em.intensidad > 0.9 && rng.bool(0.25 * peso)) {
        d.x = x + rng.gauss(0, 0.4); d.y = y + alto * 0.6; d.z = z + rng.gauss(0, 0.4);
        d.vx = rng.gauss(0, 0.3); d.vy = rng.float(1.2, 2.8); d.vz = rng.gauss(0, 0.3);
        d.vida = rng.float(0.5, 1.1);
        d.tam0 = rng.float(0.16, 0.34); d.tam1 = d.tam0 * 1.6;
        d.r = 1.0; d.g = 0.55; d.b = 0.24;
        d.grav = -1.4; d.arrastre = 1.4; d.rot = rng.float(0, 6.283); d.vrot = rng.float(-1, 1);
        d.modo = MODO.BRASA; d.op = 0.9; d.turb = 0.5; d.sem = rng.r();
        this.pFuego.emitir(d, this.tiempo);
        d.modo = MODO.LIBRE;
      }
    }
  }

  /** Limpieza (no se usa en juego, pero deja el módulo cerrado). */
  liberar() {
    for (const baja of this._bajas) { try { baja?.(); } catch (e) { /* ignorar */ } }
    this._bajas.length = 0;
    for (const p of this.pools) {
      this.raiz.remove(p.malla);
      p.geo.dispose();
      p.material.dispose();
    }
    for (const e of this.luces) this.ctx?.escena?.remove?.(e.luz);
    this.ctx?.escena?.remove?.(this.raiz);
    this.emisores.clear();
  }
}

/* Auxiliares de módulo (no se asignan por frame). */
const TMP3 = [0.6, 0.52, 0.36];
const COLOR_AUX = new THREE.Color();

export default Efectos;
