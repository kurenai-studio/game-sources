package com.alligatorX.game.model;

public class WordProcessor {
    private String targetWord; // The current word the user need to type
    private int currentIndex; // In which character index the user currently are

    // Constructor
    public WordProcessor(String firstTargetWord) {
        this.targetWord = firstTargetWord; // The first word is passed from GameController
        this.currentIndex = 0; // Index always start from 0
    }

    // Getters method
    public String getTargetWord() {
        return this.targetWord;
    }

    public int getCurrentIndex() {
        return this.currentIndex;
    }

    // Load the next word for the player to type after completed the previous word
    public void loadNextWord(String newWord) {
        this.targetWord = newWord;
        this.resetIndex();
    }

    // Reset the index for every new words
    public void resetIndex() {
        this.currentIndex = 0;
    }

    // Count how many letter the player typed correctly
    public int getCorrectLetterCount() {
        return this.currentIndex; // If player successfully typed two letter, index will be 2;
    }

    // Keystroke status enumerators
    public enum KeystrokeStatus {
        VALID_LETTER,
        WORD_COMPLETED,
        TYPO
    }

    // Check the keystroke status from the player
    public KeystrokeStatus checkKeystroke(char input) {
        // Compare the input with the current character
        if (input == this.targetWord.charAt(this.currentIndex)) {

            this.currentIndex++; // If match character, move the index forward

            // If currentIndex match with target word length, then the word is completed
            if (this.currentIndex == this.targetWord.length()) {
                return KeystrokeStatus.WORD_COMPLETED;
            }

            // If input match with currentIndex, then it is a valid letter
            return KeystrokeStatus.VALID_LETTER;
        } else {
            // If not, then it is a typo
            return KeystrokeStatus.TYPO;
        }
    }

}
