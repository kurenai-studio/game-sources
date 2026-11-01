import { type MineKind } from '../state/Mines';
import { responsiveLayout } from '../ui/ResponsiveLayout';
import { WORLD } from '../state/World';
import type { Result } from './GameOver';
import { addSoundButton, soundEffects } from '../audio/SoundEffects';
import { drawShop, drawShopProduct, drawShopkeeper } from '../art/drawShop';
import { Scene } from 'phaser';
import { emptyBonuses, isPermanentUpgrade, itemSoldOut, emptyUpgrades, purchaseUpgrade, upgradePrice, UPGRADE_INFO, UPGRADE_LIMIT, ShopItemKind, Upgrades, LevelBonuses } from '../state/Upgrades';

export class UpgradeShop extends Scene {
    constructor() { super('UpgradeShop'); }

    create(data: { lives: number; level: number; money: number; upgrades?: Upgrades; dynamite: number; bonuses?: LevelBonuses; levelSeed?: number; failed?: boolean; mine?: MineKind; result?: Result }): void {
        let bonuses = { ...emptyBonuses(), ...data.bonuses };
        let money = data.money;
        let lives = data.lives;
        let dynamite = data.dynamite;
        let upgrades = { ...emptyUpgrades(), ...data.upgrades };
        let hovered: ShopItemKind | null = null;
        let confirmingForfeit = false;
        let leaving = false;
        drawShop(this, false);
        addSoundButton(this, 32, 16);
        this.add.text(WORLD.centerX, 46, data.failed ? `LEVEL ${data.level} FAILED — RESTOCK & RETRY` : data.result?.finalLevel ? 'ALL LEVELS CLEARED!' : `LEVEL ${data.level - 1} CLEARED!`, { fontFamily: 'Arial', fontSize: 34, fontStyle: 'bold', color: '#483126' }).setOrigin(0.5);
        const shopWidth = WORLD.width - 80;
        const vendorWidth = Math.min(360, Math.max(240, WORLD.width * 0.25));
        const productsLeft = vendorWidth + 56;
        const productsWidth = WORLD.width - productsLeft - 40;
        const panelLeft = productsLeft - 8;
        const panelWidth = productsWidth + 16;
        const panelCenter = panelLeft + panelWidth / 2;
        this.add.rectangle(28 + vendorWidth / 2, 490, vendorWidth, 600, 0x302b25, 0.97)
            .setStrokeStyle(3, 0xa77d48).setData('responsiveAnchor', 'left');
        this.add.rectangle(panelCenter, 460, panelWidth, 660, 0x513b2a, 0.96)
            .setStrokeStyle(3, 0xc29659).setData('responsiveAnchor', 'center');
        this.add.rectangle(panelCenter, 850, panelWidth, 100, 0xffedbb).setStrokeStyle(3, 0xc29659).setData('responsiveAnchor', 'center');
        const descriptionTitle = this.add.text(productsLeft + 12, 811, '', { fontFamily: 'Arial', fontSize: 25, fontStyle: 'bold', color: '#483126' }).setData('responsiveAnchor', 'center');
        const description = this.add.text(productsLeft + 12, 844, '', { fontFamily: 'Arial', fontSize: 20, color: '#70452a', wordWrap: { width: Math.max(160, productsWidth - 590) } }).setData('responsiveAnchor', 'center');
        const moneyX = productsLeft + productsWidth - 138;
        this.add.rectangle(moneyX, 850, 268, 76, 0x263e2c)
            .setStrokeStyle(2, 0xcbb26b).setData('responsiveAnchor', 'center');
        const bill = this.add.graphics().setPosition(moneyX - 91, 854).setData('responsiveAnchor', 'center');
        bill.fillStyle(0x80af76).fillRoundedRect(-30, -19, 60, 38, 4);
        bill.lineStyle(2, 0xd4e5a4).strokeRoundedRect(-25, -14, 50, 28, 3);
        bill.fillStyle(0xb8d394).fillEllipse(0, 0, 22, 27);
        this.add.text(moneyX - 91, 854, '$', { fontFamily: 'Arial', fontSize: 23, fontStyle: 'bold', color: '#315538' })
            .setOrigin(0.5).setData('responsiveAnchor', 'center');
        this.add.text(moneyX + 30, 820, 'YOUR MONEY', { fontFamily: 'Arial', fontSize: 14, fontStyle: 'bold', color: '#d9d5ab' })
            .setOrigin(0.5, 0).setData('responsiveAnchor', 'center');
        const balance = this.add.text(moneyX + 30, 858, '', { fontFamily: 'Arial', fontSize: 33, fontStyle: 'bold', color: '#fff1af' })
            .setOrigin(0.5).setData('responsiveAnchor', 'center');
        const vendorX = 28 + vendorWidth / 2;
        const vendorStates = (['neutral', 'happy', 'sad'] as const).map(emotion =>
            drawShopkeeper(this, vendorX, 480, Math.min(1.65, (vendorWidth - 24) / 180), emotion).setData('responsiveAnchor', 'left').setVisible(emotion === 'neutral'));
        // Foreground counter hides the lower body while leaving the face and apron visible.
        const counter = this.add.graphics().setPosition(vendorX, 590).setData('responsiveAnchor', 'left');
        const counterWidth = vendorWidth - 20;
        counter.fillStyle(0x171510, 0.4).fillRoundedRect(-counterWidth / 2 + 4, 10, counterWidth, 126, 5);
        counter.fillStyle(0x795332).fillRect(-counterWidth / 2 + 5, 10, counterWidth - 10, 113);
        counter.lineStyle(2, 0x543923);
        for (let plank = 1; plank < 5; plank++) {
            const plankX = -counterWidth / 2 + plank * counterWidth / 5;
            counter.lineBetween(plankX, 15, plankX, 120);
        }
        counter.fillStyle(0x493323).fillRect(-counterWidth / 2 + 5, 112, counterWidth - 10, 12);
        counter.fillStyle(0x453020).fillRoundedRect(-counterWidth / 2 - 4, -6, counterWidth + 8, 22, 4);
        counter.fillStyle(0xb88b53).fillRoundedRect(-counterWidth / 2 - 4, -10, counterWidth + 8, 10, 3);
        counter.lineStyle(2, 0xd2aa70).lineBetween(-counterWidth / 2, -8, counterWidth / 2, -8);
        counter.lineStyle(1, 0x9e7041).lineBetween(-counterWidth / 2 + 18, 36, -counterWidth / 2 + 43, 36)
            .lineBetween(20, 83, 49, 83);
        for (const boltX of [-counterWidth / 2 + 15, counterWidth / 2 - 15]) {
            counter.fillStyle(0x382b20).fillCircle(boltX, 26, 3).fillCircle(boltX, 103, 3);
        }
        const vendorSpeech = this.add.text(vendorX, 242, 'Welcome, miner!', {
            fontFamily: 'Arial', fontSize: 22, fontStyle: 'bold', color: '#ffe5ac', backgroundColor: '#513b2a',
            padding: { x: 12, y: 10 }, align: 'center', wordWrap: { width: 210 }
        }).setOrigin(0.5).setData('responsiveAnchor', 'left');
        this.add.text(vendorX, 740, 'OLD BILL', { fontFamily: 'Arial', fontSize: 25, fontStyle: 'bold', color: '#ffe5ac', backgroundColor: '#513b2a', padding: { x: 20, y: 8 } })
            .setOrigin(0.5).setData('responsiveAnchor', 'left');
        let boughtSomething = false;
        let reactionTimer: Phaser.Time.TimerEvent | undefined;
        const react = (emotion: 'happy' | 'sad') => {
            reactionTimer?.remove();
            this.tweens.killTweensOf(vendorStates);
            vendorStates.forEach(vendor => vendor.setY(480).setAlpha(1));
            vendorStates.forEach((vendor, index) => vendor.setVisible(index === (emotion === 'happy' ? 1 : 2)));
            vendorSpeech.setText(emotion === 'happy' ? 'Much obliged, miner!' : 'Maybe next time…');
            if (emotion === 'happy') {
                this.tweens.add({ targets: vendorStates[1], y: 468, duration: 170, ease: 'Sine.Out', yoyo: true, hold: 45, repeat: 1, repeatDelay: 70 });
                reactionTimer = this.time.delayedCall(1500, () => {
                    vendorStates.forEach((vendor, index) => vendor.setVisible(index === 0));
                    vendorSpeech.setText('Fine supplies here!');
                });
            }
        };
        const depart = (go: () => void) => {
            if (!boughtSomething) {
                react('sad');
                this.time.delayedCall(850, go);
            } else go();
        };
        const showDescription = () => {
            if (!hovered) {
                descriptionTitle.setText('“Take a look at my wares!”');
                description.setText('Click an item to buy. One consumable charge is used per round; extra purchases cover future rounds.');
                return;
            }
            const info = UPGRADE_INFO[hovered];
            const maxed = itemSoldOut(hovered, upgrades, lives);
            const price = upgradePrice(hovered, upgrades);
            descriptionTitle.setText(info.name);
            description.setText(`${info.description}. ${maxed ? (isPermanentUpgrade(hovered) ? 'Fully upgraded!' : 'Lives full (5 / 5)!') : `${isPermanentUpgrade(hovered) ? 'Next tier' : 'Price'}: $${price}.${money < price ? ' Not enough money.' : ''}`}`);
        };
        this.add.rectangle(WORLD.centerX, 106, shopWidth, 46, 0x513b2a, 0.92)
            .setStrokeStyle(3, 0xc29659).setData('responsiveAnchor', 'center');
        const stock = this.add.text(WORLD.centerX, 106, '', { fontFamily: 'Arial', fontSize: 22, color: '#ffe5ac', align: 'center' }).setOrigin(0.5).setData('responsiveAnchor', 'center');
        const category = (x: number, y: number, width: number, title: string, subtitle: string) => {
            this.add.rectangle(x + width / 2, y + 28, width, 62, 0x513b2a, 0.96)
                .setStrokeStyle(3, 0xc29659).setData('responsiveAnchor', 'center');
            this.add.text(x + 12, y + 1, title, { fontFamily: 'Arial', fontSize: 23, fontStyle: 'bold', color: '#ffe5ac' }).setData('responsiveAnchor', 'center');
            this.add.text(x + 12, y + 29, subtitle, { fontFamily: 'Arial', fontSize: 17, color: '#d9bc8c' }).setData('responsiveAnchor', 'center');
        };
        category(productsLeft + 8, 139, productsWidth - 16, 'CONSUMABLES', 'One charge per round • Stock up for future levels');
        const bottomStep = productsWidth / 5;
        category(productsLeft + 8, 570, bottomStep * 3 - 16, 'PERMANENT UPGRADES', 'Keep every tier for the rest of this run');
        category(productsLeft + bottomStep * 3 + 8, 570, bottomStep * 2 - 16, 'SUPPLIES', 'Restore lives • Carry dynamite forward');
        const refreshers: (() => void)[] = [];
        const refresh = () => {
            const roundStock = Object.values(bonuses).reduce((total, count) => total + count, 0);
            stock.setText(`LIVES  ${lives} / 5     •     DYNAMITE  ${dynamite}     •     ROUND ITEMS  ${roundStock}     •     UPGRADE TIERS  ${upgrades.strength + upgrades.diamonds + upgrades.vialBelt} / 9`);
            balance.setText(`$${money.toLocaleString('en-US')}`);
            next.setText(data.result?.won && data.result.finalLevel ? 'VIEW RESULTS'
                : lives === 0 ? 'END RUN' : `${data.failed ? 'RETRY' : 'START'} LEVEL ${data.level}`);
            refreshers.forEach(update => update());
            showDescription();
        };
        const shopOrder: ShopItemKind[] = [
            // One-round consumables.
            'strengthPotion', 'goldRush', 'streakVial', 'extraTime',
            'luck', 'lightweightGrip', 'prospectorsLens',
            // Upgrades that last for the run.
            'strength', 'diamonds', 'vialBelt',
            // Immediate recovery and carried supplies.
            'lifeVial', 'dynamite'
        ];
        shopOrder.forEach((kind, index) => {
            const consumable = index < 7;
            const step = productsWidth / (consumable ? 4 : 5);
            const x = productsLeft + step / 2 + (consumable ? index % 4 : index - 7) * step;
            const y = consumable ? 290 + Math.floor(index / 4) * 185 : 711;
            const cardWidth = step - 16;
            const cardHeight = consumable ? 170 : 150;
            const permanent = isPermanentUpgrade(kind);
            this.add.rectangle(x + 3, y + 5, cardWidth, cardHeight, 0x302217, 0.35).setData('responsiveAnchor', 'center');
            const card = this.add.rectangle(x, y, cardWidth, cardHeight, permanent ? 0xe5d8ae : 0xf4dcaa)
                .setStrokeStyle(2, permanent ? 0x8c9a69 : 0xc29659).setData('responsiveAnchor', 'center').setInteractive({ useHandCursor: true });
            this.add.rectangle(x, y - cardHeight / 2 + 4, cardWidth - 8, 3, permanent ? 0x758956 : 0xcc9854).setData('responsiveAnchor', 'center');
            drawShopProduct(this, x, y - 9, kind, consumable ? 0.58 : 0.45).setData('responsiveAnchor', 'center');
            this.add.text(x, y - cardHeight / 2 + 12, UPGRADE_INFO[kind].name, { fontFamily: 'Arial', fontSize: Math.min(consumable ? 24 : 22, (cardWidth - 12) / 7), fontStyle: 'bold', color: '#483126', align: 'center', wordWrap: { width: cardWidth - 12 } }).setOrigin(0.5, 0).setData('responsiveAnchor', 'center');
            const tier = this.add.text(x, y + (consumable ? 34 : 29), '', { fontFamily: 'Arial', fontSize: 20, color: '#70452a' }).setOrigin(0.5).setData('responsiveAnchor', 'center');
            const priceTag = this.add.text(x, y + (consumable ? 62 : 56), '', { fontFamily: 'Arial', fontSize: 22, fontStyle: 'bold', color: '#ffffff', padding: { x: 14, y: 4 } }).setOrigin(0.5).setData('responsiveAnchor', 'center');
            refreshers.push(() => {
                const maxed = itemSoldOut(kind, upgrades, lives);
                const price = upgradePrice(kind, upgrades);
                tier.setText(isPermanentUpgrade(kind) ? `TIER ${upgrades[kind]} / ${UPGRADE_LIMIT}`
                    : kind === 'lifeVial' ? `LIVES: ${lives} / 5` : kind === 'dynamite' ? `OWNED: ${dynamite}` : `ROUNDS: ${bonuses[kind]}`);
                priceTag.setText(maxed ? (isPermanentUpgrade(kind) ? 'MAXED' : 'FULL') : `BUY $${price}`);
                priceTag.setBackgroundColor(maxed || money < price ? '#827968' : '#547f3b');
            });
            card.on('pointerover', () => {
                hovered = kind;
                card.setStrokeStyle(4, 0xfff3cc);
                showDescription();
            });
            card.on('pointerout', () => {
                hovered = null;
                card.setStrokeStyle(2, permanent ? 0x8c9a69 : 0xc29659);
                showDescription();
            });
            card.on('pointerdown', () => {
                if (confirmingForfeit || leaving) return;
                hovered = kind;
                const purchase = purchaseUpgrade(kind, money, upgrades, dynamite, bonuses, lives);
                if (purchase) {
                    boughtSomething = true;
                    react('happy');
                    soundEffects.unlock();
                    soundEffects.play('buy');
                    lives = purchase.lives;
                    bonuses = purchase.bonuses;
                    dynamite = purchase.dynamite;
                    money = purchase.money;
                    upgrades = purchase.upgrades;
                }
                refresh();
            });
        });
        const next = this.add.text(moneyX - 290, 850, `START LEVEL ${data.level}`, { fontFamily: 'Arial', fontSize: 24, fontStyle: 'bold', color: '#ffffff', backgroundColor: '#547f3b', padding: { x: 28, y: 10 } }).setOrigin(0.5).setData('responsiveAnchor', 'center').setInteractive({ useHandCursor: true });
        next.on('pointerdown', () => {
            if (confirmingForfeit || leaving) return;
            leaving = true;
            depart(() => {
            if (data.result && (lives === 0 || (data.result.won && data.result.finalLevel))) {
                this.scene.start('GameOver', { ...data.result, lives, money, upgrades, dynamite });
                return;
            }
            this.scene.start('LevelBriefing', {
                lives, mine: data.mine, level: data.level, money, upgrades, dynamite, bonuses, levelSeed: data.levelSeed
            });
            });
        });
        const forfeit = this.add.text(vendorX, 875, 'FORFEIT RUN', {
            fontFamily: 'Arial', fontSize: 22, color: '#ffffff', backgroundColor: '#8e493c', padding: { x: 24, y: 12 }
        }).setOrigin(0.5).setData('responsiveAnchor', 'left').setInteractive({ useHandCursor: true });
        const shade = this.add.rectangle(WORLD.centerX, 480, WORLD.width, WORLD.height, 0x11151a, 0.82)
            .setData('responsiveFullWidth', true).setData('responsiveAnchor', 'center').setInteractive();
        const panel = this.add.rectangle(WORLD.centerX, 480, 680, 300, 0xffedbb)
            .setStrokeStyle(4, 0xc29659).setData('responsiveAnchor', 'center');
        const heading = this.add.text(WORLD.centerX, 393, 'FORFEIT THIS RUN?', {
            fontFamily: 'Arial', fontSize: 32, fontStyle: 'bold', color: '#70452a'
        }).setOrigin(0.5).setData('responsiveAnchor', 'center');
        const warning = this.add.text(WORLD.centerX, 468, 'Your progress in this run will be lost.\nReturn to the main menu?', {
            fontFamily: 'Arial', fontSize: 22, color: '#483126', align: 'center', lineSpacing: 10
        }).setOrigin(0.5).setData('responsiveAnchor', 'center');
        const cancel = this.add.text(WORLD.centerX - 150, 563, 'KEEP PLAYING', {
            fontFamily: 'Arial', fontSize: 22, color: '#ffffff', backgroundColor: '#547f3b', padding: { x: 20, y: 14 }
        }).setOrigin(0.5).setData('responsiveAnchor', 'center').setInteractive({ useHandCursor: true });
        const confirm = this.add.text(WORLD.centerX + 150, 563, 'FORFEIT RUN', {
            fontFamily: 'Arial', fontSize: 22, color: '#ffffff', backgroundColor: '#8e493c', padding: { x: 20, y: 14 }
        }).setOrigin(0.5).setData('responsiveAnchor', 'center').setInteractive({ useHandCursor: true });
        const confirmation = [shade, panel, heading, warning, cancel, confirm];
        confirmation.forEach((item, index) => item.setDepth(100 + index).setVisible(false));
        const showConfirmation = (visible: boolean) => {
            confirmingForfeit = visible;
            confirmation.forEach(item => item.setVisible(visible));
        };
        forfeit.on('pointerdown', () => {
            if (!leaving) showConfirmation(true);
        });
        const keepPlaying = () => {
            if (!leaving) showConfirmation(false);
        };
        cancel.on('pointerdown', keepPlaying);
        confirm.on('pointerdown', () => {
            if (!confirmingForfeit || leaving) return;
            leaving = true;
            showConfirmation(false);
            depart(() => this.scene.start('MainMenu'));
        });
        this.input.keyboard?.on('keydown-ESC', keepPlaying);
        this.events.once('shutdown', () => this.input.keyboard?.off('keydown-ESC', keepPlaying));

        refresh();
        responsiveLayout(this);
    }
}
