package com.elmagica.game;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.utils.Array;

// Кто загрузил текстуры, тот потом вызывает dispose.
public class SpriteFiles {
    private final Array<Texture> textures = new Array<>();

    public TextureRegion load(String path) {
        Texture texture = new Texture(Gdx.files.internal(path + ".png"));
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        textures.add(texture);
        return new TextureRegion(texture);
    }

    public void dispose() {
        for (Texture texture : textures) texture.dispose();
        textures.clear();
    }
}
