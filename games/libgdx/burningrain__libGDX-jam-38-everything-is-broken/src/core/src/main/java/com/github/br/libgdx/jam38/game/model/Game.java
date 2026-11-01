package com.github.br.libgdx.jam38.game.model;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ObjectMap;
import com.github.br.libgdx.jam38.game.model.action.GameAction;
import com.github.br.libgdx.jam38.game.model.action.GameEdgeAction;
import com.github.br.libgdx.jam38.game.model.action.GameVertexAction;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;

public class Game {

    private final GameGraphLoader gameGraphLoader;

    private GameGraph gameGraph;
    private GameTime gameTime;
    private Array<GameVertex> gameVertices;

    private final Array<GameAction> inGameActions = new Array<>();

    public Game(GameGraphLoader gameGraphLoader) {
        this.gameGraphLoader = gameGraphLoader;
    }

    public void loadGraph(String path) {
        gameGraph = gameGraphLoader.loadGraph(path);
        gameTime = new GameTime(gameGraph.getTimeSeconds());
        gameVertices = gameGraph.getVertices().values().toArray();
        inGameActions.clear();
    }

    public GameGraph getGameGraph() {
        return gameGraph;
    }

    public void addGameAction(GameAction gameAction) {
        inGameActions.add(gameAction);
    }

    public GameDelta tick(float delta) {
        int lastTimeSec = gameTime.getTimerSec();
        boolean isTimeOver = gameTime.isTimeOver();
        boolean isGameOver = false;

        ObjectMap<String, GameVertex> vertices = gameGraph.getVertices();
        boolean isGameVictory = isGameVictory(gameGraph.getTargets(), vertices);

        Array<VertexDelta> vertexDelta = null;
        Array<GameAction> appliedActions = new Array<>();
        if (!isTimeOver && !isGameVictory) {
            appliedActions = handleActions(inGameActions, gameGraph, gameTime); // actions могут менять время
            vertexDelta = calculateGraph(gameVertices);
            inGameActions.clear();

            gameTime.tick(delta); // таймер меняет время
            isTimeOver = gameTime.isTimeOver();
            isGameOver = isGameOver(gameVertices);
        }

        int deltaTime = gameTime.getTimerSec() - lastTimeSec;
        return new GameDelta(isTimeOver, deltaTime, isGameVictory, isGameOver, vertexDelta, appliedActions);
    }

    public GameTime getGameTime() {
        return gameTime;
    }

    private Array<VertexDelta> calculateGraph(Array<GameVertex> vertices) {
        for (GameVertex vertex : vertices) {
            vertex.calculateCurrent();
        }

        Array<VertexDelta> vertexDeltaArray = new Array<>(vertices.size);
        for (GameVertex vertex : vertices) {
            VertexDelta vertexDelta = vertex.calculateFinal();
            vertexDeltaArray.add(vertexDelta);
        }

        return vertexDeltaArray;
    }

    private Array<GameAction> handleActions(Array<GameAction> inGameActions, GameGraph gameGraph, GameTime gameTime) {
        Array<GameAction> appliedActions = new Array<>(inGameActions.size);
        ObjectMap<String, GameVertex> vertices = gameGraph.getVertices();
        for (GameAction inGameAction : inGameActions) {
            gameTime.reduceTime(inGameAction.getTimeCost());

            if (inGameAction.isVertexAction()) {
                GameVertexAction vertexAction = inGameAction.asVertexAction();
                GameVertex gameVertex = vertices.get(vertexAction.getTargetName());
                vertexAction.execute(gameVertex);
            } else if (inGameAction.isEdgeAction()) {
                GameEdgeAction edgeAction = inGameAction.asEdgeAction();
                GameVertex from = vertices.get(edgeAction.getFrom());
                GameVertex to = vertices.get(edgeAction.getTo());
                edgeAction.execute(from, to);
            }
            appliedActions.add(inGameAction);
        }

        return appliedActions;
    }

    private boolean isGameVictory(Array<GameVertex> targets, ObjectMap<String, GameVertex> vertices) {
        boolean result = true;
        for (GameVertex target : targets) {
            GameVertex actual = vertices.get(target.getName());
            result = result & (target.getEnergy() <= actual.getEnergy());
        }

        return result;
    }

    private boolean isGameOver(Array<GameVertex> targets) {
        for (GameVertex target : targets) {
            if (target.getEnergy() <= 0f) {
                return true;
            }
        }
        return false;
    }

}
