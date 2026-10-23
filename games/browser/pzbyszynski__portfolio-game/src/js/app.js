const canvas = document.getElementById("myCanvas");
const ctx = canvas.getContext('2d');
const startButton = document.getElementById("startButton");


canvas.width = canvas.clientWidth;
canvas.height = canvas.clientHeight;

let score = 0;
let gameRunning = false;

const keys = { ArrowLeft: false, ArrowRight: false, ArrowUp: false, ArrowDown: false };


const obstacle = {
  x: canvas.width / 2,
  y: 0,
  width: 30,
  height: 30,
  speed: 3,
  color: 'yellow'
};

const block = {
  x: canvas.width / 2 - 20,
  y: canvas.height - 60,
  width: 40,
  height: 40,
  speed: 4,
  color: 'red'
};

window.addEventListener('keydown', (e) => {
  if (e.key in keys) keys[e.key] = true;
});
window.addEventListener('keyup', (e) => {
  if (e.key in keys) keys[e.key] = false;
});

// Obsługa przycisku start
startButton.addEventListener('click', () => {
  if (!gameRunning) {
    resetGameData();
    gameRunning = true;
    startButton.style.display = 'none';
    gameLoop();
  }
});

// Funkcja sprawdzająca czy dwa obiekty się zderzyły AABB pion i poziom
function checkCollision(rect1, rect2) {
  return (
    rect1.x < rect2.x + rect2.width &&
    rect1.x + rect1.width > rect2.x &&
    rect1.y < rect2.y + rect2.height &&
    rect1.y + rect1.height > rect2.y
  );
}


function resetGameData() {
  score = 0;
  block.x = canvas.width / 2 - block.width / 2;
  block.y = canvas.height / 2 - block.height / 2;
  obstacle.x = Math.random() * (canvas.width - obstacle.width);
  obstacle.y = -obstacle.height;
  obstacle.speed = 3;
}


function gameOver() {
  gameRunning = false;
  startButton.style.display = 'inline-block';
  startButton.textContent = 'Zagraj ponownie';
}

function gameLoop() {
  if (!gameRunning) return;

  ctx.clearRect(0, 0, canvas.width, canvas.height);


  if (keys.ArrowLeft && block.x > 0) {
    block.x -= block.speed;
  }
  if (keys.ArrowRight && block.x < canvas.width - block.width) {
    block.x += block.speed;
  }
  if (keys.ArrowDown && block.y < canvas.height - block.height) {
    block.y += block.speed;
  }
  if (keys.ArrowUp && block.y > 0) {
    block.y -= block.speed;
  }


  obstacle.y += obstacle.speed;

  if (obstacle.y > canvas.height) {
    obstacle.y = -obstacle.height;
    obstacle.x = Math.random() * (canvas.width - obstacle.width);
    score++;
    if (score % 10 === 0) {
      obstacle.speed += 0.5;
    }
  }


  if (checkCollision(block, obstacle)) {
    gameOver();
    alert(`Koniec gry! Twój wynik to: ${score}`);
    return;
  }



  ctx.fillStyle = obstacle.color;
  ctx.fillRect(obstacle.x, obstacle.y, obstacle.width, obstacle.height);


  ctx.fillStyle = block.color;
  ctx.fillRect(block.x, block.y, block.width, block.height);


  ctx.fillStyle = "white";
  ctx.font = "20px Arial";
  ctx.textAlign = "left";
  ctx.fillText(`Wynik: ${score}`, 15, 30);

  requestAnimationFrame(gameLoop);
}
