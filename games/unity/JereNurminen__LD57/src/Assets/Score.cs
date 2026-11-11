using System.Collections.Generic;
using UnityEngine;

public class Score : MonoBehaviour, IDifficultyConfigurable
{
    [SerializeField]
    private DifficultySettings<int> score;

    public List<Difficulty> allowedDifficulties { get; set; } =
        new List<Difficulty> { Difficulty.Easy, Difficulty.Medium, Difficulty.Hard };

    public void ScorePoints()
    {
        // Assuming you have a reference to the GameManager or a similar class
        GameManager gameManager = FindFirstObjectByType<GameManager>();
        if (gameManager != null)
        {
            gameManager.AddToScore(score);
        }
        else
        {
            Debug.LogError("GameManager not found in the scene.");
        }
    }

    public void SetDifficulty(Difficulty difficulty)
    {
        if (!allowedDifficulties.Contains(difficulty))
        {
            Destroy(gameObject);
            return;
        }
        score.SetDifficulty(difficulty);
    }

    public List<Difficulty> GetAllowedDifficulties()
    {
        return allowedDifficulties;
    }

    public void SetAllowedDifficulties(List<Difficulty> difficulties)
    {
        allowedDifficulties = difficulties;
    }
}
