#pragma strict

function mainMenu() {
    menuButtons.AILevel = 0;
    GameSetup.isGamePaused = false;
    Scores.score1 = 0;
    Scores.score2 = 0;
    SceneManagement.SceneManager.LoadSceneAsync("Menu");
}