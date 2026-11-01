import { GameObjects, Scene } from 'phaser';
import { resizeWorld, viewportZoom, WORLD } from '../state/World';

type Positioned = GameObjects.GameObject & { x: number; setX(x: number): unknown };

/** Reflow existing scenes without restarting a round or losing shop purchases. */
export function responsiveLayout(scene: Scene, onResize?: (oldWidth: number) => void): void {
    let previousWidth = WORLD.width;
    const entries = scene.children.list.filter(child => !child.getData('responsiveIgnore'))
        .map(child => {
            const item = child as Positioned;
            const anchor = child.getData('responsiveAnchor') as string | undefined;
            return { item, x: item.x, anchor: anchor ?? (item.x < 340 ? 'left'
                : item.x > previousWidth - 340 ? 'right' : 'center'), width: previousWidth };
        });
    const layout = () => {
        const { width, height } = scene.scale.gameSize;
        resizeWorld(width, height);
        scene.cameras.main.setViewport(0, 0, width, height)
            .setZoom(viewportZoom(width, height)).centerOn(WORLD.centerX, WORLD.height / 2);
        if (previousWidth === WORLD.width) return;
        onResize?.(previousWidth);
        for (const { item, x, anchor, width: initialWidth } of entries) {
            if (!item.scene) continue;
            const redraw = item.getData('responsiveRedraw') as (() => void) | undefined;
            if (redraw) redraw();
            else if (anchor === 'right') item.setX(x + WORLD.width - initialWidth);
            else if (anchor === 'center') item.setX(x + (WORLD.width - initialWidth) / 2);
            if (item.getData('responsiveFullWidth') && item instanceof GameObjects.Rectangle)
                item.setSize(WORLD.width, item.height);
        }
        previousWidth = WORLD.width;
    };
    layout();
    scene.scale.on('resize', layout);
    scene.events.once('shutdown', () => scene.scale.off('resize', layout));
}
