package com.github.br.libgdx.jam38.structure.ui;

import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.ParticleEffect;
import com.badlogic.gdx.scenes.scene2d.ui.Button;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;

public class ParticleButton extends Button {

    private ParticleEffect effect;

    public ParticleButton(Skin skin, ParticleEffect effect) {
        super(skin);
        this.effect = effect;
    }

    @Override
    public void act(float delta) {
        super.act(delta);
        // Обновляем позицию эффекта по центру кнопки
        effect.setPosition(getX() + getWidth() / 2, getY() + getHeight() / 2);
        effect.update(delta);
    }

    @Override
    public void draw(Batch batch, float parentAlpha) {
        // Сначала рисуем саму кнопку
        super.draw(batch, parentAlpha);
        // Затем рисуем партиклы поверх (или наоборот, если переставить строки)
        effect.draw(batch);
    }
}
