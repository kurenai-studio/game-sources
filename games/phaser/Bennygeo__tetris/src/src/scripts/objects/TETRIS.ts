
import * as shapes from '../../assets/JSON/shapes.json';
import * as config from '../../assets/JSON/config.json';
import * as settings from '../../assets/JSON/settings.json';

export class TETRIS {

    /*
    * Title of the project
    */
    public static TITLE: "Tetris";

    /*
    * Title style properties
    */
    titleStyle: Object = {}

    /*
    * Button style properties
    */
    buttonTextColor: any;
    buttonTextOverColor: any;
    buttonStyle: Object;
    buttonActiveStyle: Object;

    // Asset Sizes
    BANNER_HEIGHT: number = 145;
    LINING_WIDTH: number = 5;
    BLOCK_WIDTH: number = 50;

    STAGE_WIDTH: Number = 800;
    STAGE_HEIGHT: number = 600;

    // Board Size
    BOARD_WIDTH: number = 10;
    BOARD_HEIGHT: number = 16;

    // Movement Directions
    DOWN: number;
    LEFT: number;
    RIGHT: number;

    // Block colors
    NUM_COLORS: number;
    GREEN: number;
    RED: number;
    BLUE: number;
    YELLOW: number;

    // Static Data for the position of Blocks within a Shape.
    // blockPositions[shapeType][orientation][blockNumber].x = (int) board positions away from Shape.centerX
    // in the x direction.
    shapesJSON: Object;
    settingsJSON: Object;
    configJSON: Object;

    shapes: any = {};

    // Declare the board.
    // board is a 2d array containing placed Blocks (active blocks are not in 
    // the board yet. It will be oriented with
    // blocks[0][0] in the top left and blocks[BOARD_HEIGHT-1][BOARD_WIDTH-1]
    // in the bottom right corner. Initialized in Tetris.Game.create(). 
    board: any = {};

    game: any;

    constructor() {

        // this.game = new Phaser.Scene(new Phaser.Game);
        this.game = {};
        this.board = {};

        this.DOWN = 0;
        this.LEFT = 1;
        this.RIGHT = 2;

        this.NUM_COLORS = 4;
        this.GREEN = 0
        this.RED = 1;
        this.BLUE = 2;
        this.YELLOW = 3;

        this.BANNER_HEIGHT = 55;
        this.LINING_WIDTH = 5;
        this.BLOCK_WIDTH = 50;

        this.BOARD_WIDTH = 10;
        this.BOARD_HEIGHT = 14;

        this.shapesJSON = shapes;
        this.settingsJSON = settings;
        this.configJSON = config;

        this.STAGE_WIDTH = this.configJSON['stage'].width;
        this.STAGE_HEIGHT = this.configJSON['stage'].height;

        this.titleStyle = { font: "72px Arial", fill: "#ffffff" };
        this.buttonTextColor = 0xffffff;
        this.buttonTextOverColor = 0xffff00;
        this.buttonStyle = { font: "32px Arial", fill: "#ffffff" };
        this.buttonActiveStyle = { font: "32px Arial", fill: "#ffffff", fontStyle: "italic" };
    }
}

export class DEFAULTS {
    public static BANNER_HEIGHT: 145;
    public static LINING_WIDTH: 5;
    public static BLOCK_WIDTH: 50;

    public static STAGE_WIDTH: Number = 800;
    public static STAGE_HEIGHT: number = 600;

    // Board Size
    public static BOARD_WIDTH: 10;
    public static BOARD_HEIGHT: 16;

    // Movement Directions
    public static DOWN: number;
    public static LEFT: number;
    public static RIGHT: number;

    // Block colors
    public static NUM_COLORS: number;
    public static GREEN: number;
    public static RED: number;
    public static BLUE: number;
    public static YELLOW: number;
}



