using System.Collections.Generic;
using DefaultNamespace;
using UnityEngine;

public class EnemySpawner : MonoBehaviour {
    public GameObject enemyPrefab;
    public int maxChildren = 5;
    public GameObject coinPrefab;
    public AudioClip explosionClip;

    private MapGenerator mapGenerator;
    private GameObject player;
    private GameObject enemiesContainer;
    private GameObject coinsContainer;
    private AudioManager audioManager;

    private Timer nextSpawnTimer = new Timer();
    private int aliveChildren = 0;

    private const int NEXT_SPAWN_TIME_MIN_MS = 3 * 1000;
    private const int NEXT_SPAWN_TIME_MAX_MS = 10 * 1000;

    void Start() {
        mapGenerator = GameObject.Find("MapGenerator").GetComponent<MapGenerator>();
        player = GameObject.Find("Player");
        enemiesContainer = GameObject.Find("EnemiesContainer");
        coinsContainer = GameObject.Find("CoinsContainer");
        audioManager = GameObject.Find("AudioManager").GetComponent<AudioManager>();

        nextSpawnTimer.Set(1000);
    }

    void Update() {
        Vector2 position = transform.position;
        Vector2 playerPosition = player.transform.position;
        float distanceToPlayer = Vector2.Distance(position, playerPosition);

        if (distanceToPlayer > 15f) return; // Perf optimization

        nextSpawnTimer.Update();

        if (aliveChildren < maxChildren && nextSpawnTimer.Check()) {
            var directions = new List<Vector2> {Vector2.up, Vector2.right, Vector2.down, Vector2.left};
            directions.Shuffle();

            var collisionMap = mapGenerator.GetCollisonMap();
            foreach (var direction in directions) {
                var spawnPosition = ((Vector2) position + direction);
                var (spawnX, spawnY) = Utils.VectorToTilemapCoord(spawnPosition);

                if (collisionMap[spawnX, spawnY]) continue; // Position occupied by tile, continue

                var enemy = Instantiate(enemyPrefab, spawnPosition, Quaternion.identity, enemiesContainer.transform);
                enemy.GetComponent<Enemy>().SetParent(this);

                nextSpawnTimer.Set(Random.Range(NEXT_SPAWN_TIME_MIN_MS, NEXT_SPAWN_TIME_MAX_MS));
                aliveChildren++;
                break;
            }
        }
    }

    public void ChildrenDied() {
        aliveChildren--;
    }

    public void OnDeath() {
        for (int i = 0; i < Random.Range(5, 10); i++) {
            Instantiate(coinPrefab, transform.position, Quaternion.identity, coinsContainer.transform);
        }
        
        audioManager.PlayExplosionSound(transform.position);
    }
}