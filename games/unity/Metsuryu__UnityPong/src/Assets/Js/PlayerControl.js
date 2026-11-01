#pragma strict

var moveUp : KeyCode;
var moveDown: KeyCode;
var speed: float = 10;

function moveAI(direction, moveSpeed: float) {
    GetComponent.<Rigidbody2D>().transform.position = Vector3.MoveTowards
        (transform.position, Vector3(transform.position.x, direction, 0), moveSpeed * Time.deltaTime);
}

function AIPlayer(AILevel) {

    if (AILevel == 1) {
        //Erratic
        var downSpeed = -100;
        var upSpeed = 100;
        var AIDirection = Random.Range(downSpeed, upSpeed);
        if (AIDirection < 10 && AIDirection > -10) {
            //Avoid very small movements
            return;
        } else {
            moveAI(AIDirection, speed * 2);
        }
    } else if (AILevel == 2) {
        //Following
        var BallPos = GameObject.Find("Ball").transform.position.y;
        moveAI(BallPos, speed / 2);
    } else if (AILevel == 3) {
        //Offensive
        BallPos = GameObject.Find("Ball").transform.position.y;
        moveAI(BallPos, speed / 2);
        var BallX = GameObject.Find("Ball").transform.position.x;
        var rightSide = 4.5;
        //If the ball is close to the right side
        if (BallX > rightSide) {
            var randAngle = Random.Range(-0.5, 0.5);
            moveAI(BallPos + randAngle, speed * 2);
        }
    }
}

function Update() {
    //Players Movement
    if (!GameSetup.isGamePaused) {
        if (menuButtons.AILevel > 0 && moveUp == KeyCode.UpArrow) {
            //Player2 Disabled
            AIPlayer(menuButtons.AILevel);
            return;
        }
        if (Input.GetKey(moveUp)) {
            GetComponent.<Rigidbody2D>().velocity.y = speed;
        } else if (Input.GetKey(moveDown)) {
            GetComponent.<Rigidbody2D>().velocity.y = -speed;
        } else {
            GetComponent.<Rigidbody2D>().velocity.y = 0;
        }

    } else {
        GetComponent.<Rigidbody2D>().velocity.y = 0;
    }
}