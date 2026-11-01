#pragma strict

var mainCam: Camera;

var topWall: BoxCollider2D;
var bottomWall: BoxCollider2D;
var leftWall: BoxCollider2D;
var rightWall: BoxCollider2D;

var Player1: Transform;
var Player2: Transform;

var escKey: KeyCode;
static var isGamePaused = false;

var menuUI: UnityEngine.Object;


function Start() {
    //Constraints
    topWall.size = new Vector2(mainCam.ScreenToWorldPoint(new Vector3(Screen.width * 2f, 0f, 0f)).x, 1f);
    topWall.offset = new Vector2(0f, mainCam.ScreenToWorldPoint(new Vector3(0f, Screen.height, 0f)).y + 0.5f);

    bottomWall.size = new Vector2(mainCam.ScreenToWorldPoint(new Vector3(Screen.width * 2f, 0f, 0f)).x, 1f);
    bottomWall.offset = new Vector2(0f, mainCam.ScreenToWorldPoint(new Vector3(0f, 0f, 0f)).y - 0.5f);

    leftWall.size = new Vector2(1f, mainCam.ScreenToWorldPoint(new Vector3(0f, Screen.height * 2f, 0f)).y);
    leftWall.offset = new Vector2(mainCam.ScreenToWorldPoint(new Vector3(0f, 0f, 0f)).x - 0.5f, 0f);

    rightWall.size = new Vector2(1f, mainCam.ScreenToWorldPoint(new Vector3(0f, Screen.height * 2f, 0f)).y);
    rightWall.offset = new Vector2(mainCam.ScreenToWorldPoint(new Vector3(Screen.width, 0f, 0f)).x + 0.5f, 0f);

    Player1.position.x = mainCam.ScreenToWorldPoint(new Vector3(75f, 0f, 0f)).x;
    Player2.position.x = mainCam.ScreenToWorldPoint(new Vector3(Screen.width - 75f, 0f, 0f)).x;
}

function pauseGame() {
    if (!isGamePaused) {
        isGamePaused = true;
    } else if(isGamePaused) {
        isGamePaused = false;
        BroadcastMessage("startBall");
    };
    //Pause menu (ESC)
    if (!menuUI) {
        menuUI = Canvas.Instantiate(Resources.Load("PauseMenu"));
    } else {
        Destroy(menuUI);
    };
}

function Update() {
    if (Input.GetKeyDown(escKey)) {
        //Menu
        pauseGame();
    }
}