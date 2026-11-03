import { SkillSystem } from '../systems/SkillSystem.js';
import { SKILLS, SKILL_SLOTS_PER_TIER } from '../data/skills.js';
import EventBus from '../utils/EventBus.js';

/**
 * SkillScene — choose new skills when unlocked.
 * Shown automatically when level-up gives access to new skills, or via 'K' key.
 */
export class SkillScene extends Phaser.Scene {
    constructor() { super('Skill'); }

    create() {
        this._player = this.registry.get('player');
        SkillSystem.init(this._player);
        this._buildUI();

        const close = () => this._close();
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC).on('down', close);
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.K).on('down', close);
    }

    _buildUI() {
        const W = 544, H = 480;
        this.add.rectangle(0, 0, W, H, 0x000000, 0.92).setOrigin(0, 0);
        this.add.rectangle(10, 10, W - 20, H - 20, 0x0d0a03, 1).setOrigin(0, 0);
        this.add.rectangle(10, 10, W - 20, H - 20, 0xd4af37, 0).setOrigin(0, 0).setStrokeStyle(2, 0xd4af37);

        this.add.text(W / 2, 22, 'H A B I L I D A D E S', {
            fontSize: '17px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0);

        this.add.rectangle(504, 14, 22, 22, 0x330000, 1).setOrigin(0, 0).setInteractive()
            .on('pointerdown', () => this._close());
        this.add.text(515, 25, 'X', { fontSize: '15px', color: '#ff4444', fontFamily: 'Courier New' }).setOrigin(0.5, 0.5);

        // Owned section
        let y = 50;
        this.add.text(20, y, 'APRENDIDAS', { fontSize: '17px', color: '#88ff88', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0, 0);
        y += 18;
        const owned = this._player.skills || [];
        if (owned.length === 0) {
            this.add.text(20, y, '(nenhuma ainda)', { fontSize: '16px', color: '#666666', fontFamily: 'Courier New' });
            y += 16;
        } else {
            owned.forEach(id => {
                const s = SKILLS[id]; if (!s) return;
                this.add.rectangle(20, y, 504, 18, 0x0e1a0e, 1).setOrigin(0, 0).setStrokeStyle(1, 0x336633);
                this.add.text(26, y + 9, `[T${s.tier}] ${s.name}`, { fontSize: '16px', color: '#88ff88', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0, 0.5);
                this.add.text(150, y + 9, s.description, { fontSize: '15px', color: '#aaaaaa', fontFamily: 'Courier New' }).setOrigin(0, 0.5);
                y += 22;
            });
        }

        // Pending choices
        y += 8;
        const pending = SkillSystem.pendingChoices(this._player);
        if (pending.length === 0) {
            this.add.text(W / 2, y, 'Nenhuma habilidade nova disponível.\nSuba de nível para desbloquear mais.', {
                fontSize: '17px', color: '#666666', fontFamily: 'Courier New', align: 'center',
            }).setOrigin(0.5, 0);
            return;
        }

        this.add.text(20, y, 'ESCOLHA UMA HABILIDADE', { fontSize: '17px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold' });
        y += 22;

        for (const tier of pending) {
            this.add.text(20, y, `Tier ${tier.tier}  (escolha 1):`, { fontSize: '16px', color: '#aaaaff', fontFamily: 'Courier New' });
            y += 16;
            for (const s of tier.options) {
                const card = this.add.rectangle(20, y, 504, 38, 0x1a1a3a, 1).setOrigin(0, 0).setStrokeStyle(1, 0x4488ff)
                    .setInteractive()
                    .on('pointerover', () => card.setFillStyle(0x2a2a55))
                    .on('pointerout',  () => card.setFillStyle(0x1a1a3a))
                    .on('pointerdown', () => this._pick(s.id));
                this.add.text(28, y + 8, `${s.name}`, { fontSize: '17px', color: '#88ccff', fontFamily: 'Courier New', fontStyle: 'bold' });
                this.add.text(28, y + 23, s.description, { fontSize: '15px', color: '#aaaaaa', fontFamily: 'Courier New', wordWrap: { width: 470 } });
                y += 44;
                if (y > 430) break;
            }
            if (y > 430) break;
        }
    }

    _pick(skillId) {
        if (SkillSystem.chooseSkill(this._player, skillId)) {
            this.registry.set('player', this._player);
            this.scene.restart();
        }
    }

    _close() {
        this.registry.set('player', this._player);
        this.scene.stop('Skill');
        const world = this.scene.get('World');
        if (world?.resumeFromOverlay) world.resumeFromOverlay();
    }
}
