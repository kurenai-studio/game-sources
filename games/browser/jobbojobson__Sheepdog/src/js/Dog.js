/*
	Class to represent a Dog and its behaviour/abilities (should be a singleton?)
*/
function Dog(){
	this.posX = MAX_X / 2;
	this.posY = MAX_Y / 1.2;
	this.size = DOG_SIZE;
	this.changeX = 0;
	this.changeY = 0;
	this.speed = DOG_SPEED;

	this.computeNewPosition = function(){ //event handlers will have changed changeX and changeY
		this.posX += this.changeX;
		this.posY += this.changeY;
		
		preventEdgeOverrun(this);
	}
}