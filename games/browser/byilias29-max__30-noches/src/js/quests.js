/* ==========================================================================
   30 NOCHES - quests.js
   Objetivos de la campana, componentes de la antena y final.
   ========================================================================== */
window.TN = window.TN || {};

TN.Quests = (function () {
  const U = TN.Utils;

  class QuestManager {
    constructor(world) {
      this.world = world;
      this.components = { battery: false, circuit: false, transmitter: false };
      this.antenna = {
        x: world.antenna.x, y: world.antenna.y,
        hw: world.antenna.hw, hh: world.antenna.hh,
        hp: 200, maxHp: 200, repaired: false, activated: false
      };
      this.usedPois = {};
    }

    get collected() {
      return (this.components.battery ? 1 : 0) +
        (this.components.circuit ? 1 : 0) +
        (this.components.transmitter ? 1 : 0);
    }
    get total() { return 3; }

    componentLabel() {
      const parts = [];
      if (this.components.battery) parts.push('bateria');
      if (this.components.circuit) parts.push('circuito');
      if (this.components.transmitter) parts.push('transmisor');
      return parts.length ? parts.join(', ') : 'ninguno';
    }

    missingComponents() {
      const out = [];
      if (!this.components.battery) out.push('Bateria de emergencia (vehiculo accidentado)');
      if (!this.components.circuit) out.push('Circuito de comunicaciones (bunker)');
      if (!this.components.transmitter) out.push('Transmisor de senal (torre de vigilancia)');
      return out;
    }

    /* Recoger el componente de un punto de interes. */
    collect(poi, game) {
      if (!poi || poi.taken) return false;
      poi.taken = true;
      this.components[poi.component] = true;
      game.inventory.addResource('scrap', 6);
      game.inventory.addResource('stone', 3);
      game.ui.toast('Componente obtenido: ' + poi.componentName, 'good');
      game.audio.play('pickup');
      game.particles.burst(poi.container.x, poi.container.y, 18, { color: '#8be9ff', speed: 160, life: 0.7 });
      game.questsDirty = true;
      game.save.markDirty();
      return true;
    }

    canRepair(game) {
      if (this.antenna.repaired) return { ok: false, reason: 'La antena ya esta reparada' };
      const missing = this.missingComponents();
      if (missing.length) {
        return { ok: false, reason: 'Faltan componentes: ' + missing.join(' | ') };
      }
      const cost = TN.Config.ANTENNA.repairCost;
      if (!game.inventory.canAfford(cost)) {
        const miss = game.inventory.missingFor(cost);
        let txt = 'Faltan materiales:';
        for (const k in miss) txt += ' ' + (TN.Inventory.RES_NAMES[k] || k) + ' x' + miss[k] + '.';
        return { ok: false, reason: txt };
      }
      return { ok: true, cost: cost };
    }

    repairAntenna(game) {
      const check = this.canRepair(game);
      if (!check.ok) {
        game.ui.toast(check.reason, 'error');
        game.audio.play('error');
        return false;
      }
      game.inventory.spend(check.cost);
      this.antenna.repaired = true;
      game.ui.toast('Antena reparada. Ahora hay que encenderla.', 'good');
      game.audio.play('craft');
      game.particles.burst(this.antenna.x, this.antenna.y, 26, { color: '#8be9ff', speed: 180, life: 0.8 });
      game.questsDirty = true;
      game.save.markDirty();
      return true;
    }

    canActivate(game) {
      if (!this.antenna.repaired) {
        return { ok: false, reason: 'La antena no esta reparada. Faltan: ' + this.missingComponents().join(' | ') };
      }
      if (game.dayNight.day < TN.Config.CAMPAIGN_DAYS) {
        return { ok: false, reason: 'La señal solo sale en la noche ' + TN.Config.CAMPAIGN_DAYS + ' (quedan ' + (TN.Config.CAMPAIGN_DAYS - game.dayNight.day) + ' noches)' };
      }
      if (!game.finalBossDefeated) {
        return { ok: false, reason: 'La Entidad sigue cerca. Derrotala primero.' };
      }
      return { ok: true };
    }

    activateAntenna(game) {
      const check = this.canActivate(game);
      if (!check.ok) {
        game.ui.toast(check.reason, 'error');
        game.audio.play('error');
        return false;
      }
      this.antenna.activated = true;
      game.onVictory();
      return true;
    }

    /* Lista de objetivos para el HUD. */
    objectives(game) {
      const list = [];
      const day = game.dayNight.day;
      list.push({
        label: 'Sobrevivir hasta la noche ' + TN.Config.CAMPAIGN_DAYS,
        done: day > TN.Config.CAMPAIGN_DAYS || game.state === 'victory',
        detail: 'Dia ' + day + '/' + TN.Config.CAMPAIGN_DAYS
      });
      list.push({
        label: 'Conseguir los 3 componentes de la antena',
        done: this.collected === 3,
        detail: this.collected + '/3 - ' + this.componentLabel()
      });
      list.push({
        label: 'Reparar la antena de la base',
        done: this.antenna.repaired,
        detail: this.antenna.repaired ? 'Reparada' : 'Necesita 20 chatarra y 10 piedra'
      });
      list.push({
        label: 'Derrotar a la Entidad en la noche 30',
        done: !!game.finalBossDefeated,
        detail: game.finalBossDefeated ? 'Derrotada' : 'Pendiente'
      });
      list.push({
        label: 'Activar la senal de rescate',
        done: this.antenna.activated,
        detail: this.antenna.activated ? 'Enviada' : 'Final'
      });
      return list;
    }

    serialize() {
      return {
        components: Object.assign({}, this.components),
        antenna: {
          repaired: this.antenna.repaired,
          activated: this.antenna.activated,
          hp: this.antenna.hp
        },
        usedPois: Object.assign({}, this.usedPois)
      };
    }

    restore(data) {
      if (!data) return;
      this.components = Object.assign({ battery: false, circuit: false, transmitter: false }, data.components || {});
      if (data.antenna) {
        this.antenna.repaired = !!data.antenna.repaired;
        this.antenna.activated = !!data.antenna.activated;
        this.antenna.hp = data.antenna.hp || 200;
      }
      this.usedPois = Object.assign({}, data.usedPois || {});
      for (const p of this.world.pois) {
        if (this.components[p.component]) p.taken = true;
      }
    }
  }

  return QuestManager;
})();
