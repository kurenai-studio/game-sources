package com.alligatorX.game.controller;

import com.alligatorX.game.model.ScoreRequest;
import com.badlogic.gdx.utils.Array;

// Handle network request in the background without freezing the screen
public interface LeaderboardCallback {
    // Trigger when successfully return scores
    // To be rendered in to Table UI
    void onScoresFetched(Array<ScoreRequest> scores);

    // Trigger when network request fails
    void onError(String errorMessage);
}
