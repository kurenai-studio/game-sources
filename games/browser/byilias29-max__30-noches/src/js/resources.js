/* ==========================================================================
   30 NOCHES - resources.js
   Nodos recolectables (arboles, rocas, arbustos, cajas) y su agotamiento.
   ========================================================================== */
window.TN = window.TN || {};

TN.Resources = (function () {
  const U = TN.Utils;

  const KIND_INFO = {
    wood: { label: 'Arbol', verb: 'Talar', color: '#8a6a3c', icon: 'W' },
    stone: { label: 'Roca', verb: 'Picar', color: '#9aa0a6', icon: 'S' },
    herb: { label: 'Arbusto de hierbas', verb: 'Arrancar', color: '#7fbf5a', icon: 'H' },
    scrap: { label: 'Caja de chatarra', verb: 'Abrir', color: '#b0793c', icon: 'C' }
  };

  class ResourceManager {
    constructor(world) {
      this.world = world;
      this.nodes = [];
      this._build();
    }

    _build() {
      const w = this.world;
      // Arboles -> madera
      for (const o of w.obstacles) {
        if (o.kind === 'tree') {
          const node = this._mk('wood', o.x, o.y + 6, 13, 4, { wood: 2 }, o);
          node.tree = true;
        } else if (o.kind === 'rock') {
          const node = this._mk('stone', o.x, o.y + 4, 12, o.big ? 5 : 3, { stone: 2 }, o);
          node.rock = true;
        }
      }
      // Arbustos de hierbas
      const rng = U.makeRng(w.seed + 991);
      let placed = 0;
      for (let i = 0; i < 500 && placed < 150; i++) {
        const x = rng.range(50, w.width - 50), y = rng.range(50, w.height - 50);
        if (Math.hypot(x - w.base.x, y - w.base.y) < CFG_CLEAR()) continue;
        if (w.isPath(x, y) || w.isSwamp(x, y)) continue;
        let close = false;
        for (const n of this.nodes) {
          if (n.kind === 'herb' && Math.hypot(n.x - x, n.y - y) < 110) { close = true; break; }
        }
        if (close) continue;
        this._mk('herb', x, y, 12, 1, { herbs: 3 }, null);
        placed++;
      }
      // Cajas de chatarra dispersas
      let crates = 0;
      for (let i = 0; i < 600 && crates < 46; i++) {
        const x = rng.range(60, w.width - 60), y = rng.range(60, w.height - 60);
        if (Math.hypot(x - w.base.x, y - w.base.y) < 260) continue;
        if (w.isPath(x, y)) continue;
        let close = false;
        for (const n of this.nodes) {
          if (n.kind === 'scrap' && Math.hypot(n.x - x, n.y - y) < 260) { close = true; break; }
        }
        if (close) continue;
        this._mk('scrap', x, y, 12, 1, { scrap: rng.int(2, 5) }, null);
        crates++;
      }
      // Chatarra garantizada en ruinas y vehiculos
      for (const d of w.decor) {
        if (d.kind === 'ruinSign') {
          this._mk('scrap', d.x + 26, d.y + 16, 12, 1, { scrap: rng.int(4, 8) }, null);
        }
      }
    }

    _mk(kind, x, y, radius, charges, yieldPer, obstacle) {
      const node = {
        id: U.uid('node'),
        kind: kind,
        x: x, y: y,
        radius: radius,
        charges: charges,
        maxCharges: charges,
        yield: yieldPer,
        depleted: false,
        obstacle: obstacle || null,
        wobble: Math.random() * Math.PI * 2,
        variant: Math.random()
      };
      if (obstacle) obstacle.node = node;
      this.nodes.push(node);
      return node;
    }

    /* Nodo mas cercano dentro del rango. */
    nearest(x, y, range, kinds) {
      let best = null, bestD = range * range;
      for (const n of this.nodes) {
        if (n.depleted) continue;
        if (kinds && kinds.indexOf(n.kind) === -1) continue;
        const d = U.dist2(x, y, n.x, n.y);
        if (d < bestD) { bestD = d; best = n; }
      }
      return best;
    }

    /* Recolecta un golpe. Devuelve el botin obtenido o null si no queda. */
    harvest(node, game) {
      if (!node || node.depleted) return null;
      const gain = {};
      const bonus = game ? game.getHarvestMultiplier() : 1;
      for (const k in node.yield) {
        let amount = node.yield[k];
        amount = Math.max(1, Math.round(amount * bonus));
        gain[k] = amount;
      }
      node.charges -= 1;
      if (node.charges <= 0) {
        node.depleted = true;
        if (node.obstacle) {
          this.world.removeObstacle(node.obstacle);
          node.obstacle = null;
        }
      }
      return gain;
    }

    /* Respaldo serializable: solo los estados agotados/recolectados. */
    serialize() {
      const out = [];
      for (const n of this.nodes) {
        if (n.depleted || n.charges < n.maxCharges) {
          out.push({ id: n.id, c: n.charges, d: n.depleted ? 1 : 0 });
        }
      }
      return out;
    }

    restore(data) {
      if (!Array.isArray(data)) return;
      for (const rec of data) {
        const n = this.nodes.find(x => x.id === rec.id);
        if (!n) continue;
        n.charges = rec.c;
        if (rec.d) {
          n.depleted = true;
          if (n.obstacle) { this.world.removeObstacle(n.obstacle); n.obstacle = null; }
        }
      }
    }
  }

  function CFG_CLEAR() { return TN.Config.BASE.clearRadius * 0.6; }

  ResourceManager.KIND_INFO = KIND_INFO;
  const Resources = { Manager: ResourceManager, KIND_INFO: KIND_INFO };
  Resources.KIND_INFO = KIND_INFO;
  return Resources;
})();
