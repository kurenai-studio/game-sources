//import Phaser from "phaser"
import Ui from "../implements/Ui"
import DeadBird from "./dead"

export default class Bird extends Phaser.Physics.Arcade.Sprite{

    click /**@type {Phaser.Input.Pointer} */
    alive=true

    constructor(scene,position,texture){
        super(scene,position.x,position.y,texture)
        this.setScale(.6)
        

        scene.physics.add.existing(this)
        scene.add.existing(this)
    }

    init(){
        this.anims.play("fly")
        this.click= this.scene.input.activePointer 
        this.scene.physics.add.collider(this,this.scene.obstacle,()=>{
            this.dead()
        },undefined,this.scene)
        window.x=this

        
    }
    
    update(){
        
        if (this.y<-20 || this.y>720) {
            this.dead()
        }

        if (this.click.isDown) {
           if(this.body){
            this.body.setVelocityY(-200)

           }
          
        }
    }


    dead(){
        this.alive=false
        var scene=this.scene
        this.destroy()
        this.alive=false
        if(scene){
           Ui.uiStart(scene,{dead: true})
                scene.time.addEvent({
                delay:5000, callback:()=>{scene.scene.pause()}, callbackScope:this, loop:false
            })
           
        }
       
        

    }


}
