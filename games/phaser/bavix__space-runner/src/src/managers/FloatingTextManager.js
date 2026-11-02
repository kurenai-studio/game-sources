// Floating Text Manager - Optimized floating text system
import { colorToHex } from '../utils/colorHelpers.js';

export class FloatingTextManager {
  constructor(scene) {
    this.scene = scene;
    this.floatingTexts = scene.add.group();
    this.textPool = [];
    this.maxPoolSize = 20;
  }

  createFloatingText(x, y, text, color, size = 8, fontScale = 1) {
    const scaledSize = Math.max(8, Math.floor(size * fontScale));
    const floatingText = this.getTextFromPool() || this.createNewText(scaledSize, fontScale);
    
    floatingText.x = x;
    floatingText.y = y;
    floatingText.setText(text);
    floatingText.setColor(colorToHex(color));
    floatingText.setFontSize(`${scaledSize}px`);
    floatingText.life = 60;
    floatingText.maxLife = 60;
    floatingText.vy = -1;
    floatingText.active = true;
    floatingText.setVisible(true);
    
    if (!this.floatingTexts.contains(floatingText)) {
      this.floatingTexts.add(floatingText);
    }
    return floatingText;
  }

  getTextFromPool() {
    if (this.textPool.length > 0) {
      return this.textPool.pop();
    }
    return null;
  }

  createNewText(size, fontScale) {
    const text = this.scene.add.text(0, 0, '', {
      fontSize: `${size}px`,
      fontFamily: 'Consolas, "Courier New", monospace',
      color: '#ffffff',
      stroke: '#000000',
      strokeThickness: Math.max(1, Math.round(2 * fontScale))
    });
    text.setOrigin(0.5);
    return text;
  }

  update() {
    const textsToRemove = [];
    const children = this.floatingTexts.getChildren();
    const childrenLength = children.length;

    for (let i = 0; i < childrenLength; i++) {
      const text = children[i];
      if (!text.active) continue;

      text.y += text.vy;
      text.life--;

      // Fade out
      const alpha = text.life / text.maxLife;
      text.setAlpha(Math.max(0, alpha));

      if (text.life <= 0 || text.alpha <= 0) {
        textsToRemove.push(text);
      }
    }

    // Clean up removed texts
    for (const text of textsToRemove) {
      this.removeText(text);
    }
  }

  removeText(text) {
    text.active = false;
    text.setVisible(false);
    this.floatingTexts.remove(text, true, false);
    this.returnTextToPool(text);
  }

  returnTextToPool(text) {
    if (this.textPool.length < this.maxPoolSize) {
      text.active = false;
      this.textPool.push(text);
    } else {
      text.destroy();
    }
  }

  clear() {
    const children = this.floatingTexts.getChildren();
    for (const text of children) {
      this.removeText(text);
    }
    this.floatingTexts.clear(true, true);
  }
}

