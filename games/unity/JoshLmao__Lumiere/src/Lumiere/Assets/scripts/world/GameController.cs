using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using System;
using UnityEngine.SceneManagement;

public class GameController : MonoBehaviour
{
    int m_score = 0;
    public int Score
    {
        get { return m_score; }
        set { m_score = value; }
    }

    [SerializeField]
    GameObject m_masterGlobalObject;

    [SerializeField]
    UIController m_ui;

    [SerializeField]
    GameObject m_playerPrefab;

    [SerializeField]
    GameObject m_enemyPrefab;

    [SerializeField]
    GameObject m_flyingEnemyPrefab;

    [SerializeField]
    GameObject m_enemySpawnParent;

    [SerializeField]
    GameObject m_playerSpawnPosition;

    [SerializeField]
    GameObject m_masterEnemySpawnLocations;

    [SerializeField]
    GameObject m_masterFlyingEnemySpawnLocations;

    public PlayerController Player;

    public bool IsGameFinished { get; set; }

    List<EnemyBase> m_enemies = new List<EnemyBase>();
    GameObject m_playerObject;
    double m_multiplier = 1;

    #region MonoBehaviors
    void Awake()
    {
        DontDestroyOnLoad(m_masterGlobalObject);

        StartSpawnPlayer();

        SpawnEnemies();
    }

    void Start ()
    {

	}
	
	void FixedUpdate()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
            OnQuitGame();
	}
    #endregion

    int SpawnEnemies(Transform[] spawnLocs, GameObject enemyPrefab, double range)
    {
        int spawnCount = 0;
        foreach(Transform t in spawnLocs)
        {
            if (t == m_masterFlyingEnemySpawnLocations.transform || t == m_masterEnemySpawnLocations.transform)
                continue;

            //Way to determine if to spawn enemies. As multiplier goes up, less chance of spawning enemies
            bool shouldSpawn = Math.Round(UnityEngine.Random.Range(0, (float)range), 0) == 0;
            if (!shouldSpawn)
                continue;

            GameObject enemyObject = Instantiate(enemyPrefab, t.position, t.rotation, m_enemySpawnParent.transform);
            EnemyBase enemy = enemyObject.GetComponent<EnemyBase>();
            enemy.OnEnemyKilled += OnEnemyKilled;

            enemy.Initialize(Player.gameObject.transform, 
                UnityEngine.Random.Range(Constants.ENEMY_MIN_HEALTH, Constants.ENEMY_MAX_HEALTH), 
                UnityEngine.Random.Range(Constants.ENEMY_MIN_POWER_DROPPED, Constants.ENEMY_MAX_POWER_DROPPED),
                UnityEngine.Random.Range(Constants.ENEMY_MIN_GUN_DAMAGE, Constants.ENEMY_MAX_GUN_DAMAGE));

            m_enemies.Add(enemy);
            spawnCount++;
        }

        return spawnCount;
    }

    void OnEnemyKilled(EnemyBase enemy)
    {
        Player.AddPower(enemy.PowerDropped);
        AddToScore(enemy.ScoreAmount);
    }


    public void AddToScore(int amount)
    {
        if ((amount % 1) == 0)
            Score += amount;
        else
        {
            //Round if need to
            int rounded = (int)Math.Round((double)amount, 0, MidpointRounding.ToEven);
            Score += (int)(rounded * m_multiplier);
        }
    }

    /// <summary>
    /// Spawn player at start of level
    /// </summary>
    void StartSpawnPlayer()
    {
        GameObject playerObject = Instantiate(m_playerPrefab);
        playerObject.transform.position = m_playerSpawnPosition.transform.position;

        Player = playerObject.GetComponent<PlayerController>();
        Player.CurrentHealth = Constants.PLAYER_TOTAL_HEALTH;

        //Incase prefab is inactive
        if (!playerObject.activeInHierarchy)
            playerObject.SetActive(true);
    }

    /// <summary>
    /// When the player falls down hole at end of level. Teleport to beginning
    /// </summary>
    public void RestartLevel()
    {
        //Player dies when falling into restart
        if (IsGameFinished)
            return;

        DestroyAllSpawnedEnemies();

        //Dont reload level. Just change player pos and respawn enemies
        Player.gameObject.transform.position = m_playerSpawnPosition.transform.position;
        Player.SpawnInvulnerability();

        SpawnEnemies();

                m_multiplier += 0.5;
        Debug.Log("Increased multiplier to '" + m_multiplier + "'");
    }

    void DestroyAllSpawnedEnemies()
    {
        foreach (Transform t in m_enemySpawnParent.transform)
        {
            //Only destroy spawned enemies
            if (t.gameObject.GetComponent<EnemyController>() != null)
                Destroy(t.gameObject);
        }
    }

    public void OnPlayerKilled()
    {
        m_ui.OnGameEnded();
        IsGameFinished = true;
    }

    /// <summary>
    /// Done by the "Restart" button once game has finished
    /// </summary>
    public void OnRestartScene()
    {
        IsGameFinished = false;
        Score = 0;
        m_ui.OnRestartGame();

        Destroy(Player.gameObject);
        DestroyAllSpawnedEnemies();

        StartSpawnPlayer();

        SpawnEnemies();
    }

    void SpawnEnemies()
    {
        if(m_enemies.Count > 0)
            m_enemies.Clear();

        Transform[] spawnLocs = m_masterEnemySpawnLocations.GetComponentsInChildren<Transform>();
        var normalSpawnCount = SpawnEnemies(spawnLocs, m_enemyPrefab, m_multiplier);
        Transform[] flyingSpawnLocs = m_masterFlyingEnemySpawnLocations.GetComponentsInChildren<Transform>();
        int flyingSpawnCount = SpawnEnemies(flyingSpawnLocs, m_flyingEnemyPrefab, 2);

        Debug.Log("Spawned '" + m_enemies.Count + "' enemies. - '" + flyingSpawnCount + "' flying enemies. '" + normalSpawnCount + "' normal enemies");
    }

    public void OnQuitGame()
    {
        Debug.Log("Exiting game...");
        Application.Quit();
    }
}
