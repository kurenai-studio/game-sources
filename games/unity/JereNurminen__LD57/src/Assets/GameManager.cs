using System;
using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Purchasing;

public class GameManager : MonoBehaviour
{
    [SerializeField]
    private GameObject startingChunk;

    [SerializeField]
    [Tooltip("Number of chunks to load in front of the player")]
    private int chunksForward = 3;

    [SerializeField]
    [Tooltip("Number of chunks to keep alive behind the player")]
    private int chunksBackward = 2;

    [SerializeField]
    private Chunk[] debugChunks;

    [SerializeField]
    private bool useDebugChunks = false;

    [SerializeField]
    private int scorePerChunk = 100;
    private int score = 0;

    public PlayerController player;
    private List<Chunk> loadedChunks;
    private int lastChunkIndex = 0;
    private HUDManager hudManager;
    private SlideInController slideInController;

    public Chunk currentChunk;

    private bool gameOver = false;

    private float timeSinceStarted = 0f;
    private bool playerHasStarted = false;
    public bool playerHasFinished = false;

    [SerializeField]
    private Chunk[] easyChunks;

    [SerializeField]
    private Chunk[] mediumChunks;

    [SerializeField]
    private Chunk[] hardChunks;

    [SerializeField]
    private Chunk goalChunk;

    [SerializeField]
    private TMPro.TMP_Text congratulationsText;

    private Chunk[] chunkQueue;

    void Awake()
    {
        hudManager = FindFirstObjectByType<HUDManager>();
        slideInController = FindFirstObjectByType<SlideInController>();

        if (hudManager == null)
        {
            throw new Exception("HUDManager not found in the scene");
        }

        if (slideInController == null)
        {
            throw new Exception("SlideInController not found in the scene");
        }
    }

    public void AddToScore(int amount)
    {
        Debug.Log($"Adding {amount} to score");
        score += amount;
        hudManager.UpdateScore(score);
    }

    public void OnPlayerDeath()
    {
        // Handle player death
        Debug.Log("Player has died");
        slideInController.SlideIn(
            score,
            () =>
            {
                gameOver = true;
                Debug.Log("Game Over");
            }
        );
    }

    int GetChunkIndex()
    {
        return lastChunkIndex++;
    }

    void LoadNextChunk()
    {
        var lastChunk = loadedChunks.Last();

        var nextChunkPrefab = chunkQueue.First();

        if (nextChunkPrefab == null)
        {
            Debug.LogError("no more chunks in the queue");
            return;
        }

        // Get the world position of the last chunk's exitPoint
        var currentExitPos = lastChunk.transform.TransformPoint(lastChunk.exitPoint);

        // Get the local position of the next chunk's entryPoint
        var entryPointLocal = nextChunkPrefab.entryPoint;

        // Calculate the spawn position
        var spawnPosition = currentExitPos - (Vector3)entryPointLocal;

        // Instantiate and add the new chunk
        var newChunk = Instantiate(nextChunkPrefab, spawnPosition, Quaternion.identity);
        AddChunk(newChunk);
        // drop the first chunk from the queue
        chunkQueue = chunkQueue.Skip(1).ToArray();
    }

    public void OnPlayerEnterChunk(Chunk chunk)
    {
        playerHasStarted = true;
        currentChunk = chunk;
        if (lastChunkIndex < chunk.chunkIndex + chunksForward)
        {
            LoadNextChunk();
        }
        AddToScore(scorePerChunk);
    }

    void AddChunk(Chunk chunk)
    {
        chunk.chunkIndex = GetChunkIndex();
        var oldName = chunk.gameObject.name;
        chunk.gameObject.name = "Chunk " + chunk.chunkIndex + " (" + oldName + ")";
        loadedChunks.Add(chunk);
    }

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        player = FindFirstObjectByType<PlayerController>();

        if (useDebugChunks && debugChunks.Length > 0)
        {
            chunkQueue = debugChunks.Append(goalChunk).ToArray();
        }
        else
        {
            var shuffledEasyChunks = ShuffleChunks(easyChunks);
            var shuffledMediumChunks = ShuffleChunks(mediumChunks);
            var shuffledHardChunks = ShuffleChunks(hardChunks);

            chunkQueue = shuffledEasyChunks
                .Concat(shuffledMediumChunks)
                .Concat(shuffledHardChunks)
                .Append(goalChunk)
                .ToArray();
        }

        loadedChunks = new List<Chunk>();
        var firstChunk = startingChunk.GetComponent<Chunk>();
        AddChunk(firstChunk);
        currentChunk = firstChunk;
        foreach (var i in Enumerable.Range(0, chunksForward))
        {
            LoadNextChunk();
        }
    }

    private Chunk[] ShuffleChunks(Chunk[] chunks)
    {
        var shuffled = chunks.ToArray(); // Create a copy to avoid modifying the original array
        for (int i = shuffled.Length - 1; i > 0; i--)
        {
            int randomIndex = UnityEngine.Random.Range(0, i + 1);
            var temp = shuffled[i];
            shuffled[i] = shuffled[randomIndex];
            shuffled[randomIndex] = temp;
        }
        return shuffled;
    }

    public void OnPlayerFinish()
    {
        Debug.Log(
            $"Player finished the game in {timeSinceStarted} seconds, with a score of {score}"
        );
        playerHasFinished = true;
        congratulationsText.text = congratulationsText.text
            .Replace("XX", Mathf.Floor(timeSinceStarted).ToString())
            .Replace("YY", score.ToString());
        congratulationsText.gameObject.SetActive(true);
    }

    // Update is called once per frame
    void Update()
    {
        if (playerHasStarted)
        {
            timeSinceStarted += Time.deltaTime;
        }

        if (gameOver && Input.anyKeyDown)
        {
            // Restart the game
            UnityEngine.SceneManagement.SceneManager.LoadScene(
                UnityEngine.SceneManagement.SceneManager.GetActiveScene().buildIndex
            );
        }
    }
}
