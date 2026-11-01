/**
 * Abstract Game Server Base Class
 */
export default class AGameServer extends Phaser.Scene {    

    constructor() {
        super();
        AGameServer._GameID = 1;
        AGameServer._Instance = this;
    }

    /**
     * callback handler for server events completion, typeof AGame
     * @param {*} handler : AGame
     */
    static RegisterHandler(handler){
        AGameServer._handler = handler
    } 

    static GetCoins() {
        return 0
    }
    static GetScores() {
        return [];
    }  

    createGame() {
        AGameServer._handler.onGameCreated()
    }

    newGame(reinit) {
        AGameServer._handler.onNewGameReady(reinit)
    }

    calculateWin(cup,result)  {
        AGameServer._handler.onGetWinResponse(cup,result)
    }
    
    static GetWin() {}
}