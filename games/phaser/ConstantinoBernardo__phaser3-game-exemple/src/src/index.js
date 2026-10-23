import Phaser from "phaser"
import MainMenu from "./scenes/MainMenu";
import Select from "./scenes/Select";
import Level from "./scenes/Level"

window.addEventListener("load",()=>{

    let game=new Phaser.Game({
        type:Phaser.Auto,
        pixelArt:true,
        width:400,
        height:715,
        background:'#00000000',
        scale: {
            mode: Phaser.Scale.FIT,
            autoCenter: Phaser.Scale.CENTER_BOTH
        },   
        physics:{
            default:'arcade',
            arcade :{
                gravity:{
                    y:250,},
                    debug:false
            }
        },
        
    });

    game.scene.add("Boot", Boot);
    game.scene.add("Select",Select)
    game.scene.add("MainMenu",MainMenu)
    game.scene.add("Level",Level)
    game.scene.start("Boot")

})

class Boot extends Phaser.Scene{
    constructor(){
        super("Boot")

        
    }
    preload() {
        this.load.pack("asset-pack", "assets/asset-pack.json");

        this.load.on(Phaser.Loader.Events.COMPLETE, () =>this.scene.start("Level",{init:true}));
    }


}