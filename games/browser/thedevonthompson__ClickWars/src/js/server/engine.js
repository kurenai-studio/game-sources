let Client = require('./client.js');

let Engine = {

    serverIntervalId: null,
    serverIntervalSpeed: 20,

    // Enemy spawning interval id for testing purposes.
    enemyTestingId: NaN,

    Canvas: {
        width: 1000,
        height: 600,
        id: "ClickWars",
        containerId: "game",
        drawIntervalSpeed: 10,

        colorList: ['Black', 'Blue', 'Red', 'Green', 'Orange', 'Pink', 'Cyan', 'Purple', 'Gold', 'Grey', 'LightBlue', 'DarkGreen', 'Brown']
    },

    Gm: {

        resources: 0,
        resourceCap: NaN,

        baseIncome: NaN,
        extraIncome: 0,

        addIncome: function(amount) {
            this.extraIncome += amount;
            this.updateBaseIncome();
        },

        calcIncome: function () {
            return this.baseIncome + this.extraIncome;
        },

        updateBaseIncome: function() {
            this.baseIncome = (Client.playerList.length - 1) * 20;
            this.resourceCap = this.calcIncome() * 8;
        },

        resourceUpdate: function() {
            if (this.resources < this.resourceCap) {
                this.resources += this.calcIncome();
                if (this.resources > this.resourceCap) {
                    this.resources = this.resourceCap;
                }
            }
        },

        spendResources: function(amount) {
            this.resources -= amount;
        },

        intervalId: NaN,
        intervalSpeed: 1000
    },

    getDistance: function(x1, x2, y1, y2) {
        return Math.sqrt( (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2) )
    },

    // Minimum is inclusive, maximum is exclusive.
    getRandomInteger: function(min, max) {
        return ( Math.floor( Math.random() * (max - min) ) + min );
    },

    getRandomBool: function() {
        return ( Math.random() >= 0.5 );
    }

};

module.exports = Engine;