#pragma strict

static var AILevel = 0;

function OnGUI() {
    
    var sWidth = Screen.width;
    var buttonW = 100;
    var buttonH = 25;
    var centerX = (sWidth / 2) - (buttonW / 2);
    var ttX = centerX + buttonW + 20;
    var ttY = 150;
    var localMPW = buttonW + 20;
    var localMPX = centerX - 10;
    var labelCenterX = centerX + 15;

    if (GUI.Button(Rect(localMPX, 50, localMPW, buttonH),
        GUIContent("Local Multiplayer", "Play against another player locally.")) ) {
        SceneManagement.SceneManager.LoadSceneAsync("Pong");
    }
    
    GUI.Box(new Rect(centerX-10, 100, 120, 180), "Play vs AI");
    
    if (GUI.Button(Rect(centerX, 150, buttonW, buttonH),
        GUIContent("Erratic", "The AI player moves randomly."))) {
        AILevel = 1;
        SceneManagement.SceneManager.LoadSceneAsync("Pong");
    }
    if (GUI.Button(Rect(centerX, 190, buttonW, buttonH),
        GUIContent("Following", "The AI player follows the ball."))) {
        AILevel = 2;
        SceneManagement.SceneManager.LoadSceneAsync("Pong");
    }
    if (GUI.Button(Rect(centerX, 230, buttonW, buttonH),
        GUIContent("Offensive", "The AI player tries to hit the ball at different angles."))) {
        AILevel = 3;
        SceneManagement.SceneManager.LoadSceneAsync("Pong");
    }

    // Display the tooltip from the element that has mouseover or keyboard focus
    GUI.Label(Rect(ttX, ttY, 100, 100), GUI.tooltip);
}