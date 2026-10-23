/*
	Class to represent a sheep and it's behaviour/abilities
*/
function Sheep(){
	this.posX = 0;
	this.posY = 0;
	this.changeX = 0;
	this.changeY = 0;
	this.speed = Math.random() * 0.1;
	this.direction = Math.random() * (2 * Math.PI);
	this.size = SHEEP_SIZE;
	this.isEvading = false;
	
	this.computeNewPosition = function(dogX, dogY){
		
		var diffX = dogX - this.posX;
		var diffY = dogY - this.posY;
		var distance = Math.hypot(diffX, diffY);
		
		if(distance > 150){
			
			if(this.isEvading){// || Math.random() > 0.95){
				//i was evading, now i don't need to. do something random
				this.direction = Math.random() * (2 * Math.PI);
				this.speed = Math.random() * 0.1;
				
				//tend towads the centre 
				//if(Math.random() < 0.3){
				//	this.direction = Math.atan2( (this.posY - (MAX_Y / 2) ), (this.posX - (MAX_X / 2) ) ) + Math.PI;	
				//}
			}
			
			this.isEvading = false;
			
		} else {
			this.isEvading = true;
			
			//speed is an inverse square multiplier
			this.speed = 30 / (distance ^ 2);
			
			var angleToDog = Math.atan2(diffY, diffX); //<-- you can add 2PI to this if it's less than zero to get a 'real' angle in radians
			this.direction = angleToDog + Math.PI; //run directly away from the dog...
			
			//apply a fear factor so the angle is not precisely away from the dog
			var f = Math.random() * 0.05;
			f *= Math.random() > 0.5 ? 1 : -1;
			this.direction += f;
		}
		
		this.changeX = Math.cos(this.direction) * this.speed;
		this.changeY = Math.sin(this.direction) * this.speed;
		this.posX += this.changeX;
		this.posY += this.changeY;
		
		preventEdgeOverrun(this);
	}
}