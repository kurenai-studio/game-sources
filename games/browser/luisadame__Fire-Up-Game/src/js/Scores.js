function Scores() {
    this.db = 'scores';
    this.dataProvider = 'localStorage';
}

Scores.prototype.all = function () {
    const scores = window[this.dataProvider].getItem(this.db);
    return JSON.parse(scores);
}

Scores.prototype.update = function (scores) {
    window[this.dataProvider].setItem(this.db, JSON.stringify(scores));
}

Scores.prototype.get = function (name) {
    return this.all() ? this.all()[name] : 0;
}

Scores.prototype.zip = function () {
    let zipped = [];
    const scores = this.all();
    if (!scores) return zipped;
    for (let name of Object.keys(scores)) {
        zipped.push({
            name: name,
            score: scores[name]
        })
    }
    zipped.sort((a, b) => +b.score - +a.score);
    return zipped;
}

Scores.prototype.set = function (name, score) {
    const scores = this.all() || {};
    if (scores[name] > score) return;
    scores[name] = score;
    this.update(scores);
}

export default Scores;
