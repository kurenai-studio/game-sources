using UnityEngine;

/// <summary>
/// Central game state: playing / game over, score, and end-of-game UI.
/// Created on demand, so it never needs to be placed in a scene.
/// </summary>
public class GameManager : MonoBehaviour
{
    private static GameManager instance;

    public static GameManager Instance
    {
        get
        {
            if (instance == null)
            {
                instance = new GameObject("GameManager").AddComponent<GameManager>();
            }
            return instance;
        }
    }

    public bool IsGameOver { get; private set; }
    public int Score { get; private set; }

    private GameObject hudPanel;
    private GameObject gameOverPanel;

    private void Awake()
    {
        if (instance != null && instance != this)
        {
            Destroy(gameObject);
            return;
        }
        instance = this;
    }

    public void RegisterUI(GameObject hud, GameObject gameOver)
    {
        hudPanel = hud;
        gameOverPanel = gameOver;
        if (hudPanel != null)
        {
            hudPanel.SetActive(true);
        }
        if (gameOverPanel != null)
        {
            gameOverPanel.SetActive(false);
        }
    }

    public void AddScore(int amount = 1)
    {
        Score += amount;
    }

    public void TriggerGameOver()
    {
        if (IsGameOver)
        {
            return;
        }
        IsGameOver = true;
        if (hudPanel != null)
        {
            hudPanel.SetActive(false);
        }
        if (gameOverPanel != null)
        {
            gameOverPanel.SetActive(true);
        }
    }
}
