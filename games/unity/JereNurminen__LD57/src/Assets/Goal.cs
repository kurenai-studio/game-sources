using UnityEngine;

public class Goal : MonoBehaviour
{
    [SerializeField]
    private LayerMask playerLayerMask;

    private PlayerController playerController;
    private GameManager gameManager;

    private bool playerInZone = false;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        playerController = FindFirstObjectByType<PlayerController>();
        gameManager = FindFirstObjectByType<GameManager>();
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        if (playerLayerMask == (playerLayerMask | (1 << other.gameObject.layer)))
        {
            playerInZone = true;
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (playerInZone && playerController.isGrounded && !gameManager.playerHasFinished)
        {
            gameManager.OnPlayerFinish();
        }
    }
}
