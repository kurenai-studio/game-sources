using UnityEngine;
using System.Collections;

public class GameManager : MonoBehaviour
{
    // Public Properties
    public int CurrentScore { get; private set; } 
    public int NumberOfLives { get; private set; } 
    
    // Editor Fields
    [Header("Game")] 
    [SerializeField] private int numberOfLives = 3;
    [SerializeField] private float timeBetweenRounds = 3;
    
    [Header("Player")]
    [SerializeField] private Player playerPrefab;

    [Header("Spawners")] 
    [SerializeField] private ObjectSpawner enemySpawnerScript;

    // Internal Fields
    private Player _playerScript;


    // Unity Events
    private void Start()
    {
        StartGame();
    }
    
    // Internal Functions

    private void StartGame()
    {
        // Add any startup code
        CurrentScore = 0;
        NumberOfLives = numberOfLives;
        StartRound();
    }

    private void StartRound()
    {
        _playerScript = Instantiate(playerPrefab, Vector2.zero, Quaternion.identity);
        enemySpawnerScript.StartSpawner();
        Debug.Log($"Player has {NumberOfLives} lives");
    }
    
    // Internal Functions
    private IEnumerator DelayedStartRound()
    {
        yield return new WaitForSeconds(timeBetweenRounds);
        StartRound();
    }
    
    // Public Functions
    public void PlayerHasDied()
    {
        Debug.Log("Player Has Died");
        enemySpawnerScript.StopSpawner();
        NumberOfLives--;

        if (NumberOfLives > 0)
        {
            StartCoroutine(DelayedStartRound());
        }
        else
        {
            Debug.Log("Game Over !!!");
        }

    }

}
