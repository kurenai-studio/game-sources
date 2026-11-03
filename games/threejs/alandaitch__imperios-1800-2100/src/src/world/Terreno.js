/**
 * Terreno: malla, consultas de suelo y pintura dinámica.
 *
 * Geometría: 16×16 chunks de 32×32 quads (1 m por quad) con 3 niveles de LOD
 * pregenerados. Cada chunk es una malla propia para que el frustum culling de
 * Three.js descarte lo que queda fuera de cámara; las normales SIEMPRE se sacan
 * de la rejilla fina, así el LOD no produce saltos de iluminación al conmutar.
 * Un faldón vertical por chunk tapa las grietas entre niveles distintos.
 *
 * Datos: dos DataTexture alimentan el shader.
 *   texDatos  (RGBA) R=AO horneada · G=verdor · B=aridez · A=variación macro
 *   texMezcla (RGBA) R=camino · G=quemadura · B=cráter        <- pintarDecal()
 *
 * La AO se hornea por muestreo de horizonte en 8 direcciones sobre el heightmap.
 * Es lo que da sensación de volumen en los valles cuando el sol pega de frente.
 */
import * as THREE from 'three';
import { clamp, lerp, smoothstep } from '../core/RNG.js';
import { construirMaterialTerreno } from './TerrenoShader.js';

const BIOMAS = ['pradera', 'bosque', 'montana', 'desierto', 'playa', 'agua'];

/** Direcciones del muestreo de horizonte (8 rayos) y sus distancias en metros. */
const DIR_AO = (() => {
  const d = new Float32Array(16);
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * Math.PI * 2;
    d[i * 2] = Math.cos(a); d[i * 2 + 1] = Math.sin(a);
  }
  return d;
})();
const DIST_AO = [1.5, 3.0, 6.0, 11.0, 18.0, 27.0];

const sinAcentos = (s) => String(s).toLowerCase()
  .replace(/á/g, 'a').replace(/é/g, 'e').replace(/í/g, 'i').replace(/ó/g, 'o').replace(/ú/g, 'u').replace(/ñ/g, 'n');

export class Terreno {
  constructor(ctx) {
    this.nombre = 'terreno';
    this.orden = 99;
    this.ctx = ctx;
    this.ruido = ctx.ruido;

    const mapa = this._prepararMapa(ctx);
    this.mapa = mapa;
    this.tam = mapa.tam;
    this.res = mapa.res;
    this.alturas = mapa.alturas;
    this.biomas = mapa.biomas;
    this.humedadMapa = mapa.humedad;
    this.nivelAgua = mapa.nivelAgua ?? 0;
    this.escalaCelda = this.tam / (this.res - 1);
    this.medioTam = this.tam * 0.5;

    let min = Infinity, max = -Infinity;
    for (let i = 0; i < this.alturas.length; i++) {
      const h = this.alturas[i];
      if (h < min) min = h;
      if (h > max) max = h;
    }
    this.altMin = min; this.altMax = max;
    this.altNieve = Math.max(14, Math.min(max * 0.72, 21));

    this._resolverBiomas();
    this._crearTexturasDatos();
    this._hornearBiomas();
    this._calcularAO(0, 0, this.tamAO, this.tamAO);
    this._volcarDatos(0, 0, this.tamDatos, this.tamDatos);

    this._crearMaterial();
    this._construirChunks();
    this._construirFalda();

    this._posLOD = new THREE.Vector3(1e9, 1e9, 1e9);
    this._actualizarLOD(ctx.camara?.position ?? new THREE.Vector3(0, 80, 0));

    ctx.escena.add(this.malla);
  }

  /* ================================================================ *
   *  Mapa de entrada (o respaldo si el generador todavía no corrió)
   * ================================================================ */

  _prepararMapa(ctx) {
    const m = ctx.mapa;
    const ok = m && m.alturas && m.res && m.alturas.length >= m.res * m.res;
    if (ok) return m;
    const respaldo = this._generarMapaRespaldo(ctx);
    if (!m) ctx.mapa = respaldo;   // que main.js no reviente leyendo inicios[]
    return respaldo;
  }

  /** Isla con cordillera al noreste. Sólo se usa si ctx.mapa no existe todavía. */
  _generarMapaRespaldo(ctx) {
    const tam = 512, res = 513;
    const alturas = new Float32Array(res * res);
    const biomas = new Uint8Array(res * res);
    const humedad = new Float32Array(res * res);
    const ruido = ctx.ruido;
    const paso = tam / (res - 1);

    for (let f = 0; f < res; f++) {
      const z = -tam * 0.5 + f * paso;
      for (let c = 0; c < res; c++) {
        const x = -tam * 0.5 + c * paso;
        const i = f * res + c;
        const colinas = ruido.fbm(x * 0.0026, z * 0.0026, 5) * 4.2;
        const cresta = Math.max(0, ruido.ridged(x * 0.0016 + 31, z * 0.0016 - 17, 4));
        const mascara = smoothstep(0.15, 0.75, ruido.fbm(x * 0.0011 - 8, z * 0.0011 + 5, 3) * 0.5 + 0.5);
        const r = Math.hypot(x, z) / (tam * 0.5);
        const isla = 1 - smoothstep(0.66, 1.02, r);
        const h = (2.6 + colinas + cresta * cresta * 24 * mascara) * isla - 6 * (1 - isla);
        alturas[i] = h;
        const hum = clamp(ruido.fbm(x * 0.0032 + 77, z * 0.0032 - 41, 4) * 0.5 + 0.55, 0, 1);
        humedad[i] = hum;
        biomas[i] = h < 0 ? 5 : h < 0.9 ? 4 : h > 13 ? 2 : hum > 0.62 ? 1 : hum < 0.34 ? 3 : 0;
      }
    }
    return {
      semilla: ctx.semilla ?? 1337, tam, res, alturas, biomas, humedad,
      nivelAgua: 0, inicios: [{ x: -80, z: -80 }, { x: 80, z: 80 }], nodos: [],
      nombresBioma: BIOMAS,
    };
  }

  /**
   * El generador de mapa es otro módulo: puede exponer los nombres de bioma o no.
   * Si no los expone, se deducen por semántica (qué índice cae bajo agua, cuál
   * está más alto, cuál más húmedo) en vez de asumir un orden que puede cambiar.
   */
  _resolverBiomas() {
    const m = this.mapa;
    if (typeof m.bioma === 'function') {
      this._biomaDelegado = (x, z) => sinAcentos(m.bioma(x, z));
    }
    const dado = m.nombresBioma || m.BIOMAS || m.clavesBioma || m.biomasNombres;
    if (Array.isArray(dado) && dado.length) {
      this.nombresBioma = dado.map((n) => {
        const s = sinAcentos(n);
        return BIOMAS.includes(s) ? s : 'pradera';
      });
      return;
    }
    if (!this.biomas) { this.nombresBioma = BIOMAS.slice(); return; }

    const n = 8;
    const cuenta = new Float64Array(n), sumaAlt = new Float64Array(n);
    const sumaHum = new Float64Array(n), bajoAgua = new Float64Array(n), enOrilla = new Float64Array(n);
    const total = this.res * this.res;
    for (let i = 0; i < total; i++) {
      const b = this.biomas[i] & 7, h = this.alturas[i];
      cuenta[b]++; sumaAlt[b] += h;
      sumaHum[b] += this.humedadMapa ? this.humedadMapa[i] : 0.5;
      if (h < this.nivelAgua - 0.2) bajoAgua[b]++;
      else if (h < this.nivelAgua + 1.6) enOrilla[b]++;
    }
    const nombres = new Array(n).fill(null);
    const libres = [];
    for (let i = 0; i < n; i++) if (cuenta[i] > 0) libres.push(i);

    const elegir = (puntaje, nombre) => {
      let mejor = -1, mejorV = -Infinity;
      for (const i of libres) {
        if (nombres[i]) continue;
        const v = puntaje(i);
        if (v > mejorV) { mejorV = v; mejor = i; }
      }
      if (mejor >= 0 && mejorV > 0) nombres[mejor] = nombre;
    };
    elegir((i) => bajoAgua[i] / cuenta[i] - 0.5, 'agua');
    elegir((i) => sumaAlt[i] / cuenta[i] - this.altMax * 0.35, 'montana');
    elegir((i) => enOrilla[i] / cuenta[i] - 0.35, 'playa');
    elegir((i) => sumaHum[i] / cuenta[i] - 0.58, 'bosque');
    elegir((i) => 0.42 - sumaHum[i] / cuenta[i], 'desierto');
    for (let i = 0; i < n; i++) if (!nombres[i]) nombres[i] = 'pradera';
    this.nombresBioma = nombres;
  }

  /* ================================================================ *
   *  Consultas de suelo
   * ================================================================ */

  _alturaRejilla(col, fila) {
    const r = this.res;
    const c = col < 0 ? 0 : col >= r ? r - 1 : col;
    const f = fila < 0 ? 0 : fila >= r ? r - 1 : fila;
    return this.alturas[f * r + c];
  }

  /** Bilineal sobre el heightmap. Fuera del mapa devuelve el borde (soporta la falda). */
  altura(x, z) {
    const r = this.res, e = this.escalaCelda;
    let fx = (x + this.medioTam) / e;
    let fz = (z + this.medioTam) / e;
    fx = fx < 0 ? 0 : fx > r - 1.0001 ? r - 1.0001 : fx;
    fz = fz < 0 ? 0 : fz > r - 1.0001 ? r - 1.0001 : fz;
    const c0 = fx | 0, f0 = fz | 0;
    const tx = fx - c0, tz = fz - f0;
    const i = f0 * r + c0;
    const h00 = this.alturas[i], h10 = this.alturas[i + 1];
    const h01 = this.alturas[i + r], h11 = this.alturas[i + r + 1];
    const a = h00 + (h10 - h00) * tx;
    const b = h01 + (h11 - h01) * tx;
    return a + (b - a) * tz;
  }

  /** Gradiente del suelo por diferencias centradas de medio metro. */
  _gradiente(x, z, salida) {
    const d = Math.max(0.5, this.escalaCelda * 0.5);
    const gx = (this.altura(x + d, z) - this.altura(x - d, z)) / (2 * d);
    const gz = (this.altura(x, z + d) - this.altura(x, z - d)) / (2 * d);
    salida[0] = gx; salida[1] = gz;
    return salida;
  }

  normal(x, z, salida) {
    const g = this._gradiente(x, z, this._grad || (this._grad = new Float64Array(2)));
    const v = salida || new THREE.Vector3();
    return v.set(-g[0], 1, -g[1]).normalize();
  }

  /** 0 = llano, 1 = pared vertical (seno del ángulo con la horizontal). */
  pendiente(x, z) {
    const g = this._gradiente(x, z, this._grad || (this._grad = new Float64Array(2)));
    const m = Math.hypot(g[0], g[1]);
    return m / Math.sqrt(1 + m * m);
  }

  bioma(x, z) {
    if (this.altura(x, z) < this.nivelAgua) return 'agua';
    if (this._biomaDelegado) return this._biomaDelegado(x, z);
    if (!this.biomas) return 'pradera';
    const r = this.res, e = this.escalaCelda;
    const c = clamp(Math.round((x + this.medioTam) / e), 0, r - 1);
    const f = clamp(Math.round((z + this.medioTam) / e), 0, r - 1);
    return this.nombresBioma[this.biomas[f * r + c] & 7] || 'pradera';
  }

  transitable(x, z) {
    const l = this.medioTam - 2;
    if (x < -l || x > l || z < -l || z > l) return false;
    if (this.altura(x, z) < this.nivelAgua + 0.25) return false;
    return this.pendiente(x, z) < 0.58;
  }

  /**
   * Marcha sobre el rayo contra el heightmap. Nada de raycast de malla: con 256
   * chunks eso serían cientos de miles de triángulos por click.
   */
  intersectar(raycaster) {
    const rayo = raycaster?.ray || raycaster;
    if (!rayo) return null;
    const o = rayo.origin, d = rayo.direction;
    const limite = this.medioTam + this.anchoFalda;

    let t = 0;
    const techo = this.altMax + 4;
    if (o.y > techo) {
      if (d.y >= -1e-5) return null;          // mira hacia arriba desde arriba de todo
      t = (techo - o.y) / d.y;
    }
    // recorte contra la caja del mapa en XZ para no marchar al infinito
    let tSalida = 4000;
    for (let eje = 0; eje < 2; eje++) {
      const po = eje === 0 ? o.x : o.z, pd = eje === 0 ? d.x : d.z;
      if (Math.abs(pd) < 1e-6) {
        if (po < -limite || po > limite) return null;
        continue;
      }
      const t1 = (-limite - po) / pd, t2 = (limite - po) / pd;
      const tmin = Math.min(t1, t2), tmax = Math.max(t1, t2);
      if (tmax < t) return null;
      t = Math.max(t, tmin);
      tSalida = Math.min(tSalida, tmax);
    }
    if (t > tSalida) return null;

    let tPrev = t;
    let dPrev = o.y + d.y * t - this.altura(o.x + d.x * t, o.z + d.z * t);
    if (dPrev <= 0) dPrev = 0.001;

    while (t < tSalida) {
      const paso = Math.min(8, Math.max(0.6, dPrev * 0.55));
      const tn = t + paso;
      const x = o.x + d.x * tn, y = o.y + d.y * tn, z = o.z + d.z * tn;
      const dif = y - this.altura(x, z);
      if (dif <= 0) {
        // bisección entre el último punto por encima y este por debajo
        let a = t, b = tn;
        for (let k = 0; k < 14; k++) {
          const mm = (a + b) * 0.5;
          const hm = o.y + d.y * mm - this.altura(o.x + d.x * mm, o.z + d.z * mm);
          if (hm > 0) a = mm; else b = mm;
        }
        const tf = (a + b) * 0.5;
        return { x: o.x + d.x * tf, y: o.y + d.y * tf, z: o.z + d.z * tf };
      }
      t = tn; dPrev = dif;
    }
    return null;
  }

  /* ================================================================ *
   *  Texturas de datos y de mezcla
   * ================================================================ */

  _crearTexturasDatos() {
    this.tamDatos = Math.min(512, this.res - 1);
    this.tamAO = this.tamDatos >> 1;
    this.ao = new Float32Array(this.tamAO * this.tamAO);
    this.verdor = new Float32Array(this.tamDatos * this.tamDatos);
    this.aridez = new Float32Array(this.tamDatos * this.tamDatos);
    this.macro = new Float32Array(this.tamDatos * this.tamDatos);

    const n = this.tamDatos * this.tamDatos * 4;
    this.datosPix = new Uint8Array(n);
    this.texDatos = new THREE.DataTexture(this.datosPix, this.tamDatos, this.tamDatos, THREE.RGBAFormat);
    this.texDatos.magFilter = THREE.LinearFilter;
    this.texDatos.minFilter = THREE.LinearFilter;
    this.texDatos.wrapS = this.texDatos.wrapT = THREE.ClampToEdgeWrapping;
    this.texDatos.colorSpace = THREE.NoColorSpace;
    this.texDatos.needsUpdate = true;

    this.tamMezcla = 512;
    this.mezclaPix = new Uint8Array(this.tamMezcla * this.tamMezcla * 4);
    this.texMezcla = new THREE.DataTexture(this.mezclaPix, this.tamMezcla, this.tamMezcla, THREE.RGBAFormat);
    this.texMezcla.magFilter = THREE.LinearFilter;
    this.texMezcla.minFilter = THREE.LinearFilter;
    this.texMezcla.wrapS = this.texMezcla.wrapT = THREE.ClampToEdgeWrapping;
    this.texMezcla.colorSpace = THREE.NoColorSpace;
    this.texMezcla.needsUpdate = true;
    this._mezclaSucia = false;
  }

  /** Coordenada de mundo del centro del texel de datos. */
  _mundoDeDato(j) { return (j + 0.5) * (this.tam / this.tamDatos) - this.medioTam; }
  _mundoDeAO(j) { return (j + 0.5) * (this.tam / this.tamAO) - this.medioTam; }

  _hornearBiomas() {
    const T = this.tamDatos;
    const crudoV = new Float32Array(T * T), crudoA = new Float32Array(T * T);
    const r = this.res, e = this.escalaCelda;

    for (let y = 0; y < T; y++) {
      const wz = this._mundoDeDato(y);
      const fila = clamp(Math.round((wz + this.medioTam) / e), 0, r - 1);
      for (let x = 0; x < T; x++) {
        const wx = this._mundoDeDato(x);
        const col = clamp(Math.round((wx + this.medioTam) / e), 0, r - 1);
        const i = fila * r + col;
        const nombre = this.biomas ? (this.nombresBioma[this.biomas[i] & 7] || 'pradera') : 'pradera';
        const hum = this.humedadMapa ? this.humedadMapa[i] : 0.5;
        let verdor = 0.5, aridez = 0.05;
        switch (nombre) {
          case 'bosque': verdor = 0.72 + hum * 0.28; aridez = 0.0; break;
          case 'pradera': verdor = 0.44 + hum * 0.50; aridez = 0.05; break;
          case 'desierto': verdor = hum * 0.22; aridez = 0.92; break;
          case 'montana': verdor = 0.12 + hum * 0.38; aridez = 0.14; break;
          case 'playa': verdor = hum * 0.30; aridez = 0.55; break;
          default: verdor = hum * 0.3; aridez = 0.25; break;   // agua
        }
        // el ruido entra ANTES del desenfoque: así el borde de bioma queda dentado
        const n = this.ruido.fbm(wx * 0.018, wz * 0.018, 3) * 0.22;
        crudoV[y * T + x] = clamp(verdor + n, 0, 1);
        crudoA[y * T + x] = clamp(aridez + n * 0.8, 0, 1);
        this.macro[y * T + x] = clamp(this.ruido.fbm(wx * 0.0055 + 12, wz * 0.0055 - 7, 3) * 0.5 + 0.5, 0, 1);
      }
    }

    // desenfoque separable 5 tap: las fronteras de bioma dejan de ser un escalón
    const tmp = new Float32Array(T * T);
    const desenfocar = (src, dst) => {
      for (let y = 0; y < T; y++) {
        for (let x = 0; x < T; x++) {
          const a = src[y * T + Math.max(0, x - 2)], b = src[y * T + Math.max(0, x - 1)];
          const c = src[y * T + x];
          const d = src[y * T + Math.min(T - 1, x + 1)], f = src[y * T + Math.min(T - 1, x + 2)];
          tmp[y * T + x] = (a + b * 2 + c * 3 + d * 2 + f) * 0.111111;
        }
      }
      for (let y = 0; y < T; y++) {
        for (let x = 0; x < T; x++) {
          const a = tmp[Math.max(0, y - 2) * T + x], b = tmp[Math.max(0, y - 1) * T + x];
          const c = tmp[y * T + x];
          const d = tmp[Math.min(T - 1, y + 1) * T + x], f = tmp[Math.min(T - 1, y + 2) * T + x];
          dst[y * T + x] = (a + b * 2 + c * 3 + d * 2 + f) * 0.111111;
        }
      }
    };
    desenfocar(crudoV, this.verdor);
    desenfocar(crudoA, this.aridez);
  }

  /** Oclusión por horizonte: 8 rayos × 6 distancias sobre el heightmap. */
  _calcularAO(x0, y0, x1, y1) {
    const A = this.tamAO;
    const cx0 = clamp(x0, 0, A), cy0 = clamp(y0, 0, A);
    const cx1 = clamp(x1, 0, A), cy1 = clamp(y1, 0, A);
    const e = this.escalaCelda, r = this.res;
    for (let y = cy0; y < cy1; y++) {
      const wz = this._mundoDeAO(y);
      const fila = clamp(Math.round((wz + this.medioTam) / e), 0, r - 1);
      for (let x = cx0; x < cx1; x++) {
        const wx = this._mundoDeAO(x);
        const col = clamp(Math.round((wx + this.medioTam) / e), 0, r - 1);
        const h0 = this.alturas[fila * r + col];
        let ocl = 0;
        for (let k = 0; k < 8; k++) {
          const dx = DIR_AO[k * 2], dz = DIR_AO[k * 2 + 1];
          let tanMax = 0;
          for (let s = 0; s < DIST_AO.length; s++) {
            const dist = DIST_AO[s];
            const c = Math.round(col + (dx * dist) / e), f = Math.round(fila + (dz * dist) / e);
            const t = (this._alturaRejilla(c, f) - h0) / dist;
            if (t > tanMax) tanMax = t;
          }
          ocl += tanMax / Math.sqrt(1 + tanMax * tanMax);
        }
        this.ao[y * A + x] = clamp(1 - (ocl / 8) * 1.35, 0.18, 1);
      }
    }
  }

  _volcarDatos(x0, y0, x1, y1) {
    const T = this.tamDatos, A = this.tamAO;
    const cx0 = clamp(x0, 0, T), cy0 = clamp(y0, 0, T);
    const cx1 = clamp(x1, 0, T), cy1 = clamp(y1, 0, T);
    const escala = A / T;
    for (let y = cy0; y < cy1; y++) {
      const fy = clamp(y * escala - 0.5, 0, A - 1.001);
      const ay = fy | 0, ty = fy - ay;
      for (let x = cx0; x < cx1; x++) {
        const fx = clamp(x * escala - 0.5, 0, A - 1.001);
        const ax = fx | 0, tx = fx - ax;
        const i0 = ay * A + ax;
        const a = lerp(this.ao[i0], this.ao[i0 + 1], tx);
        const b = lerp(this.ao[i0 + A], this.ao[i0 + A + 1], tx);
        const i = y * T + x, o = i * 4;
        this.datosPix[o] = lerp(a, b, ty) * 255;
        this.datosPix[o + 1] = this.verdor[i] * 255;
        this.datosPix[o + 2] = this.aridez[i] * 255;
        this.datosPix[o + 3] = this.macro[i] * 255;
      }
    }
    this.texDatos.needsUpdate = true;
  }

  /* ================================================================ *
   *  Material
   * ================================================================ */

  _crearMaterial() {
    const { material, uniformes } = construirMaterialTerreno(this.ctx, {
      tam: this.tam,
      nivelAgua: this.nivelAgua,
      altNieve: this.altNieve,
      datos: this.texDatos,
      mezcla: this.texMezcla,
      tamAtlas: this.ctx.calidad === 'baja' ? 128 : 256,
      fuerzaAO: 0.92,
    });
    this.material = material;
    this.uniformes = uniformes;

    // Sombras.js puede reemplazar onBeforeCompile para meter las cascadas:
    // se encadenan los dos en vez de dejar que uno pise al otro.
    const mio = material.onBeforeCompile;
    const claveMia = material.customProgramCacheKey;
    this.ctx.sombras?.registrarMaterial?.(material);
    if (material.onBeforeCompile !== mio) {
      const suyo = material.onBeforeCompile;
      material.onBeforeCompile = function (shader, renderer) {
        suyo.call(this, shader, renderer);
        mio.call(this, shader, renderer);
      };
    }
    if (material.customProgramCacheKey !== claveMia) {
      const suya = material.customProgramCacheKey;
      material.customProgramCacheKey = function () { return `terreno|${suya.call(this)}`; };
    }
  }

  /* ================================================================ *
   *  Chunks + LOD
   * ================================================================ */

  _construirChunks() {
    const quads = this.res - 1;
    let lado = 16;
    while (lado > 1 && quads % lado !== 0) lado--;
    this.chunksPorLado = lado;
    this.quadsChunk = quads / lado;
    this.niveles = Math.max(1, Math.min(3, 1 + Math.floor(Math.log2(Math.max(1, this.quadsChunk / 8)))));
    this.tamChunk = this.quadsChunk * this.escalaCelda;

    this.chunks = [];
    for (let cz = 0; cz < lado; cz++) {
      for (let cx = 0; cx < lado; cx++) {
        const geos = [];
        for (let n = 0; n < this.niveles; n++) geos.push(this._crearGeometriaChunk(cx, cz, n));
        const malla = new THREE.Mesh(geos[0], this.material);
        malla.position.set(cx * this.tamChunk - this.medioTam, 0, cz * this.tamChunk - this.medioTam);
        malla.receiveShadow = true;
        malla.castShadow = false;
        malla.matrixAutoUpdate = false;
        malla.updateMatrix();
        malla.name = `terreno-chunk-${cx}-${cz}`;
        this.chunks.push({
          cx, cz, geos, malla, nivel: 0,
          centroX: malla.position.x + this.tamChunk * 0.5,
          centroZ: malla.position.z + this.tamChunk * 0.5,
          centroY: 0,
        });
      }
    }
  }

  _crearGeometriaChunk(cx, cz, nivel) {
    const salto = 1 << nivel;
    const q = this.quadsChunk / salto;
    const n = q + 1;
    const nBorde = 4 * q;
    const nVerts = n * n + nBorde;

    const geo = new THREE.BufferGeometry();
    const pos = new Float32Array(nVerts * 3);
    const nor = new Float32Array(nVerts * 3);
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('normal', new THREE.BufferAttribute(nor, 3));

    // índices: rejilla + faldón perimetral (el faldón nunca cambia de topología)
    const idx = new Uint16Array(q * q * 6 + nBorde * 6);
    let p = 0;
    for (let j = 0; j < q; j++) {
      for (let i = 0; i < q; i++) {
        const a = j * n + i, b = a + 1, c = a + n, d = c + 1;
        idx[p++] = a; idx[p++] = c; idx[p++] = b;
        idx[p++] = b; idx[p++] = c; idx[p++] = d;
      }
    }
    const perim = new Int32Array(nBorde);
    let k = 0;
    for (let i = 0; i < q; i++) perim[k++] = i;                    // norte, +X
    for (let j = 0; j < q; j++) perim[k++] = j * n + q;            // este, +Z
    for (let i = q; i > 0; i--) perim[k++] = q * n + i;            // sur, -X
    for (let j = q; j > 0; j--) perim[k++] = j * n;                // oeste, -Z
    for (let s = 0; s < nBorde; s++) {
      const a = perim[s], b = perim[(s + 1) % nBorde];
      const ap = n * n + s, bp = n * n + ((s + 1) % nBorde);
      idx[p++] = a; idx[p++] = b; idx[p++] = bp;
      idx[p++] = a; idx[p++] = bp; idx[p++] = ap;
    }
    geo.setIndex(new THREE.BufferAttribute(idx, 1));

    geo.userData = { cx, cz, nivel, q, n, salto, perim };
    this._rellenarGeometria(geo);
    return geo;
  }

  _rellenarGeometria(geo) {
    const { cx, cz, q, n, salto, perim } = geo.userData;
    const pos = geo.attributes.position.array;
    const nor = geo.attributes.normal.array;
    const e = this.escalaCelda, res = this.res;
    const col0 = cx * this.quadsChunk, fila0 = cz * this.quadsChunk;
    const inv2e = 1 / (2 * e);
    let minY = Infinity, maxY = -Infinity;

    for (let j = 0; j < n; j++) {
      const fila = fila0 + j * salto;
      for (let i = 0; i < n; i++) {
        const col = col0 + i * salto;
        const v = (j * n + i) * 3;
        const h = this.alturas[fila * res + col];
        pos[v] = i * salto * e; pos[v + 1] = h; pos[v + 2] = j * salto * e;
        // normal siempre de la rejilla fina: sin esto, cada LOD ilumina distinto
        const nx = (this._alturaRejilla(col - 1, fila) - this._alturaRejilla(col + 1, fila)) * inv2e;
        const nz = (this._alturaRejilla(col, fila - 1) - this._alturaRejilla(col, fila + 1)) * inv2e;
        const inv = 1 / Math.sqrt(nx * nx + 1 + nz * nz);
        nor[v] = nx * inv; nor[v + 1] = inv; nor[v + 2] = nz * inv;
        if (h < minY) minY = h;
        if (h > maxY) maxY = h;
      }
    }

    const hondo = 1.2 + geo.userData.nivel * 2.4;
    const base = n * n;
    for (let s = 0; s < perim.length; s++) {
      const o = perim[s] * 3, v = (base + s) * 3;
      pos[v] = pos[o]; pos[v + 1] = pos[o + 1] - hondo; pos[v + 2] = pos[o + 2];
      nor[v] = nor[o]; nor[v + 1] = nor[o + 1]; nor[v + 2] = nor[o + 2];
    }

    geo.attributes.position.needsUpdate = true;
    geo.attributes.normal.needsUpdate = true;

    const lado = q * salto * e;
    const caja = new THREE.Box3(
      new THREE.Vector3(0, minY - hondo, 0),
      new THREE.Vector3(lado, maxY, lado),
    );
    geo.boundingBox = caja;
    geo.boundingSphere = caja.getBoundingSphere(new THREE.Sphere());
  }

  /**
   * Faldón perimetral: el mapa no puede terminar en un corte flotando. Cinco
   * anillos que bajan desde la altura real del borde hasta bien debajo del agua.
   */
  _construirFalda() {
    const anillos = [0, 8, 22, 48, 90, 150];
    this.anchoFalda = anillos[anillos.length - 1];
    const porLado = 96;
    const N = porLado * 4;
    const S = this.medioTam;
    const fondo = this.nivelAgua - 16;

    const pos = new Float32Array(N * anillos.length * 3);
    const idx = [];
    const punto = (t) => {
      const lado = Math.min(3, Math.floor(t));
      const f = t - lado;
      const d = S * 2 * f;
      if (lado === 0) return [-S + d, -S];
      if (lado === 1) return [S, -S + d];
      if (lado === 2) return [S - d, S];
      return [-S, S - d];
    };

    for (let a = 0; a < anillos.length; a++) {
      const escala = (S + anillos[a]) / S;
      const curva = Math.pow(anillos[a] / this.anchoFalda, 0.72);
      for (let k = 0; k < N; k++) {
        const [bx, bz] = punto((k / porLado) % 4);
        const x = bx * escala, z = bz * escala;
        const hBorde = this.altura(bx, bz);
        let y = lerp(hBorde - 0.4, fondo, curva);
        if (a > 0) y += this.ruido.fbm(x * 0.012, z * 0.012, 3) * 3.5 * curva;
        const v = (a * N + k) * 3;
        pos[v] = x; pos[v + 1] = y; pos[v + 2] = z;
      }
    }
    for (let a = 0; a < anillos.length - 1; a++) {
      for (let k = 0; k < N; k++) {
        const k2 = (k + 1) % N;
        const A = a * N + k, B = a * N + k2, C = (a + 1) * N + k2, D = (a + 1) * N + k;
        idx.push(A, B, C, A, C, D);
      }
    }

    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setIndex(idx);
    geo.computeVertexNormals();
    geo.computeBoundingSphere();

    // La falda es la raíz del terreno y los chunks cuelgan de ella: así
    // `terreno.malla` sigue siendo una THREE.Mesh de verdad, con material propio.
    this.malla = new THREE.Mesh(geo, this.material);
    this.malla.name = 'terreno';
    this.malla.receiveShadow = true;
    this.malla.castShadow = false;
    this.malla.matrixAutoUpdate = false;
    this.malla.updateMatrix();
    this.malla.frustumCulled = false;
    for (const c of this.chunks) this.malla.add(c.malla);
  }

  _actualizarLOD(posCam) {
    const d0 = 115, d1 = 260;
    for (let i = 0; i < this.chunks.length; i++) {
      const c = this.chunks[i];
      const dx = c.centroX - posCam.x, dz = c.centroZ - posCam.z, dy = posCam.y;
      const d = Math.sqrt(dx * dx + dz * dz + dy * dy * 0.35);
      const nivel = Math.min(this.niveles - 1, d < d0 ? 0 : d < d1 ? 1 : 2);
      if (nivel !== c.nivel) {
        c.nivel = nivel;
        c.malla.geometry = c.geos[nivel];
      }
    }
    this._posLOD.copy(posCam);
  }

  /* ================================================================ *
   *  Modificación del terreno
   * ================================================================ */

  /**
   * Aplana un rectángulo para asentar un edificio y reconstruye lo afectado.
   * @returns {number} altura a la que quedó la plataforma.
   */
  aplanar(x, z, ancho, alto) {
    const e = this.escalaCelda, res = this.res;
    const margen = clamp(Math.min(ancho, alto) * 0.45, 2.5, 8);
    const x0 = x - ancho * 0.5, x1 = x + ancho * 0.5;
    const z0 = z - alto * 0.5, z1 = z + alto * 0.5;

    // altura objetivo = media del interior, así el edificio no queda enterrado ni volando
    let suma = 0, cuenta = 0;
    for (let a = 0; a <= 2; a++) {
      for (let b = 0; b <= 2; b++) {
        suma += this.altura(lerp(x0, x1, a / 2), lerp(z0, z1, b / 2));
        cuenta++;
      }
    }
    const objetivo = suma / cuenta;

    const aCol = (w) => clamp(Math.floor((w + this.medioTam) / e), 0, res - 1);
    const c0 = aCol(x0 - margen), c1 = aCol(x1 + margen);
    const f0 = aCol(z0 - margen), f1 = aCol(z1 + margen);

    for (let f = f0; f <= f1; f++) {
      const wz = -this.medioTam + f * e;
      const dz = Math.max(0, Math.max(z0 - wz, wz - z1));
      for (let c = c0; c <= c1; c++) {
        const wx = -this.medioTam + c * e;
        const dx = Math.max(0, Math.max(x0 - wx, wx - x1));
        const d = Math.hypot(dx, dz) / margen;
        const t = 1 - smoothstep(0, 1, clamp(d, 0, 1));
        if (t <= 0) continue;
        const i = f * res + c;
        this.alturas[i] = lerp(this.alturas[i], objetivo, t);
      }
    }

    this._reconstruirZona(c0, f0, c1, f1);
    return objetivo;
  }

  /** Rehace geometría, AO y datos de la zona tocada (en índices de rejilla). */
  _reconstruirZona(c0, f0, c1, f1) {
    const qc = this.quadsChunk, lado = this.chunksPorLado;
    const cx0 = clamp(Math.floor((c0 - 1) / qc), 0, lado - 1);
    const cx1 = clamp(Math.floor((c1 + 1) / qc), 0, lado - 1);
    const cz0 = clamp(Math.floor((f0 - 1) / qc), 0, lado - 1);
    const cz1 = clamp(Math.floor((f1 + 1) / qc), 0, lado - 1);
    for (let cz = cz0; cz <= cz1; cz++) {
      for (let cx = cx0; cx <= cx1; cx++) {
        const c = this.chunks[cz * lado + cx];
        for (const g of c.geos) this._rellenarGeometria(g);
      }
    }

    // la AO cambia hasta el alcance del horizonte, no sólo bajo el edificio
    const e = this.escalaCelda, alcance = DIST_AO[DIST_AO.length - 1];
    const aTexel = (col, T) => (col * e) / this.tam * T;
    const holgura = alcance / this.tam;
    const A = this.tamAO, T = this.tamDatos;
    const ax0 = Math.floor(aTexel(c0, A) - holgura * A), ax1 = Math.ceil(aTexel(c1, A) + holgura * A);
    const ay0 = Math.floor(aTexel(f0, A) - holgura * A), ay1 = Math.ceil(aTexel(f1, A) + holgura * A);
    this._calcularAO(ax0, ay0, ax1 + 1, ay1 + 1);
    const tx0 = Math.floor(aTexel(c0, T) - holgura * T), tx1 = Math.ceil(aTexel(c1, T) + holgura * T);
    const ty0 = Math.floor(aTexel(f0, T) - holgura * T), ty1 = Math.ceil(aTexel(f1, T) + holgura * T);
    this._volcarDatos(tx0, ty0, tx1 + 2, ty1 + 2);
  }

  /**
   * Pinta en la textura de mezcla. 'camino' se acumula (se marca de tanto pasar),
   * 'crater' y 'quemadura' se estampan de una.
   */
  pintarDecal(x, z, radio = 3, tipo = 'crater') {
    const canal = tipo === 'camino' ? 0 : tipo === 'quemadura' ? 1 : 2;
    const acumula = canal === 0;
    const T = this.tamMezcla;
    const porMetro = T / this.tam;
    const px = (x + this.medioTam) * porMetro;
    const pz = (z + this.medioTam) * porMetro;
    const rt = Math.max(1, radio * porMetro);
    const x0 = Math.max(0, Math.floor(px - rt)), x1 = Math.min(T - 1, Math.ceil(px + rt));
    const z0 = Math.max(0, Math.floor(pz - rt)), z1 = Math.min(T - 1, Math.ceil(pz + rt));
    const fuerza = canal === 0 ? 0.34 : canal === 1 ? 0.9 : 1.0;

    for (let j = z0; j <= z1; j++) {
      for (let i = x0; i <= x1; i++) {
        const dx = (i + 0.5 - px) / rt, dz = (j + 0.5 - pz) / rt;
        const d = Math.hypot(dx, dz);
        if (d > 1.15) continue;
        // el borde se deforma con ruido de mundo: nada de círculos perfectos
        const wx = i / porMetro - this.medioTam, wz = j / porMetro - this.medioTam;
        const n = this.ruido.fbm(wx * 0.35, wz * 0.35, 3) * 0.26;
        const cae = 1 - smoothstep(0.35 + n, 1.0 + n, d);
        if (cae <= 0) continue;
        const o = (j * T + i) * 4 + canal;
        const v = cae * fuerza * 255;
        this.mezclaPix[o] = acumula ? Math.min(255, this.mezclaPix[o] + v) : Math.max(this.mezclaPix[o], v);
      }
    }
    this._mezclaSucia = true;
  }

  /* ================================================================ */

  cada(dtReal, alfa, ctx) {
    // una sola subida por frame aunque hayan estallado veinte proyectiles
    if (this._mezclaSucia) { this.texMezcla.needsUpdate = true; this._mezclaSucia = false; }

    const cam = ctx.camara;
    if (!cam) return;
    const p = cam.position;
    const dx = p.x - this._posLOD.x, dy = p.y - this._posLOD.y, dz = p.z - this._posLOD.z;
    if (dx * dx + dy * dy + dz * dz > 36) this._actualizarLOD(p);
  }

  dispose() {
    for (const c of this.chunks) for (const g of c.geos) g.dispose();
    this.malla.geometry.dispose();
    this.material.dispose();
    this.texDatos.dispose();
    this.texMezcla.dispose();
    this.uniformes.uCapasColor.value?.dispose();
    this.uniformes.uCapasNormal.value?.dispose();
  }
}
