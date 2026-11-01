import AGameServer from "../services/agameserver.js";
import Log from '../services/log.js';

/********************************
  Mock Game Server for Testing 
  v 0.01 Mister Barista
 ********************************/

let _Coins = 100;
var _CurrentTarget = "";
var _Cups = ["Latte", "Cuppucino", "Americano"];
var _Seed = 12;
var _HighScores = [
    {
        name:"jonl", 
        score:59
    },
    {
        name:"jane",
        score:120
    }
];

class MockGameServer extends AGameServer {    

    constructor() {
        super('GameServer');
        //Instance = this;        
    }    

    static get GameID() {
        return _GameID;
    }

    static GetWin(cup) {
        Log( "Player selected : " + cup.ObjectID + " --- Current Game is :" + _CurrentTarget);
        return MockGameServer._Instance.calculateWin(cup);
    }

    static GetCoins() {
        return _Coins;
    }

    static CreateGame() {                
        return MockGameServer._Instance.createGame();
    }

    /**
     * Create a new game
     * @param {*} reinit : reinitialize assets, false = pooling
     */
    static NewGame(reinit) {        
        return MockGameServer._Instance.newGame(reinit);
    }

    static EndGame() {
        Log("ending game");
        _HighScores.push( { name:"player", score:_Coins } );
        return true;
    }

    static GetScores() {
        return _HighScores;
    }    

    create() {        
    }

    createGame() {
        Log( "MockGameServer:createGame");
        _Coins = 100;        
        super.createGame();
    }

    newGame(reinit) {
        Log( "MockGameServer:newGame");
        var n = MockGameServer.getRndInteger(0,_Cups.length-1);
        _CurrentTarget = _Cups[n];
        Log("Current Target:" + _CurrentTarget);
        super.newGame(reinit);
    }

    /**
     * A number generator that should return a 'perfect' game, 
     * ie balanced odds of winning and losing 
     * @param {*} min 
     * @param {*} max 
     */
    static getRndInteger(min, max) {
        //return Math.floor(Math.random() * (max - min + 1) ) + min; //steady loss?
        var x = Math.sin(_Seed++) * 10000;
        return Math.floor((x - Math.floor(x))* (max - min + 1)) + min; //steady value
      }

    /**
     * Did the player win? Give them a coin
     * Lose? take a coin
     * @param {*} ChosenOne 
     */
    calculateWin(cup)  {        
        let result = false;
        if ( cup.ObjectID === _CurrentTarget ) {
            _Coins++;
            result = true;            
        }
        else 
        {
            _Coins>0 ? _Coins-- : _Coins = 0;        
            result = false;
        };        
        super.calculateWin(cup,result);
        return result;
    }
}

export default MockGameServer;