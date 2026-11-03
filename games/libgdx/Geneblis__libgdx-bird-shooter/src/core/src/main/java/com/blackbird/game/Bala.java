package com.blackbird.game;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;

public class Bala {
    private float x;
    private float y;
    private final float angle;
    private final float size;
    private final float speed;
    private final Texture projectileTexture;
    private final Sprite projectileSprite;

    // Construtor da bala
    public Bala(float x, float y, float angle, float size, float speed) {
        this.x = x;
        this.y = y;
        this.angle = angle;
        this.size = size;
        this.speed = speed;
        projectileTexture = new Texture("projectile.png");
        projectileSprite = new Sprite(projectileTexture);
        projectileSprite.setSize(size, size);
        projectileSprite.setOrigin(size / 2, size / 2);
        projectileSprite.setRotation(angle);
    }

    public static Bala atirar(float playerX, float playerY, float angle, float offset, float size, float speed) {
        float posicao_da_bala_X = playerX + (float) Math.cos(Math.toRadians(angle)) * offset;
        float posicao_da_bala_Y = playerY + (float) Math.sin(Math.toRadians(angle)) * offset;
        return new Bala(posicao_da_bala_X, posicao_da_bala_Y, angle, size, speed);
    }

    public void update() {
        x += Math.cos(Math.toRadians(angle)) * speed;
        y += Math.sin(Math.toRadians(angle)) * speed;
        projectileSprite.setPosition(x, y);
    }

    public void draw(SpriteBatch batch) {
        projectileSprite.draw(batch);
    }

    public boolean check(float width, float height) {
        return x >= 0 && x <= width && y >= 0 && y <= height;
    }

    public Rectangle getBounds() {// Retângulo delimitador da bala
        return new Rectangle(x, y, size, size);
    }

    public void dispose() {
        projectileTexture.dispose();
    }
}