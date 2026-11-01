package com.github.br.libgdx.jam38.game.model;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Json;
import com.badlogic.gdx.utils.ObjectMap;
import com.github.br.libgdx.jam38.game.model.action.edge.GameEdge;
import com.github.br.libgdx.jam38.game.model.dto.JsonEdge;
import com.github.br.libgdx.jam38.game.model.dto.JsonGraph;
import com.github.br.libgdx.jam38.game.model.dto.JsonVertex;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertexData;

public class GameGraphLoader {

    private final Json json;
    private final GameVertexProxyFactory gameVertexProxyFactory;

    public GameGraphLoader(GameVertexProxyFactory gameVertexProxyFactory, Json json) {
        this.gameVertexProxyFactory = gameVertexProxyFactory;
        this.json = json;
    }

    public GameGraph loadGraph(String path) {
        FileHandle level = Gdx.files.internal(path);
        JsonGraph jsonGraph = json.fromJson(JsonGraph.class, new String(level.readBytes()));

        ObjectMap<String, GameVertex> vertexes = new ObjectMap<>();
        for (JsonVertex vertex : jsonGraph.getVertices()) {
            vertexes.put(vertex.getName(), gameVertexProxyFactory.createProxy(convertVertex(vertex)));
        }

        Array<GameEdge> edges = new Array<>(jsonGraph.getEdges().size);
        for (JsonEdge edge : jsonGraph.getEdges()) {
            GameVertex from = vertexes.get(edge.getFrom());
            GameVertex to = vertexes.get(edge.getTo());

            from.addNeighbour(to);
            to.addNeighbour(from);

            edges.add(new GameEdge(from, to));
        }

        Array<GameVertex> targets = new Array<>();
        for (JsonVertex target : jsonGraph.getTargets()) {
            targets.add(gameVertexProxyFactory.createProxy(convertVertex(target)));
        }

        return new GameGraph(jsonGraph.getTimeSeconds(), vertexes, edges, targets);
    }

    private GameVertexData convertVertex(JsonVertex vertex) {
        GameVertexState state = vertex.getState() != null? vertex.getState() : GameVertexState.NONE;
        return new GameVertexData(
            vertex.getName(),
            new Vector2(vertex.getX(), vertex.getY()),
            vertex.getEnergy(),
            vertex.getEmissionPercent(),
            state,
            vertex.isFreeze()
        );
    }

}
