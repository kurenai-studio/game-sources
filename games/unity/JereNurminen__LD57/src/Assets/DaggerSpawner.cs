using System.Collections.Generic;
using UnityEngine;

public class DaggerSpawner : MonoBehaviour, IDifficultyConfigurable
{
    [SerializeField]
    private GameObject daggerPrefab; // Prefab of the dagger to spawn

    [SerializeField]
    private DifficultySettings<float> spawnInterval; // Time interval between spawns

    [SerializeField]
    private float timeSinceLastSpawnHit = 0f;
    private bool waitingToSpawn = true;

    [SerializeField]
    private float daggerRange = 62f;

    [SerializeField]
    private List<Difficulty> allowedDifficulties = new List<Difficulty>();

    private Difficulty difficulty;

    public List<Difficulty> GetAllowedDifficulties()
    {
        return allowedDifficulties;
    }

    public void SetAllowedDifficulties(List<Difficulty> difficulties)
    {
        allowedDifficulties = difficulties;
    }

    public void SetDifficulty(Difficulty difficulty)
    {
        Debug.Log($"Setting difficulty to {difficulty} for {gameObject.name}");
        Debug.Log($"Allowed difficulties: {string.Join(", ", allowedDifficulties)}");

        if (!allowedDifficulties.Contains(difficulty))
        {
            Destroy(gameObject); // Destroy the GameObject if the difficulty is not allowed
            return;
        }

        spawnInterval.SetDifficulty(difficulty);

        this.difficulty = difficulty;
    }

    void Update()
    {
        timeSinceLastSpawnHit += Time.deltaTime;

        if (waitingToSpawn && timeSinceLastSpawnHit >= spawnInterval)
        {
            SpawnDagger();
            timeSinceLastSpawnHit = 0f;
            waitingToSpawn = false;
        }
    }

    public void OnDaggerLaunch()
    {
        waitingToSpawn = true;
        timeSinceLastSpawnHit = 0f;
    }

    private void SpawnDagger()
    {
        if (daggerPrefab != null)
        {
            Debug.Log($"Spawning dagger at {transform.position}");
            GameObject dagger = Instantiate(daggerPrefab, transform.position, Quaternion.identity);
            DaggerController daggerController = dagger.GetComponent<DaggerController>();

            if (daggerController != null)
            {
                daggerController.SetRespawner(this); // Set the spawner reference in the dagger
                daggerController.SetDifficulty(this.difficulty); // Set the difficulty for the dagger
                daggerController.range = daggerRange; // Set the range for the dagger
                waitingToSpawn = true;
            }
        }
        else
        {
            Debug.LogWarning("DaggerPrefab or SpawnPoint is not assigned in DaggerSpawner.");
        }
    }

    private void OnDrawGizmos()
    {
        // Set the gizmo color
        Gizmos.color = Color.red;

        // Draw a wire sphere to represent the dagger range
        Gizmos.DrawWireSphere(transform.position, daggerRange);
    }
}
