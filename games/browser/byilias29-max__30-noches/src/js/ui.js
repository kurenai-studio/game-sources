/* ==========================================================================
   30 NOCHES - ui.js
   HUD, menus, notificaciones, minimapa y pantallas de final.
   Toda la interfaz es DOM real (botones y eventos de raton/teclado).
   ========================================================================== */
window.TN = window.TN || {};

TN.UI = (function () {
  const U = TN.Utils;

  const ITEM_ICONS = {
    medkit: '💊', repairkit: '🔧', grenade: '💣', flashlight: '🔦',
    axe: '🪓', spear: '🔱', bow: '🏹', pistol: '🔫', baton: '⚡', rifle: '🎯',
    pipe: '🔨', wall: '🧱', trap: '🪤', lamp: '💡', door: '🚪',
    bench: '🔨', turret: '🔫', forge: '🔥', arrows: '🏹',
    scrapAmmo: '🔩', rifleAmmo: '🔩'
  };

  const RECIPE_ICONS = {
    axe: '🪓', spear: '🔱', medkit: '💊', repairkit: '🔧', flashlight: '🔦',
    wall: '🧱', trap: '🪤', lamp: '💡', bow: '🏹', arrows: '🏹',
    pistol: '🔫', scrapAmmo: '🔩', bench: '🔨', door: '🚪', turret: '🔫',
    forge: '🔥', baton: '⚡', rifle: '🎯', rifleAmmo: '🔩', grenade: '💣'
  };

  const BUILD_ICONS = {
    wall: '🧱', trap: '🪤', lamp: '💡', door: '🚪', bench: '🔨', turret: '🔫', forge: '🔥'
  };

  class UISystem {
    constructor(game) {
      this.game = game;
      this.current = null;
      this.parent = null;
      this.toasts = [];
      this._hudTimer = 0;
      this._minimapTimer = 0;
      this.minimapBig = false;
      this.el = {};
      this._cache();
      this._wire();
    }

    _cache() {
      const id = (x) => document.getElementById(x);
      this.el = {
        hud: id('hud'),
        overlay: id('overlay'),
        hpFill: id('hpFill'), hpText: id('hpText'),
        batFill: id('batFill'), batText: id('batText'),
        weaponIcon: id('weaponIcon'), weaponName: id('weaponName'),
        dayText: id('dayText'), phaseText: id('phaseText'), timeFill: id('timeFill'),
        timeText: id('timeText'), threatText: id('threatText'),
        resWood: id('resWood'), resStone: id('resStone'), resScrap: id('resScrap'), resHerbs: id('resHerbs'),
        objectiveList: id('objectiveList'),
        bossWrap: id('bossWrap'), bossName: id('bossName'), bossTitle: id('bossTitle'), bossFill: id('bossFill'),
        bossIntro: id('bossIntro'), biName: id('biName'), biSub: id('biSub'),
        hotbar: id('hotbar'),
        prompt: id('prompt'),
        toasts: id('toasts'),
        damageFlash: id('damageFlash'),
        crosshair: id('crosshair'),
        debugInfo: id('debugInfo'),
        minimap: id('minimap'), minimapWrap: id('minimapWrap'),
        hudCenter: id('hudCenter'),
        mainMeta: id('mainMeta'),
        rpCount: id('rpCount'),
        craftList: id('craftList'), buildList: id('buildList'), buildTip: id('buildTip'),
        invRes: id('invRes'), invWeapons: id('invWeapons'), invItems: id('invItems'),
        researchList: id('researchList'), upgradeList: id('upgradeList'),
        gameOverStats: id('gameOverStats'), gameOverReason: id('gameOverReason'),
        victoryStats: id('victoryStats'), victoryText: id('victoryText'),
        panels: {
          main: id('panelMain'), pause: id('panelPause'), craft: id('panelCraft'),
          build: id('panelBuild'), upgrade: id('panelUpgrade'), research: id('panelResearch'),
          options: id('panelOptions'), controls: id('panelControls'), credits: id('panelCredits'),
          gameOver: id('panelGameOver'), victory: id('panelVictory')
        }
      };
      this.minimapCtx = this.el.minimap.getContext('2d');
    }

    _wire() {
      const g = this.game;
      const el = this.el;

      el.panels.main.querySelector('#btnNew').addEventListener('click', () => { g.audio.play('ui'); g.startNewGame(); });
      el.panels.main.querySelector('#btnContinue').addEventListener('click', () => { g.audio.play('ui'); g.continueGame(); });
      el.panels.main.querySelector('#btnResearch').addEventListener('click', () => { g.audio.play('ui'); this.open('research'); this.parent = 'main'; });
      el.panels.main.querySelector('#btnControls').addEventListener('click', () => { g.audio.play('ui'); this.open('controls'); this.parent = 'main'; });
      el.panels.main.querySelector('#btnOptions').addEventListener('click', () => { g.audio.play('ui'); this.open('options'); this.parent = 'main'; });
      el.panels.main.querySelector('#btnCredits').addEventListener('click', () => { g.audio.play('ui'); this.open('credits'); this.parent = 'main'; });

      el.panels.pause.querySelector('#btnResume').addEventListener('click', () => { g.audio.play('ui'); this.close(); });
      el.panels.pause.querySelector('#btnPauseCraft').addEventListener('click', () => { g.audio.play('ui'); this.open('craft'); this.parent = 'pause'; });
      el.panels.pause.querySelector('#btnPauseBuild').addEventListener('click', () => { g.audio.play('ui'); this.open('build'); this.parent = 'pause'; });
      el.panels.pause.querySelector('#btnPauseResearch').addEventListener('click', () => { g.audio.play('ui'); this.open('research'); this.parent = 'pause'; });
      el.panels.pause.querySelector('#btnPauseOptions').addEventListener('click', () => { g.audio.play('ui'); this.open('options'); this.parent = 'pause'; });
      el.panels.pause.querySelector('#btnPauseControls').addEventListener('click', () => { g.audio.play('ui'); this.open('controls'); this.parent = 'pause'; });
      el.panels.pause.querySelector('#btnAbandon').addEventListener('click', () => { g.audio.play('ui'); g.abandonRun(); });

      el.panels.options.querySelector('#btnCloseOptions').addEventListener('click', () => { g.audio.play('ui'); this.back(); });
      el.panels.controls.querySelector('#btnCloseControls').addEventListener('click', () => { g.audio.play('ui'); this.back(); });
      el.panels.credits.querySelector('#btnCloseCredits').addEventListener('click', () => { g.audio.play('ui'); this.back(); });
      el.panels.gameOver.querySelector('#btnRetry').addEventListener('click', () => { g.audio.play('ui'); g.startNewGame(); });
      el.panels.gameOver.querySelector('#btnGoMenu').addEventListener('click', () => { g.audio.play('ui'); g.toMainMenu(); });
      el.panels.victory.querySelector('#btnVictoryAgain').addEventListener('click', () => { g.audio.play('ui'); g.startNewGame(); });
      el.panels.victory.querySelector('#btnVictoryMenu').addEventListener('click', () => { g.audio.play('ui'); g.toMainMenu(); });

      // Pestanas de fabricacion
      el.panels.craft.querySelectorAll('.tab').forEach(function (tab) {
        tab.addEventListener('click', function () {
          el.panels.craft.querySelectorAll('.tab').forEach(t => t.classList.remove('on'));
          tab.classList.add('on');
          const which = tab.getAttribute('data-tab');
          document.getElementById('craftTabRecipes').classList.toggle('hidden', which !== 'recipes');
          document.getElementById('craftTabInv').classList.toggle('hidden', which !== 'inv');
          g.audio.play('ui');
        });
      });

      // Opciones
      const optVolume = el.panels.options.querySelector('#optVolume');
      const optVolumeVal = el.panels.options.querySelector('#optVolumeVal');
      optVolume.addEventListener('input', function () {
        optVolumeVal.textContent = optVolume.value + '%';
        g.progression.options.volume = optVolume.value / 100;
        g.audio.setVolume(optVolume.value / 100);
        g.progression.save();
      });
      const optMuted = el.panels.options.querySelector('#optMuted');
      optMuted.addEventListener('change', function () {
        g.progression.options.muted = optMuted.checked;
        g.audio.setMuted(optMuted.checked);
        g.progression.save();
      });
      const optCycle = el.panels.options.querySelector('#optCycle');
      optCycle.addEventListener('change', function () {
        const s = TN.Config.CYCLE_SCALES[optCycle.value] || 1;
        g.progression.options.cycleScale = s;
        TN.Config.DEBUG.cycleScale = s;
        g.progression.save();
        g.ui.toast('Duracion del ciclo cambiada', 'info');
      });
      const optScreenFx = el.panels.options.querySelector('#optScreenFx');
      optScreenFx.addEventListener('change', function () {
        g.progression.options.screenEffects = optScreenFx.checked;
        g.progression.save();
      });
      const optCoords = el.panels.options.querySelector('#optCoords');
      optCoords.addEventListener('change', function () {
        g.progression.options.showCoords = optCoords.checked;
        TN.Config.DEBUG.showCoords = optCoords.checked;
        g.progression.save();
      });
      const optDebug = el.panels.options.querySelector('#optDebug');
      optDebug.addEventListener('change', function () {
        TN.Config.DEBUG.enabled = optDebug.checked;
        g.ui.toast(optDebug.checked ? 'Modo desarrollo activado (F1 ayuda)' : 'Modo desarrollo desactivado', 'info');
      });
    }

    /* --- Paneles ---------------------------------------------------------- */
    open(name) {
      const g = this.game;
      for (const k in this.el.panels) this.el.panels[k].classList.add('hidden');
      const panel = this.el.panels[name];
      if (panel) panel.classList.remove('hidden');
      this.current = name;
      if (name === 'build') {
        this.el.overlay.className = 'mode-docked';
      } else if (name === 'main') {
        this.el.overlay.className = 'mode-menu';
      } else {
        this.el.overlay.className = 'mode-modal';
      }
      this.el.overlay.style.display = 'flex';
      g.audio.play('ui');
      if (name === 'pause' && g.state === 'playing') g.state = 'paused';
      if (name === 'main') this.refreshMainMeta();
      if (name === 'craft') this.refreshCraft();
      if (name === 'build') this.refreshBuild();
      if (name === 'research') this.refreshResearch();
      if (name === 'upgrade') this.refreshUpgrades();
      if (name === 'options') this.refreshOptions();
    }

    back() {
      const p = this.parent || (this.game.state === 'menu' ? 'main' : 'pause');
      this.parent = null;
      this.open(p);
    }

    close() {
      for (const k in this.el.panels) this.el.panels[k].classList.add('hidden');
      this.current = null;
      this.parent = null;
      this.el.overlay.className = 'mode-menu';
      this.el.overlay.style.display = 'none';
      if (this.game.state === 'paused') this.game.state = 'playing';
      this.game.input.clear();
    }

    setHudVisible(v) {
      this.el.hud.classList.toggle('hidden', !v);
      this.el.hud.setAttribute('aria-hidden', v ? 'false' : 'true');
      this.el.crosshair.classList.toggle('hidden', !v);
    }

    /* --- Notificaciones ---------------------------------------------------- */
    toast(msg, type) {
      const t = document.createElement('div');
      t.className = 'toast ' + (type || 'info');
      t.textContent = msg;
      this.el.toasts.appendChild(t);
      const entry = { el: t, life: 3.4 };
      this.toasts.push(entry);
      // Limite de notificaciones simultaneas
      while (this.toasts.length > 5) {
        const old = this.toasts.shift();
        if (old.el.parentNode) old.el.parentNode.removeChild(old.el);
      }
    }

    _updateToasts(dt) {
      for (let i = this.toasts.length - 1; i >= 0; i--) {
        const t = this.toasts[i];
        t.life -= dt;
        if (t.life <= 0) {
          t.el.classList.add('out');
          if (t.life < -0.5) {
            if (t.el.parentNode) t.el.parentNode.removeChild(t.el);
            this.toasts.splice(i, 1);
          }
        }
      }
    }

    /* --- HUD --------------------------------------------------------------- */
    update(dt) {
      const g = this.game;
      this._updateToasts(dt);
      // Un cambio de objetivos (componente recogido, antena reparada) se
      // refleja en el HUD en el acto.
      if (g.questsDirty) {
        g.questsDirty = false;
        this._updateHud();
      }
      this._hudTimer -= dt;
      if (this._hudTimer <= 0) {
        this._hudTimer = 0.12;
        this._updateHud();
      }
      this._minimapTimer -= dt;
      if (this._minimapTimer <= 0) {
        this._minimapTimer = 0.2;
        if (g.state === 'playing' || g.state === 'paused') this.drawMinimap();
      }
      // Destello de dano
      if (g.player && g.player.hurtFlash > 0) {
        this.el.damageFlash.style.opacity = Math.min(0.85, g.player.hurtFlash * 2).toFixed(2);
      } else {
        this.el.damageFlash.style.opacity = '0';
      }
      // Mira
      if (g.state === 'playing' && !this.current) {
        this.el.crosshair.style.left = g.input.mouse.screenX + 'px';
        this.el.crosshair.style.top = g.input.mouse.screenY + 'px';
      }
    }

    _updateHud() {
      const g = this.game;
      const pl = g.player;
      if (!pl) return;
      const inv = g.inventory;

      this.el.hpFill.style.width = U.clamp(pl.hp / pl.maxHp, 0, 1) * 100 + '%';
      this.el.hpText.textContent = Math.max(0, Math.ceil(pl.hp));

      const bat = pl.flashlightBattery / TN.Config.FLASHLIGHT.batteryMax;
      this.el.batFill.style.width = U.clamp(bat, 0, 1) * 100 + '%';
      this.el.batText.textContent = Math.round(bat * 100) + '%';
      this.el.batFill.style.background = pl.flashlightOn
        ? 'linear-gradient(90deg,#8a6a20,#f0d070)'
        : 'linear-gradient(90deg,#3a3a3a,#6a6a6a)';

      const w = TN.Weapons.get(inv.equipped);
      this.el.weaponName.textContent = w.name;
      this.el.weaponIcon.textContent = ITEM_ICONS[inv.equipped] || '🔨';

      const dn = g.dayNight;
      this.el.dayText.textContent = 'DIA ' + dn.day + (dn.day >= TN.Config.CAMPAIGN_DAYS ? ' / ' + TN.Config.CAMPAIGN_DAYS : '');
      this.el.phaseText.textContent = dn.phaseName();
      this.el.hudCenter.classList.toggle('night', dn.phase !== 'day');
      const ratio = dn.phaseDuration && isFinite(dn.phaseDuration) ? U.clamp(dn.timeLeft / dn.phaseDuration, 0, 1) : 1;
      this.el.timeFill.style.width = ratio * 100 + '%';
      this.el.timeText.textContent = isFinite(dn.timeLeft) ? U.formatTime(dn.timeLeft) : '--:--';
      const threat = dn.threatText(g);
      this.el.threatText.textContent = threat;
      this.el.threatText.classList.toggle('danger', threat === 'Asedio' || threat.indexOf('JEFE') === 0);

      this.el.resWood.textContent = inv.resources.wood || 0;
      this.el.resStone.textContent = inv.resources.stone || 0;
      this.el.resScrap.textContent = inv.resources.scrap || 0;
      this.el.resHerbs.textContent = inv.resources.herbs || 0;

      // Objetivos
      const objs = g.quests.objectives(g);
      let html = '';
      for (const o of objs) {
        html += '<li class="' + (o.done ? 'done' : '') + '">' + o.label + ' <span style="opacity:.6">(' + o.detail + ')</span></li>';
      }
      this.el.objectiveList.innerHTML = html;

      // Barra de jefe
      const boss = g.getActiveBoss();
      if (boss) {
        this.el.bossWrap.classList.remove('hidden');
        this.el.bossName.textContent = boss.name;
        this.el.bossTitle.textContent = boss.boss ? boss.boss.def.title : '';
        this.el.bossFill.style.width = U.clamp(boss.hp / boss.maxHp, 0, 1) * 100 + '%';
      } else {
        this.el.bossWrap.classList.add('hidden');
      }

      this.refreshHotbar();
      if (TN.Config.DEBUG.showCoords) {
        this.el.debugInfo.classList.remove('hidden');
        this.el.debugInfo.textContent =
          'x:' + Math.round(pl.x) + ' y:' + Math.round(pl.y) + '\n' +
          'dia:' + dn.day + ' fase:' + dn.phase + '\n' +
          'enemigos:' + g.enemies.aliveCount + '\n' +
          'fps:' + Math.round(g.fps);
      } else {
        this.el.debugInfo.classList.add('hidden');
      }
    }

    refreshHotbar() {
      const inv = this.game.inventory;
      const labels = { medkit: 'Medicina', repairkit: 'Kit reparacion', grenade: 'Bomba', flashlight: 'Linterna' };
      let html = '';
      for (let i = 0; i < 4; i++) {
        const id = inv.hotbar[i];
        if (!id) { html += '<div class="slot empty"><span class="key">' + (i + 1) + '</span><span class="ico">·</span></div>'; continue; }
        let qty = '';
        if (id === 'flashlight') qty = this.game.player.flashlightOn ? 'ON' : 'OFF';
        else qty = inv.countItem(id);
        html += '<div class="slot"><span class="key">' + (i + 1) + '</span>' +
          '<span class="ico">' + (ITEM_ICONS[id] || '•') + '</span>' +
          '<span class="qty">' + qty + '</span></div>';
      }
      this.el.hotbar.innerHTML = html;
    }

    /* --- Prompt contextual -------------------------------------------------- */
    setPrompt(text) {
      if (!text) {
        this.el.prompt.classList.add('hidden');
        return;
      }
      this.el.prompt.classList.remove('hidden');
      this.el.prompt.innerHTML = text;
    }

    flashDamage() {
      this.el.damageFlash.style.opacity = '0.8';
    }

    /* --- Listas ------------------------------------------------------------- */
    refreshInventory() {
      const g = this.game;
      const inv = g.inventory;
      this._updateHud();
      if (this.current !== 'craft') return;

      // Costes
      const rows = [];
      for (const r of TN.Crafting.all()) {
        const req = TN.Crafting.checkRequirements(r, g);
        const cost = TN.Crafting.effectiveCost(r, g);
        const can = g.inventory.canAfford(cost);
        const locked = !req.ok;
        let costTxt = '';
        for (const k in cost) costTxt += (TN.Inventory.RES_NAMES[k] || k) + ' ' + cost[k] + ', ';
        costTxt = costTxt.replace(/, $/, '');
        const why = locked ? req.reason : (can ? '' : 'Materiales insuficientes');
        rows.push({
          icon: RECIPE_ICONS[r.id] || '🔧',
          name: r.name,
          desc: r.desc,
          cost: costTxt,
          lack: !can || locked,
          btn: locked ? 'Bloqueado' : 'Fabricar',
          disabled: locked || !can,
          why: why,
          action: function () { TN.Crafting.craft(r.id, g); g.ui.refreshCraft(); }
        });
      }
      this.el.craftList.innerHTML = '';
      for (const row of rows) this.el.craftList.appendChild(this._makeItem(row));

      // Inventario
      let html = '';
      for (const k of TN.Inventory.RES_KEYS) {
        html += '<div class="inv-cell"><span>' + (TN.Inventory.RES_NAMES[k]) + '</span><b>' + (inv.resources[k] || 0) + '</b></div>';
      }
      for (const k in inv.ammo) {
        html += '<div class="inv-cell"><span>' + (TN.Weapons.AMMO_NAMES[k] || k) + '</span><b>' + inv.ammo[k] + '</b></div>';
      }
      this.el.invRes.innerHTML = html;

      let wHtml = '';
      for (const wid of inv.weapons) {
        const w = TN.Weapons.get(wid);
        const isEquipped = inv.equipped === wid;
        wHtml += '<div class="item"><div class="iico">' + (ITEM_ICONS[wid] || '🔨') + '</div>' +
          '<div class="ibody"><div class="iname">' + w.name + (isEquipped ? ' <span style="color:var(--good)">(equipada)</span>' : '') + '</div>' +
          '<div class="idesc">' + w.desc + '</div></div>' +
          (isEquipped ? '' : '<button class="ibtn" data-equip="' + wid + '">Equipar</button>') + '</div>';
      }
      this.el.invWeapons.innerHTML = wHtml;
      const btns = this.el.invWeapons.querySelectorAll('[data-equip]');
      for (let i = 0; i < btns.length; i++) {
        btns[i].addEventListener('click', (function (id) {
          return function () {
            g.inventory.equip(id);
            g.ui.toast('Equipada: ' + TN.Weapons.get(id).name, 'good');
            g.audio.play('ui');
            g.ui.refreshCraft();
          };
        })(btns[i].getAttribute('data-equip')));
      }

      let iHtml = '';
      for (const id in inv.items) {
        iHtml += '<div class="item"><div class="iico">' + (ITEM_ICONS[id] || '📦') + '</div>' +
          '<div class="ibody"><div class="iname">' + id + '</div>' +
          '<div class="idesc">x' + inv.items[id] + '</div></div></div>';
      }
      if (!iHtml) iHtml = '<div class="item"><div class="ibody"><div class="idesc">Sin objetos especiales.</div></div></div>';
      this.el.invItems.innerHTML = iHtml;
    }

    refreshCraft() { this.refreshInventory(); }

    refreshBuild() {
      const g = this.game;
      const rows = [];
      for (const id in TN.Buildings.DEFINITIONS) {
        const def = TN.Buildings.DEFINITIONS[id];
        const unlocked = g.buildings.has(id);
        const cost = g.buildings.effectiveCost(id, g);
        const can = g.inventory.canAfford(cost);
        let costTxt = '';
        for (const k in cost) costTxt += (TN.Inventory.RES_NAMES[k] || k) + ' ' + cost[k] + ', ';
        costTxt = costTxt.replace(/, $/, '');
        const selected = g.buildMode === id;
        rows.push({
          icon: BUILD_ICONS[id] || '🧱',
          name: def.name + (selected ? ' <span style="color:var(--good)">(seleccionada)</span>' : ''),
          desc: def.desc,
          cost: costTxt,
          lack: !can,
          btn: unlocked ? (selected ? 'Colocando...' : 'Colocar') : 'Bloqueado',
          disabled: !unlocked,
          why: unlocked ? '' : 'Fabricalo primero (tecla C)',
          action: function () { g.selectBuildType(id); g.ui.refreshBuild(); }
        });
      }
      this.el.buildList.innerHTML = '';
      for (const row of rows) this.el.buildList.appendChild(this._makeItem(row));
      this.el.buildTip.textContent = g.buildMode
        ? 'Colocando "' + TN.Buildings.DEFINITIONS[g.buildMode].name + '". Clic izquierdo para poner, Esc para cancelar.'
        : 'Selecciona una estructura y haz clic en el suelo para colocarla. Verde = valido, rojo = no.';
    }

    refreshResearch() {
      const g = this.game;
      this.el.rpCount.textContent = g.progression.rp + ' RP';
      const box = this.el.researchList;
      box.innerHTML = '';
      for (const id in TN.Progression.RESEARCH) {
        const r = TN.Progression.RESEARCH[id];
        const lvl = g.progression.get(id);
        const maxed = lvl >= r.max;
        const cost = maxed ? 0 : r.costs[lvl];
        const can = !maxed && g.progression.rp >= cost;
        const row = this._makeItem({
          icon: '🔬',
          name: r.name + (lvl ? ' (nivel ' + lvl + '/' + r.max + ')' : ''),
          desc: r.desc,
          cost: maxed ? 'Nivel maximo' : (cost + ' RP'),
          lack: maxed ? false : !can,
          btn: maxed ? 'Completado' : 'Investigar',
          disabled: maxed || !can,
          why: maxed ? '' : 'Puntos de investigacion insuficientes',
          action: function () {
            if (g.progression.buy(id)) {
              g.ui.toast('Investigacion: ' + r.name, 'good');
              g.audio.play('upgrade');
              g.applyResearchToRun();
              g.ui.refreshResearch();
            }
          }
        });
        box.appendChild(row);
      }
    }

    refreshUpgrades() {
      const g = this.game;
      const pending = g.upgrades.pending || [];
      this.el.upgradeList.innerHTML = '';
      for (const id of pending) {
        const u = TN.Upgrades.LIST[id];
        if (!u) continue;
        const row = this._makeItem({
          icon: u.icon || '⭐',
          name: u.name,
          desc: u.desc,
          cost: '',
          lack: false,
          btn: 'Elegir',
          disabled: false,
          why: '',
          action: function () {
            g.upgrades.choose(id);
            g.ui.toast('Mejora obtenida: ' + u.name, 'good');
            g.audio.play('upgrade');
            g.ui.close();
            g.applyUpgradesToPlayer();
          }
        });
        this.el.upgradeList.appendChild(row);
      }
    }

    _makeItem(row) {
      const el = document.createElement('div');
      el.className = 'item' + (row.disabled ? ' locked' : '');
      const icost = row.cost ? '<div class="icost' + (row.lack ? ' lack' : '') + '">' + row.cost + '</div>' : '';
      el.innerHTML =
        '<div class="iico">' + row.icon + '</div>' +
        '<div class="ibody"><div class="iname">' + row.name + '</div>' +
        '<div class="idesc">' + row.desc + '</div>' + icost + '</div>' +
        '<button class="ibtn"' + (row.disabled ? ' disabled' : '') + '>' + row.btn + '</button>';
      const btn = el.querySelector('.ibtn');
      const self = this;
      btn.addEventListener('click', function () {
        if (row.disabled) {
          if (row.why) self.game.ui.toast(row.why, 'error');
          self.game.audio.play('error');
          return;
        }
        row.action();
      });
      return el;
    }

    refreshOptions() {
      const o = this.game.progression.options;
      const p = this.el.panels.options;
      p.querySelector('#optVolume').value = Math.round((o.volume || 0) * 100);
      p.querySelector('#optVolumeVal').textContent = Math.round((o.volume || 0) * 100) + '%';
      p.querySelector('#optMuted').checked = !!o.muted;
      p.querySelector('#optScreenFx').checked = o.screenEffects !== false;
      p.querySelector('#optCoords').checked = !!o.showCoords;
      p.querySelector('#optDebug').checked = !!TN.Config.DEBUG.enabled;
      const sel = p.querySelector('#optCycle');
      const scale = o.cycleScale || 1;
      sel.value = scale === 1 ? 'normal' : (scale === TN.Config.CYCLE_SCALES.short ? 'short' : 'tiny');
    }

    refreshMainMeta() {
      const r = this.game.progression.records;
      const el = this.el.mainMeta;
      const best = r.bestDay || 0;
      el.innerHTML = 'Mejor expedicion: <b>' + best + '</b> ' + (best === 1 ? 'dia' : 'dias') +
        ' &nbsp;|&nbsp; investigation: <b>' + this.game.progression.rp + ' RP</b><br>' +
        'Noches sobrevividas: ' + (r.nights || 0) + ' &nbsp;|&nbsp; Jefes derrotados: ' + (r.bosses || 0);
      // El boton Continuar solo se habilita si hay una partida valida.
      const btn = document.getElementById('btnContinue');
      if (btn) btn.disabled = !this.game.saveMgr.hasValidSave();
    }

    /* --- Presentacion de jefe ------------------------------------------------ */
    showBossIntro(name, subtitle) {
      this.el.biName.textContent = name;
      this.el.biSub.textContent = subtitle || '';
      this.el.bossIntro.classList.remove('hidden');
      this.el.bossIntro.style.animation = 'none';
      // Reinicia la animacion
      void this.el.bossIntro.offsetWidth;
      this.el.bossIntro.style.animation = '';
      clearTimeout(this._bossIntroTimer);
      this._bossIntroTimer = setTimeout(() => {
        this.el.bossIntro.classList.add('hidden');
      }, 2600);
    }

    /* --- Fin de partida ------------------------------------------------------ */
    showGameOver(stats, reason) {
      this.el.gameOverReason.textContent = reason || 'El bosque se queda con lo que encuentra.';
      this.el.gameOverStats.innerHTML = this._statsHtml(stats);
      this.open('gameOver');
    }

    showVictory(stats) {
      this.el.victoryStats.innerHTML = this._statsHtml(stats);
      this.open('victory');
    }

    _statsHtml(stats) {
      let html = '';
      for (const k in stats) {
        html += '<div class="stat-cell"><div class="k">' + k + '</div><div class="v">' + stats[k] + '</div></div>';
      }
      return html;
    }

    /* --- Minimapa ------------------------------------------------------------- */
    drawMinimap() {
      const g = this.game;
      const cv = this.el.minimap;
      const ctx = this.minimapCtx;
      const size = cv.width;
      const range = 900;                        // unidades de mundo visibles
      const scale = size / range;
      const cx = g.player.x, cy = g.player.y;

      ctx.clearRect(0, 0, size, size);
      ctx.fillStyle = '#101a12';
      ctx.fillRect(0, 0, size, size);

      // Terreno basico
      ctx.fillStyle = 'rgba(60,90,60,0.25)';
      const step = 8;
      for (let ty = 0; ty < g.world.rows; ty += 3) {
        for (let tx = 0; tx < g.world.cols; tx += 3) {
          const wx = tx * g.world.tile, wy = ty * g.world.tile;
          if (Math.hypot(wx - cx, wy - cy) > range / 2) continue;
          const t = g.world.tiles[ty * g.world.cols + tx];
          if (t === 3) ctx.fillStyle = 'rgba(150,130,90,0.25)';
          else if (t === 4) ctx.fillStyle = 'rgba(60,100,110,0.3)';
          else continue;
          ctx.fillRect((wx - cx) * scale + size / 2, (wy - cy) * scale + size / 2,
            g.world.tile * 3 * scale, g.world.tile * 3 * scale);
        }
      }

      // Base
      ctx.fillStyle = '#d8c07a';
      ctx.fillRect((g.world.base.x - cx) * scale + size / 2 - 3, (g.world.base.y - cy) * scale + size / 2 - 3, 6, 6);
      // Generador
      ctx.fillStyle = '#ff9a5c';
      ctx.beginPath();
      ctx.arc((g.generator.x - cx) * scale + size / 2, (g.generator.y - cy) * scale + size / 2, 3, 0, 6.3);
      ctx.fill();

      // Puntos de interes (descubiertos)
      for (const p of g.world.pois) {
        const known = p.discovered || p.taken || g.progression.get('scout') > 0;
        if (!known) continue;
        ctx.fillStyle = p.taken ? '#5a6a5a' : '#8be9ff';
        ctx.fillRect((p.x - cx) * scale + size / 2 - 3, (p.y - cy) * scale + size / 2 - 3, 6, 6);
      }

      // Construcciones
      ctx.fillStyle = '#c9a06a';
      for (const b of g.buildings.list) {
        ctx.fillRect((b.x - cx) * scale + size / 2 - 1.5, (b.y - cy) * scale + size / 2 - 1.5, 3, 3);
      }

      // Enemigos cercanos
      ctx.fillStyle = '#e05a4a';
      for (const e of g.enemies.list) {
        if (e.dead) continue;
        if (Math.hypot(e.x - cx, e.y - cy) > 260) continue;
        ctx.beginPath();
        ctx.arc((e.x - cx) * scale + size / 2, (e.y - cy) * scale + size / 2, 2, 0, 6.3);
        ctx.fill();
      }

      // Jugador
      ctx.fillStyle = '#ffffff';
      ctx.beginPath();
      ctx.arc(size / 2, size / 2, 3.4, 0, 6.3);
      ctx.fill();
      // Cono de vision
      ctx.strokeStyle = 'rgba(255,255,255,0.35)';
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(size / 2, size / 2);
      ctx.lineTo(size / 2 + Math.cos(g.player.aimAngle) * 16, size / 2 + Math.sin(g.player.aimAngle) * 16);
      ctx.stroke();
    }
  }

  return UISystem;
})();
