//Test animated rect object
var SceneSwitcher = function(args) {
    
    GameObject.call(this, args);

    this.nextScene = args.nextScene || "";
    this.prevScene = args.prevScene || "";
}

SceneSwitcher.prototype = Object.create(GameObject.prototype);

//Game object update
SceneSwitcher.prototype.update = function(dt, gTrans) {

    if(keys.isReleased(keys.KEYBOARD.UP)) {
        
        this.parent.loadScene(this.nextScene);
    }
    
    else if(keys.isReleased(keys.KEYBOARD.DOWN)) {
        
        this.parent.loadScene(this.prevScene);
    }

    GameObject.prototype.update.call(this, dt, gTrans);
}

//Game object draw
SceneSwitcher.prototype.draw = function(ctx) {

    GameObject.prototype.draw.call(this, ctx);
}