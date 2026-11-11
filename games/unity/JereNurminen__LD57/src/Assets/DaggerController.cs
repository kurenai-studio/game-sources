using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DaggerController : MonoBehaviour, IDifficultyConfigurable
{
    [SerializeField]
    private DifficultySettings<float> speed;

    [SerializeField]
    public float range = 62f;

    [SerializeField]
    private DifficultySettings<float> waitTime;

    [SerializeField]
    private DifficultySettings<float> rotationSpeed;

    [SerializeField]
    private LayerMask wallMask;

    private float timeSincePlayerInRange = 0f;
    private bool isShooting = false;
    private Vector2 shootDirection;

    private PlayerController playerController;
    private Rigidbody2D rb;

    private Coroutine resetCoroutine;
    private Quaternion targetRotation = Quaternion.Euler(0, 0, 0); // Default to pointing upwards

    private Animator animator;

    [SerializeField]
    private List<Difficulty> allowedDifficulties = new List<Difficulty>(); // Backing field for allowed difficulties

    public List<Difficulty> GetAllowedDifficulties()
    {
        return allowedDifficulties;
    }

    public void SetAllowedDifficulties(List<Difficulty> difficulties)
    {
        allowedDifficulties = difficulties;
    }

    private DaggerSpawner spawner;

    private bool hasSeenPlayer = false;

    [SerializeField]
    private LayerMask solidLayerMask;

    void Start()
    {
        playerController = FindFirstObjectByType<PlayerController>();
        rb = GetComponent<Rigidbody2D>();
        animator = GetComponent<Animator>();
    }

    public void SetRespawner(DaggerSpawner newSpawner)
    {
        spawner = newSpawner;
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

        speed.SetDifficulty(difficulty);
        waitTime.SetDifficulty(difficulty);
        rotationSpeed.SetDifficulty(difficulty);
    }

    void Update()
    {
        if (!isShooting)
        {
            var distanceToPlayer = Vector2.Distance(
                transform.position,
                playerController.transform.position
            );

            if (distanceToPlayer < range)
            {
                RotateTowardsPlayer();

                timeSincePlayerInRange += Time.deltaTime;
                if (timeSincePlayerInRange >= waitTime)
                {
                    ShootTowardsPlayer();
                }
            }
            else
            {
                timeSincePlayerInRange = 0f;
            }
        }

        // Smoothly rotate towards the target rotation
        transform.rotation = Quaternion.RotateTowards(
            transform.rotation,
            targetRotation,
            rotationSpeed * Time.deltaTime
        );
    }

    public void Die()
    {
        GetComponent<BoxCollider2D>().enabled = false;
        rb.linearVelocity = Vector2.zero; // Stop the dagger's movement
        animator.SetTrigger("death");
    }

    public void OnAnimationEnd()
    {
        Destroy(gameObject);
    }

    private void RotateTowardsPlayer()
    {
        Vector2 direction = (
            playerController.playerCollider.bounds.center - transform.position
        ).normalized;
        float angle = Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg - 90f;
        targetRotation = Quaternion.Euler(0, 0, angle); // Update the target rotation
    }

    private void ShootTowardsPlayer()
    {
        isShooting = true;
        shootDirection = (playerController.transform.position - transform.position).normalized;
        rb.linearVelocity = shootDirection * speed;

        if (spawner != null)
        {
            spawner.OnDaggerLaunch();
        }
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (wallMask == (wallMask | (1 << collision.gameObject.layer)))
        {
            // Trigger the dagger's death when it hits a wall
            Die();
        }
    }
}
