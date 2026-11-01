import { drawShopProduct } from '../art/drawShop';
import type { MysteryReward } from '../state/MysteryRewards';
import { DepositIntegrity } from '../state/DepositIntegrity';
import { DepositRewardKind, rollDepositRewards } from '../state/DepositRewards';
import { TNT_BLAST_RADIUS } from './Explosions';
import { findClearAim, findExposedGemAim } from './Aiming';
import { RAT_LANE_Y } from '../state/Layouts';
import { WORLD } from '../state/World';
import { rollTreasureReward, treasureRewardLabel, TreasureReward } from '../state/TreasureRewards';
import { GameObjects, Scene } from 'phaser';
import { LEVELS, LevelConfig } from '../state/Levels';

export type OreKind = 'small' | 'medium' | 'large' | 'giant' | 'rock' | 'mediumRock' | 'heavyRock' | 'largeRock' | 'diamond' | 'ruby' | 'moneyBag' | 'rat' | 'diamondRat' | 'rubyRat' | 'tnt' | 'strengthPotion' | 'goldRush' | 'timeVial' | 'streakVial' | 'mysteryBag' | 'treasureChest';
const TYPES = {
    ruby: { radius: 15, value: 650, weight: 2, color: 0xe83864 },
    treasureChest: { radius: 36, value: 0, weight: 5.5, color: 0xb77736 },
    goldRush: { radius: 30, value: 0, weight: 0.2, color: 0xffc52e },
    streakVial: { radius: 30, value: 0, weight: 0.2, color: 0xa75ae0 },
    timeVial: { radius: 30, value: 0, weight: 0.2, color: 0x66d9fa },
    mysteryBag: { radius: 30, value: 0, weight: 3, color: 0x837097 },
    strengthPotion: { radius: 30, value: 0, weight: 0.2, color: 0x80d65b },
    tnt: { radius: 40, value: 0, weight: 1, color: 0xbb3c2d },
    rat: { radius: 21, value: 1, weight: 0.1, color: 0x88766a },
    diamondRat: { radius: 24, value: 451, weight: 0.2, color: 0x88766a },
    rubyRat: { radius: 24, value: 651, weight: 0.2, color: 0x88766a },
    diamond: { radius: 17, value: 450, weight: 0.4, color: 0x70e6f5 },
    moneyBag: { radius: 30, value: 0, weight: 1.2, color: 0xc49450 },
    small: { radius: 15, value: 50, weight: 0.6, color: 0xffdf49 },
    medium: { radius: 32, value: 100, weight: 1.5, color: 0xffca28 },
    large: { radius: 48, value: 200, weight: 3, color: 0xf5b51b },
    giant: { radius: 72, value: 350, weight: 4.8, color: 0xf0b21d },
    mediumRock: { radius: 40, value: 16, weight: 4.4, color: 0x838e97 },
    heavyRock: { radius: 51, value: 18, weight: 4.95, color: 0x808c95 },
    largeRock: { radius: 62, value: 20, weight: 5.5, color: 0x7e8993 },
    rock: { radius: 30, value: 12, weight: 3.8, color: 0x89939b }
};

export class Collectable {
    readonly radius: number;
    readonly value: number;
    private readonly baseWeight: number;
    mountedGem?: Collectable;
    private supportingRock?: Collectable;
    private gemOffset = { x: 0, y: 0 };
    get isMountedGem(): boolean { return this.supportingRock !== undefined; }
    get weight(): number { return this.haulingWeight(false); }
    haulingWeight(lightweightGrip: boolean): number {
        const rock = ['rock', 'mediumRock', 'heavyRock', 'largeRock'].includes(this.kind);
        return this.baseWeight * (lightweightGrip && rock ? 0.6 : 1) + (this.mountedGem?.weight ?? 0);
    }
    readonly graphic: GameObjects.Graphics;
    available = true;
    private chestOpened = false;
    readonly treasureReward?: TreasureReward;
    depositIntegrity?: DepositIntegrity;
    private combinedGemRock = false;
    private blastedGem?: 'diamond' | 'ruby';
    get gemDeposit(): boolean { return this.depositIntegrity !== undefined; }
    private depositCracks?: GameObjects.Graphics;
    get depositRewards(): readonly DepositRewardKind[] {
        const gem = this.combinedGemRock ? this.blastedGem ?? this.mountedGem?.kind : undefined;
        return [...(gem === 'diamond' || gem === 'ruby' ? [gem] as DepositRewardKind[] : []),
            ...(this.depositIntegrity?.rewards ?? [])];
    }
    private treasureLabel?: GameObjects.Text;
    private lensIcon?: GameObjects.Graphics;
    private direction: number;
    private readonly speed: number;
    private catchGlow?: GameObjects.Graphics;

    constructor(scene: Scene, public x: number, public y: number, readonly kind: OreKind, ratSpeed = 1, random: () => number = Math.random, gemDeposit = false, private readonly gemOnlyDeposit = false) {
        if (gemDeposit) {
            let rewards = rollDepositRewards(random, kind === 'largeRock');
            if (gemOnlyDeposit) {
                rewards = rewards.filter(reward => reward === 'diamond' || reward === 'ruby');
                if (rewards.length === 0) rewards = ['diamond'];
            }
            this.depositIntegrity = new DepositIntegrity(rewards, random);
        }
        this.direction = random() < 0.5 ? -1 : 1;
        this.speed = (80 + random() * 30) * 0.85 * ratSpeed;
        const type = TYPES[kind];
        this.radius = type.radius;
        this.value = kind === 'moneyBag' ? 150 + Math.floor(random() * 26) * 10 : type.value;
        this.baseWeight = type.weight;
        if (kind === 'treasureChest') this.treasureReward = rollTreasureReward(random);
        this.graphic = scene.add.graphics().setData('responsiveIgnore', true).setPosition(x, y);
        const r = this.radius;
        const g = this.graphic;
        if (kind === 'treasureChest') {
            this.drawChest();
            return;
        }
        if (kind === 'strengthPotion' || kind === 'goldRush' || kind === 'timeVial' || kind === 'streakVial') {
            g.save().scaleCanvas(r / 19, r / 19);
            g.fillStyle(0x9fc9bd).lineStyle(3, 0x365c50);
            g.beginPath().moveTo(-6, -13).lineTo(-6, -5).lineTo(-14, 3)
                .lineTo(-14, 13).lineTo(-8, 17).lineTo(8, 17).lineTo(14, 13)
                .lineTo(14, 3).lineTo(6, -5).lineTo(6, -13).closePath().fillPath().strokePath();
            g.fillStyle(type.color).fillRoundedRect(-10, 3, 20, 11, 3);
            g.fillStyle(kind === 'goldRush' ? 0xffee9a : kind === 'timeVial' ? 0xd5f8ff : 0xaff17d).fillRect(-8, 4, 4, 7);
            g.fillStyle(0xad7c43).lineStyle(2, 0x694729)
                .fillRoundedRect(-7, -18, 14, 7, 2).strokeRoundedRect(-7, -18, 14, 7, 2);
            if (kind === 'streakVial') {
                for (const x of [-5, 5]) {
                    g.fillStyle(0xffe68c).fillTriangle(x + 2, -1, x - 4, 7, x + 1, 7)
                        .fillTriangle(x - 1, 5, x + 4, 5, x - 2, 13);
                }
            } else if (kind === 'goldRush') {
                g.fillStyle(0xfff1af).lineStyle(1, 0x986019);
                g.beginPath().moveTo(-6, 6).lineTo(-2, 1).lineTo(4, 2)
                    .lineTo(7, 8).lineTo(0, 12).closePath().fillPath().strokePath();
            } else if (kind === 'timeVial') {
                g.fillStyle(0xe8ffff).fillCircle(0, 6, 7);
                g.lineStyle(1.5, 0x287e9a).strokeCircle(0, 6, 7)
                    .lineBetween(0, 6, 0, 1).lineBetween(0, 6, 4, 8);
            } else {
                g.fillStyle(0xfff1af).fillTriangle(2, -1, -4, 7, 1, 7).fillTriangle(-1, 5, 4, 5, -2, 13);
            }
            g.lineStyle(2, 0xe0f6de).lineBetween(-9, -1, -11, 2);
            g.restore();
            return;
        }
        if (kind === 'tnt') {
            const w = r * 0.65;
            const h = r * 0.82;
            g.fillStyle(type.color).lineStyle(3, 0x633128);
            g.fillRoundedRect(-w, -h, w * 2, h * 2, 7).strokeRoundedRect(-w, -h, w * 2, h * 2, 7);
            g.fillStyle(0x8d3027).fillRect(w * 0.5, -h + 5, w * 0.4, h * 2 - 10);
            g.fillStyle(0xdf6245).fillRect(-w * 0.73, -h + 6, w * 0.2, h * 2 - 12);
            g.fillStyle(0x7b4636).fillEllipse(0, -h + 3, w * 2, 10);
            g.lineStyle(2, 0x4b3a30).strokeEllipse(0, -h + 3, w * 2, 10);
            g.fillStyle(0x5d6262).fillRect(-w - 1, -h * 0.58, w * 2 + 2, 7).fillRect(-w - 1, h * 0.52, w * 2 + 2, 7);
            g.lineStyle(1, 0x9aa09b).lineBetween(-w, -h * 0.58, w, -h * 0.58)
                .lineBetween(-w, h * 0.52, w, h * 0.52);
            g.fillStyle(0xffe7a3).fillRoundedRect(-w + 4, -11, w * 2 - 8, 24, 2);
            g.lineStyle(3, 0x793524);
            for (const x of [-14, 14]) g.lineBetween(x - 4, -5, x + 4, -5).lineBetween(x, -5, x, 7);
            g.beginPath().moveTo(-5, 7).lineTo(-5, -5).lineTo(5, 7).lineTo(5, -5).strokePath();
            return;
        }
        if (this.isRat) {
            g.lineStyle(3, 0xbe9687);
            g.beginPath().moveTo(-12, 3).lineTo(-19, 0).lineTo(-20, -6).strokePath();
            g.fillStyle(type.color).lineStyle(2, 0x51483f);
            g.fillEllipse(-2, 2, 29, 20).strokeEllipse(-2, 2, 29, 20);
            g.fillTriangle(6, -5, 20, 5, 6, 9);
            g.fillStyle(0xb8998a).fillCircle(6, -7, 7);
            g.fillStyle(0xe3b5ab).fillCircle(6, -7, 4).fillCircle(19, 5, 2);
            g.fillStyle(0x201f1d).fillCircle(12, 0, 2);
            g.lineStyle(3, 0x51483f).lineBetween(-10, 10, -6, 12).lineBetween(6, 10, 10, 12);
            if (kind === 'diamondRat') {
                g.fillStyle(0x70e6f5).lineStyle(2, 0x287e9a);
                g.beginPath().moveTo(-12, -14).lineTo(-7, -20).lineTo(1, -20)
                    .lineTo(6, -14).lineTo(-3, -5).closePath().fillPath().strokePath();
                g.lineStyle(1, 0xe8ffff).lineBetween(-12, -14, 6, -14).lineBetween(-7, -20, -3, -5);
            } else if (kind === 'rubyRat') {
                g.fillStyle(0xe83864).lineStyle(2, 0x751d42);
                g.beginPath().moveTo(-7, -23).lineTo(1, -23).lineTo(7, -16)
                    .lineTo(3, -9).lineTo(-3, -5).lineTo(-10, -10).lineTo(-13, -16)
                    .closePath().fillPath().strokePath();
                g.fillStyle(0xffa6bb).fillTriangle(-7, -23, -3, -16, -13, -16);
                g.fillStyle(0x9f2152).fillTriangle(7, -16, -3, -5, 3, -9);
                g.lineStyle(1, 0xffd2dd).lineBetween(-13, -16, 7, -16).lineBetween(-3, -16, 1, -23);
            }
            g.setScale(this.direction, 1);
            return;
        }
        if (kind === 'ruby') {
            g.fillStyle(type.color).lineStyle(2, 0x751d42);
            g.beginPath().moveTo(-r * 0.5, -r).lineTo(r * 0.5, -r)
                .lineTo(r, -r * 0.3).lineTo(r * 0.7, r * 0.55).lineTo(0, r)
                .lineTo(-r * 0.7, r * 0.55).lineTo(-r, -r * 0.3).closePath().fillPath().strokePath();
            g.fillStyle(0xffa6bb).fillTriangle(-r * 0.5, -r, 0, -r * 0.3, -r, -r * 0.3);
            g.fillStyle(0xff6288).fillTriangle(-r, -r * 0.3, 0, -r * 0.3, 0, r);
            g.fillStyle(0x9f2152).fillTriangle(r, -r * 0.3, 0, r, r * 0.7, r * 0.55);
            g.lineStyle(1, 0xffd2dd).lineBetween(-r, -r * 0.3, r, -r * 0.3)
                .lineBetween(0, -r * 0.3, r * 0.5, -r);
            return;
        }
        if (kind === 'diamond') {
            g.fillStyle(type.color).lineStyle(2, 0x287e9a);
            g.beginPath().moveTo(-r, -r * 0.25).lineTo(-r * 0.5, -r * 0.75)
                .lineTo(r * 0.5, -r * 0.75).lineTo(r, -r * 0.25).lineTo(0, r)
                .closePath().fillPath().strokePath();
            g.fillStyle(0xe8ffff).fillTriangle(-r, -r * 0.25, 0, -r * 0.75, 0, r);
            g.lineStyle(1, 0x3196b1).lineBetween(-r, -r * 0.25, r, -r * 0.25)
                .lineBetween(-r * 0.5, -r * 0.25, 0, r).lineBetween(r * 0.5, -r * 0.25, 0, r);
            return;
        }
        if (kind === 'moneyBag' || kind === 'mysteryBag') {
            const mystery = kind === 'mysteryBag';
            g.save().scaleCanvas(r / 22, r / 22);
            // Faceted canvas, dark contour and warm highlights match the ore art.
            g.fillStyle(type.color).lineStyle(3, mystery ? 0x48364f : 0x73502c);
            g.beginPath().moveTo(-5, -10).lineTo(-13, -3).lineTo(-18, 8)
                .lineTo(-14, 17).lineTo(-4, 20).lineTo(12, 18).lineTo(18, 11)
                .lineTo(15, 0).lineTo(6, -10).closePath().fillPath().strokePath();
            g.fillStyle(mystery ? 0xb6a0c6 : 0xe2b66c);
            g.beginPath().moveTo(-5, -9).lineTo(-12, 0).lineTo(-13, 10)
                .lineTo(-7, 15).lineTo(-5, 2).lineTo(0, -6).closePath().fillPath();
            g.fillStyle(mystery ? 0x675279 : 0xa37239);
            g.beginPath().moveTo(6, -8).lineTo(11, 5).lineTo(9, 14)
                .lineTo(-4, 18).lineTo(11, 17).lineTo(16, 10).lineTo(13, 1).closePath().fillPath();
            // Gathered mouth and a knotted rope replace the old flat triangle.
            g.fillStyle(type.color).lineStyle(2, mystery ? 0x48364f : 0x73502c);
            g.beginPath().moveTo(-5, -10).lineTo(-10, -20).lineTo(-2, -18)
                .lineTo(6, -21).lineTo(9, -19).lineTo(5, -10).closePath().fillPath().strokePath();
            g.lineStyle(2, 0x9a6c35).lineBetween(-3, -17, -1, -11).lineBetween(5, -18, 3, -11);
            g.lineStyle(3, 0x66472a).lineBetween(-7, -10, 7, -10);
            g.lineStyle(2, 0xe4bf7b).lineBetween(-6, -11, 6, -11);
            g.lineStyle(2, 0x66472a).strokeEllipse(9, -10, 8, 5).lineBetween(7, -8, 12, -4);
            if (mystery) {
                g.lineStyle(3, 0xffedb7);
                g.beginPath().moveTo(-6, 0).lineTo(-5, -4).lineTo(3, -5)
                    .lineTo(7, -1).lineTo(6, 3).lineTo(0, 7).lineTo(0, 9).strokePath();
                g.fillStyle(0xffedb7).fillCircle(0, 14, 1.7);
                g.restore();
                return;
            }
            // A painted dollar sign identifies a cash sack; payout stays random.
            g.lineStyle(2.5, 0x67472a);
            g.beginPath().moveTo(6, -1).lineTo(-1, -2).lineTo(-5, 1).lineTo(-3, 5)
                .lineTo(4, 7).lineTo(5, 10).lineTo(1, 13).lineTo(-6, 12).strokePath();
            g.lineBetween(0, -5, 0, 15);
            g.restore();
            return;
        }
        const rock = kind === 'rock' || kind === 'mediumRock' || kind === 'heavyRock' || kind === 'largeRock';
        // Uneven silhouettes and flat facets distinguish ore from round pebbles.
        const outline = rock
            ? [[-0.95, 0.25], [-0.8, -0.5], [-0.25, -0.9], [0.5, -0.78], [0.95, -0.15], [0.8, 0.65], [0.1, 0.9], [-0.6, 0.75]]
            : [[-0.95, 0.1], [-0.7, -0.55], [-0.28, -0.6], [0.05, -0.94], [0.65, -0.68], [0.93, -0.05], [0.65, 0.65], [-0.1, 0.9], [-0.65, 0.65]];
        g.fillStyle(type.color).lineStyle(3, rock ? 0x414952 : 0x986019);
        g.beginPath();
        outline.forEach(([x, y], index) => {
            if (index === 0) g.moveTo(x * r, y * r);
            else g.lineTo(x * r, y * r);
        });
        g.closePath().fillPath().strokePath();
        g.fillStyle(rock ? 0xb6bfc3 : 0xffe889);
        g.fillTriangle(-0.7 * r, -0.5 * r, -0.25 * r, -0.65 * r, -0.35 * r, 0.1 * r);
        g.fillTriangle(-0.25 * r, -0.65 * r, 0.5 * r, -0.6 * r, 0.1 * r, -0.1 * r);
        g.fillStyle(rock ? 0x68757e : 0xd99a20);
        g.fillTriangle(0.1 * r, -0.1 * r, 0.85 * r, -0.05 * r, 0.6 * r, 0.6 * r);
        g.fillTriangle(-0.6 * r, 0.6 * r, 0.6 * r, 0.6 * r, -0.1 * r, 0.8 * r);
        if (rock) {
            g.lineStyle(2, 0x535f68);
            g.beginPath().moveTo(-0.1 * r, -0.5 * r).lineTo(0.12 * r, -0.12 * r)
                .lineTo(-0.12 * r, 0.2 * r).lineTo(0.1 * r, 0.5 * r).strokePath();
            g.fillStyle(0x58636c).fillEllipse(-0.5 * r, 0.3 * r, 5, 3).fillEllipse(0.5 * r, -0.35 * r, 4, 3);

            if (this.gemDeposit) this.drawDepositCrystals();
        } else {
            g.lineStyle(2, 0xfff6c7);
            const x = -0.36 * r;
            const y = -0.33 * r;
            g.lineBetween(x - 4, y, x + 4, y).lineBetween(x, y - 4, x, y + 4);
        }
    }

    private drawDepositCrystals(): void {
        const g = this.graphic;
        for (const [fx, fy] of [[-0.4, -0.25], [0.3, -0.35], [0.05, 0.35]]) {
            const x = fx * this.radius;
            const y = fy * this.radius;
            g.fillStyle(0x70e6f5).lineStyle(2, 0x287e9a);
            g.beginPath().moveTo(x - 7, y - 3).lineTo(x, y - 11)
                .lineTo(x + 7, y - 3).lineTo(x, y + 8).closePath().fillPath().strokePath();
            g.lineStyle(1, 0xe8ffff).lineBetween(x, y - 8, x - 3, y);
        }
    }

    /** A clean gem catch detaches it; a rock catch carries its gem too. */
    prepareCatch(): void {
        if (this.supportingRock) {
            this.supportingRock.mountedGem = undefined;
            this.supportingRock = undefined;
        }
        if (this.mountedGem) this.mountedGem.available = false;
    }

    mountGem(gem: Collectable, random: () => number = Math.random, combined = false): void {
        if (combined) {
            this.combinedGemRock = true;
            // Combined rocks guarantee the visible gem; hidden contents contain only gold.
            const gold = (this.gemOnlyDeposit ? [] : rollDepositRewards(random, this.kind === 'largeRock'))
                .filter(kind => kind === 'small' || kind === 'medium');
            this.depositIntegrity = new DepositIntegrity(gold, random);
            this.drawDepositCrystals();
        }
        this.mountedGem = gem;
        gem.supportingRock = this;
        this.gemOffset = { x: gem.x - this.x, y: gem.y - this.y };
        gem.graphic.setDepth(1);
    }

    advanceDepositHaul(scene: Scene, distance: number): void {
        const integrity = this.depositIntegrity;
        if (!integrity) return;
        const previousStage = integrity.stage;
        const lost = integrity.advance(distance);
        if (integrity.stage !== previousStage) {
            const g = this.depositCracks ??= scene.add.graphics().setDepth(5);
            g.clear().setPosition(this.x, this.y).lineStyle(integrity.stage + 1, 0x352b28);
            const r = this.radius;
            for (let i = 0; i <= integrity.stage; i++) {
                const angle = i * 2.1;
                g.beginPath().moveTo(0, 0).lineTo(Math.cos(angle) * r * 0.35, Math.sin(angle) * r * 0.35)
                    .lineTo(Math.cos(angle + 0.35) * r * 0.65, Math.sin(angle + 0.35) * r * 0.65)
                    .lineTo(Math.cos(angle) * r * 0.9, Math.sin(angle) * r * 0.9).strokePath();
            }
        }
        for (const [index, kind] of lost.entries()) {
            const color = kind === 'ruby' ? 0xe83864 : kind === 'diamond' ? 0x70e6f5 : 0xffca28;
            const fragment = scene.add.graphics().setPosition(this.x, this.y).setDepth(7);
            fragment.fillStyle(color).fillTriangle(-6, -4, 6, -4, 0, 7);
            // Lost fragments crumble away; they are visual feedback, not collectible drops.
            scene.tweens.add({ targets: fragment, x: this.x + (index % 2 ? -32 : 32),
                y: this.y + 65, angle: 120, alpha: 0, duration: 650,
                onComplete: () => fragment.destroy() });
        }
    }

    get isRat(): boolean { return this.kind === 'rat' || this.kind === 'diamondRat' || this.kind === 'rubyRat'; }

    hideTreasureLabel(): void {
        this.treasureLabel?.destroy();
        this.treasureLabel = undefined;
        this.lensIcon?.destroy();
        this.lensIcon = undefined;
    }

    private drawChest(): void {
        const g = this.graphic.clear();
        const opened = this.chestOpened;
        // Original rounded silhouette, with light from the upper left.
        g.fillStyle(0x6b3e24).lineStyle(3, 0x432b20);
        g.fillRoundedRect(-30, -4, 60, 29, 4).strokeRoundedRect(-30, -4, 60, 29, 4);
        g.fillStyle(0xb77736).fillRect(-26, 0, 52, 21);
        g.fillStyle(0xd09550).fillRect(-26, 0, 7, 19);
        g.fillStyle(0x8d572e).fillRect(21, 0, 5, 21);
        g.fillStyle(0x704329, 0.5).fillRect(-26, 17, 52, 4);
        g.lineStyle(1.5, 0x85502c).lineBetween(-25, 8, 25, 8).lineBetween(-25, 17, 25, 17);
        g.lineStyle(1, 0xe0a461).lineBetween(-24, 2, -9, 2).lineBetween(-13, 10, 8, 10);
        g.lineStyle(1, 0x89542e).lineBetween(-12, 5, -4, 5).lineBetween(2, 14, 12, 14);
        g.strokeEllipse(-9, 13, 5, 2);
        const lidY = opened ? -28 : -18;
        // Shadow beneath the lid and a narrow highlight along its rounded top.
        g.fillStyle(0x432b20, 0.35).fillRect(-27, opened ? -3 : 0, 54, 4);
        g.fillStyle(0x98602e).lineStyle(3, 0x432b20);
        g.fillRoundedRect(-30, lidY, 60, 20, 6).strokeRoundedRect(-30, lidY, 60, 20, 6);
        g.fillStyle(0xb67b3c).fillRoundedRect(-27, lidY + 2, 53, 8, 4);
        g.fillStyle(0x754627).fillRect(-26, lidY + 14, 52, 4);
        g.lineStyle(1.5, 0xd9a360).lineBetween(-23, lidY + 3, 22, lidY + 3);
        g.lineStyle(1, 0x81502a).lineBetween(-13, lidY + 10, 10, lidY + 10);
        // Brass bands retain their original placement, with edges and small rivets.
        for (const x of [-23, 16]) {
            g.fillStyle(0xe3b956).fillRect(x, lidY + 2, 7, 17).fillRect(x, 0, 7, 23);
            g.fillStyle(0xa87935).fillRect(x + 5, lidY + 3, 2, 15).fillRect(x + 5, 1, 2, 21);
            g.lineStyle(1, 0xffe6a0).lineBetween(x + 1, lidY + 3, x + 1, lidY + 16)
                .lineBetween(x + 1, 1, x + 1, 21);
            g.fillStyle(0x80582c).fillCircle(x + 3, lidY + 6, 1.1).fillCircle(x + 3, 19, 1.1);
        }
        if (opened) {
            g.fillStyle(0xffdf65, 0.18).fillEllipse(0, -8, 65, 36);
            g.fillStyle(0x432b20).fillRect(-25, -7, 50, 10);
            g.lineStyle(1, 0xdba55b).lineBetween(-24, 3, 24, 3);
            if (this.treasureReward?.kind === 'money') {
                for (const [x, y] of [[-18, -6], [-7, -9], [5, -6], [17, -8], [0, -14]]) {
                    g.fillStyle(0xffd447).lineStyle(1, 0xa96b1d).fillCircle(x, y, 6).strokeCircle(x, y, 6);
                }
            } else if (this.treasureReward?.kind === 'dynamite') {
                for (let i = 0; i < this.treasureReward.amount; i++) {
                    const x = (i - (this.treasureReward.amount - 1) / 2) * 12;
                    g.fillStyle(0xc43c2f).fillRoundedRect(x - 4, -22, 8, 22, 2);
                    g.lineStyle(1, 0xffe486).lineBetween(x, -22, x + 2, -26);
                }
            } else if (this.treasureReward?.kind === 'life') {
                // A red vial with a heart identifies the extra-life reward.
                g.fillStyle(0xf1c9cc).lineStyle(2, 0x793341);
                g.fillRoundedRect(-11, -20, 22, 26, 7).strokeRoundedRect(-11, -20, 22, 26, 7);
                g.fillStyle(0xd94b52).fillRoundedRect(-8, -11, 16, 14, 4);
                g.fillStyle(0xb68b4e).fillRoundedRect(-6, -26, 12, 8, 2);
                g.fillStyle(0xffe8e8).fillCircle(-3, -8, 4).fillCircle(3, -8, 4)
                    .fillTriangle(-7, -7, 7, -7, 0, 1);
            } else if (this.treasureReward?.kind === 'lightweightGrip') {
                g.lineStyle(5, 0xc5e5ec).lineBetween(0, -25, 0, -12);
                g.lineStyle(4, 0x7199a8).beginPath().moveTo(0, -12).lineTo(-12, -5)
                    .lineTo(-8, 4).moveTo(0, -12).lineTo(12, -5).lineTo(8, 4).strokePath();
            } else {
                g.fillStyle(this.treasureReward?.kind === 'luck' ? 0xb67ee0 : 0xdba34d)
                    .fillRoundedRect(-10, -18, 20, 20, 4);
                g.fillStyle(0xb68b4e).fillRect(-6, -24, 12, 7);
                g.fillStyle(0xffedbb).fillCircle(0, -9, 4);
            }
            g.lineStyle(2, 0xfff4c2).lineBetween(-9, -23, -1, -23).lineBetween(-5, -27, -5, -19);
        } else {
            g.fillStyle(0x432b20, 0.35).fillRoundedRect(-6, -5, 14, 17, 3);
            g.fillStyle(0xffd66a).lineStyle(2, 0x8a6028)
                .fillRoundedRect(-7, -7, 14, 17, 3).strokeRoundedRect(-7, -7, 14, 17, 3);
            g.fillStyle(0xd09b42).fillRect(3, -4, 2, 11);
            g.lineStyle(1, 0xffefb3).lineBetween(-4, -5, 3, -5).lineBetween(-5, -3, -5, 6);
            g.fillStyle(0x634227).fillCircle(0, -1, 2.5).fillRect(-1, -1, 2, 6);
        }
    }

    /** The first hit unlocks the chest in place; the claw returns empty. */
    openChest(scene: Scene): boolean {
        if (this.kind !== 'treasureChest' || this.chestOpened || !this.available) return false;
        this.chestOpened = true;
        this.drawChest();
        this.hideTreasureLabel();
        const label = scene.add.text(this.x, this.y + (this.kind === 'treasureChest' ? 29 : this.radius + 3), `${treasureRewardLabel(this.treasureReward!)}\nCatch again to collect`, {
            fontFamily: 'Arial', fontSize: 16, fontStyle: 'bold', color: '#ffe06a', align: 'center',
            stroke: '#483126', strokeThickness: 4
        }).setOrigin(0.5, 0).setDepth(10);
        // Keep instructions inside the playfield, including chests near the sides.
        label.setX(Math.max(label.width / 2 + 16, Math.min(WORLD.width - label.width / 2 - 16, this.x)));
        this.treasureLabel = label;
        return true;
    }

    revealTreasureReward(scene: Scene): void {
        if (!this.treasureReward || this.chestOpened) return;
        this.showLensReveal(scene, treasureRewardLabel(this.treasureReward));
    }

    revealMysteryReward(scene: Scene, reward: MysteryReward): void {
        const text = reward.kind === 'money' ? `$${reward.amount}`
            : reward.kind === 'dynamite' ? '+1 DYNAMITE' : 'STRENGTH x2';
        this.showLensReveal(scene, text);
    }

    private showLensReveal(scene: Scene, text: string): void {
        this.hideTreasureLabel();
        this.treasureLabel = scene.add.text(this.x, this.y, text, {
            fontFamily: 'Arial', fontSize: 16, fontStyle: 'bold', color: '#bdefff',
            stroke: '#302e2b', strokeThickness: 4
        }).setOrigin(0.5, 0).setDepth(10);
        this.lensIcon = drawShopProduct(scene, 0, 0, 'prospectorsLens', 0.2).setDepth(10);
        this.moveTo(this.x, this.y);
    }

    /** Catch feedback uses known values only: sealed mystery bags keep their secret. */
    celebrateCatch(scene: Scene, value = this.value): boolean {
        if (value < 90) return false;
        const intensity = Math.min(1, Math.max(0, (value - 90) / 660));
        const color = this.kind === 'ruby' || this.kind === 'rubyRat' ? 0xff93b4
            : this.kind === 'diamond' || this.kind === 'diamondRat' ? 0x9ef5ff : 0xffe48a;
        const glow = scene.add.graphics().setPosition(this.x, this.y).setDepth(4);
        this.catchGlow = glow;
        const r = this.radius;
        if (intensity > 0.1) glow.fillStyle(color, intensity * 0.16).fillCircle(0, 0, r + 10);
        if (intensity > 0.3) glow.lineStyle(2, color, intensity * 0.7).strokeCircle(0, 0, r + 6);
        const count = 1 + Math.round(intensity * 11);
        for (let i = 0; i < count; i++) {
            const angle = i * Math.PI * 2 / count;
            const distance = r + 12 + (i % 2) * 9;
            const x = Math.cos(angle) * distance;
            const y = Math.sin(angle) * distance;
            const size = (i % 2 === 0 ? 2.5 : 2) + intensity * 5;
            glow.fillStyle(i % 2 === 0 ? 0xffffff : color);
            glow.fillTriangle(x - size, y, x, y - 2, x + size, y);
            glow.fillTriangle(x - size, y, x, y + 2, x + size, y);
            glow.fillTriangle(x, y - size, x - 2, y, x, y + size);
            glow.fillTriangle(x, y - size, x + 2, y, x, y + size);
        }
        // A bright glint sweeps across the face while the burst follows the hauled ore.
        glow.lineStyle(1 + intensity * 2, 0xffffff, 0.3 + intensity * 0.6)
            .lineBetween(-r * 0.35, -r * 0.4, r * 0.15, r * 0.15);
        glow.setAlpha(0.45 + intensity * 0.55);
        scene.tweens.add({
            targets: glow, scale: 1.05 + intensity * 0.65, alpha: 0,
            duration: 200 + intensity * 750, ease: 'Cubic.easeOut',
            onComplete: () => { glow.destroy(); if (this.catchGlow === glow) this.catchGlow = undefined; }
        });
        return true;
    }

    collectionValue(diamondMultiplier = 1): number {
        if (this.mountedGem) {
            return this.value + this.mountedGem.collectionValue(diamondMultiplier);
        }
        if (this.kind === 'treasureChest') return this.chestOpened && this.treasureReward?.kind === 'money' ? this.treasureReward.amount : 0;
        if (this.kind === 'diamondRat') return TYPES.rat.value + Math.round(TYPES.diamond.value * diamondMultiplier);
        if (this.kind === 'rubyRat') return TYPES.rat.value + Math.round(TYPES.ruby.value * diamondMultiplier);
        return Math.round(this.value * (this.kind === 'diamond' || this.kind === 'ruby' ? diamondMultiplier : 1));
    }

    update(seconds: number, objects: Collectable[]): void {
        if (!this.available || !this.isRat) return;
        const nextX = this.x + this.direction * this.speed * seconds;
        const dx = nextX - WORLD.centerX;
        const dy = this.y - WORLD.pivotY;
        const blocked = nextX - this.radius < 40 || nextX + this.radius > WORLD.width - 40
            || Math.hypot(dx, dy) > WORLD.spawnRange - this.radius
            || Math.abs(Math.atan2(dx, dy)) > WORLD.maxAngle
            || objects.some(other => other !== this && other.available
                && Math.hypot(nextX - other.x, this.y - other.y) < this.radius + other.radius + 4);
        if (blocked) this.direction *= -1;
        else this.moveTo(nextX, this.y);
        this.graphic.setScale(this.direction, 1);
    }

    moveTo(x: number, y: number): void {
        this.x = x;
        this.y = y;
        this.graphic.setPosition(x, y);
        this.mountedGem?.moveTo(x + this.gemOffset.x, y + this.gemOffset.y);
        this.catchGlow?.setPosition(x, y);
        this.depositCracks?.setPosition(x, y);
        if (this.treasureLabel) {
            this.treasureLabel.setData('responsiveIgnore', true);
            const iconSpace = this.lensIcon ? 24 : 0;
            const halfWidth = (this.treasureLabel.width + iconSpace) / 2;
            const centerX = Math.max(halfWidth + 16, Math.min(WORLD.width - halfWidth - 16, x));
            const labelY = y + (this.kind === 'treasureChest' ? 29 : this.radius + 3);
            this.treasureLabel.setPosition(centerX + iconSpace / 2, labelY);
            this.lensIcon?.setData('responsiveIgnore', true).setPosition(centerX - halfWidth + 8, labelY + this.treasureLabel.height / 2 - 1);
        }
    }

    destroy(): void {
        this.available = false;
        if (this.supportingRock) {
            this.supportingRock.mountedGem = undefined;
            this.supportingRock = undefined;
        }
        if (this.mountedGem?.kind === 'diamond' || this.mountedGem?.kind === 'ruby') {
            this.blastedGem = this.mountedGem.kind;
        }
        this.mountedGem?.destroy();
        this.mountedGem = undefined;
        this.treasureLabel?.destroy();
        this.treasureLabel = undefined;
        this.lensIcon?.destroy();
        this.lensIcon = undefined;
        if (this.catchGlow) {
            this.catchGlow.scene.tweens.killTweensOf(this.catchGlow);
            this.catchGlow.destroy();
            this.catchGlow = undefined;
        }
        this.depositCracks?.destroy();
        this.graphic.destroy();
    }
}

/** Valuable catches require a longer trip; mystery bags keep an unknown payout. */
export function spawnDepthRange(kind: OreKind, minimumDepth: number): [number, number] {
    switch (kind) {
        case 'strengthPotion':
        case 'goldRush':
        case 'streakVial':
        case 'timeVial': return [minimumDepth, 860];
        case 'tnt': return [400, 820];
        case 'diamond': return [800, 880];
        case 'ruby': return [560, 860];
        case 'diamondRat':
        case 'rubyRat': return [570, 700];
        case 'giant': return [700, 840];
        case 'treasureChest': return [620, 820];
        case 'large': return [570, 730];
        case 'mysteryBag': return [570, 800];
        case 'moneyBag': return [570, 820];
        case 'medium': return [Math.max(minimumDepth, 440), 620];
        case 'small': return [minimumDepth, 500];
        default: return [minimumDepth, 880];
    }
}

const isStaticHazard = (kind: OreKind): boolean => kind === 'rock' || kind === 'mediumRock' || kind === 'heavyRock' || kind === 'largeRock';
const isQuarryTreasure = (kind: OreKind): boolean => ['diamond', 'ruby', 'moneyBag', 'mysteryBag', 'treasureChest'].includes(kind);
const needsAimingGap = (kind: OreKind): boolean => !isStaticHazard(kind) && kind !== 'tnt' && kind !== 'rat' && kind !== 'diamondRat' && kind !== 'rubyRat';

export function generateCollectables(scene: Scene, level: LevelConfig = LEVELS[0], random: () => number = Math.random): Collectable[] {
    const isQuarry = (level.mine ?? 'quarry') === 'quarry';
    // Roll once per seeded level, not on placement retries. Quarry bonus treasure is rolled below before placement retries.
    const hasGemRock = random() < (isQuarry ? 0.75 : 0.5);
    const hasChest = random() < 0.5;
    const hasRuby = random() < 0.35;
    // Place the largest objects first; retry the whole layout if it becomes crowded.
    const kinds: OreKind[] = [
        'giant', ...Array<OreKind>(level.largeRocks).fill('largeRock'),
        ...Array<OreKind>(level.heavyRocks).fill('heavyRock'),
        'large', ...Array.from({ length: level.rocks }, (_, index): OreKind => index === 0 ? 'mediumRock' : 'rock'),
        ...(hasChest ? ['treasureChest' as const] : []),
        ...Array<OreKind>(level.tnt).fill('tnt'),
        'medium', 'medium', 'medium', 'medium',
        ...Array<OreKind>(level.moneyBags).fill('moneyBag'),
        ...Array<OreKind>(level.diamonds).fill('diamond'),
        ...(hasRuby ? ['ruby' as const] : []),
        'rock', 'small', 'small', 'small', 'small', 'small', 'small', 'strengthPotion', 'goldRush', 'timeVial', 'streakVial', 'mysteryBag',
        ...Array<OreKind>(level.rats).fill('rat'),
        ...Array<OreKind>(level.diamondRats).fill('diamondRat')
    ];
    if (isQuarry) {
        // Trade low-value filler for a few big catches while keeping a mixed mine.
        for (const kind of ['small', 'small', 'medium', 'medium'] as const) {
            kinds.splice(kinds.indexOf(kind), 1);
        }
        kinds.push('giant', 'giant', 'large', 'diamond');
        // Give even the opening levels a fuller mix of gold and obstacles.
        kinds.push('small', 'medium', 'large', 'rock', 'mediumRock');
    }
    if (level.mine === 'goldBasin') {
        kinds.push('giant', 'giant', 'giant', 'giant', 'giant', 'giant', 'giant', 'large', 'large');
        if (hasGemRock) kinds.push('largeRock');
        // Trade filler for big hauls rather than stacking both into the same space.
        for (const kind of ['medium', 'medium', 'small', 'small', 'small', 'small'] as const) {
            kinds.splice(kinds.indexOf(kind), 1);
        }
    }
    if (level.mine === 'gemHollow') {
        kinds.push('diamond', 'diamond', 'diamond', 'diamond', 'ruby', 'ruby', 'ruby');
        // Precision obstacles: placement still requires a clear shot to every gem.
        kinds.push('largeRock', 'largeRock', 'mediumRock', 'mediumRock', 'rock', 'rock');
    }
    // Populate the extra screen area, then add up to 45% more catches across the full mix.
    // Large treasure and both gems are included even in the first density cycle.
    const widthExtra = Math.max(0, Math.round((WORLD.width / 1024 - 1) * 12));
    // Narrow windows need fewer additions to keep deep, large objects placeable.
    const density = Math.min(0.45, 0.10 + (WORLD.width / 1024 - 1) * 0.7);
    const densityExtra = Math.max(isQuarry ? 6 : 5, Math.ceil((kinds.length + widthExtra) * (density + (isQuarry ? 0.08 : 0))));
    const routeKind = (kind: OreKind): OreKind => {
        if (level.mine === 'gemHollow') {
            if (kind === 'large') return 'diamond';
            if (kind === 'giant') return 'ruby';
        }
        return kind;
    };
    const widthAdditions: OreKind[] = level.mine === 'goldBasin'
        ? ['giant', 'large', 'small', 'small', 'large', 'small', 'strengthPotion', 'goldRush']
        : isQuarry ? ['large', 'moneyBag', 'rock', 'small', 'diamond', 'medium', 'ruby', 'large']
        : ['small', 'medium', 'rock', 'small', 'moneyBag', 'medium', 'heavyRock', 'diamond'];
    for (let i = 0; i < widthExtra; i++) kinds.push(routeKind(widthAdditions[i % widthAdditions.length]));
    const additions: OreKind[] = level.mine === 'goldBasin' ? [
        'large', 'small', 'small', 'large', 'giant', 'strengthPotion',
        'goldRush', 'timeVial', 'streakVial', 'small', 'large', 'small'
    ] : [
        'large', 'moneyBag', 'diamond', 'ruby', 'giant', 'mediumRock',
        'mysteryBag', 'medium', 'largeRock', 'small', 'heavyRock', 'moneyBag',
        'diamond', 'ruby', 'large', 'rock', 'strengthPotion', 'goldRush',
        'timeVial', 'streakVial',
        ...(hasChest ? ['treasureChest' as const] : []),
        ...(level.rats > 0 ? ['rat' as const] : []),
        ...(level.diamondRats > 0 ? ['diamondRat' as const, 'rubyRat' as const] : []),
        ...(level.tnt > 0 ? ['tnt' as const] : [])
    ];
    for (let i = 0; i < densityExtra; i++) kinds.push(routeKind(additions[i % additions.length]));
    if ((level.mine ?? 'quarry') === 'quarry') {
        // Roll extras once for this seeded layout, never again on placement retries.
        // Chest and mystery guarantees replace their generic density spawns.
        const chestCount = 1 + (random() < 0.4 ? 1 : 0);
        const mysteryCount = 2 + (random() < 0.5 ? 1 : 0) + (random() < 0.2 ? 1 : 0);
        // Cash bags keep their existing population plus two guaranteed additions.
        const mixedTreasure = kinds.filter(kind => kind !== 'treasureChest' && kind !== 'mysteryBag');
        kinds.splice(0, kinds.length, ...mixedTreasure,
            ...Array<OreKind>(chestCount).fill('treasureChest'),
            ...Array<OreKind>(mysteryCount).fill('mysteryBag'), 'moneyBag', 'moneyBag');
    }
    if (level.mine === 'goldBasin') {
        // Quarry keeps its mixed treasure; this route focuses on heavy gold.
        const caps: Partial<Record<OreKind, number>> = {
            diamond: 1, ruby: 0, diamondRat: 0, rubyRat: 0,
            moneyBag: 1, mysteryBag: 0, treasureChest: 0,
            strengthPotion: 0, goldRush: 0, timeVial: 0, streakVial: 1
        };
        const counts: Partial<Record<OreKind, number>> = {};
        const focused = kinds.filter(kind => {
            counts[kind] = (counts[kind] ?? 0) + 1;
            return caps[kind] === undefined || counts[kind]! <= caps[kind]!;
        });
        // Minimum supplies plus independent bonus rolls, fixed for this seeded layout.
        const extraTnt = random() < 0.4 ? 1 : 0;
        const timeVials = (level.timeVials ?? 2) + (random() < 0.5 ? 1 : 0) + (random() < 0.2 ? 1 : 0);
        const strengthVials = (level.strengthVials ?? 2) + (random() < 0.4 ? 1 : 0);
        const goldRushVials = (level.goldRushVials ?? 2) + (random() < 0.4 ? 1 : 0);
        kinds.splice(0, kinds.length, ...focused, ...Array<OreKind>(extraTnt).fill('tnt'),
            ...Array<OreKind>(timeVials).fill('timeVial'),
            ...Array<OreKind>(strengthVials).fill('strengthPotion'),
            ...Array<OreKind>(goldRushVials).fill('goldRush'));
    }
    if (level.mine === 'gemHollow') {
        // Keep the precision route free of nuggets, including width/density filler.
        const gemsAndSupplies = kinds.filter(kind => !['small', 'medium', 'large', 'giant', 'goldRush'].includes(kind));
        kinds.splice(0, kinds.length, ...gemsAndSupplies);
    }
    const densityHazards = additions.slice(0, Math.min(densityExtra, additions.length)).map(routeKind).filter(isStaticHazard);
    const placementPriority = (kind: OreKind): number => isQuarry && kind === 'tnt' ? 80
        : level.mine === 'gemHollow'
        && (kind === 'diamond' || kind === 'ruby') ? 100
        : (level.mine ?? 'quarry') === 'quarry' && isQuarryTreasure(kind) ? 35 : TYPES[kind].radius;
    kinds.sort((a, b) => placementPriority(b) - placementPriority(a));
    // Extra Quarry treasure can need more placement attempts in narrow windows.
    const placementAttempts = (level.mine ?? 'quarry') === 'quarry' ? 600 : 300;
    for (let layout = 0; layout < placementAttempts; layout++) {
        // If extra blockers hide too many shots, keep the density by replacing
        // those added rocks with similarly sized gold rather than dropping catches.
        if (layout === 50) {
            for (const kind of densityHazards) {
                const index = kinds.lastIndexOf(kind);
                if (index >= 0) {
                    if (level.mine === 'gemHollow') kinds.splice(index, 1);
                    else kinds[index] = kind === 'largeRock' ? 'large' : kind === 'heavyRock' ? 'large' : 'medium';
                }
            }
            kinds.sort((a, b) => placementPriority(b) - placementPriority(a));
        }
        if (level.mine === 'goldBasin' && layout === 100) {
            // Make room for giant hauls, the gem host and supplies by dropping filler first.
            for (let removed = 0; removed < 4; removed++) {
                const small = kinds.lastIndexOf('small');
                if (small < 0) break;
                kinds.splice(small, 1);
            }
            for (let removed = 0; removed < 2; removed++) {
                const medium = kinds.lastIndexOf('medium');
                if (medium < 0) break;
                kinds.splice(medium, 1);
            }
        }
        // Crowded seeds may need one fewer small obstacle to retain clear shots.
        // Keep the new rock size and all treasure; retries use the same seeded fallback.
        if (layout === 150) {
            const smallRock = kinds.indexOf('rock');
            const depositHosts = kinds.filter(kind => kind === 'rock' || kind === 'largeRock').length;
            if (smallRock >= 0 && (level.mine !== 'goldBasin' || depositHosts > 1)) kinds.splice(smallRock, 1);
        }
        // Narrow Quarry layouts can use slimmer blockers without losing treasure or objects.
        if (isQuarry && layout === 250) {
            for (let i = 0; i < kinds.length; i++) {
                if (kinds[i] === 'largeRock' || kinds[i] === 'heavyRock') kinds[i] = 'mediumRock';
            }
            kinds.sort((a, b) => placementPriority(b) - placementPriority(a));
        }
        if (isQuarry && layout === 400) {
            let keptGemHost = false;
            for (let i = 0; i < kinds.length; i++) {
                if (kinds[i] !== 'mediumRock') continue;
                if (!keptGemHost) keptGemHost = true;
                else kinds[i] = 'rock';
            }
            // Prefer the special gem host over an excess of ordinary blockers.
            for (let removed = 0; removed < 2; removed++) {
                if (kinds.filter(kind => kind === 'rock').length <= 1) break;
                kinds.splice(kinds.lastIndexOf('rock'), 1);
            }
            kinds.sort((a, b) => placementPriority(b) - placementPriority(a));
        }
        const positions: { x: number; y: number; radius: number; kind: OreKind }[] = [];
        for (const [index, kind] of kinds.entries()) {
            const radius = TYPES[kind].radius;
            const [baseMinY, baseMaxY] = spawnDepthRange(kind, level.minimumDepth);
            const scatteredGem = level.mine === 'gemHollow' && (kind === 'diamond' || kind === 'ruby');
            const scatteredQuarryTreasure = (level.mine ?? 'quarry') === 'quarry' && isQuarryTreasure(kind);
            let maxY = level.mine === 'goldBasin' && (kind === 'small' || kind === 'medium') ? 800 : baseMaxY;
            // Large groups of giant nuggets need room across the middle and bottom.
            let minY = scatteredGem ? Math.max(440, level.minimumDepth)
                : level.mine === 'goldBasin' && kind === 'giant' ? 390
                : isQuarry && kind === 'giant' ? 430 : baseMinY;
            // Dense layouts can spread large gold through the deeper middle too.
            if (layout >= 100) {
                if (kind === 'giant') minY -= 80;
                else if (kind === 'large') minY -= 150;
                else if (kind === 'moneyBag' || kind === 'mysteryBag' || kind === 'treasureChest') minY -= 180;
            }
            if (level.mine === 'goldBasin' && layout >= 100) {
                if (kind === 'giant') minY = Math.max(350, minY - 40);
                else if (kind === 'large') minY -= 60;
            }
            if (level.mine === 'gemHollow' && kind === 'largeRock') minY = Math.max(minY, 620);
            if (level.mine === 'goldBasin' && kind === 'largeRock') minY = 650;
            if (isQuarry && kind === 'mediumRock') minY = Math.max(minY, 620);
            if (['strengthPotion', 'goldRush', 'timeVial', 'streakVial'].includes(kind)) {
                // Favor the middle; keep the chosen band through position retries.
                const depthRoll = random();
                [minY, maxY] = depthRoll < 0.15 ? [350, 440]
                    : depthRoll < 0.85 ? [440, 700] : [700, 820];
                minY = Math.max(minY, level.minimumDepth);
                maxY = Math.max(minY, maxY);
            }
            if (level.mine === 'gemHollow' && (kind === 'mediumRock' || kind === 'rock')) {
                minY = Math.max(minY, 600);
            }
            const deepQuarryValuable = isQuarry && (scatteredQuarryTreasure || kind === 'large' || kind === 'giant');
            if (deepQuarryValuable) {
                // Choose a band once per object, so placement retries cannot drift up
                // into easier surface space. Keep the bias even in crowded layouts.
                const depthRoll = random();
                [minY, maxY] = depthRoll < 0.10 ? [390, 500]
                    : depthRoll < 0.35 ? [500, 660] : [660, 860];
                minY = Math.max(minY, level.minimumDepth);
                maxY = Math.max(minY, maxY);
            }
            for (let attempt = 0; attempt < 2000; attempt++) {
                let x = 65 + random() * (WORLD.width - 130);
                let y = minY + random() * (maxY - minY);
                const gold = kind === 'small' || kind === 'medium' || kind === 'large' || kind === 'giant';
                const rock = kind === 'rock' || kind === 'mediumRock' || kind === 'heavyRock' || kind === 'largeRock';
                if (level.layout === 'goldPocket') {
                    if (gold) x = WORLD.centerX - (WORLD.width - 160) * 0.45 + random() * (WORLD.width - 160) * 0.9;
                    if (rock) y = isQuarry && kind === 'mediumRock' ? minY + random() * (850 - minY)
                        : level.mine === 'goldBasin' && kind === 'largeRock' ? 650 + random() * 200
                        : level.mine === 'gemHollow' ? Math.max(minY, 600) + random() * (850 - Math.max(minY, 600))
                        : 380 + random() * 470;
                } else if (level.layout === 'ratTunnels') {
                    if (kind === 'rat') y = RAT_LANE_Y + random() * 8 - 4;
                    // Leave an actual open horizontal route for the nuisance rats.
                    else if (y + radius > RAT_LANE_Y - (level.ratLaneMargin ?? 38)
                        && y - radius < RAT_LANE_Y + (level.ratLaneMargin ?? 38)) continue;
                } else if (level.layout === 'explosiveCavern') {
                    const anchors = positions.filter(position => kind === 'tnt'
                        ? position.kind === 'giant' || position.kind === 'large'
                        : position.kind === 'tnt');
                    if (((kind === 'tnt' && !isQuarry) || (kind === 'diamond' && !scatteredGem && !scatteredQuarryTreasure)) && anchors.length && attempt < 300) {
                        const anchor = anchors[Math.floor(random() * anchors.length)];
                        const angle = random() * Math.PI * 2;
                        const separation = radius + anchor.radius + 20 + random() * 25;
                        x = anchor.x + Math.cos(angle) * separation;
                        y = anchor.y + Math.sin(angle) * separation;
                        if (y < minY || y > maxY) continue;
                    }
                } else if (level.layout === 'deepMine' && (gold || kind === 'moneyBag') && !deepQuarryValuable) {
                    const deeperMin = Math.min(860 - radius, minY + (kind === 'small' ? 80 : 55));
                    const deeperMax = Math.min(890 - radius, maxY + 55);
                    y = deeperMin + random() * (deeperMax - deeperMin);
                }
                const dx = x - WORLD.centerX;
                const dy = y - WORLD.pivotY;
                if (x - radius < 40 || x + radius > WORLD.width - 40 || y + radius > WORLD.floorY || Math.hypot(dx, dy) > WORLD.spawnRange - radius || Math.abs(Math.atan2(dx, dy)) > WORLD.maxAngle) continue;
                if (positions.some(other => Math.hypot(x - other.x, y - other.y) < radius + other.radius + (layout < 50 ? 18 : 10))) continue;
                if (scatteredGem && positions.some(other => (other.kind === 'diamond' || other.kind === 'ruby')
                    && (Math.hypot(x - other.x, y - other.y) < 130
                        || Math.abs(Math.atan2(dx, dy) - Math.atan2(other.x - WORLD.centerX, other.y - WORLD.pivotY)) < 0.045))) continue;
                if (scatteredQuarryTreasure && positions.some(other => isQuarryTreasure(other.kind)
                    && Math.hypot(x - other.x, y - other.y) < 90)) continue;
                // Include the other barrel's hit radius, plus a gap beyond the blast edge.
                if (kind === 'tnt' && positions.some(other => other.kind === 'tnt'
                    && Math.hypot(x - other.x, y - other.y) < TNT_BLAST_RADIUS + Math.max(radius, other.radius) + 25)) continue;
                const candidate = { x, y, radius, kind };
                const hazards = positions.filter(other => isStaticHazard(other.kind));
                if (isStaticHazard(kind)) {
                    hazards.push(candidate);
                    if (positions.some(other => needsAimingGap(other.kind) && findClearAim(other, hazards) === null)) continue;
                } else if (needsAimingGap(kind) && findClearAim(candidate, hazards) === null) continue;
                positions.push(candidate);
                break;
            }
            if (positions.length < index + 1) break;
        }
        if (positions.length === kinds.length) {
            const rocks = positions.filter(p => isStaticHazard(p.kind));
            const deposits = rocks.filter(p => (level.mine !== 'goldBasin' || p.kind === 'largeRock') && p.kind !== 'mediumRock' && p.kind !== 'heavyRock'
                && (p.kind !== 'largeRock' || p.y >= 620)
                && findClearAim(p, rocks.filter(other => other !== p)) !== null);
            if (deposits.length === 0 && level.mine !== 'goldBasin') continue;
            const deposit = deposits.length ? deposits[Math.floor(random() * deposits.length)] : undefined;
            // Swap gems after placement: both carriers share a size and depth range.
            const objects = positions.map(({ x, y, kind }) => new Collectable(scene, x, y,
                kind === 'diamondRat' && random() < 0.25 ? 'rubyRat' : kind, level.ratSpeed, random, deposit?.x === x && deposit?.y === y, level.mine === 'gemHollow'));
            if (level.mine === 'goldBasin') {
                if (hasGemRock) perchLooseGem(objects, random, true, 0, 0, true);
            } else {
                const gemGap = level.mine === 'gemHollow' ? 130 : 0;
                const treasureGap = (level.mine ?? 'quarry') === 'quarry' ? 90 : 0;
                if (hasGemRock) perchLooseGem(objects, random, true, gemGap, treasureGap);
                perchLooseGem(objects, random, false, gemGap, treasureGap);
            }
            return objects;
        }
    }
    throw new Error('Could not generate a complete mining layout.');
}

/** Embed an existing gem in a deep rock, optionally forming the rare combined type. */
export function perchLooseGem(objects: Collectable[], random: () => number, combined = false, gemGap = 0, treasureGap = 0, largeOnly = false): boolean {
    // Keep the entire host rock in the deeper half of the cave.
    const rocks = objects.filter(object => (!object.gemDeposit || largeOnly) && !object.mountedGem && object.y - object.radius >= 580
        && (object.kind === 'mediumRock' || object.kind === 'heavyRock' || object.kind === 'largeRock')
        && (!largeOnly || object.kind === 'largeRock'));
    const gems = objects.filter(object => !object.isMountedGem && (object.kind === 'diamond' || object.kind === 'ruby'));
    // Seeded rotations vary the selected rock and gem without changing retries.
    const rockOffset = Math.floor(random() * rocks.length);
    const gemOffset = Math.floor(random() * gems.length);
    for (let g = 0; g < gems.length; g++) {
        const gem = gems[(g + gemOffset) % gems.length];
        for (let r = 0; r < rocks.length; r++) {
            const rock = rocks[(r + rockOffset) % rocks.length];
            for (const side of [-1, 1]) {
                const target = { x: rock.x + side * rock.radius * 0.62,
                    y: rock.y - rock.radius * 0.65, radius: gem.radius };
                if (target.x - gem.radius < 40 || target.x + gem.radius > WORLD.width - 40 || target.y - gem.radius < 580) continue;
                const others = objects.filter(object => object !== gem && object !== rock);
                if (others.some(other => Math.hypot(target.x - other.x, target.y - other.y) < gem.radius + other.radius + 10)) continue;
                if (gemGap > 0 && others.some(other => (other.kind === 'diamond' || other.kind === 'ruby')
                    && (Math.hypot(target.x - other.x, target.y - other.y) < gemGap
                        || Math.abs(Math.atan2(target.x - WORLD.centerX, target.y - WORLD.pivotY)
                            - Math.atan2(other.x - WORLD.centerX, other.y - WORLD.pivotY)) < 0.045))) continue;
                if (treasureGap > 0 && others.some(other => isQuarryTreasure(other.kind)
                    && Math.hypot(target.x - other.x, target.y - other.y) < treasureGap)) continue;
                const aimObstacles = largeOnly ? [...others.filter(other => isStaticHazard(other.kind)), rock] : [...others, rock];
                if (findExposedGemAim(target, aimObstacles) === null) continue;
                gem.moveTo(target.x, target.y);
                rock.mountGem(gem, random, combined);
                return true;
            }
        }
    }
    return false;
}
