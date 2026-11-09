using UnityEngine;
using UnityEngine.SceneManagement;

public class GameMaster : MonoBehaviour {
    public int coins = 80;
    public int currentLevel = 1;
    public int score = 0;

    private static GameMaster instance;
    
    private void Awake() {
        if (instance == null) {
            instance = this;
            DontDestroyOnLoad(gameObject);
        } else {
            Destroy(gameObject);
        }
    }

    public void AdvanceToNextLevel() {
        currentLevel += 1;
        SceneManager.LoadScene("GameScene");
    }

    public void GameOver() {
        SceneManager.LoadScene("GameOverScreen");
    }
}