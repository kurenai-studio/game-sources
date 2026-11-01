#pragma strict

var ballSpeed: float = 85;

function Start() {
    yield WaitForSeconds(0.2);
    startBall();
}

function startBall() {
    var startDirection = Random.Range(0f, 1f);
    if (startDirection <= 0.5) {
        //Right
        GetComponent.<Rigidbody2D>().AddForce(new Vector2(ballSpeed, 10));
    } else {
        //Left
        GetComponent.<Rigidbody2D>().AddForce(new Vector2(-ballSpeed, -10));
    };
}

function resetBall() {
    GetComponent.<Rigidbody2D>().velocity.x = 0;
    GetComponent.<Rigidbody2D>().velocity.y = 0;
    transform.position.x = 0;
    transform.position.y = 0;
    yield WaitForSeconds(0.2);
    startBall();
}

function stopBall() {
    GetComponent.<Rigidbody2D>().velocity.x = 0;
    GetComponent.<Rigidbody2D>().velocity.y = 0;
    transform.position.x = 0;
    transform.position.y = 0;
}

var ballHitAudio: AudioSource;
ballHitAudio = GetComponent.<AudioSource>();
function OnCollisionEnter2D (colInfo : Collision2D) {
    //Ball collides with player
    if (colInfo.collider.tag == "Player") {
        var velY = GetComponent.<Rigidbody2D>().velocity.y;
        GetComponent.<Rigidbody2D>().velocity.y = velY / 2 + colInfo.collider.GetComponent.<Rigidbody2D>().velocity.y / 2;
        var randomPitch = Random.Range(0.95f, 1.05f);
        ballHitAudio.pitch = randomPitch;
        ballHitAudio.Play();
    }
}

function Update() {
    if (GameSetup.isGamePaused) {
        stopBall();
    }

    var xVel: float = GetComponent.<Rigidbody2D>().velocity.x;
    //If the ball gets too slow, speed it up.
    if (xVel < 5f && xVel > -5 && xVel != 0) {
        if (xVel > 0) {
            GetComponent.<Rigidbody2D>().velocity.x = 8;
        } else {
            GetComponent.<Rigidbody2D>().velocity.x = -8;
        }
    }
}