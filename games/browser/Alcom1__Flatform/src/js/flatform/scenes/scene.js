//Scene
var Scene = function() {

	this.gTrans = new Transform(1, 0, 0, 1, 0, 0);
	this.gameObjects = [];
	this.preloader = {};
	this.newScene = "";
}

//Init
Scene.prototype.init = function() {
	
	this.gameObjects.push(new GameObject({ parent : this }));
}

//Clear
Scene.prototype.clear = function() {
	
	this.gameObjects = [];
	this.preloader = {};
}

//Push Game Object
Scene.prototype.pushGO = function(gameObject) {
	
	this.gameObjects.push(gameObject);
	
	//Sort game objects by z-index.
	this.gameObjects.sort(
		function(a, b) {
	
			if(a.zIndex == b.zIndex)
				return 0;
			
			return a.zIndex > b.zIndex;
		});
}

//Set a New Scene to load it
Scene.prototype.loadScene = function(newScene) {
	this.newScene = newScene;
}

//Scene update
Scene.prototype.update = function(dt) {
	
	for(var i = 0; i < this.gameObjects.length; i++) {
	
		this.gameObjects[i].update(dt, this.transform);
	}
}

//Scene draw
Scene.prototype.draw = function(ctx) {
	
	for(var i = 0; i < this.gameObjects.length; i++) {
	
		this.gameObjects[i].draw(ctx);
	}
}