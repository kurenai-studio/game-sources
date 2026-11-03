import EventBus   from '../utils/EventBus.js';
import { Sound }  from '../utils/SoundSystem.js';
import { SaveSystem } from '../systems/SaveSystem.js';

// Os Dados do Vex — minigame de apostas com dois dados.
// Cada aposta exibe a probabilidade real e o retorno esperado: o jogador
// aprende na prática que valor esperado < 1 significa perda no longo prazo.
const BETS = [
    {
        id: 'high',   label: 'SOMA ≥ 8',  favorable: 15, mult: 2.2,
        desc: 'A soma dos dois dados é 8 ou mais.',
        check: (a, b) => a + b >= 8,
    },
    {
        id: 'seven',  label: 'SOMA = 7',  favorable: 6,  mult: 5.0,
        desc: 'A soma é exatamente 7 — a mais provável das somas.',
        check: (a, b) => a + b === 7,
    },
    {
        id: 'double', label: 'DUPLA',     favorable: 6,  mult: 5.5,
        desc: 'Os dois dados mostram o mesmo valor.',
        check: (a, b) => a === b,
    },
    {
        id: 'low',    label: 'SOMA ≤ 4',  favorable: 6,  mult: 5.8,
        desc: 'A soma é 4 ou menos. A aposta "generosa" do Vex.',
        check: (a, b) => a + b <= 4,
    },
];

const BET_AMOUNTS = [10, 25, 50, 100];
const W = 544, H = 480;

export class GambleScene extends Phaser.Scene {
    constructor() { super('Gamble'); }

    create() {
        this._player  = this.registry.get('player');
        this._betIdx  = 0;
        this._amount  = 25;
        this._rolling = false;
        this._session = { rounds: 0, net: 0, expected: 0 };

        this._buildUI();
        this._selectBet(0);

        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC)
            .on('down', () => this._close());
    }

    _buildUI() {
        this.add.rectangle(0, 0, W, H, 0x000000, 0.92).setOrigin(0, 0);
        this.add.rectangle(10, 10, W - 20, H - 20, 0x0d0a03, 1).setOrigin(0, 0);
        this.add.rectangle(10, 10, W - 20, H - 20, 0xd4af37, 0).setOrigin(0, 0).setStrokeStyle(2, 0xaa1111);

        this.add.text(W / 2, 20, '🎲  OS DADOS DO VEX  🎲', {
            fontSize: '17px', color: '#ff6644', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0);
        this.add.text(W / 2, 40, '"A casa sempre vence... a matemática explica o porquê."', {
            fontSize: '11px', color: '#997766', fontFamily: 'Courier New', fontStyle: 'italic',
        }).setOrigin(0.5, 0);

        // Close button
        const closeBg = this.add.rectangle(504, 14, 22, 22, 0x330000, 1).setOrigin(0, 0).setInteractive()
            .on('pointerover', () => closeBg.setFillStyle(0x660000))
            .on('pointerout',  () => closeBg.setFillStyle(0x330000))
            .on('pointerdown', () => this._close());
        this.add.text(515, 25, 'X', { fontSize: '15px', color: '#ff4444', fontFamily: 'Courier New' }).setOrigin(0.5, 0.5);

        this._goldTx = this.add.text(W - 30, 60, '', {
            fontSize: '14px', color: '#ffcc44', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(1, 0);
        this._refreshGold();

        // ── Bet cards (left column) ──────────────────────────────────────
        this.add.text(20, 62, 'ESCOLHA SUA APOSTA', {
            fontSize: '11px', color: '#d4af37', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0, 0);

        this._betCards = BETS.map((bet, i) => {
            const y  = 82 + i * 72;
            const bg = this.add.rectangle(18, y, 252, 66, 0x110d08, 1).setOrigin(0, 0)
                .setStrokeStyle(1, 0x443322, 1).setInteractive()
                .on('pointerover', () => { if (this._betIdx !== i) { bg.setFillStyle(0x1a140a); Sound.hover(); } })
                .on('pointerout',  () => { if (this._betIdx !== i) bg.setFillStyle(0x110d08); })
                .on('pointerdown', () => { Sound.select(); this._selectBet(i); });

            const pct = (bet.favorable / 36) * 100;
            const ev  = (bet.favorable / 36) * bet.mult;

            const title = this.add.text(26, y + 7, `${bet.label}   paga ${bet.mult.toFixed(1)}×`, {
                fontSize: '13px', color: '#ffcc88', fontFamily: 'Courier New', fontStyle: 'bold',
            }).setOrigin(0, 0);
            this.add.text(26, y + 24, `P = ${bet.favorable}/36 ≈ ${pct.toFixed(1)}%`, {
                fontSize: '11px', color: '#88ccff', fontFamily: 'Courier New',
            }).setOrigin(0, 0);
            this.add.text(26, y + 38, `Retorno esperado: ${(ev * 100).toFixed(0)} a cada 100 apostados`, {
                fontSize: '11px', color: ev >= 0.95 ? '#88dd88' : '#dd8866', fontFamily: 'Courier New',
            }).setOrigin(0, 0);
            this.add.text(26, y + 52, bet.desc, {
                fontSize: '10px', color: '#776655', fontFamily: 'Courier New',
            }).setOrigin(0, 0);

            return { bg, title };
        });

        // ── Right panel: amount, dice, roll ──────────────────────────────
        const RX = 286;
        this.add.text(RX, 62, 'VALOR DA APOSTA', {
            fontSize: '11px', color: '#d4af37', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0, 0);

        this._amountBtns = BET_AMOUNTS.map((amt, i) => {
            const x  = RX + i * 62;
            const bg = this.add.rectangle(x, 82, 56, 26, 0x110d08, 1).setOrigin(0, 0)
                .setStrokeStyle(1, 0x443322, 1).setInteractive()
                .on('pointerover', () => { if (this._amount !== amt) bg.setFillStyle(0x1a140a); })
                .on('pointerout',  () => { if (this._amount !== amt) bg.setFillStyle(0x110d08); })
                .on('pointerdown', () => { Sound.click(); this._setAmount(amt); });
            const tx = this.add.text(x + 28, 95, `${amt}`, {
                fontSize: '13px', color: '#ccaa77', fontFamily: 'Courier New', fontStyle: 'bold',
            }).setOrigin(0.5, 0.5);
            return { bg, tx, amt };
        });
        this._setAmount(this._amount);

        // Dice
        this._die1 = this.add.image(RX + 70,  190, 'dice_1').setScale(3);
        this._die2 = this.add.image(RX + 170, 190, 'dice_1').setScale(3);
        this._sumTx = this.add.text(RX + 120, 244, '', {
            fontSize: '15px', color: '#ffffff', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0);

        // Roll button
        this._rollBg = this.add.rectangle(RX + 20, 280, 200, 36, 0x2a0808, 1).setOrigin(0, 0)
            .setStrokeStyle(2, 0xaa3322, 0.9).setInteractive()
            .on('pointerover', () => this._rollBg.setFillStyle(0x3a1010))
            .on('pointerout',  () => this._rollBg.setFillStyle(0x2a0808))
            .on('pointerdown', () => this._roll());
        this._rollTx = this.add.text(RX + 120, 298, '🎲 LANÇAR DADOS', {
            fontSize: '14px', color: '#ff8855', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0.5);

        // Result + session stats
        this._resultTx = this.add.text(RX + 120, 330, '', {
            fontSize: '13px', fontFamily: 'Courier New', fontStyle: 'bold', align: 'center',
            wordWrap: { width: 230 },
        }).setOrigin(0.5, 0);

        this._statsTx = this.add.text(RX + 120, 388, '', {
            fontSize: '11px', color: '#8899aa', fontFamily: 'Courier New', align: 'center', lineSpacing: 3,
        }).setOrigin(0.5, 0);

        this.add.text(W / 2, 458, 'ESC para fechar', {
            fontSize: '11px', color: '#444444', fontFamily: 'Courier New',
        }).setOrigin(0.5, 0);
    }

    _refreshGold() {
        this._goldTx.setText(`Ouro: ${this._player.gold || 0}`);
    }

    _selectBet(i) {
        this._betIdx = i;
        this._betCards.forEach((card, j) => {
            card.bg.setFillStyle(j === i ? 0x2a1a08 : 0x110d08);
            card.bg.setStrokeStyle(1, j === i ? 0xd4af37 : 0x443322, 1);
        });
    }

    _setAmount(amt) {
        this._amount = amt;
        this._amountBtns.forEach(({ bg, tx, amt: a }) => {
            bg.setFillStyle(a === amt ? 0x2a1a08 : 0x110d08);
            bg.setStrokeStyle(1, a === amt ? 0xd4af37 : 0x443322, 1);
            tx.setColor(a === amt ? '#ffd700' : '#ccaa77');
        });
    }

    _roll() {
        if (this._rolling) return;
        const bet = BETS[this._betIdx];
        if ((this._player.gold || 0) < this._amount) {
            Sound.denied();
            this._resultTx.setColor('#ff5555').setText('Ouro insuficiente!');
            return;
        }

        this._rolling = true;
        this._player.gold -= this._amount;
        this._refreshGold();
        this._resultTx.setText('');

        // Rolling animation: dice cycle random faces, then settle
        const a = Phaser.Math.Between(1, 6);
        const b = Phaser.Math.Between(1, 6);
        let ticks = 0;
        this.time.addEvent({
            delay: 70, repeat: 11,
            callback: () => {
                ticks++;
                if (ticks <= 11) {
                    this._die1.setTexture(`dice_${Phaser.Math.Between(1, 6)}`);
                    this._die2.setTexture(`dice_${Phaser.Math.Between(1, 6)}`);
                    Sound.dialogTick();
                }
                if (ticks === 12) this._settle(a, b, bet);
            },
        });
    }

    _settle(a, b, bet) {
        this._die1.setTexture(`dice_${a}`);
        this._die2.setTexture(`dice_${b}`);
        this._sumTx.setText(`${a} + ${b} = ${a + b}`);

        const won    = bet.check(a, b);
        const payout = won ? Math.floor(this._amount * bet.mult) : 0;
        if (won) this._player.gold = (this._player.gold || 0) + payout;

        // Session tracking: empirical vs expected
        const ev = (bet.favorable / 36) * bet.mult;
        this._session.rounds++;
        this._session.net      += payout - this._amount;
        this._session.expected += this._amount * (ev - 1);

        if (won) {
            Sound.coins();
            this._resultTx.setColor('#66ff88')
                .setText(`VOCÊ VENCEU!\n+${payout} ouro (${bet.mult.toFixed(1)}× de ${this._amount})`);
            this.tweens.add({ targets: [this._die1, this._die2], scale: 3.5, duration: 120, yoyo: true });
        } else {
            Sound.wrong();
            this._resultTx.setColor('#ff7755')
                .setText(`Perdeu ${this._amount} ouro.\n${bet.label} não saiu.`);
        }

        const s = this._session;
        const fmt = n => (n >= 0 ? `+${Math.round(n)}` : `${Math.round(n)}`);
        this._statsTx.setText(
            `Sessão: ${s.rounds} rodada${s.rounds > 1 ? 's' : ''}\n` +
            `Saldo real: ${fmt(s.net)} ouro\n` +
            `Saldo esperado (teoria): ${fmt(s.expected)} ouro`
        );

        this._refreshGold();
        this.registry.set('player', this._player);
        EventBus.emit('player-stats-changed', { player: this._player });
        SaveSystem.autoSave(this._player);
        this._rolling = false;
    }

    _close() {
        if (this._session.rounds > 0) {
            const s = this._session;
            EventBus.emit('chat', {
                msg: `Vex sorri: {{accent:${s.rounds} rodadas}}, saldo {{gold:${s.net >= 0 ? '+' : ''}${s.net} ouro}}. A teoria previa ${Math.round(s.expected)}.`,
                type: 'system',
            });
        }
        this.scene.stop('Gamble');
        const world = this.scene.get('World');
        if (world?.resumeFromOverlay) world.resumeFromOverlay();
    }
}
