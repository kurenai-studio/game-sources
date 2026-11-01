import type { MineKind } from '../state/Mines';
import { LayoutKind, RAT_LANE_Y } from '../state/Layouts';
import { WORLD } from '../state/World';
import { Scene } from 'phaser';

/** Original vector scenery, drawn once so the playfield stays inexpensive. */
export function drawEnvironment(scene: Scene, layout?: LayoutKind, mine: MineKind = 'quarry'): void {
    const palette = mine === 'goldBasin'
        ? { sky: 0x302719, chamber: 0x4c3b21, shaft: 0x211b12, soil: [0x70552f, 0x61482c, 0x503d29, 0x403323], seam: 0xd4a653, wall: 0x423423, edge: 0x977746, light: 0xffc66b }
        : mine === 'gemHollow'
        ? { sky: 0x191d35, chamber: 0x30304d, shaft: 0x11172a, soil: [0x393e58, 0x30364f, 0x282d46, 0x22243b], seam: 0x7d9fb9, wall: 0x23283f, edge: 0x5e718c, light: 0x9eeeff }
        : { sky: 0x252b32, chamber: 0x343b42, shaft: 0x171d24, soil: [0x645344, 0x584b40, 0x4b423c, 0x3e3936], seam: 0x9c8060, wall: 0x282d32, edge: 0x465057, light: 0xffc66b };
    const g = scene.add.graphics();
    const draw = () => {
    g.clear();
    // Enclosed stone chamber, with a darker shaft descending below the miner.
    g.fillStyle(palette.sky).fillRect(0, 0, WORLD.width, WORLD.height);
    g.fillStyle(palette.chamber).fillEllipse(WORLD.centerX, 230, 810, 370);
    g.fillStyle(palette.shaft).fillEllipse(WORLD.centerX, 212, 260, 245);
    g.fillStyle(palette.soil[0]).fillRect(0, WORLD.groundY, WORLD.width, WORLD.height - WORLD.groundY);
    g.fillStyle(palette.soil[1]).fillRect(0, 430, WORLD.width, 220);
    g.fillStyle(palette.soil[2]).fillRect(0, 650, WORLD.width, 150);
    g.fillStyle(palette.soil[3]).fillRect(0, 800, WORLD.width, 160);
    g.lineStyle(2, palette.seam, 0.3);
    for (let row = 0; row < 4; row++) {
        const y = 345 + row * 150;
        for (let x = 50; x < WORLD.width - 34; x += 155) {
            g.beginPath().moveTo(x, y).lineTo(x + 32, y - 9).lineTo(x + 69, y + 7).lineTo(x + 103, y + 2).strokePath();
        }
    }
    for (let i = 0; i < Math.ceil(WORLD.width / 6); i++) {
        const x = 42 + (i * 137) % (WORLD.width - 84);
        const y = 275 + (i * 73) % 630;
        g.fillStyle(i % 3 ? 0x2c2c2c : 0x9e8464, 0.45).fillEllipse(x, y, i % 3 + 3, 3);
    }
    if (layout === 'ratTunnels') {
        g.fillStyle(0x302e2c).fillRoundedRect(46, RAT_LANE_Y - 32, WORLD.width - 92, 64, 25);
        g.lineStyle(2, 0x78634e).lineBetween(65, RAT_LANE_Y + 32, WORLD.width - 65, RAT_LANE_Y + 32);
    } else if (layout === 'goldPocket') {
        g.fillStyle(0xd3a34c, 0.08).fillEllipse(WORLD.centerX, 665, 560, 400);
    } else if (layout === 'deepMine') {
        g.fillStyle(0x171d24, 0.2).fillRect(40, 720, WORLD.width - 80, 190);
    } else if (layout === 'explosiveCavern') {
        g.lineStyle(2, 0xb06d45, 0.4);
        for (let x = 90; x < WORLD.width - 64; x += 170) {
            g.beginPath().moveTo(x, 730).lineTo(x + 25, 765).lineTo(x + 5, 790).lineTo(x + 30, 820).strokePath();
        }
    }
    // Route scenery stays behind the catches; bright decorations hug the walls.
    if (mine === 'goldBasin') {
        for (let row = 0; row < 3; row++) {
            const y = 360 + row * 185;
            g.lineStyle(9, 0x2e281b, 0.5).beginPath().moveTo(38, y)
                .lineTo(WORLD.width * 0.32, y + 42).lineTo(WORLD.width * 0.63, y - 18)
                .lineTo(WORLD.width - 38, y + 30).strokePath();
            g.lineStyle(3, 0xd4a653, 0.24).beginPath().moveTo(38, y)
                .lineTo(WORLD.width * 0.32, y + 42).lineTo(WORLD.width * 0.63, y - 18)
                .lineTo(WORLD.width - 38, y + 30).strokePath();
        }
        for (const side of [0, WORLD.width]) {
            const direction = side === 0 ? 1 : -1;
            g.fillStyle(0x493523).fillRect(side + direction * 42 - 8, 270, 16, 620);
            g.lineStyle(5, 0x8d6739).lineBetween(side + direction * 42, 340, side + direction * 105, 280);
            for (let y = 330; y < 890; y += 85) {
                g.fillStyle(0xc59843, 0.65).fillEllipse(side + direction * 18, y, 22, 10);
            }
        }
    } else if (mine === 'gemHollow') {
        for (const side of [0, WORLD.width]) {
            const direction = side === 0 ? 1 : -1;
            for (let i = 0; i < 5; i++) {
                const y = 320 + i * 122;
                const x = side + direction * 17;
                const color = i % 2 ? 0xaa76d8 : 0x6bbcca;
                g.fillStyle(color, 0.07).fillEllipse(x, y, 150, 150);
                g.fillStyle(color, 0.65).fillTriangle(x, y - 37, x + direction * 27, y + 21, x - direction * 7, y + 29);
                g.fillStyle(0xd9e7ff, 0.35).fillTriangle(x, y - 37, x + direction * 7, y + 23, x + direction * 27, y + 21);
            }
        }
        g.lineStyle(2, 0x99b8dd, 0.18);
        for (let x = 110; x < WORLD.width - 80; x += 210) {
            g.beginPath().moveTo(x, 890).lineTo(x + 25, 841).lineTo(x + 9, 798).strokePath();
        }
    }
    // Rough ceiling, stalactites and side walls frame the usable mining area.
    g.fillStyle(palette.shaft).fillRect(0, 80, WORLD.width, 18);
    for (let i = 0; i < Math.ceil(WORLD.width / 79); i++) {
        const x = i * 79;
        g.fillTriangle(x, 89, x + 70, 89, x + 26, 112 + (i * 13) % 35);
    }
    for (let y = 100; y < 935; y += 80) {
        g.fillStyle(palette.wall).fillTriangle(0, y, 0, y + 100, 29 + (y % 21), y + 45);
        g.fillTriangle(WORLD.width, y - 10, WORLD.width, y + 100, WORLD.width - 31 - (y % 17), y + 55);
        g.lineStyle(2, palette.edge).lineBetween(7, y + 10, 23, y + 37);
    }
    g.save().translateCanvas(WORLD.centerX - 512, 0);
    // A timber-supported tunnel and warm lanterns replace the outdoor horizon.
    g.fillStyle(0x503b2c).fillRect(344, 105, 18, 137).fillRect(662, 105, 18, 137);
    g.fillStyle(0x84603e).fillRect(337, 103, 350, 18);
    g.lineStyle(3, 0xa07a50).lineBetween(346, 108, 677, 108).lineBetween(350, 125, 350, 237).lineBetween(668, 125, 668, 237);
    for (const x of [385, 639]) {
        g.fillStyle(palette.light, 0.06).fillCircle(x, 171, 60);
        g.fillStyle(palette.light, 0.09).fillCircle(x, 171, 38);
        g.lineStyle(2, 0x151b20).lineBetween(x, 120, x, 150);
        g.fillStyle(0x262c30).fillRoundedRect(x - 10, 150, 20, 33, 4);
        g.fillStyle(palette.light).fillRect(x - 6, 156, 12, 20);
        g.fillStyle(0xffe4a0).fillRect(x - 2, 158, 4, 16);
        g.lineStyle(2, 0x262c30).lineBetween(x - 8, 170, x + 8, 170);
    }
    g.restore();
    // Rough ledges leave the centre open for the descending rope.
    g.fillStyle(0x302e2b).fillRect(0, 235, WORLD.centerX - 48, 20).fillRect(WORLD.centerX + 48, 235, WORLD.centerX - 48, 20);
    g.lineStyle(3, 0x8f7960).lineBetween(0, 236, WORLD.centerX - 49, 236).lineBetween(WORLD.centerX + 49, 236, WORLD.width, 236);

    g.save().translateCanvas(WORLD.centerX - 512, 0);
    // Timber platform and braces frame the centered rope pivot.
    g.lineStyle(9, 0x543824).lineBetween(464, 236, 494, 209).lineBetween(560, 236, 530, 209);
    g.fillStyle(0x70472e).fillRoundedRect(458, 204, 108, 14, 3);
    g.fillStyle(0xbb8750).fillRect(460, 204, 104, 4);
    g.fillStyle(0x593c2b).fillRect(468, 218, 10, 20).fillRect(546, 218, 10, 20);
    g.restore();

    };
    g.setData('responsiveRedraw', draw);
    draw();
}
