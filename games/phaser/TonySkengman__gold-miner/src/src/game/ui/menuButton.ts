import type { Scene } from 'phaser';

export function menuButton(scene: Scene, x: number, y: number, label: string, action: () => void): void {
    const button = scene.add.text(x, y, label, {
        fontFamily: 'Arial', fontSize: 25, fontStyle: 'bold', color: '#fff3cc',
        backgroundColor: '#547f3b', padding: { x: 26, y: 15 }
    }).setOrigin(0.5).setInteractive({ useHandCursor: true });
    button.on('pointerover', () => button.setBackgroundColor('#659b47'));
    button.on('pointerout', () => button.setBackgroundColor('#547f3b'));
    button.on('pointerdown', action);
}
