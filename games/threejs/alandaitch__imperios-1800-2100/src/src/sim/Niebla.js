/**
 * NIEBLA DE GUERRA — visión activa, memoria del terreno y bruma.
 *
 * Modelo (por jugador):
 *   Una grilla de 256×256 celdas de 2 m (Uint8Array, un byte por celda):
 *     bit 0 (1) = explorado  · bit 1 (2) = visible ahora
 *
 * Simulación (20 Hz, `fijo`):
 *   1. Se borra la visión activa del tick anterior repasando EXACTAMENTE los mismos
 *      discos que se pintaron (nada de barrer 65k celdas ni de bounding boxes que
 *      se agrandan cuando un explorador se va al otro lado del mapa).
 *   2. Se repinta un disco por entidad usando un stencil precalculado por radio
 *      entero: una fila = un rango contiguo, sin sqrt por celda.
 *   3. El radio se corrige por altura (mirar desde una loma ve más lejos) y por
 *      bosque denso (ve menos). Ambos factores salen de mapas auxiliares que se
 *      muestrean una sola vez al arrancar.
 *
 * Render:
 *   La textura RG (R = explorado, G = visible, suavizadas en el tiempo) sube al GPU
 *   cada 3 ticks. Se dibuja como una capa que calca el relieve del terreno, con
 *   mezcla normal hacia un gris azulado muy oscuro: lo no explorado queda negro
 *   absoluto y lo explorado-sin-visión queda oscurecido, desaturado y sin contraste.
 *   Los bordes se rompen con dos capas de ruido que se arrastran despacio, así la
 *   niebla se ve como bruma y no como una escalera de píxeles.
 *
 * Además expone `pase`: un pase de post-proceso equivalente que sólo se activa si
 * el composer tiene textura de profundidad (hoy no la tiene, así que devuelve null
 * y manda la capa sobre el terreno, que es lo robusto).
 *
 * API pública:
 *   visible(jugador, x, z) · explorado(jugador, x, z)
 *   revelarTodo(jugador) · ocultarTodo(jugador) · revelar(jugador, x, z, radio)
 *   recuerdos(jugador) -> [{ id, clave, defId, jugador, x, y, z, rot, visto }]
 *   mascara(jugador) -> Uint8Array   (la lee el minimapa)
 *   textura -> THREE.DataTexture · activa (get/set, modo espectador)
 */
import * as THREE from 'three';
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';
import { ORDEN } from '../core/Ctx.js';
import { TIPO } from '../core/World.js';
import { bus as busGlobal } from '../core/EventBus.js';
import { UNIDADES } from '../data/unidades.js';
import { EDIFICIOS } from '../data/edificios.js';

const N = 256;                 // lado de la grilla de niebla
const MAX_JUG = 8;
const BIT_EXPLORADO = 1;
const BIT_VISIBLE = 2;
const SEG_MALLA = 128;         // subdivisiones de la capa de bruma
const TICKS_SUBIDA = 3;        // cada cuántos ticks se sube la textura
const TICKS_RECUERDOS = 4;     // cada cuántos ticks se refrescan los fantasmas
const LADO_RUIDO = 64;         // textura de ruido (tileable) para romper bordes
const VACIO = [];

/* ------------------------------------------------------------------ *
 *  Shaders de la capa de bruma
 * ------------------------------------------------------------------ */

const VS_BRUMA = /* glsl */`
  varying vec2 vXZ;
  void main() {
    vXZ = position.xz;                     // la malla vive en identidad: xz = mundo
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
`;

const FS_BRUMA = /* glsl */`
  uniform sampler2D tNiebla;
  uniform sampler2D tRuido;
  uniform vec2  uTexel;
  uniform float uTam;
  uniform float uTiempo;
  uniform float uVelo;        // opacidad del velo sobre lo explorado
  uniform vec3  uColorVelo;
  uniform vec3  uColorBorde;
  varying vec2 vXZ;

  void main() {
    vec2 uv = vXZ / uTam + 0.5;

    // Dos capas de ruido arrastrándose: deforman la consulta a la grilla para que
    // el borde de la niebla ondule en vez de mostrar el escalón de la celda.
    vec3 r1 = texture2D(tRuido, vXZ * 0.0075 + vec2( uTiempo * 0.0038, -uTiempo * 0.0024)).rgb;
    vec3 r2 = texture2D(tRuido, vXZ * 0.0210 + vec2(-uTiempo * 0.0071,  uTiempo * 0.0052)).rgb;
    vec2 despl = ((r1.rg - 0.5) * 3.1 + (r2.rg - 0.5) * 1.3) / uTam;
    vec2 uvw = uv + despl;

    // Tres muestras cruzadas: el filtro lineal ya suaviza, esto redondea la esquina.
    vec2 m  = texture2D(tNiebla, uvw).rg * 0.5;
    m      += texture2D(tNiebla, uvw + uTexel * 0.85).rg * 0.25;
    m      += texture2D(tNiebla, uvw - uTexel * 0.85).rg * 0.25;

    float grano = r1.b * 0.6 + r2.b * 0.4;
    float explorado = m.r + (grano - 0.5) * 0.15;
    float visto     = m.g + (grano - 0.5) * 0.21;

    float oculto = 1.0 - smoothstep(0.17, 0.64, explorado);
    float velo   = (1.0 - smoothstep(0.21, 0.70, visto)) * (1.0 - oculto);

    float alfa = oculto + velo * uVelo * (0.86 + 0.30 * grano);
    if (alfa <= 0.004) discard;

    // Negro absoluto en lo no explorado; velo frío en lo recordado.
    vec3 col = mix(uColorVelo, vec3(0.0), oculto);
    // Filo apenas más claro donde la bruma se abre: da sensación de vapor.
    float filo = velo * (1.0 - velo) * 4.0;
    col += uColorBorde * filo * 0.35;

    gl_FragColor = vec4(col, min(alfa, 1.0));
  }
`;

/** Pase de post-proceso equivalente (necesita profundidad; ver getter `pase`). */
const SHADER_PASE = {
  uniforms: {
    tDiffuse: { value: null },
    tProfundidad: { value: null },
    tNiebla: { value: null },
    tRuido: { value: null },
    uInvVP: { value: new THREE.Matrix4() },
    uTam: { value: 512 },
    uTexel: { value: new THREE.Vector2(1 / N, 1 / N) },
    uTiempo: { value: 0 },
    uVelo: { value: 0.6 },
    uColorVelo: { value: new THREE.Color(0.055, 0.062, 0.082) },
  },
  vertexShader: /* glsl */`
    varying vec2 vUv;
    void main(){ vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }
  `,
  fragmentShader: /* glsl */`
    uniform sampler2D tDiffuse, tProfundidad, tNiebla, tRuido;
    uniform mat4 uInvVP;
    uniform vec2 uTexel;
    uniform float uTam, uTiempo, uVelo;
    uniform vec3 uColorVelo;
    varying vec2 vUv;
    void main(){
      vec3 escena = texture2D(tDiffuse, vUv).rgb;
      float d = texture2D(tProfundidad, vUv).x;
      if (d >= 1.0) { gl_FragColor = vec4(escena, 1.0); return; }
      vec4 clip = vec4(vUv * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
      vec4 p = uInvVP * clip; p /= p.w;
      vec2 uv = p.xz / uTam + 0.5;
      vec3 r1 = texture2D(tRuido, p.xz * 0.0075 + vec2( uTiempo * 0.0038, -uTiempo * 0.0024)).rgb;
      vec3 r2 = texture2D(tRuido, p.xz * 0.0210 + vec2(-uTiempo * 0.0071,  uTiempo * 0.0052)).rgb;
      uv += ((r1.rg - 0.5) * 3.1 + (r2.rg - 0.5) * 1.3) / uTam;
      vec2 m = texture2D(tNiebla, uv).rg;
      float grano = r1.b * 0.6 + r2.b * 0.4;
      float oculto = 1.0 - smoothstep(0.17, 0.64, m.r + (grano - 0.5) * 0.15);
      float velo   = (1.0 - smoothstep(0.21, 0.70, m.g + (grano - 0.5) * 0.21)) * (1.0 - oculto);
      float alfa = oculto + velo * uVelo * (0.86 + 0.30 * grano);
      vec3 col = mix(uColorVelo, vec3(0.0), oculto);
      gl_FragColor = vec4(mix(escena, col, clamp(alfa, 0.0, 1.0)), 1.0);
    }
  `,
};

/* ------------------------------------------------------------------ */

export class Niebla {
  constructor(ctx) {
    this.ctx = ctx;
    this.nombre = 'niebla';
    this.orden = ORDEN.NIEBLA;

    this.N = N;
    this.tam = ctx?.mapa?.tam ?? ctx?.terreno?.tam ?? 512;
    this.medio = this.tam * 0.5;
    this.metrosPorCelda = this.tam / N;
    this.C = N >> 1;                       // mapas auxiliares de terreno (128×128)

    this._activa = true;
    this.tickN = 0;
    this._tiempo = 0;
    this._primeraSubida = true;
    this._sinFogonazo = 0;                 // margen para apagar la capa en modo espía

    /* ---- estado de simulación ---- */
    this.mascaras = new Array(MAX_JUG).fill(null);   // Uint8Array(N*N) por jugador
    this.revelado = new Uint8Array(MAX_JUG);         // 1 = mapa revelado a mano
    this.discos = new Array(MAX_JUG).fill(null);     // Int16Array [cx,cz,r] del tick previo
    this.capDiscos = new Int32Array(MAX_JUG);
    this.nDiscos = new Int32Array(MAX_JUG);
    this.jugadoresActivos = [];
    this._marcaJugador = new Uint8Array(MAX_JUG);
    this._modsCache = new Array(MAX_JUG).fill(null);
    this._stencils = [];                             // half-widths por radio entero

    /* ---- fantasmas de edificios enemigos ---- */
    this.listasRecuerdos = new Array(MAX_JUG).fill(null);
    this.indicesRecuerdos = new Array(MAX_JUG).fill(null);
    this.versionRecuerdos = 0;

    /* ---- textura RG que consume el shader y el minimapa ---- */
    this.pintura = new Uint8Array(N * N * 2);
    this.textura = new THREE.DataTexture(this.pintura, N, N, THREE.RGFormat, THREE.UnsignedByteType);
    this.textura.magFilter = THREE.LinearFilter;
    this.textura.minFilter = THREE.LinearFilter;
    this.textura.wrapS = THREE.ClampToEdgeWrapping;
    this.textura.wrapT = THREE.ClampToEdgeWrapping;
    this.textura.generateMipmaps = false;
    this.textura.unpackAlignment = 1;
    this.textura.needsUpdate = true;

    /* ---- mapas auxiliares del terreno ---- */
    this.altCelda = new Float32Array(this.C * this.C);
    this.altMedia = new Float32Array(this.C * this.C);
    this.esBosque = new Uint8Array(this.C * this.C);
    this._terrenoListo = false;

    this.malla = null;
    this.material = null;
    this.texturaRuido = null;
    this._pase = undefined;

    this._prepararTerreno();
    this._construirMalla();

    const b = ctx?.bus ?? busGlobal;
    b?.on?.('entidad:muerta', (carga) => this._alMorir(carga));
  }

  /* ================================================================ *
   *  API de consulta
   * ================================================================ */

  /** Índice de celda desde coordenadas de mundo; -1 si cae fuera del mapa. */
  celda(x, z) {
    const cx = Math.floor((x + this.medio) / this.metrosPorCelda);
    const cz = Math.floor((z + this.medio) / this.metrosPorCelda);
    if (cx < 0 || cz < 0 || cx >= N || cz >= N) return -1;
    return cz * N + cx;
  }

  visible(jugador, x, z) {
    if (!this._activa) return true;
    const g = this.mascaras[jugador];
    if (!g) return true;                       // sin datos todavía: no escondemos nada
    const i = this.celda(x, z);
    return i >= 0 && (g[i] & BIT_VISIBLE) !== 0;
  }

  explorado(jugador, x, z) {
    if (!this._activa) return true;
    const g = this.mascaras[jugador];
    if (!g) return true;
    const i = this.celda(x, z);
    return i >= 0 && (g[i] & BIT_EXPLORADO) !== 0;
  }

  /** Grilla cruda para el minimapa: 1 byte por celda (bit0 explorado, bit1 visible). */
  mascara(jugador = this.ctx?.jugadorLocal ?? 0) { return this.mascaras[jugador] ?? null; }

  revelarTodo(jugador = this.ctx?.jugadorLocal ?? 0, soloExplorado = false) {
    const g = this._grilla(jugador);
    g.fill(soloExplorado ? BIT_EXPLORADO : (BIT_EXPLORADO | BIT_VISIBLE));
    this.revelado[jugador] = soloExplorado ? 0 : 1;
    this.nDiscos[jugador] = 0;
  }

  ocultarTodo(jugador = this.ctx?.jugadorLocal ?? 0) {
    const g = this._grilla(jugador);
    g.fill(0);
    this.revelado[jugador] = 0;
    this.nDiscos[jugador] = 0;
    const lista = this.listasRecuerdos[jugador];
    if (lista && lista.length) { lista.length = 0; this.indicesRecuerdos[jugador]?.clear(); this.versionRecuerdos++; }
  }

  /** Revelado puntual (una bengala, un aliado que comparte visión, un radar). */
  revelar(jugador, x, z, radio = 20) {
    const g = this._grilla(jugador);
    const i = this.celda(x, z);
    if (i < 0) return;
    const cx = i % N, cz = (i / N) | 0;
    let r = Math.round(radio / this.metrosPorCelda);
    if (r < 1) r = 1; else if (r > 60) r = 60;
    this._pintar(g, cx, cz, r);
    this._registrarDisco(jugador, cx, cz, r);
  }

  /** Fantasmas de edificios ajenos ya vistos. Lo lee VistaEntidades. */
  recuerdos(jugador = this.ctx?.jugadorLocal ?? 0) { return this.listasRecuerdos[jugador] ?? VACIO; }

  get activa() { return this._activa; }
  set activa(v) {
    const nuevo = !!v;
    if (nuevo === this._activa) return;
    this._activa = nuevo;
    this._sinFogonazo = nuevo ? 0 : 2.5;     // deja que se disuelva antes de apagarla
    if (this.malla) this.malla.visible = true;
  }

  /**
   * Pase de post-proceso opcional. Sólo se materializa si el composer expone una
   * textura de profundidad; si no, devuelve null y la niebla sigue por la capa
   * sobre el terreno (que es la que está activa por defecto).
   */
  get pase() {
    if (this._pase !== undefined) return this._pase;
    this._pase = null;
    try {
      const objetivo = this.ctx?.render?.composer?.renderTarget1;
      const prof = objetivo?.depthTexture;
      if (!prof) return null;
      const p = new ShaderPass(SHADER_PASE);
      p.material.uniforms.tProfundidad.value = prof;
      p.material.uniforms.tNiebla.value = this.textura;
      p.material.uniforms.tRuido.value = this.texturaRuido;
      p.material.uniforms.uTam.value = this.tam;
      this._pase = p;
      if (this.malla) this.malla.visible = false;   // no duplicar la niebla
    } catch (e) {
      console.warn('[niebla] no se pudo armar el pase de post-proceso:', e?.message);
      this._pase = null;
    }
    return this._pase;
  }

  /* ================================================================ *
   *  Simulación
   * ================================================================ */

  fijo(dt, ctx) {
    this.tickN++;
    if (!this._terrenoListo) this._prepararTerreno();

    this._recalcularVision(ctx);
    this._aplicarVisibilidad(ctx);
    if (this.tickN % TICKS_RECUERDOS === 0) this._actualizarRecuerdos(ctx);
    if (this._primeraSubida || this.tickN % TICKS_SUBIDA === 0) this._subirTextura(ctx);
  }

  cada(dtReal, alfa, ctx) {
    this._tiempo += dtReal;
    if (!this.malla) {
      if (!this._terrenoListo) this._prepararTerreno();
      this._construirMalla();
      if (!this.malla) return;
    }
    const u = this.material.uniforms;
    u.uTiempo.value = this._tiempo;

    if (this._sinFogonazo > 0) {
      this._sinFogonazo -= dtReal;
      if (this._sinFogonazo <= 0 && !this._activa) this.malla.visible = false;
    }

    const p = this._pase === undefined ? null : this._pase;
    if (p) {
      const cam = ctx.camara;
      const uu = p.material.uniforms;
      uu.uTiempo.value = this._tiempo;
      uu.uInvVP.value.multiplyMatrices(cam.matrixWorld, cam.projectionMatrixInverse);
    }
  }

  /* ---------------- visión activa ---------------- */

  _recalcularVision(ctx) {
    const w = ctx.mundo;
    if (!w) return;

    // 1) borrar la visión del tick anterior repasando los mismos discos
    for (let j = 0; j < MAX_JUG; j++) {
      const g = this.mascaras[j];
      if (!g) continue;
      if (this.revelado[j]) { this.nDiscos[j] = 0; continue; }
      const d = this.discos[j];
      const n = this.nDiscos[j];
      for (let k = 0, o = 0; k < n; k++, o += 3) this._borrar(g, d[o], d[o + 1], d[o + 2]);
      this.nDiscos[j] = 0;
    }

    // 2) repintar
    this.jugadoresActivos.length = 0;
    this._marcaJugador.fill(0);
    const mods = ctx.eco?.mods;
    for (let j = 0; j < MAX_JUG; j++) this._modsCache[j] = mods ? mods[j] : null;

    const mpc = this.metrosPorCelda, medio = this.medio, C = this.C;
    for (let i = 0, n = w.maxUsado; i < n; i++) {
      if (!w.vivo[i]) continue;
      const t = w.tipo[i];
      if (t !== TIPO.UNIDAD && t !== TIPO.EDIFICIO) continue;
      const j = w.jugador[i];
      if (j >= MAX_JUG) continue;

      if (!this._marcaJugador[j]) { this._marcaJugador[j] = 1; this.jugadoresActivos.push(j); this._grilla(j); }
      if (this.revelado[j]) continue;

      const cx = Math.floor((w.px[i] + medio) / mpc);
      if (cx < 0 || cx >= N) continue;
      const cz = Math.floor((w.pz[i] + medio) / mpc);
      if (cz < 0 || cz >= N) continue;

      const def = t === TIPO.UNIDAD ? UNIDADES[w.defId[i]] : EDIFICIOS[w.defId[i]];
      let v = def?.vision ?? 18;
      const m = this._modsCache[j];
      if (m && m.vision) {
        const extra = t === TIPO.UNIDAD ? m.vision[def?.clase] : m.vision.edificio;
        if (extra) v += extra;
      }

      // altura: ver desde arriba llega más lejos; bosque denso lo achica
      const cc = (cz >> 1) * C + (cx >> 1);
      const suelo = this.altCelda[cc];
      const alto = w.py[i] > suelo ? w.py[i] : suelo;
      let f = 1 + (alto - this.altMedia[cc]) * 0.05;
      if (f < 0.82) f = 0.82; else if (f > 1.7) f = 1.7;
      if (this.esBosque[cc]) f *= 0.72;
      v *= f;

      let r = Math.round(v / mpc);
      if (r < 1) r = 1; else if (r > 60) r = 60;

      this._pintar(this.mascaras[j], cx, cz, r);
      this._registrarDisco(j, cx, cz, r);
    }
  }

  /** Marca explorado + visible en un disco. Una fila = un rango contiguo. */
  _pintar(g, cx, cz, r) {
    const st = this._stencil(r);
    let z0 = cz - r, z1 = cz + r;
    if (z0 < 0) z0 = 0;
    if (z1 > N - 1) z1 = N - 1;
    for (let z = z0; z <= z1; z++) {
      const dz = z - cz;
      const hw = st[dz < 0 ? -dz : dz];
      let x0 = cx - hw, x1 = cx + hw;
      if (x0 < 0) x0 = 0;
      if (x1 > N - 1) x1 = N - 1;
      const base = z * N;
      for (let x = x0; x <= x1; x++) g[base + x] |= (BIT_EXPLORADO | BIT_VISIBLE);
    }
  }

  /** Apaga sólo el bit de visión activa (lo explorado no se olvida nunca). */
  _borrar(g, cx, cz, r) {
    const st = this._stencil(r);
    let z0 = cz - r, z1 = cz + r;
    if (z0 < 0) z0 = 0;
    if (z1 > N - 1) z1 = N - 1;
    for (let z = z0; z <= z1; z++) {
      const dz = z - cz;
      const hw = st[dz < 0 ? -dz : dz];
      let x0 = cx - hw, x1 = cx + hw;
      if (x0 < 0) x0 = 0;
      if (x1 > N - 1) x1 = N - 1;
      const base = z * N;
      for (let x = x0; x <= x1; x++) g[base + x] &= ~BIT_VISIBLE;
    }
  }

  /** Semiancho por fila para un radio entero. Se calcula una vez por radio. */
  _stencil(r) {
    let st = this._stencils[r];
    if (st) return st;
    st = new Int16Array(r + 1);
    const r2 = (r + 0.35) * (r + 0.35);
    for (let dz = 0; dz <= r; dz++) {
      const v = r2 - dz * dz;
      st[dz] = v <= 0 ? 0 : Math.floor(Math.sqrt(v));
    }
    this._stencils[r] = st;
    return st;
  }

  _registrarDisco(j, cx, cz, r) {
    let cap = this.capDiscos[j];
    if (!cap) { cap = 512; this.capDiscos[j] = cap; this.discos[j] = new Int16Array(cap * 3); }
    const n = this.nDiscos[j];
    if (n >= cap) {
      const nuevo = new Int16Array(cap * 6);
      nuevo.set(this.discos[j]);
      this.discos[j] = nuevo;
      this.capDiscos[j] = cap * 2;
    }
    const d = this.discos[j], o = n * 3;
    d[o] = cx; d[o + 1] = cz; d[o + 2] = r;
    this.nDiscos[j] = n + 1;
  }

  _grilla(j) {
    let g = this.mascaras[j];
    if (!g) { g = new Uint8Array(N * N); this.mascaras[j] = g; }
    return g;
  }

  /* ---------------- visibilidad de entidades ---------------- */

  _aplicarVisibilidad(ctx) {
    const w = ctx.mundo;
    const local = ctx.jugadorLocal | 0;
    const g = this.mascaras[local];
    const vis = w.visible;

    if (!this._activa || !g) {
      for (let i = 0, n = w.maxUsado; i < n; i++) if (w.vivo[i]) vis[i] = 1;
      return;
    }

    const mpc = this.metrosPorCelda, medio = this.medio;
    for (let i = 0, n = w.maxUsado; i < n; i++) {
      if (!w.vivo[i]) continue;
      const j = w.jugador[i];
      if (j === local) { vis[i] = 1; continue; }
      const cx = Math.floor((w.px[i] + medio) / mpc);
      const cz = Math.floor((w.pz[i] + medio) / mpc);
      if (cx < 0 || cz < 0 || cx >= N || cz >= N) { vis[i] = 0; continue; }
      const m = g[cz * N + cx];
      const t = w.tipo[i];
      // Los recursos y el decorado del mapa quedan dibujados una vez explorados;
      // todo lo que se mueve o dispara necesita visión activa.
      if (j === 255 && (t === TIPO.RECURSO || t === TIPO.DECORADO)) vis[i] = (m & BIT_EXPLORADO) ? 1 : 0;
      else vis[i] = (m & BIT_VISIBLE) ? 1 : 0;
    }
  }

  /* ---------------- fantasmas de edificios ---------------- */

  _actualizarRecuerdos(ctx) {
    const w = ctx.mundo;
    const activos = this.jugadoresActivos;
    if (!activos.length) return;
    const tiempo = w.tiempo;
    const mpc = this.metrosPorCelda, medio = this.medio;

    // 1) anotar lo que cada jugador ve ahora de los demás
    for (let i = 0, n = w.maxUsado; i < n; i++) {
      if (!w.vivo[i] || w.tipo[i] !== TIPO.EDIFICIO) continue;
      const duenio = w.jugador[i];
      if (duenio >= MAX_JUG) continue;
      const cx = Math.floor((w.px[i] + medio) / mpc);
      const cz = Math.floor((w.pz[i] + medio) / mpc);
      if (cx < 0 || cz < 0 || cx >= N || cz >= N) continue;
      const celda = cz * N + cx;
      for (let k = 0; k < activos.length; k++) {
        const p = activos[k];
        if (p === duenio) continue;
        const g = this.mascaras[p];
        if (!g || !(g[celda] & BIT_VISIBLE)) continue;
        this._anotarRecuerdo(p, i, w, duenio, tiempo);
      }
    }

    // 2) si el jugador está mirando el lugar y ya no hay nada, se borra el fantasma
    for (let k = 0; k < activos.length; k++) {
      const p = activos[k];
      const lista = this.listasRecuerdos[p];
      if (!lista || !lista.length) continue;
      const g = this.mascaras[p];
      for (let m = lista.length - 1; m >= 0; m--) {
        const rec = lista[m];
        const celda = this.celda(rec.x, rec.z);
        if (celda < 0 || !(g[celda] & BIT_VISIBLE)) continue;
        const id = rec.id;
        const sigue = w.vivo[id] && w.tipo[id] === TIPO.EDIFICIO && w.jugador[id] === rec.jugador && w.defId[id] === rec.defId;
        if (!sigue) this._olvidar(p, m);
      }
    }
  }

  _anotarRecuerdo(p, id, w, duenio, tiempo) {
    let idx = this.indicesRecuerdos[p];
    if (!idx) { idx = new Map(); this.indicesRecuerdos[p] = idx; this.listasRecuerdos[p] = []; }
    let rec = idx.get(id);
    if (!rec) {
      const def = EDIFICIOS[w.defId[id]];
      rec = {
        id, defId: w.defId[id], clave: def?.clave ?? 'sede', jugador: duenio,
        x: w.px[id], y: w.py[id], z: w.pz[id], rot: w.rot[id],
        escala: w.escala[id], progreso: w.progreso[id], visto: tiempo,
      };
      idx.set(id, rec);
      this.listasRecuerdos[p].push(rec);
      this.versionRecuerdos++;
      return;
    }
    // refrescar el estado conocido (una obra en construcción cambia de aspecto)
    rec.x = w.px[id]; rec.y = w.py[id]; rec.z = w.pz[id]; rec.rot = w.rot[id];
    rec.progreso = w.progreso[id];
    rec.visto = tiempo;
  }

  _olvidar(p, indice) {
    const lista = this.listasRecuerdos[p];
    const rec = lista[indice];
    lista.splice(indice, 1);
    this.indicesRecuerdos[p]?.delete(rec.id);
    this.versionRecuerdos++;
  }

  /** Si el edificio muere delante de tus ojos, el fantasma se cae en el acto. */
  _alMorir(carga) {
    const id = typeof carga === 'number' ? carga : carga?.id;
    if (id == null) return;
    for (let p = 0; p < MAX_JUG; p++) {
      const idx = this.indicesRecuerdos[p];
      if (!idx) continue;
      const rec = idx.get(id);
      if (!rec) continue;
      if (!this._activa || this.visible(p, rec.x, rec.z)) {
        const lista = this.listasRecuerdos[p];
        const n = lista.indexOf(rec);
        if (n >= 0) this._olvidar(p, n);
      }
    }
  }

  /* ================================================================ *
   *  Textura
   * ================================================================ */

  /**
   * Suaviza la máscara del jugador local hacia la textura RG. La visión entra
   * rápido (respuesta inmediata al mover tropas) y se cierra despacio (la bruma
   * vuelve como vapor, no como un interruptor).
   */
  _subirTextura(ctx) {
    const local = ctx.jugadorLocal | 0;
    const g = this.mascaras[local];
    const p = this.pintura;
    const espia = !this._activa;
    const golpe = this._primeraSubida;
    const total = N * N;

    if (!g && !espia) { this.textura.needsUpdate = true; return; }

    for (let i = 0, k = 0; i < total; i++, k += 2) {
      let tr, tg;
      if (espia) { tr = 255; tg = 255; }
      else {
        const m = g[i];
        if (m === 0 && p[k] === 0 && p[k + 1] === 0) continue;   // atajo: océano de negro
        tr = (m & BIT_EXPLORADO) ? 255 : 0;
        tg = (m & BIT_VISIBLE) ? 255 : 0;
      }
      if (golpe) { p[k] = tr; p[k + 1] = tg; continue; }

      const a = p[k];
      if (a !== tr) {
        const v = a + (tr - a) * 0.55;
        p[k] = v > 250 ? 255 : (v < 5 ? 0 : v);
      }
      const b = p[k + 1];
      if (b !== tg) {
        const v = tg > b ? b + (tg - b) * 0.72 : b + (tg - b) * 0.26;
        p[k + 1] = v > 250 ? 255 : (v < 5 ? 0 : v);
      }
    }

    this._primeraSubida = false;
    this.textura.needsUpdate = true;
    if (this.malla && this._activa) this.malla.visible = true;
  }

  /* ================================================================ *
   *  Terreno auxiliar y malla de bruma
   * ================================================================ */

  /** Muestrea altura y bioma una sola vez: la niebla no vuelve a tocar el terreno. */
  _prepararTerreno() {
    const t = this.ctx?.terreno;
    if (!t || typeof t.altura !== 'function') return;
    const C = this.C, paso = this.tam / C, medio = this.medio;
    const alt = this.altCelda, bosque = this.esBosque;
    const tieneBioma = typeof t.bioma === 'function';

    for (let j = 0; j < C; j++) {
      const z = -medio + (j + 0.5) * paso;
      for (let i = 0; i < C; i++) {
        const x = -medio + (i + 0.5) * paso;
        const k = j * C + i;
        const h = t.altura(x, z);
        alt[k] = Number.isFinite(h) ? h : 0;
        if (tieneBioma) {
          const b = t.bioma(x, z);
          bosque[k] = (b === 'bosque' || b === 'montana') ? 1 : 0;
        }
      }
    }

    // media de altura del entorno (caja separable de ~24 m): sirve para saber si
    // la unidad está parada más alto que lo que la rodea.
    const tmp = new Float32Array(C * C);
    const R = 6;
    for (let j = 0; j < C; j++) {
      const fila = j * C;
      let suma = 0, cuenta = 0;
      for (let i = -R; i <= R; i++) { const a = i < 0 ? 0 : (i >= C ? C - 1 : i); suma += alt[fila + a]; cuenta++; }
      for (let i = 0; i < C; i++) {
        tmp[fila + i] = suma / cuenta;
        const sale = i - R, entra = i + R + 1;
        suma -= alt[fila + (sale < 0 ? 0 : sale)];
        suma += alt[fila + (entra >= C ? C - 1 : entra)];
      }
    }
    const med = this.altMedia;
    for (let i = 0; i < C; i++) {
      let suma = 0, cuenta = 0;
      for (let j = -R; j <= R; j++) { const b = j < 0 ? 0 : (j >= C ? C - 1 : j); suma += tmp[b * C + i]; cuenta++; }
      for (let j = 0; j < C; j++) {
        med[j * C + i] = suma / cuenta;
        const sale = j - R, entra = j + R + 1;
        suma -= tmp[(sale < 0 ? 0 : sale) * C + i];
        suma += tmp[(entra >= C ? C - 1 : entra) * C + i];
      }
    }

    this._terrenoListo = true;
  }

  /** Altura máxima del entorno inmediato: la bruma se apoya sobre las crestas. */
  _altoLocal(x, z) {
    const C = this.C, paso = this.tam / C;
    const ci = Math.floor((x + this.medio) / paso);
    const ck = Math.floor((z + this.medio) / paso);
    let h = -1e9;
    for (let b = ck - 1; b <= ck + 1; b++) {
      if (b < 0 || b >= C) continue;
      const fila = b * C;
      for (let a = ci - 1; a <= ci + 1; a++) {
        if (a < 0 || a >= C) continue;
        const v = this.altCelda[fila + a];
        if (v > h) h = v;
      }
    }
    return h === -1e9 ? 0 : h;
  }

  _construirMalla() {
    if (this.malla || !this._terrenoListo) return;
    const escena = this.ctx?.escena;
    if (!escena) return;

    const seg = SEG_MALLA, lado = seg + 1, paso = this.tam / seg, medio = this.medio;
    const pos = new Float32Array(lado * lado * 3);
    for (let j = 0, v = 0; j < lado; j++) {
      const z = -medio + j * paso;
      for (let i = 0; i < lado; i++, v += 3) {
        const x = -medio + i * paso;
        pos[v] = x;
        pos[v + 1] = this._altoLocal(x, z) + 0.42;   // apenas por encima del suelo
        pos[v + 2] = z;
      }
    }
    const idx = new Uint32Array(seg * seg * 6);
    for (let j = 0, o = 0; j < seg; j++) {
      for (let i = 0; i < seg; i++) {
        const a = j * lado + i, b = a + 1, c = a + lado, d = c + 1;
        idx[o++] = a; idx[o++] = c; idx[o++] = b;
        idx[o++] = b; idx[o++] = c; idx[o++] = d;
      }
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setIndex(new THREE.BufferAttribute(idx, 1));
    geo.computeBoundingSphere();

    this.texturaRuido = this._crearRuido();
    this.material = new THREE.ShaderMaterial({
      uniforms: {
        tNiebla: { value: this.textura },
        tRuido: { value: this.texturaRuido },
        uTexel: { value: new THREE.Vector2(1 / N, 1 / N) },
        uTam: { value: this.tam },
        uTiempo: { value: 0 },
        uVelo: { value: 0.6 },
        uColorVelo: { value: new THREE.Color(0.055, 0.062, 0.082) },
        uColorBorde: { value: new THREE.Color(0.17, 0.21, 0.27) },
      },
      vertexShader: VS_BRUMA,
      fragmentShader: FS_BRUMA,
      transparent: true,
      depthWrite: false,
      depthTest: true,
      side: THREE.FrontSide,
      polygonOffset: true,
      polygonOffsetFactor: -4,
      polygonOffsetUnits: -8,
      toneMapped: false,
      fog: false,
    });

    const malla = new THREE.Mesh(geo, this.material);
    malla.name = 'niebla';
    malla.frustumCulled = false;
    malla.matrixAutoUpdate = false;
    malla.updateMatrix();
    malla.renderOrder = 12;
    malla.castShadow = false;
    malla.receiveShadow = false;
    malla.raycast = () => {};                 // jamás intercepta un click
    malla.userData.noSeleccionable = true;
    malla.visible = false;                    // se enciende con la primera subida

    // Los prepasos con overrideMaterial (GTAO/normales) no deben ver la bruma:
    // si escribiera profundidad ahí se comería el AO de contacto de las unidades.
    malla.onBeforeRender = (renderer, escenaR, camara, geometria, material) => {
      if (material !== this.material) geometria.setDrawRange(0, 0);
    };
    malla.onAfterRender = (renderer, escenaR, camara, geometria) => {
      if (geometria.drawRange.count === 0) geometria.setDrawRange(0, Infinity);
    };

    escena.add(malla);
    this.malla = malla;
  }

  /** Ruido tileable determinista (ctx.ruido) para romper el borde de la bruma. */
  _crearRuido() {
    const S = LADO_RUIDO;
    const datos = new Uint8Array(S * S * 4);
    const ru = this.ctx?.ruido;
    const esc = 3.0 / S;
    // Tres campos independientes (R y G desplazan, B da el grano de vapor) mezclados
    // en el toro con cuatro copias corridas: así la textura calza consigo misma.
    const desp = [0, 41.7, 93.1];
    for (let c = 0; c < 3; c++) {
      const sy = desp[c];
      for (let y = 0; y < S; y++) {
        const wy = y / S;
        for (let x = 0; x < S; x++) {
          const wx = x / S;
          let v = 0;
          if (ru) {
            const n00 = ru.fbm(x * esc, y * esc + sy, 2, 2.0, 0.5);
            const n10 = ru.fbm((x - S) * esc, y * esc + sy, 2, 2.0, 0.5);
            const n01 = ru.fbm(x * esc, (y - S) * esc + sy, 2, 2.0, 0.5);
            const n11 = ru.fbm((x - S) * esc, (y - S) * esc + sy, 2, 2.0, 0.5);
            v = n00 * (1 - wx) * (1 - wy) + n10 * wx * (1 - wy) + n01 * (1 - wx) * wy + n11 * wx * wy;
          }
          const b = Math.round((v * 0.7 + 0.5) * 255);
          datos[(y * S + x) * 4 + c] = b < 0 ? 0 : (b > 255 ? 255 : b);
        }
      }
    }
    for (let i = 3; i < datos.length; i += 4) datos[i] = 255;
    const tex = new THREE.DataTexture(datos, S, S, THREE.RGBAFormat, THREE.UnsignedByteType);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.magFilter = THREE.LinearFilter;
    tex.minFilter = THREE.LinearFilter;
    tex.generateMipmaps = false;
    tex.needsUpdate = true;
    return tex;
  }

  liberar() {
    if (this.malla) {
      this.malla.geometry.dispose();
      this.material.dispose();
      this.malla.parent?.remove(this.malla);
      this.malla = null;
    }
    this.textura.dispose();
    this.texturaRuido?.dispose();
  }
}
