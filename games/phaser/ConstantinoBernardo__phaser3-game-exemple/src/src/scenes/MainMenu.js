import {Scene} from "phaser";

export default class MainMenu extends Scene{
    
    avataar

    constructor(){
        super('MainMenu')
    }

    create(){
        this.add.image(0,0,'MainUi').setOrigin(0,0)
       window.r=this.add.image(50,50,'av2').setScale(2)

       window.x= this.add.image(80,170,'av2')
       window.y= this.add.image(80,220,'av1')
       window.x= this.add.image(80,270,'av2')
       window.y= this.add.image(80,320,'av1')
       window.x= this.add.image(80,370,'av2')
       window.y= this.add.image(80,420  ,'av1')
    }
}