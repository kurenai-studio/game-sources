//Base game object
var GameObject = function(args) {

	this.lTrans = new Transform(1, 0, 0, 1, 0, 0);	//Local transform.
	this.gTrans = new Transform(1, 0, 0, 1, 0, 0);	//Global transform.
	if(args.zIndex != null) {		//zIndex compared to sibling objects.
		this.zIndex = args.zIndex;
	}
	else {
		this.zIndex = 0;
	}
    this.parent = args.parent;		//parent object.
	this.parent.pushGO(this);
	this.children = [];

	self = this;

	//Instantiate child objects of this game object.
	args.children = args.children || [];
	args.children.forEach(function(o) {
		o.params = o.params || {};
		o.params.parent = self;
		o.params.children = o.children || [];
		callObject(o.name, o.params);
	});
}

//Game object update
GameObject.prototype.update = function(dt, gTrans) {

	gTrans = this.parent.gTrans;

    this.gTrans = gTrans.getMult(this.lTrans);
}

//Set a New Scene to load it
GameObject.prototype.loadScene = function(newScene) {
	this.parent.loadScene(newScene);
}

//Game object draw
GameObject.prototype.draw = function(ctx) {
	
}

//
GameObject.prototype.pushGO = function(gameObject) {
	this.parent.pushGO(gameObject);
}

//Game object collision
GameObject.prototype.collide = function(other, pos) {
	
}

