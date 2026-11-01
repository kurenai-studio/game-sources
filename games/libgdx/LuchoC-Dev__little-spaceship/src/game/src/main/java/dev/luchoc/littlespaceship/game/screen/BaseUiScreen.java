package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.InputMultiplexer;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.Image;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.utils.ScreenUtils;
import com.badlogic.gdx.utils.viewport.Viewport;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;
import dev.luchoc.littlespaceship.game.adapter.render.PixelPerfectViewport;
import dev.luchoc.littlespaceship.game.ui.Palette;

/**
 * Common scaffolding for the six {@code scene2d.ui} screens of {@code
 * docs/design/mockups/screens.html}: one {@link Stage} at the logical 480x270 resolution, scaled
 * the same way {@link LittleSpaceshipGame} scales gameplay — integer factor, nearest-neighbour,
 * letterboxed — because a menu drawn at a different policy than the game it wraps would be the one
 * inconsistency a player notices immediately.
 *
 * <p>Every screen shares the fixed frame {@code 04-hud-layout.md} fixes for the flow: the title at
 * {@code 40, 32} in {@code font-title}, a rule beneath it, and a 24 px safe area. Subclasses add
 * their own content to {@link #content}, a table already inset by the safe area.
 */
public abstract class BaseUiScreen extends ScreenAdapter {

    protected static final int TITLE_X = 40;
    protected static final int TITLE_Y = 32;
    protected static final int SAFE_AREA = 24;

    protected final LittleSpaceshipGame game;
    protected final Skin skin;
    protected final Stage stage;
    protected final Table content;

    protected BaseUiScreen(LittleSpaceshipGame game, String title) {
        this.game = game;
        this.skin = game.skin();
        Viewport viewport = new PixelPerfectViewport(
            LittleSpaceshipGame.LOGICAL_WIDTH, LittleSpaceshipGame.LOGICAL_HEIGHT,
            new com.badlogic.gdx.graphics.OrthographicCamera());
        this.stage = new Stage(viewport, new SpriteBatch());

        Table root = new Table();
        root.setFillParent(true);
        stage.addActor(root);

        if (title != null) {
            Label titleLabel = new Label(title, skin, "title");
            root.top().left();
            root.add(titleLabel).padTop(TITLE_Y).padLeft(TITLE_X).row();

            // The 1 px N3 rule docs/design/mockups/src/05-screens.js draws under every screen's
            // title, sized to the title's own width so it reads as an underline rather than a
            // divider that happens to sit near the text.
            GlyphLayout titleLayout = new GlyphLayout(skin.getFont("font-title"), title);
            Image rule = new Image(skin.newDrawable("white", Palette.N3));
            root.add(rule).width(titleLayout.width).height(1f)
                .padLeft(TITLE_X).padTop(4f).left().row();
        }

        content = new Table();
        root.add(content).expand().fill()
            .pad(SAFE_AREA, SAFE_AREA, SAFE_AREA, SAFE_AREA);
    }

    @Override
    public void show() {
        InputMultiplexer multiplexer = new InputMultiplexer(stage);
        Gdx.input.setInputProcessor(multiplexer);
    }

    @Override
    public void resize(int width, int height) {
        stage.getViewport().update(width, height, true);
    }

    @Override
    public void render(float delta) {
        ScreenUtils.clear(Palette.N0.r, Palette.N0.g, Palette.N0.b, 1f);
        stage.act(delta);
        stage.draw();
    }

    @Override
    public void hide() {
        Gdx.input.setInputProcessor(null);
    }

    @Override
    public void dispose() {
        stage.dispose();
    }
}
