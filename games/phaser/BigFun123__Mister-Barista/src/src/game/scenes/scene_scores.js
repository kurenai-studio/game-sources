import GameState from '../state.js';
import ToggleButton from '../components/togglebutton.js';
import Constants from '../const.js';
import GameServer from '../../services/gameserver.js';

/*******************************
 *     Menu and Settings       *
 *******************************/
class ScoreScene extends Phaser.Scene {    
        
    constructor ()
    {
        super('ScoreScene');        
    }

    preload ()
    {
        this.load.setBaseURL('../../../assets/');
        this.load.image("sky2", "sky.jpg");
        this.load.image("back", "back.png");
    }

    create ()
    {
        this.add.image(400, 300, 'sky2');
        this.menuButton = new ToggleButton(this, 700, 25, 'back', this.startGame); 
        this.add.existing(this.menuButton);
        this.text = this.add.text(10, 10, Constants.gameName() + " " + Constants.version());
        this.showScores();
    }

    startGame(context) {
        context.scene.start("MenuScene", "from_scores");
    }

    showScores() {
        var scores = GameServer.GetScores();

        Object.entries(scores)
            .slice(0, 10)
            .map(([index, entry]) => {                
                this.text = this.add.text(280, 50 + index* 40, entry.name , { fontFamily: "Arial Black", fontSize: 34, color: "#964b00" });             
                this.text.setStroke('#e69b50', 4);
                this.text.setShadow(2, 2, '#333333', 2, true, false);

                this.text = this.add.text(440, 50 + index* 40, entry.score, { fontFamily: "Arial Black", fontSize: 34, color: "#964b00" });             
                this.text.setStroke('#e69b50', 4);
                this.text.setShadow(2, 2, '#333333', 2, true, false);
            });

        this.text = this.add.text(10, 10, Constants.gameName() + " " + Constants.version());
    }
}

export default ScoreScene;