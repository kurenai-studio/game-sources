import type Phaser from 'phaser';
import { ITEM_BY_ID } from '@/game/data/items';
import { gameEvents } from '@/game/events';
import { audio } from '@/game/systems/audio';
import { createReadableSeed } from '@/game/systems/rng';
import { loadSave, updateSave } from '@/game/systems/storage';
import type { GameDebugSnapshot, GameResult } from '@/game/types';
import type { GameScene } from '@/game/scenes/GameScene';

function required<T extends Element>(selector: string): T {
  const element = document.querySelector<T>(selector);
  if (!element) throw new Error(`Missing required interface element: ${selector}`);
  return element;
}

function formatTime(milliseconds: number): string {
  const totalSeconds = Math.floor(milliseconds / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

export class UiController {
  private readonly game: Phaser.Game;
  private readonly menu = required<HTMLElement>('#menu');
  private readonly hud = required<HTMLElement>('#hud');
  private readonly pauseOverlay = required<HTMLElement>('#pause-overlay');
  private readonly resultOverlay = required<HTMLElement>('#result-overlay');
  private readonly seedInput = required<HTMLInputElement>('#seed-input');
  private readonly hearts = required<HTMLElement>('#hearts');
  private readonly stats = required<HTMLElement>('#stats');
  private readonly inventory = required<HTMLElement>('#inventory');
  private readonly minimap = required<HTMLElement>('#minimap');
  private readonly floorLabel = required<HTMLElement>('#floor-label');
  private readonly roomLabel = required<HTMLElement>('#room-label');
  private readonly bossMeter = required<HTMLElement>('#boss-meter');
  private readonly bossMeterFill = required<HTMLElement>('#boss-meter-fill');
  private readonly bossPhase = required<HTMLElement>('#boss-phase');
  private readonly toast = required<HTMLElement>('#toast');
  private readonly soundButton = required<HTMLButtonElement>('#sound-button');
  private readonly bellButton = required<HTMLButtonElement>('#bell-button');
  private readonly bellTouch = required<HTMLButtonElement>('#bell-touch');
  private toastTimer: number | null = null;
  private currentSeed = 'MOURNWELL';
  private readonly removers: Array<() => void> = [];

  constructor(game: Phaser.Game) {
    this.game = game;
    const save = loadSave();
    audio.setEnabled(save.sound);
    this.soundButton.textContent = save.sound ? 'SOUND ON' : 'SOUND OFF';
    this.seedInput.value = createReadableSeed();
    this.bindButton('#primary-action', () => this.startRun(this.seedInput.value));
    this.bindButton('#retry-button', () => this.startRun(this.currentSeed));
    this.bindButton('#menu-button', () => this.showMenu());
    this.bindButton('#pause-button', () => this.getGameScene()?.pauseGame());
    this.bindButton('#resume-button', () => this.getGameScene()?.resumeGame());
    this.bindButton('#quit-button', () => {
      const scene = this.getGameScene();
      if (scene?.phase === 'paused') scene.resumeGame();
      scene?.abandonRun();
    });
    const toll = (button: HTMLButtonElement) => (): void => {
      // drop focus so Space doesn't also press the button next time
      button.blur();
      this.getGameScene()?.tollBell();
    };
    this.bindButton('#bell-button', toll(this.bellButton));
    this.bindButton('#bell-touch', toll(this.bellTouch));
    this.bindButton('#sound-button', () => {
      const enabled = !audio.isEnabled();
      audio.setEnabled(enabled);
      updateSave({ sound: enabled });
      this.soundButton.textContent = enabled ? 'SOUND ON' : 'SOUND OFF';
    });

    this.removers.push(
      gameEvents.on('snapshot', (snapshot) => this.renderSnapshot(snapshot)),
      gameEvents.on('phase', (phase) => this.renderPhase(phase)),
      gameEvents.on('result', (result) => this.renderResult(result)),
      gameEvents.on('toast', (message) => this.showToast(message.title, message.subtitle, message.duration)),
    );

    const onVisibility = (): void => {
      if (document.hidden) this.getGameScene()?.pauseGame();
    };
    document.addEventListener('visibilitychange', onVisibility);
    this.removers.push(() => document.removeEventListener('visibilitychange', onVisibility));

    const onPauseKey = (event: KeyboardEvent): void => {
      if (event.repeat || (event.code !== 'Escape' && event.code !== 'KeyP')) return;
      const target = event.target;
      if (target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement) return;
      const scene = this.getGameScene();
      if (!scene) return;
      if (scene.phase === 'running') scene.pauseGame();
      else if (scene.phase === 'paused') scene.resumeGame();
      else return;
      event.preventDefault();
    };
    window.addEventListener('keydown', onPauseKey);
    this.removers.push(() => window.removeEventListener('keydown', onPauseKey));
  }

  destroy(): void {
    this.removers.forEach((remove) => remove());
    this.hideToast();
  }

  private bindButton(selector: string, action: () => void): void {
    const button = required<HTMLButtonElement>(selector);
    const handler = (): void => action();
    button.addEventListener('click', handler);
    this.removers.push(() => button.removeEventListener('click', handler));
  }

  private startRun(seed: string): void {
    this.hideToast();
    void audio.unlock();
    this.currentSeed = seed.trim() || createReadableSeed();
    this.seedInput.value = this.currentSeed;
    this.menu.classList.add('is-hidden');
    this.pauseOverlay.classList.add('is-hidden');
    this.resultOverlay.classList.add('is-hidden');
    this.hud.classList.remove('is-hidden');
    if (this.game.scene.isActive('MenuScene')) this.game.scene.stop('MenuScene');
    if (this.game.scene.getScene('GameScene')) this.game.scene.stop('GameScene');
    this.game.scene.start('GameScene', { seed: this.currentSeed });
  }

  private showMenu(): void {
    this.hideToast();
    if (this.game.scene.getScene('GameScene')) this.game.scene.stop('GameScene');
    if (!this.game.scene.isActive('MenuScene')) this.game.scene.start('MenuScene');
    this.hud.classList.add('is-hidden');
    this.pauseOverlay.classList.add('is-hidden');
    this.resultOverlay.classList.add('is-hidden');
    this.menu.classList.remove('is-hidden');
    this.seedInput.value = createReadableSeed();
    gameEvents.emit('phase', 'menu');
    required<HTMLButtonElement>('#primary-action').focus({ preventScroll: true });
  }

  private renderPhase(phase: GameDebugSnapshot['phase']): void {
    this.pauseOverlay.classList.toggle('is-hidden', phase !== 'paused');
    if (phase === 'paused') required<HTMLButtonElement>('#resume-button').focus({ preventScroll: true });
    if (phase === 'running') {
      this.menu.classList.add('is-hidden');
      this.resultOverlay.classList.add('is-hidden');
      this.hud.classList.remove('is-hidden');
    }
  }

  private renderSnapshot(snapshot: GameDebugSnapshot): void {
    this.currentSeed = snapshot.seed;
    this.floorLabel.textContent = `DEPTH ${roman(snapshot.floor)}`;
    this.roomLabel.textContent = `CHAMBER ${snapshot.room.index + 1}/${snapshot.dungeon.rooms.length}`;
    this.renderHealth(snapshot.summary.hp, snapshot.summary.maxHp);
    this.renderStats(snapshot);
    this.renderInventory(snapshot);
    this.renderMinimap(snapshot);
    this.renderBossMeter(snapshot);
    this.renderBell(snapshot);
  }

  private renderHealth(hp: number, maxHp: number): void {
    const segmentCount = Math.min(6, Math.max(5, Math.ceil(maxHp / 20)));
    const nodes: HTMLElement[] = [];
    for (let index = 0; index < segmentCount; index += 1) {
      const segment = document.createElement('span');
      segment.className = 'heart';
      if (hp <= index * (maxHp / segmentCount)) segment.classList.add('is-empty');
      segment.setAttribute('aria-hidden', 'true');
      nodes.push(segment);
    }
    const label = document.createElement('span');
    label.className = 'health-value';
    label.textContent = `${hp}/${maxHp}`;
    this.hearts.replaceChildren(...nodes, label);
    this.hearts.setAttribute('aria-label', `Resolve ${hp} of ${maxHp}`);
  }

  private renderStats(snapshot: GameDebugSnapshot): void {
    const values: Array<[string, string]> = [
      ['ATK', snapshot.summary.attributes.attack.toFixed(1)],
      ['CAST', `${snapshot.summary.attributes.fireRate}/s`],
      ['SPD', String(snapshot.summary.attributes.moveSpeed)],
      ['RNG', String(snapshot.summary.attributes.range)],
      ['PIERCE', String(snapshot.stats.pierce)],
      ['SHOTS', String(snapshot.stats.projectiles)],
    ];
    const fragments = values.map(([label, value]) => {
      const wrapper = document.createElement('div');
      const term = document.createElement('dt');
      const definition = document.createElement('dd');
      term.textContent = label;
      definition.textContent = value;
      wrapper.append(term, definition);
      return wrapper;
    });
    this.stats.replaceChildren(...fragments);
  }

  private renderInventory(snapshot: GameDebugSnapshot): void {
    if (snapshot.inventory.length === 0) {
      const empty = document.createElement('span');
      empty.className = 'inventory__empty';
      empty.textContent = 'None — yet.';
      this.inventory.replaceChildren(empty);
      return;
    }
    const entries = snapshot.inventory.map(({ id, stacks }) => {
      const element = document.createElement('span');
      element.className = 'inventory__item';
      element.textContent = ITEM_BY_ID.get(id)?.name ?? id;
      if (stacks > 1) {
        const count = document.createElement('b');
        count.textContent = `×${stacks}`;
        element.append(count);
      }
      return element;
    });
    this.inventory.replaceChildren(...entries);
  }

  private renderMinimap(snapshot: GameDebugSnapshot): void {
    const rooms = snapshot.dungeon.rooms;
    const minX = Math.min(...rooms.map((room) => room.x));
    const maxX = Math.max(...rooms.map((room) => room.x));
    const minY = Math.min(...rooms.map((room) => room.y));
    const maxY = Math.max(...rooms.map((room) => room.y));
    const discovered = new Set<string>();
    for (const room of rooms) {
      if (room.visited) {
        discovered.add(room.id);
        Object.values(room.neighbors).forEach((neighbor) => neighbor && discovered.add(neighbor));
      }
    }
    const toPosition = (room: (typeof rooms)[number]): { left: number; top: number } => ({
      left: 16 + ((room.x - minX) / Math.max(1, maxX - minX)) * 68,
      top: 18 + ((room.y - minY) / Math.max(1, maxY - minY)) * 64,
    });
    const positions = new Map(rooms.map((room) => [room.id, toPosition(room)]));
    const links: HTMLElement[] = [];
    for (const room of rooms.filter((candidate) => discovered.has(candidate.id))) {
      for (const neighborId of Object.values(room.neighbors)) {
        if (!neighborId || !discovered.has(neighborId) || room.id.localeCompare(neighborId) >= 0) continue;
        const from = positions.get(room.id);
        const to = positions.get(neighborId);
        if (!from || !to) continue;
        const dx = to.left - from.left;
        const dy = to.top - from.top;
        const link = document.createElement('span');
        link.className = 'map-link';
        link.setAttribute('aria-hidden', 'true');
        if (Math.abs(dx) > Math.abs(dy)) {
          link.classList.add('map-link--horizontal');
          link.style.left = `${Math.min(from.left, to.left)}%`;
          link.style.top = `${from.top}%`;
          link.style.width = `${Math.abs(dx)}%`;
        } else {
          link.classList.add('map-link--vertical');
          link.style.left = `${from.left}%`;
          link.style.top = `${Math.min(from.top, to.top)}%`;
          link.style.height = `${Math.abs(dy)}%`;
        }
        links.push(link);
      }
    }
    const nodes = rooms
      .filter((room) => discovered.has(room.id))
      .map((room) => {
        const element = document.createElement('span');
        element.className = 'map-room';
        element.setAttribute('aria-hidden', 'true');
        if (room.visited) element.classList.add('is-visited');
        if (room.id === snapshot.room.id) element.classList.add('is-current');
        if (room.kind === 'boss' && room.visited) element.classList.add('is-boss');
        if (room.kind === 'treasure' && room.visited) element.classList.add('is-treasure');
        const position = positions.get(room.id);
        element.style.left = `${position?.left ?? 50}%`;
        element.style.top = `${position?.top ?? 50}%`;
        element.title = room.visited ? `${room.kind} room` : 'Unexplored chamber';
        return element;
      });
    const visitedCount = rooms.filter((room) => room.visited).length;
    this.minimap.setAttribute(
      'aria-label',
      `Dungeon map: ${visitedCount} of ${rooms.length} chambers visited`,
    );
    this.minimap.replaceChildren(...links, ...nodes);
  }

  private renderBell(snapshot: GameDebugSnapshot): void {
    const { ready, readyInMs, cost } = snapshot.bell;
    const waiting = readyInMs > 0;
    this.bellButton.textContent = waiting
      ? `TOLL · ${Math.ceil(readyInMs / 1000)}s`
      : ready
        ? `TOLL −${cost} · SPACE`
        : 'TOLL · LOW RESOLVE';
    this.bellTouch.textContent = waiting ? `${Math.ceil(readyInMs / 1000)}s` : 'TOLL';
    for (const button of [this.bellButton, this.bellTouch]) {
      button.classList.toggle('is-ready', ready);
      button.classList.toggle('is-waiting', !ready);
    }
  }

  private renderBossMeter(snapshot: GameDebugSnapshot): void {
    const boss = snapshot.enemies.find((enemy) => enemy.type === 'tollmother');
    this.bossMeter.classList.toggle('is-hidden', !boss || snapshot.phase !== 'running');
    if (!boss) return;
    const ratio = Math.max(0, Math.min(1, boss.hp / boss.maxHp));
    this.bossMeterFill.style.width = `${ratio * 100}%`;
    this.bossPhase.textContent = ratio > 0.65 ? 'FIRST TOLL' : ratio > 0.3 ? 'SECOND TOLL' : 'FINAL TOLL';
  }

  private renderResult(result: GameResult): void {
    this.hideToast();
    updateSave({
      runs: loadSave().runs + 1,
      wins: loadSave().wins + Number(result.victory),
      bestTimeMs: result.victory
        ? Math.min(loadSave().bestTimeMs ?? Number.POSITIVE_INFINITY, result.elapsedMs)
        : loadSave().bestTimeMs,
      wellscript: loadSave().wellscript + result.roomsCleared + (result.victory ? 8 : 0),
    });
    required<HTMLElement>('#result-kicker').textContent = result.victory
      ? 'THE LAST BELL IS STILL'
      : 'THE WELL REMEMBERS';
    required<HTMLElement>('#result-title').textContent = result.victory
      ? 'Silence, at last'
      : 'Your vessel broke';
    required<HTMLElement>('#result-copy').textContent = result.victory
      ? 'You carried a name out of the dark.'
      : 'The dark settles around what remains.';
    const values: Array<[string, string]> = [
      ['TIME', formatTime(result.elapsedMs)],
      ['KILLS', String(result.kills)],
      ['RELICS', String(result.pickups)],
      ['CLEARED', String(result.roomsCleared)],
      ['DEALT', String(result.damageDealt)],
      ['TAKEN', String(result.damageTaken)],
      ['SEED', result.seed],
      ['RESULT', result.victory ? 'VICTORY' : 'FALLEN'],
    ];
    const fragments = values.map(([label, value]) => {
      const wrapper = document.createElement('div');
      const term = document.createElement('dt');
      const definition = document.createElement('dd');
      term.textContent = label;
      definition.textContent = value;
      wrapper.append(term, definition);
      return wrapper;
    });
    required<HTMLElement>('#result-stats').replaceChildren(...fragments);
    window.setTimeout(() => {
      this.resultOverlay.classList.remove('is-hidden');
      required<HTMLButtonElement>('#retry-button').focus({ preventScroll: true });
    }, 550);
  }

  private showToast(title: string, subtitle: string, duration = 1_100): void {
    if (this.toastTimer !== null) window.clearTimeout(this.toastTimer);
    const small = document.createElement('small');
    small.textContent = subtitle;
    this.toast.replaceChildren(document.createTextNode(title), small);
    this.toast.classList.remove('is-hidden');
    this.toastTimer = window.setTimeout(() => {
      this.toast.classList.add('is-hidden');
      this.toastTimer = null;
    }, duration);
  }

  private hideToast(): void {
    if (this.toastTimer !== null) window.clearTimeout(this.toastTimer);
    this.toastTimer = null;
    this.toast.classList.add('is-hidden');
  }

  private getGameScene(): GameScene | null {
    try {
      return this.game.scene.getScene('GameScene') as GameScene;
    } catch {
      return null;
    }
  }
}

function roman(value: number): string {
  return ['I', 'II', 'III', 'IV', 'V'][value - 1] ?? String(value);
}
