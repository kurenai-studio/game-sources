import { InferenceSystem } from '../systems/InferenceSystem.js';
import { COLORS } from '../constants.js';

export class InferenceScene extends Phaser.Scene {
    constructor() { super('Inference'); }

    init(data) {
        this._targetId = data.targetId;
        this._isActuallyMimic = data.isActuallyMimic;
        this._onResult = data.onResult;
        this._investigated = false;
        this._investigationData = null;
    }

    create() {
        const W = 544, H = 480;
        this.add.rectangle(0, 0, W, H, 0x000000, 0.8).setOrigin(0);

        const panelW = 400, panelH = 300;
        const px = (W - panelW) / 2;
        const py = (H - panelH) / 2;

        this.add.rectangle(px, py, panelW, panelH, 0x110f1c, 1).setOrigin(0).setStrokeStyle(2, 0x3b3458);
        
        this.add.text(W / 2, py + 20, 'INVESTIGAÇÃO DE OBJETO', {
            fontSize: '18px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold'
        }).setOrigin(0.5);

        this.add.text(W / 2, py + 50, 'Um baú suspeito... o que deseja fazer?', {
            fontSize: '12px', color: '#e8dfd1', fontFamily: 'Courier New'
        }).setOrigin(0.5);

        // Action Buttons
        this._btnOpen = this._createButton(W / 2, py + 100, 'ABRIR DIRETAMENTE', 0x1a3a1a, () => this._handleOpen());
        this._btnInvestigate = this._createButton(W / 2, py + 150, 'INVESTIGAR (Teste de Hipótese)', 0x1a1a44, () => this._handleInvestigate());
        this._btnLeave = this._createButton(W / 2, py + 200, 'SAIR', 0x2a1000, () => this._handleLeave());

        // Result Container (hidden initially)
        this._resultContainer = this.add.container(0, 0).setVisible(false);
        this._buildResultUI(px, py, panelW);
    }

    _createButton(x, y, label, color, callback) {
        const bg = this.add.rectangle(x, y, 320, 32, color, 1)
            .setInteractive({ useHandCursor: true })
            .on('pointerover', () => bg.setAlpha(0.8))
            .on('pointerout', () => bg.setAlpha(1))
            .on('pointerdown', callback);
        
        const txt = this.add.text(x, y, label, {
            fontSize: '12px', color: '#ffffff', fontFamily: 'Courier New', fontStyle: 'bold'
        }).setOrigin(0.5);

        return { bg, txt };
    }

    _buildResultUI(px, py, panelW) {
        const yStart = py + 80;
        this._resTitle = this.add.text(px + 20, yStart, 'RESULTADOS DA INFERÊNCIA:', {
            fontSize: '11px', color: '#88ccff', fontFamily: 'Courier New', fontStyle: 'bold'
        });
        
        this._resH0 = this.add.text(px + 20, yStart + 25, '', { fontSize: '10px', color: '#aaaaaa', fontFamily: 'Courier New' });
        this._resH1 = this.add.text(px + 20, yStart + 40, '', { fontSize: '10px', color: '#aaaaaa', fontFamily: 'Courier New' });
        
        this._resMetric = this.add.text(px + 20, yStart + 65, '', { fontSize: '12px', color: '#ffffff', fontFamily: 'Courier New', fontStyle: 'bold' });
        this._resPValue = this.add.text(px + 20, yStart + 90, '', { fontSize: '14px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold' });
        
        this._resDecision = this.add.text(px + 20, yStart + 120, '', { 
            fontSize: '11px', color: '#ff5555', fontFamily: 'Courier New', fontStyle: 'italic', wordWrap: { width: panelW - 40 }
        });

        this._resultContainer.add([this._resTitle, this._resH0, this._resH1, this._resMetric, this._resPValue, this._resDecision]);
    }

    _handleOpen() {
        if (this._isActuallyMimic) {
            this.scene.stop();
            this._onResult('mimic_trigger');
        } else {
            this.scene.stop();
            this._onResult('open');
        }
    }

    _handleInvestigate() {
        if (this._investigated) return;
        this._investigated = true;

        this._investigationData = InferenceSystem.generateInvestigation(this._isActuallyMimic);
        const d = this._investigationData;

        // Hide main buttons
        this._btnOpen.bg.setVisible(false);
        this._btnOpen.txt.setVisible(false);
        this._btnInvestigate.bg.setVisible(false);
        this._btnInvestigate.txt.setVisible(false);
        this._btnLeave.bg.setY(this._btnLeave.bg.y + 60);
        this._btnLeave.txt.setY(this._btnLeave.txt.y + 60);

        // Show results
        this._resH0.setText(`H0 (Hipótese Nula): ${d.h0}`);
        this._resH1.setText(`H1 (Hipótese Alternativa): ${d.h1}`);
        this._resMetric.setText(`EVIDÊNCIA: ${d.evidence}${d.unit} (${d.metric})`);
        this._resPValue.setText(`Valor-p calculado: ${d.pValue}`);

        if (d.pValue < d.threshold) {
            this._resPValue.setColor('#ff5555');
            this._resDecision.setText(`DECISÃO: Como o valor-p (${d.pValue}) é menor que o limite (${d.threshold}), {{bad:REJEITAMOS H0}}. Há evidências estatísticas significativas de que o objeto é um {{bad:MÍMICO}}!`);
        } else {
            this._resPValue.setColor('#55ff88');
            this._resDecision.setText(`DECISÃO: Como o valor-p (${d.pValue}) é maior ou igual ao limite (${d.threshold}), {{good:FALHAMOS EM REJEITAR H0}}. Não há evidência suficiente para afirmar que o objeto é perigoso.`);
        }

        this._resultContainer.setVisible(true);

        // Update Leave button to "CONCLUIR"
        this._btnLeave.txt.setText('CONCLUIR INVESTIGAÇÃO');
    }

    _handleLeave() {
        this.scene.stop();
        this._onResult('leave');
    }
}
