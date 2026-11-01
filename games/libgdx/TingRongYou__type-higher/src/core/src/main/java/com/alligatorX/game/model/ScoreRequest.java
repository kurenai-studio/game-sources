package com.alligatorX.game.model;

// Hold data while it travels between server and game
public class ScoreRequest {
    public String playerName;
    public Integer score;
    public Integer typos;

    public ScoreRequest() {}

    public ScoreRequest(String playerName, int score, int typos) {
        this.playerName = playerName;
        this.score = score;
        this.typos = typos;
    }
}
