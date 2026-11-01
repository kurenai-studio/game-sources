package com.alligatorX.game.controller;

import com.alligatorX.game.model.ScoreRequest;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Net;
import com.badlogic.gdx.net.NetJavaImpl;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Json;

public class NetworkManager {
    // Where spring boot backend listening for requests
    private static final String BASE_URL = "http://localhost:8080/api/scores/unlimited";

    // LibGDX tool to help converting Java objects to JSON and back
    private final Json json = new Json();

    public NetworkManager() {
        // Force JSON to use double quotes around keys
        json.setOutputType(com.badlogic.gdx.utils.JsonWriter.OutputType.json);
    }

    // Write path: send new score to database
    public void submitScore(String playerName, int score, int typos) {

        // Pack raw data into Java object
        ScoreRequest data = new ScoreRequest(playerName, score, typos);

        // Convert to Java object to JSON string so Internet can understand
        String jsonContent = json.toJson(data);
        System.out.println("Sending JSON: " + jsonContent);

        // Set up "POST" request to tell server we are sending data
        Net.HttpRequest request = new Net.HttpRequest(Net.HttpMethods.POST);
        request.setUrl(BASE_URL);
        request.setHeader("Content-Type", "application/json"); // Tell server to expect JSON
        request.setContent(jsonContent); // Attach JSON string

        // Send request in background so game doesn't freeze
        new NetJavaImpl().sendHttpRequest(request, new Net.HttpResponseListener() {
            @Override
            public void handleHttpResponse(Net.HttpResponse httpResponse) {
                System.out.println("Score submitted successfully!");
            }

            @Override
            public void failed(Throwable throwable) {
                System.out.println("Failed to submit score: " + throwable.getMessage());
            }

            @Override
            public void cancelled() {

            }
        });
    }

    // Read path: get top 10 scores to show on screen
    public void fetchLeaderboard(final LeaderboardCallback callback) {
        // Set up "GET" request to ask server for data
        Net.HttpRequest request = new Net.HttpRequest(Net.HttpMethods.GET);
        request.setUrl(BASE_URL + "/top10");

        // Send request in background
        new NetJavaImpl().sendHttpRequest(request, new Net.HttpResponseListener() {
            @Override
            public void handleHttpResponse(Net.HttpResponse httpResponse) {
                // Get the raw JSON text the server sent back
                String jsonResponse = httpResponse.getResultAsString();

                // Convert JSON array back to Java object
                try {
                    Array<ScoreRequest> topScores = json.fromJson(Array.class, ScoreRequest.class, jsonResponse);

                    // Send the data back to main thread safely
                    Gdx.app.postRunnable(new Runnable() {
                        @Override
                        public void run() {
                            callback.onScoresFetched(topScores);
                        }
                    });

                    System.out.println("Successfully parsed: " + topScores.size + " scores!");

                    for (ScoreRequest s : topScores) {
                        System.out.println(s.playerName + " - " + s.score);
                    }
                } catch (Exception e) {
                    Gdx.app.postRunnable(() -> callback.onError("Failed to parse data"));
                }
            }

            @Override
            public void failed(Throwable throwable) {
                Gdx.app.postRunnable(() -> callback.onError("Network Error"));
            }

            @Override
            public void cancelled() {}
        });
    }
}
