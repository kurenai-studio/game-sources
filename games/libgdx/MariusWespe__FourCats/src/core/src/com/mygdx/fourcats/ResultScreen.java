package com.mygdx.fourcats;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.utils.viewport.FitViewport;

public class ResultScreen implements Screen {

    private final FitViewport fitViewport;
    private final FourCatsGame game;

    private final int worldSizeX = Config.MENU_SCREENS_SIZE_X;
    private final int worldSizeY = Config.MENU_SCREENS_SIZE_Y;

    private int srcWidth, srcHeight;

    private Texture texture;

    private final int highscore;

    private final String  notherRoundString = "Press ENTER for another round";

    private final String quitGameString = "Press ESCAPE to end the game";


    public ResultScreen(FourCatsGame game, CatName name, int score)
    {
        this.game = game;
        this.highscore = score;
        fitViewport = new FitViewport(worldSizeX, worldSizeY);
        retrieveTextureByName(name);

    }

    private void retrieveTextureByName(CatName name)
    {
        switch (name)
        {
            case LENNY:
                texture = new Texture(Gdx.files.internal("Lenny.png"));
                break;
            case ARCHIE:
                texture = new Texture(Gdx.files.internal("Archie.png"));
                break;
            case CICCIO:
                texture = new Texture(Gdx.files.internal("Ciccio.png"));
                break;
            default:
                texture = new Texture(Gdx.files.internal("MerlinEdit.png"));
        }
        srcWidth = texture.getWidth();
        srcHeight = texture.getHeight();
    }


    @Override
    public void show()
    {
    }

    @Override
    public void render(float delta)
    {
        handleInput();

        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
        game.batch.setProjectionMatrix(fitViewport.getCamera().combined);
        game.batch.begin();
        game.bigfont.draw(game.batch,"You scored", Math.round(-0.175f * worldSizeX), Math.round((0.3f * worldSizeY)));
        String scoreString = highscore + " points!";
        game.bigfont.draw(game.batch, scoreString, Math.round(-0.175f * worldSizeX), Math.round((0.15f * worldSizeY)));
        game.batch.draw(texture, -  Math.round(0.475f * worldSizeX), Math.round(0.1f * worldSizeY), Math.round(0.15f * worldSizeX), Math.round(0.15f * worldSizeX), 0,0, srcWidth, srcHeight, true, false);
        game.batch.draw(texture, Math.round(0.325f * worldSizeX), Math.round(0.1f * worldSizeY), Math.round(0.15f * worldSizeX), Math.round(0.15f * worldSizeX), 0,0, srcWidth, srcHeight, false, false);

        game.regularfont.draw(game.batch, notherRoundString, Math.round(-0.375f * worldSizeX), Math.round(-0.3f * worldSizeY));
        game.regularfont.draw(game.batch, quitGameString, Math.round(-0.375f * worldSizeX), Math.round(-0.4f * worldSizeY));
        game.batch.end();

    }

    private void handleInput()
    {
        if (Gdx.input.isKeyPressed(Input.Keys.ESCAPE))
        {
            Gdx.app.exit();
        }

        if (Gdx.input.isKeyPressed(Input.Keys.ENTER))
        {
            this.game.setScreen(new MenuScreen(this.game));
            dispose();
        }
    }

    @Override
    public void resize(int width, int height)
    {
        fitViewport.update(width, height);
    }

    @Override
    public void pause()
    {

    }
    @Override
    public void resume() {

    }

    @Override
    public void hide() {

    }

    @Override
    public void dispose() {
        texture.dispose();

    }
}
