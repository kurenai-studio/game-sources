export default class Obstacle{
    
    time /**@type{Phaser.Time.TimerEvent} */

    constructor(_scene){
        this.scene=_scene
        this.object=_scene.physics.add.staticGroup()
        this.object.init=this.init
        this.object.update=this.update
        this.object.generate=this.generate

        return this.object
    }
    init(){
        this.time=this.scene.time.addEvent({
            delay:2800, callback:this.generate, callbackScope:this, loop:true
        })
        console.log(this.generate)
        

    }

    update(){
       //window.a=this.children.entries

       for(let c in this.children.entries){
            this.children.entries[c].x-=2
            this.children.entries[c].refreshBody()
    
    
    
            if(this.children.entries[c].x<=-50){
                this.children.entries[c].destroy()
                if(this.scene.bird.alive){
                    this.scene.score++
                }
            
            }
       
        }
    }

    generate(){
       var random= Phaser.Math.Between(0,3)

       if (random<=0) {
        this.create(500,10,'obstacle1').setScale(.8).refreshBody()

        this.create(500,495,'obstacle2').setScale(.8).refreshBody()
       }else if (random<=2) {
        this.create(500,120,'obstacle1').setScale(.8).refreshBody()

        this.create(500,585,'obstacle2').setScale(.8).refreshBody()
       }else if (random>=3) {
        this.create(500,220,'obstacle1').setScale(.8).refreshBody()

        this.create(500,665,'obstacle2').setScale(.8).refreshBody()
       }
        
    }
}
