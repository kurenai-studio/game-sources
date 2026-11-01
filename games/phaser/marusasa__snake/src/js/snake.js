(function() {
	var config = {
		type: Phaser.AUTO,
		width: 800,
		height: 600,
		backgroundColor: '#ffffff',
		parent: 'game-loc',
		physics: {
			default: 'arcade',
			arcade: {
				gravity: { y: 0, x: 0 },
				debug: false
			}
		},
		scene: {
			preload: preload,
			create: create,
			update: update
		},
		dom: {
			createContainer: true
		}
	};

	var game = new Phaser.Game(config);
	var food;
	var direction = 1;  //0 = up, 1 = right, 2 = down, 3 = left
	var nextDirection = Array();
	var MAX_Y = 16;
	var MAX_X = 25;
	var DEFAULT_GAME_SPEED = 150;
	var squares = new Array();
	var currentX = 3;
	var currentY = 1;
	var movesX = Array();
	var movesY = Array();
	var lastPointer = 0;
	var foodX = 0;
	var foodY = 0;
	var scoreText;
	var score = 0;
	var gameText;
	var hs = {
		domElement: null
	}
	var gameObjArray = [new SsgGameObj("14dc9ac2-39d3-4015-b482-407ef8a2b86a", "marudot-hs-weekly"),
	new SsgGameObj("34b85f8b-8d13-43f3-837a-bbfcfeee8a69", "marudot-hs-monthly")];
	var hsObj = new SsgHighScore(gameObjArray);

	function preload() {
		this.load.image('snake_body', 'assets/snake_square.png');
		this.load.image('food', 'assets/food_square.png');
		this.load.html('hs_input', 'assets/highscore_input.html');
	}

	function create() {
		//Draw outer lines
		var line1 = this.add.line(0, 0, 0, 60, 780, 60, 0x3a3a3a);
		line1.setOrigin(0, 0);
		var line2 = this.add.line(0, 0, 0, 570, 780, 570, 0x3a3a3a);
		line2.setOrigin(0, 0);
		var line3 = this.add.line(0, 0, 1, 60, 1, 570, 0x3a3a3a);
		line3.setOrigin(0, 0);
		var line4 = this.add.line(0, 0, 780, 60, 780, 570, 0x3a3a3a);
		line4.setOrigin(0, 0);

		for (let x = 0; x <= MAX_X; x++) {
			squares.push(new Array());
			for (let y = 0; y <= MAX_Y; y++) {
				squares[x].push(this.physics.add.sprite(30 * (x + 1) - 15, 30 * (y + 3) - 15, 'snake_body'));
			}
		}

		foodX = 10;
		foodY = 1;
		food = this.physics.add.sprite((foodX + 1) * 30 - 15, (foodY + 3) * 30 - 15, 'food');

		//Add Text
		scoreText = this.add.text(16, 16, 'Score: ' + score, { fontSize: '32px', fill: '#000' });
		gameText = this.add.text(400, 16, '', { fontSize: '32px', fill: '#000' });

		resetGame();
		gameText.setText('Hit Space to Start');

		//  Input Events
		cursors = this.input.keyboard.createCursorKeys();
		this.input.keyboard.addKey('W').on('down', function(event) {
			nextDirection.push(0);
		});
		this.input.keyboard.addKey('A').on('down', function(event) {
			nextDirection.push(3);
		});
		this.input.keyboard.addKey('S').on('down', function(event) {
			nextDirection.push(2);
		});
		this.input.keyboard.addKey('X').on('down', function(event) {
			nextDirection.push(2);
		});
		this.input.keyboard.addKey('D').on('down', function(event) {
			nextDirection.push(1);
		});
		cursors.up.on('down', function(event) {
			nextDirection.push(0);
		});
		cursors.down.on('down', function(event) {
			nextDirection.push(2);
		});
		cursors.left.on('down', function(event) {
			nextDirection.push(3);
		});
		cursors.right.on('down', function(event) {
			nextDirection.push(1);
		});
		cursors.space.on('down', function(event) {
			//set score to 0
			if (!go && !hs.domElement.visible) {
				resetGame();
				go = true;
			}
		});

		hsObj.loadHS();

		//prepare highscore input html
		hs.domElement = this.add.dom(200, 150).createFromCache('hs_input');
		hs.domElement.setOrigin(0, 0);
		hs.domElement.on('click', function(event) {
			if (event.target.name === 'submitButton') {
				event.target.disabled = true;
				let inputName = this.getChildByName('nameField');
				if (hsObj.validate(score, inputName.value)) {
					//  Turn off the click events
					this.removeListener('click');
					console.log(inputName.value);
					hsObj.addScore(score, inputName.value);
					hs.domElement.setVisible(false);
					game.input.keyboard.startListeners();
				}
				event.target.disabled = false;
			} else if (event.target.name === 'cancelButton') {
				this.removeListener('click');
				console.log('HS Canceled');
				hs.domElement.setVisible(false);
				game.input.keyboard.startListeners();
			}
		});
		hs.domElement.setVisible(false);
	}

	function askHSName(score) {
		hs.domElement.addListener('click');
		document.getElementById("hs_score_disp").innerHTML = score;
		hs.domElement.setVisible(true);
		setTimeout(() => {
			document.getElementsByName("nameField")[0].focus();
		}, 400);
		game.input.keyboard.stopListeners();
	}

	function resetGame() {
		//hide all snake body
		for (var x = 0; x <= MAX_X; x++) {
			for (var y = 0; y <= MAX_Y; y++) {
				squares[x][y].setVisible(false);
			}
		}

		movesX = Array();
		movesY = Array();
		nextDirection = Array();

		squares[1][1].setVisible(true);
		movesX.push(1);
		movesY.push(1);
		squares[2][1].setVisible(true);
		movesX.push(2);
		movesY.push(1);
		squares[3][1].setVisible(true);
		movesX.push(3);
		movesY.push(1);
		lastPointer = 0;

		currentX = 3;
		currentY = 1;
		foodX = 10;
		foodY = 1;
		food.setX((foodX + 1) * 30 - 15);
		food.setY((foodY + 3) * 30 - 15);

		gameSpeed = DEFAULT_GAME_SPEED;

		direction = 1;
		score = 0;
		scoreText.setText('Score: ' + score);
		gameText.setText('');
	}

	function newFood() {
		var newX = Math.floor(Math.random() * (MAX_X - 1));
		var newY = Math.floor(Math.random() * (MAX_Y - 1));
		while (squares[newX][newY].visible) {
			newX = Math.floor(Math.random() * (MAX_X - 1));
			newY = Math.floor(Math.random() * (MAX_Y - 1));
		}
		food.setX((newX + 1) * 30 - 15);
		food.setY((newY + 3) * 30 - 15);
		foodX = newX;
		foodY = newY;
	}

	var gameTime = 0;
	var go = false;
	var gameSpeed = DEFAULT_GAME_SPEED;
	function update(time, delta) {
		gameTime += delta;
		if (gameTime > gameSpeed && go) {
			//0 = up, 1 = right, 2 = down, 3 = left
			var nd = direction;
			if (nextDirection.length > 0) {
				nd = nextDirection.shift();
				if (nd == 0 && direction != 2) {
					direction = nd;
				} else if (nd == 2 && direction != 0) {
					direction = nd;
				} else if (nd == 3 && direction != 1) {
					direction = nd;
				} else if (nd == 1 && direction != 3) {
					direction = nd;
				}
			}
			if (direction == 0) {
				currentY--;
			} else if (direction == 1) {
				currentX++;
			} else if (direction == 2) {
				currentY++;
			} else if (direction == 3) {
				currentX--;
			}
			//move tail end before checking body collision
			squares[movesX[lastPointer]][movesY[lastPointer]].setVisible(false);
			lastPointer++;
			if (currentY < 0 || currentX < 0 || currentY > MAX_Y || currentX > MAX_X ||
				squares[currentX][currentY].visible) {
				go = false;
				if (hsObj.isNewHS(score)) {
					askHSName(score);
				}
				gameText.setText('Game Over');
				this.time.delayedCall(2000, function() { if (!go) { gameText.setText('Hit Space to Restart'); } });
			} else {
				squares[currentX][currentY].setVisible(true);
				movesX.push(currentX);
				movesY.push(currentY);
				if (foodX == currentX && foodY == currentY) {
					//score
					score++;
					scoreText.setText('Score: ' + score);
					//grow body
					lastPointer--;
					newFood();
					if (gameSpeed > 80) {
						gameSpeed -= 1;
					}
					//show gamespeed for debug.
					if (config.physics.arcade.debug) {
						gameText.setText(gameSpeed);
					}
				}
				gameTime = 0;
			}
		}
	}
}());