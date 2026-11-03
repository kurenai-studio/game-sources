/**
 * Almacén de entidades del juego (SoA: structure of arrays) + índice espacial.
 *
 * CONTRATO — no cambiar sin avisar al resto de los módulos:
 *  - Cada entidad es un entero `id` (índice en los arrays tipados).
 *  - `vivo[id] === 1` significa que la ranura está ocupada.
 *  - Las posiciones están en coordenadas de mundo (metros), con Y = altura.
 *  - El eje X/Z es el plano del terreno. Y = arriba. Es coherente con Three.js.
 */

export const TIPO = { NINGUNO: 0, UNIDAD: 1, EDIFICIO: 2, RECURSO: 3, PROYECTIL: 4, DECORADO: 5 };
export const ESTADO = {
  QUIETO: 0, MOVIENDO: 1, ATACANDO: 2, RECOLECTANDO: 3, CONSTRUYENDO: 4,
  DEPOSITANDO: 5, MURIENDO: 6, PRODUCIENDO: 7, REPARANDO: 8,
};

const CAP_INICIAL = 4096;

export class World {
  constructor(capacidad = CAP_INICIAL) {
    this.cap = capacidad;
    this.libres = [];
    this.maxUsado = 0;
    this.tick = 0;
    this.tiempo = 0;

    const f32 = (n = 1) => new Float32Array(capacidad * n);
    const u8 = () => new Uint8Array(capacidad);
    const u16 = () => new Uint16Array(capacidad);
    const i32 = () => new Int32Array(capacidad);

    this.vivo = u8();
    this.tipo = u8();
    this.jugador = u8();          // 0..7 ; 255 = gaia/neutral
    this.defId = u16();           // índice en la tabla de datos (unidades/edificios/recursos)

    this.px = f32(); this.py = f32(); this.pz = f32();
    this.vx = f32(); this.vz = f32();
    this.rot = f32();             // yaw en radianes
    this.rotObjetivo = f32();
    this.escala = f32();

    this.vida = f32(); this.vidaMax = f32();
    this.radio = f32();           // radio de colisión
    this.estado = u8();
    this.objetivo = i32();        // id de entidad objetivo, -1 = ninguno
    this.destinoX = f32(); this.destinoZ = f32();
    this.tieneDestino = u8();
    this.cargaTipo = u8();        // recurso que lleva encima
    this.cargaCant = f32();
    this.temporizador = f32();    // cooldown genérico (ataque / recolección)
    this.progreso = f32();        // 0..1 construcción / producción
    this.veterania = u8();
    this.animFase = f32();        // fase del ciclo de animación
    this.velocidad = f32();
    this.visible = u8();          // recomputado por la niebla de guerra
    this.grupo = u8();            // grupo de control 0..9 (255 = ninguno)
    this.marcaBorrado = u8();

    this.escala.fill(1);
    this.objetivo.fill(-1);

    /** Datos auxiliares poco frecuentes por entidad (cola de producción, etc.) */
    this.meta = new Map();

    /** Índice espacial en rejilla, se reconstruye por tick. */
    this.rejillaCelda = 8; // metros
    this.rejilla = new Map();

    /** Listeners de ciclo de vida: (id) => void */
    this.alCrear = new Set();
    this.alDestruir = new Set();
  }

  crear(tipo, defId, x, z, jugador = 0) {
    let id;
    if (this.libres.length) id = this.libres.pop();
    else {
      id = this.maxUsado++;
      if (id >= this.cap) throw new Error('World: capacidad agotada');
    }
    this.vivo[id] = 1;
    this.tipo[id] = tipo;
    this.defId[id] = defId;
    this.jugador[id] = jugador;
    this.px[id] = x; this.py[id] = 0; this.pz[id] = z;
    this.vx[id] = 0; this.vz[id] = 0;
    this.rot[id] = 0; this.rotObjetivo[id] = 0;
    this.escala[id] = 1;
    this.estado[id] = ESTADO.QUIETO;
    this.objetivo[id] = -1;
    this.tieneDestino[id] = 0;
    this.cargaTipo[id] = 0; this.cargaCant[id] = 0;
    this.temporizador[id] = 0; this.progreso[id] = 0;
    this.veterania[id] = 0;
    this.animFase[id] = Math.random() * Math.PI * 2;
    this.visible[id] = 1;
    this.grupo[id] = 255;
    this.marcaBorrado[id] = 0;
    for (const fn of this.alCrear) fn(id);
    return id;
  }

  destruir(id) {
    if (!this.vivo[id]) return;
    for (const fn of this.alDestruir) fn(id);
    this.vivo[id] = 0;
    this.meta.delete(id);
    this.libres.push(id);
  }

  /** Itera entidades vivas de un tipo. */
  *deTipo(tipo) {
    for (let i = 0; i < this.maxUsado; i++) if (this.vivo[i] && this.tipo[i] === tipo) yield i;
  }
  *todas() {
    for (let i = 0; i < this.maxUsado; i++) if (this.vivo[i]) yield i;
  }

  /* ---------- índice espacial ---------- */
  clave(x, z) {
    const c = this.rejillaCelda;
    return ((Math.floor(x / c) & 0xffff) << 16) | (Math.floor(z / c) & 0xffff);
  }

  reconstruirRejilla() {
    this.rejilla.clear();
    for (let i = 0; i < this.maxUsado; i++) {
      if (!this.vivo[i] || this.tipo[i] === TIPO.PROYECTIL) continue;
      const k = this.clave(this.px[i], this.pz[i]);
      let a = this.rejilla.get(k);
      if (!a) { a = []; this.rejilla.set(k, a); }
      a.push(i);
    }
  }

  /** Devuelve ids dentro de `radio` de (x,z). Reutiliza `salida` si se pasa. */
  cerca(x, z, radio, salida = []) {
    salida.length = 0;
    const c = this.rejillaCelda;
    const r = Math.ceil(radio / c);
    const cx = Math.floor(x / c), cz = Math.floor(z / c);
    const r2 = radio * radio;
    for (let oz = -r; oz <= r; oz++) {
      for (let ox = -r; ox <= r; ox++) {
        const k = (((cx + ox) & 0xffff) << 16) | ((cz + oz) & 0xffff);
        const a = this.rejilla.get(k);
        if (!a) continue;
        for (let n = 0; n < a.length; n++) {
          const id = a[n];
          const dx = this.px[id] - x, dz = this.pz[id] - z;
          if (dx * dx + dz * dz <= r2) salida.push(id);
        }
      }
    }
    return salida;
  }

  dist2(a, b) {
    const dx = this.px[a] - this.px[b], dz = this.pz[a] - this.pz[b];
    return dx * dx + dz * dz;
  }
}
