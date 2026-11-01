import os
import random


def getWord(wordLength):
    """
    Gets a random word of a specific length from the words.txt file.
    """
    # Build a path to words.txt that is relative to this file
    # This is much more reliable than a hardcoded path.
    dir_path = os.path.dirname(os.path.realpath(__file__))
    file_path = os.path.join(dir_path, "words.txt")

    with open(file_path, "r") as f:
        all_words = f.read().splitlines()

    wordList = [word for word in all_words if len(word) == wordLength]

    if not wordList:
        # Handle case where no words of the requested length are found
        raise ValueError(f"No words of length {wordLength} found in the dictionary.")

    word = random.choice(wordList)
    return word
