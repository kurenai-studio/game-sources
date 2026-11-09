using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class GameOverScreen : MonoBehaviour {
    private Text scoreText;
    private GameMaster gameMaster;
    private int highScore;

    public static string HIGH_SCORE_KEY = "HighScore";
    
    void Start() {
        scoreText = GameObject.Find("Score").GetComponent<Text>();
        gameMaster = GameObject.Find("GameMaster").GetComponent<GameMaster>();

        var currentHigh = PlayerPrefs.GetInt(HIGH_SCORE_KEY, 0);
        if (gameMaster.score > currentHigh) {
            PlayerPrefs.SetInt(HIGH_SCORE_KEY, gameMaster.score);
            highScore = gameMaster.score;
        } else {
            highScore = currentHigh;
        }
    }

    void Update() {
        scoreText.text = $"Score: {gameMaster.score}\nhigh score: {highScore}";

        if (Input.GetKey(KeyCode.Space)) {
            SceneManager.LoadScene("MenuScene");
        }
    }
}