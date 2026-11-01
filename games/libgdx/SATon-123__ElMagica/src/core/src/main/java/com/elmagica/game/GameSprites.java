package com.elmagica.game;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.MathUtils;

public class GameSprites {
    private final SpriteFiles files = new SpriteFiles();
    private final TextureRegion shooterPicture;
    private final TextureRegion snakePicture;
    private final TextureRegion[] pictures = new TextureRegion[8];

    public GameSprites() {
        String[] names = {"characters/player/mage", "characters/enemies/slime",
            "characters/bosses/fire-water", "characters/bosses/fire-earth", "characters/bosses/fire-air",
            "characters/bosses/water-earth", "characters/bosses/water-air", "characters/bosses/earth-air"};
        for (int i = 0; i < names.length; i++) pictures[i] = files.load(names[i]);
        shooterPicture = files.load("characters/enemies/shooter");
        snakePicture = files.load("characters/enemies/snake");
    }

    public void drawMage(SpriteBatch batch, ElementType element, float x, float y, float size) {
        // Спрайт мага один, цвет берём от стихии.
        draw(batch, pictures[0], element.color, x, y, size);
    }

    public void drawEnemy(SpriteBatch batch, Enemy enemy) {
        if (enemy.isBoss()) {
            drawBoss(batch, enemy);
        } else {
            float time = enemy.getAnimationTime();
            float hop = enemy.isMoving() ? Math.abs(MathUtils.sin(time * 9)) * 8 : 0;
            if (enemy.isJumping()) hop += 10;
            float stretch = enemy.isMoving() ? MathUtils.sin(time * 9) * 0.12f : MathUtils.sin(time * 3) * 0.03f;
            TextureRegion picture = pictures[1];
            float turn = 0;
            if (enemy.isShooter()) {
                picture = shooterPicture;
                hop *= 0.4f;
                stretch *= 0.35f;
                float cast = enemy.shooterCombat.getCastTimer() / Player.CAST_TIME;
                if (cast > 0) {
                    turn = -MathUtils.cosDeg(enemy.shooterCombat.getAngle()) * 12 * cast;
                    stretch = -0.1f * cast;
                    hop += 3 * cast;
                }
            }
            if (enemy.isSnake()) {
                picture = snakePicture;
                hop = 0;
                turn = enemy.isMoving() ? MathUtils.sin(time * 10) * 5 : 0;
                stretch = 0;
                if (enemy.snakeCombat.isDashing()) {
                    turn = -MathUtils.cosDeg(enemy.snakeCombat.getAngle()) * 9;
                    stretch = -0.12f;
                }
            }
            Color color = enemy.getHurtTimer() > 0 ? new Color(enemy.element.color).lerp(Color.WHITE, 0.7f) : enemy.element.color;
            float stretchX = 1 + stretch;
            if (enemy.isSnake() && MathUtils.cosDeg(enemy.snakeCombat.getAngle()) < 0) stretchX *= -1;
            drawPose(batch, picture, color, enemy.x, enemy.y, enemy.getSize(), hop, turn, stretchX, 1 - stretch);
        }
    }

    public void drawMage(SpriteBatch batch, Player player) {
        float time = player.getAnimationTime();
        float lift = player.isMoving() ? Math.abs(MathUtils.sin(time * 14)) * 3 : MathUtils.sin(time * 3) * 1.5f;
        float turn = player.isMoving() ? MathUtils.sin(time * 14) * 3 : 0;
        float stretch = 1;
        if (player.getCastTimer() > 0) {
            float cast = player.getCastTimer() / Player.CAST_TIME;
            turn = -MathUtils.cosDeg(player.aimAngle) * 12 * cast;
            stretch = 1 + 0.1f * cast;
        }
        Color color = player.getHurtTimer() > 0 ? new Color(player.element.color).lerp(Color.WHITE, 0.8f) : player.element.color;
        drawPose(batch, pictures[0], color, player.x, player.y, Player.SIZE, lift, turn, 1, stretch);
    }

    private void drawPose(SpriteBatch batch, TextureRegion picture, Color color, float x, float y,
        float size, float lift, float turn, float stretchX, float stretchY) {
        float scale = size / Math.max(picture.getRegionWidth(), picture.getRegionHeight());
        float width = picture.getRegionWidth() * scale, height = picture.getRegionHeight() * scale;
        batch.setColor(color);
        batch.draw(picture, x + (size - width) / 2, y + lift, width / 2, height / 2,
            width, height, stretchX, stretchY, turn);
        batch.setColor(Color.WHITE);
    }

    private void drawBoss(SpriteBatch batch, Enemy enemy) {
        TextureRegion picture = pictures[bossPicture(enemy.element, enemy.secondElement)];
        float scale = enemy.getSize() / Math.max(picture.getRegionWidth(), picture.getRegionHeight());
        float width = picture.getRegionWidth() * scale;
        float height = picture.getRegionHeight() * scale;
        float time = enemy.getAnimationTime();
        float lift = 0, turn = 0, stretchX = 1, stretchY = 1;
        // Качаем картинку, хитбокс оставляем на месте.
        if (enemy.isMoving()) {
            lift = Math.abs(MathUtils.sin(time * 10)) * 4;
            turn = MathUtils.sin(time * 10) * 3;
        }
        if (enemy.isJumping()) lift = Math.abs(MathUtils.sin(time * 12)) * 14;
        BossAttack attack = enemy.bossCombat.getCurrent();
        if (attack != null) {
            float charge = MathUtils.clamp(attack.getAge() / attack.getWarningTime(), 0, 1);
            if (attack.isWarning()) {
                stretchX = 1 + charge * 0.12f;
                stretchY = 1 - charge * 0.14f;
                turn = MathUtils.sin(time * 35) * charge * 2;
            } else if (attack.element == ElementType.EARTH) {
                float recoil = Math.max(0, 1 - (attack.getAge() - attack.getWarningTime()) / 0.3f);
                stretchX = 1 + recoil * 0.2f;
                stretchY = 1 - recoil * 0.22f;
                lift = recoil * 5;
            } else if (attack.element == ElementType.FIRE || attack.element == ElementType.WATER) {
                float elapsed = attack.getAge() - attack.getWarningTime();
                float recoil = attack.element == ElementType.WATER ? Math.max(0, 1 - elapsed / attack.getDuration())
                    : 0.5f + MathUtils.sin(elapsed * 24) * 0.25f;
                turn = -MathUtils.cosDeg(attack.getAngle()) * 12 * recoil;
                stretchX = 1 - recoil * 0.08f;
                stretchY = 1 + recoil * 0.1f;
            } else {
                turn = MathUtils.sin(time * 15) * 12;
                lift = 8 + MathUtils.sin(time * 10) * 4;
            }
        }
        if (enemy.isEnraged()) batch.setColor(1, 0.82f, 0.82f, 1);
        else batch.setColor(Color.WHITE);
        batch.draw(picture, enemy.x + (enemy.getSize() - width) / 2, enemy.y + lift,
            width / 2, height / 2, width, height, stretchX, stretchY, turn);
        batch.setColor(Color.WHITE);
    }

    private void draw(SpriteBatch batch, TextureRegion picture, Color color, float x, float y, float size) {
        float scale = size / Math.max(picture.getRegionWidth(), picture.getRegionHeight());
        float width = picture.getRegionWidth() * scale;
        float height = picture.getRegionHeight() * scale;
        batch.setColor(color);
        batch.draw(picture, x + (size - width) / 2, y, width, height);
        batch.setColor(Color.WHITE);
    }

    private int bossPicture(ElementType first, ElementType second) {
        if (hasPair(first, second, ElementType.FIRE, ElementType.WATER)) return 2;
        if (hasPair(first, second, ElementType.FIRE, ElementType.EARTH)) return 3;
        if (hasPair(first, second, ElementType.FIRE, ElementType.AIR)) return 4;
        if (hasPair(first, second, ElementType.WATER, ElementType.EARTH)) return 5;
        if (hasPair(first, second, ElementType.WATER, ElementType.AIR)) return 6;
        return 7;
    }

    private boolean hasPair(ElementType first, ElementType second, ElementType a, ElementType b) {
        return (first == a && second == b) || (first == b && second == a);
    }

    public void dispose() {
        files.dispose();
    }
}
