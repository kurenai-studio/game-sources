package com.github.br.libgdx.jam38.game.model;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ObjectMap;
import com.github.br.libgdx.jam38.game.model.action.edge.GameEdge;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;

public class GameGraph {

    private final int timeSeconds;
    private final ObjectMap<String, GameVertex> vertices;
    private final Array<GameEdge> edges;
    private Array<GameVertex> targets;

    public GameGraph(
        int timeSeconds,
        ObjectMap<String, GameVertex> vertices,
        Array<GameEdge> edges,
        Array<GameVertex> targets
    ) {
        this.timeSeconds = timeSeconds;
        this.vertices = vertices;
        this.edges = edges;
        this.targets = targets;
    }

    public int getTimeSeconds() {
        return timeSeconds;
    }

    public ObjectMap<String, GameVertex> getVertices() {
        return vertices;
    }

    public Array<GameEdge> getEdges() {
        return edges;
    }

    public Array<GameVertex> getTargets() {
        return targets;
    }

}
