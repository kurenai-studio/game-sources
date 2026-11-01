package dev.meowpow.boxbot.render;

import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.Shelf;
import dev.meowpow.boxbot.engine.robot.JobType;
import dev.meowpow.boxbot.engine.spatial.InterpolatedFacing;
import dev.meowpow.boxbot.engine.spatial.InterpolatedPosition;
import dev.meowpow.boxbot.engine.spatial.grid.Footprint;
import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.engine.time.Alpha;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.assets.BakedFont;
import dev.meowpow.boxbot.render.assets.EntitySprite;
import dev.meowpow.boxbot.render.assets.EntitySprites;

import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.utils.Disposable;

/**
 * Draws the simulation's dynamic
 * entities onto the screen each frame.
 */
@HotPath
public final class EntityRenderer implements Disposable {

    private final TileSize tileSize;
    private final EntitySprites sprites;
    private final BakedFont shelfLabelFont;
    private final BakedFont loadingBayLabelFont;

    private final SpriteBatch batch = new SpriteBatch();
    private final GlyphLayout layout = new GlyphLayout();

    private final InterpolatedPosition robotPosition = new InterpolatedPosition();
    private final InterpolatedFacing robotFacing = new InterpolatedFacing();

    /**
     * Creates a renderer that draws entities at the given tile size.
     *
     * @param tileSize the map's tile size, in pixels
     * @param sprites the entity sprites to draw with
     * @param shelfLabelFont the font used to label empty shelves
     * @param loadingBayLabelFont the font used to label the loading bay
     */
    public EntityRenderer(
            TileSize tileSize,
            EntitySprites sprites,
            BakedFont shelfLabelFont,
            BakedFont loadingBayLabelFont
    ) {
        this.tileSize = tileSize;
        this.sprites = sprites;
        this.shelfLabelFont = shelfLabelFont;
        this.loadingBayLabelFont = loadingBayLabelFont;
    }

    /**
     * Draws one frame of the world's entities using the given camera.
     *
     * @param camera the camera whose view the batch renders into
     * @param world the simulation state to render
     * @param alpha the interpolation fraction between previous and current simulation tick
     * @param delta elapsed time since the last frame, in seconds
     */
    public void render(Camera camera, World world, Alpha alpha, float delta) {
        batch.setProjectionMatrix(camera.combined);
        batch.begin();

        drawLabel(loadingBayLabelFont.font(), "Loading Bay", world.loadingBay().footprint());

        float centerX = world.chargingStation().footprint().centerX(tileSize);
        float centerY = world.chargingStation().footprint().centerY(tileSize);

        draw(sprites.chargingStation(), centerX, centerY);

        var incomingPackages = world.loadingBay().incomingPackagePlacements();
        for (int i = 0; i < incomingPackages.size(); i++) {
            var placement = incomingPackages.get(i);
            draw(sprites.packageIncoming(placement.pkg().color()),
                    centerX(placement.position().x()),
                    centerY(placement.position().y())
            );
        }
        var outgoingPackages = world.loadingBay().outgoingPackagePlacements();
        for (int i = 0; i < outgoingPackages.size(); i++) {
            var placement = outgoingPackages.get(i);
            var sprite = sprites.packageOutgoing(placement.pkg().color());
            var spriteX = centerX(placement.position().x());
            var spriteY = centerY(placement.position().y());

            draw(sprite, spriteX, spriteY);
        }
        var shelves = world.shelves();
        for (int i = 0; i < shelves.size(); i++) {
            Shelf shelf = shelves.get(i);
            var occupyingPackage = shelf.occupyingPackage();
            if (occupyingPackage != null) {
                var sprite = sprites.pkg(occupyingPackage.color());
                var spriteX = centerX(shelf.position().x());
                var spriteY = centerY(shelf.position().y());

                draw(sprite, spriteX, spriteY);
            }
            else {
                var font = shelfLabelFont.font();
                var shelfX = shelf.position().x();
                var shelfY = shelf.position().y();

                drawLabel(font, shelf.label(), shelfX, shelfY);
            }
        }
        var robot = world.robot();

        robotPosition.set(robot.previousPosition(), robot.position(), alpha);
        robotFacing.set(robot.previousFacing(), robot.facing(), alpha);

        float robotCenterX = robotPosition.centerX(tileSize);
        float robotCenterY = robotPosition.centerY(tileSize);
        float robotRotation = robotFacing.degrees();

        var robotAnimation = sprites.robotAnimation();
        robotAnimation.setAction(robot.action());
        robotAnimation.update(delta);

        draw(robotAnimation.frame(), robotCenterX, robotCenterY, robotRotation);

        var carriedPackage = robot.carriedPackage();
        if (carriedPackage != null) {
            var outgoing = sprites.packageOutgoing(carriedPackage.color());
            var incoming = sprites.packageIncoming(carriedPackage.color());
            var sprite = world.carriedJobType() == JobType.RETRIEVAL ? outgoing : incoming;

            draw(sprite, robotCenterX, robotCenterY, robotRotation);
        }
        batch.end();
    }

    private void draw(EntitySprite sprite, float centerX, float centerY) {
        draw(sprite, centerX, centerY, 0f);
    }

    /**
     * <strong>Implementation Note:</strong>
     * Snap draw position to the nearest whole pixel
     * so {@code Nearest-filtered} sampling stays
     * aligned to the same texel grid every frame
     */
    private void draw(EntitySprite sprite, float centerX, float centerY, float rotation) {
        float size = sprite.size();
        float origin = size / 2f;

        float x = Math.round(centerX - origin);
        float y = Math.round(centerY - origin);
        float scaleX = 1f, scaleY = 1f;

        batch.draw(sprite.region(), x, y, origin, origin, size, size, scaleX, scaleY, rotation);
    }

    private float centerX(int tileX) {
        return (tileX + 0.5f) * tileSize.pixels();
    }

    private float centerY(int tileY) {
        return (tileY + 0.5f) * tileSize.pixels();
    }

    private void drawLabel(BitmapFont font, String text, Footprint footprint) {
        layout.setText(font, text);

        float x = footprint.centerX(tileSize) - layout.width / 2f;
        float y = footprint.centerY(tileSize) + layout.height / 2f;

        font.draw(batch, layout, x, y);
    }

    private void drawLabel(BitmapFont font, String text, int tileX, int tileY) {
        layout.setText(font, text);

        float x = centerX(tileX) - layout.width / 2f;
        float y = centerY(tileY) + layout.height / 2f;

        font.draw(batch, layout, x, y);
    }

    @Override
    public void dispose() {
        batch.dispose();
    }
}
