package com.alligatorX.game.model;

public class Player {
    private int currentPosition; // Current position of the player at the ladder
    private int checkpointPosition; // Last word position, if player typo, drop down to this position
    private int totalTypos; // Count how many typos the player has made in a game

    // Constructor didn't take any value, cuz player always start everything from 0
    public Player() {
        this.currentPosition = 0;
        this.checkpointPosition = 0;
        this.totalTypos = 0;
    }

    // Getters method
    public int getCurrentPosition() {
        return this.currentPosition;
    }

    public int getCheckpointPosition() {
        return this.checkpointPosition;
    }

    public int getTotalTypos() {
        return this.totalTypos;
    }

    // Player move up a single position
    public void climbUp() {
        this.currentPosition++;
    }

    // Save the checkpoint
    public void saveCheckpoint() {
        this.checkpointPosition = this.currentPosition;
    }

    // If player typo, drop to last checkpoint
    public void revertToCheckpoint() {
        this.currentPosition = this.checkpointPosition;
    }

    // Increment typo count for tracking
    public void addTypoCount() {
        this.totalTypos++;
    }

}
