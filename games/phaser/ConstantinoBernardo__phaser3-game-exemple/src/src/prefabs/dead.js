//import Phaser from "phaser"

export default class DeadBird extends Phaser.GameObjects.Sprite{

    
    constructor(scene,position,texture){
        super(scene,position.x,position.y,texture)
        
        
    }

    init(){
        this.anims.play("Dead")
        
    }
    
    update(){

    }
        
        
}
