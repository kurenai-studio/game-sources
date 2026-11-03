package com.blackbird.game;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Vector2;

@SuppressWarnings("unused")
public class Enemy {
    private float x;
    private float y;
    private final Texture enemyTexture;
    private final Sprite enemySprite;
    private boolean isAlive;
    private final float speed = 2.5f; // Velocidade do inimigo
    private Main main; // Referência à classe Main

    public Enemy(float x, float y, Main main) {
        this.x = x;
        this.y = y;
        this.isAlive = true;
        this.main = main; // Armazena a referência
        enemyTexture = new Texture("blackbird.png"); // Use o sprite correto
        enemySprite = new Sprite(enemyTexture);
        enemySprite.setSize(50, 50);
        enemySprite.setPosition(x, y);
    }

    public void update(Player player) {
        if (isAlive) {
            // Lógica de movimento do inimigo
            Vector2 direction = new Vector2(player.getX() - x, player.getY() - y).nor();
            x += direction.x * speed;
            y += direction.y * speed;
            enemySprite.setPosition(x, y);
        }
    }

    public void draw(SpriteBatch batch) {
        if (isAlive) {
            enemySprite.draw(batch);
        }
    }

    public boolean checkCollision(Bala bala) {
        return isAlive && bala.getBounds().overlaps(enemySprite.getBoundingRectangle());
    }

    public boolean checkPlayerCollision(Player player) {
        return isAlive && player.getBounds().overlaps(enemySprite.getBoundingRectangle());
    }

    public void hit(Main main) {
        isAlive = false;
        main.addScore(100); // Adiciona 100 pontos ao jogador
    }

    public boolean isAlive() {
        return isAlive;
    }

    public float getX() {
        return x;
    }

    public float getY() {
        return y;
    }

    public void dispose() {
        enemyTexture.dispose();
    }
}
