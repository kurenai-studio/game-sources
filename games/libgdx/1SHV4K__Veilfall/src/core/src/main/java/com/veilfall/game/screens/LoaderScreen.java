package com.veilfall.game.screens;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.scenes.scene2d.ui.Image;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Cell;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.utils.TextureRegionDrawable;
import com.badlogic.gdx.utils.Align;
import com.veilfall.game.VeilfallGame;

public final class LoaderScreen extends AbstractGameScreen {
    private static final float LOADING_DURATION = 1.8f;
    private static final float BAR_WIDTH = 220f;
    private float elapsed;
    private final Label loadingLabel;
    private final Image progress;
    private final Table progressBar;
    private final Cell<Image> progressCell;

    public LoaderScreen(VeilfallGame game) {
        super(game);
        Table root = new Table();
        root.setFillParent(true);
        stage.addActor(root);

        Label title = game.getUiTheme().label("VEILFALL");
        title.setFontScale(2.0f);
        title.setAlignment(Align.center);
        loadingLabel = game.getUiTheme().label("LOADING...");
        loadingLabel.setAlignment(Align.center);

        TextureRegionDrawable barDrawable = new TextureRegionDrawable(
                new com.badlogic.gdx.graphics.g2d.TextureRegion(game.getUiTheme().getSkin()
                        .get("white-texture", com.badlogic.gdx.graphics.Texture.class)));
        progressBar = new Table();
        progressBar.setBackground(barDrawable.tint(new Color(0.12f, 0.15f, 0.19f, 1f)));
        progress = new Image(barDrawable.tint(new Color(0.55f, 0.68f, 0.74f, 1f)));
        progressCell = progressBar.add(progress).left().width(0f).height(8f);
        root.add(title).padBottom(18f).row();
        root.add(loadingLabel).padBottom(14f).row();
        root.add(progressBar).width(BAR_WIDTH).height(8f);
    }

    @Override
    public void render(float delta) {
        elapsed += delta;
        clearDarkBackground(0.025f, 0.035f, 0.05f);
        float fraction = Math.min(elapsed / LOADING_DURATION, 1f);
        progressCell.width(BAR_WIDTH * fraction);
        progressBar.invalidateHierarchy();
        float alpha = 0.55f + 0.45f * (float) Math.sin(elapsed * 4f);
        loadingLabel.getColor().a = alpha;
        drawStage(delta);
        if (elapsed >= LOADING_DURATION) {
            game.showLobby();
        }
    }
}
