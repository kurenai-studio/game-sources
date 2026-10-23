/* ==========================================================================
   30 NOCHES - world.js
   Generacion procedural del bosque (reproducible por semilla), obstaculos,
   caminos, puntos de interes, cuadrícula de navegacion y colisiones.
   ========================================================================== */
window.TN = window.TN || {};

TN.World = (function () {
  const U = TN.Utils;
  const CFG = TN.Config;

  const TILE = {
    GRASS: 0,
    DARK: 1,
    DIRT: 2,
    PATH: 3,
    SWAMP: 4,
    FLOOR: 5,
    ASH: 6
  };

  const TILE_COLORS = {
    0: ['#22331f', '#233520', '#1e2f1d'],
    1: ['#1a2819', '#1b2a1b', '#162315'],
    2: ['#332d22', '#352f24', '#312b21'],
    3: ['#3e3628', '#413a2c', '#3a3327'],
    4: ['#1f2b27', '#22302b', '#1c2824'],
    5: ['#363429', '#38362d', '#33322a'],
    6: ['#2c2926', '#2e2b27', '#292622']
  };

  function hexToRgb(hex) {
    let h = hex.slice(1);
    if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
    return [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)];
  }
  function rgbToHex(r, g, b) {
    const c = (v) => {
      v = Math.max(0, Math.min(255, Math.round(v)));
      return (v < 16 ? '0' : '') + v.toString(16);
    };
    return '#' + c(r) + c(g) + c(b);
  }

  class World {
    constructor(seed) {
      this.seed = seed >>> 0;
      this.width = CFG.WORLD.width;
      this.height = CFG.WORLD.height;
      this.tile = CFG.WORLD.tile;
      this.cols = Math.ceil(this.width / this.tile);
      this.rows = Math.ceil(this.height / this.tile);

      this.tiles = new Uint8Array(this.cols * this.rows);
      this.shade = new Float32Array(this.cols * this.rows);
      this.navBlocked = new Uint8Array(this.cols * this.rows);
      this.navCost = new Float32Array(this.cols * this.rows);

      this.obstacles = [];      // obstaculos solidos (arboles, rocas, edificios)
      this.blockers = [];       // rectangulos que bloquean la navegacion
      this.pois = [];           // puntos de interes
      this.decor = [];         // decoracion no solida (arbustos, huesos, (...)
      this.base = { x: CFG.BASE.x, y: CFG.BASE.y };
      this.generator = { x: CFG.BASE.x, y: CFG.BASE.y - 40, hw: CFG.GENERATOR.w / 2, hh: CFG.GENERATOR.h / 2 };
      this.antenna = { x: CFG.BASE.x, y: CFG.BASE.y + 70, hw: 14, hh: 14 };

      this._hash = new Map();
      this._hashCell = 80;
      this._rng = U.makeRng(this.seed);
      this._treeCount = 0;
      this._rockCount = 0;
    }

    /* ================= Indices de tiles ================= */
    idx(tx, ty) { return ty * this.cols + tx; }
    inBounds(tx, ty) { return tx >= 0 && ty >= 0 && tx < this.cols && ty < this.rows; }
    tileAt(wx, wy) {
      const tx = Math.floor(wx / this.tile), ty = Math.floor(wy / this.tile);
      if (!this.inBounds(tx, ty)) return TILE.DIRT;
      return this.tiles[this.idx(tx, ty)];
    }
    setTile(wx, wy, t) {
      const tx = Math.floor(wx / this.tile), ty = Math.floor(wy / this.tile);
      if (!this.inBounds(tx, ty)) return;
      this.tiles[this.idx(tx, ty)] = t;
    }

    isSwamp(wx, wy) { return this.tileAt(wx, wy) === TILE.SWAMP; }
    isPath(wx, wy) { return this.tileAt(wx, wy) === TILE.PATH; }

    /* ================= Generacion ================= */
    generate() {
      const rng = this._rng;
      this._genGround(rng);
      this._genBaseClearing(rng);
      this._genPaths(rng);
      this._genSwamps(rng);
      this._placePois(rng);
      this._genTrees(rng);
      this._genRocks(rng);
      this._genRuins(rng);
      this._genDecor(rng);
      this._genShade();
      this._genTileColors();
      this.rebuildNav();
      return this;
    }

    _genGround(rng) {
      const t = this.tiles;
      for (let y = 0; y < this.rows; y++) {
        for (let x = 0; x < this.cols; x++) {
          const n = U.hash2(x, y, this.seed);
          const n2 = U.hash2(x >> 2, y >> 2, this.seed + 7);
          t[this.idx(x, y)] = n2 > 0.62 ? TILE.DARK : TILE.GRASS;
          if (n > 0.985) t[this.idx(x, y)] = TILE.DIRT;
        }
      }
    }

    _genBaseClearing(rng) {
      const R = CFG.BASE.clearRadius;
      const cx = this.base.x, cy = this.base.y;
      for (let y = 0; y < this.rows; y++) {
        for (let x = 0; x < this.cols; x++) {
          const wx = x * this.tile + this.tile / 2, wy = y * this.tile + this.tile / 2;
          const d = Math.hypot(wx - cx, wy - cy);
          if (d < R) {
            const edge = d > R - 34;
            this.tiles[this.idx(x, y)] = edge ? TILE.DIRT : TILE.FLOOR;
          }
        }
      }
    }

    _pathBetween(ax, ay, bx, by, width) {
      const steps = Math.ceil(Math.hypot(bx - ax, by - ay) / 12);
      const half = width / 2;
      for (let i = 0; i <= steps; i++) {
        const t = i / steps;
        const px = ax + (bx - ax) * t, py = ay + (by - ay) * t;
        for (let oy = -half; oy <= half; oy += this.tile / 2) {
          for (let ox = -half; ox <= half; ox += this.tile / 2) {
            this.setTile(px + ox, py + oy, TILE.PATH);
          }
        }
      }
    }

    _genPaths(rng) {
      // Anillo alrededor de la base
      const R = 300;
      const segs = 48;
      for (let i = 0; i < segs; i++) {
        const a1 = (i / segs) * Math.PI * 2, a2 = ((i + 1) / segs) * Math.PI * 2;
        this._pathBetween(this.base.x + Math.cos(a1) * R, this.base.y + Math.sin(a1) * R,
          this.base.x + Math.cos(a2) * R, this.base.y + Math.sin(a2) * R, 46);
      }
      // Caminos a los puntos de interes
      for (const p of CFG.POIS) {
        this._pathBetween(this.base.x, this.base.y, p.x, p.y, 40);
      }
      // Sendero secundario entre POIs
      this._pathBetween(CFG.POIS[0].x, CFG.POIS[0].y, CFG.POIS[1].x, CFG.POIS[1].y, 32);
    }

    _genSwamps(rng) {
      const count = 4;
      for (let i = 0; i < count; i++) {
        let x = 0, y = 0, ok = false;
        for (let tries = 0; tries < 60 && !ok; tries++) {
          x = rng.range(200, this.width - 200);
          y = rng.range(200, this.height - 200);
          ok = Math.hypot(x - this.base.x, y - this.base.y) > 520;
          for (const p of CFG.POIS) if (Math.hypot(x - p.x, y - p.y) < 260) ok = false;
          if (ok && this.isPath(x, y)) ok = false;
        }
        if (!ok) continue;
        const rad = rng.range(70, 130);
        for (let oy = -rad; oy <= rad; oy += 12) {
          for (let ox = -rad; ox <= rad; ox += 12) {
            if (ox * ox + oy * oy > rad * rad) continue;
            this.setTile(x + ox, y + oy, TILE.SWAMP);
          }
        }
      }
    }

    _placePois(rng) {
      for (const def of CFG.POIS) {
        const poi = {
          id: def.id, name: def.name, hint: def.hint,
          component: def.component, componentName: def.componentName,
          x: def.x, y: def.y, hw: def.w / 2, hh: def.h / 2,
          rot: def.rot || 0,
          discovered: false,
          taken: false
        };
        this.pois.push(poi);
        // Estructura solida + bloquea navegacion
        this.addObstacle({ kind: 'poi_' + poi.id, x: poi.x, y: poi.y, shape: 'rect', hw: poi.hw, hh: poi.hh, solid: true, poi: poi });
        this.blockers.push({ x: poi.x, y: poi.y, hw: poi.hw, hh: poi.hh });
        // Limpieza alrededor
        this._clearArea(poi.x, poi.y, poi.hw + 90, poi.hh + 90);
        // Contenedor interactuable junto a la estructura
        poi.container = {
          x: poi.x + poi.hw * 0.4, y: poi.y + poi.hh * 0.55,
          kind: 'scrap', label: poi.name, poi: poi
        };
      }
    }

    _clearArea(cx, cy, hw, hh) {
      for (let y = 0; y < this.rows; y++) {
        for (let x = 0; x < this.cols; x++) {
          const wx = x * this.tile + this.tile / 2, wy = y * this.tile + this.tile / 2;
          if (Math.abs(wx - cx) <= hw && Math.abs(wy - cy) <= hh) {
            if (this.tiles[this.idx(x, y)] === TILE.SWAMP) continue;
            this.tiles[this.idx(x, y)] = TILE.DIRT;
          }
        }
      }
    }

    _isFreeForTree(x, y) {
      if (Math.hypot(x - this.base.x, y - this.base.y) < CFG.BASE.clearRadius + 30) return false;
      // Los puntos de interes se describen con w/h (CFG.POIS), no con hw/hh:
      // los arboles no pueden caer encima del pecio, el bunker ni la torre.
      for (const p of CFG.POIS) {
        if (Math.abs(x - p.x) < p.w / 2 + 70 && Math.abs(y - p.y) < p.h / 2 + 70) return false;
      }
      if (this.isPath(x, y)) return false;
      if (this.isSwamp(x, y)) return false;
      return true;
    }

    _genTrees(rng) {
      const target = 460;
      let attempts = 0;
      while (this._treeCount < target && attempts < target * 30) {
        attempts++;
        const x = rng.range(40, this.width - 40), y = rng.range(40, this.height - 40);
        if (!this._isFreeForTree(x, y)) continue;
        // Separacion minima para que el bosque no se solape
        let close = false;
        for (const o of this.nearby(x, y, 40)) {
          if (o.kind === 'tree' && Math.hypot(o.x - x, o.y - y) < 38) { close = true; break; }
        }
        if (close) continue;
        const big = rng.chance(0.16);
        const r = big ? rng.range(16, 21) : rng.range(11, 15);
        const ob = this.addObstacle({
          kind: 'tree', x: x, y: y, shape: 'circle', r: r, solid: true,
          variant: rng.int(0, 3), scale: rng.range(0.85, 1.25)
        });
        this._treeCount++;
        ob.node = null; // enlazado por ResourceManager
      }
    }

    _genRocks(rng) {
      const target = 190;
      let attempts = 0;
      while (this._rockCount < target && attempts < target * 30) {
        attempts++;
        const x = rng.range(40, this.width - 40), y = rng.range(40, this.height - 40);
        if (Math.hypot(x - this.base.x, y - this.base.y) < CFG.BASE.clearRadius + 10) continue;
        let close = false;
        for (const o of this.nearby(x, y, 50)) {
          if ((o.kind === 'rock' || o.kind === 'tree') && Math.hypot(o.x - x, o.y - y) < 34) { close = true; break; }
        }
        if (close) continue;
        const big = rng.chance(0.4);
        const r = big ? rng.range(15, 20) : rng.range(8, 12);
        const ob = this.addObstacle({
          kind: 'rock', x: x, y: y, shape: 'circle', r: r, solid: true,
          variant: rng.int(0, 2), scale: rng.range(0.85, 1.2), big: big
        });
        this._rockCount++;
        ob.node = null;
      }
    }

    _genRuins(rng) {
      // Restos de instalaciones:-recursos de chatarra garantizados.
      const spots = [
        { x: 760, y: 1420, w: 90, h: 70, name: 'Restos de un galpon' },
        { x: 1520, y: 520, w: 80, h: 80, name: 'Cimiento derruido' },
        { x: 2100, y: 1450, w: 100, h: 70, name: 'Zona de carga' },
        { x: 380, y: 1780, w: 84, h: 84, name: 'Torre carbonera' },
        { x: 2280, y: 260, w: 86, h: 66, name: 'Coche quemado' }
      ];
      for (const s of spots) {
        this.addObstacle({ kind: 'ruin', x: s.x, y: s.y, shape: 'rect', hw: s.w / 2, hh: s.h / 2, solid: true });
        this.blockers.push({ x: s.x, y: s.y, hw: s.w / 2, hh: s.h / 2 });
        this._clearArea(s.x, s.y, s.w / 2 + 40, s.h / 2 + 40);
        this.decor.push({ kind: 'ruinSign', x: s.x, y: s.y - s.h / 2 - 10, label: s.name });
      }
    }

    _genDecor(rng) {
      for (let i = 0; i < 260; i++) {
        const x = rng.range(30, this.width - 30), y = rng.range(30, this.height - 30);
        if (Math.hypot(x - this.base.x, y - this.base.y) < CFG.BASE.clearRadius) continue;
        if (this.isPath(x, y)) continue;
        this.decor.push({
          kind: rng.chance(0.5) ? 'grass' : 'twig',
          x: x, y: y, s: rng.range(0.7, 1.4), v: rng.int(0, 2)
        });
      }
    }

    _genShade() {
      for (let y = 0; y < this.rows; y++) {
        for (let x = 0; x < this.cols; x++) {
          this.shade[this.idx(x, y)] = 0.86 + this._noise(x, y, 5) * 0.26;
        }
      }
    }

    /* Ruido de valor interpolado: manchas suaves en lugar de quadriculas. */
    _noise(x, y, scale) {
      const fx = x / scale, fy = y / scale;
      const x0 = Math.floor(fx), y0 = Math.floor(fy);
      const tx = fx - x0, ty = fy - y0;
      const sx = tx * tx * (3 - 2 * tx), sy = ty * ty * (3 - 2 * ty);
      const s = this.seed + 99;
      const n00 = U.hash2(x0, y0, s);
      const n10 = U.hash2(x0 + 1, y0, s);
      const n01 = U.hash2(x0, y0 + 1, s);
      const n11 = U.hash2(x0 + 1, y0 + 1, s);
      const a = n00 + (n10 - n00) * sx;
      const b = n01 + (n11 - n01) * sx;
      return a + (b - a) * sy;
    }

    /* Colores de terreno precalculados: mezcla continua de la paleta con
       ruido suave, para que el terreno no parezca un damero. */
    _genTileColors() {
      this.tileColors = new Array(this.cols * this.rows);
      for (let y = 0; y < this.rows; y++) {
        for (let x = 0; x < this.cols; x++) {
          const i = this.idx(x, y);
          const t = this.tiles[i] || 0;
          const pal = TILE_COLORS[t] || TILE_COLORS[0];
          const a = hexToRgb(pal[0]);
          const c = hexToRgb(pal[2]);
          const n = this._noise(x, y, 4);
          const jitter = (U.hash2(x, y, this.seed + 31) - 0.5) * 7;
          const sh = this.shade[i];
          this.tileColors[i] = rgbToHex(
            (a[0] + (c[0] - a[0]) * n + jitter) * sh,
            (a[1] + (c[1] - a[1]) * n + jitter) * sh,
            (a[2] + (c[2] - a[2]) * n + jitter) * sh
          );
        }
      }
    }

    /* ================= Obstaculos y hash espacial ================= */
    _hashKey(cx, cy) { return cx + ',' + cy; }

    addObstacle(o) {
      o.id = U.uid('ob');
      this.obstacles.push(o);
      if (o.solid) this._hashInsert(o);
      return o;
    }

    _hashInsert(o) {
      const c = this._hashCell;
      const x0 = Math.floor((o.x - (o.r || o.hw || 16)) / c), x1 = Math.floor((o.x + (o.r || o.hw || 16)) / c);
      const y0 = Math.floor((o.y - (o.r || o.hh || 16)) / c), y1 = Math.floor((o.y + (o.r || o.hh || 16)) / c);
      for (let cy = y0; cy <= y1; cy++) {
        for (let cx = x0; cx <= x1; cx++) {
          const k = this._hashKey(cx, cy);
          let list = this._hash.get(k);
          if (!list) { list = []; this._hash.set(k, list); }
          list.push(o);
        }
      }
    }

    removeObstacle(o) {
      const i = this.obstacles.indexOf(o);
      if (i !== -1) this.obstacles.splice(i, 1);
      if (o.solid) {
        const c = this._hashCell;
        const x0 = Math.floor((o.x - (o.r || o.hw || 16)) / c), x1 = Math.floor((o.x + (o.r || o.hw || 16)) / c);
        const y0 = Math.floor((o.y - (o.r || o.hh || 16)) / c), y1 = Math.floor((o.y + (o.r || o.hh || 16)) / c);
        for (let cy = y0; cy <= y1; cy++) {
          for (let cx = x0; cx <= x1; cx++) {
            const list = this._hash.get(this._hashKey(cx, cy));
            if (!list) continue;
            const j = list.indexOf(o);
            if (j !== -1) list.splice(j, 1);
          }
        }
      }
    }

    /* Obstaculos solidos cercanos a un punto. */
    nearby(x, y, radius) {
      const c = this._hashCell;
      const x0 = Math.floor((x - radius) / c), x1 = Math.floor((x + radius) / c);
      const y0 = Math.floor((y - radius) / c), y1 = Math.floor((y + radius) / c);
      const out = [];
      const seen = new Set();
      for (let cy = y0; cy <= y1; cy++) {
        for (let cx = x0; cx <= x1; cx++) {
          const list = this._hash.get(this._hashKey(cx, cy));
          if (!list) continue;
          for (const o of list) { if (!seen.has(o.id)) { seen.add(o.id); out.push(o); } }
        }
      }
      return out;
    }

    /* Resolucion de colisiones de un circulo contra el mundo.
       opts.ignorePassable: ignora obstaculos marcados como passableForPlayer
       (puertas abiertas por el jugador). */
    resolve(x, y, r, opts) {
      opts = opts || {};
      for (let pass = 0; pass < 3; pass++) {
        let moved = false;
        const cands = this.nearby(x, y, r + 24);
        for (let i = 0; i < cands.length; i++) {
          const o = cands[i];
          if (o.solid === false) continue;
          if (opts.ignorePassable && o.passableForPlayer) continue;
          if (o.shape === 'circle') {
            const dx = x - o.x, dy = y - o.y;
            const d = Math.hypot(dx, dy);
            const min = o.r + r;
            if (d < min) {
              if (d < 0.0001) { x += min; moved = true; }
              else { const push = min - d; x += (dx / d) * push; y += (dy / d) * push; moved = true; }
            }
          } else {
            const hw = o.hw || 0, hh = o.hh || 0;
            const nx = U.clamp(x, o.x - hw, o.x + hw);
            const ny = U.clamp(y, o.y - hh, o.y + hh);
            const dx = x - nx, dy = y - ny;
            const d2 = dx * dx + dy * dy;
            if (d2 < r * r) {
              if (d2 > 1e-6) {
                const d = Math.sqrt(d2), push = r - d;
                x += (dx / d) * push; y += (dy / d) * push;
              } else {
                const ox = hw + r - Math.abs(x - o.x);
                const oy = hh + r - Math.abs(y - o.y);
                if (ox < oy) x += (x < o.x ? -ox : ox);
                else y += (y < o.y ? -oy : oy);
              }
              moved = true;
            }
          }
        }
        if (!moved) break;
      }
      x = U.clamp(x, r, this.width - r);
      y = U.clamp(y, r, this.height - r);
      return { x: x, y: y };
    }

    /* ================= Navegacion ================= */
    rebuildNav() {
      const nav = this.navBlocked, cost = this.navCost;
      nav.fill(0); cost.fill(0);
      // obstaculos solidos rectangulares (edificios, ruinas, POI)
      for (const b of this.blockers) this._stampRect(b, 1);
      for (const o of this.obstacles) {
        if (o.kind === 'rock' && o.big) this._stampRect({ x: o.x, y: o.y, hw: o.r, hh: o.r }, 1);
      }
      // arboles: coste adicional pero transitables
      for (const o of this.obstacles) {
        if (o.kind === 'tree') this._stampRect({ x: o.x, y: o.y, hw: o.r * 0.75, hh: o.r * 0.75 }, 0, 1.6);
      }
      // generador y antena
      this._stampRect({ x: this.generator.x, y: this.generator.y, hw: this.generator.hw, hh: this.generator.hh }, 1);
      this._stampRect({ x: this.antenna.x, y: this.antenna.y, hw: this.antenna.hw, hh: this.antenna.hh }, 1);
    }

    _stampRect(r, blocked, extraCost) {
      const x0 = Math.max(0, Math.floor((r.x - r.hw) / this.tile));
      const x1 = Math.min(this.cols - 1, Math.floor((r.x + r.hw) / this.tile));
      const y0 = Math.max(0, Math.floor((r.y - r.hh) / this.tile));
      const y1 = Math.min(this.rows - 1, Math.floor((r.y + r.hh) / this.tile));
      for (let ty = y0; ty <= y1; ty++) {
        for (let tx = x0; tx <= x1; tx++) {
          const i = this.idx(tx, ty);
          if (blocked) this.navBlocked[i] = 1;
          if (extraCost) this.navCost[i] += extraCost;
        }
      }
    }

    navBlockedAt(wx, wy) {
      const tx = Math.floor(wx / this.tile), ty = Math.floor(wy / this.tile);
      if (!this.inBounds(tx, ty)) return 1;
      return this.navBlocked[this.idx(tx, ty)] === 1;
    }

    /* Linea de vision sobre la cuadricula de navegacion.
       La casilla de origen y la de destino se ignoran: asi una torreta
       (que ocupa una casilla solida) puede ver y ser vista. */
    losClear(x1, y1, x2, y2) {
      let tx = Math.floor(x1 / this.tile), ty = Math.floor(y1 / this.tile);
      const tx2 = Math.floor(x2 / this.tile), ty2 = Math.floor(y2 / this.tile);
      if (tx === tx2 && ty === ty2) return true;
      const dx = Math.abs(tx2 - tx), dy = Math.abs(ty2 - ty);
      const sx = tx < tx2 ? 1 : -1, sy = ty < ty2 ? 1 : -1;
      let err = dx - dy;
      let guard = 0;
      while (guard++ < 400) {
        const e2 = 2 * err;
        if (e2 > -dy) { err -= dy; tx += sx; }
        if (e2 < dx) { err += dx; ty += sy; }
        if (tx === tx2 && ty === ty2) return true;
        if (this.navBlockedAt(tx * this.tile, ty * this.tile)) return false;
      }
      return true;
    }

    /* Punto aleatorio transitable (fuera de obstaculos). */
    randomOpenPoint(rng, minBaseDist) {
      const minD = minBaseDist === undefined ? 0 : minBaseDist;
      for (let i = 0; i < 200; i++) {
        const x = rng.range(60, this.width - 60);
        const y = rng.range(60, this.height - 60);
        if (Math.hypot(x - this.base.x, y - this.base.y) < minD) continue;
        if (this.navBlockedAt(x, y)) continue;
        return { x: x, y: y };
      }
      return { x: rng.range(60, this.width - 60), y: rng.range(60, this.height - 60) };
    }

    /* Color base de un tile (precalculado en la generacion). */
    tileColor(tx, ty) {
      if (!this.tileColors) return '#22331f';
      const i = this.idx(tx, ty);
      return this.tileColors[i] || '#22331f';
    }
  }

  World.TILE = TILE;
  World.TILE_COLORS = TILE_COLORS;
  return World;
})();
