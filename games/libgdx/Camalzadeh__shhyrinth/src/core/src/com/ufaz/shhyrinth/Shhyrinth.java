package com.ufaz.shhyrinth;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.github.tommyettinger.colorful.Shaders;
import com.ufaz.shhyrinth.data.Assets;
import com.ufaz.shhyrinth.screens.BlankScreen;
import com.ufaz.shhyrinth.screens.GameScreen;
import de.eskalon.commons.core.ManagedGame;
import de.eskalon.commons.screen.ManagedScreen;
import de.eskalon.commons.screen.transition.ScreenTransition;
import de.eskalon.commons.screen.transition.impl.BlendingTransition;

public class Shhyrinth extends ManagedGame<ManagedScreen, ScreenTransition> {
    //TODO sprint icon
    private SpriteBatch batch;

    @Override
    public void create() {
        super.create();
        batch = new SpriteBatch(1000, Shaders.makeRGBAShader());
        Assets.instance.load();
        screenManager.addScreen("Game", new GameScreen(this));
        screenManager.addScreen("Reset", new BlankScreen());

        BlendingTransition b = new BlendingTransition(batch, 1f);
        screenManager.addScreenTransition("blend", b);
        screenManager.pushScreen("Game", "blend");
    }

    @Override
    public void render() {
        super.render();
    }

    @Override
    public void dispose() {
        super.dispose();
        Assets.instance.dispose();
    }

    public SpriteBatch getBatch() {
        return batch;
    }
}
