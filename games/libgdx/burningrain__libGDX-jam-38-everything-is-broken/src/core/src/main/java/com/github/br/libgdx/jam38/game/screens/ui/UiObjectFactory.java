package com.github.br.libgdx.jam38.game.screens.ui;

import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.scenes.scene2d.ui.ImageButton;
import com.badlogic.gdx.scenes.scene2d.utils.TextureRegionDrawable;
import com.badlogic.gdx.utils.Array;
import com.github.br.libgdx.jam38.game.Resources;
import com.github.br.libgdx.jam38.game.model.GameTime;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;
import com.github.br.libgdx.jam38.game.screens.ui.button.UiBurnTimeButton;
import com.github.br.libgdx.jam38.game.screens.ui.button.UiEmitButton;
import com.github.br.libgdx.jam38.game.screens.ui.button.UiEmptyButton;
import com.github.br.libgdx.jam38.game.screens.ui.button.UiFreezeButton;
import com.github.br.libgdx.jam38.structure.ui.AnimatedImage;

public class UiObjectFactory {

    private final AssetManager assetManager;

    private final TextureAtlas textureAtlas;

    // node
    private final Array<TextureAtlas.AtlasRegion> targetNode;
    private final Array<TextureAtlas.AtlasRegion> emitterNode;
    private final Array<TextureAtlas.AtlasRegion> emptyNode;
    private final Array<TextureAtlas.AtlasRegion> freezeNode;
    private final Array<TextureAtlas.AtlasRegion> selectedNode;

    // effects
    private final Array<TextureAtlas.AtlasRegion> emitFrom;
    private final Array<TextureAtlas.AtlasRegion> emitTo;
    private final Array<TextureAtlas.AtlasRegion> emitToFromTime;

    // edge
    private final Array<TextureAtlas.AtlasRegion> emptyEdge;
    private final Array<TextureAtlas.AtlasRegion> emitEdge;
    private final Array<TextureAtlas.AtlasRegion> freezeEdge;
    private final Array<TextureAtlas.AtlasRegion> targetEdge;

    // button
    private final Array<TextureAtlas.AtlasRegion> emptyButtonRegions;
    private final Array<TextureAtlas.AtlasRegion> emitterButtonRegions;
    private final Array<TextureAtlas.AtlasRegion> freezeButtonRegions;
    private final Array<TextureAtlas.AtlasRegion> burnButtonRegions;

    private final Array<TextureAtlas.AtlasRegion> restartButtonRegions;
    private final Array<TextureAtlas.AtlasRegion> nextButtonRegions;

    // time stone
    private final Array<TextureAtlas.AtlasRegion> timeStone;


    public UiObjectFactory(AssetManager assetManager) {
        this.assetManager = assetManager;

        textureAtlas = assetManager.get(Resources.GRAPH_GAME_ATLAS, TextureAtlas.class);

        // node
        targetNode = textureAtlas.findRegions(Resources.GraphGame.Node.TARGET_NODE);
        emitterNode = textureAtlas.findRegions(Resources.GraphGame.Node.EMITTER_NODE);
        emptyNode = textureAtlas.findRegions(Resources.GraphGame.Node.EMPTY_NODE);
        freezeNode = textureAtlas.findRegions(Resources.GraphGame.Node.FREEZE_NODE);
        selectedNode = textureAtlas.findRegions(Resources.GraphGame.Node.SELECTED_EFFECT);

        // effects
        emitFrom = textureAtlas.findRegions(Resources.GraphGame.EmitterEffect.EMITTER_FROM);
        emitTo = textureAtlas.findRegions(Resources.GraphGame.EmitterEffect.EMITTER_TO);
        emitToFromTime = textureAtlas.findRegions(Resources.GraphGame.EmitterEffect.EMITTER_FROM_TIME);

        // edge
        emptyEdge = textureAtlas.findRegions(Resources.GraphGame.Edge.EMPTY_EDGE);
        emitEdge = textureAtlas.findRegions(Resources.GraphGame.Edge.EMIT_EDGE);
        freezeEdge = textureAtlas.findRegions(Resources.GraphGame.Edge.FREEZE_EDGE);
        targetEdge = textureAtlas.findRegions(Resources.GraphGame.Edge.TARGET_EDGE);

        // button
        emptyButtonRegions = textureAtlas.findRegions(Resources.GraphGame.Button.EMPTY_BUTTON);
        emitterButtonRegions = textureAtlas.findRegions(Resources.GraphGame.Button.EMITTER_BUTTON);
        freezeButtonRegions = textureAtlas.findRegions(Resources.GraphGame.Button.FREEZE_BUTTON);
        burnButtonRegions = textureAtlas.findRegions(Resources.GraphGame.Button.BURN_BUTTON);

        restartButtonRegions = textureAtlas.findRegions(Resources.GraphGame.Button.RESTART_BUTTON);
        nextButtonRegions = textureAtlas.findRegions(Resources.GraphGame.Button.NEXT_BUTTON);

        // time stone
        timeStone = textureAtlas.findRegions(Resources.GraphGame.TIME);
    }

    public UiTime createUiTime(GameTime gameTime) {
        return new UiTime(gameTime, timeStone);
    }

    public ImageButton createRestartButton() {
        return new ImageButton(createImageButtonStyleWithoutDisabled(restartButtonRegions));
    }

    public ImageButton createNextButton() {
        return new ImageButton(createImageButtonStyleWithoutDisabled(nextButtonRegions));
    }

    public UiEmptyButton createEmptyButton() {
        return new UiEmptyButton(createImageButtonStyle(emptyButtonRegions));
    }

    public UiEmitButton createEmitButton() {
        return new UiEmitButton(createImageButtonStyle(emitterButtonRegions));
    }

    public UiFreezeButton createFreezeButton() {
        return new UiFreezeButton(createImageButtonStyle(freezeButtonRegions));
    }

    public UiBurnTimeButton createBurnTimeButton() {
        return new UiBurnTimeButton(createImageButtonStyle(burnButtonRegions));
    }

    public UiNode createUiNode(GameVertex vertex) {
        TextureAtlas.AtlasRegion icon = textureAtlas.findRegion(vertex.getName());

        return new UiNode(
            vertex,
            icon, // Texture
            createAnimatedImagePingPong(emitFrom), // AnimatedImage
            createAnimatedImagePingPong(emitToFromTime), // AnimatedImage
            createAnimatedImagePingPong(emitTo), // AnimatedImage
            createAnimatedImagePingPong(selectedNode), // AnimatedImage
            createAnimatedImagePingPong(freezeNode), // AnimatedImage
            createAnimatedImagePingPong(emitterNode), // AnimatedImage
            createAnimatedImagePingPong(emptyNode), // AnimatedImage
            createAnimatedImagePingPong(targetNode) // AnimatedImage
        );
    }

    public UiEdge createUiEdge(UiNode from, UiNode to) {

        return new UiEdge(
            from,
            to,
            createAnimatedImage(emitEdge, 1 / 20f, Animation.PlayMode.LOOP),   // AnimatedImage emitEdge,
            createAnimatedImagePingPong(emptyEdge),  // AnimatedImage emptyEdge,
            createAnimatedImagePingPong(freezeEdge), // AnimatedImage freezeEdge,
            createAnimatedImagePingPong(targetEdge)  // AnimatedImage targetEdge
        );
    }

    private AnimatedImage createAnimatedImagePingPong(Array<TextureAtlas.AtlasRegion> targetNode) {
        return createAnimatedImage(targetNode, 1 / 14f, Animation.PlayMode.LOOP_PINGPONG);
    }

    private AnimatedImage createAnimatedImage(
        Array<TextureAtlas.AtlasRegion> targetNode,
        float frameDuration,
        Animation.PlayMode playMode
    ) {
        AnimatedImage animatedImage = new AnimatedImage(new Animation<>(frameDuration, targetNode));
        animatedImage.setLooping(true);
        animatedImage.setPlayMode(playMode);

        return animatedImage;
    }

    private ImageButton.ImageButtonStyle createImageButtonStyle(Array<TextureAtlas.AtlasRegion> buttonRegions) {
        ImageButton.ImageButtonStyle myButtonStyle = new ImageButton.ImageButtonStyle();
        myButtonStyle.up = new TextureRegionDrawable(buttonRegions.get(0));
        myButtonStyle.down = new TextureRegionDrawable(buttonRegions.get(3));
        myButtonStyle.over = new TextureRegionDrawable(buttonRegions.get(2));
        myButtonStyle.disabled = new TextureRegionDrawable(buttonRegions.get(1));

        return myButtonStyle;
    }

    private ImageButton.ImageButtonStyle createImageButtonStyleWithoutDisabled(Array<TextureAtlas.AtlasRegion> buttonRegions) {
        ImageButton.ImageButtonStyle myButtonStyle = new ImageButton.ImageButtonStyle();
        myButtonStyle.up = new TextureRegionDrawable(buttonRegions.get(0));
        myButtonStyle.down = new TextureRegionDrawable(buttonRegions.get(2));
        myButtonStyle.over = new TextureRegionDrawable(buttonRegions.get(1));
        myButtonStyle.disabled = null;

        return myButtonStyle;
    }


}
