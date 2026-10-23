/* ==========================================================================
   30 NOCHES - game.js
   Estados generales, bucle principal, coordinacion de sistemas y reglas
   de la campana (dia/noche, oleadas, jefes, victoria y derrota).
   ========================================================================== */
window.TN = window.TN || {};

TN.Game = (function () {
  const U = TN.Utils;
  const CFG = TN.Config;

  class Game {
    constructor(canvas) {
      this.canvas = canvas;
      this.ctx = canvas.getContext('2d', { alpha: false });
      this.dpr = 1;
      this.viewW = 800; this.viewH = 600;

      this.input = new TN.Input(canvas);
      this.audio = new TN.Audio();
      this.progression = new TN.Progression();
      this.particles = new TN.Particles();
      this.lighting = new TN.Lighting.System();
      this.ui = new TN.UI(this);
      this.saveMgr = new TN.Save(this);
      this.save = this.saveMgr;      // alias comodo para los modulos

      this.state = 'menu';            // menu | playing | paused | gameOver | victory
      this.time = 0;
      this.fps = 60;
      this.weather = { storm: 0, fog: 0, blackout: 0 };
      // El ciclo dia/noche tambien existe en el menu: sin el, lighting.ambient()
      // reventaba en el primer frame y el bucle rAF se quedaba muerto (pantalla negra).
      this.dayNight = new TN.DayNight();
      this.effects = [];
      this.floaters = [];
      this.bossesDefeated = {};
      this.finalBossDefeated = false;
      this.buildMode = null;
      this.buildGhost = { x: 0, y: 0, valid: false };
      this.waveMultiplier = 1;
      this.waveTimer = 6;
      this.dayEncounterTimer = 25;
      this.interactCd = 0;
      this.autosaveTimer = 0;
      this.stats = { kills: 0, nights: 0, bosses: 0, time: 0, rp: 0 };
      this.currentDiff = TN.Config.difficultyFor(1);
      this.running = false;
      this.debugShowHitbox = false;

      this.applyOptions();
      this.buildWorld((Math.random() * 0xffffffff) >>> 0);
      this.camera = new TN.Camera(this.world);
      this.camera.setViewport(this.viewW, this.viewH);
      this.camera.snapTo(this.world.base.x, this.world.base.y);

      this.bindResize();
      this.ui.refreshMainMeta();
      this.ui.open('main');
      this.ui.setHudVisible(false);
      this.ui.el.overlay.style.display = 'flex';
    }

    /* ================= Opciones y arranque ================= */
    applyOptions() {
      const o = this.progression.options;
      this.audio.setVolume(o.volume === undefined ? 0.6 : o.volume);
      this.audio.setMuted(!!o.muted);
      TN.Config.DEBUG.cycleScale = o.cycleScale || 1;
      TN.Config.DEBUG.showCoords = !!o.showCoords;
      const params = new URLSearchParams(location.search);
      if (params.get('debug') === '1') TN.Config.DEBUG.enabled = true;
    }

    bindResize() {
      const self = this;
      this._onResize = function () { self.resize(); };
      window.addEventListener('resize', this._onResize);
      window.addEventListener('orientationchange', this._onResize);
      this.resize();
    }

    resize() {
      const w = Math.max(320, window.innerWidth);
      const h = Math.max(240, window.innerHeight);
      this.dpr = Math.min(window.devicePixelRatio || 1, 2);
      this.canvas.width = Math.floor(w * this.dpr);
      this.canvas.height = Math.floor(h * this.dpr);
      this.canvas.style.width = w + 'px';
      this.canvas.style.height = h + 'px';
      this.viewW = w; this.viewH = h;
      if (this.camera) { this.camera.setViewport(w, h); this.camera.clampToWorld(); }
    }

    start() {
      if (this.running) return;
      this.running = true;
      const self = this;
      let last = performance.now();
      function frame(ts) {
        let dt = (ts - last) / 1000;
        last = ts;
        if (!(dt > 0)) dt = 0.0001;
        if (dt > 0.1) dt = 0.1;            // limita saltos tras perder el foco
        self.fps = self.fps * 0.92 + (1 / dt) * 0.08;
        try {
          self.update(dt);
        } catch (e) {
          // Una excepcion en un solo fotograma no puede congelar el juego:
          // se registra y el bucle sigue vivo.
          console.error('[TN] error en el bucle principal', e);
        } finally {
          // endFrame() siempre se llama: si no, los flags justPressed se
          // quedan pegados y el juego responde a teclas antiguas.
          self.input.endFrame();
          requestAnimationFrame(frame);
        }
      }
      requestAnimationFrame(frame);
    }

    /* ================= Construccion del mundo ================= */
    buildWorld(seed) {
      this.seed = seed >>> 0;
      this.world = new TN.World(this.seed).generate();
      this.resources = new TN.Resources.Manager(this.world);
      this.navigator = new TN.EnemyAI.Navigator(this.world);
      this.buildings = new TN.Buildings.Manager(this.world);
      this.quests = new TN.Quests(this.world);
      this.enemies = new TN.Enemies.Manager();
      if (!this.projectiles) this.projectiles = new TN.Projectiles.Manager();
      this.projectiles.clear();
      this.particles.clear();
      this.effects.length = 0;
      this.floaters.length = 0;

      this.generator = {
        x: this.world.generator.x, y: this.world.generator.y,
        hp: CFG.GENERATOR.hp, maxHp: CFG.GENERATOR.maxHp,
        dead: false, hitFlash: 0
      };
      this.world.addObstacle({
        kind: 'generator', x: this.generator.x, y: this.generator.y,
        shape: 'rect', hw: CFG.GENERATOR.w / 2, hh: CFG.GENERATOR.h / 2, solid: true
      });
      this.world.addObstacle({
        kind: 'antenna', x: this.quests.antenna.x, y: this.quests.antenna.y,
        shape: 'rect', hw: 12, hh: 12, solid: true
      });
      this.world.rebuildNav();
    }

    /* ================= Ciclo de partida ================= */
    startNewGame() {
      this.audio.init();
      // Se borra el guardado anterior: si se cierra la pestaña antes del
      // siguiente autoguardado, "Continuar" no debe restaurar la partida vieja.
      this.saveMgr.clear();
      const seed = (Math.random() * 0xffffffff) >>> 0;
      this.beginRun(seed, null);
    }

    continueGame() {
      this.audio.init();
      const data = this.saveMgr.load();
      if (!data) {
        this.ui.toast('No hay ninguna partida guardada valida', 'error');
        this.ui.refreshMainMeta();
        return;
      }
      this.beginRun(data.seed, data);
    }

    beginRun(seed, saveData) {
      this.state = 'playing';
      this.inventory = new TN.Inventory();
      this.dayNight = new TN.DayNight();
      this.upgrades = new TN.Upgrades.Manager();
      this.events = new TN.Events.Manager();
      this.buildWorld(seed);

      this.player = new TN.Player(this, this.world.base.x, this.world.base.y + 150);
      this.player.inventory = this.inventory;
      this.stats = { kills: 0, nights: 0, bosses: 0, time: 0, rp: 0 };
      this.bossesDefeated = {};
      this.finalBossDefeated = false;
      this.buildMode = null;
      this.weather = { storm: 0, fog: 0, blackout: 0 };
      this.waveMultiplier = 1;
      this.waveTimer = 8;
      this.dayEncounterTimer = 30;
      this.currentDiff = TN.Config.difficultyFor(1);
      this._stockApplied = false;

      if (saveData) {
        this.saveMgr.apply(saveData);
      } else {
        this.applyResearchToPlayer();
        this.applyResearchToRun();
        this.dayNight.startPhase('day', null);
      }

      this.camera = new TN.Camera(this.world);
      this.camera.setViewport(this.viewW, this.viewH);
      this.camera.snapTo(this.player.x, this.player.y);
      this.lighting.collect(this);

      this.ui.close();
      this.ui.setHudVisible(true);
      this.ui.refreshMainMeta();
      this.ui.refreshHotbar();
      if (!saveData) {
        this.ui.toast('Dia 1. Explora el bosque, recoge materiales y prepara el refugio.', 'info');
      } else {
        this.ui.toast('Partida recuperada: dia ' + this.dayNight.day, 'info');
      }
      this.saveMgr.markDirty();
    }

    toMainMenu() {
      this.state = 'menu';
      this.ui.setHudVisible(false);
      this.ui.open('main');
      this.ui.refreshMainMeta();
      this.input.clear();
    }

    abandonRun() {
      this.saveMgr.clear();
      this.ui.toast('Expedicion abandonada', 'info');
      this.toMainMenu();
    }

    /* ================= Multiplicadores ================= */
    getHarvestMultiplier() {
      return this.upgrades.harvestMultiplier() * this.progression.harvestBonus();
    }
    getCostMultiplier() {
      return this.upgrades.costMultiplier() * this.progression.craftBonus();
    }
    getAmmoMultiplier() { return this.upgrades.ammoMultiplier(); }

    applyResearchToPlayer() {
      if (!this.player) return;
      const base = CFG.PLAYER.maxHp + this.progression.maxHpBonus();
      const bonus = this.upgrades && this.upgrades.has('maxhp') ? 25 : 0;
      const newMax = base + bonus;
      if (newMax > this.player.maxHp) {
        this.player.hp += (newMax - this.player.maxHp);
        this.player.maxHp = newMax;
      }
    }

    applyUpgradesToPlayer() { this.applyResearchToPlayer(); }

    applyResearchToRun() {
      if (!this.inventory || this._stockApplied) return;
      this._stockApplied = true;
      const lvl = this.progression.get('stock');
      if (lvl > 0) {
        this.inventory.addResource('wood', 6 * lvl);
        this.inventory.addResource('scrap', 4 * lvl);
        this.inventory.addResource('herbs', lvl);
      }
    }

    /* ================= Bucle ================= */
    update(dt) {
      this.time += dt;
      this.ui.update(dt);
      this.handleHotkeys();

      if (this.state === 'playing') {
        if (this.ui.current) {
          // Menú abierto: la simulación se detiene, la previsualización no.
          this.updateBuildPreview(dt);
        } else {
          this.simulate(dt);
        }
      } else if (this.state === 'menu') {
        this.previewCamera(dt);
      }
      this.render();
    }

    simulate(dt) {
      const dn = this.dayNight;
      this.currentDiff = TN.Config.difficultyFor(dn.day);
      dn.update(dt, this);
      if (this.player && !this.player.dead) this.player.update(dt, this);

      for (const e of this.enemies.list) {
        if (e.dead) continue;
        if (e.isBoss && e.boss) TN.Bosses.updateBoss(this, e, dt);
        else TN.EnemyAI.updateEnemy(this, e, dt);
      }
      this.enemies.removeDead();
      this.buildings.update(dt, this);
      this.projectiles.update(dt, this);
      this.particles.update(dt, this);
      this.events.update(dt, this);
      this.lighting.collect(this);
      this.updateFloaters(dt);
      this.updateEffects(dt);
      this.updateWaves(dt);
      this.handleInteraction(dt);
      this.camera.follow(this.player.x, this.player.y, dt);
      this.camera.updateShake(dt);

      this.autosaveTimer += dt;
      if (this.autosaveTimer >= this.saveMgr.autoInterval) {
        this.autosaveTimer = 0;
        this.saveMgr.save();
      }
    }

    updateFloaters(dt) {
      for (let i = this.floaters.length - 1; i >= 0; i--) {
        const f = this.floaters[i];
        f.life -= dt;
        f.y += f.vy * dt;
        f.vy *= 0.92;
        if (f.life <= 0) this.floaters.splice(i, 1);
      }
    }

    updateEffects(dt) {
      for (let i = this.effects.length - 1; i >= 0; i--) {
        const fx = this.effects[i];
        fx.life -= dt;
        if (fx.life <= 0) this.effects.splice(i, 1);
      }
    }

    previewCamera(dt) {
      // Camara lenta panoramica sobre el bosque del menu
      this.camera.targetX = this.world.base.x + Math.sin(this.time * 0.08) * 380;
      this.camera.targetY = this.world.base.y + Math.cos(this.time * 0.06) * 300;
      const k = 1 - Math.exp(-2 * dt);
      this.camera.x += (this.camera.targetX - this.camera.x) * k;
      this.camera.y += (this.camera.targetY - this.camera.y) * k;
      this.camera.clampToWorld();
      this.lighting.collect(this);
    }

    render() {
      TN.Renderer.draw(this.ctx, this);
    }

    /* ================= Teclas globales ================= */
    handleHotkeys() {
      const inp = this.input;
      // Con la partida en marcha o en pausa se pueden usar los menus.
      const menusOk = (this.state === 'playing' || this.state === 'paused');
      if (menusOk) {
        if (inp.wasPressed('Escape')) {
          if (this.ui.current) {
            // Cerrar el panel de construccion cancela tambien el modo
            // construccion (el hint dice "Esc para cancelar").
            if (this.ui.current === 'build') this.buildMode = null;
            if (this.ui.current !== 'upgrade') this.ui.close();
          } else {
            this.ui.open('pause');
          }
        }
        if (inp.wasPressed('KeyB')) {
          if (this.ui.current === 'build') { this.ui.close(); this.buildMode = null; }
          else { this.ui.open('build'); this.ui.refreshBuild(); }
        }
        if (inp.wasPressed('KeyC')) {
          if (this.ui.current === 'craft') this.ui.close();
          else { this.ui.open('craft'); this.ui.refreshCraft(); }
        }
      }
      if (this.state === 'playing') {
        if (inp.wasPressed('KeyF') && this.player) this.player.toggleFlashlight(this);
        if (inp.wasPressed('KeyQ') && this.player) this.cycleWeapon();
        if (inp.wasPressed('KeyM')) {
          this.ui.minimapBig = !this.ui.minimapBig;
          this.ui.el.minimapWrap.classList.toggle('big', this.ui.minimapBig);
        }
        for (let i = 0; i < 4; i++) {
          if (inp.wasPressed('Digit' + (i + 1))) this.useHotbar(i);
        }
      }
      if (TN.Config.DEBUG.enabled) this.handleDebugKeys();
    }

    cycleWeapon() {
      const list = this.inventory.weapons;
      if (list.length < 2) return;
      const idx = list.indexOf(this.inventory.equipped);
      const next = list[(idx + 1) % list.length];
      this.inventory.equip(next);
      this.ui.toast('Arma: ' + TN.Weapons.get(next).name, 'info');
      this.audio.play('ui');
    }

    useHotbar(slot) {
      const id = this.inventory.hotbar[slot];
      if (!id || !this.player) return;
      if (id === 'flashlight') { this.player.toggleFlashlight(this); return; }
      if (!this.inventory.hasItem(id)) {
        this.ui.toast('No tienes: ' + id, 'warn');
        return;
      }
      if (id === 'medkit') {
        if (this.player.hp >= this.player.maxHp) { this.ui.toast('Vida al maximo', 'info'); return; }
        const heal = 45 * this.upgrades.healMultiplier();
        this.player.hp = Math.min(this.player.maxHp, this.player.hp + heal);
        this.inventory.removeItem(id, 1);
        this.ui.toast('+' + Math.round(heal) + ' de vida', 'good');
        this.audio.play('pickup');
        this.particles.burst(this.player.x, this.player.y, 12, { color: '#8fe36a', speed: 100, life: 0.5 });
      } else if (id === 'repairkit') {
        // useRepairKit() ya consume el kit cuando la reparacion tiene exito.
        // Si no hay nada que reparar, el kit NO se gasta.
        this.useRepairKit();
      } else if (id === 'grenade') {
        this.inventory.removeItem(id, 1);
        const w = TN.Weapons.get('grenade');
        const ang = this.player.aimAngle;
        this.projectiles.spawn({
          x: this.player.x + Math.cos(ang) * 14, y: this.player.y + Math.sin(ang) * 14,
          vx: Math.cos(ang) * w.speed, vy: Math.sin(ang) * w.speed, speed: w.speed,
          damage: w.damage, color: w.color, size: 5, kind: 'grenade',
          friendly: true, life: 1.4, blastRadius: w.blastRadius
        });
        this.audio.play('swing');
      }
      this.ui.refreshHotbar();
      this.saveMgr.markDirty();
    }

    useRepairKit() {
      const pl = this.player;
      // 1) Generador
      if (U.dist(pl.x, pl.y, this.generator.x, this.generator.y) < 70 && this.generator.hp < this.generator.maxHp) {
        this.generator.hp = Math.min(this.generator.maxHp, this.generator.hp + 120);
        this.inventory.removeItem('repairkit', 1);
        this.ui.toast('Generador reparado (+120)', 'good');
        this.audio.play('build');
        return true;
      }
      // 2) Estructura danada mas cercana
      let best = null, bd = Infinity;
      for (const b of this.buildings.list) {
        if (b.dead || b.hp >= b.maxHp) continue;
        const d = U.dist(pl.x, pl.y, b.x, b.y);
        if (d < 70 && d < bd) { bd = d; best = b; }
      }
      if (best) {
        best.hp = Math.min(best.maxHp, best.hp + 120);
        this.inventory.removeItem('repairkit', 1);
        this.ui.toast(best.name + ' reparada', 'good');
        this.audio.play('build');
        return true;
      }
      // 3) Antena: NO se repara con kits. La antena exige los 3 componentes
      // y 20 chatarra + 10 piedra (quests.repairAntenna), asi que el kit no
      // puede saltarse el objetivo de campana. Se repara interactuando con E.
      this.ui.toast('No hay nada que reparar cerca', 'warn');
      return false;
    }

    /* ================= Interaccion ================= */
    handleInteraction(dt) {
      this.interactCd -= dt;
      const target = this.getInteractTarget();
      this.ui.setPrompt(target ? target.text : null);
      if (!target) return;
      if (target.type === 'node') {
        if (this.input.isDown('KeyE') && this.interactCd <= 0) {
          this.interactCd = CFG.PLAYER.harvestCd;
          this.harvest(target.node);
        }
      } else if (this.input.wasPressed('KeyE')) {
        this.doInteract(target);
      }
    }

    getInteractTarget() {
      const pl = this.player;
      if (!pl || pl.dead) return null;

      const ant = this.quests.antenna;
      if (U.dist(pl.x, pl.y, ant.x, ant.y) < 46) {
        if (ant.activated) return { type: 'antenna', text: 'La senal ya se ha enviado' };
        if (!ant.repaired) {
          const miss = this.quests.missingComponents();
          return {
            type: 'antenna',
            text: '<b>E</b> Reparar antena &nbsp;<span style="opacity:.7">' +
              (miss.length ? 'Faltan: ' + miss.join(', ') : 'Faltan materiales: 20 chatarra, 10 piedra') +
              '</span>'
          };
        }
        if (!this.finalBossDefeated) {
          return { type: 'antenna', text: '<b>E</b> Activar senal <span style="opacity:.7">(derrota antes a la Entidad)</span>' };
        }
        if (this.dayNight.day < CFG.CAMPAIGN_DAYS) {
          return { type: 'antenna', text: '<b>E</b> Activar senal <span style="opacity:.7">(disponible en la noche ' + CFG.CAMPAIGN_DAYS + ')</span>' };
        }
        return { type: 'antenna', text: '<b>E</b> Activar la senal de rescate' };
      }

      const gen = this.generator;
      if (!gen.dead && U.dist(pl.x, pl.y, gen.x, gen.y) < 56) {
        const cost = CFG.GENERATOR.repairCost;
        const missing = this.inventory.missingFor(cost);
        let extra = '';
        if (Object.keys(missing).length) extra = ' <span style="color:#e05a4a">(faltan materiales)</span>';
        else if (gen.hp >= gen.maxHp) extra = ' <span style="opacity:.6">(sin danos)</span>';
        return {
          type: 'generator',
          text: '<b>E</b> Reparar generador: ' + cost.wood + ' madera, ' + cost.scrap + ' chatarra' + extra
        };
      }

      for (const p of this.world.pois) {
        const c = p.container;
        if (U.dist(pl.x, pl.y, c.x, c.y) < 48) {
          if (p.taken) return { type: 'poi', poi: p, text: p.name + ' <span style="opacity:.6">(ya saqueado)</span>' };
          return { type: 'poi', poi: p, text: '<b>E</b> Recoger: ' + p.componentName };
        }
      }

      for (const b of this.buildings.list) {
        if (b.dead) continue;
        if (U.dist(pl.x, pl.y, b.x, b.y) > 46) continue;
        if (b.type === 'door') {
          return { type: 'door', building: b, text: '<b>E</b> ' + (b.open ? 'Cerrar' : 'Abrir') + ' la puerta' };
        }
        if (b.type === 'bench') {
          return { type: 'bench', building: b, text: '<b>E</b> Recargar torretas y linterna (1 chatarra)' };
        }
        if (b.type === 'forge') {
          return { type: 'forge', building: b, text: '<b>E</b> Forno: consulta las recetas de alto nivel (C)' };
        }
      }

      const node = this.resources.nearest(pl.x, pl.y, CFG.PLAYER.interactRange);
      if (node) {
        const info = TN.Resources.KIND_INFO[node.kind];
        return { type: 'node', node: node, text: '<b>E</b> ' + info.verb + ' ' + info.label.toLowerCase() };
      }
      return null;
    }

    doInteract(target) {
      switch (target.type) {
        case 'poi':
          this.quests.collect(target.poi, this);
          break;
        case 'generator': {
          const gen = this.generator;
          if (gen.hp >= gen.maxHp) { this.ui.toast('El generador no tiene danos', 'info'); return; }
          const cost = CFG.GENERATOR.repairCost;
          if (!this.inventory.canAfford(cost)) {
            this.ui.toast('Faltan materiales para reparar', 'error');
            this.audio.play('error');
            return;
          }
          this.inventory.spend(cost);
          gen.hp = Math.min(gen.maxHp, gen.hp + CFG.GENERATOR.repairAmount);
          this.ui.toast('Generador reparado (+' + CFG.GENERATOR.repairAmount + ')', 'good');
          this.audio.play('build');
          this.particles.burst(gen.x, gen.y, 14, { color: '#ffb066', speed: 120, life: 0.5 });
          this.saveMgr.markDirty();
          break;
        }
        case 'antenna':
          if (!this.quests.antenna.repaired) {
            this.quests.repairAntenna(this);
          } else {
            this.quests.activateAntenna(this);
          }
          break;
        case 'door': {
          const b = target.building;
          b.open = !b.open;
          if (b.obstacle) b.obstacle.passableForPlayer = b.open;
          this.audio.play('ui');
          break;
        }
        case 'bench':
          this.buildings.serviceBench(this);
          break;
        case 'forge':
          this.ui.open('craft');
          this.ui.refreshCraft();
          break;
        default: break;
      }
    }

    harvest(node) {
      if (!node || node.depleted) return;
      const gain = this.resources.harvest(node, this);
      if (!gain) return;
      let txt = [];
      for (const k in gain) {
        this.inventory.addResource(k, gain[k]);
        txt.push('+' + gain[k] + ' ' + (TN.Inventory.RES_NAMES[k] || k).toLowerCase());
      }
      this.ui.toast(txt.join('   '), 'good');
      TN.Combat.floatText(this, node.x, node.y - 16, txt.join(' '), '#ffe9a8', 12);
      this.audio.play('pickup');
      this.particles.burst(node.x, node.y, 9, { color: '#c9a06a', speed: 100, life: 0.4, shape: 'circle' });
      if (node.depleted && node.kind === 'wood') {
        this.particles.burst(node.x, node.y, 14, { color: '#7fb05a', speed: 150, life: 0.6 });
      }
      this.ui.refreshHotbar();
      this.saveMgr.markDirty();
    }

    /* ================= Construccion ================= */
    selectBuildType(type) {
      this.buildMode = type;
      this.ui.refreshBuild();
    }

    updateBuildPreview(dt) {
      if (this.ui.current !== 'build') return;
      if (!this.buildMode) return;
      const m = this.input.mouse;
      const w = this.camera.screenToWorld(m.x, m.y);
      const t = CFG.WORLD.tile;
      const gx = Math.round(w.x / t) * t;
      const gy = Math.round(w.y / t) * t;
      const changed = (gx !== this.buildGhost.x || gy !== this.buildGhost.y || this.buildGhost.type !== this.buildMode);
      this.buildGhost.x = gx; this.buildGhost.y = gy; this.buildGhost.type = this.buildMode;
      // Comprobaciones baratas en cada fotograma; la de acceso a la base
      // (un recorrido de la cuadricula) solo cuando cambia la casilla.
      const check = this.buildings.validate(this, this.buildMode, gx, gy, { fast: true });
      let valid = check.ok;
      let reason = check.reason;
      if (valid && changed) {
        if (!this.buildings.checkAccess(this, this.buildMode, gx, gy)) {
          valid = false;
          reason = 'Bloquearia el acceso a la base';
        }
      }
      this.buildGhost.valid = valid;
      this.buildGhost.reason = reason;
      if (m.justDown) {
        if (this.buildGhost.valid) {
          this.buildings.place(this, this.buildMode, gx, gy);
          this.ui.refreshBuild();
        } else {
          this.ui.toast(this.buildGhost.reason || 'No se puede construir aqui', 'error');
          this.audio.play('error');
        }
      }
    }

    /* ================= Oleadas ================= */
    updateWaves(dt) {
      const dn = this.dayNight;
      if (dn.phase === 'night') {
        this.waveTimer -= dt;
        if (this.waveTimer <= 0) {
          this.waveTimer = this.currentDiff.waveInterval / Math.max(0.4, this.waveMultiplier);
          this.spawnWave();
        }
      } else if (dn.phase === 'day') {
        this.dayEncounterTimer -= dt;
        if (this.dayEncounterTimer <= 0) {
          this.dayEncounterTimer = 26 + Math.random() * 26;
          if (this.enemies.aliveCount < 5) this.spawnDayEncounter();
        }
      }
    }

    spawnWave() {
      const diff = this.currentDiff;
      const count = Math.max(1, Math.round(diff.waveSize * (0.7 + Math.random() * 0.6) * this.waveMultiplier));
      for (let i = 0; i < count; i++) {
        if (this.enemies.aliveCount >= CFG.WAVES.maxEnemies) break;
        const type = diff.types[Math.floor(Math.random() * diff.types.length)];
        // A partir de la noche 19 algunos enemigos de la oleada pueden ser
        // variantes de élite (dificultad.eliteChance).
        const elite = (diff.eliteChance || 0) > 0 && Math.random() < diff.eliteChance;
        const pos = this.findSpawnPoint();
        const e = this.enemies.spawn(type, pos.x, pos.y, { diff: diff, elite: elite });
        if (e) {
          e.spawnAnim = 0.5;
          this.particles.burst(e.x, e.y, 6, { color: '#5a3a5a', speed: 90, life: 0.4 });
        }
      }
    }

    spawnDayEncounter() {
      const diff = this.currentDiff;
      const n = 1 + Math.floor(Math.random() * 2);
      for (let i = 0; i < n; i++) {
        const type = diff.types[0];
        const pos = this.findSpawnPoint();
        if (!pos) continue;
        this.enemies.spawn(type, pos.x, pos.y, { diff: diff });
      }
    }

    findSpawnPoint() {
      for (let i = 0; i < CFG.WAVES.spawnTryLimit; i++) {
        const ang = Math.random() * Math.PI * 2;
        // Nunca dentro del radio "seguro" de la base.
        const d = Math.max(CFG.BASE.baseRadius, CFG.WAVES.minSpawnDistance + Math.random() * 320);
        let x = this.world.base.x + Math.cos(ang) * d;
        let y = this.world.base.y + Math.sin(ang) * d;
        x = U.clamp(x, 50, this.world.width - 50);
        y = U.clamp(y, 50, this.world.height - 50);
        if (this.world.navBlockedAt(x, y)) continue;
        if (this.player && U.dist(x, y, this.player.x, this.player.y) < 320) continue;
        return { x: x, y: y };
      }
      return this.world.randomOpenPoint(U.makeRng((Math.random() * 1e9) >>> 0), 500);
    }

    /* ================= Luz ================= */
    findLightTarget(x, y, range) {
      let best = null, bd = range * range;
      for (const l of this.lighting.lights) {
        const d = U.dist2(x, y, l.x, l.y);
        if (d < bd) { bd = d; best = l; }
      }
      return best;
    }

    getActiveBoss() {
      for (const e of this.enemies.list) {
        if (!e.dead && e.isBoss) return e;
      }
      return null;
    }

    /* ================= Fases, jefes y final ================= */
    onPhaseChange(phase) {
      if (phase === 'night') this.onNightStart();
      else if (phase === 'day') this.onNightEnd();
      else if (phase === 'final') {
        // La noche agresiva termina con la noche: el multiplicador vuelve a 1.
        this.waveMultiplier = 1;
        this.ui.toast('La noche 30 ha pasado. Enciende la antena.', 'info');
      }
    }

    onNightStart() {
      const day = this.dayNight.day;
      this.audio.play('nightStart');
      this.ui.toast('Llega la noche ' + day + '. Prepara tus defensas.', 'warn');
      this.waveTimer = 3;
      // Jefe de la noche
      if (this.currentDiff.isBossNight) {
        const bossId = 'day' + day;
        if (!this.bossesDefeated[bossId] && TN.Bosses.BOSSES[bossId]) {
          const pos = this.findSpawnPoint();
          const boss = TN.Bosses.spawnBoss(this, bossId, pos.x, pos.y);
          if (boss) {
            const def = TN.Bosses.BOSSES[bossId];
            this.ui.showBossIntro(def.name, def.intro);
            this.audio.play('bossWarn');
            this.camera.addShake(6);
          }
        }
      }
      this.saveMgr.save();
    }

    onNightEnd() {
      const night = this.dayNight.lastNight || this.dayNight.day;
      this.audio.play('nightEnd');
      // La noche agresiva (evento instantaneo) solo dura esta noche.
      this.waveMultiplier = 1;
      const rp = 3 + Math.floor(night / 3);
      const scrap = 2 + Math.floor(night / 4);
      const herbs = 1 + Math.floor(night / 8);
      this.progression.addRp(rp);
      this.stats.rp += rp;
      this.inventory.addResource('scrap', scrap);
      this.inventory.addResource('herbs', herbs);
      this.stats.nights++;
      this.ui.toast('Noche ' + night + ' superada: +' + rp + ' RP, +' + scrap + ' chatarra, +' + herbs + ' hierbas', 'good');
      // Los enemigos se retiran al amanecer
      this.enemies.clear();
      this.projectiles.clear();
      // Mejora temporal por hitos
      if (night % 5 === 0 && !this.upgrades.pending) this.offerUpgrade();
      this.ui.refreshInventory();
      this.saveMgr.save();
      this.progression.save();
    }

    onBossDefeated(enemy) {
      this.stats.bosses++;
      const def = TN.Bosses.BOSSES[enemy.bossId];
      if (def) {
        this.progression.addRp(def.rp);
        this.stats.rp += def.rp;
        this.bossesDefeated[enemy.bossId] = true;
        this.ui.toast('Jefe derrotado: ' + enemy.name + ' (+' + def.rp + ' RP)', 'good');
      }
      if (enemy.bossId === 'day30') {
        this.finalBossDefeated = true;
        this.ui.toast('La Entidad ha caido. Ve a la antena y activa la senal.', 'good');
        // Deja de llover oleadas: queda el combate final
        this.dayNight.phase = 'final';
        this.dayNight.timeLeft = Infinity;
        this.dayNight.phaseDuration = Infinity;
      }
      this.offerUpgrade();
      this.saveMgr.save();
      this.progression.save();
    }

    offerUpgrade() {
      if (this.upgrades.pending) return;
      const list = this.upgrades.offer();
      if (!list) return;
      this.ui.open('upgrade');
    }

    onPlayerDeath(source) {
      if (this.state !== 'playing') return;
      this.state = 'gameOver';
      this.player.dead = true;
      this.audio.play('defeat');
      this.camera.addShake(10);
      this.particles.burst(this.player.x, this.player.y, 26, { color: '#a03030', speed: 200, life: 0.8 });
      const reason = source === 'enemy'
        ? 'Las criaturas te han alcanzado.'
        : 'El bosque no perdona.';
      this.finishRun(false, reason);
    }

    onGeneratorDestroyed() {
      if (this.state !== 'playing') return;
      this.state = 'gameOver';
      this.generator.dead = true;
      this.audio.play('defeat');
      this.camera.addShake(14);
      this.particles.burst(this.generator.x, this.generator.y, 50, { color: '#ff9a4a', speed: 300, life: 1.0, shape: 'circle' });
      this.finishRun(false, 'El generador ha sido destruido. Sin luz no hay refugio.');
    }

    onVictory() {
      if (this.state !== 'playing') return;
      this.state = 'victory';
      this.audio.play('victory');
      this.particles.burst(this.quests.antenna.x, this.quests.antenna.y, 60, { color: '#8be9ff', speed: 260, life: 1.4, shape: 'circle', glow: true });
      this.finishRun(true, '');
    }

    finishRun(victory, reason) {
      this.stats.time = this.dayNight.totalElapsed;
      const stats = {
        'Dia alcanzado': this.dayNight.day,
        'Tiempo': U.formatTime(this.dayNight.totalElapsed),
        'Noches superadas': this.stats.nights,
        'Enemigos derrotados': this.stats.kills,
        'Jefes derrotados': this.stats.bosses,
        'Madera': this.inventory.collected.wood,
        'Piedra': this.inventory.collected.stone,
        'Chatarra': this.inventory.collected.scrap,
        'Hierbas': this.inventory.collected.herbs,
        'RP obtenidos': this.stats.rp
      };
      this.progression.recordRun({
        day: this.dayNight.day,
        time: this.dayNight.totalElapsed,
        kills: this.stats.kills,
        bosses: this.stats.bosses,
        nights: this.stats.nights,
        victory: victory
      });
      this.progression.save();
      this.ui.refreshMainMeta();
      if (victory) {
        this.ui.showVictory(stats);
        this.saveMgr.clear();
      } else {
        this.ui.showGameOver(stats, reason);
        this.saveMgr.clear();
      }
    }

    /* ================= Utilidades ================= */
    canControl() {
      return this.state === 'playing' && !this.ui.current && this.player && !this.player.dead;
    }

    /* ================= Modo desarrollo ================= */
    handleDebugKeys() {
      const inp = this.input;
      if (inp.wasPressed('F1')) {
        TN.Config.DEBUG.showCoords = !TN.Config.DEBUG.showCoords;
        this.ui.toast('Coordenadas: ' + (TN.Config.DEBUG.showCoords ? 'ON' : 'OFF'), 'info');
      }
      if (inp.wasPressed('F2') && this.state === 'playing') {
        this.dayNight.skipPhase(this);
        this.ui.toast('Salto de fase (debug)', 'info');
      }
      if (inp.wasPressed('F3') && this.state === 'playing' && this.inventory) {
        this.inventory.addResource('wood', 50);
        this.inventory.addResource('stone', 50);
        this.inventory.addResource('scrap', 50);
        this.inventory.addResource('herbs', 20);
        this.ui.toast('Materiales de prueba anadidos', 'info');
      }
      if (inp.wasPressed('F4') && this.state === 'playing') {
        const diff = this.currentDiff;
        const ang = Math.random() * Math.PI * 2;
        const x = this.player.x + Math.cos(ang) * 260;
        const y = this.player.y + Math.sin(ang) * 260;
        this.enemies.spawn(diff.types[0], x, y, { diff: diff });
        this.ui.toast('Enemigo invocado', 'info');
      }
      if (inp.wasPressed('F5') && this.state === 'playing') {
        const id = 'day' + this.dayNight.day;
        const bossId = TN.Bosses.BOSSES[id] ? id : 'day5';
        const ang = Math.random() * Math.PI * 2;
        const x = this.player.x + Math.cos(ang) * 400;
        const y = this.player.y + Math.sin(ang) * 400;
        const boss = TN.Bosses.spawnBoss(this, bossId, x, y);
        if (boss) {
          this.ui.showBossIntro(boss.name, TN.Bosses.BOSSES[bossId].intro);
          this.ui.toast('Jefe invocado (debug)', 'info');
        }
      }
      if (inp.wasPressed('F6') && this.state === 'playing') {
        this.player.x = this.world.base.x;
        this.player.y = this.world.base.y + 150;
        this.camera.snapTo(this.player.x, this.player.y);
      }
      if (inp.wasPressed('F7')) {
        TN.Config.DEBUG.godMode = !TN.Config.DEBUG.godMode;
        this.ui.toast('Modo dios: ' + (TN.Config.DEBUG.godMode ? 'ON' : 'OFF'), 'info');
      }
    }
  }

  return Game;
})();
