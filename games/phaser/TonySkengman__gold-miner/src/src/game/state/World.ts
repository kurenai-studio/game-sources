/** A fixed logical height preserves precision; the mine width follows the viewport. */
export const WORLD = {
    width: 1440,
    height: 960,
    get centerX(): number { return this.width / 2; },
    pivotY: 210,
    get sideReach(): number { return this.centerX - 24; },
    groundY: 248,
    floorY: 910,
    footerY: 937,
    get clawRange(): number { return Math.hypot(this.sideReach, this.floorY - this.pivotY) + 20; },
    get spawnRange(): number { return this.clawRange - 5; },
    get maxAngle(): number { return Math.min(1.45, Math.atan2(this.centerX - 65, 110)); }
};

export function viewportZoom(width: number, height: number): number {
    return Math.min(height / WORLD.height, width / 1024);
}

export function resizeWorld(width: number, height: number): void {
    WORLD.width = width / viewportZoom(width, height);
}
