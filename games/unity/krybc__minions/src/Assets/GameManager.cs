using System;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using Random = UnityEngine.Random;

public class GameManager : MonoBehaviour
{
    [SerializeField] private GameObject enemyPrefab;
    [SerializeField] private Text levelText;
    [SerializeField] private Text notifyText;
    [SerializeField] private Text scoreText;
    [SerializeField] private Transform[] enemyPositions;
    private int score = 0;
    private int level = 1;
    private int levelKilled = 25;
    private double initialEnemyPeriod = 1.1;
    private double enemyPeriodStep = 0.1;
    private double minEnemyPeriodStep = 0.2;
    private double enemyPeriod = 1;
    
    void Start()
    {
        CalculateLevel();
        InvokeEnemies();
        scoreText.text = score.ToString();
    }
    
    void Update()
    {
        scoreText.text = score.ToString();
    }

    private void InvokeEnemies()
    {
        enemyPeriod = initialEnemyPeriod - level * enemyPeriodStep;
        CancelInvoke(nameof(CreateEnemy));
        InvokeRepeating(nameof(CreateEnemy), 0.5f, (float) enemyPeriod);
    }

    void CreateEnemy()
    {
        GameObject enemy = Instantiate(enemyPrefab);
        int position = Random.Range(0, enemyPositions.Length);
        enemy.transform.position = enemyPositions[position].transform.position;
    }

    public void EnemyKilled()
    {
        double difference = Math.Abs(enemyPeriod * .00001);
        score++;
        int newLevel = CalculateLevel();
        if (newLevel != level && Math.Abs(enemyPeriod - minEnemyPeriodStep) > difference)
        {
            level = newLevel;
            ShowLevel();
            InvokeEnemies();
        }
    }

    private int CalculateLevel()
    {
        return (int) Math.Floor((float) score / levelKilled);
    }

    private void ShowLevel()
    {
        string levelLabel = "Level: ";
        levelText.text = levelLabel + level;
    }

    public void GameOver()
    {
        PlayerPrefs.SetInt("Score", score);
        SceneManager.LoadScene(0);
    }
}
