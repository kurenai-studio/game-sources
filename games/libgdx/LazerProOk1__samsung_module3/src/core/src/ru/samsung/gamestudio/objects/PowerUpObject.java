package ru.samsung.gamestudio.objects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.physics.box2d.Filter;
import com.badlogic.gdx.physics.box2d.World;
import ru.samsung.gamestudio.GameSettings;
import ru.samsung.gamestudio.PowerUpType;

import java.util.Random;

public class PowerUpObject extends GameObject {

    private static final int POWERUP_SIZE = 64;
    private static final int paddingHorizontal = 30;

    private boolean wasCollected;
    private final PowerUpType type;

    public PowerUpObject(PowerUpType type, World world) {
        super(
                createCircleTexture(type),
                paddingHorizontal + POWERUP_SIZE / 2 + new Random().nextInt(
                        GameSettings.SCREEN_WIDTH - 2 * paddingHorizontal - POWERUP_SIZE),
                GameSettings.SCREEN_HEIGHT + POWERUP_SIZE / 2,
                POWERUP_SIZE, POWERUP_SIZE,
                GameSettings.POWERUP_BIT,
                world
        );
        this.type = type;
        this.wasCollected = false;
        body.setLinearVelocity(new Vector2(0, -GameSettings.TRASH_VELOCITY * 0.75f));

        Filter filter = new Filter();
        filter.categoryBits = GameSettings.POWERUP_BIT;
        filter.maskBits = GameSettings.SHIP_BIT;
        body.getFixtureList().get(0).setFilterData(filter);
    }

    private static Texture createCircleTexture(PowerUpType type) {
        int s = POWERUP_SIZE;
        Pixmap pixmap = new Pixmap(s, s, Pixmap.Format.RGBA8888);
        pixmap.setColor(fillColorFor(type));
        pixmap.fillCircle(s / 2, s / 2, s / 2 - 2);
        pixmap.setColor(Color.WHITE);
        pixmap.drawCircle(s / 2, s / 2, s / 2 - 2);
        Texture t = new Texture(pixmap);
        pixmap.dispose();
        return t;
    }

    private static Color fillColorFor(PowerUpType type) {
        if (type == PowerUpType.SHIELD)      return new Color(0.15f, 0.45f, 1.00f, 1f);
        if (type == PowerUpType.DOUBLE_SHOT) return new Color(1.00f, 0.75f, 0.00f, 1f);
        return new Color(1.00f, 0.20f, 0.10f, 1f);
    }

    public PowerUpType getType()      { return type; }
    public boolean wasCollected()     { return wasCollected; }
    public boolean hasToBeDestroyed() { return wasCollected || getY() + height / 2 < 0; }

    @Override
    public void hit() {
        wasCollected = true;
    }
}
