using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class MenuScene : MonoBehaviour {
    private void Start() {
        var hsObject = GameObject.Find("HighScore");
        if (hsObject != null) {
            hsObject.GetComponent<Text>().text = $"high score: {PlayerPrefs.GetInt(GameOverScreen.HIGH_SCORE_KEY, 0)}";
        }
        
        var gameMaster = GameObject.Find("GameMaster");
        if (gameMaster != null) {
            Destroy(gameMaster);
        }
    }

    void Update() {
        if (Input.GetKeyDown(KeyCode.Space)) {
            SceneManager.LoadScene("GameScene");
        }

        if (Input.GetKeyDown(KeyCode.E)) {
            SceneManager.LoadScene("HelpScreen");
        }
    }
}