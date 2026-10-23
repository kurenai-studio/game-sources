// *NOTE* The next step to make this more efficient might be to initialize with an extra set of cells around the array, that way simple addition operations replace conditionals //
// IMPORTANT DO NOT FORGET ^
// I think also we could get rid of as much of the global variables as possible to make it more self contained

const canvas = document.getElementById('canvas');
const canvasContext = canvas.getContext('2d');
const pauseButton = document.getElementById('pause');
const randomizeButton = document.getElementById('randomize');
const clearButton = document.getElementById('clear');
const speedSlider = document.getElementById('speedSlider');
const aliveColor = '#665c54';
const deadColor = '#bdae93';
const coordColor = '#fabd2f';
const coordOutlineColor = "#282828";
const scalingFactor = 8; // scales the scope down the bigger the number
const screenWidth = (canvas.width / scalingFactor);
const screenHeight = (canvas.height / scalingFactor);
let speed = 10; // speed of program
let startSim = false; // flag to tell simulation to start/stop
let stopId; // ID to stop the animation loop
let timeoutId; // ID to clear the timeout counter
let currentGameBoard = [];
let pastGameBoard = [];
let mouseX;
let mouseY;

const State = {
	Dead: 0,
	Alive: 1
}

window.addEventListener("load", event =>
{
	initializeGameBoard(currentGameBoard);
	initCopyGameBoard(currentGameBoard, pastGameBoard);
	drawBoardToCanvas(currentGameBoard);
});

randomizeButton.addEventListener("click", event =>
{
	randomizeGameBoard(currentGameBoard);
	copyCurrentGameBoard(currentGameBoard, pastGameBoard);
	if(!startSim){
		drawBoardToCanvas(currentGameBoard);
		drawMousePos(mouseX, mouseY);
	}
});

clearButton.addEventListener("click", event =>
{
	clearGameBoard(currentGameBoard);
	copyCurrentGameBoard(currentGameBoard, pastGameBoard);
	if(!startSim){
		drawBoardToCanvas(currentGameBoard);
		drawMousePos(mouseX, mouseY);
	}
});

pauseButton.addEventListener("click", event =>
{
	if(!startSim)
	{
		startSim = true;
		clearTimeout(timeoutId);
		gameLoop(currentGameBoard, pastGameBoard);
	}
	else
	{
		startSim = false;
		drawBoardToCanvas(currentGameBoard);
		drawMousePos(mouseX, mouseY);
	}
});

speedSlider.oninput = function() {
	speed = speedSlider.value;
	document.getElementById('sliderLabel').innerText = "Speed: " + speed;
}

canvas.addEventListener("mousemove", event => 
{
	const rect = canvas.getBoundingClientRect();
	const x = Math.floor((event.clientX - rect.left) / scalingFactor);
	const y = Math.floor((event.clientY - rect.top) / scalingFactor);
	mouseX = x;
	mouseY = y;

	if(!startSim)
	{
		drawBoardToCanvas(currentGameBoard);
		drawMousePos(x, y);
	}
});

canvas.addEventListener("mousedown", event =>{
	if(!startSim)
	{
		currentGameBoard[mouseY + 1][mouseX + 1] = State.Alive;
		pastGameBoard[mouseY + 1][mouseX + 1] = State.Alive;
		drawBoardToCanvas(currentGameBoard);
		drawMousePos(mouseX, mouseY);
	}
});

function drawMousePos(x, y)
{
	const pauseState = !startSim;
	const text = x.toString() + ", " + y.toString() + " Paused: " + pauseState.toString();
	canvasContext.font = "bold 20px arial";
	canvasContext.fillStyle = coordOutlineColor;
	canvasContext.strokeText(text, 25, 25);
	canvasContext.fillStyle = coordColor;
	canvasContext.fillText(text, 25, 25);
}

function main()
{
	// initially draw gameboard and then pause
	// canvasContext.clearRect(0, 0, canvas.width, canvas.height);
	drawBoardToCanvas(currentGameBoard);
	startSim = false;


	// start game loop
	stopId = window.requestAnimationFrame(function() { gameLoop(currentGameBoard, pastGameBoard); });
}

function gameLoop(gameBoard, copyGameBoard)
{
	if(startSim)
	{
		updateGameBoard(gameBoard, copyGameBoard);
		// canvasContext.clearRect(0, 0, canvas.width, canvas.height);
		drawBoardToCanvas(gameBoard);
		drawMousePos(mouseX, mouseY);

		// recursively call function
		timeoutId = setTimeout(() => { window.requestAnimationFrame(function() { gameLoop(gameBoard, copyGameBoard); }); }, 1000 / speed);
	}
	else
	{
		cancelAnimationFrame(stopId);
	}
}

function updateGameBoard(gameBoard, copyGameBoard)
{
	/* iterate over all cells and count neighbors to determine next state; copy new state
	to current gameboard */

	let numAliveCells;
	for(let y = 1; y < screenHeight + 1; y++)
	{
		for(let x = 1; x < screenWidth + 1; x++)
		{
			numAliveCells = countNeighborCells(gameBoard, x, y);

			if(gameBoard[y][x] === State.Alive)
			{
				// dies of loneliness or overcrowding
				if(numAliveCells < 2 || numAliveCells > 3)
				{
					copyGameBoard[y][x] = State.Dead;
				}

			}
			else if(gameBoard[y][x] === State.Dead)
			{
				// a new cell is born, rejoyce!
				if(numAliveCells === 3)
				{
					copyGameBoard[y][x] = State.Alive;
				}
			}
		}
	}


	copyCurrentGameBoard(copyGameBoard, gameBoard);
}

function countNeighborCells(gameBoard, x, y)
{
	let numAliveCells = gameBoard[y - 1][x - 1] + gameBoard[y - 1][x] +
		gameBoard[y - 1][x + 1] + gameBoard[y][x - 1] + 
		gameBoard[y][x + 1] + gameBoard[y + 1][x - 1] +
		gameBoard[y + 1][x] + gameBoard[y + 1][x + 1];

	return numAliveCells;
}

function randomizeGameBoard(gameBoard)
{
	// function randomizes and initializes gameboard

	for(let y = 0; y < screenHeight + 2; y++)
	{
		for(let x = 0; x < screenWidth + 2; x++)
		{
			if((x > 0 && x < screenWidth + 1) && (y > 0 && y < screenHeight + 1))
			{
				gameBoard[y][x] = Math.round(Math.random());
			}
		}
	}
}

function clearGameBoard(gameBoard)
{
	for(let y = 0; y < screenHeight + 2; y++)
	{
		for(let x = 0; x < screenWidth + 2; x++)
		{
			if((x > 0 && x < screenWidth + 1) && (y > 0 && y < screenHeight + 1))
			{
				gameBoard[y][x] = 0;
			}
		}
	}
}

function initializeGameBoard(gameBoard)
{
	for(let y = 0; y < screenHeight + 2; y++)
	{
		gameBoard[y] = [];
		for(let x = 0; x < screenWidth + 2; x++)
		{
			gameBoard[y][x] = 0;
		}
	}
}

function copyCurrentGameBoard(gameBoard, copyGameBoard)
{
	for(let y = 0; y < screenHeight + 2; y++)
	{
		for(let x = 0; x < screenWidth + 2; x++)
		{
			copyGameBoard[y][x] = gameBoard[y][x]; 
		}
	}
}

function initCopyGameBoard(gameBoard, copyGameBoard)
{
	for(let y = 0; y < screenHeight + 2; y++)
	{
		copyGameBoard[y] = [];
		for(let x = 0; x < screenWidth + 2; x++)
		{
			copyGameBoard[y][x] = gameBoard[y][x]; 
		}
	}
}

function drawBoardToCanvas(gameBoard)
{
	for(let y = 1; y < screenHeight + 1; y++)
	{
		for(let x = 1; x < screenWidth + 1; x++)
		{
			switch(gameBoard[y][x])
			{
				case State.Dead:
					drawCellDead(x - 1, y - 1);
					break;
				case State.Alive:
					drawCellAlive(x - 1, y - 1);
					break;
			}
		}
	}
}

function drawCellDead(x, y)
{
	canvasContext.fillStyle = aliveColor;
	canvasContext.fillRect(x * scalingFactor, y * scalingFactor, scalingFactor, scalingFactor);
	canvasContext.fillStyle = deadColor;
	canvasContext.fillRect(x * scalingFactor, y * scalingFactor, 
		scalingFactor * .80, scalingFactor * .80);
}

function drawCellAlive(x, y)
{
	canvasContext.fillStyle = aliveColor;
	canvasContext.fillRect(x * scalingFactor, y * scalingFactor, scalingFactor, scalingFactor);
}

