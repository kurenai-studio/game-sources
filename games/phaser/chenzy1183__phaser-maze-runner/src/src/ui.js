// 简单的 UI 组件：圆角按钮（Graphics 绘制 + Zone 接收点击）
const UI = {
  button(scene, x, y, w, h, label, onClick, opts = {}) {
    const primary = !!opts.primary;
    const depth = opts.depth || 0;
    const fontSize = opts.fontSize || (primary ? 26 : 20);

    const gfx = scene.add.graphics().setDepth(depth);
    const text = scene.add
      .text(x, y, label, { fontFamily: FONT, fontSize: fontSize + 'px', fontStyle: 'bold', color: '#f8fafc' })
      .setOrigin(0.5)
      .setDepth(depth + 1);
    const zone = scene.add.zone(x, y, w, h).setInteractive({ useHandCursor: true }).setDepth(depth + 2);

    const state = { hover: false, selected: false };

    const draw = () => {
      gfx.clear();
      let fill;
      let stroke;
      if (primary) {
        fill = state.hover ? 0x0ea5e9 : 0x0284c7;
        stroke = 0x7dd3fc;
      } else if (state.selected) {
        fill = 0x0c4a6e;
        stroke = 0x38bdf8;
      } else {
        fill = state.hover ? 0x334155 : 0x1e293b;
        stroke = state.hover ? 0x64748b : 0x334155;
      }
      const r = Math.min(12, h / 2);
      gfx.fillStyle(fill, 1);
      gfx.fillRoundedRect(x - w / 2, y - h / 2, w, h, r);
      gfx.lineStyle(2, stroke, 1);
      gfx.strokeRoundedRect(x - w / 2, y - h / 2, w, h, r);
    };

    zone.on('pointerover', () => {
      state.hover = true;
      draw();
    });
    zone.on('pointerout', () => {
      state.hover = false;
      draw();
    });
    zone.on('pointerdown', () => {
      Sfx.unlock();
      Sfx.click();
      onClick();
    });

    draw();

    return {
      gfx,
      text,
      zone,
      setSelected(v) {
        state.selected = v;
        draw();
      },
      setLabel(t) {
        text.setText(t);
      },
      destroy() {
        gfx.destroy();
        text.destroy();
        zone.destroy();
      },
    };
  },
};
