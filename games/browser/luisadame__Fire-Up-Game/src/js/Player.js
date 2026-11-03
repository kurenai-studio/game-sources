let player = {
    score: 0,
    lost: false,
    name: '',
    playing: false,
    reset: function () {
        this.score = 0;
        this.lost = false;
        this.playing = true;
    }
}

export default player;
