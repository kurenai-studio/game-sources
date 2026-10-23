import { TETRIS } from "./TETRIS";
import { ShapeFn } from "./ShapeFn";


window['board'] = {};

export class Game extends TETRIS {

    turnLength: number = 60;
    turnCounter: number = 0;

    isUpdatingAfterRowClear: boolean = false;

    nextShape: any = null;
    activeShape: any = null;

    cursors: any = null;

    completedRows: Array<any> = [];

    stateKey: string = "Game";

    stage: Object = {
        backgroundColor: 0x171642
    };

    tetris: TETRIS;

    activeScene: Phaser.Scene;

    constructor() {
        super();
    }

    create(scope) {

        this.activeScene = scope;
        var i, j;

        // Create background
        this.stage['backgroundColor'] = 0x171642;
        scope.add.sprite(0, 0, 'background').setOrigin(0, 0);
        scope.add.sprite(0, 0, 'banner').setOrigin(0, 0);

        // Create an empty board filled with nulls
        // Tetris.board = new Array(Tetris.BOARD_HEIGT);

        window['board'] = new Array(this.BOARD_HEIGHT);

        for (i = 0; i < this.BOARD_HEIGHT; i++) {
            window['board'][i] = new Array(this.BOARD_WIDTH);
            for (j = 0; j < this.BOARD_WIDTH; j++) {
                window['board'][i][j] = null;
            }
        }
        // console.log(window['board']);
        // console.log("**********");

        // debugger;

        // Retrieve blockPositions
        // this.shapesJSON = this.game.cache.getJSON('shapes');
        // this.shapes = this.shapesJSON;

        // Set turn length and counter
        this.isUpdatingAfterRowClear = false;
        this.turnLength = 60;
        this.turnCounter = 0;

        this.cursors = scope.input.keyboard.createCursorKeys();

        // Create Shapes
        this.nextShape = new ShapeFn();
        this.nextShape.randomizeShape();
        this.nextShape.preview();

        this.activeShape = new ShapeFn();
        this.activeShape.randomizeShape();
        this.activeShape.activate(this.activeScene);
    }

    update() {
        if (this.turnCounter >= this.turnLength) {
            if (this.activeShape !== null && this.activeShape.canMoveShape(this.DOWN)) {
                this.activeShape.moveShape(this.DOWN);
            } else {
                this.activeShape.placeShapeInBoard();
                this.completedRows = this.getCompleteRows();

                if (this.completedRows.length > 0) {
                    this.clearRow(this.completedRows);
                    this.isUpdatingAfterRowClear = true;
                } else {
                    this.promoteShapes();
                }
                this.completedRows = [];
            }
            this.turnCounter = 0;

        } else if (this.isUpdatingAfterRowClear) {

            if (this.turnCounter >= this.turnLength / 10) {
                this.isUpdatingAfterRowClear = false;
                this.promoteShapes();
            } else {
                this.turnCounter++;
            }
        } else {
            this.handleInput();
            this.turnCounter++;
        }
    }

    handleInput() {
        // let cursors = this.input.keyboard.createCursorKeys();
        if (this.activeShape.isTweening) {
            this.activeShape.updateTween();
        } else if (this.cursors.up.isDown) {

            if (this.activeShape.canRotate()) {
                this.activeShape.rotate();
            }
        } else if (this.cursors.left.isDown) {
            if (this.activeShape.canMoveShape(this.LEFT)) {
                this.activeShape.moveShape(this.LEFT);
                this.activeShape.isTweening = true;
            }
        } else if (this.cursors.right.isDown) {
            if (this.activeShape.canMoveShape(this.RIGHT)) {
                this.activeShape.moveShape(this.RIGHT);
                this.activeShape.isTweening = true;
            }
        } else if (this.cursors.down.isDown) {
            this.turnCounter += this.turnLength / 5;
        }
    }

    promoteShapes() {
        this.activeShape = null;
        this.nextShape.clearPreview();
        this.activeShape = this.nextShape;
        this.activeShape.activate(this.activeScene);

        this.nextShape = new ShapeFn();
        this.nextShape.randomizeShape();
        this.nextShape.preview();
    }

    getCompleteRows() {
        var j, max;
        var completeRows: Array<any> = [];

        for (let i: any = 0; i < window['board'].length; i++) {
            if (this.isRowFull(i)) {
                completeRows.push(i);
            }
        }
        return completeRows;
    }

    isRowFull(row) {
        var i;
        for (i = 0; i < window['board'][row].length; i++) {
            if (window['board'][row][i] === null) {
                return false;
            }
        }
        return true;
    }

    clearRow(completedRows) {
        var i, j, h, row, block, alreadyShifted, actualRowToClear;
        alreadyShifted = 0;
        for (i = completedRows.length - 1; i >= 0; i--) {
            actualRowToClear = completedRows[i] + alreadyShifted;
            row = window['board'][actualRowToClear];
            for (j = 0; j < row.length; j++) {
                window['board'][actualRowToClear][j].clean();
                window['board'][actualRowToClear][j] = null;
            }
            this.dropRowsAbove(actualRowToClear - 1);
            alreadyShifted++;
        }
    }

    dropRowsAbove(row) {
        var i, j, block;
        for (i = row; i >= 0; i--) {
            for (j = 0; j < window['board'][i].length; j++) {

                block = window['board'][i][j];
                if (block !== null) {
                    window['board'][i][j].moveBlock(block.x, block.y + 1);
                    window['board'][i + 1][j] = window['board'][i][j];
                    window['board'][i][j] = null;
                }
            }
        }
    }

    setupSounds() {

    }
} 