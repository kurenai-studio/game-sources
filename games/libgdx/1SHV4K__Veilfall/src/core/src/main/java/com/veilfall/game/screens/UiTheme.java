package com.veilfall.game.screens;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.TextureRegionDrawable;
import com.badlogic.gdx.utils.Disposable;

public final class UiTheme implements Disposable {
    private final Skin skin;

    public UiTheme() {
        skin = new Skin();
        BitmapFont font = new BitmapFont();
        Texture whiteTexture = createWhiteTexture();
        skin.add("default-font", font, BitmapFont.class);
        skin.add("white-texture", whiteTexture, Texture.class);

        Label.LabelStyle labelStyle = new Label.LabelStyle(font, Color.WHITE);
        skin.add("default", labelStyle, Label.LabelStyle.class);

        TextButton.TextButtonStyle buttonStyle = new TextButton.TextButtonStyle();
        buttonStyle.font = font;
        buttonStyle.fontColor = Color.WHITE;
        TextureRegion whiteRegion = new TextureRegion(whiteTexture);
        buttonStyle.up = new TextureRegionDrawable(whiteRegion).tint(new Color(0.16f, 0.20f, 0.25f, 1f));
        buttonStyle.down = new TextureRegionDrawable(whiteRegion).tint(new Color(0.28f, 0.34f, 0.40f, 1f));
        buttonStyle.disabled = new TextureRegionDrawable(whiteRegion).tint(new Color(0.10f, 0.12f, 0.15f, 1f));
        buttonStyle.disabledFontColor = new Color(0.55f, 0.58f, 0.61f, 1f);
        skin.add("default", buttonStyle, TextButton.TextButtonStyle.class);
    }

    public Skin getSkin() {
        return skin;
    }

    public Label label(String text) {
        return new Label(text, skin);
    }

    public TextButton button(String text) {
        return new TextButton(text, skin);
    }

    private static Texture createWhiteTexture() {
        Pixmap pixmap = new Pixmap(1, 1, Pixmap.Format.RGBA8888);
        pixmap.setColor(Color.WHITE);
        pixmap.fill();
        Texture texture = new Texture(pixmap);
        pixmap.dispose();
        return texture;
    }

    @Override
    public void dispose() {
        skin.dispose();
    }
}
