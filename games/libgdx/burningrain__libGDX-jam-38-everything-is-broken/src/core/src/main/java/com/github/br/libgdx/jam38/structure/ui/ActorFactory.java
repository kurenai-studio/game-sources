package com.github.br.libgdx.jam38.structure.ui;

import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.maps.MapObject;
import com.badlogic.gdx.maps.MapProperties;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.ui.Image;
import com.badlogic.gdx.scenes.scene2d.ui.ImageButton;
import com.badlogic.gdx.scenes.scene2d.ui.ImageTextButton;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.utils.Align;
import com.badlogic.gdx.utils.Array;
import com.github.tommyettinger.textra.TypingLabel;

public class ActorFactory {

    public interface ActorType {
        String IMAGE = "image";
        String ANIMATED_IMAGE = "animated_image";

        String LABEL = "label";
        String TYPING_LABEL = "typing_label";

        String IMAGE_BUTTON = "image_button";
        String IMAGE_TEXT_BUTTON = "image_text_button";
    }

    public static final String ACTOR_TYPE = "actor_type";
    public static final String ATLAS_NAME = "atlas_name";
    public static final String REGION_NAME = "region_name";
    public static final String PLAY_MODE = "play_mode";

    public static final String TEXT = "text";
    public static final String STYLE_NAME = "style_name";
    private static final String FRAME_DURATION = "frame_duration";

    private final Skin skin;
    private final AssetManager assetManager;

    public ActorFactory(Skin skin, AssetManager assetManager) {
        this.skin = skin;
        this.assetManager = assetManager;
    }

    public Actor getActor(MapObject object) {
        String name = object.getName();
        MapProperties properties = object.getProperties();

        String actorType = properties.get(ACTOR_TYPE, String.class);

        switch (actorType) {
            case ActorType.IMAGE:
                return createImage(object);
            case ActorType.ANIMATED_IMAGE:
                return createAnimatedImage(object);

            case ActorType.LABEL:
                return createLabel(object);
            case ActorType.TYPING_LABEL:
                return createTypingLabel(object);

            case ActorType.IMAGE_BUTTON:
                return createImageButton(object);
            case ActorType.IMAGE_TEXT_BUTTON:
                return createImageTextButton(object);
            default:
                throw new IllegalArgumentException("unknown stage2d actor type [" + actorType + "]. actor name: " + name);
        }
    }

    private Actor createImage(MapObject object) {
        MapProperties properties = object.getProperties();
        String atlasName = properties.get(ATLAS_NAME, String.class);
        String regionName = properties.get(REGION_NAME, String.class);

        TextureAtlas textureAtlas = assetManager.get(atlasName, TextureAtlas.class);
        TextureAtlas.AtlasRegion region = textureAtlas.findRegion(regionName);

        return new Image(region);
    }

    private Actor createLabel(MapObject object) {
        MapProperties properties = object.getProperties();
        String buttonText = properties.get(TEXT, String.class);
        String styleName = properties.get(STYLE_NAME, String.class);

        //TODO сам текст нужно брать из файлика локализации !!!
        Label label = new Label(buttonText, skin, styleName);
        label.setAlignment(Align.topLeft);

        Float width = properties.get("width", float.class);
        Float height = properties.get("height", float.class);

        label.setWidth(width);
        label.setHeight(height);

        label.setWrap(true);

        return label;
    }

    private Actor createTypingLabel(MapObject object) {
        MapProperties properties = object.getProperties();
        String buttonText = properties.get(TEXT, String.class);
        String styleName = properties.get(STYLE_NAME, String.class);

        //TODO сам текст нужно брать из файлика локализации !!!
        TypingLabel label = new TypingLabel(buttonText, skin, styleName);
        label.setAlignment(Align.topLeft);

        Float width = properties.get("width", float.class);
        Float height = properties.get("height", float.class);

        label.setWidth(width);
        label.setHeight(height);

        label.setWrap(true);

        return label;
    }

    private Actor createAnimatedImage(MapObject object) {
        MapProperties properties = object.getProperties();
        String atlasName = properties.get(ATLAS_NAME, String.class);
        String regionName = properties.get(REGION_NAME, String.class);
        String playMode = properties.get(PLAY_MODE, String.class);
        float frameDuration = properties.get(FRAME_DURATION, Float.class);

        TextureAtlas textureAtlas = assetManager.get(atlasName, TextureAtlas.class);
        Array<TextureAtlas.AtlasRegion> regions = textureAtlas.findRegions(regionName);
        Animation<TextureRegion> animation = new Animation<>(
            frameDuration, regions, Animation.PlayMode.valueOf(playMode)
        );

        return new AnimatedImage(animation);
    }

    private Actor createImageTextButton(MapObject object) {
        MapProperties properties = object.getProperties();
        String buttonText = properties.get(TEXT, String.class);
        //TODO сам текст нужно брать из файлика локализации !!!
        return new ImageTextButton(buttonText, skin);
    }

    private Actor createImageButton(MapObject object) {
        ImageButton button = new ImageButton(skin);
        MapProperties properties = object.getProperties();
        Boolean isFlip = (Boolean) properties.get("flip");
        if (isFlip != null && isFlip) {
            button.setTransform(true); // Разрешаем трансформацию
            button.setScale(-1, 1);    // Отражаем по горизонтали
            button.setOrigin(Align.center); // Устанавливаем центр для отражения

            // Корректировка хитбокса (важно для нажатий!)
            // Из-за scale(-1) координаты нажатий будут неправильными, если не скорректировать
        }

        return button;
    }

}
