using UnityEngine;

public class CameraController : MonoBehaviour
{
    public bool isEnabled = true;
    public Vector2 offset;
    private PlayerController playerController;
    private GameManager gameManager;

    [SerializeField]
    private AudioClip bgMusic;
    private AudioSource audioSource;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        playerController = FindFirstObjectByType<PlayerController>();
        gameManager = FindFirstObjectByType<GameManager>();
        audioSource = GetComponent<AudioSource>();
        audioSource.clip = bgMusic;
        audioSource.Play();
        audioSource.loop = true;
    }

    // Update is called once per frame
    void LateUpdate()
    {
        if (!isEnabled)
        {
            return;
        }
        Vector3 targetPosition =
            playerController.transform.position + new Vector3(offset.x, offset.y, -10);

        float cameraHalfWidth =
            Camera.main.orthographicSize * ((float)Screen.width / Screen.height);

        /*
        float minX = gameManager.currentChunk.cameraWorldMinX + cameraHalfWidth;
        float maxX = gameManager.currentChunk.cameraWorldMaxX - cameraHalfWidth;

        if (targetPosition.x > transform.position.x && targetPosition.x > maxX)
        {
            targetPosition.x = transform.position.x;
        }
        else if (targetPosition.x < transform.position.x && targetPosition.x < minX)
        {
            targetPosition.x = minX;
        }

        // If the camera's target position is outside the bounds, don't move it
        if (targetPosition.x < minX || targetPosition.x > maxX)
        {
            Debug.Log("Camera out of bounds, " + minX + " " + targetPosition.x + " " + maxX);
            targetPosition.x = transform.position.x;
        }
        */

        transform.position = targetPosition;
    }
}
