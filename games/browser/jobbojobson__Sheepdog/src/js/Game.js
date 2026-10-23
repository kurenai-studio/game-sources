//game logic
var gameCanvas = document.getElementById('gameCanvas'); //the game's canvas
var ctx = gameCanvas.getContext("2d"); //the canvas' graphics context
var roundNum = 1;
var round = new Round(); // class to represent the round of the game
round.initRound(roundNum);

var completeTimer = new Timer(); 
var roundTimer = new Timer();
roundTimer.isReversed = true;
roundTimer.time = ROUND_TIME;

document.all.roundNumLabel.innerText = roundNum;
document.all.roundTimeLabel.innerText = roundTimer.time;

/*
	utility function:
	Edge collision detection is the same for everything,
	this function makes sure the given object doesn't step out of the
	playing area
*/
function preventEdgeOverrun(animal){
	if(animal.posX - (animal.size / 2) < 0) animal.posX = (0 + animal.size / 2);
	if(animal.posX + (animal.size / 2) > MAX_X) animal.posX = (MAX_X - animal.size / 2);
	if(animal.posY - (animal.size / 2) < 0) animal.posY = (0 + animal.size / 2);
	if(animal.posY + (animal.size / 2) > MAX_Y) animal.posY = (MAX_Y - animal.size / 2);
}

// --------- Setup all event handlers ----------
// ------------ DESKTOP CONTROLS ---------------
//when we press a key
window.addEventListener('keydown', function(e){
	switch(e.keyCode){
	case 37: //left
		e.preventDefault();
		round.dog.changeX = round.dog.speed * -1;
		break;
	case 38: //up
		e.preventDefault();
		round.dog.changeY = round.dog.speed * -1;
		break;
	case 39://right
		e.preventDefault();
		round.dog.changeX = round.dog.speed;
		break;
	case 40://down
		e.preventDefault();
		round.dog.changeY = round.dog.speed;
		break;
	}
});

//when we release a key...
window.addEventListener('keyup', function(e){
	switch(e.keyCode){
	case 37: //left or right
	case 39:
		e.preventDefault();
		round.dog.changeX = 0;
		break;
	case 38: //up or down
	case 40:
		e.preventDefault();
		round.dog.changeY = 0;
		break;
	}
});

// ------------ TOUCH CONTROLS ---------------
function touchStart(e){
	switch(e.id){
	case 'leftButton': //left
		round.dog.changeX = round.dog.speed * -1;
		break;
	case 'upButton': //up
		round.dog.changeY = round.dog.speed * -1;
		break;
	case 'rightButton'://right
		round.dog.changeX = round.dog.speed;
		break;
	case 'downButton'://down
		round.dog.changeY = round.dog.speed;
		break;            		
	}
}

function touchEnd(e){
	 switch(e.id){
	case 'leftButton': //left or right
	case 'rightButton':
		round.dog.changeX = 0;
		break;
	case 'upButton': //up or down
	case 'downButton':
		round.dog.changeY = 0;
		break;
	}
}

//------ end event handlers ----------


roundTimer.start();

//main animation loop
function animate(){
	
	//clear the canvas
	ctx.clearRect(0, 0, gameCanvas.width, gameCanvas.height);
	
	//draw the dog
	ctx.fillStyle = "#FF0000";
	ctx.fillRect( (round.dog.posX - (round.dog.size / 2)), (round.dog.posY - (round.dog.size / 2)), round.dog.size, round.dog.size );
	
	//draw the pen
	ctx.strokeStyle = "#0000FF";
	ctx.rect(round.pen.x, round.pen.y, round.pen.width, round.pen.height);
	ctx.stroke();
	
	//draw all sheep
	ctx.fillStyle = '#000000';
	for(var s in round.allSheep){
		var sheep = round.allSheep[s];
		ctx.fillRect( (sheep.posX - (sheep.size / 2)), (sheep.posY - (sheep.size / 2)), sheep.size, sheep.size );
	}
	
	round.computeAllPositions();
	
	//remember this gets hit every 17 milliseconds
	if(round.allSheepInPen()){
		if(!completeTimer.isRunning){
			//sheep are in the pen, begin the completion timer
			completeTimer.start();
			roundTimer.stop();
		} else {
			//sheep are in the pen and the completion timer is running
			ctx.font = '30px Arial';
			ctx.fillText(completeTimer.time, round.pen.x,round.pen.y);
						
			if(completeTimer.time > PEN_TIME){
				//sheep have been in the pen an acceptable amount of time, end the round
				completeTimer.stop();
				completeTimer.time = 0;
				round.initRound(++roundNum);
				roundTimer.time = ROUND_TIME;
				roundTimer.start();
			}
		}
	} else {
		//sheep are out of the pen, reset the complete timer, restart the round timer
		roundTimer.start();
		completeTimer.stop();
		completeTimer.time = 0;
	}
	
	document.all.roundNumLabel.innerText = roundNum;
	document.all.roundTimeLabel.innerText = roundTimer.time;
	
	if(roundTimer.time < 0) {
		ctx.font = '45px Arial';
		ctx.fillText("Game Over", round.pen.x, round.pen.y);
	} else {
		setTimeout(animate, 17); //~60 FPS
	}
}
animate(); 