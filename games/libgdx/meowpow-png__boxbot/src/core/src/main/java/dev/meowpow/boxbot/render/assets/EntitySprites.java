package dev.meowpow.boxbot.render.assets;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.robot.RobotAnimationController;

import com.badlogic.gdx.graphics.g2d.TextureAtlas;

import java.util.Objects;

/**
 * Owns and provides the sprite assets
 * used to render the simulation's entities.
 */
public final class EntitySprites {

    private final RobotAnimationController robotAnimation;
    private final EntitySprite chargingStationSprite;

    private final PackageSpriteSet restingSprites;
    private final PackageSpriteSet incomingSprites;
    private final PackageSpriteSet outgoingSprites;

    /**
     * Loads all sprite assets needed to render the simulation.
     */
    public EntitySprites(TextureAtlas atlas) {
        robotAnimation = new RobotAnimationController(atlas);
        chargingStationSprite = atlasSprite(atlas, "power", 0.5f);
        restingSprites = PackageSpriteSet.load(atlas, "package");
        incomingSprites = PackageSpriteSet.load(atlas, "package-inbound");
        outgoingSprites = PackageSpriteSet.load(atlas, "package-outbound");
    }

    /**
     * Returns the robot's animation controller.
     */
    public RobotAnimationController robotAnimation() {
        return robotAnimation;
    }

    /**
     * Returns the charging station's sprite.
     */
    public EntitySprite chargingStation() {
        return chargingStationSprite;
    }

    /**
     * Returns the sprite for a package
     * resting on a shelf, in the given color.
     *
     * @param color the package's color
     */
    public EntitySprite pkg(PackageColor color) {
        return restingSprites.get(color);
    }

    /**
     * Returns the sprite for a package
     * inbound to storage, in the given color.
     *
     * @param color the package's color
     */
    public EntitySprite packageIncoming(PackageColor color) {
        return incomingSprites.get(color);
    }

    /**
     * Returns the sprite for a package
     * outbound for shipment, in the given color.
     *
     * @param color the package's color
     */
    public EntitySprite packageOutgoing(PackageColor color) {
        return outgoingSprites.get(color);
    }

    static EntitySprite atlasSprite(TextureAtlas atlas, String name, float sizeRatio) {
        var region = Objects.requireNonNull(atlas.findRegion(name), "no atlas region: " + name);
        return new EntitySprite(region, sizeRatio);
    }
}
