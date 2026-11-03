import { SaveSystem } from '../systems/SaveSystem.js';
import { PLAYER_DEFAULTS, VERSION } from '../constants.js';
import { Music } from '../utils/MusicSystem.js';

export class MainMenuScene extends Phaser.Scene {
    constructor() { super('MainMenu'); }

    create() {
        const W = this.scale.width;
        const H = this.scale.height;

        // Background gradient + stars
        this.add.rectangle(W / 2, H / 2, W, H, 0x05030a).setDepth(0);
        for (let i = 0; i < 70; i++) {
            const x = Math.random() * W;
            const y = Math.random() * H;
            const s = Math.random() * 1.5 + 0.4;
            const star = this.add.rectangle(x, y, s, s, 0xffffff, Math.random() * 0.7 + 0.2).setDepth(1);
            this.tweens.add({ targets: star, alpha: 0.1, duration: 1500 + Math.random() * 1500, yoyo: true, repeat: -1 });
        }

        // ── LAYOUT: title (60..120) | preview (130..210) | buttons (230..420) | footer ──
        const TITLE_Y       = 50;
        const PREVIEW_Y     = 165;
        const FIRST_BTN_Y   = 250;
        const BTN_GAP       = 38;

        // Title
        this.add.text(W / 2, TITLE_Y, 'MeanFall', {
            fontSize: '38px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#000000', strokeThickness: 5,
        }).setOrigin(0.5).setDepth(2);

        // Beta badge next to title
        const betaBadge = this.add.rectangle(W / 2 + 100, TITLE_Y - 8, 50, 20, 0xcc1144, 1).setDepth(3);
        betaBadge.setStrokeStyle(1, 0xff4477);
        this.add.text(W / 2 + 100, TITLE_Y - 8, 'BETA', {
            fontSize: '17px', color: '#ffffff', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5).setDepth(4);

        this.add.text(W / 2, TITLE_Y + 30, 'Aprenda Estatística através da aventura', {
            fontSize: '15px', color: '#d4af37', fontFamily: 'Courier New', fontStyle: 'italic',
        }).setOrigin(0.5).setDepth(2);

        // Divider under subtitle
        this.add.rectangle(W / 2, TITLE_Y + 55, 320, 2, 0xd4af37, 0.5).setDepth(2);

        // Player preview — placed BETWEEN title and buttons, with platform shadow
        const platformY = PREVIEW_Y + 36;
        this.add.ellipse(W / 2, platformY + 4, 60, 10, 0x000000, 0.5).setDepth(2);
        const px = this.add.image(W / 2, PREVIEW_Y, 'sprite_player').setOrigin(0.5, 0.5).setDepth(2).setScale(1.6);
        // Soft glow halo behind the sprite
        this.add.circle(W / 2, PREVIEW_Y, 36, 0xffd700, 0.08).setDepth(1);
        this.add.circle(W / 2, PREVIEW_Y, 24, 0xffd700, 0.12).setDepth(1);
        this.tweens.add({
            targets: px, y: PREVIEW_Y - 4, duration: 1100, yoyo: true, repeat: -1, ease: 'Sine.easeInOut',
        });

        // Buttons (compact, vertically below preview)
        let by = FIRST_BTN_Y;
        this._makeButton(W / 2, by, 'Novo Jogo', () => this._newGame()); by += BTN_GAP;

        const saves = SaveSystem.loadAll();
        if (saves.some(s => s !== null)) {
            this._makeButton(W / 2, by, 'Continuar', () => this._loadGame(saves)); by += BTN_GAP;
        }

        this._makeButton(W / 2, by, 'Como Jogar',    () => this._showHelp());    by += BTN_GAP;
        this._makeButton(W / 2, by, 'Resetar Saves', () => this._resetSaves());

        // Version + credits at the very bottom
        this.add.text(8, H - 6, `v${VERSION.number} ${VERSION.label}`, {
            fontSize: '16px', color: '#666', fontFamily: 'Courier New',
        }).setOrigin(0, 1).setDepth(2);

        this.add.text(W - 8, H - 6, `Developed by ${VERSION.author}`, {
            fontSize: '16px', color: '#888', fontFamily: 'Courier New', fontStyle: 'italic',
        }).setOrigin(1, 1).setDepth(2);

        // Donate Button (floating bottom right above author)
        const donateBtn = this.add.text(W - 8, H - 24, '[ APOIAR PROJETO ]', {
            fontSize: '17px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
            backgroundColor: '#1a1505', padding: { x: 8, y: 4 }
        }).setOrigin(1, 1).setDepth(3).setInteractive({ useHandCursor: true });

        donateBtn.on('pointerover', () => donateBtn.setStyle({ color: '#ffffff', backgroundColor: '#332a0a' }));
        donateBtn.on('pointerout',  () => donateBtn.setStyle({ color: '#ffd700', backgroundColor: '#1a1505' }));
        donateBtn.on('pointerdown', () => this._showDonate());

        this._helpVisible = false;
        this._donateVisible = false;

        Music.play('menu');
    }

    _makeButton(x, y, label, callback) {
        const btn = this.add.text(x, y, `[ ${label} ]`, {
            fontSize: '15px', color: '#d4af37', fontFamily: 'Courier New', fontStyle: 'bold',
            backgroundColor: '#0d0a03',
            padding: { x: 14, y: 6 },
        }).setOrigin(0.5).setDepth(3).setInteractive({ useHandCursor: true });

        btn.on('pointerover',  () => btn.setStyle({ color: '#ffffff', backgroundColor: '#2a2005' }));
        btn.on('pointerout',   () => btn.setStyle({ color: '#d4af37', backgroundColor: '#0d0a03' }));
        btn.on('pointerdown',  () => callback());
        return btn;
    }

    _newGame() { this.scene.start('Intro'); }

    _resetSaves() {
        if (window.confirm('Apagar TODOS os saves? Necessário para jogar a nova versão Beta com criação de personagem.')) {
            try {
                Object.keys(localStorage).filter(k => k.toLowerCase().includes('save') || k.toLowerCase().includes('quest') || k.toLowerCase().includes('meanfall')).forEach(k => localStorage.removeItem(k));
            } catch (e) { /* ignore */ }
            window.alert('Saves apagados. A página será recarregada.');
            window.location.reload();
        }
    }

    _loadGame(saves) {
        const valid = saves.filter(s => s !== null);
        const latest = valid.sort((a, b) => new Date(b.saveTimestamp) - new Date(a.saveTimestamp))[0];
        this.registry.set('player', latest);
        this.scene.start('World');
        this.scene.launch('UI');
    }

    _showHelp() {
        if (this._helpVisible) return;
        this._helpVisible = true;
        const W = this.scale.width;
        const H = this.scale.height;

        const overlay = this.add.rectangle(W / 2, H / 2, W - 50, H - 60, 0x0d0a18, 0.97)
            .setStrokeStyle(2, 0xd4af37).setDepth(10).setInteractive();

        const lines = [
            'COMO JOGAR',
            '',
            'WASD ou Setas  →  Mover personagem',
            'Espaço         →  Falar com NPCs / abrir loja',
            'I              →  Inventário',
            'C              →  Personagem',
            'Q              →  Missões',
            'B              →  Biblioteca de tomos',
            'K              →  Habilidades',
            'F5             →  Salvar jogo',
            '',
            'COMBATE:',
            'Encoste em um monstro para iniciar combate.',
            'Responda perguntas de estatística para atacar.',
            'Acerto correto = você causa dano.',
            'Erro = o monstro te ataca.',
            'Foco -10 = obtém uma dica.',
            '',
            'PROGRESSÃO:',
            'Suba de nível, escolha skills (K) e itens.',
            'Maestria + nível desbloqueia novos portais.',
            '',
            '[Clique para fechar]',
        ];

        this.add.text(W / 2, H / 2, lines.join('\n'), {
            fontSize: '17px', color: '#d4af37', fontFamily: 'Courier New',
            align: 'left', lineSpacing: 4,
        }).setOrigin(0.5).setDepth(11);

        overlay.on('pointerdown', () => {
            overlay.destroy();
            this._helpVisible = false;
            this.children.list
                .filter(c => c.depth === 11)
                .forEach(c => c.destroy());
        });
    }

    _showDonate() {
        if (this._donateVisible) return;
        this._donateVisible = true;
        const W = this.scale.width;
        const H = this.scale.height;

        const overlay = this.add.rectangle(W / 2, H / 2, 380, 220, 0x110d05, 0.98)
            .setStrokeStyle(2, 0xffd700).setDepth(20).setInteractive();

        const title = this.add.text(W / 2, H / 2 - 70, 'APOIAR O DESENVOLVIMENTO', {
            fontSize: '16px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold'
        }).setOrigin(0.5).setDepth(21);

        const msg = this.add.text(W / 2, H / 2 - 30, 'Se você está gostando do MeanFall e deseja\najudar a manter o projeto vivo e gratuito,\nconsidere fazer uma doação de qualquer valor.', {
            fontSize: '17px', color: '#e8dfd1', fontFamily: 'Courier New', align: 'center', lineSpacing: 4
        }).setOrigin(0.5).setDepth(21);

        const pixLabel = this.add.text(W / 2, H / 2 + 30, 'CHAVE PIX (E-mail):', {
            fontSize: '16px', color: '#888', fontFamily: 'Courier New'
        }).setOrigin(0.5).setDepth(21);

        const pixValue = this.add.text(W / 2, H / 2 + 50, 'solarcubix@gmail.com', {
            fontSize: '15px', color: '#ffffff', fontFamily: 'Courier New', fontStyle: 'bold',
            backgroundColor: '#2a2005', padding: { x: 10, y: 5 }
        }).setOrigin(0.5).setDepth(21);

        const closeHint = this.add.text(W / 2, H / 2 + 90, '[ Clique para fechar ]', {
            fontSize: '16px', color: '#666', fontFamily: 'Courier New'
        }).setOrigin(0.5).setDepth(21);

        overlay.on('pointerdown', () => {
            overlay.destroy();
            title.destroy();
            msg.destroy();
            pixLabel.destroy();
            pixValue.destroy();
            closeHint.destroy();
            this._donateVisible = false;
        });
    }
}
