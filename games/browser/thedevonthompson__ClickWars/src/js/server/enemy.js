let Center = require('./center.js');
let Engine = require('./engine.js');

let Enemy = {

    idGen: function() {
        // Unique-ish ID's for enemys
        // Barely millisecond unique, but
        // should fine for my purposes.
        return new Date().valueOf();
    },

    list: [],

    inherit: function(obj) {
        obj.id = Enemy.idGen();

        let pos = Enemy.getRandomEdgePos();
        obj.x = pos[0];
        obj.y = pos[1];

        obj.getDistanceTo = function(tx, ty) {
            return Engine.getDistance(this.x, tx, this.y, ty) - this.radius / 2;
        }

        obj.updateDistanceTo = function(tx, ty) {
            this.distance = this.getDistanceTo(tx, ty);
        }
        obj.updateDistanceTo(Center.x, Center.y);

        obj.decrementHealth = function(amount) {
            this.health -= amount;
            if (this.health <= 0) {
                Enemy.removeById(this.id);
            }
        }
    },

    createBasic: function() {
        this.type = "basic";
        this.color = "red";
        this.speed = 1;
        this.radius = 10;
        this.health = 2;

        Enemy.inherit(this);
        Enemy.setMoveType.Basic(this);

        Enemy.list.push(this);
    },

    createFast: function() {
        this.type = "fast";
        this.color = "purple";
        this.speed = 4;
        this.radius = 14;
        this.health = 1;

        Enemy.inherit(this);
        Enemy.setMoveType.Basic(this);

        Enemy.list.push(this);
    },

    createEnemy: function(type) {
        let cost = NaN;

        switch (type) {
            case "createBasic":
                cost = 40;
                break;
            case "createFast":
                cost = 120;
                break;
        }

        if (typeof cost != NaN && Engine.Gm.resources >= cost) {
            Engine.Gm.spendResources(cost);
            Engine.Gm.addIncome(cost / 20);
            let enemy = new Enemy[type];
        }
    },

    move: function() {
        Enemy.list.map(function(enemy, index) {

            // Move enemy
            enemy.move();

            // Update enemy distance to the center.
            enemy.updateDistanceTo(Center.x, Center.y);

            // Circle collision detection
            if (enemy.distance <= Center.size) {
                Enemy.removeById(enemy.id);
                Center.health--;
            }
        });
    },

    hurtEnemy: function(id, amount) {
        Enemy.list.some(function(enemy, index) {
            if (enemy.id === id) {
                enemy.decrementHealth(amount);
                return true;
            }
        });
    },

    setMoveType: {

        // Move in a straight line, at a constant speed, towards the center.
        Basic: function(obj) {
            obj.move = function() {
                this.x += ( Center.x - this.x ) / this.distance * this.speed;
                this.y += ( Center.y - this.y ) / this.distance * this.speed;
            }
        },

        // This movement type is horrible, especially at high speeds.
        Random: function(obj) {
            obj.move = function() {
                // Generate a random point thats closer to the center.
                let newPos = [];
                let newDistance = -1;
                do {
                    newPos = Enemy.getRandomMovePos(this.x, this.y, this.speed);
                    newDistance = Engine.getDistance(newPos[0], Center.x, newPos[1], Center.y) + this.radius;
                }
                while (newDistance >= this.distance);

                this.x = newPos[0];
                this.y = newPos[1];
            }
        }
    },

    getRandomEdgePos: function() {
        // Returns array, index 0 is x coord, index 1 is y coord.
        let edge = Engine.getRandomInteger(1, 4);

        if (edge === 1) {
            // Edge is top
            return [0, Engine.getRandomInteger(0, Engine.Canvas.height)];
        } else if (edge === 2) {
            // Edge is right
            return [Engine.getRandomInteger(0, Engine.Canvas.width), Engine.Canvas.height];
        } else if (edge === 3) {
            // Edge is bottom
            return [Engine.Canvas.width, Engine.getRandomInteger(0, Engine.Canvas.height)];
        } else if (edge === 4) {
            // Edge is left
            return [Engine.getRandomInteger(0, Engine.Canvas.width), 0];
        }
    },

    getRandomMovePos: function(x, y, speed) {
        // Returns array, index 0 is x coord, index 1 is y coord.
        return [x + Engine.getRandomInteger(-1 * speed, speed + 1), y + Engine.getRandomInteger(-1 * speed, speed + 1)]
    },

    removeById: function(id) {
        Enemy.list.some(function(enemy, index) {
            if (enemy.id === id) {
                Enemy.list.splice(index, 1);
                return true;
            }
        });
    }
}

module.exports = Enemy;