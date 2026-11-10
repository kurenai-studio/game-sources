using UnityEngine;

public class TargetController : MonoBehaviour
{
    [SerializeField]
    private float explosionTimerLength = 1f;
    private float explosionTimer = 0f;
    private bool timerStarted = false;

    [SerializeField]
    private GameObject explosionEffectPrefab;

    [SerializeField]
    private GameObject carExplosionEffectPrefab;

    [SerializeField]
    private Vector2 explosionPivotOffset = Vector2.zero;

    [SerializeField]
    private float triggerRadius = 1.5f;

    private PlayerController playerController;

    private Animator animator;
    private Collider2D explosionCollider;
    private bool hasExploded = false;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        animator = GetComponent<Animator>();
        explosionCollider = GetComponent<Collider2D>();
        playerController = FindObjectOfType<PlayerController>();
    }

    // Update is called once per frame
    public void OnTargetDone()
    {
        timerStarted = true;
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (!other.CompareTag("Player") || !timerStarted)
            return;

        timerStarted = false;
        Explode(true);
    }

    void Update()
    {
        if (!timerStarted || hasExploded)
            return;

        if (
            Vector2.Distance(transform.position, playerController.transform.position)
            <= triggerRadius
        )
        {
            timerStarted = false;
            Explode(true);
            return;
        }

        if (explosionTimer < explosionTimerLength)
        {
            explosionTimer += Time.deltaTime;
            if (explosionTimer >= explosionTimerLength)
            {
                Explode();
            }
        }
    }

    private void Explode(bool isPlayerHit = false)
    {
        if (hasExploded)
            return;

        hasExploded = true;
        animator.SetTrigger("out");
        if (isPlayerHit)
        {
            var explosion = Instantiate(
                carExplosionEffectPrefab,
                (Vector3)playerController.BeamPosition,
                Quaternion.identity
            );
            explosion.GetComponent<SpriteRenderer>().sortingLayerName = "Terrain";
            explosion.GetComponent<SpriteRenderer>().sortingOrder = Mathf.RoundToInt(
                playerController.BeamPosition.y + 1
            );
            explosion.GetComponent<ExplosionHandler>().SetTarget(playerController.gameObject);
            playerController.Stop(true);
        }
        else
        {
            Instantiate(
                explosionEffectPrefab,
                transform.position + (Vector3)explosionPivotOffset,
                Quaternion.identity
            );
        }
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, triggerRadius);
    }
}
