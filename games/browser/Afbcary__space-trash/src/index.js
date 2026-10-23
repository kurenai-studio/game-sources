var canvas = document.getElementById("canvas");
var ctx = canvas.getContext("2d");
var currScore = document.getElementById("currScore");
var highScore = document.getElementById("highScore");
var menu = document.getElementById("menu");
var start = document.getElementById("start");

var canvasWidth = (canvas.width = window.innerWidth);
var canvasHeight = (canvas.height = window.innerHeight);

var ship;
var score;
var pause = false;
var asteroids = [];
addOneAsteroidOnEachEdge();
addOneAsteroidOnEachEdge();
addOneAsteroidOnEachEdge();
addOneAsteroidOnEachEdge();
addOneAsteroidOnEachEdge();
addOneAsteroidOnEachEdge();

function startGame() {
  pause = false;
  score = 0;
  ship = {
    x: 0,
    y: canvasHeight / 2,
    xVelocity: 2,
    yVelocity: 0,
    xAccel: 0,
    yAccel: 0,
    // yGrow: null,
    // xGrow: true,
    // speed: 4,
    alive: true,
    size: 6,
    color: "#FFFF00"
  };
  menu.style.display = "none";
  const a1 = buildAsteroid();
  a1.x = 3 * canvasWidth / 4;
  const a2 = buildAsteroid();
  a2.x = 3 * canvasWidth / 4;
  const a3 = buildAsteroid();
  a3.x = canvasWidth / 2;
  const a4 = buildAsteroid();
  a4.x = canvasWidth / 2;
  const a5 = buildAsteroid();
  asteroids = [a1,a2,a3,a4,a5];
}

function drawAsteroids() {
  for (let asteroid of asteroids) {
    bounceObjectOffWall(asteroid);
    asteroid.x += asteroid.xGrow == null ? 0 : asteroid.xGrow ? asteroid.speed : -asteroid.speed;
    asteroid.y += asteroid.yGrow == null ? 0 : asteroid.yGrow ? asteroid.speed : -asteroid.speed;
    drawObject(asteroid);
    if (ship && hasCollision(asteroid, ship)) {
      gameOver();
    }
  }
}

function gameOver() {
  pause = true;
  ship.alive = false;
  menu.style.display = 'flex';
  start.innerHTML = 'Play Again?';
  if (score > +highScore.innerHTML) {
    highScore.innerHTML = score;
  }
}

function hasCollision(obj1, obj2) {
  const collisionDistance = obj1.size + obj2.size;
  const xVector = Math.pow(obj1.x - obj2.x, 2);
  const yVector = Math.pow(obj1.y - obj2.y, 2);
  return Math.sqrt(xVector + yVector) < collisionDistance;
}

function drawSpace() {
  ctx.fillStyle = "rgba(0,0,0,0.5)"; // 0.08
  ctx.fillRect(0, 0, canvasWidth, canvasHeight);
}

function moveShip(s) {
  ctx.lineWidth = 1;
  ctx.fillStyle = s.color;
  s.xVelocity += s.xAccel;
  s.yVelocity += s.yAccel;
  s.x += s.xVelocity;
  s.y += s.yVelocity;
  ctx.beginPath();
  ctx.moveTo(s.x - s.size / 2, s.y);
  ctx.arc(s.x, s.y, s.size, 0, 2 * Math.PI);
  ctx.fill();
}

function drawObject(obj) {
  ctx.lineWidth = 1;
  ctx.fillStyle = obj.color;
  ctx.beginPath();
  ctx.moveTo(obj.x - obj.size / 2, obj.y);
  ctx.arc(obj.x, obj.y, obj.size, 0, 2 * Math.PI);
  ctx.fill();
}

function bounceShipOffWall(s) {
  if (s.x - s.size <= 0) {
    s.xVelocity = 0.8 * Math.abs(s.xVelocity);
  }
  if (s.x + s.size >= canvasWidth) {
    s.xVelocity = -0.8 * Math.abs(s.xVelocity);
  }
  if (s.y - s.size <= 0) {
    s.yVelocity = 0.8 * Math.abs(s.yVelocity);
  }
  if (s.y + s.size >= canvasHeight) {
    s.yVelocity = -0.8 * Math.abs(s.yVelocity);
  }
}

function bounceObjectOffWall(obj) {
  if (obj.x - obj.size <= 0) {
    obj.xGrow = true;
  }
  if (obj.x + obj.size >= canvasWidth) {
    obj.xGrow = false;
  }
  if (obj.y - obj.size <= 0) {
    obj.yGrow = true;
  }
  if (obj.y + obj.size >= canvasHeight) {
    obj.yGrow = false;
  }
}

function drawShip() {
  if (ship && ship.alive) {
    bounceShipOffWall(ship);
    moveShip(ship);
    currScore.innerHTML = score++;
    if (score % 1000 === 0) {
      addOneAsteroidOnEachEdge();
    }
  }
}

setInterval(function() {
  if (!pause) {
    drawSpace();
    drawShip();
    drawAsteroids();
  } 
}, 10);

window.addEventListener("keydown", (e) => changeDirection(e, true), true);
window.addEventListener("keyup", (e) => changeDirection(e, false), true);

const accelerationMap = {};

function changeDirection(e, isKeyDown) {
  e = e || window.event;

  if (e.keyCode == "38") {
    // up arrow
    ship.yAccel = isKeyDown ? -0.08 : 0;
  }  
  if (e.keyCode == "40") {
    // down arrow
    ship.yAccel = isKeyDown ? 0.08 : 0;
  }  
  if (e.keyCode == "37") {
    // left arrow
    ship.xAccel = isKeyDown ? -0.08 : 0;
  }  
  if (e.keyCode == "39") {
    // right arrow
    ship.xAccel = isKeyDown ? 0.08 : 0;
  }
  e.preventDefault();
}

function addOneAsteroidOnEachEdge() {
  const aTop = buildAsteroid();
  aTop.x = randomIntFromUniformDistribution(0, canvasWidth);
  aTop.y = 0;
  const aRight = buildAsteroid();
  aRight.y = randomIntFromUniformDistribution(0, canvasHeight);
  aRight.x = canvasWidth;
  const aDown = buildAsteroid();
  aDown.x = randomIntFromUniformDistribution(0, canvasWidth);
  aDown.y = canvasHeight;
  const aLeft = buildAsteroid();
  aLeft.y = randomIntFromUniformDistribution(0, canvasHeight);
  aLeft.x = 0;
  asteroids = asteroids.concat(aTop, aRight, aDown, aLeft);
}

function buildAsteroid() {
  const randSpeed = randomIntFromUniformDistribution(1, 10) * 0.1;
  const randSize = randomIntFromUniformDistribution(5, 50);
  return {
    size: randSize,
    x: canvasWidth,
    y: randomIntFromUniformDistribution(0, canvasHeight),
    xGrow: false,
    yGrow: false,
    speed: randSpeed,
    color: getAsteroidColor()
  };
}

function getAsteroidColor() {
  return `hsla(${randomIntFromUniformDistribution(113, 255)},100%,60%,1)`;
}

function formatRGBA(r,g,b,a){
  return `rgb(${r},${g},${b},${a})`;
}

function rand255(){
  return randomIntFromUniformDistribution(0,255);
}

function randomIntFromUniformDistribution(mn, mx) {
  return ~~(Math.random() * (mx - mn + 1) + mn);
}
