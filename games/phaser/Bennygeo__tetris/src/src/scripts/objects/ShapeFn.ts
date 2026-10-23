import { TETRIS } from "./TETRIS";
import { Block } from "./Block";

export class ShapeFn extends TETRIS {
    type: any;
    orientation: any;
    color: any;

    centerX: any;
    centerY: any;

    shape: any;
    blocks: Array<any> = [];

    isTweening: boolean = false;
    tweenCounter: number = 0;

    tempCounter: number = 0;

    NUM_BLOCKS_IN_SHAPE: number;
    NUM_SHAPE_TYPES: number;
    NUM_ORIENTATIONS: number;

    I: Number = 0;
    J: Number = 1;
    L: Number = 2;
    O: Number = 3;
    S: Number = 4;
    Z: Number = 5;
    T: Number = 6;

    constructor() {
        super();

        this.type = null;
        this.orientation = null;
        this.color = null;

        this.centerX = null;
        this.centerY = null;

        this.shape = null;
        this.blocks = [];

        this.isTweening = false;
        this.tweenCounter = 0;

        this.tempCounter = 0;

        this.NUM_BLOCKS_IN_SHAPE = 4;
        this.NUM_SHAPE_TYPES = 7;
        this.NUM_ORIENTATIONS = 4;

        this.I = 0;
        this.J = 1;
        this.L = 2;
        this.O = 3;
        this.S = 4;
        this.Z = 5;
        this.T = 6;
    }

    randomizeShape() {
        this.type = Math.floor(Math.random() * this.NUM_SHAPE_TYPES);
        this.orientation = Math.floor(Math.random() * this.NUM_ORIENTATIONS);
        this.color = Math.floor(Math.random() * this.NUM_COLORS);

        this.initBlocks();
    };

    initBlocks() {

        var i;
        for (i = 0; i < this.NUM_BLOCKS_IN_SHAPE; i++) {
            this.blocks[i] = new Block();
        }
    }

    preview() {

        //TODO
    }

    clearPreview() {

        //TODO
    }

    activate(scope) {

        this.shape = this.shapesJSON['shapes'][this.type];
        // debugger;
        this.centerX = this.shape.orientation[this.orientation].startingLocation.x;
        this.centerY = this.shape.orientation[this.orientation].startingLocation.y;

        var i, newX, newY;

        for (i = 0; i < this.blocks.length; i++) {
            newX = this.centerX + this.shape.orientation[this.orientation].blockPosition[i].x;
            newY = this.centerY + this.shape.orientation[this.orientation].blockPosition[i].y;
            this.blocks[i].makeBlock(scope, newX, newY, this.color);
        }
    }

    clearActive() {

        this.type = null;
        this.orientation = null;
        this.color = null;

        this.centerX = null;
        this.centerY = null;

        this.blocks = [];
    }

    placeShapeInBoard() {

        var i, block;

        for (i = 0; i < this.blocks.length; i++) {
            block = this.blocks[i];
            window['board'][block.y][block.x] = this.blocks[i];
        }
    }

    isOnBoard(x, y) {

        if (x >= 0 && y >= 0 &&
            x < this.BOARD_WIDTH && y < this.BOARD_HEIGHT) {
            return true;
        }
        return false;
    }

    isOccupied(x, y) {

        // console.log(x, y);
        // console.log(window['board']);
        // console.log("----------");
        // debugger;
        if (window['board'][y][x] === null) {
            return false;
        }
        return true;
    }

    canMoveShape(direction) {

        var i, newX, newY;

        for (i = 0; i < this.blocks.length; i++) {
            switch (direction) {
                case this.DOWN:
                    newX = this.blocks[i].x;
                    newY = this.blocks[i].y + 1;
                    break;
                case this.LEFT:
                    newX = this.blocks[i].x - 1;
                    newY = this.blocks[i].y;
                    break;
                case this.RIGHT:
                    newX = this.blocks[i].x + 1;
                    newY = this.blocks[i].y;
                    break;
            }
            // console.log(this.blocks);

            if (!this.isOnBoard(newX, newY) || this.isOccupied(newX, newY)) {
                return false;
            }
        }
        return true;
    }

    moveShape(direction) {

        if (!this.canMoveShape(direction)) {
            throw "Cannot move active shape in direction: " + direction;
        }

        var i, newX, newY;

        // Move the Shape's blocks
        for (i = 0; i < this.blocks.length; i++) {
            switch (direction) {
                case this.DOWN:
                    newX = this.blocks[i].x;
                    newY = this.blocks[i].y + 1;
                    break;
                case this.LEFT:
                    newX = this.blocks[i].x - 1;
                    newY = this.blocks[i].y;
                    break;
                case this.RIGHT:
                    newX = this.blocks[i].x + 1;
                    newY = this.blocks[i].y;
                    break;
            }
            this.blocks[i].moveBlock(newX, newY);
        }

        // Update the Shape's center
        switch (direction) {
            case this.DOWN:
                this.centerX += 0;
                this.centerY += 1;
                break;
            case this.LEFT:
                this.centerX += -1;
                this.centerY += 0;
                break;
            case this.RIGHT:
                this.centerX += 1;
                this.centerY += 0;
                break;
        }
    }

    canRotate() {

        if (this.isTweening) {
            return false;
        }

        var i, newX, newY, newOrientation;
        newOrientation = (this.orientation + 1) % this.NUM_ORIENTATIONS;

        for (i = 0; i < this.blocks.length; i++) {
            newX = this.centerX + this.shape.orientation[newOrientation].blockPosition[i].x;
            newY = this.centerY + this.shape.orientation[newOrientation].blockPosition[i].y;

            if (!this.isOnBoard(newX, newY) || this.isOccupied(newX, newY)) {
                return false;
            }
        }
        return true;
    }

    rotate() {

        if (!this.canRotate()) {
            throw "Cannot rotate active shape";
        }

        var i, newX, newY, newOrientation;
        newOrientation = (this.orientation + 1) % this.NUM_ORIENTATIONS;
        for (i = 0; i < this.blocks.length; i++) {
            newX = this.centerX + this.shape.orientation[newOrientation].blockPosition[i].x;
            newY = this.centerY + this.shape.orientation[newOrientation].blockPosition[i].y;
            this.blocks[i].moveBlock(newX, newY);
        }
        this.orientation = newOrientation;
        this.isTweening = true;
    }

    updateTween() {

        if (this.tweenCounter > 10) {
            this.isTweening = false;
            this.tweenCounter = 0;
        }
        this.tweenCounter++;
    }

}