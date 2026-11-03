/**
 * Cámara de estrategia: órbita isométrica con inercia, zoom hacia el cursor,
 * rotación libre, borde de pantalla y sacudida (screen shake) para impactos.
 */
import * as THREE from 'three';
import { ORDEN } from '../core/Ctx.js';
import { clamp, lerp } from '../core/RNG.js';

const _rayo = new THREE.Raycaster();
const _plano = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0);
const _v = new THREE.Vector3();
const _v2 = new THREE.Vector3();

export class CamaraRTS {
  constructor(camara, dom, ctx) {
    this.nombre = 'camara';
    this.orden = ORDEN.ENTRADA;
    this.cam = camara;
    this.dom = dom;
    this.ctx = ctx;

    this.foco = new THREE.Vector3(0, 0, 0);   // punto del suelo que mira
    this.focoObjetivo = new THREE.Vector3(0, 0, 0);
    this.distancia = 78;
    this.distanciaObjetivo = 78;
    this.minDist = 16; this.maxDist = 240;
    this.azimut = Math.PI * 0.25;
    this.azimutObjetivo = Math.PI * 0.25;
    this.elevacion = 0.86;                    // radianes desde el horizonte
    this.elevacionObjetivo = 0.86;
    this.velocidad = 62;                      // m/s de paneo
    this.limite = 400;                        // se ajusta al tamaño del mapa

    this.teclas = new Set();
    this.raton = { x: 0, y: 0, nx: 0, ny: 0, dentro: false, botones: 0 };
    this.arrastreRotar = false;
    this.bordeActivo = true;
    this.sacudida = 0;
    this._sacudidaV = new THREE.Vector3();

    this._instalarEventos();
  }

  _instalarEventos() {
    const d = this.dom;
    window.addEventListener('keydown', (e) => {
      if (e.repeat) return;
      this.teclas.add(e.code);
    });
    window.addEventListener('keyup', (e) => this.teclas.delete(e.code));
    window.addEventListener('blur', () => this.teclas.clear());

    d.addEventListener('pointermove', (e) => {
      this.raton.x = e.clientX; this.raton.y = e.clientY;
      this.raton.nx = (e.clientX / window.innerWidth) * 2 - 1;
      this.raton.ny = -(e.clientY / window.innerHeight) * 2 + 1;
      this.raton.dentro = true;
      if (this.arrastreRotar) {
        this.azimutObjetivo -= e.movementX * 0.005;
        this.elevacionObjetivo = clamp(this.elevacionObjetivo + e.movementY * 0.004, 0.30, 1.45);
      }
    });
    d.addEventListener('pointerdown', (e) => {
      this.raton.botones = e.buttons;
      if (e.button === 1 || (e.button === 2 && e.shiftKey)) {
        this.arrastreRotar = true;
        d.requestPointerLock?.();
      }
    });
    window.addEventListener('pointerup', (e) => {
      this.raton.botones = e.buttons;
      if (this.arrastreRotar) { this.arrastreRotar = false; document.exitPointerLock?.(); }
    });
    d.addEventListener('contextmenu', (e) => e.preventDefault());
    d.addEventListener('wheel', (e) => {
      e.preventDefault();
      const f = Math.exp(e.deltaY * 0.0014);
      const antes = this.puntoSueloCursor();
      this.distanciaObjetivo = clamp(this.distanciaObjetivo * f, this.minDist, this.maxDist);
      // zoom hacia el cursor: corrige el foco para que el punto bajo el mouse quede quieto
      if (antes && e.deltaY < 0) {
        this.focoObjetivo.lerp(new THREE.Vector3(antes.x, 0, antes.z), 0.16);
      }
    }, { passive: false });
  }

  /** Rayo desde el cursor al plano del suelo (o al terreno si está disponible). */
  puntoSueloCursor() {
    return this.puntoSuelo(this.raton.nx, this.raton.ny);
  }

  puntoSuelo(nx, ny) {
    _rayo.setFromCamera({ x: nx, y: ny }, this.cam);
    const terreno = this.ctx?.terreno;
    if (terreno?.intersectar) {
      const p = terreno.intersectar(_rayo);
      if (p) return p;
    }
    const hit = _rayo.ray.intersectPlane(_plano, _v2.set(0, 0, 0));
    return hit ? { x: hit.x, y: 0, z: hit.z } : null;
  }

  rayoCursor() {
    _rayo.setFromCamera({ x: this.raton.nx, y: this.raton.ny }, this.cam);
    return _rayo;
  }

  enfocar(x, z, inmediato = false) {
    this.focoObjetivo.set(x, 0, z);
    if (inmediato) this.foco.copy(this.focoObjetivo);
  }

  sacudir(fuerza = 1) { this.sacudida = Math.min(this.sacudida + fuerza, 3); }

  setLimite(tam) { this.limite = tam * 0.5 + 40; }

  cada(dt) {
    const t = this.teclas;
    const rapido = t.has('ShiftLeft') || t.has('ShiftRight') ? 2.2 : 1;
    let mx = 0, mz = 0;
    if (t.has('KeyW') || t.has('ArrowUp')) mz -= 1;
    if (t.has('KeyS') || t.has('ArrowDown')) mz += 1;
    if (t.has('KeyA') || t.has('ArrowLeft')) mx -= 1;
    if (t.has('KeyD') || t.has('ArrowRight')) mx += 1;

    // paneo por borde de pantalla
    if (this.bordeActivo && this.raton.dentro && !this.arrastreRotar) {
      const m = 8;
      if (this.raton.x < m) mx -= 1;
      if (this.raton.x > window.innerWidth - m) mx += 1;
      if (this.raton.y < m) mz -= 1;
      if (this.raton.y > window.innerHeight - m) mz += 1;
    }

    if (t.has('KeyQ')) this.azimutObjetivo += dt * 1.4;
    if (t.has('KeyE')) this.azimutObjetivo -= dt * 1.4;

    if (mx || mz) {
      const len = Math.hypot(mx, mz) || 1;
      mx /= len; mz /= len;
      const ca = Math.cos(this.azimut), sa = Math.sin(this.azimut);
      const escala = this.velocidad * rapido * dt * (this.distancia / 78);
      this.focoObjetivo.x += (mx * ca - mz * sa) * escala;
      this.focoObjetivo.z += (mx * sa + mz * ca) * escala;
    }

    const L = this.limite;
    this.focoObjetivo.x = clamp(this.focoObjetivo.x, -L, L);
    this.focoObjetivo.z = clamp(this.focoObjetivo.z, -L, L);

    const k = 1 - Math.pow(0.0008, dt);
    this.foco.lerp(this.focoObjetivo, k);
    this.distancia = lerp(this.distancia, this.distanciaObjetivo, k);
    this.azimut = lerp(this.azimut, this.azimutObjetivo, k);
    this.elevacion = lerp(this.elevacion, this.elevacionObjetivo, k);

    // altura del terreno bajo el foco para que la cámara "siga" el relieve
    const hSuelo = this.ctx?.terreno?.altura ? this.ctx.terreno.altura(this.foco.x, this.foco.z) : 0;
    this.foco.y = lerp(this.foco.y, hSuelo, 1 - Math.pow(0.002, dt));

    const ce = Math.cos(this.elevacion), se = Math.sin(this.elevacion);
    _v.set(
      this.foco.x + Math.cos(this.azimut) * ce * this.distancia,
      this.foco.y + se * this.distancia,
      this.foco.z + Math.sin(this.azimut) * ce * this.distancia
    );

    if (this.sacudida > 0.001) {
      this.sacudida *= Math.pow(0.02, dt);
      const a = performance.now() * 0.05;
      this._sacudidaV.set(Math.sin(a * 1.7), Math.sin(a * 2.3), Math.cos(a * 1.3))
        .multiplyScalar(this.sacudida * 0.55);
      _v.add(this._sacudidaV);
    }

    this.cam.position.copy(_v);
    this.cam.lookAt(this.foco);
    // el plano lejano se adapta al zoom: menos z-fighting de cerca, más alcance de lejos
    this.cam.far = Math.max(900, this.distancia * 14);
    this.cam.near = Math.max(0.4, this.distancia * 0.012);
    this.cam.updateProjectionMatrix();
  }
}
