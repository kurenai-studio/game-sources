package com.github.br.libgdx.jam38.game.model.dto;

import com.badlogic.gdx.utils.Array;

public class JsonGraph {

    private int timeSeconds;
    private Array<JsonVertex> vertices = new Array<>();
    private Array<JsonEdge> edges = new Array<>();
    private Array<JsonVertex> targets = new Array<>();

    public Array<JsonVertex> getVertices() {
        return vertices;
    }

    public void setVertices(Array<JsonVertex> vertices) {
        this.vertices = vertices;
    }

    public Array<JsonEdge> getEdges() {
        return edges;
    }

    public void setEdges(Array<JsonEdge> edges) {
        this.edges = edges;
    }

    public int getTimeSeconds() {
        return timeSeconds;
    }

    public void setTimeSeconds(int timeSeconds) {
        this.timeSeconds = timeSeconds;
    }

    public Array<JsonVertex> getTargets() {
        return targets;
    }

    public void setTargets(Array<JsonVertex> targets) {
        this.targets = targets;
    }

}
