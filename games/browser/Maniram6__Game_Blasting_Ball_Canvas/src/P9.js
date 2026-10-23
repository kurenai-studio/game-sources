const canvas = document.querySelector("canvas");
canvas.width = innerWidth;
canvas.height = innerHeight;
const c = canvas.getContext("2d");

addEventListener("resize", function () {
  canvas.width = innerWidth;
  canvas.height = innerHeight;
});

function ClearL1() {
  c.beginPath();
  c.strokeStyle = "rgb(79, 79, 189)";
  c.fillStyle = "rgb(79, 79, 189)";
  c.rect(innerWidth / 4, innerHeight / 4, innerWidth / 2, innerHeight / 2);
  c.fill();
  c.stroke();
  c.closePath();

  c.beginPath();
  c.fillStyle = "white";
  c.textAlign = "center";
  c.fillText(
    "You reached the target of 6.",
    innerWidth / 2,
    innerHeight / 2 - 100
  );
  c.fillText(
    "click to proceed to next Level",
    innerWidth / 2,
    innerHeight / 2 - 30
  );
  c.fill();

  setTimeout(() => {
    game = 1;
    GameLevel = 2;
    score = 0;
    numOfTargets = 1;
    shoot = 0;
    bulletPositionX = characterPositionXL2;
    bulletPositionY = characterPositionYL2;
    createTargetsLevel2();
  }, 3000);
}

// For Game Level Changing>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.>>

let GameLevel = -2;
let game = 0;

// Logo Intro_______________________________________________________________________________________________

// For Two M's   >>>>>>>>>>>>>>>>>
c.lineWidth = 80;
c.strokeStyle = " #336699";
c.beginPath();
c.moveTo(563, 329);
c.lineTo(563, 171);
c.lineTo(623, 250);
c.lineTo(683, 171);
c.lineTo(743, 250);
c.lineTo(803, 171);
c.lineTo(803, 329);
c.moveTo(683, 171);
c.lineTo(683, 329);
c.stroke();
c.closePath();

// For R  >>>>>>>>>>>>>>>>>>>>>>>

c.lineWidth = 1;
c.strokeStyle = "red";
c.beginPath();
c.fillStyle = "red";
c.rect(663, 191, 10, 54);

c.moveTo(673, 212);
c.lineTo(703, 245);
c.lineTo(693, 245);
c.lineTo(673, 225);

c.ellipse(673, 204.5, 30, 13.5, 0, (3 * Math.PI) / 2, Math.PI / 2, false);
c.fill();
c.stroke();
c.closePath();

c.beginPath();
c.strokeStyle = "#336699";
c.fillStyle = "#336699";
c.ellipse(673, 204.5, 15, 5, 0, (3 * Math.PI) / 2, Math.PI / 2, false);
c.lineTo(673, 204.5);
c.fill();
c.stroke();

c.beginPath();
c.font = "30px arial";
c.strokeStyle = "red";
c.fillStyle = "red";
c.textAlign = "center";
c.fillText("MMR Games", 683, 380, 240);
c.fill();
c.stroke();

setTimeout(() => {
  c.clearRect(0, 0, innerWidth, innerHeight);
  GameLevel = -1;
}, 4000);
setTimeout(() => {
  GameLevel = 0;
  HomePage();
}, 6500);
// Presenting Game(MMR Games Presents)_____________________________________________________________________

function gamePresents() {
  requestAnimationFrame(gamePresents);

  if (GameLevel === -1) {
    c.beginPath();
    c.strokeStyle = "White";
    c.fillStyle = "white";
    c.textAlign = "center";
    c.font = "69 bad script";
    c.fillText("MMR Games Presents...", 329, 329);
    c.fill();
    c.stroke();
  }
}
gamePresents();

// Small Animation____________________________________________________________________________________________
// function smallAnimation() {
//   GameLevel = 0;
// }

// Home Page of Game_________________________________________________________________________________________

let boxPositionX = innerWidth / 4;
let boxPositionY = innerHeight / 4;

function HomePage() {
  c.clearRect(0, 0, innerWidth, innerHeight);

  if (GameLevel === 0) {
    document.querySelector("button").style.visibility = "visible";
    boxPositionX = innerWidth / 4;
    boxPositionY = innerHeight / 4;

    c.beginPath();
    c.fillStyle = "blue";
    c.rect(boxPositionX, boxPositionY, innerWidth / 2, innerHeight / 2);
    c.fill();
    c.closePath();

    c.beginPath();
    c.fillStyle = "red";
    c.font = "bold 60px arial";
    c.textAlign = "center";

    c.fillText(
      "Welcome To Blasting Ball",
      innerWidth / 2,
      boxPositionY + 60,
      innerWidth / 2 - 40
    );

    c.fill();
    c.closePath();
  }
}
function StartGame() {
  GameLevel = 1;
  c.clearRect(0, 0, innerWidth, innerHeight);
  document.querySelector("button").style.visibility = "hidden";

  game = 1;
}

// If possible a small backstory????????????????????????????????????????????????????????????????????????????

// Common functions for all Levels >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

// Using Pythagorus theorem for distance calculating
function distanceCalculation(x1, x2, y1, y2) {
  return Math.sqrt(Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2));
}

// Level - 1 .................................................................................................

let score = 0;
let LevelIncrementL1 = 0;
let LevelIncrementL2 = 0;
let LevelIncrementL3 = 0;

// For Main character specifications
let characterPositionX = innerWidth / 2;
let characterPositionY = innerHeight - 90;
let characterRadius = 20;
let characterColor = "gold";

// For obstacles Specification

let BlockX1 = 0;
let BlockX2 = characterPositionX + 80;
let XtraBlockX = characterPositionX - 80;
let XtraBlockY = innerHeight - 10;
let XtraBlockWidth = 160;
let XtraBlockHeight = 10;
let BlockY = 0;
let BlockWidth = characterPositionX - (80 + BlockX1);
let BlockHeight = innerHeight;

// For bullet Specifications
let bulletPositionX = characterPositionX;
let bulletPositionY = characterPositionY;
let bulletRadius = 5;
let bulletVelocity = 6;
let bulletColor = "white";
let shoot = 0;
let count = 0;

// For Targets Specifications
let numOfTargets = 1;
let targetsArr1 = [];
const targetsColor = ["red", "green", "blue", "violet", "pink"];
let targetRadius = 30;

function createTargetsLevel1() {
  targetsArr1 = [];

  for (let i = 0; i < numOfTargets; i++) {
    let targetInitialX = BlockWidth + 32 + Math.random() * 127;
    let targetInitialY = 30;

    let targetVelocityX = 0;
    let targetVelocityY = 0;
    const xdiff = characterPositionX - targetInitialX;
    const ydiff = characterPositionY - targetInitialY;
    if (xdiff > 0) {
      targetVelocityX = +1;
    } else {
      targetVelocityX = -1;
    }
    if (ydiff > 0) {
      targetVelocityY = +1;
    } else {
      targetVelocityY = -1;
    }

    let targetColor =
      targetsColor[Math.round(Math.random() * (targetsColor.length - 1))];

    targetsArr1.push(
      new OverallTargets(
        targetInitialX,
        targetInitialY,
        targetRadius,
        targetVelocityX,
        targetVelocityY,
        targetColor,
        i
      )
    );
  }
}
createTargetsLevel1();

function Refresh1() {
  c.beginPath();
  c.fillStyle = "white";
  c.fillText("Score : " + score, characterPositionX, 45, 200);
  c.font = "italic small-caps bold 30px arial";
  c.textAlign = "center";
  c.fill();
  c.closePath();

  // Block/Obstacles in Game
  c.beginPath();
  c.fillStyle = "grey";
  c.fill();
  c.fillRect(BlockX1, BlockY, BlockWidth, BlockHeight);
  c.fillRect(BlockX2, BlockY, BlockWidth, BlockHeight);
  c.fillRect(XtraBlockX, XtraBlockY, XtraBlockWidth, XtraBlockHeight);

  c.closePath();

  // For bullet four Directions

  for (let i = 1; i < 5; i++) {
    if (shoot === i) {
      if (count != i) {
        bulletPositionX = characterPositionX;
        bulletPositionY = characterPositionY;
      }

      c.beginPath();
      c.moveTo(characterPositionX, characterPositionY);
      c.lineTo(bulletPositionX, bulletPositionY);
      c.strokeStyle = bulletColor;
      c.stroke();
      c.closePath();

      c.beginPath();
      c.arc(bulletPositionX, bulletPositionY, bulletRadius, 0, 2 * Math.PI);
      c.lineWidth = 2;
      c.fillStyle = bulletColor;
      c.fill();
      c.stroke();
      c.closePath();

      if (i === 1) {
        bulletPositionY -= bulletVelocity;
      }
      if (i === 2) {
        bulletPositionX += bulletVelocity;
      }
      if (i === 3) {
        bulletPositionY += bulletVelocity;
      }
      if (i === 4) {
        bulletPositionX -= bulletVelocity;
      }

      count = i;
    }
  }

  // For main Game Character
  c.beginPath();
  c.arc(
    characterPositionX,
    characterPositionY,
    characterRadius,
    0,
    2 * Math.PI
  );
  c.lineWidth = 2;
  c.strokeStyle = characterColor;
  c.fillStyle = characterColor;
  c.fill();
  c.stroke();
  c.closePath();
}

// For Targets Tracking, bouncing, collision detection

function OverallTargets(x, y, r, dx, dy, color, i) {
  this.x = x;
  this.y = y;
  this.r = r;
  this.dx = dx;
  this.dy = dy;
  this.color = color;
  this.i = i;

  this.draw = function () {
    c.beginPath();
    c.arc(this.x, this.y, this.r, 0, 2 * Math.PI);
    c.lineWidth = 2;
    c.strokeStyle = this.color;
    c.fillStyle = this.color;
    c.fill();
    c.stroke();
    c.closePath();

    this.update();
  };
  this.update = function () {
    if (
      distanceCalculation(bulletPositionX, this.x, bulletPositionY, this.y) <
      bulletRadius + this.r
    ) {
      score++;

      if (score > 6) {
        game = 0;
        GameLevel = 0;

        ClearL1();

        // c.beginPath();
        // c.lineWidth = 3;
        // c.strokeStyle = "white";
        // c.fillStyle = "gold";
        // c.rect(boxPositionX, boxPositionY, innerWidth / 2, innerHeight / 2);
        // c.fill();
        // c.stroke();
        // c.closePath();
        // document.getElementById("btn").value = "Next";
        // document.querySelector("button").style.backgroundColor = "white";

        // document.querySelector("button").style.visibility = "visible";
      }

      targetsArr1.splice(this, 1);
      if (targetsArr1.length === 0) {
        LevelIncrementL1++;
        if (LevelIncrementL1 === 5) {
          numOfTargets++;
          LevelIncrementL1 = 0;
        }

        createTargetsLevel1();
      }
    }

    if (this.y + this.r > innerHeight || this.y - this.r < 0) {
      this.dy = -this.dy;
    }

    if (this.x + this.r > innerWidth || this.x - this.r < 0) {
      this.dx = -this.dx;
    }

    if (this.y - characterPositionY < 1 && this.y - characterPositionY > -1) {
      this.dy = 0;
    }
    if (this.x - characterPositionX < 1 && this.x - characterPositionX > -1) {
      this.dx = 0;
    }

    if (
      distanceCalculation(
        this.x,
        characterPositionX,
        this.y,
        characterPositionY
      ) <
      this.r + characterRadius
    ) {
      this.dx = 0;
      this.dy = 0;
      // console.log("GAme over");
      // alert("you lost");
      c.beginPath();
      c.fillStyle = "red";
      c.fillText("Game Over!", innerWidth / 2, innerHeight / 4, 600);
      c.fillText(
        "Your Score is " + score,
        innerWidth / 2,
        innerHeight / 4 + 60,
        600
      );

      c.font = "italic small-caps bold 30px arial";
      c.textAlign = "center";
      c.fill();
      c.closePath();
      game = 0;
    } else {
      this.x += this.dx;
      this.y += this.dy;
    }
  };
}

// Level - 2 .................................................................................................

// For Main character specifications

let characterPositionXL2 = innerWidth / 2;
let characterPositionYL2 = Math.round(innerHeight / 2);
let characterRadiusL2 = 20;
let characterColorL2 = "gold";

// For obstacles Specification

let BlockX = 0;
let BlockY1 = 0;
let BlockY2 = characterPositionYL2 + 80;
let BlockWidthL2 = innerWidth;
let BlockHeightL2 = characterPositionYL2 - 80;

// For Targets Specifications
let targetsArr2 = [];

function createTargetsLevel2() {
  targetsArr2 = [];

  for (let i = 0; i < numOfTargets; i++) {
    let bestXPosition = [30, innerWidth - 30];
    let targetInitialX = bestXPosition[Math.round(Math.random() * 1)];
    let targetInitialY = characterPositionYL2 - 50 + Math.random() * 100;

    targetVelocityX = 0;
    targetVelocityY = 0;
    const xdiffL2 = characterPositionXL2 - targetInitialX;
    const ydiffL2 = characterPositionYL2 - targetInitialY;
    if (xdiffL2 > 0) {
      targetVelocityX = +1;
    } else {
      targetVelocityX = -1;
    }
    if (ydiffL2 > 0) {
      targetVelocityY = +1;
    } else {
      targetVelocityY = -1;
    }

    let targetColor =
      targetsColor[Math.round(Math.random() * (targetsColor.length - 1))];

    targetsArr2.push(
      new OverallTargets2(
        targetInitialX,
        targetInitialY,
        targetRadius,
        targetVelocityX,
        targetVelocityY,
        targetColor,
        i
      )
    );
  }
}
if (GameLevel === 2) {
  createTargetsLevel2();
}

function Refresh2() {
  // Block/Obstacles in Game

  c.beginPath();
  c.fillStyle = "grey";

  c.fillRect(BlockX, BlockY1, BlockWidthL2, BlockHeightL2);
  c.fillRect(BlockX, BlockY2, BlockWidthL2, BlockHeightL2);
  c.fill();
  c.closePath();

  c.beginPath();
  c.fillStyle = "white";
  c.fillText("Score : " + score, characterPositionXL2, 45, 200);
  c.font = "italic small-caps bold 30px arial";
  c.textAlign = "center";
  c.fill();
  c.closePath();

  // For bullet four Directions

  for (let i = 1; i < 5; i++) {
    if (shoot === i) {
      if (count != i) {
        bulletPositionX = characterPositionXL2;
        bulletPositionY = characterPositionYL2;
      }

      c.beginPath();
      c.moveTo(characterPositionXL2, characterPositionYL2);
      c.lineTo(bulletPositionX, bulletPositionY);
      c.strokeStyle = bulletColor;
      c.stroke();
      c.closePath();

      c.beginPath();
      c.arc(bulletPositionX, bulletPositionY, bulletRadius, 0, 2 * Math.PI);
      c.lineWidth = 2;
      c.fillStyle = bulletColor;
      c.fill();
      c.stroke();
      c.closePath();

      if (i === 1) {
        bulletPositionY -= bulletVelocity;
      }
      if (i === 2) {
        bulletPositionX += bulletVelocity;
      }
      if (i === 3) {
        bulletPositionY += bulletVelocity;
      }
      if (i === 4) {
        bulletPositionX -= bulletVelocity;
      }

      count = i;
    }
  }

  // For main Game Character
  c.beginPath();
  c.arc(
    characterPositionXL2,
    characterPositionYL2,
    characterRadius,
    0,
    2 * Math.PI
  );
  c.lineWidth = 2;
  c.strokeStyle = characterColor;
  c.fillStyle = characterColor;
  c.fill();
  c.stroke();
  c.closePath();
}

// For Targets Tracking, bouncing, collision detection

function OverallTargets2(x, y, r, dx, dy, color, i) {
  this.x = x;
  this.y = y;
  this.r = r;
  this.dx = dx;
  this.dy = dy;
  this.color = color;
  this.i = i;

  this.draw = function () {
    c.beginPath();
    c.arc(this.x, this.y, this.r, 0, 2 * Math.PI);
    c.lineWidth = 2;
    c.strokeStyle = this.color;
    c.fillStyle = this.color;
    c.fill();
    c.stroke();
    c.closePath();

    this.update();
  };
  this.update = function () {
    if (
      distanceCalculation(bulletPositionX, this.x, bulletPositionY, this.y) <
      bulletRadius + this.r
    ) {
      score++;
      if (score > 6) {
        GameLevel = 3;
        score = 0;
        numOfTargets = 1;
        createTargets3();
      }

      targetsArr2.splice(this, 1);
      if (targetsArr2.length === 0) {
        LevelIncrementL2++;
        if (LevelIncrementL2 === 5) {
          numOfTargets++;
          LevelIncrementL2 = 0;
        }

        createTargetsLevel2();
      }
    }

    if (this.y + this.r > innerHeight || this.y - this.r < 0) {
      this.dy = -this.dy;
    }

    if (this.x + this.r > innerWidth || this.x - this.r < 0) {
      this.dx = -this.dx;
    }

    if (
      this.y - characterPositionYL2 < 1 &&
      this.y - characterPositionYL2 > -1
    ) {
      this.dy = 0;
    }
    if (
      this.x - characterPositionXL2 < 1 &&
      this.x - characterPositionXL2 > -1
    ) {
      this.dx = 0;
    }

    if (
      distanceCalculation(
        this.x,
        characterPositionXL2,
        this.y,
        characterPositionYL2
      ) <
      this.r + characterRadius
    ) {
      this.dx = 0;
      this.dy = 0;
      // console.log("GAme over");
      // alert("you lost");
      c.beginPath();
      c.fillStyle = "red";
      c.fillText("Game Over!", innerWidth / 2, innerHeight / 4, 600);
      c.fillText(
        "Your Score is " + score,
        innerWidth / 2,
        innerHeight / 4 + 60,
        600
      );

      c.font = "italic small-caps bold 30px arial";
      c.textAlign = "center";
      c.fill();
      c.closePath();
      game = 0;
    } else {
      this.x += this.dx;
      this.y += this.dy;
    }
  };
}

function correctArr() {
  for (let i = 0; i < targetsArr3.length; i++) {
    targetsArr3[i].forPosition = i;
  }
  console.log("correction function");
  console.log(targetsArr3);
}
let forPosition = 0;

// Level - 3 ................................................................................................

//  For Main character specifications
let characterPositionXL3 = innerWidth / 2;
let characterPositionYL3 = Math.round(innerHeight / 2);
let characterRadiusL3 = 20;
let characterColorL3 = "gold";

// // For obstacles Specification
let BlockX1L3 = 120;
let BlockX2L3 = characterPositionXL3 + 80;
let BlockY1L3 = 100;
let BlockY2L3 = characterPositionYL3 + 80;
let BlockWidthL3 = characterPositionXL3 - (80 + BlockX1L3);
let BlockHeightL3 = characterPositionYL3 - (80 + BlockY1L3);
let nearYBase = characterPositionYL3 - 80;
let farYBase = characterPositionYL3 + 80 + BlockHeightL3;
let nearXBase = characterPositionXL3 - 80;
let farXBase = characterPositionXL3 + 80 + BlockWidthL3;

// // For Targets Specifications

let targetsArr3 = [];

let positionChoice = [
  30 + Math.random() * (innerWidth - 60),
  30,
  innerWidth - 30,
];

function createTargets3() {
  targetsArr3 = [];
  for (let i = 0; i < numOfTargets; i++) {
    let targetInitialX = positionChoice[Math.round(Math.random() * 2)];
    let targetInitialY = 0;
    if (targetInitialX === positionChoice[0]) {
      let YChoice = [30, innerHeight - 30];
      targetInitialY = YChoice[Math.round(Math.random() * 1)];
    }
    if (targetInitialX === positionChoice[1]) {
      targetInitialY = 30 + Math.random() * (innerHeight - 60);
    }
    if (targetInitialX === positionChoice[2]) {
      targetInitialY = 30 + Math.random() * (innerHeight - 60);
    }

    let targetVelocityX = 0;
    let targetVelocityY = 0;

    const xdiffL3 = characterPositionXL3 - targetInitialX;
    const ydiffL3 = characterPositionYL3 - targetInitialY;
    if (xdiffL3 > 0) {
      targetVelocityX = +1;
    } else {
      targetVelocityX = -1;
    }
    if (ydiffL3 > 0) {
      targetVelocityY = +1;
    } else {
      targetVelocityY = -1;
    }

    let targetColor =
      targetsColor[Math.round(Math.random() * (targetsColor.length - 1))];
    forPosition = i;
    targetsArr3.push(
      new OverallTargets3(
        targetInitialX,
        targetInitialY,
        targetRadius,
        targetVelocityX,
        targetVelocityY,
        targetColor,
        forPosition
      )
    );
  }
}
if (GameLevel === 3) {
  createTargets3();
}

function Refresh3() {
  c.beginPath();
  c.fillStyle = "white";
  c.fillText("Score : " + score, characterPositionXL3, 45, 200);
  c.font = "italic small-caps bold 30px arial";
  c.textAlign = "center";
  c.fill();
  c.closePath();

  // Block/Obstacles in Game
  c.beginPath();
  c.fillStyle = "grey";
  c.fill();
  c.fillRect(BlockX1L3, BlockY1L3, BlockWidthL3, BlockHeightL3);
  c.fillRect(BlockX2L3, BlockY1L3, BlockWidthL3, BlockHeightL3);
  c.fillRect(BlockX1L3, BlockY2L3, BlockWidthL3, BlockHeightL3);
  c.fillRect(BlockX2L3, BlockY2L3, BlockWidthL3, BlockHeightL3);
  c.closePath();

  // For bullet four Directions

  for (let i = 1; i < 5; i++) {
    if (shoot === i) {
      if (count != i) {
        bulletPositionX = characterPositionXL3;
        bulletPositionY = characterPositionYL3;
      }

      c.beginPath();
      c.moveTo(characterPositionXL3, characterPositionYL3);
      c.lineTo(bulletPositionX, bulletPositionY);
      c.strokeStyle = bulletColor;
      c.stroke();
      c.closePath();

      c.beginPath();
      c.arc(bulletPositionX, bulletPositionY, bulletRadius, 0, 2 * Math.PI);
      c.lineWidth = 2;
      c.fillStyle = bulletColor;
      c.fill();
      c.stroke();
      c.closePath();

      if (i === 1) {
        bulletPositionY -= bulletVelocity;
      }
      if (i === 2) {
        bulletPositionX += bulletVelocity;
      }
      if (i === 3) {
        bulletPositionY += bulletVelocity;
      }
      if (i === 4) {
        bulletPositionX -= bulletVelocity;
      }

      count = i;
    }
  }

  // For main Game Character
  c.beginPath();
  c.arc(
    characterPositionXL3,
    characterPositionYL3,
    characterRadiusL3,
    0,
    2 * Math.PI
  );
  c.lineWidth = 2;
  c.strokeStyle = characterColor;
  c.fillStyle = characterColor;
  c.fill();
  c.stroke();
  c.closePath();
}

// For Targets Tracking, bouncing, collision detection

function OverallTargets3(x, y, r, dx, dy, color, i) {
  this.x = x;
  this.y = y;
  this.r = r;
  this.dx = dx;
  this.dy = dy;
  this.color = color;
  this.i = i;

  this.draw = function () {
    c.beginPath();
    c.arc(this.x, this.y, this.r, 0, 2 * Math.PI);
    c.lineWidth = 2;
    c.strokeStyle = this.color;
    c.fillStyle = this.color;
    c.fill();
    c.stroke();
    c.closePath();

    this.update();
  };
  this.update = function () {
    let a = [];
    let b = [];
    this.i = i;

    if (
      distanceCalculation(bulletPositionX, this.x, bulletPositionY, this.y) <=
      bulletRadius + this.r
    ) {
      score++;

      // console.log("logging stated here");
      // console.log(targetsArr3.forPosition);
      // console.log(i);
      // console.log(this.i, targetsArr3.length);

      targetsArr3.splice(i, 1);
      // for (let i = 0; i < targetsArr3.length; i++) {
      //   targetsArr3[i].forPosition = targetsArr3[i + 1].forPosition;
      // }

      // correctArr();

      // console.log("came here");
      // console.log(this.i, targetsArr3.length);
      console.log(targetsArr3);
      if (targetsArr3.length === 0) {
        LevelIncrementL3++;
        if (LevelIncrementL3 === 3) {
          numOfTargets++;
          LevelIncrementL3 = 0;
        }

        createTargets3();
      }
    }

    b[0] = BouncingConditions1(
      this.r,
      this.y,
      farYBase,
      this.x,
      BlockX1L3,
      nearXBase,
      this.dy
    );
    b[1] = BouncingConditions1(
      this.r,
      this.y,
      farYBase,
      this.x,
      BlockX2L3,
      farXBase,
      this.dy
    );
    b[2] = BouncingConditions1(
      this.r,
      this.y,
      nearYBase,
      this.x,
      BlockX1L3,
      nearXBase,
      this.dy
    );
    b[3] = BouncingConditions1(
      this.r,
      this.y,
      nearYBase,
      this.x,
      BlockX2L3,
      farXBase,
      this.dy
    );

    b[4] = BouncingConditions2(
      this.r,
      this.y,
      BlockY2L3,
      this.x,
      BlockX1L3,
      nearXBase,
      this.dy
    );
    b[5] = BouncingConditions2(
      this.r,
      this.y,
      BlockY2L3,
      this.x,
      BlockX2L3,
      farXBase,
      this.dy
    );
    b[6] = BouncingConditions2(
      this.r,
      this.y,
      BlockY1L3,
      this.x,
      BlockX1L3,
      nearXBase,
      this.dy
    );
    b[7] = BouncingConditions2(
      this.r,
      this.y,
      BlockY1L3,
      this.x,
      BlockX2L3,
      farXBase,
      this.dy
    );

    a[0] = BouncingConditions1(
      this.r,
      this.x,
      nearXBase,
      this.y,
      BlockY1L3,
      nearYBase,
      this.dx
    );
    a[1] = BouncingConditions1(
      this.r,
      this.x,
      farXBase,
      this.y,
      BlockY1L3,
      nearYBase,
      this.dx
    );
    a[2] = BouncingConditions1(
      this.r,
      this.x,
      farXBase,
      this.y,
      BlockY2L3,
      farYBase,
      this.dx
    );
    a[3] = BouncingConditions1(
      this.r,
      this.x,
      nearXBase,
      this.y,
      BlockY2L3,
      farYBase,
      this.dx
    );

    a[4] = BouncingConditions2(
      this.r,
      this.x,
      BlockX1L3,
      this.y,
      BlockY1L3,
      nearYBase,
      this.dx
    );
    a[5] = BouncingConditions2(
      this.r,
      this.x,
      BlockX2L3,
      this.y,
      BlockY1L3,
      nearYBase,
      this.dx
    );
    a[6] = BouncingConditions2(
      this.r,
      this.x,
      BlockX2L3,
      this.y,
      BlockY2L3,
      farYBase,
      this.dx
    );
    a[7] = BouncingConditions2(
      this.r,
      this.x,
      BlockX1L3,
      this.y,
      BlockY2L3,
      farYBase,
      this.dx
    );

    for (let i = 0; i < a.length; i++) {
      if (a[i] != undefined) {
        this.dx = a[i];
        a[i] = undefined;
      }
    }

    for (let i = 0; i < b.length; i++) {
      if (b[i] != undefined) {
        this.dy = b[i];
        b[i] = undefined;
      }
    }

    if (this.y + this.r > innerHeight || this.y - this.r < 0) {
      this.dy = -this.dy;
    }

    if (this.x + this.r > innerWidth || this.x - this.r < 0) {
      this.dx = -this.dx;
    }

    if (
      this.y - characterPositionYL3 < 1 &&
      this.y - characterPositionYL3 > -1
    ) {
      this.dy = 0;
    }
    if (
      this.x - characterPositionXL3 < 1 &&
      this.x - characterPositionXL3 > -1
    ) {
      this.dx = 0;
    }

    if (
      distanceCalculation(
        this.x,
        characterPositionXL3,
        this.y,
        characterPositionYL3
      ) <
      this.r + characterRadiusL3
    ) {
      // console.log("GAme over");
      this.dx = 0;
      this.dy = 0;
      // alert("you lost");
      c.beginPath();
      c.fillStyle = "red";
      c.fillText("Game Over!", innerWidth / 2, innerHeight / 4, 600);
      c.fillText(
        "Your Score is " + score,
        innerWidth / 2,
        innerHeight / 4 + 60,
        600
      );

      c.font = "italic small-caps bold 30px arial";
      c.textAlign = "center";
      c.fill();
      c.closePath();
      game = 0;
    } else {
      this.x += this.dx;
      this.y += this.dy;
    }
  };
}

function BouncingConditions1(
  radius,
  centerOne,
  x,
  centerTwo,
  a,
  b,
  oneVelocity
) {
  if (centerOne - radius === x && centerTwo > a && centerTwo < b) {
    return -oneVelocity;
  }
}
function BouncingConditions2(
  radius,
  centerOne,
  x,
  centerTwo,
  a,
  b,
  oneVelocity
) {
  if (centerOne + radius === x && centerTwo > a && centerTwo < b) {
    return -oneVelocity;
  }
}

// Strating of the game

function MainGameOn() {
  requestAnimationFrame(MainGameOn);
  if (GameLevel === 1) {
    c.clearRect(0, 0, innerWidth, innerHeight);
    Refresh1();

    for (let i = 0; i < targetsArr1.length; i++) {
      targetsArr1[i].draw();
    }
  }
  if (GameLevel === 2) {
    c.clearRect(0, 0, innerWidth, innerHeight);
    Refresh2();
    for (let i = 0; i < targetsArr2.length; i++) {
      targetsArr2[i].draw();
    }
  }
  if (GameLevel === 3) {
    c.clearRect(0, 0, innerWidth, innerHeight);
    Refresh3();
    for (let i = 0; i < targetsArr3.length; i++) {
      targetsArr3[i].draw();
    }
  }
}
MainGameOn();

// Game Controls

addEventListener("keypress", function (e) {
  if (game === 1) {
    if (e.key == "w" || e.key == "W") {
      shoot = 1;
    }
    if (e.key == "d" || e.key == "D") {
      shoot = 2;
    }
    if (e.key == "s" || e.key == "S") {
      shoot = 3;
    }
    if (e.key == "a" || e.key == "A") {
      shoot = 4;
    }
  }
});
