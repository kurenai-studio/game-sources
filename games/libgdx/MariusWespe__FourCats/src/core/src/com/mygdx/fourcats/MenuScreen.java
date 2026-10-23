package com.mygdx.fourcats;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.viewport.FitViewport;

public class MenuScreen implements Screen {

    private final FitViewport fitViewport;
    private final FourCatsGame game;

    private final CatSelection selection;

    private final String ARCHIETEXT = "Great jumping skills     \nuse SPACE to jump across the whole field!";
    private final String LENNYTEXT = "Slow but crazy      \nprepare for random berserk states!";
    private final String CICCIOTEXT = "Great hunter     \npress SPACE to charge for short fast lunges!";
    private final String MERLINTEXT = "Balanced stats     \nfast runner without special skills!";

    public MenuScreen(FourCatsGame fourCatsGame)
    {
        game = fourCatsGame;
        fitViewport = new FitViewport(400, 200);
        selection = new CatSelection(game.shape, 400, -90);
        selection.addCat(CatName.ARCHIE, "Archie.png");
        selection.addCat(CatName.LENNY, "Lenny.png");
        selection.addCat(CatName.CICCIO, "Ciccio.png");
        selection.addCat(CatName.MERLIN, "Merlin.png");
        selection.setPositions();


    }

    @Override
    public void show() {

    }

    @Override
    public void render(float delta)
    {


        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
        game.batch.setProjectionMatrix(fitViewport.getCamera().combined);
        game.shape.setProjectionMatrix(fitViewport.getCamera().combined);
        handleSelectionInput();

        game.shape.begin(ShapeRenderer.ShapeType.Filled);
        game.shape.setColor(Color.WHITE);
        selection.drawSelectionBox(game.shape);
        game.shape.end();

        game.batch.begin();
        game.bigfont.draw(game.batch, "Welcome to FourCats ",- 140, 90);
        drawDescription();
        selection.draw(game.batch);
        game.batch.end();


    }

    private void drawDescription()
    {
        String description;
        switch (selection.getSelectedCat())
        {
            case ARCHIE:
                description = ARCHIETEXT;
                break;
            case LENNY:
                description = LENNYTEXT;
                break;
            case CICCIO:
                description = CICCIOTEXT;
                break;
            default:
                description = MERLINTEXT;
        }

        game.regularfont.draw(game.batch, description, - 140, 50);
    }

    private void handleSelectionInput()
    {
        if (Gdx.input.isKeyJustPressed(Input.Keys.D))
        {
            selection.increaseSelectedIndex();
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.A))
        {
            selection.decreaseSelectedIndex();
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.ENTER))
        {
            Config.setSpeed(selection.getSelectedCat());
            game.setScreen(new GameScreen(game, selection.getSelectedCat()));
        }
    }

    @Override
    public void resize(int width, int height) {
        fitViewport.update(width, height);
    }

    @Override
    public void pause() {

    }

    @Override
    public void resume() {

    }

    @Override
    public void hide() {

    }

    @Override
    public void dispose()
    {
        selection.dispose();
    }
}
