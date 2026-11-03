import { Music } from '../utils/MusicSystem.js';
import { Sound } from '../utils/SoundSystem.js';

const W = 544;
const H = 480;

export class GameOverScene extends Phaser.Scene {
    constructor() { super('GameOver'); }

    init(data) {
        this._playerData = data.playerData || {};
    }

    create() {
        Music.play('dungeon');

        // ── Background ────────────────────────────────────────────────────────
        this.add.rectangle(W / 2, H / 2, W, H, 0x000000);

        // Falling blood-red particles
        this._spawnParticles();

        // Vignette overlay
        const vig = this.add.graphics();
        vig.fillGradientStyle(0x000000, 0x000000, 0x000000, 0x000000, 0.85, 0.85, 0, 0);
        vig.fillRect(0, 0, W, H);
        vig.setDepth(1);

        // ── Title ─────────────────────────────────────────────────────────────
        const title = this.add.text(W / 2, -60, 'VOCÊ CAIU', {
            fontSize: '48px', color: '#cc0000', fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#000000', strokeThickness: 8,
        }).setOrigin(0.5).setDepth(10);

        this.tweens.add({
            targets: title,
            y: 68,
            duration: 800,
            ease: 'Back.easeOut',
            onComplete: () => this._buildStats(),
        });

        this.add.text(W / 2, 110, '— a Distorção venceu desta vez —', {
            fontSize: '13px', color: '#884444', fontFamily: 'Courier New', fontStyle: 'italic',
        }).setOrigin(0.5).setDepth(10).setAlpha(0);

        // animated subtitle fade-in after title lands
        this.time.delayedCall(900, () => {
            this.tweens.add({
                targets: this.children.getAll().filter(c => c.text === '— a Distorção venceu desta vez —'),
                alpha: 1, duration: 600,
            });
        });
    }

    // ── Stats panel ───────────────────────────────────────────────────────────

    _buildStats() {
        const p = this._playerData;

        // Total questions
        const mastery  = p.mastery || {};
        let totalCorrecto = 0, totalTentado = 0;
        for (const area of Object.values(mastery)) {
            totalCorrecto += area.correct  || 0;
            totalTentado  += area.attempted || 0;
        }
        const pct = totalTentado > 0 ? Math.round((totalCorrecto / totalTentado) * 100) : 0;

        // Monsters defeated
        const monstersDefeated = Object.keys(p.defeatedMonsters || {}).length;

        // Area label
        const AREA_LABELS = {
            village: 'Vila dos Dados', meadows: 'Prados das Medidas',
            forest: 'Floresta da Dispersão', plains: 'Planícies da Probabilidade',
            mountains: 'Montanhas das Distribuições', dungeon: 'Calabouço da Inferência',
            village_house_elder: 'Vila', village_house_scholar: 'Vila', village_house_merchant: 'Vila',
        };
        const areaLabel = AREA_LABELS[p.currentArea] || p.currentArea || 'Vila';

        const rows = [
            ['Nível',              `${p.level}`],
            ['Última área',        areaLabel],
            ['Questões acertadas', `${totalCorrecto} / ${totalTentado}  (${pct}%)`],
            ['Monstros derrotados',`${monstersDefeated}`],
            ['Ouro acumulado',     `${p.gold || 0}`],
        ];

        // Panel background
        const panelY = 138;
        const panelH = rows.length * 30 + 20;
        const panel = this.add.rectangle(W / 2, panelY + panelH / 2, 340, panelH, 0x110000, 0.85)
            .setStrokeStyle(1, 0x661111).setDepth(9).setAlpha(0);

        this.tweens.add({ targets: panel, alpha: 1, duration: 400 });

        rows.forEach(([label, value], i) => {
            const y = panelY + 14 + i * 30;
            const row = [
                this.add.text(W / 2 - 150, y, label, {
                    fontSize: '14px', color: '#aa7777', fontFamily: 'Courier New',
                }).setOrigin(0, 0).setDepth(10).setAlpha(0),
                this.add.text(W / 2 + 150, y, value, {
                    fontSize: '14px', color: '#ffffff', fontFamily: 'Courier New', fontStyle: 'bold',
                }).setOrigin(1, 0).setDepth(10).setAlpha(0),
            ];
            this.time.delayedCall(200 + i * 100, () => {
                this.tweens.add({ targets: row, alpha: 1, duration: 300 });
            });
        });

        // Divider
        const divY = panelY + panelH + 14;
        this.add.rectangle(W / 2, divY, 300, 1, 0x661111, 0.6).setDepth(9);

        // Buttons
        this.time.delayedCall(200 + rows.length * 100 + 200, () => this._buildButtons(divY + 20));
    }

    // ── Buttons ───────────────────────────────────────────────────────────────

    _buildButtons(startY) {
        this._makeBtn(startY,      '↩  Continuar do Save', 0x003311, 0x00ff88, () => this._continue());
        this._makeBtn(startY + 52, '⚑  Menu Principal',    0x110022, 0xaa88ff, () => this._mainMenu());
    }

    _makeBtn(y, label, bgColor, textColor, cb) {
        const bg = this.add.rectangle(W / 2, y, 260, 40, bgColor, 1)
            .setStrokeStyle(1, textColor).setInteractive().setDepth(11).setAlpha(0);
        const txt = this.add.text(W / 2, y, label, {
            fontSize: '16px', color: `#${textColor.toString(16).padStart(6, '0')}`,
            fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5).setDepth(12).setAlpha(0);

        this.tweens.add({ targets: [bg, txt], alpha: 1, duration: 400 });

        bg.on('pointerover',  () => { bg.setFillStyle(textColor, 0.2); Sound.hover(); });
        bg.on('pointerout',   () => bg.setFillStyle(bgColor, 1));
        bg.on('pointerdown',  () => { Sound.click(); cb(); });
    }

    // ── Actions ───────────────────────────────────────────────────────────────

    _continue() {
        // Restore to respawn state (already set in registry by WorldScene)
        const respawn = this._playerData;
        this.registry.set('player', respawn);
        this.scene.start('World');
        this.scene.launch('UI');
    }

    _mainMenu() {
        this.scene.stop('UI');
        this.scene.start('MainMenu');
    }

    // ── Visual: falling ash/ember particles ───────────────────────────────────

    _spawnParticles() {
        const g = this.add.graphics().setDepth(2);
        this._particles = [];

        for (let i = 0; i < 30; i++) {
            this._particles.push({
                x: Math.random() * W,
                y: Math.random() * H,
                vy: 0.3 + Math.random() * 0.6,
                vx: (Math.random() - 0.5) * 0.4,
                size: 1 + Math.random() * 2,
                alpha: 0.3 + Math.random() * 0.5,
                color: Math.random() > 0.5 ? 0xcc2200 : 0x442200,
            });
        }

        this.time.addEvent({
            delay: 40,
            loop: true,
            callback: () => {
                g.clear();
                for (const p of this._particles) {
                    p.y += p.vy;
                    p.x += p.vx;
                    if (p.y > H) { p.y = -4; p.x = Math.random() * W; }
                    g.fillStyle(p.color, p.alpha);
                    g.fillRect(Math.floor(p.x), Math.floor(p.y), p.size, p.size);
                }
            },
        });
    }
}
