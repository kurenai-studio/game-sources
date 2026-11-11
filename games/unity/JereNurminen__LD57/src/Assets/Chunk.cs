using System;
using System.Reflection;
using UnityEngine;
using UnityEngine.Events;

public class Chunk : MonoBehaviour
{
    public Vector2 entryPoint;
    public Vector2 exitPoint;
    public float cameraMinX;
    public float cameraMaxX;
    public int chunkIndex;

    private GameManager gameManager;
    private bool playerInChunk = false;
    private float entryY;
    private float exitY;
    public float cameraWorldMinX;
    public float cameraWorldMaxX;
    public Difficulty difficulty = Difficulty.Easy;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        gameManager = FindFirstObjectByType<GameManager>();
        entryY = transform.TransformPoint(entryPoint).y;
        exitY = transform.TransformPoint(exitPoint).y;
        cameraWorldMinX = transform.TransformPoint(new Vector2(cameraMinX, 0)).x;
        cameraWorldMaxX = transform.TransformPoint(new Vector2(cameraMaxX, 0)).x;

        // Automatically set difficulty for all components on this GameObject
        SetDifficultyForAllChildren();
    }

    private void SetDifficultyForAllChildren()
    {
        // Iterate through all child GameObjects
        foreach (Transform child in transform)
        {
            // Get all components that implement the IDifficultyConfigurable interface
            var configurableComponents = child.GetComponentsInChildren<IDifficultyConfigurable>(
                true
            );

            foreach (var component in configurableComponents)
            {
                component.SetDifficulty(difficulty); // Directly call the method
            }
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (
            entryY > gameManager.player.transform.position.y
            && gameManager.player.transform.position.y > exitY
        )
        {
            if (!playerInChunk)
            {
                Debug.Log("Player entered chunk: " + chunkIndex);
                playerInChunk = true;
                gameManager.OnPlayerEnterChunk(this);
            }
        }
        else
        {
            playerInChunk = false;
        }
    }

    void OnCollisionEnter2D(Collision2D collision)
    {
        Debug.Log(collision.collider.name + " entered chunk: " + chunkIndex);
        //gameManager.OnPlayerEnterChunk(this);
    }

    void OnDrawGizmos()
    {
        var localEntryPoint = transform.TransformPoint(entryPoint);
        var localExitPoint = transform.TransformPoint(exitPoint);
        var localCameraMinX = transform.TransformPoint(new Vector2(cameraMinX, 0)).x;
        var localCameraMaxX = transform.TransformPoint(new Vector2(cameraMaxX, 0)).x;

        Gizmos.color = Color.green;
        Gizmos.DrawWireSphere(localEntryPoint, 8f);
        Gizmos.DrawLine(localEntryPoint, localExitPoint);
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(localExitPoint, 8f);

        Gizmos.color = Color.blue;
        Gizmos.DrawLine(
            new Vector2(localCameraMinX, localEntryPoint.y),
            new Vector2(localCameraMinX, localExitPoint.y)
        );

        Gizmos.DrawLine(
            new Vector2(localCameraMaxX, localEntryPoint.y),
            new Vector2(localCameraMaxX, localExitPoint.y)
        );
    }
}
