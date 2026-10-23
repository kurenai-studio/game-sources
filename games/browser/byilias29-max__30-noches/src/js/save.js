/* ==========================================================================
   30 NOCHES - save.js
   Guardado local de la partida en curso (localStorage) con version de esquema
   y validacion basica de los datos.
   ========================================================================== */
window.TN = window.TN || {};

TN.Save = (function () {
  const U = TN.Utils;

  class SaveManager {
    constructor(game) {
      this.game = game;
      this.dirty = false;
      this.lastSave = 0;
      this.autoInterval = 20;      // segundos entre guardados automaticos
    }

    markDirty() { this.dirty = true; }

    key() { return TN.Config.STORAGE_KEYS.save; }

    /* --- Validacion -------------------------------------------------------- */
    validate(data) {
      if (!data || typeof data !== 'object') return false;
      if (data.v !== TN.Config.SCHEMA_VERSION) return false;
      if (typeof data.seed !== 'number') return false;
      if (!data.player || typeof data.player.x !== 'number') return false;
      if (!data.inventory || !data.inventory.resources) return false;
      if (typeof data.day !== 'number' || data.day < 1) return false;
      return true;
    }

    hasValidSave() {
      try {
        const raw = localStorage.getItem(this.key());
        if (!raw) return false;
        return this.validate(JSON.parse(raw));
      } catch (e) {
        return false;
      }
    }

    /* --- Guardado ---------------------------------------------------------- */
    save() {
      const g = this.game;
      if (!g.player || g.state === 'menu') return false;
      const data = {
        v: TN.Config.SCHEMA_VERSION,
        savedAt: Date.now(),
        seed: g.seed,
        day: g.dayNight.day,
        phase: g.dayNight.phase,
        timeLeft: isFinite(g.dayNight.timeLeft) ? g.dayNight.timeLeft : -1,
        phaseDuration: isFinite(g.dayNight.phaseDuration) ? g.dayNight.phaseDuration : -1,
        elapsed: g.dayNight.totalElapsed,
        nightsSurvived: g.dayNight.nightsSurvived,
        lastNight: g.dayNight.lastNight || 0,
        player: g.player.serialize(),
        inventory: g.inventory.serialize(),
        upgrades: g.upgrades.serialize(),
        world: {
          nodes: g.resources.serialize(),
          pois: g.world.pois.map(p => ({ id: p.id, discovered: p.discovered, taken: p.taken }))
        },
        buildings: g.buildings.serialize(),
        generator: { hp: g.generator.hp },
        quests: g.quests.serialize(),
        // Los jefes NO se guardan como enemigos normales: su tipo base
        // ('brute', 'runner'...) perderia isBoss, sus fases y su nombre.
        enemies: g.enemies.list.filter(e => !e.dead && !e.isBoss).map(e => ({
          t: e.type, x: Math.round(e.x), y: Math.round(e.y),
          hp: Math.round(e.hp), el: e.isElite ? 1 : 0
        })),
        // Jefe en combate: se guarda aparte para poder restaurarlo como jefe.
        bossActive: (function () {
          const b = g.getActiveBoss();
          if (!b) return null;
          return { id: b.bossId, x: Math.round(b.x), y: Math.round(b.y), hp: Math.round(b.hp) };
        })(),
        bosses: Object.assign({}, g.bossesDefeated),
        events: g.events.serialize(),
        stats: Object.assign({}, g.stats),
        collected: Object.assign({}, g.inventory.collected),
        finalBossDefeated: !!g.finalBossDefeated,
        buildMode: g.buildMode || null
      };
      try {
        localStorage.setItem(this.key(), JSON.stringify(data));
        this.dirty = false;
        this.lastSave = g.time;
        return true;
      } catch (e) {
        console.warn('[TN] no se pudo guardar la partida', e);
        return false;
      }
    }

    /* --- Carga -------------------------------------------------------------- */
    load() {
      const g = this.game;
      let data = null;
      try {
        const raw = localStorage.getItem(this.key());
        if (!raw) return null;
        data = JSON.parse(raw);
      } catch (e) {
        console.warn('[TN] partida corrupta, se ignora', e);
        return null;
      }
      if (!this.validate(data)) {
        console.warn('[TN] partida incompatible con esta version');
        return null;
      }
      return data;
    }

    clear() {
      try { localStorage.removeItem(this.key()); } catch (e) { /* ignore */ }
    }

    /* Aplica los datos guardados a una partida recien construida. */
    apply(data) {
      const g = this.game;
      g.seed = data.seed;
      g.buildWorld(data.seed);

      g.dayNight.restore({
        day: data.day,
        phase: data.phase,
        timeLeft: data.timeLeft,
        phaseDuration: data.phaseDuration,
        totalElapsed: data.elapsed,
        nightsSurvived: data.nightsSurvived,
        lastNight: data.lastNight
      });
      g.inventory.restore(data.inventory);
      g.upgrades.restore(data.upgrades);
      // Se reutiliza el jugador ya creado (no se instancia otro): la posicion
      // y la vida se restauran justo debajo.
      if (!g.player) g.player = new TN.Player(g, data.player.x, data.player.y);
      g.player.inventory = g.inventory;
      g.applyResearchToPlayer();
      g.player.restore(data.player);
      g.applyUpgradesToPlayer();

      g.resources.restore(data.world && data.world.nodes);
      if (data.world && data.world.pois) {
        for (const rec of data.world.pois) {
          const p = g.world.pois.find(x => x.id === rec.id);
          if (p) { p.discovered = !!rec.discovered; p.taken = !!rec.taken; }
        }
      }
      g.buildings.restore(data.buildings, g);
      if (data.generator) g.generator.hp = data.generator.hp;
      g.quests.restore(data.quests);
      g.bossesDefeated = Object.assign({}, data.bosses || {});
      g.finalBossDefeated = !!data.finalBossDefeated;
      g.stats = Object.assign({ kills: 0, nights: 0, bosses: 0, time: 0 }, data.stats || {});
      if (data.collected) g.inventory.collected = Object.assign({ wood: 0, stone: 0, scrap: 0, herbs: 0 }, data.collected);
      g.events.restore(data.events, g);
      g.buildMode = data.buildMode || null;

      // Enemigos: se reconstruyen desde cero para no duplicar
      g.enemies.clear();
      if (Array.isArray(data.enemies)) {
        const diff = TN.Config.difficultyFor(g.dayNight.day);
        for (const rec of data.enemies) {
          if (U.dist(rec.x, rec.y, g.player.x, g.player.y) < 70) continue;
          const e = g.enemies.spawn(rec.t, rec.x, rec.y, { diff: diff, elite: !!rec.el });
          if (e) e.hp = rec.hp;
        }
      }
      // Jefe en combate: se restaura como jefe (con sus fases), no como
      // un enemigo normal del tipo base.
      if (data.bossActive && TN.Bosses.BOSSES[data.bossActive.id]) {
        const rec = data.bossActive;
        const boss = TN.Bosses.spawnBoss(g, rec.id, rec.x, rec.y);
        if (boss) boss.hp = Math.max(1, Math.min(rec.hp, boss.maxHp));
      }
      g.camera.snapTo(g.player.x, g.player.y);
      g.lighting.collect(g);
      return true;
    }
  }

  return SaveManager;
})();
