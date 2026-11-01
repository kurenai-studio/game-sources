package com.github.br.libgdx.jam38.game.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.ImageButton;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.badlogic.gdx.scenes.scene2d.utils.ClickListener;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ObjectMap;
import com.badlogic.gdx.utils.Scaling;
import com.badlogic.gdx.utils.viewport.ExtendViewport;
import com.badlogic.gdx.utils.viewport.ScalingViewport;
import com.badlogic.gdx.utils.viewport.Viewport;
import com.github.br.libgdx.jam38.game.Resources;
import com.github.br.libgdx.jam38.game.model.*;
import com.github.br.libgdx.jam38.game.model.action.GameAction;
import com.github.br.libgdx.jam38.game.model.action.GameVertexAction;
import com.github.br.libgdx.jam38.game.model.action.edge.GameEdge;
import com.github.br.libgdx.jam38.game.model.action.vertex.ApplyTimeStoneToVertexAction;
import com.github.br.libgdx.jam38.game.model.action.vertex.FreezeVertexAction;
import com.github.br.libgdx.jam38.game.model.action.vertex.SwitchEmitterVertexAction;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;
import com.github.br.libgdx.jam38.game.screens.ui.UiEdge;
import com.github.br.libgdx.jam38.game.screens.ui.UiNode;
import com.github.br.libgdx.jam38.game.screens.ui.UiObjectFactory;
import com.github.br.libgdx.jam38.game.screens.ui.UiTime;
import com.github.br.libgdx.jam38.game.screens.ui.button.UiBurnTimeButton;
import com.github.br.libgdx.jam38.game.screens.ui.button.UiEmitButton;
import com.github.br.libgdx.jam38.game.screens.ui.button.UiEmptyButton;
import com.github.br.libgdx.jam38.game.screens.ui.button.UiFreezeButton;
import com.github.br.libgdx.jam38.structure.GameSettings;
import com.github.br.libgdx.jam38.structure.screen.AbstractGameScreen;
import com.github.br.libgdx.jam38.structure.screen.statemachine.GameScreenState;

public class GraphGameScreen extends AbstractGameScreen {

    private GameModelApplicationContext applicationContext;
    private UiObjectFactory uiObjectFactory;

    protected OrthographicCamera camera;
    protected Viewport viewport;

    protected OrthographicCamera backgroundCamera;
    protected Viewport backgroundViewport;

    private SpriteBatch spriteBatch;
    private ShapeRenderer shapeRenderer;

    private Texture background;

    private ObjectMap<String, UiNode> nodesMap = new ObjectMap<>();
    private Array<UiNode> nodes;
    private Array<UiEdge> edges;
    private UiTime uiTime;

    private float accumulator = 0f;
    private float stepTime = 1 / 2.5f; // число шагов эмуляции в секунду

    private Stage stage;

    private UiNode selectedNode = null;
    private final ClickListener nodeClickListener = new ClickListener() {
        @Override
        public void clicked(InputEvent event, float x, float y) {
            Actor target = event.getTarget();
            UiNode uiTargetNode = (UiNode) target;
            String name = uiTargetNode.getModel().getName();
            if (selectedNode != null && !selectedNode.getModel().getName().equals(name)) {
                selectedNode.deselect();
            }

            if (uiTargetNode.isSelected()) {
                selectedNode = null;
                uiTargetNode.deselect();
            } else {
                selectedNode = uiTargetNode;
                uiTargetNode.select();
            }
        }
    };

    private GameDelta lastResult;

    // buttons
    private UiEmptyButton emptyButton;
    private final ChangeListener emptyButtonListener = new ChangeListener() {
        @Override
        public void changed(ChangeListener.ChangeEvent event, Actor actor) {
            Game game = applicationContext.getGame();
            game.addGameAction(new SwitchEmitterVertexAction(selectedNode.getModel().getName()));
        }
    };

    private UiEmitButton emitButton;
    private final ChangeListener emitButtonListener = new ChangeListener() {
        @Override
        public void changed(ChangeListener.ChangeEvent event, Actor actor) {
            Game game = applicationContext.getGame();
            game.addGameAction(new SwitchEmitterVertexAction(selectedNode.getModel().getName()));
        }
    };
    private UiFreezeButton freezeButton;
    private final ChangeListener freezeButtonListener = new ChangeListener() {
        @Override
        public void changed(ChangeListener.ChangeEvent event, Actor actor) {
            Game game = applicationContext.getGame();
            game.addGameAction(new FreezeVertexAction(selectedNode.getModel().getName()));
        }
    };
    private UiBurnTimeButton burnTimeButton;
    private final ChangeListener burnTimeButtonListener = new ChangeListener() {
        @Override
        public void changed(ChangeListener.ChangeEvent event, Actor actor) {
            Game game = applicationContext.getGame();
            game.addGameAction(new ApplyTimeStoneToVertexAction(selectedNode.getModel().getName()));
        }
    };

    private boolean isGameEnd = false;
    // кнопки выхода / рестарта уровня
    private ImageButton restartButton;
    private final ChangeListener restartButtonListener = new ChangeListener() {
        @Override
        public void changed(ChangeListener.ChangeEvent event, Actor actor) {
            restartLevel(level);
        }
    };
    private ImageButton nextButton;
    private final ChangeListener nextButtonListener = new ChangeListener() {
        @Override
        public void changed(ChangeListener.ChangeEvent event, Actor actor) {
            getGameManager().screenStateManager.changeCurrentState(nextScreen);
        }
    };

    private final String level;
    private final GameScreenState nextScreen;

    public GraphGameScreen(String level, GameScreenState nextScreen) {
        this.level = level;
        this.nextScreen = nextScreen;
    }

    @Override
    public void show() {
        AssetManager assetManager = getGameManager().assetManager;
        uiObjectFactory = new UiObjectFactory(assetManager);
        background = assetManager.get(Resources.GraphGame.BACKGROUND, Texture.class);

        GameSettings gameSettings = getGameManager().gameSettings;
        camera = new OrthographicCamera();
        viewport = new ExtendViewport(
            gameSettings.getVirtualScreenWidth(),
            gameSettings.getVirtualScreenHeight(),
            camera
        );
        viewport.apply(true);

        // --- Инициализация вьюпорта для фона ---
        backgroundCamera = new OrthographicCamera();
        // Инициализируем под физический размер самой текстуры фона (2400x1080)
        // Scaling.fill растянет этот виртуальный экран так, чтобы он заполнил монитор без черных полос, обрезав лишнее
        backgroundViewport = new ScalingViewport(
            Scaling.stretch,
            gameSettings.getVirtualScreenWidth(),
            gameSettings.getVirtualScreenHeight(),
            backgroundCamera
        );
        backgroundViewport.apply(true);

        spriteBatch = new SpriteBatch();
        stage = new Stage(viewport, spriteBatch);
        shapeRenderer = new ShapeRenderer();

        restartLevel(level); // "graphs/graph_1.json"
    }

    public void restartLevel(String level) {
        if (edges != null) {
            for (UiEdge edge : edges) {
                edge.remove();
            }
            edges.clear();
        }
        if (nodes != null) {
            for (UiNode node : nodes) {
                node.remove();
            }
            nodes.clear();
        }
        if (nodesMap != null) {
            nodesMap.clear();
        }

        if (uiTime != null) {
            uiTime.remove();
        }
        if (emptyButton != null) {
            emptyButton.remove();
        }
        if (emitButton != null) {
            emitButton.remove();
        }
        if (freezeButton != null) {
            freezeButton.remove();
        }
        if (burnTimeButton != null) {
            burnTimeButton.remove();
        }
        isGameEnd = false;
        lastResult = null;
        selectedNode = null;

        if (restartButton != null) {
            restartButton.remove();
        }
        if (nextButton != null) {
            nextButton.remove();
        }
        createButtons();
        restartButton.setVisible(false);
        nextButton.setVisible(false);

        applicationContext = new GameModelApplicationContext();
        Game game = applicationContext.getGame();
        game.loadGraph(level);
        createTime(game, getGameManager().gameSettings);
        createGraphUi(game.getGameGraph());

        Gdx.input.setInputProcessor(stage);
    }

    private void handleLogic(float delta) {
        isGameEnd = lastResult != null && (lastResult.isGameOver() || lastResult.isTimeOver() || lastResult.isGameVictory());
        if (isGameEnd) {
            changeButtonsVisible(false);
            if (lastResult.isGameOver() || lastResult.isTimeOver()) {
                restartButton.toFront();
                restartButton.setVisible(true);
            }
            if (lastResult.isGameVictory()) {
                for (UiNode node : nodes) {
                    GameVertex model = node.getModel();
                    if(GameVertexState.TARGET == model.getState()) {
                        model.setState(GameVertexState.EMITTER);
                    }
                }

                nextButton.toFront();
                nextButton.setVisible(true);
            }
            return;
        }

        Game game = applicationContext.getGame();

        accumulator += delta;
        while (accumulator >= stepTime) {
            accumulator -= stepTime;
            lastResult = game.tick(stepTime);
            for (GameAction appliedAction : lastResult.getAppliedActions()) {
                if (appliedAction instanceof GameVertexAction gameVertexAction) {
                    UiNode uiNode = nodesMap.get(gameVertexAction.getTargetName());
                    if (gameVertexAction instanceof FreezeVertexAction) {
                        uiNode.freeze();
                    }
                    if (gameVertexAction instanceof ApplyTimeStoneToVertexAction timeStoneAction) {
                        if (timeStoneAction.isUnfreeze()) {
                            uiNode.unfreeze();
                        } else {
                            uiNode.emitFromTime();
                        }
                    }
                }
            }
        }

        updateButtonsForSelectedNode(game.getGameTime());
    }

    private void changeButtonsVisible(boolean isVisible) {
        emptyButton.setVisible(isVisible);
        emitButton.setVisible(isVisible);
        freezeButton.setVisible(isVisible);
        burnTimeButton.setVisible(isVisible);
    }

    private void updateButtonsForSelectedNode(GameTime gameTime) {
        if (selectedNode == null) {
            emptyButton.setDisabled(true);
            emitButton.setDisabled(true);
            freezeButton.setDisabled(true);
            burnTimeButton.setDisabled(true);
            return;
        }

        GameVertex model = selectedNode.getModel();

        emptyButton.setDisabled(false);
        emitButton.setDisabled(false);
        freezeButton.setDisabled(false);
        burnTimeButton.setDisabled(false);

        if (model.isFreeze()) {
            freezeButton.setDisabled(true);
            emptyButton.setDisabled(true);
            emitButton.setDisabled(true);
        }
        switch (model.getState()) {
            case NONE -> emptyButton.setDisabled(true);
            case EMITTER -> emitButton.setDisabled(true);
            case TARGET -> {
                emptyButton.setDisabled(true);
                emitButton.setDisabled(true);
                freezeButton.setDisabled(true);
                burnTimeButton.setDisabled(true);
            }
        }
        if (gameTime.getTimerSec() - 10 <= 0) {
            //FIXME хардкод из Action по сжиганию
            burnTimeButton.setDisabled(true);
        }
    }

    @Override
    public void render(float delta) {
        handleLogic(delta);

        Gdx.gl.glClearColor(1, 1, 1, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        // ---  Рисуем фон через его собственный вьюпорт ---
        backgroundCamera.update();
        backgroundViewport.apply(true);
        spriteBatch.setProjectionMatrix(backgroundCamera.combined);
        spriteBatch.begin();
        // Так как размеры вьюпорта равны размерам текстуры, просто рисуем её с нуля
        spriteBatch.draw(background, 0, 0);
        spriteBatch.end();

        // --- Рисуем игру (ноды, ребра, частицы) через ExtendViewport ---
        GameSettings gameSettings = getGameManager().gameSettings;
        viewport.apply(false);
        camera.position.set(
            gameSettings.getVirtualScreenWidth() / 2f,
            gameSettings.getVirtualScreenHeight() / 2f,
            0
        );
        camera.update();

        spriteBatch.setProjectionMatrix(camera.combined);
        stage.act();
        stage.draw();

        // отрисовка энергии
        if (!isGameEnd) {
            shapeRenderer.setProjectionMatrix(spriteBatch.getProjectionMatrix());
            shapeRenderer.setTransformMatrix(spriteBatch.getTransformMatrix());
            Gdx.gl.glEnable(GL20.GL_BLEND);
            Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);

            shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);
            for (UiNode node : nodes) {
                node.drawEnergy(shapeRenderer, 1f);
            }
            shapeRenderer.end();
        }
    }

    @Override
    public void resize(int width, int height) {
        backgroundViewport.update(width, height, true);
        viewport.update(width, height, false);
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
    public void dispose() {

    }

    private void createGraphUi(GameGraph gameGraph) {
        nodes = new Array<>(gameGraph.getVertices().size);
        for (GameVertex vertex : gameGraph.getVertices().values()) {
            UiNode node = uiObjectFactory.createUiNode(vertex);
            node.addListener(nodeClickListener);

            Vector2 position = vertex.getPosition();
            node.setPosition(position.x, position.y);
            nodes.add(node);
            nodesMap.put(node.getModel().getName(), node);
        }

        Array<GameEdge> edges = gameGraph.getEdges();
        this.edges = new Array<>(edges.size);
        for (GameEdge edge : edges) {
            UiEdge uiEdge = uiObjectFactory.createUiEdge(
                nodesMap.get(edge.getFrom().getName()),
                nodesMap.get(edge.getTo().getName())
            );
            this.edges.add(uiEdge);
            stage.addActor(uiEdge);
        }

        for (UiNode node : nodes) {
            stage.addActor(node);
        }
    }

    private void createButtons() {
        GameSettings gameSettings = getGameManager().gameSettings;

        int virtualScreenWidth = gameSettings.getVirtualScreenWidth();
        int virtualScreenHeight = gameSettings.getVirtualScreenHeight();
        int startPadding = 300;
        int padding = 260;
        int startX = 16;

        emptyButton = uiObjectFactory.createEmptyButton();
        emptyButton.setPosition(startX, virtualScreenHeight - startPadding);
        emptyButton.addListener(emptyButtonListener);

        emitButton = uiObjectFactory.createEmitButton();
        emitButton.setPosition(startX, virtualScreenHeight - (startPadding + padding));
        emitButton.addListener(emitButtonListener);

        freezeButton = uiObjectFactory.createFreezeButton();
        freezeButton.setPosition(startX, virtualScreenHeight - (startPadding + padding * 2));
        freezeButton.addListener(freezeButtonListener);

        burnTimeButton = uiObjectFactory.createBurnTimeButton();
        burnTimeButton.setPosition(startX, virtualScreenHeight - (startPadding + padding * 3));
        burnTimeButton.addListener(burnTimeButtonListener);

        stage.addActor(emptyButton);
        stage.addActor(emitButton);
        stage.addActor(freezeButton);
        stage.addActor(burnTimeButton);

        //
        float centerX = virtualScreenWidth / 2f;
        float centerY = virtualScreenHeight / 2f;

        restartButton = uiObjectFactory.createRestartButton();
        restartButton.setPosition(
            centerX - restartButton.getWidth() / 2f,
            centerY - restartButton.getHeight() / 2f
        );
        restartButton.setVisible(false);
        restartButton.addListener(restartButtonListener);

        nextButton = uiObjectFactory.createNextButton();
        nextButton.setPosition(
            centerX - nextButton.getWidth() / 2f,
            centerY - nextButton.getHeight() / 2f
        );
        nextButton.setVisible(false);
        nextButton.addListener(nextButtonListener);

        stage.addActor(restartButton);
        stage.addActor(nextButton);
    }

    private void createTime(Game game, GameSettings gameSettings) {
        uiTime = uiObjectFactory.createUiTime(game.getGameTime());
        uiTime.setScale(0.5f);
        uiTime.setPosition(gameSettings.getVirtualScreenWidth() - 125, 10);
        stage.addActor(uiTime);
    }

}
