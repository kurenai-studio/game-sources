#pragma strict

static var score1 : int = 0;
static var score2 : int = 0;

var textSkin: GUISkin;

static function Score ( wall : String ) {
    if (wall == "rightWall") {
        score1 += 1;
    } else if (wall == "leftWall") {
        score2 += 1;
    }
}

function OnGUI() {
    GUI.skin = textSkin;
    GUI.Label(new Rect(Screen.width / 2 - 300, 20, 100, 100), "" + score1);
    GUI.Label(new Rect(Screen.width / 2 + 300, 20, 100, 100), "" + score2);
}