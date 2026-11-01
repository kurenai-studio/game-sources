package dev.meowpow.boxbot.render.assets;

import com.badlogic.gdx.graphics.g2d.TextureRegion;

final class TestTextureRegion extends TextureRegion {

    private final int width;

    TestTextureRegion(int width) {
        this.width = width;
    }

    @Override
    public int getRegionWidth() {
        return width;
    }
}
