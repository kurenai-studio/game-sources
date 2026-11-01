package com.alligatorX.game.model;

public class TimeManager {

    private float remainingTime; // Remaining time for a word, return every frame
    private float decrementAmount; // How much to decrement to increase game difficulty
    private float minTimeFloor; // How low the time limit should be (avoid being impossible)
    private float timePerChar; // Dynamic difficulty, time to type per character

    // Constructor
    public TimeManager() {
        this.remainingTime = 0f; // Will get filed when first word is loaded
        this.decrementAmount = 0.1f; // The decrement amount is set to decrease 0.1s
        this.minTimeFloor = 0.1f; // Lowest possible time for a single character is set to 0.1s
        this.timePerChar = 1.0f; // Original Time per character is set to 1.0s

    }

    // Getters method
    public float getRemainingTime() {
        return this.remainingTime;
    }

    public float getTimePerChar() {
        return this.timePerChar;
    }

    public float getDecrementAmount() {
        return this.decrementAmount;
    }

    public float getMinTimeFloor() {
        return this.minTimeFloor;
    }

    // Call every single frame to subtract time
    public void updateTimer(float deltaTime) {
        this.remainingTime -= deltaTime;
    }

    // Check if it is timeout for the word
    public boolean isTimeUp() {
        return this.remainingTime <= 0;
    }

    // Call to shrink the time limit
    public void shrinkTimeLimit() {
        // Ensure even if that the result of timePerChar - decrementAmount is 0.45f, it converts to max, which is minTimeFloor
        this.timePerChar = Math.max(this.minTimeFloor, this.timePerChar - this.decrementAmount);
    }

    // Reset the timer for each new word
    public void resetTimerForNewWord(int wordLength) {
        this.remainingTime = wordLength * this.timePerChar;
    }

}
