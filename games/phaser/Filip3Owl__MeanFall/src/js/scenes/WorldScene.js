import { TILE_SIZE, AREA_INFO, AREA_UNLOCK, AREA_BOSS, PLAYER_DEFAULTS, RESPAWN_TIME, REGEN_INTERVAL_MS, REGEN_HP_PER_TICK, REGEN_FOCUS_PER_TICK, ELEMENTS, NPC_NAMES, parentArea } from '../constants.js';
import { MapManager } from '../systems/MapManager.js';
import { Player } from '../entities/Player.js';
import { Monster } from '../entities/Monster.js';
import { NPC } from '../entities/NPC.js';
import { SaveSystem } from '../systems/SaveSystem.js';
import { masteryPercent } from '../systems/XPSystem.js';
import { QuestSystem } from '../systems/QuestSystem.js';
import { BountySystem } from '../systems/BountySystem.js';
import { ShopSystem } from '../systems/ShopSystem.js';
import { CombatSystem } from '../systems/CombatSystem.js';
import { SkillSystem } from '../systems/SkillSystem.js';
import { TutorialSystem } from '../systems/TutorialSystem.js';
import { AchievementSystem } from '../systems/AchievementSystem.js';
import { ITEMS } from '../data/items.js';
import { MAP_DATA } from '../data/maps.js';
import { MONSTERS, SANCTUM_GAUNTLET } from '../data/monsters.js';
import { ANCIENT_SCROLLS } from '../data/lore.js';
import { NPC_REACTIONS } from '../data/npcReactions.js';
import { CompanionSystem } from '../systems/CompanionSystem.js';
import { buildPlayerSprite, attachRarityGlow } from '../utils/Draw.js';
import { DayNight } from '../utils/DayNight.js';
import EventBus from '../utils/EventBus.js';
import { Sound } from '../utils/SoundSystem.js';
import { Music } from '../utils/MusicSystem.js';

export class WorldScene extends Phaser.Scene {
    constructor() { super('World'); }

    create() {
        this._playerData = this.registry.get('player') || JSON.parse(JSON.stringify(PLAYER_DEFAULTS));
        
        // Ensure new systems have data even on old saves
        if (!this._playerData.elementalMastery) {
            this._playerData.elementalMastery = JSON.parse(JSON.stringify(PLAYER_DEFAULTS.elementalMastery));
        }
        if (!this._playerData.openedChests) this._playerData.openedChests = {};
        if (!this._playerData.inventory) this._playerData.inventory = [];
        if (!this._playerData.upgrades) this._playerData.upgrades = {};
        if (!this._playerData.secretsFound) this._playerData.secretsFound = {};
        if (!this._playerData.dugSites) this._playerData.dugSites = {};
        if (!this._playerData.equipment) this._playerData.equipment = {};
        if (this._playerData.equipment.relic === undefined) this._playerData.equipment.relic = null;
        
        // Ensure stats exist
        const stats = ['strength', 'intelligence', 'agility', 'vitality'];
        stats.forEach(s => { if (this._playerData[s] === undefined) this._playerData[s] = 5; });
        
        // Rebuild player sprite from saved appearance
        if (this._playerData.appearance) buildPlayerSprite(this, this._playerData.appearance);

        this._mapManager = new MapManager(this);
        this._monsters   = [];
        this._npcs       = [];
        this._npcIcons   = this.add.group();
        this._paused        = false;
        this._spaceLock     = false;
        this._respawns      = [];
        this._transitioning = false;
        this._nightWas      = DayNight.isNight();
        if (!this._playerData.seenReactions) this._playerData.seenReactions = {};

        this._loadArea(this._playerData.currentArea);
        const _sp = this._playerData.position;
        this._revealTiles(_sp.x, _sp.y);

        this._cursors = this.input.keyboard.createCursorKeys();
        this._wasd    = this.input.keyboard.addKeys({
            up: Phaser.Input.Keyboard.KeyCodes.W,
            down: Phaser.Input.Keyboard.KeyCodes.S,
            left: Phaser.Input.Keyboard.KeyCodes.A,
            right: Phaser.Input.Keyboard.KeyCodes.D,
        });
        this._spaceKey  = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
        this._iKey      = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.I);
        this._cKey      = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.C);
        this._qKey      = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.Q);
        this._bKey      = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.B);
        this._kKey      = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.K);
        this._lKey      = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.L);
        this._nKey      = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.N);
        this._f5Key     = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.F5);
        this._escKey    = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);

        QuestSystem.init(this._playerData);
        BountySystem.init(this._playerData);
        SkillSystem.init(this._playerData);
        TutorialSystem.init(this._playerData);
        CombatSystem.refreshWeaponElement(this._playerData, ITEMS);

        this._onCombatEndBound = this._onCombatEnd.bind(this);
        this._onLevelUpBound = this._onLevelUp.bind(this);
        this._onElementXpChangeBound = () => this._updateElementalAura();
        this._onQuestUpdateBound = () => this._updateQuestIcons();
        this._onGearChangeBound = () => this._updateGearGlow();
        this._onBountyCompleteBound = ({ slot }) => {
            this._chat(`{{accent:BÔNUS COMPLETO:}} ${slot.label} — abra o diário (Q) para coletar!`, 'xp');
            AchievementSystem.recordBounty(this._playerData);
            AchievementSystem.check(this._playerData);
        };

        EventBus.on('combat-end',       this._onCombatEndBound);
        EventBus.on('player-level-up',  this._onLevelUpBound);
        EventBus.on('element-xp-change', this._onElementXpChangeBound);
        EventBus.on('quest-update',     this._onQuestUpdateBound);
        EventBus.on('bounty-complete',  this._onBountyCompleteBound);
        EventBus.on('player-stats-changed', this._onGearChangeBound);

        this._syncTimer      = this.time.addEvent({ delay: 5000,   loop: true, callback: this._autoSync,     callbackScope: this });
        this._regenTimer     = this.time.addEvent({ delay: REGEN_INTERVAL_MS, loop: true, callback: this._regenTick, callbackScope: this });
        this._periodicSaveTimer = this.time.addEvent({ delay: 180000, loop: true, callback: this._periodicSave, callbackScope: this });

        this._updateElementalAura();
        this._updateGearGlow();
        EventBus.emit('area-changed', { areaId: this._playerData.currentArea });
        EventBus.emit('minimap-update', { mapMgr: this._mapManager, player: this._playerData });

        this._chat(`Bem-vindo a ${AREA_INFO[this._playerData.currentArea]?.displayName || '?'}!`, 'portal');

        // First-time tutorial
        TutorialSystem.trigger(this._playerData, this, 'start');

        // Show skill selector if pending picks
        this.time.delayedCall(800, () => this._maybeOpenSkill());
    }

    // ── Area & spawning ───────────────────────────────────────────────────────

    _loadArea(areaId) {
        this._monsters.forEach(m => m.destroy());
        this._npcs.forEach(n => n.destroy());
        this._monsters = [];
        this._npcs = [];
        if (this._player) this._player.destroy();

        this._mapManager.load(areaId, this._playerData);
        this._playerData.currentArea = areaId;

        const pos = this._playerData.position;
        this._player = new Player(this, { ...this._playerData, position: { ...pos } });

        const defeated = this._playerData.defeatedMonsters || {};
        const mapMons  = this._mapManager.mapData?.monsters || [];
        for (const md of mapMons) {
            if (defeated[md.instanceId]) continue;
            if (!this._mapManager.isWalkable(md.x, md.y)) continue;
            this._monsters.push(new Monster(this, md));
        }

        const mapNpcs = this._mapManager.mapData?.npcs || [];
        this._npcIcons.clear(true, true);
        for (const nd of mapNpcs) {
            const npc = new NPC(this, nd);
            this._npcs.push(npc);

            // Quest indicator icon (above the name label)
            const icon = this.add.text(npc.sprite.x, npc.sprite.y - 30, '!', {
                fontSize: '13px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
                stroke: '#000', strokeThickness: 3
            }).setOrigin(0.5, 0.5).setDepth(100).setVisible(false);
            icon.npcId = nd.npcId;
            this._npcIcons.add(icon);
        }
        this._updateQuestIcons();

        // The map is always 544×480 (same as the canvas), so the correct
        // camera position is always scroll (0,0). Reset here to fix any
        // drift left by combat pan/zoom animations.
        const cam = this.cameras.main;
        cam.stopFollow();
        cam.setZoom(1);
        cam.setScroll(0, 0);

        this._setupDarkness(areaId);
        this._setupNightOverlay(areaId);
        this._setupLights(areaId);
        this._setupVignette();
        this._setupWeather(areaId);
        this._setupCompanion();
        this._setupTrophies(areaId);
        this._setupWaygate(areaId);
        Music.play(this._musicKeyFor(areaId));
    }

    _musicKeyFor(areaId) {
        if (areaId.includes('house')) return 'home';
        if (areaId.endsWith('_depths')) return 'underground';
        return areaId;
    }

    // ── Underground darkness: black overlay with a light circle following
    //    the player (Tibia-style limited vision) ──────────────────────────────

    _setupDarkness(areaId) {
        this._darkness?.destroy();
        this._darkness = null;
        if (!areaId.endsWith('_depths')) return;
        this._darkness = this.add.renderTexture(0, 0, 544, 480)
            .setOrigin(0, 0).setDepth(40);
        this._exitLights = (this._mapManager.mapData?.exits || []).map(e => ({
            x: e.x * TILE_SIZE + TILE_SIZE / 2,
            y: e.y * TILE_SIZE + TILE_SIZE / 2,
        }));
        this._updateDarkness(0);
    }

    _updateDarkness(time) {
        if (!this._darkness || !this._player?.sprite) return;
        const rt = this._darkness;
        // Flicker like torchlight
        const flicker = 0.02 * Math.sin(time * 0.004) + 0.015 * Math.sin(time * 0.013);
        rt.clear();
        rt.fill(0x000005, 0.92 + flicker);
        rt.erase('light_radial', this._player.sprite.x - 128, this._player.sprite.y - 128);
        for (const l of this._exitLights || []) {
            rt.erase('light_radial_small', l.x - 48, l.y - 48);
        }
    }

    // ── Dia/noite: overlay azulado nas superfícies; Noturnos somem ao amanhecer ──

    _setupNightOverlay(areaId) {
        this._nightOverlay?.destroy();
        this._nightOverlay = null;
        if (areaId.endsWith('_depths') || areaId.includes('house')) return;
        // Luz ambiente: retângulo MULTIPLY cuja cor segue a hora do dia
        // (branco de dia = sem efeito; âmbar no entardecer; azul à noite)
        this._nightOverlay = this.add.rectangle(0, 0, 544, 480, 0xffffff, 1)
            .setOrigin(0, 0).setDepth(39).setBlendMode(Phaser.BlendModes.MULTIPLY);
    }

    _setupVignette() {
        this._vignette?.destroy();
        this._vignette = this.add.image(0, 0, 'vignette')
            .setOrigin(0, 0).setDepth(45).setAlpha(0.2);
    }

    // Luzes pontuais (blend ADD): acendem conforme escurece. Nas profundezas,
    // a "tocha" âmbar do jogador fica acima da escuridão e é fixa.
    _setupLights(areaId) {
        (this._lights || []).forEach(l => l.destroy());
        this._lights = [];
        this._lantern?.destroy();
        this._lantern = null;
        if (areaId.includes('house')) return;

        if (areaId.endsWith('_depths')) {
            this._lantern = this.add.image(0, 0, 'light_radial_small')
                .setBlendMode(Phaser.BlendModes.ADD).setTint(0xffaa55)
                .setScale(1.6).setAlpha(0.3).setDepth(41);
            this._lantern._fixed = true;
            return;
        }

        const mk = (x, y, tint, scale, maxA) => {
            const img = this.add.image(x, y, 'light_radial_small')
                .setBlendMode(Phaser.BlendModes.ADD).setTint(tint)
                .setScale(scale).setAlpha(0).setDepth(40);
            img._maxA = maxA;
            this.tweens.add({
                targets: img, scale: scale * 1.12,
                duration: 1400 + Math.random() * 600,
                yoyo: true, repeat: -1, ease: 'Sine.easeInOut',
            });
            this._lights.push(img);
        };

        for (const e of this._mapManager.mapData?.exits || []) {
            const x = e.x * TILE_SIZE + TILE_SIZE / 2;
            const y = e.y * TILE_SIZE + TILE_SIZE / 2;
            if (e.targetArea.includes('house')) mk(x, y - 6, 0xffcc88, 0.9, 0.55); // janela acesa
            else if (e.isHole)                  mk(x, y, 0x8866ff, 0.7, 0.30);
            else                                mk(x, y, 0xaaccff, 0.8, 0.35);
        }
        for (let r = 0; r < 15; r++) {
            for (let c = 0; c < 17; c++) {
                if (this._mapManager.getTileId(c, r) === 7) {
                    mk(c * TILE_SIZE + 16, r * TILE_SIZE + 16, 0xffd777, 0.55, 0.35);
                }
            }
        }
        // Lanterna do jogador
        this._lantern = this.add.image(0, 0, 'light_radial_small')
            .setBlendMode(Phaser.BlendModes.ADD).setTint(0xffcc88)
            .setScale(1.3).setAlpha(0).setDepth(40);
        this._lantern._maxA = 0.4;
    }

    _updateDayNight() {
        const d = DayNight.darkness();
        if (this._nightOverlay) this._nightOverlay.setFillStyle(DayNight.lightColor(), 1);
        if (this._fireflies) this._fireflies.emitting = DayNight.isNight();

        const area = this._playerData.currentArea || '';
        const indoor = area.endsWith('_depths') || area.includes('house');
        if (this._vignette) this._vignette.setAlpha(indoor ? 0.3 : 0.15 + 0.25 * d);

        for (const l of this._lights || []) l.setAlpha(l._maxA * d);
        if (this._lantern && this._player?.sprite) {
            this._lantern.setPosition(this._player.sprite.x, this._player.sprite.y);
            if (!this._lantern._fixed) this._lantern.setAlpha(this._lantern._maxA * d);
        }

        const night = DayNight.isNight();
        if (night === this._nightWas) return;
        this._nightWas = night;
        if (!this._nightOverlay) return; // interior/profundezas: sem anúncio
        if (night) {
            this._chat('{{accent:A noite cai sobre o mundo...}} Criaturas {{rarity:Noturnas}} despertam.', 'system');
        } else {
            this._chat('{{accent:O sol nasce.}} As criaturas noturnas recolhem-se às sombras.', 'system');
            this._dismissNocturnals();
        }
    }

    // Sombras acompanham o sol: deslocadas/compridas de manhã e à tarde,
    // curtas ao meio-dia, quase apagadas à noite. Interiores: neutras.
    _updateShadows() {
        const area = this._playerData.currentArea || '';
        const indoor = area.endsWith('_depths') || area.includes('house');
        const sp = indoor ? { ox: 0, sx: 1, alpha: 1 } : DayNight.shadowParams();
        const apply = (ent) => {
            const sh = ent?.shadow;
            if (!sh || !ent.sprite) return;
            if (sh._baseSX === undefined) {
                sh._baseSX = sh.scaleX;
                sh._baseA  = sh.alpha;
            }
            sh.x      = ent.sprite.x + sp.ox;
            sh.scaleX = sh._baseSX * sp.sx;
            sh.alpha  = sh._baseA * sp.alpha;
        };
        apply(this._player);
        for (const m of this._monsters) apply(m);
        for (const n of this._npcs) apply(n);
    }

    _dismissNocturnals() {
        const gone = this._monsters.filter(m => m.isNocturnal);
        if (!gone.length) return;
        this._monsters = this._monsters.filter(m => !m.isNocturnal);
        for (const m of gone) {
            const parts = [m.sprite, m.shadow, m.aura, m._hpBar, m._nameLabel].filter(Boolean);
            this.tweens.add({
                targets: parts, alpha: 0, duration: 900, ease: 'Sine.easeIn',
                onComplete: () => m.destroy(),
            });
            // A versão comum da criatura retorna em seguida
            this._respawns.push({
                instanceId: m.instanceId,
                areaId: this._playerData.currentArea,
                respawnAt: this.time.now + 4000,
            });
        }
    }

    // ── Clima: partículas ambientes por área de superfície ───────────────────

    _setupWeather(areaId) {
        this._weather?.destroy();
        this._weather = null;
        this._fireflies?.destroy();
        this._fireflies = null;
        if (areaId.endsWith('_depths') || areaId.includes('house')) return;

        const fromSky = (tint, cfg = {}) => this.add.particles(0, 0, 'particle_dot', {
            x: { min: 0, max: 544 }, y: -6,
            lifespan: 12000, frequency: 240, quantity: 1, tint,
            speedY: { min: 14, max: 32 }, speedX: { min: -10, max: 10 },
            scale: { min: 0.5, max: 1 }, alpha: { start: 0.9, end: 0.15 },
            ...cfg,
        }).setDepth(38);

        switch (areaId) {
            case 'meadows': // pólen e folhas ao vento
                this._weather = fromSky(0xbbdd66, { speedX: { min: 8, max: 30 }, frequency: 300 });
                break;
            case 'forest': // neve constante
                this._weather = fromSky(0xffffff, { frequency: 170 });
                break;
            case 'plains': // brasas subindo do chão quente
                this._weather = this.add.particles(0, 0, 'particle_dot', {
                    x: { min: 0, max: 544 }, y: 486,
                    lifespan: 6000, frequency: 210, quantity: 1, tint: 0xff8833,
                    speedY: { min: -55, max: -22 }, speedX: { min: -12, max: 12 },
                    scale: { start: 0.8, end: 0.2 }, alpha: { start: 1, end: 0 },
                    blendMode: 'ADD',
                }).setDepth(38);
                break;
            case 'mountains': // chuva fina
                this._weather = this.add.particles(0, 0, 'particle_streak', {
                    x: { min: 0, max: 560 }, y: -10,
                    lifespan: 1900, frequency: 45, quantity: 2, tint: 0x88aadd,
                    speedY: { min: 250, max: 330 }, speedX: { min: -25, max: -12 },
                    alpha: { start: 0.55, end: 0.15 },
                }).setDepth(38);
                break;
            case 'dungeon': // motas de sombra flutuando
                this._weather = this.add.particles(0, 0, 'particle_dot', {
                    x: { min: 0, max: 544 }, y: { min: 40, max: 460 },
                    lifespan: 5000, frequency: 320, quantity: 1, tint: 0xaa66ff,
                    speedY: { min: -14, max: -4 }, speedX: { min: -8, max: 8 },
                    scale: { min: 0.4, max: 0.9 }, alpha: { start: 0, end: 0.7 },
                    blendMode: 'ADD',
                }).setDepth(38);
                break;
            case 'codex': // glifos verdes subindo, como saída de terminal
                this._weather = this.add.particles(0, 0, 'particle_dot', {
                    x: { min: 0, max: 544 }, y: 486,
                    lifespan: 7000, frequency: 260, quantity: 1, tint: 0x55ffaa,
                    speedY: { min: -40, max: -16 }, speedX: { min: -4, max: 4 },
                    scale: { min: 0.4, max: 0.9 }, alpha: { start: 0.8, end: 0 },
                    blendMode: 'ADD',
                }).setDepth(38);
                break;
            case 'village': // vagalumes — apenas à noite (ligados em _updateDayNight)
                this._fireflies = this.add.particles(0, 0, 'particle_dot', {
                    x: { min: 30, max: 514 }, y: { min: 60, max: 430 },
                    lifespan: 1600, frequency: 380, quantity: 1, tint: 0xffee66,
                    speedY: { min: -8, max: 8 }, speedX: { min: -8, max: 8 },
                    scale: { min: 0.5, max: 0.8 }, alpha: { start: 1, end: 0 },
                    blendMode: 'ADD',
                }).setDepth(41);
                this._fireflies.emitting = DayNight.isNight();
                break;
        }
    }

    // ── Outlier: wisp companheiro que segue o jogador ─────────────────────────

    _setupCompanion() {
        this._companion?.destroy();
        const p = this._playerData;
        if (!p.companionStage) p.companionStage = CompanionSystem.stage(p);
        const sx = this._player.sprite.x - 14;
        const sy = this._player.sprite.y - 12;
        this._companion = this.add.image(sx, sy, CompanionSystem.texKey(p.companionStage)).setDepth(5);
        this._companionT = Math.random() * 1000;
        if (!p.companionMet) {
            p.companionMet = true;
            this.time.delayedCall(1500, () =>
                this._chat('Um pequeno wisp desgarrado começou a te seguir... {{accent:Outlier}} agora é seu companheiro.', 'dialog'));
        }
    }

    _updateCompanion(delta) {
        if (!this._companion || !this._player?.sprite) return;
        this._companionT += delta;
        const bob = Math.sin(this._companionT * 0.004) * 2.5;
        const tx  = this._player.sprite.x - 14;
        const ty  = this._player.sprite.y - 12 + bob;
        const k   = Math.min(1, delta * 0.006);
        this._companion.x += (tx - this._companion.x) * k;
        this._companion.y += (ty - this._companion.y) * k;
    }

    _checkCompanionEvolution() {
        const p     = this._playerData;
        const stage = CompanionSystem.stage(p);
        const prev  = p.companionStage || 1;
        if (stage <= prev) return;
        p.companionStage = stage;
        this._setupCompanion();
        Sound.secret();
        const pct = Math.round(CompanionSystem.xpBonus(stage) * 100);
        this._chat(`{{level:✦ ${CompanionSystem.label(stage)}!}} Seu companheiro evoluiu e agora concede {{xp:+${pct}% de XP}}.`, 'levelup');
        if (this._companion) {
            const ring = this.add.circle(this._companion.x, this._companion.y, 6, CompanionSystem.color(stage), 0)
                .setStrokeStyle(2, CompanionSystem.color(stage), 1).setDepth(30);
            this.tweens.add({
                targets: ring, radius: 30, alpha: 0, duration: 800,
                ease: 'Sine.easeOut', onComplete: () => ring.destroy(),
            });
        }
    }

    // ── Troféus: chefes derrotados viram placas na casa da Anciã ─────────────

    _setupTrophies(areaId) {
        this._trophies?.forEach(t => t.objs.forEach(o => o.destroy()));
        this._trophies = [];
        if (areaId !== 'village_house_elder') return;

        const SLOTS = [
            { instanceId: 'v_boss',  monsterId: 'boss_village',   x: 2  },
            { instanceId: 'me_boss', monsterId: 'boss_meadows',   x: 4  },
            { instanceId: 'fo_boss', monsterId: 'boss_forest',    x: 6  },
            { instanceId: 'pl_boss', monsterId: 'boss_plains',    x: 10 },
            { instanceId: 'mo_boss', monsterId: 'boss_mountains', x: 12 },
            { instanceId: 'du_boss', monsterId: 'boss_dungeon',   x: 14 },
        ];
        const defeated = this._playerData.defeatedMonsters || {};
        for (const slot of SLOTS) {
            const def = MONSTERS[slot.monsterId];
            if (!def) continue;
            const won = !!defeated[slot.instanceId];
            const cx  = slot.x * TILE_SIZE + TILE_SIZE / 2;
            const cy  = TILE_SIZE + 12;
            const objs = [];
            const plaque = this.add.image(cx, cy, 'sprite_trophy').setDepth(6).setAlpha(won ? 1 : 0.18);
            objs.push(plaque);
            if (won) {
                const gem = this.add.circle(cx, cy - 1, 4, def.color || 0xffffff, 1).setDepth(7);
                this.tweens.add({
                    targets: gem, alpha: 0.5, duration: 1400,
                    yoyo: true, repeat: -1, ease: 'Sine.easeInOut',
                });
                objs.push(gem);
            }
            this._trophies.push({ tileX: slot.x, tileY: 1, def, won, objs });
        }
    }

    _showTrophy(trophy) {
        Sound.interact();
        this._paused = true;
        const lines = trophy.won
            ? [`{{accent:${trophy.def.name}}} — guardião de nível ${trophy.def.level}, derrotado por você.`, trophy.def.flavor]
            : ['Um suporte vazio. A Anciã reservou este lugar para o troféu de um guardião que ainda vive...'];
        this.scene.launch('Dialog', {
            speaker: 'Troféu de Caçada',
            lines,
            role: 'lore',
            onClose: () => { this._paused = false; },
        });
    }

    // ── Update loop ───────────────────────────────────────────────────────────

    update(time, delta) {
        if (this._paused) return;

        const moved = this._player.update(delta, this._cursors, this._wasd, this._mapManager);
        if (moved) {
            this._playerData.position = { ...moved };
            this._revealTiles(moved.x, moved.y);
            this._checkTileInteractions(moved.x, moved.y);
            EventBus.emit('minimap-update', { mapMgr: this._mapManager, player: this._playerData });
            this._maybeNearPortalTutorial(moved.x, moved.y);
            this._maybeNearMerchantTutorial(moved.x, moved.y);
        }

        for (const m of this._monsters) m.update(delta, this._mapManager);

        this._syncAuraPosition();
        this._updateDarkness(time);
        this._updateDayNight();
        this._updateShadows();
        this._updateCompanion(delta);

        if (Phaser.Input.Keyboard.JustDown(this._spaceKey) && !this._spaceLock) this._tryInteract();
        if (Phaser.Input.Keyboard.JustDown(this._iKey)) this._openOverlay('Inventory');
        if (Phaser.Input.Keyboard.JustDown(this._cKey)) this._openOverlay('Character');
        if (Phaser.Input.Keyboard.JustDown(this._qKey)) this._openOverlay('Quest');
        if (Phaser.Input.Keyboard.JustDown(this._bKey)) this._openOverlay('Book');
        if (Phaser.Input.Keyboard.JustDown(this._kKey)) this._openOverlay('Skill');
        if (Phaser.Input.Keyboard.JustDown(this._lKey)) this._openOverlay('Compendium');
        if (Phaser.Input.Keyboard.JustDown(this._nKey)) this._openOverlay('Scratchpad');
        if (Phaser.Input.Keyboard.JustDown(this._f5Key)) {
            SaveSystem.autoSave(this._playerData);
            Sound.save();
            EventBus.emit('autosave');
        }
        if (Phaser.Input.Keyboard.JustDown(this._escKey)) this._openPauseMenu();

        this._processRespawns(time);
    }

    _openOverlay(sceneKey) {
        Sound.menuOpen();
        this.scene.launch(sceneKey);
        this._paused = true;
    }

    // ── Menu de pausa (ESC) ───────────────────────────────────────────────────

    _openPauseMenu() {
        if (this._pauseMenu) return;
        this._paused = true;
        this._autoSync();
        Sound.menuOpen();

        const W = 544, H = 480;
        const c = this.add.container(0, 0).setDepth(300);
        this._pauseMenu = c;
        c.add(this.add.rectangle(0, 0, W, H, 0x000000, 0.72).setOrigin(0, 0).setInteractive());

        const pw = 260, ph = 236;
        const px = (W - pw) / 2, py = (H - ph) / 2;
        c.add(this.add.rectangle(px, py, pw, ph, 0x0d0a12, 1).setOrigin(0, 0)
            .setStrokeStyle(2, 0xd4af37, 0.8));
        c.add(this.add.rectangle(px, py, pw, 3, 0xd4af37, 0.9).setOrigin(0, 0));
        c.add(this.add.text(W / 2, py + 16, 'PAUSA', {
            fontSize: '20px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#000000', strokeThickness: 4,
        }).setOrigin(0.5, 0));

        const mkBtn = (y, label, color, borderColor, cb) => {
            const bg = this.add.rectangle(W / 2 - 100, y, 200, 34, 0x141020, 1).setOrigin(0, 0)
                .setStrokeStyle(1, borderColor, 0.7)
                .setInteractive({ useHandCursor: true })
                .on('pointerover', () => bg.setFillStyle(0x201838))
                .on('pointerout',  () => bg.setFillStyle(0x141020))
                .on('pointerdown', cb);
            const tx = this.add.text(W / 2, y + 17, label, {
                fontSize: '13px', color, fontFamily: 'Courier New', fontStyle: 'bold',
            }).setOrigin(0.5, 0.5);
            c.add([bg, tx]);
            return tx;
        };

        mkBtn(py + 56,  '▶  CONTINUAR', '#88ff88', 0x33aa55, () => this._closePauseMenu());
        const saveTx = mkBtn(py + 100, '✦  SALVAR JOGO', '#88ccff', 0x3355aa, () => {
            SaveSystem.autoSave(this._playerData);
            Sound.save();
            EventBus.emit('autosave');
            saveTx.setText('✓  SALVO!').setColor('#44ff88');
            this.time.delayedCall(1200, () => saveTx?.setText('✦  SALVAR JOGO').setColor('#88ccff'));
        });
        mkBtn(py + 144, '⌂  MENU PRINCIPAL', '#ffaa66', 0xaa6633, () => {
            SaveSystem.autoSave(this._playerData);
            this._closePauseMenu();
            Music.stop();
            this.scene.stop('UI');
            this.scene.start('MainMenu');
        });

        c.add(this.add.text(W / 2, py + ph - 22, '[ESC] para continuar', {
            fontSize: '10px', color: '#555555', fontFamily: 'Courier New',
        }).setOrigin(0.5, 0));

        this._pauseEsc = (e) => { if (e.key === 'Escape') this._closePauseMenu(); };
        this.input.keyboard.on('keydown', this._pauseEsc);
    }

    _closePauseMenu() {
        if (!this._pauseMenu) return;
        this.input.keyboard.off('keydown', this._pauseEsc);
        this._pauseMenu.destroy();
        this._pauseMenu = null;
        // O ESC que fechou ainda está como JustDown (update estava pausado);
        // sem o reset, o próximo frame reabriria o menu imediatamente
        this._escKey.reset();
        this._paused = false;
        Sound.menuClose();
    }

    // ── Regen tick ────────────────────────────────────────────────────────────

    _regenTick() {
        if (this._paused) return;
        const p = this._playerData;
        const hpRegen    = REGEN_HP_PER_TICK    + SkillSystem.effectsOf(p, 'hpRegenBonus');
        const focusRegen = REGEN_FOCUS_PER_TICK + SkillSystem.effectsOf(p, 'focusRegenBonus');
        let changed = false;
        if (p.hp < p.maxHp) { p.hp = Math.min(p.maxHp, p.hp + hpRegen); changed = true; }
        if (p.focus < p.maxFocus) { p.focus = Math.min(p.maxFocus, p.focus + focusRegen); changed = true; }
        if (changed) EventBus.emit('player-hp-change', { player: p });
    }

    _spawnRespawnEffect(monster) {
        // Visual fanfare when a creature reappears: pulsing rings + sprite fade-in
        Sound.respawn();
        const cx = monster.tileX * TILE_SIZE + TILE_SIZE / 2;
        const cy = monster.tileY * TILE_SIZE + TILE_SIZE / 2;
        const elemColor = monster.def.color || 0xffffff;

        // Sprite fade in from invisible + scale punch
        if (monster.sprite) {
            monster.sprite.setAlpha(0).setScale(0.2);
            this.tweens.add({
                targets: monster.sprite, alpha: 1, scale: 1,
                duration: 600, ease: 'Back.easeOut',
            });
        }
        if (monster._nameLabel) {
            monster._nameLabel.setAlpha(0);
            this.tweens.add({ targets: monster._nameLabel, alpha: 1, duration: 800, delay: 200 });
        }

        // Two expanding rings of color
        const makeRing = (delay) => {
            const ring = this.add.circle(cx, cy, 4, elemColor, 0).setStrokeStyle(2, elemColor, 0.9).setDepth(7);
            this.tweens.add({
                targets: ring,
                radius: 24, alpha: 0,
                duration: 700, delay,
                ease: 'Sine.easeOut',
                onComplete: () => ring.destroy(),
            });
        };
        makeRing(0);
        makeRing(180);

        // Sparkle particles around the spawn point
        for (let i = 0; i < 8; i++) {
            const a = (i / 8) * Math.PI * 2;
            const dx = Math.cos(a) * 16;
            const dy = Math.sin(a) * 16;
            const spark = this.add.rectangle(cx, cy, 2, 2, 0xffffff, 1).setDepth(8);
            this.tweens.add({
                targets: spark,
                x: cx + dx, y: cy + dy, alpha: 0,
                duration: 600,
                ease: 'Quad.easeOut',
                onComplete: () => spark.destroy(),
            });
        }
    }

    _processRespawns(now) {
        if (!this._respawns?.length) return;
        const ready = this._respawns.filter(r => now >= r.respawnAt && r.areaId === this._playerData.currentArea);
        for (const r of ready) {
            if (this._playerData.defeatedMonsters) delete this._playerData.defeatedMonsters[r.instanceId];
            const md = (this._mapManager.mapData?.monsters || []).find(m => m.instanceId === r.instanceId);
            if (md && this._mapManager.isWalkable(md.x, md.y) && !this._monsters.some(m => m.instanceId === r.instanceId)) {
                const newMon = new Monster(this, md);
                this._monsters.push(newMon);
                this._spawnRespawnEffect(newMon);
                this._chat(`{{accent:${newMon.def.name}}} reapareceu na região.`, 'system');
            }
        }
        this._respawns = this._respawns.filter(r => !ready.includes(r));
    }

    // ── Fog of war ────────────────────────────────────────────────────────────

    _revealTiles(cx, cy, radius = 3) {
        const area = this._playerData.currentArea;
        if (!this._playerData.discoveredTiles) this._playerData.discoveredTiles = {};
        if (!this._playerData.discoveredTiles[area]) this._playerData.discoveredTiles[area] = {};
        const map = this._playerData.discoveredTiles[area];
        for (let dy = -radius; dy <= radius; dy++) {
            for (let dx = -radius; dx <= radius; dx++) {
                map[`${cx + dx},${cy + dy}`] = true;
            }
        }
    }

    // ── Tile interactions ─────────────────────────────────────────────────────

    _checkTileInteractions(col, row) {
        const exit = this._mapManager.getExit(col, row);
        if (exit) { this._tryPortal(exit); return; }

        if (this._waygate && col === this._waygate.x && row === this._waygate.y) {
            this._openWaygate();
            return;
        }

        const hit = this._monsters.find(m => m.isAt(col, row));
        if (hit) this._startCombat(hit);
    }

    // ── Viagem rápida: círculo de teletransporte na Vila ──────────────────────

    _setupWaygate(areaId) {
        this._waygateObjs?.forEach(o => o.destroy());
        this._waygateObjs = [];
        this._waygate = null;
        if (areaId !== 'village') return;

        this._waygate = { x: 9, y: 13 };
        const cx = this._waygate.x * TILE_SIZE + TILE_SIZE / 2;
        const cy = this._waygate.y * TILE_SIZE + TILE_SIZE / 2;

        const ring = this.add.circle(cx, cy, 12, 0x66ccff, 0.12).setDepth(1)
            .setStrokeStyle(2, 0x66ccff, 0.7);
        this.tweens.add({
            targets: ring, scale: 1.25, alpha: 0.5,
            duration: 1300, yoyo: true, repeat: -1, ease: 'Sine.easeInOut',
        });
        const core = this.add.circle(cx, cy, 4, 0xaaeeff, 0.8).setDepth(1);
        this.tweens.add({ targets: core, alpha: 0.3, duration: 900, yoyo: true, repeat: -1 });
        const lbl = this.add.text(cx, cy - 18, 'VIAGEM', {
            fontSize: '8px', color: '#88ddff', backgroundColor: '#00000088',
        }).setOrigin(0.5).setDepth(6);
        this._waygateObjs = [ring, core, lbl];
    }

    _openWaygate() {
        const p = this._playerData;
        const SURFACES = ['meadows', 'forest', 'plains', 'mountains', 'dungeon'];
        const visited = SURFACES.filter(a => Object.keys(p.discoveredTiles?.[a] || {}).length > 0);

        Sound.interact();
        this._paused = true;
        if (!visited.length) {
            this.scene.launch('Dialog', {
                speaker: 'Círculo Rúnico', role: 'lore',
                lines: ['O círculo pulsa fracamente... Ele só pode levá-lo a lugares que você já conhece. Explore o mundo e volte.'],
                onClose: () => { this._paused = false; },
            });
            return;
        }

        const choices = visited.map(a => ({
            label: AREA_INFO[a]?.displayName || a,
            onSelect: () => {
                this._paused = false;
                this._doPortalTransition({ targetArea: a, targetSpawn: { ...MAP_DATA[a].spawn } });
            },
        }));
        // ESC seleciona a última opção — mantenha "Cancelar" no fim
        choices.push({ label: 'Cancelar', onSelect: () => { this._paused = false; } });

        this.scene.launch('Dialog', {
            speaker: 'Círculo Rúnico', role: 'lore',
            lines: ['As runas da Sociedade reconhecem você. Para onde deseja viajar?'],
            choices,
            onClose: () => { this._paused = false; },
        });
    }

    _updateQuestIcons() {
        this._npcIcons.getChildren().forEach(icon => {
            const quests = QuestSystem.questsForNPC(this._playerData, icon.npcId);
            const hasComplete = quests.some(q => q.status === 'complete');
            const hasAvailable = quests.some(q => q.status === 'available');
            if (hasComplete) {
                icon.setText('?').setColor('#44ff88').setVisible(true);
            } else if (hasAvailable) {
                icon.setText('!').setColor('#ffd700').setVisible(true);
            } else {
                icon.setVisible(false);
            }
        });
    }

    _maybeNearPortalTutorial(col, row) {
        const exits = this._mapManager.mapData?.exits || [];
        const close = exits.some(e => Math.abs(e.x - col) + Math.abs(e.y - row) <= 1);
        if (close) TutorialSystem.trigger(this._playerData, this, 'near_portal');
    }

    _maybeNearMerchantTutorial(col, row) {
        const merchant = this._npcs.find(n => n.role === 'shop' && Math.abs(n.tileX - col) + Math.abs(n.tileY - row) <= 1);
        if (merchant) TutorialSystem.trigger(this._playerData, this, 'near_merchant');
    }

    _tryPortal(exit) {
        const nextArea = exit.targetArea;
        const isHouse  = nextArea.includes('house');

        // Play door sound for house entries
        if (isHouse) Sound.door();

        // Back portals, house interiors and holes bypass all lock/boss checks —
        // the depths are open to anyone brave (or careless) enough to descend
        if (!exit.isBack && !isHouse && !exit.isHole) {
            const unlock = AREA_UNLOCK[nextArea];
            if (unlock) {
                const player  = this._playerData;
                const mastery = masteryPercent(player.mastery[unlock.masteryArea]);
                const levelOk = !unlock.minLevel || player.level >= unlock.minLevel;
                const mastOk  = mastery >= unlock.masteryPct;

                if (!levelOk || !mastOk) {
                    const reasons = [];
                    if (!levelOk) reasons.push(`{{level:nível ${unlock.minLevel}}}`);
                    if (!mastOk)  reasons.push(`{{accent:${unlock.masteryPct}% de maestria}} em {{accent:${AREA_INFO[unlock.masteryArea]?.displayName}}}`);
                    Sound.denied();
                    this._chat(`{{bad:Portal bloqueado!}} Você precisa de: ${reasons.join(' e ')}.`, 'error');
                    this._playerData.position.y -= 1;
                    this._player.syncSprite();
                    return;
                }
            }

            // Boss gate — each area's boss must be defeated before using the exit
            const bossEntry = AREA_BOSS[this._playerData.currentArea];
            if (bossEntry) {
                const defeated = this._playerData.defeatedMonsters || {};
                const bossDef  = MONSTERS[bossEntry.monsterId];
                if (bossDef) {
                    if (!defeated[bossEntry.instanceId]) {
                        // Boss not yet defeated — force encounter
                        this._chat(`☠ {{bad:${bossDef.name.toUpperCase()} BLOQUEIA A SAÍDA!}} Derrote o chefe para avançar.`, 'error');
                        this._portalBoss = { def: bossDef, instanceId: bossEntry.instanceId };
                        this.time.delayedCall(900, () => this._startCombat(this._portalBoss));
                        return;
                    } else {
                        // Boss already defeated — offer rematch
                        this._showBossRematchDialog(bossDef, bossEntry, exit);
                        return;
                    }
                }
            }
        }

        this._doPortalTransition(exit);
    }

    _showBossRematchDialog(bossDef, bossEntry, exit) {
        if (this._rematchOverlay) return;
        this._paused = true;

        const W = 544, H = 480;
        const container = this.add.container(0, 0).setDepth(100);
        this._rematchOverlay = container;

        // Dim
        const dim = this.add.rectangle(0, 0, W, H, 0x000000, 0.75).setOrigin(0, 0).setInteractive();
        container.add(dim);

        // Card
        const cx = W / 2, cy = H / 2;
        const cardW = 320, cardH = 180;
        const card = this.add.rectangle(cx, cy, cardW, cardH, 0x1a0808, 1);
        card.setStrokeStyle(2, 0xff4400);
        container.add(card);

        // Title
        container.add(this.add.text(cx, cy - 68, '☠ REVANCHE', {
            fontSize: '18px', color: '#ff6622', fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#000000', strokeThickness: 4,
        }).setOrigin(0.5));

        container.add(this.add.text(cx, cy - 44, bossDef.name, {
            fontSize: '14px', color: '#ffcc88', fontFamily: 'Courier New',
        }).setOrigin(0.5));

        container.add(this.add.text(cx, cy - 18, 'Você já derrotou este chefe.\nDeseja enfrentá-lo novamente?', {
            fontSize: '13px', color: '#cccccc', fontFamily: 'Courier New', align: 'center',
        }).setOrigin(0.5));

        // YES button
        const yesBg = this.add.rectangle(cx - 60, cy + 48, 100, 32, 0x3a0a00).setStrokeStyle(1, 0xff4400).setInteractive({ useHandCursor: true });
        const yesTx = this.add.text(cx - 60, cy + 48, 'ENFRENTAR', { fontSize: '12px', color: '#ff8844', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0.5);
        yesBg.on('pointerover',  () => yesBg.setFillStyle(0x660f00));
        yesBg.on('pointerout',   () => yesBg.setFillStyle(0x3a0a00));
        yesBg.on('pointerdown',  () => {
            this.input.keyboard.off('keydown', kbHandler);
            container.destroy();
            this._rematchOverlay = null;
            this._paused = false;
            this._portalBoss = { def: bossDef, instanceId: bossEntry.instanceId };
            this.time.delayedCall(200, () => this._startCombat(this._portalBoss));
        });
        container.add([yesBg, yesTx]);

        // NO button
        const noBg = this.add.rectangle(cx + 60, cy + 48, 100, 32, 0x0a0a0a).setStrokeStyle(1, 0x555555).setInteractive({ useHandCursor: true });
        const noTx = this.add.text(cx + 60, cy + 48, 'AVANÇAR', { fontSize: '12px', color: '#aaaaaa', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0.5);
        noBg.on('pointerover',  () => noBg.setFillStyle(0x222222));
        noBg.on('pointerout',   () => noBg.setFillStyle(0x0a0a0a));
        noBg.on('pointerdown',  () => {
            this.input.keyboard.off('keydown', kbHandler);
            container.destroy();
            this._rematchOverlay = null;
            this._paused = false;
            this._doPortalTransition(exit);
        });
        container.add([noBg, noTx]);

        container.add(this.add.text(cx, cy + 72, '[ESC] para avançar', {
            fontSize: '10px', color: '#444444', fontFamily: 'Courier New',
        }).setOrigin(0.5));

        const kbHandler = (event) => {
            if (event.key !== 'Escape') return;
            this.input.keyboard.off('keydown', kbHandler);
            if (!container.active) return;
            container.destroy();
            this._rematchOverlay = null;
            this._paused = false;
            this._doPortalTransition(exit);
        };
        this.input.keyboard.on('keydown', kbHandler);
    }

    _doPortalTransition(exit) {
        if (this._transitioning) return;
        this._transitioning = true;
        this._paused = true;

        const nextArea = exit.targetArea;

        if (nextArea === 'village' && this._playerData.currentArea !== 'village') {
            const heal = this._playerData.maxHp - this._playerData.hp;
            if (heal > 0) {
                this._playerData.hp    = this._playerData.maxHp;
                this._playerData.focus = this._playerData.maxFocus;
                this._chat('Você descansa na vila e {{heal:recupera todas as suas energias}}!', 'heal');
                EventBus.emit('player-hp-change', { player: this._playerData });
                this._player.syncSprite();
            }
        }

        // Play door sound when exiting a house back to main world
        if (this._playerData.currentArea.includes('house')) {
            Sound.door();
        }

        if (exit.isHole) {
            this._chat(`Você desce pela escuridão rumo a {{accent:${AREA_INFO[nextArea]?.displayName}}}...`, 'portal');
            Sound.fall();
        } else if (this._playerData.currentArea.endsWith('_depths')) {
            this._chat(`Você sobe de volta à luz de {{accent:${AREA_INFO[nextArea]?.displayName}}}...`, 'portal');
            Sound.door();
        } else {
            this._chat(`Viajando para {{accent:${AREA_INFO[nextArea]?.displayName}}}...`, 'portal');
            Sound.portal();
        }

        const px = this._player.sprite.x;
        const py = this._player.sprite.y;
        this._spawnPortalEffect(px, py, nextArea);

        this.time.delayedCall(220, () => {
            this.cameras.main.fade(480, 0, 0, 0, false, (_cam, progress) => {
                if (progress < 1) return;

                this._playerData.currentArea      = nextArea;
                this._playerData.position         = { ...exit.targetSpawn };
                this._playerData.lastSafePosition = { ...exit.targetSpawn };
                this._playerData.lastSafeArea     = nextArea;
                this.registry.set('player', this._playerData);
                SaveSystem.autoSave(this._playerData);

                this._loadArea(nextArea);
                this._revealTiles(exit.targetSpawn.x, exit.targetSpawn.y);
                EventBus.emit('area-changed',   { areaId: nextArea });
                EventBus.emit('minimap-update', { mapMgr: this._mapManager, player: this._playerData });

                this._transitioning = false;
                this._paused        = false;

                this.cameras.main.fadeIn(650, 0, 0, 0);
                this._showAreaBanner(nextArea);
            });
        });
    }

    _spawnPortalEffect(px, py, targetArea) {
        const COLOR_MAP = {
            village: 0x88ddff, meadows: 0x88ee88, forest: 0x44bb44,
            plains:  0xff9944, mountains: 0x8899ff, dungeon: 0xcc44ff,
        };
        const color = COLOR_MAP[targetArea] || 0xffffff;

        // Three expanding rings with staggered delay
        [0, 140, 280].forEach((delay, i) => {
            const ring = this.add.circle(px, py, 6, 0, 0).setDepth(30);
            ring.setStrokeStyle(3 - i * 0.5, color, 1);
            this.tweens.add({
                targets: ring,
                scaleX: 7, scaleY: 7, alpha: 0,
                duration: 650, delay,
                ease: 'Cubic.Out',
                onComplete: () => ring.destroy(),
            });
        });

        // Sparkle particles radiating outward
        for (let i = 0; i < 14; i++) {
            const angle = (i / 14) * Math.PI * 2;
            const dist  = 28 + Math.random() * 28;
            const size  = 1.5 + Math.random() * 2;
            const p = this.add.circle(px, py, size, color, 0.95).setDepth(30);
            this.tweens.add({
                targets: p,
                x: px + Math.cos(angle) * dist,
                y: py + Math.sin(angle) * dist,
                alpha: 0, scaleX: 0, scaleY: 0,
                duration: 400 + Math.random() * 200,
                ease: 'Quad.Out',
                onComplete: () => p.destroy(),
            });
        }

        // Central bright flash circle
        const flash = this.add.circle(px, py, 14, color, 0.6).setDepth(29);
        this.tweens.add({
            targets: flash, alpha: 0, scaleX: 3, scaleY: 3,
            duration: 300, ease: 'Cubic.Out',
            onComplete: () => flash.destroy(),
        });

        // Player sprite squeezes upward and vanishes
        if (this._player?.sprite) {
            this.tweens.add({
                targets: this._player.sprite,
                scaleY: 0, alpha: 0,
                duration: 340, ease: 'Cubic.In',
            });
        }
    }

    _showAreaBanner(areaId) {
        const info = AREA_INFO[areaId];
        if (!info) return;
        const W = this.scale.width, H = this.scale.height;

        // Dark backing strip
        const strip = this.add.rectangle(0, H / 2, W, 50, 0x000000, 0.6)
            .setOrigin(0, 0.5).setScrollFactor(0).setDepth(50).setAlpha(0);

        // Area name
        const nameTx = this.add.text(W / 2, H / 2 - 5, info.displayName.toUpperCase(), {
            fontSize: '22px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#000000', strokeThickness: 5,
        }).setOrigin(0.5).setScrollFactor(0).setDepth(51).setAlpha(0);

        // Sub-label (topic)
        const subTx = this.add.text(W / 2, H / 2 + 16, info.topic, {
            fontSize: '13px', color: '#aaaaaa', fontFamily: 'Courier New', fontStyle: 'italic',
        }).setOrigin(0.5).setScrollFactor(0).setDepth(51).setAlpha(0);

        const objs = [strip, nameTx, subTx];

        // Fade in
        this.tweens.add({
            targets: objs, alpha: 1, duration: 380, ease: 'Cubic.Out',
            onComplete: () => {
                // Hold then fade out
                this.time.delayedCall(1100, () => {
                    this.tweens.add({
                        targets: objs, alpha: 0, duration: 420, ease: 'Cubic.In',
                        onComplete: () => objs.forEach(o => o.destroy()),
                    });
                });
            },
        });
    }

    _startCombat(monster) {
        this._paused = true;
        this._playerData.lastSafePosition = { ...this._playerData.position };
        this.registry.set('player', this._playerData);

        // Tutorial do primeiro combate: o diálogo abre por cima de tudo, então
        // o combate só começa quando ele fechar (antes, fechá-lo despausava o
        // mundo com o combate já aberto e engolia os cliques do jogador)
        const tipShown = TutorialSystem.trigger(this._playerData, this, 'first_monster',
            () => this._beginCombat(monster));
        if (tipShown) return;
        this._beginCombat(monster);
    }

    _beginCombat(monster) {
        this._paused = true; // resumeFromOverlay do tutorial despausa — repausa aqui

        // ── Combat Entry Animation ───────────────────────────────────────────
        
        // Stop following the player to allow custom pan/zoom
        this.cameras.main.stopFollow();
        
        // Shake and Flash
        this.cameras.main.shake(400, 0.015);
        this.cameras.main.flash(400, 255, 255, 255);

        // Zoom and Pan towards the monster
        if (monster.sprite) {
            this.cameras.main.pan(monster.sprite.x, monster.sprite.y, 400, 'Quad.easeIn');
            this.cameras.main.zoomTo(2.5, 400, 'Quad.easeIn');
        }

        // Wait for animation to finish before launching CombatScene
        this.time.delayedCall(450, () => {
            Music.play(monster.def?.isBoss ? 'boss' : 'combat');
            this.scene.launch('Combat', { monster: monster.def, instanceId: monster.instanceId });
            
            // Reset camera immediately behind the overlay — map is always
            // 544×480 = canvas size, so scroll (0,0) is always correct.
            this.cameras.main.setZoom(1);
            this.cameras.main.setScroll(0, 0);
        });
    }

    // ── Combat result ─────────────────────────────────────────────────────────

    _onCombatEnd({ outcome, instanceId, xpGained, loot, playerData, maxStreak = 0, allCorrect = false, feverReached = false, isElite = false, isMimic = false }) {
        this._paused = false;

        if (playerData) {
            Object.assign(this._playerData, playerData);
            if (this._player) {
                Object.assign(this._player, playerData);
            }
            this.registry.set('player', this._playerData);
        }

        AchievementSystem.recordCombat(this._playerData, { outcome, maxStreak, allCorrect, isElite, isMimic });
        AchievementSystem.check(this._playerData, { outcome, maxStreak, allCorrect, feverReached, isElite, isMimic });
        this._checkCompanionEvolution();

        if (outcome === 'win') {
            const idx = this._monsters.findIndex(m => m.instanceId === instanceId);
            let defDef = null;
            if (idx !== -1) {
                defDef = this._monsters[idx].def;
                this._monsters[idx].destroy();
                this._monsters.splice(idx, 1);
                if (!this._playerData.defeatedMonsters) this._playerData.defeatedMonsters = {};
                this._playerData.defeatedMonsters[instanceId] = true;
            } else if (this._portalBoss?.instanceId === instanceId) {
                // Boss was triggered by portal gate, not a map entity
                defDef = this._portalBoss.def;
                this._portalBoss = null;
                if (!this._playerData.defeatedMonsters) this._playerData.defeatedMonsters = {};
                this._playerData.defeatedMonsters[instanceId] = true;
            }
            if (defDef) {
                QuestSystem.recordKill(this._playerData, defDef);
                BountySystem.recordKill(this._playerData, defDef);
                if (!defDef.isBoss) {
                    const weight = defDef.spawnWeight ?? 10;
                    const respawnDelay = Math.round(RESPAWN_TIME * (10 / weight));
                    this._respawns.push({
                        instanceId, areaId: this._playerData.currentArea,
                        respawnAt: this.time.now + respawnDelay,
                    });
                }
                if (defDef.isBoss) {
                    this._chat(`☠ {{level:CHEFE DERROTADO!}} {{accent:${defDef.name}}} foi vencido!`, 'levelup');
                    if (this._mapManager.mapData?.exits?.length > 0) {
                        this.time.delayedCall(600, () =>
                            this._chat('{{accent:O portal está livre!}} Você pode avançar para a próxima área.', 'portal')
                        );
                    }
                }
            }
            if (xpGained) this._chat(`Você obteve {{xp:+${xpGained} XP}} na batalha!`, 'xp');
            if (loot?.length) {
                Sound.coins();
                this._chat(`{{accent:RECOMPENSAS:}} ${loot.join(', ')}`, 'loot');
                this._playerData.pendingItemAlert = true;
                EventBus.emit('item-alert', { player: this._playerData });
                if (loot.some(s => s.includes('Livro:'))) {
                    TutorialSystem.trigger(this._playerData, this, 'first_book');
                }
            }
            SaveSystem.autoSave(this._playerData);
            EventBus.emit('player-hp-change', { player: this._playerData });

        } else if (outcome === 'loss') {
            const respawnData = {
                ...this._playerData,
                hp: Math.floor(this._playerData.maxHp * 0.5),
                position: { ...this._playerData.lastSafePosition },
                currentArea: this._playerData.lastSafeArea,
            };
            this.registry.set('player', respawnData);
            Music.stop();
            this.scene.stop('UI');
            this.scene.start('GameOver', { playerData: respawnData });
            return;
        }

        // Julgamento: encadeia o próximo guardião, conclui, ou aborta na fuga
        if (this._gauntlet) {
            if (outcome === 'win') {
                this._gauntlet.index++;
                if (this._gauntlet.index < SANCTUM_GAUNTLET.length) {
                    const next = MONSTERS[SANCTUM_GAUNTLET[this._gauntlet.index]];
                    this._chat(`{{bad:O próximo juiz desperta:}} {{accent:${next.name}}} (${this._gauntlet.index + 1}/${SANCTUM_GAUNTLET.length})...`, 'combat-hit');
                    this.time.delayedCall(1600, () => this._launchGauntletCombat());
                    return; // segue em combate: não retoma a música da área
                }
                this._gauntlet = null;
                this._completeSanctum();
            } else {
                this._gauntlet = null;
                this._chat('{{bad:O Julgamento foi interrompido.}} Os guardiões retornam ao silêncio — o altar aguarda outra tentativa.', 'error');
            }
        }

        EventBus.emit('minimap-update', { mapMgr: this._mapManager, player: this._playerData });
        Music.play(this._musicKeyFor(this._playerData.currentArea));
    }

    _onLevelUp() {
        TutorialSystem.trigger(this._playerData, this, 'first_levelup');
        this._chat('{{level:SUBIU DE NÍVEL!}} Seus atributos aumentaram.', 'levelup');
        AchievementSystem.check(this._playerData);
        this.time.delayedCall(600, () => this._maybeOpenSkill());
    }

    _maybeOpenSkill() {
        const pending = SkillSystem.pendingChoices(this._playerData);
        if (pending.length > 0) {
            this._chat(`{{accent:Pressione K}} para escolher uma nova habilidade!`, 'levelup');
            EventBus.emit('skill-alert', { player: this._playerData });
        }
    }

    // ── Interaction ──────────────────────────────────────────────────────────

    _tryInteract() {
        const col = this._playerData.position.x;
        const row = this._playerData.position.y;

        // Check for adjacent NPCs
        const npc = this._npcs.find(n => n.isAdjacentTo(col, row));
        if (npc) {
            this._interactNPC(npc);
            return;
        }

        // Trophy plaques in the elder's house
        const trophy = (this._trophies || []).find(t =>
            Math.abs(t.tileX - col) + Math.abs(t.tileY - row) === 1);
        if (trophy) {
            this._showTrophy(trophy);
            return;
        }

        // Check for adjacent Chests (Tile 7)
        const adj = [
            { x: col, y: row - 1 }, { x: col, y: row + 1 },
            { x: col - 1, y: row }, { x: col + 1, y: row }
        ];
        for (const pos of adj) {
            // Check for tile-based chests
            if (this._mapManager.getTileId(pos.x, pos.y) === 7) {
                this._interactChest(pos.x, pos.y);
                return;
            }

            // Check for scroll sprites
            const scroll = this._mapManager.getScrollAt(pos.x, pos.y);
            if (scroll) {
                this._interactScroll(scroll);
                return;
            }

            // Secret walls (tile 26): pushing them opens a hidden passage
            if (this._mapManager.getTileId(pos.x, pos.y) === 26) {
                this._revealSecret(pos.x, pos.y);
                return;
            }

            // Dig sites (tile 27): a shovel opens them into a hole
            if (this._mapManager.getTileId(pos.x, pos.y) === 27) {
                this._digSite(pos.x, pos.y);
                return;
            }

            // Cracked boulders (tile 28): a pickaxe clears the passage
            if (this._mapManager.getTileId(pos.x, pos.y) === 28) {
                this._breakBoulder(pos.x, pos.y);
                return;
            }

            // The Sanctum altar (tile 29): offers the judgement gauntlet
            if (this._mapManager.getTileId(pos.x, pos.y) === 29) {
                this._interactAltar();
                return;
            }
        }
    }

    _hasTool(itemId) {
        return (this._playerData.inventory || []).some(s => s.itemId === itemId && s.qty > 0);
    }

    _digSite(x, y) {
        if (!this._hasTool('shovel')) {
            Sound.denied();
            this._chat('O solo aqui foi revirado — algo está {{accent:enterrado}}. Você precisa de uma {{accent:Pá do Escavador}}.', 'system');
            return;
        }
        if (!this._mapManager.digSite(x, y)) return;
        this._playerData.dugSites[`${this._playerData.currentArea}:${x}:${y}`] = true;
        Sound.secret();
        this.cameras.main.shake(300, 0.01);
        this._chat('{{accent:A pá afunda na terra solta...}} Você desenterrou um {{level:buraco escuro}}!', 'levelup');
        SaveSystem.autoSave(this._playerData);
    }

    _breakBoulder(x, y) {
        if (!this._hasTool('pickaxe')) {
            Sound.denied();
            this._chat('Uma rocha {{accent:rachada}} bloqueia a passagem. Uma {{accent:Picareta de Ferro}} daria conta dela.', 'system');
            return;
        }
        if (!this._mapManager.breakBoulder(x, y)) return;
        this._playerData.dugSites[`${this._playerData.currentArea}:${x}:${y}`] = true;
        Sound.secret();
        this.cameras.main.shake(300, 0.012);
        this._chat('{{accent:A rocha se parte com um estalo!}} A passagem está livre.', 'levelup');
        SaveSystem.autoSave(this._playerData);
    }

    _revealSecret(x, y) {
        if (!this._mapManager.revealSecret(x, y)) return;
        this._playerData.secretsFound[`${this._playerData.currentArea}:${x}:${y}`] = true;
        Sound.secret();
        this.cameras.main.shake(250, 0.008);
        this._chat('{{accent:A parede cede...}} Você encontrou uma {{level:passagem secreta}}!', 'levelup');
        SaveSystem.autoSave(this._playerData);
    }

    // ── O Julgamento (gauntlet da Câmara da Hipótese Nula) ───────────────────

    _interactAltar() {
        if (this._gauntlet) return; // julgamento já em andamento (evita reabrir/duplicar)
        Sound.interact();
        this._paused = true;
        const cleared = !!this._playerData.sanctumCleared;
        const lines = cleared
            ? [
                'O altar está em silêncio. Os quatro guardiões reconhecem você — {{good:o Julgamento já foi vencido}}.',
                'Mas a Câmara permanece aberta a quem deseja provar-se outra vez.',
            ]
            : [
                'Uma voz sem corpo preenche a câmara: {{accent:"Aproxima-se um aprendiz. Que seja julgado."}}',
                '{{bad:Quatro guardiões, um após o outro. Sem itens. Sem descanso entre as lutas. A fuga encerra tudo.}}',
                'Apenas seu conhecimento entra na arena. Deseja ser julgado?',
            ];
        this.scene.launch('Dialog', {
            speaker: 'O Altar do Julgamento',
            lines,
            role: 'lore',
            choices: [
                { label: cleared ? '⚔ DESAFIAR NOVAMENTE' : '⚔ ACEITAR O JULGAMENTO', onSelect: () => {
                    this._paused = false;
                    this._startGauntlet();
                }},
                { label: '↩ RECUAR', onSelect: () => { this._paused = false; } },
            ],
            onClose: () => { this._paused = false; },
        });
    }

    _startGauntlet() {
        this._gauntlet = { index: 0 };
        this._chat('{{bad:O JULGAMENTO COMEÇA.}} Quatro guardiões aguardam — sua mochila foi selada.', 'combat-hit');
        this.time.delayedCall(900, () => this._launchGauntletCombat());
    }

    _launchGauntletCombat() {
        if (!this._gauntlet) return;
        const i = this._gauntlet.index;
        const def = MONSTERS[SANCTUM_GAUNTLET[i]];
        if (!def) { this._gauntlet = null; return; }

        this._paused = true;
        this._playerData.lastSafePosition = { ...this._playerData.position };
        this.registry.set('player', this._playerData);

        this.cameras.main.shake(350, 0.012);
        this.cameras.main.flash(350, 120, 60, 200);
        this.time.delayedCall(400, () => {
            Music.play(def.isBoss ? 'boss' : 'combat');
            this.scene.launch('Combat', {
                monster: def,
                instanceId: `sanctum_g${i + 1}`,
                rules: { noItems: true },
                gauntlet: { index: i, total: SANCTUM_GAUNTLET.length },
            });
        });
    }

    _completeSanctum() {
        const firstClear = !this._playerData.sanctumCleared;
        this._playerData.sanctumCleared = true;
        Sound.victory();
        this._chat('{{level:H₀ REJEITADA — O JULGAMENTO FOI VENCIDO!}} Os quatro guardiões se curvam.', 'levelup');

        if (firstClear) {
            CombatSystem.addToInventory(this._playerData, 'ring_of_significance');
            this._playerData.pendingItemAlert = true;
            EventBus.emit('item-alert', { player: this._playerData });
            this.time.delayedCall(700, () => {
                Sound.achievement();
                this._chat(`Você recebeu o {{legend:${ITEMS.ring_of_significance.name}}}! Equipe-o no espaço de relíquia (I).`, 'loot');
            });
        } else {
            const bonus = 300;
            this._playerData.gold += bonus;
            this._chat(`Os guardiões honram sua persistência: {{gold:+${bonus} moedas de ouro}}.`, 'loot');
        }

        AchievementSystem.check(this._playerData);
        EventBus.emit('player-stats-changed', { player: this._playerData });
        SaveSystem.autoSave(this._playerData);
    }

    _interactScroll(scroll) {
        const data = ANCIENT_SCROLLS[scroll.sprite.scrollId];
        if (!data) return;

        Sound.interact();
        this._paused = true;
        this.scene.launch('Dialog', {
            speaker: data.title,
            lines: [data.text],
            role: 'lore',
            onClose: () => { this._paused = false; }
        });
    }

    _interactNPC(npc) {
        // Build dialog lines (cycle through their full lore script)
        const lines = [...(npc.dialog || [])];

        // Reações ao progresso do jogador — cada uma dispara só uma vez,
        // antes das falas normais do NPC
        const seen = this._playerData.seenReactions || (this._playerData.seenReactions = {});
        const reactive = NPC_REACTIONS
            .filter(r => r.npcId === npc.npcId && !seen[r.id] && r.when(this._playerData))
            .slice(0, 2);
        if (reactive.length) {
            reactive.forEach(r => { seen[r.id] = true; });
            lines.unshift(...reactive.map(r => r.line));
        }

        // Action follow-up info (shop/quest/gamble) included as final lore-flavored line
        let action = null;
        if (npc.role === 'shop') {
            lines.push('Examine minhas mercadorias quando estiver pronto, viajante.');
            action = { label: 'ABRIR LOJA', kind: 'shop' };
        } else if (npc.role === 'quest') {
            const offers = QuestSystem.questsForNPC(this._playerData, npc.npcId);
            const completes = offers.filter(o => o.status === 'complete');
            const newOnes   = offers.filter(o => o.status === 'available');
            for (const o of newOnes)   lines.push(`Tarefa proposta: {{accent:${o.quest.name}}}.`);
            for (const o of completes) lines.push(`Você completou: {{good:${o.quest.name}}}! Reivindique sua recompensa.`);
            if (completes.length > 0) action = { label: 'VER MISSÕES', kind: 'quest' };
        }
        // Vex oferece seu jogo de dados quando não há recompensa de missão pendente
        if (npc.npcId === 'gambler' && !action) {
            lines.push('Sente o cheiro da sorte? Meus dados estão sempre na mesa. Sabe calcular suas chances?');
            action = { label: 'JOGAR DADOS', kind: 'gamble' };
        }

        Sound.interact();
        this._paused = true;
        this.scene.launch('Dialog', {
            speaker: this._displayName(npc.npcId),
            npcId: npc.npcId,
            lines,
            role: npc.role || 'quest',
            action,
            onClose: () => this._afterDialog(npc),
            onAction: action ? () => this._performNpcAction(action.kind, npc) : null,
        });
    }

    _interactChest(x, y) {
        const instanceId = `chest_${this._playerData.currentArea}_${x}_${y}`;
        // Chests reset daily: openedChests stores the date it was last opened.
        // Legacy saves stored `true`, which never matches a date — reopens once.
        const today = new Date().toISOString().slice(0, 10);
        if (this._playerData.openedChests[instanceId] === today) {
            this._chat('Este baú já foi aberto hoje. Volte amanhã!', 'system');
            return;
        }

        // 30% de mímico no dungeon, 20% nas profundezas, 10% no resto
        const areaNow = this._playerData.currentArea;
        const mimicChance = areaNow.startsWith('dungeon') ? 0.3
            : areaNow.endsWith('_depths') ? 0.2 : 0.1;
        const isActuallyMimic = Math.random() < mimicChance;

        this._paused = true;
        this.scene.launch('Inference', {
            targetId: instanceId,
            isActuallyMimic,
            onResult: (result) => {
                this._paused = false;
                if (result === 'open') {
                    this._openChest(x, y, instanceId);
                } else if (result === 'mimic_trigger') {
                    this._triggerMimic(x, y, instanceId);
                }
            }
        });
    }

    _openChest(x, y, instanceId) {
        this._playerData.openedChests[instanceId] = new Date().toISOString().slice(0, 10);
        Sound.chest();
        const CHEST_GOLD = {
            village: [15, 20], meadows:   [30, 30], forest:  [55, 40],
            plains:  [80, 50], mountains: [120, 70], dungeon: [180, 100],
        };
        const AREA_ELEMENT = {
            village: 'normal', meadows: 'earth', forest: 'ice',
            plains: 'fire', mountains: 'water', dungeon: 'shadow',
        };
        const area   = this._playerData.currentArea;
        const parent = parentArea(area);
        const isDepths = area.endsWith('_depths');
        // Baús das profundezas pagam 1.8× o da superfície correspondente
        let [base, spread] = CHEST_GOLD[parent] || [15, 20];
        if (isDepths) { base = Math.floor(base * 1.8); spread = Math.floor(spread * 1.8); }
        const gold = base + Math.floor(Math.random() * spread);
        this._playerData.gold += gold;

        const extras = [];
        // 45% de chance de material do elemento da área
        if (Math.random() < 0.45) {
            const matId = `essence_${AREA_ELEMENT[parent] || 'normal'}`;
            if (CombatSystem.addToInventory(this._playerData, matId)) {
                extras.push(`{{loot:${ITEMS[matId]?.name || 'Material'}}}`);
            }
        }
        // 12% de chance de consumível
        if (Math.random() < 0.12) {
            const consumableId = ['plains', 'mountains', 'dungeon'].includes(parent)
                ? 'greater_health_potion' : 'health_potion';
            if (CombatSystem.addToInventory(this._playerData, consumableId)) {
                extras.push(`{{loot:${ITEMS[consumableId]?.name}}}`);
            }
        }

        const extraTxt = extras.length ? ` e ${extras.join(', ')}` : '';
        this._chat(`Você abriu o baú e encontrou {{gold:${gold} moedas de ouro}}${extraTxt}!`, 'loot');
        EventBus.emit('player-stats-changed', { player: this._playerData });
        SaveSystem.autoSave(this._playerData);
    }

    _triggerMimic(x, y, instanceId) {
        this._chat('{{bad:O BAÚ ERA UM MÍMICO!}}', 'combat-hit');
        const MIMIC_TABLE = {
            village:   { name: 'Mímico de Madeira',  maxHp:  70, attackDamage:  14, defense: 1, xpReward:  40, goldReward:  30, questionTopic: 'data_types',       questionDifficulty: ['easy']           },
            meadows:   { name: 'Mímico de Pedra',    maxHp: 100, attackDamage:  24, defense: 2, xpReward:  75, goldReward:  55, questionTopic: 'mean_median_mode', questionDifficulty: ['easy', 'medium'] },
            forest:    { name: 'Mímico de Cristal',  maxHp: 135, attackDamage:  38, defense: 3, xpReward: 120, goldReward:  85, questionTopic: 'spread',           questionDifficulty: ['medium']         },
            plains:    { name: 'Mímico de Chamas',   maxHp: 170, attackDamage:  52, defense: 4, xpReward: 175, goldReward: 120, questionTopic: 'probability',      questionDifficulty: ['medium']         },
            mountains: { name: 'Mímico Abissal',     maxHp: 220, attackDamage:  68, defense: 6, xpReward: 260, goldReward: 180, questionTopic: 'distributions',   questionDifficulty: ['medium', 'hard'] },
            dungeon:   { name: 'Mímico das Trevas',  maxHp: 320, attackDamage: 100, defense: 9, xpReward: 420, goldReward: 300, questionTopic: 'inference',        questionDifficulty: ['hard']           },
        };
        const template = MIMIC_TABLE[parentArea(this._playerData.currentArea)] || MIMIC_TABLE.village;
        const mimicDef = {
            id: 'mimic',
            level: this._playerData.level + 1,
            element: 'shadow',
            color: 0x8822aa,
            ...template,
        };
        this._startCombat({ def: mimicDef, instanceId });
    }

    _performNpcAction(kind, npc) {
        this._paused = true;
        let launched = false;
        if (kind === 'shop') {
            const shop = ShopSystem.shopForNPC(npc.npcId);
            if (shop) { this.scene.launch('Shop', { shopId: shop.id }); launched = true; }
        } else if (kind === 'quest') {
            this.scene.launch('Quest'); launched = true;
        } else if (kind === 'gamble') {
            this.scene.launch('Gamble'); launched = true;
        }
        // Safety: if nothing opened, unpause immediately to prevent permanent freeze
        if (!launched) this._paused = false;
    }

    _afterDialog(npc) {
        this._paused = false; // FIRST — guaranteed even if something below throws
        try {
            if (npc.role === 'quest') {
                const offers = QuestSystem.questsForNPC(this._playerData, npc.npcId);
                for (const o of offers) {
                    if (o.status === 'available') {
                        QuestSystem.accept(this._playerData, o.quest.id);
                        this._chat(`Nova {{quest:missão}} aceita: {{accent:${o.quest.name}}}`, 'levelup');
                        TutorialSystem.trigger(this._playerData, this, 'quest_received');
                    }
                }
            }
        } catch (e) { console.error('[WorldScene] _afterDialog error:', e); }
    }

    _displayName(npcId) {
        return NPC_NAMES[npcId] || npcId;
    }

    _autoSync() {
        if (this._player) {
            Object.assign(this._playerData, this._player.toData());
        }
        this.registry.set('player', this._playerData);
    }

    _periodicSave() {
        if (this._playerData) {
            SaveSystem.autoSave(this._playerData);
            EventBus.emit('autosave');
        }
    }

    _chat(msg, type) { EventBus.emit('chat', { msg, type }); }

    pauseForOverlay() {
        Sound.menuOpen();
        this._paused = true;
    }
    resumeFromOverlay() {
        Sound.menuClose();
        this._paused = false;
        const updated = this.registry.get('player');
        if (updated) {
            Object.assign(this._playerData, updated);
            if (this._player) {
                // Only assign data fields — never Phaser internals (sprite, shadow, scene, etc.)
                const { scene, sprite, shadow, _moveCooldown, _moveDelay, _facing, ...safe } = updated;
                Object.assign(this._player, safe);
            }
        }
    }

    // ── Elemental Aura Visual Effect ──────────────────────────────────────────

    _updateElementalAura() {
        const p = this._playerData;
        if (!p.elementalMastery || !this._player?.sprite) return;

        // Find highest level element (must be at least level 2 to show aura)
        let bestId = null;
        let maxLevel = 1;

        for (const [id, m] of Object.entries(p.elementalMastery)) {
            if (m.level > maxLevel) {
                maxLevel = m.level;
                bestId = id;
            }
        }

        // Cleanup old aura
        if (this._playerAura) {
            this._playerAura.destroy();
            this._playerAura = null;
        }

        if (!bestId) return;

        const data = ELEMENTS[bestId];
        const color = data.color;

        // Create a new container for the aura that will follow the player
        const aura = this.add.container(0, 0).setDepth(this._player.sprite.depth - 1);
        this._playerAura = aura;

        // 1. Static glow
        const glow = this.add.circle(0, 0, 16, color, 0.2);
        aura.add(glow);
        this.tweens.add({ targets: glow, alpha: 0.4, scale: 1.2, duration: 1000, yoyo: true, repeat: -1 });

        // 2. Rotating particles
        for (let i = 0; i < 3; i++) {
            const p = this.add.rectangle(0, 0, 4, 4, color, 0.8);
            aura.add(p);
            const angle = (i / 3) * Math.PI * 2;
            const radius = 18;
            p.x = Math.cos(angle) * radius;
            p.y = Math.sin(angle) * radius;

            this.tweens.add({
                targets: p,
                angle: 360,
                duration: 2000,
                repeat: -1,
                onUpdate: (tween) => {
                    const currentAngle = angle + (tween.progress * Math.PI * 2);
                    p.x = Math.cos(currentAngle) * radius;
                    p.y = Math.sin(currentAngle) * radius;
                }
            });
        }
    }

    _syncAuraPosition() {
        if (this._playerAura && this._player?.sprite) {
            this._playerAura.setPosition(this._player.sprite.x, this._player.sprite.y + 4);
        }
        if (this._gearGlow && this._player?.sprite) {
            this._gearGlow.setPosition(this._player.sprite.x, this._player.sprite.y + 9);
        }
    }

    // Halo de prestígio ao pé do personagem, pela maior raridade equipada
    // (raro/épico/lendário — comum/incomum não mostram nada). Visualmente
    // distinto da aura elemental (que orbita o meio do corpo): este é um
    // brilho de chão, mais parecido com o "glow" de item raro do Tibia.
    _updateGearGlow() {
        this._gearGlow?.destroyGlow();
        this._gearGlow = null;
        if (!this._player?.sprite) return;

        const rarity = CombatSystem.highestEquippedRarity(this._playerData, ITEMS);
        if (!rarity) return;

        const glow = attachRarityGlow(
            this, this._player.sprite.x, this._player.sprite.y + 9, 20, rarity, { alphaMult: 1.6 });
        if (!glow) return; // comum/incomum
        glow.setDepth(this._player.sprite.depth - 2);
        this._gearGlow = glow;
    }

    shutdown() {
        this._rematchOverlay?.destroy();
        this._rematchOverlay = null;
        EventBus.off('combat-end',       this._onCombatEndBound);
        EventBus.off('player-level-up',  this._onLevelUpBound);
        EventBus.off('element-xp-change', this._onElementXpChangeBound);
        EventBus.off('quest-update',     this._onQuestUpdateBound);
        EventBus.off('bounty-complete',  this._onBountyCompleteBound);
        EventBus.off('player-stats-changed', this._onGearChangeBound);
        this._gearGlow?.destroyGlow();
        this._syncTimer?.remove();
        this._regenTimer?.remove();
        this._periodicSaveTimer?.remove();
    }
}
