const wordController = {
    canvas: document.getElementById('demo'),
    wordsList: ["hi", "job", "two", "meet", "test", "hobby"],
    initWordsList() {
        fetch('words.txt')
            .then(response => response.text())
            .then(text => {
                this.wordsList = text.split(" ")
                this.shuffleArray(this.wordsList)
            })
    },
    createEnemyWordElement() {
        const word = this.wordsList.shift()
        let wordElement = document.createElement("div")
        wordElement.innerHTML = word
        wordElement.classList.add("enemyText")
        this.canvas.appendChild(wordElement);
        return {
            health: word.length,
            word: word.split(''),
            wordElement: wordElement
        }
    },
    shuffleArray(array) {
        for (let i = array.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [array[i], array[j]] = [array[j], array[i]];
        }
    }
}

export { wordController }