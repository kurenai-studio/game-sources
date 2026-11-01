import AGameServer from './agameserver.js';

/**
 * Not fully implemented for demo
 */
let _Instance = null;
let _Coins = 100;
export default class RealGameServer extends AGameServer {
    constructor() {
        super();
        _Instance = this;    
        console.log(" ****************************************** ");
        console.log("    REAL SERVER NOT IMPLEMENTED FOR DEMO    ");
        console.log(" ****************************************** ");
    }
    static CreateGame() {                
        return _Instance.createGame();
    }
     /**
     * Create a new game
     * @param {*} reinit : reinitialize assets, false = pooling
     */
    static NewGame(reinit) {        
        return _Instance.newGame(reinit);
    }

    static EndGame() {
        console.log("ending game");
        _HighScores.push( { name:"player", score:_Coins } );
        return true;
    }
}