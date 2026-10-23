/*
	Class to represent a round of the game
*/

function Round(){	
	this.timer = 0;
	this.dog = new Dog();
	this.allSheep = [];
	this.pen = {
		x:PEN_ORIGIN[0],
		y:PEN_ORIGIN[1],
		width:PEN_WIDTH,
		height:PEN_HEIGHT
	}
	
	//return true if all sheep are in the pen
	this.allSheepInPen = function(){
		
		for(var i = 0; i < this.allSheep.length; i++){
			var s = this.allSheep[i];
			
			//if the position of this sheep is not in the pen...
			if(! ((s.posX > this.pen.x && s.posX < (this.pen.x + this.pen.width)) 
			  && (s.posY > this.pen.y && s.posY < (this.pen.y + this.pen.height))) ){
			
				return false;
			}
		}
		
		return true;
	}
	
	//the higher roundNum, the more sheep
	this.initRound = function(roundNum){
		var numSheep = Math.ceil(roundNum * 1.4);
		this.allSheep = [];
		
		for(var i = 0; i < numSheep; i++){
			var s = new Sheep();
			s.posX = Math.floor((Math.random() * MAX_X)+1);
			s.posY = Math.floor((Math.random() * MAX_Y)+1);
			this.allSheep.push(s);
		}
	}
	
	//compute all new positions
	this.computeAllPositions = function(){
		
		for(var s in this.allSheep){
			this.allSheep[s].computeNewPosition( this.dog.posX, this.dog.posY );
		}
		
		this.dog.computeNewPosition();
	}
}