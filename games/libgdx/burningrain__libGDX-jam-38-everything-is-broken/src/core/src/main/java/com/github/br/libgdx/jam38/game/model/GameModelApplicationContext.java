package com.github.br.libgdx.jam38.game.model;

import com.badlogic.gdx.utils.Json;
import com.badlogic.gdx.utils.JsonWriter;

public class GameModelApplicationContext {

    private final Json json;
    private final Game game;

    public GameModelApplicationContext() {
        json = new Json(JsonWriter.OutputType.json);
        GameVertexProxyFactory gameVertexProxyFactory = new GameVertexProxyFactoryImpl();
        GameGraphLoader gameGraphLoader = new GameGraphLoader(gameVertexProxyFactory, json);
        game = new Game(gameGraphLoader);
    }

    public Json getJson() {
        return json;
    }

    public Game getGame() {
        return game;
    }

}
