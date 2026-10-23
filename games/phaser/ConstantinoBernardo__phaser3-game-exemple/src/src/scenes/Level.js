//import Phaser from "phaser";
import Ui from "../implements/Ui";
import Bird from "../prefabs/Bird";
import Obstacle from "../prefabs/obstacle";


export default class Level extends Phaser.Scene{
    bird /**@type {Phaser.Physics.Arcade.Sprite} */
    obstacle /**@type {Phaser.Physics.Arcade.StaticGroup} */
	bg /** @type {Phaser Physics Arcade Sprite} */
    text_score
    score=0
    active=1
    _init=true
    constructor(){
        super("Level")
    }

    

    create(){
        this.bg = this.add.image(0,0,'bg'+this.active).setOrigin(0,0)

        if (this._init) {
			//Add Score Text to Scene
            Ui.uiStart(this,false)
            return
        }
       
		//Add Obstacle to Scene
        this.obstacle= new Obstacle(this)
        this.obstacle.init()

		// Add Bird to Scene
        this.bird=new Bird(this,{x:180,y:357.5},'Bird')
        this.bird.init()
        

        
      Ui.uiMain(this)
     
    }

    update(){
       if (this._init) return

       this.obstacle.update()
       this.bird.update()
       this.text_score.setText('score:'+this.score)

    }


}