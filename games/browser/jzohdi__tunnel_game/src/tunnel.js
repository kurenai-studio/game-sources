// modal function for showing instructions at beggining of page load,
// as well as at the end of the game.
const MODAL_DIV =
  '<div id="myModal" class="modal question-titles"><div class="modal-content main-card">' +
  '<span class="close">X</span>' +
  "contentPlaceHolder" +
  "</div></div>";

const createModal = (someIdOnPage, content) => {
  const modalContent = MODAL_DIV.replace("contentPlaceHolder", content);
  const modalHolder = document.getElementById(someIdOnPage);
  modalHolder.innerHTML = modalContent;

  const modal = document.getElementById("myModal");
  // const openButton = document.getElementById(triggerId);
  const span = document.getElementsByClassName("close")[0];
  const done = document.getElementById("done-selection");

  modal.style.display = "block";

  span.onclick = function() {
    modalHolder.innerHTML = "";
    startGame();
  };
  done.onclick = () => {
    span.click();
  };
  window.onclick = function(event) {
    if (event.target == modal) {
      span.click();
    }
  };
};

function startGame() {
  // 1 Dimesnional Perlin Noise Function. This is used so that the tunnel can
  // move in a pseudorandom fashion while remaining smooth. Each next random position is closely
  // related to the previous positon.
  class OneDNoise {
    constructor(max, amp, scale) {
      this.MAX_VERTICES = 256;
      this.MAX_VERTICES_MASK = this.MAX_VERTICES - 1;
      this.amplitude = amp;
      this.scale = scale;
      this.xx = 0.1;
      this.matrix = [];

      // load matrix.
      for (var i = 0; i < this.MAX_VERTICES; ++i) {
        this.matrix.push(Math.random());
      }
    }

    eVal() {
      let x = this.xx;
      let scaledX = x * this.scale,
        xFloor = Math.floor(scaledX),
        t = scaledX - xFloor;
      let tRemapSmoothstep = 6 * t ** 5 - 15 * t ** 4 + 10 * t ** 3;
      this.xx += 1;
      /// Modulo using &
      let xMin = xFloor & this.MAX_VERTICES_MASK,
        xMax = (xMin + 1) & this.MAX_VERTICES_MASK;
      let a = this.matrix[xMin],
        b = this.matrix[xMax];
      return this.lerp(a, b, tRemapSmoothstep) * this.amplitude;
    }

    lerp(a, b, t) {
      return a * (1 - t) + b * t;
    }
  }
  // Initiate canvas
  const GENERATOR = new OneDNoise(256, 1.0, 0.025);
  const canvas = document.getElementById("map-canvas");
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;

  let rtime;
  let timeout = false;
  let delta = 300;

  // detect when someone has resized the screen, we don't want to reload each time as this will be
  // a massive amount of reload calls. Instead we need to detect when they resized and haven't resized
  // in a certain amount of time.
  window.addEventListener("resize", function() {
    rtime = new Date();
    if (timeout === false) {
      timeout = true;
      setTimeout(resizeEnd, delta);
    }
  });

  function resizeEnd() {
    if (new Date() - rtime < delta) {
      setTimeout(resizeEnd, delta);
    } else {
      timeout = false;
      location.reload();
    }
  }

  // canvas base for canvas drawing.
  const cb = canvas.getContext("2d");
  gameOver = false;

  const getRndInteger = (min, max) => {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  };

  const getDeci = x => {
    return parseFloat(Number.parseFloat(x).toFixed(2));
  };
  // control width of tunnel for Ship, since different screens will require different
  // settings; we need to calculate the settings before start.
  // since only used once, it is written as an immediately-invoked arrow function.
  const SCALERS = (() => {
    const innerWidth = window.innerWidth;
    if (innerWidth > 1000) {
      return [10, 200, 170];
    } else if (innerWidth > 800) {
      return [6, 150, 120];
    } else if (innerWidth > 600) {
      return [5, 120, 100];
    } else if (innerWidth > 500) {
      return [5, 110, 100];
    } else if (innerWidth <= 500) {
      return [5, 100, 90];
    }
  })();
  const SHIPRADIUS = SCALERS[0];
  let GAP = SCALERS[1];
  const GAPWHENEASY = SCALERS[2];
  let CENTER;
  let GRAVITY = 2.4;
  let HOWJAGGED = 10;
  GAMEOVER = false;

  // The ship is a circular ellipse has an x, y position that is its center.
  // it can move left or right.
  class Ship {
    constructor(x, y, radius) {
      this.x = x;
      this.y = y;
      this.radius = radius;
    }

    draw() {
      cb.beginPath();
      cb.arc(this.x, this.y, this.radius, 0.2, Math.PI * 2, false);
      cb.strokeStyle = "red";
      cb.fillStyle = "black";
      cb.fill();
      cb.stroke();
    }
    moveLeft() {
      this.x -= 10;
    }
    moveRight() {
      this.x += 10;
    }
    update() {
      this.draw();
    }
  }
  // A wall must be able to redraw itself, remove itself, make a new wall, and detect if it
  // is colliding with the ship.
  class LeftWall {
    constructor(length, dy, whenToPush) {
      this.length = length;
      this.y = -18.0;
      this.dy = dy;
      this.height = 20.0;
      this.whenToPush = whenToPush;
    }

    draw() {
      if (
        (this.length - myShip.x) ** 2 + (this.y - myShip.y) ** 2 <
          myShip.radius ** 2 ||
        (this.length - myShip.x) ** 2 + (this.y + 20 - myShip.y) ** 2 <
          myShip.radius ** 2 ||
        (myShip.x < this.length &&
          this.y + 20 >= myShip.y - 10 &&
          this.y <= myShip.y + 10)
      ) {
        cb.fillStyle = "red";
        GAMEOVER = true;
      } else {
        cb.fillStyle = "black";
      }
      cb.fillRect(0, this.y, this.length, this.height);
    }

    // if this y position of this wall is lower than 20 pixels past the bottom of the screen.
    // remove self from the array of left walls.
    update() {
      if (this.y > innerHeight + 20) {
        this.dy = 0;
        leftArray.shift();
      }
      if (this.y == this.whenToPush) {
        pushLeftWall();
      }

      // var thisNumL = parseInt(this.y.toFixed(2)) + parseInt(this.dy.toFixed(2));
      this.y = getDeci(getDeci(this.y) + getDeci(this.dy));
      this.draw();
    }
  }

  class RightWall {
    constructor(xEdge, dy, whenToPush) {
      this.xEdge = xEdge;
      this.y = -18;
      this.dy = dy;
      this.height = 20;
      this.whenToPush = whenToPush;
    }

    draw() {
      // TOdo function for if touching
      if (
        (this.xEdge - myShip.x) ** 2 + (this.y - myShip.y) ** 2 <
          myShip.radius ** 2 ||
        (this.xEdge - myShip.x) ** 2 + (this.y + 20 - myShip.y) ** 2 <
          myShip.radius ** 2 ||
        (myShip.x > this.xEdge &&
          this.y + 20 >= myShip.y - 10 &&
          this.y <= myShip.y + 10)
      ) {
        cb.fillStyle = "red";
        GAMEOVER = true;
      } else {
        cb.fillStyle = "black";
      }
      cb.fillRect(this.xEdge, this.y, innerWidth, this.height);
    }

    update() {
      if (this.y > innerHeight + 20) {
        this.dy = 0;
        rightArray.shift();
      }

      if (this.y == this.whenToPush) {
        pushRightWall();
      }

      // var thisNumR = getDeci(this.y) + getDeci(this.dy);
      this.y = getDeci(getDeci(this.y) + getDeci(this.dy));
      this.draw();
    }
  }

  class ScoreBox {
    constructor(width, style, color) {
      this.score = 0;
      this.x = 20;
      this.y = 20;
      this.color = color;
      this.font = width + style;
      this.score = 0;
    }
    update() {
      cb.font = this.font;
      cb.fillStyle = this.color;
      cb.fillText("SCORE: " + this.score, this.x, this.y);
    }
  }

  class EndGame {
    constructor() {
      this.score = 0;
      this.x = window.innerWidth / 5;
      this.y = window.innerHeight / 3;
      this.size = innerWidth / 11;
      this.message = "YOU LOST :(";
      this.message2 = "YOUR SCORE: ";
    }

    update() {
      cb.font = this.size + "px Consolas";
      cb.fillStyle = "red";
      cb.fillText(this.message, this.x, this.y);
      cb.fillText(this.message2 + this.score, this.x - 70, this.y + this.size);
    }
  }

  class Restart {
    constructor() {
      this.x = window.innerWidth / 3;
      this.y = window.innerHeight * 0.8;
      this.size = innerWidth / 15;
      this.message = "Restart?";
    }
    update() {
      cb.font = this.size + "px Consolas";
      cb.fillStyle = "green";
      cb.fillText(this.message, this.x, this.y);
    }
  }

  const score = new ScoreBox("20px ", "Consolas", "red");

  // this function decidres how big the the gap between the left wall and the right wall should be
  // this is necessary due to the fact that if the
  const decideTunnelWidth = (oldCENTER, CENTER) => {
    const diff = Math.abs(CENTER - oldCENTER);
    if (diff >= 13) {
      const newGAP = GAPWHENEASY - 10 + 3.06 * diff;
      return newGAP;
    }
    return GAPWHENEASY;
  };

  const leftArray = [];

  // pushLeftWall (and pushRightWall) functions to create new walls.
  // to do so first we must:
  // 1. GENERATOR the next perlin noise value and scale it to match the width of the screen
  // 2. check that the new position is not too far from the previous position (this would cause the tunnel to be closed).
  // 3. based on the new position GENERATOR the size of the gap based on the difference in the new tunnel position and the old position.
  //   (again if the gap was too small this would cause the tunnel to be closed).
  // 4. calculate the size of the wall based on this gap, and then create the new wall while adding it to the array of left walls.
  const pushLeftWall = () => {
    const oldCenter = CENTER;
    const moveTunnel = GENERATOR.eVal() * window.innerWidth;
    if (moveTunnel > GAP / 2 && moveTunnel < innerWidth - GAP / 2) {
      CENTER = moveTunnel;
    }

    GAP = decideTunnelWidth(oldCenter, CENTER);
    const whenToPushL = getDeci(-18 + Math.trunc(18 / GRAVITY) * GRAVITY);
    const wallLength = getRndInteger(
      CENTER - GAP / 2 - HOWJAGGED,
      CENTER - GAP / 2 + HOWJAGGED
    );
    leftArray.push(new LeftWall(wallLength, GRAVITY, whenToPushL));
  };

  const rightArray = [];
  let gameTimer = 1;

  // while left wall functions to GENERATOR the gap for the tunnerl, push right wall functions
  // to speed up the game and add to the score board.
  const pushRightWall = () => {
    gameTimer += 1;
    if (gameTimer % 100 == 0 && GRAVITY <= 10.0) {
      GRAVITY += 0.1;
    }
    const whenToPushR = getDeci(-18 + Math.trunc(18 / GRAVITY) * GRAVITY);
    // console.log(whenToPushR)
    const xStart = getRndInteger(
      CENTER + GAP / 2 + HOWJAGGED,
      CENTER + GAP / 2 - HOWJAGGED
    );
    rightArray.push(new RightWall(xStart, GRAVITY, whenToPushR));
  };

  const myShip = new Ship(innerWidth / 2, innerHeight * 0.66, SHIPRADIUS);

  let DEVICE;
  let touchPosition;

  if (
    /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
      navigator.userAgent
    )
  ) {
    DEVICE = "mobile";
  } else {
    DEVICE = "desk";
  }

  if (DEVICE == "mobile") {
    window.addEventListener("touchstart", function(e) {
      touchPosition = e.touches[0].clientX;
    });
    window.addEventListener("touchmove", function(e) {
      var movement = e.touches[0].pageX;
      var positionChange = movement - touchPosition;
      myShip.x += positionChange;
      touchPosition = movement;
    });
  } else {
    window.addEventListener("mousemove", function() {
      myShip.x = event.clientX;
    });
  }
  // Initiate first walls on left and right
  pushLeftWall();
  pushRightWall();

  const updateScoreAndPositions = () => {
    requestAnimationFrame(animate);
    cb.clearRect(0, 0, innerWidth, innerHeight);
    // draw the ship in the correct position. -> related to the position of cursor/touch
    myShip.update();

    // for all walls (right and left) update their position.
    // get the index of the array with the larger size to iterate through.
    const maxWallIndex =
      rightArray.length >= leftArray.length
        ? rightArray.length
        : leftArray.length;
    for (let index = 0; index < maxWallIndex; index++) {
      if (index < rightArray.length) {
        rightArray[index].update();
      }
      if (index < leftArray.length) {
        leftArray[index].update();
      }
    }

    score.score += 1;
    score.update();
  };
  // when the game ends. show modal. if they got a new high score show congratze, else show score and restart button.
  const updateGameToGameOver = () => {
    const MAIN_CONTENT = `<h4>Game Over :(</h4><h4>Your Score: ${score.score}</h4>`;
    const NEW_HIGH_SCORE = `<h4>Game Over :(</h4><h4>Contgratz new high score! <br/>Score: ${score.score}</h4>`;
    const RESTART_GAME_MODAL_CONTENT = `<div id='end-game'>${
      score.score > parseInt(localStorage.getItem("highScore"))
        ? NEW_HIGH_SCORE
        : MAIN_CONTENT
    }
    <button class='button restart-button' id='done-selection'>Restart!</button>
    </div>`;

    // if the score is a new high score, set the highscore in localstorage.
    if (score.score > parseInt(localStorage.getItem("highScore"))) {
      localStorage.setItem("highScore", JSON.stringify(score.score));
    }
    createModal("modal-holder", RESTART_GAME_MODAL_CONTENT);
    sessionStorage.setItem("gameJustEnded", "true");
  };

  const animate = () => {
    if (!GAMEOVER) {
      updateScoreAndPositions();
    } else if (GAMEOVER == true) {
      updateGameToGameOver();
    }
  };

  animate();
}

const init = () => {
  // initialzie highscore to 0 if user has not visited yet.
  if (!localStorage.getItem("highScore")) {
    localStorage.setItem("highScore", "0");
  }
  // if the user had not just played the game previously. show modal with game instructions.
  if (!sessionStorage.getItem("gameJustEnded")) {
    const BEGIN_GAME_MODAL_CONTENT = `<h3>Tunnel Game</h3>
    <div id="game-instructions">
    <h4>How To Play:</h4>
    <p>1. Move left and right to control position: </p>
    <p style='padding-left: 20px;'>Mobile: hold finger down anywhere on the screen</p>
    <p style='padding-left: 20px;'>Computer: move cursor on screen</p>
    <p>2. Don't touch the walls on the left or right!</p>
    </div>
    <button class='button' id='done-selection'>Start Game!</button>`;

    createModal("modal-holder", BEGIN_GAME_MODAL_CONTENT);
  } else {
    // else start the game automatically.
    startGame();
  }
};

init();
