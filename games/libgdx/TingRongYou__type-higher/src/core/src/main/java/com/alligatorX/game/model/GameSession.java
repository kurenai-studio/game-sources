package com.alligatorX.game.model;

public class GameSession {

    private int targetLength; // How many words the player choose (30, 60, 90, unlimited)
    private int wordCompleted; // How many words player has completed

    // Constructor
    public GameSession(int targetLength) {
        this.targetLength = targetLength; // How many words is decided by the player
        this.wordCompleted = 0; // Always starts at 0
    }

    // Getters method
    public int getTargetLength() {
        return this.targetLength;
    }

    public int getWordCompleted() {
        return this.wordCompleted;
    }

    public void addWordCompleted() {
        this.wordCompleted++;
    }

    // Check if player has won the game
    public boolean isPlayerWon() {
        // If it is unlimited mode, always false
        if (this.targetLength == -1) {
            return false;
        }
        return this.wordCompleted >= this.targetLength; // Check if the word completed has more than the targetLength
    }


}
