/**
 * A clickable Cup
 */
export default class Cup extends Phaser.GameObjects.Sprite {
    constructor(scene, x, y, ImageID, ObjectID) {
        super(scene, x, y, ImageID);
        this.ObjectID = ObjectID;
        this.setInteractive({useHandCursor:true});
        this.on('pointerover', ()=>this.pointerOver())        
            .on('pointerout', () =>this.pointerOut());
        this.setTint(0xeeeeee);
    }
    pointerOver() {
        this.setTint(0xffffff);    
    }
    pointerOut(){
        this.setTint(0xeeeeee);    
    }
}

/**
 * Factory plugin for creating cups
 */
class CupPlugin extends Phaser.Plugins.BasePlugin {

    constructor (pluginManager)
    {
        super(pluginManager);
        //  Register our new Game Object type
        pluginManager.registerGameObject('cup', this.createCup);
    }

    createCup (x, y)
    {
        return this.displayList.add(new Cup(this.scene, x, y));
    }

}
