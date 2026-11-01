package com.github.br.libgdx.jam38.structure.ui;

import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.ParticleEffect;
import com.badlogic.gdx.scenes.scene2d.Actor;

public class ParticleActor extends Actor {

    private final ParticleEffect effect;

    public ParticleActor(ParticleEffect effect, float width, float height) {
        this.effect = effect;
        // Обязательно задаем размер, иначе клики не будут регистрироваться
        setSize(width, height);
    }

    @Override
    public void act(float delta) {
        super.act(delta);
        // Центрируем эффект внутри актера
        effect.setPosition(getX() + getWidth() / 2, getY() + getHeight() / 2);
        effect.update(delta);
    }

    @Override
    public void draw(Batch batch, float parentAlpha) {
        effect.draw(batch);
    }

}
