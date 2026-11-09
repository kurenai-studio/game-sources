using UnityEngine;
using Random = UnityEngine.Random;

public class Enemy : MonoBehaviour {
    public float speed = 3f;
    public float attentionRadius = 5.5f;

    public GameObject coinPrefab;

    private Vector2 delta = Vector2.zero;
    private Timer timer = new Timer();

    private new Rigidbody2D rigidbody;
    private GameObject player;
    private EnemySpawner parent;
    private GameObject coinsContainer;
    private AudioManager audioManager;
    private SpriteRenderer spriteRenderer;
    private GameMaster gameMaster;

    private int enemyType = 0;
    public Sprite[] sprites;

    private void Start() {
        rigidbody = GetComponent<Rigidbody2D>();
        audioManager = GameObject.Find("AudioManager").GetComponent<AudioManager>();
        player = GameObject.Find("Player");
        coinsContainer = GameObject.Find("CoinsContainer");
        spriteRenderer = GetComponent<SpriteRenderer>();
        gameMaster = GameObject.Find("GameMaster").GetComponent<GameMaster>();

        enemyType = Random.Range(0, 2);
        spriteRenderer.sprite = sprites[enemyType];
        if (enemyType == 0) {
            rigidbody.mass = 0.25f;
        } else {
            rigidbody.mass = 0.5f;
            GetComponent<Damageable>().health = 300;
        }
        
        timer.Set(0);
    }

    private void FixedUpdate() {
        Vector2 position = transform.position;
        Vector2 playerPosition = player.transform.position;
        float distanceToPlayer = Vector2.Distance(position, playerPosition);

        if (distanceToPlayer > 15f) return; // Perf optimization

        timer.Update();

        // Randomly change position
        if (timer.Check()) {
            ChangeDirection(new Vector2(Random.Range(-1f, 1f), Random.Range(-1f, 1f)));
        }

        // Is attracted to player?
        if (CanSeePlayer(playerPosition) && distanceToPlayer <= attentionRadius) {
            Vector2 directionToPlayer = (playerPosition - position).normalized;
            delta = directionToPlayer;
        } else { // Is attracted to cables? 
            // Find closest cable
            GameObject[] cableGameObjects = GameObject.FindGameObjectsWithTag("Cable");

            float maxDistance = 3f;
            float bestDistance = float.MaxValue;
            GameObject bestCable = null;

            foreach (var e in cableGameObjects) {
                var targetPosition = e.transform.position;
                var distanceToTarget = Vector2.Distance(targetPosition, position);
                if (distanceToTarget > maxDistance) continue;

                if (distanceToTarget < bestDistance) {
                    bestDistance = distanceToTarget;
                    bestCable = e;
                }
            }

            if (bestCable != null) {
                Vector2 directionToTarget = (Vector2)bestCable.transform.position - position;
                delta = directionToTarget;
            }
        }

        // Apply force
        rigidbody.AddForce(delta * speed, ForceMode2D.Force);
        
        // Flip sprite
        spriteRenderer.flipX = delta.x < 0;
    }

    private void ChangeDirection(Vector2 newDirection) {
        delta = newDirection;
        timer.Set(Random.Range(3000, 10000));
    }

    private void OnCollisionEnter2D(Collision2D target) {
        // Bounce off the wall
        if (target.gameObject.name == "Walls") {
            ChangeDirection(delta * -1);
        }
    }

    private bool CanSeePlayer(Vector2 playerPosition) {
        int tilemapAndPlayerMask = (1 << 7) | (1 << 8);
        RaycastHit2D hit = Physics2D.Linecast(transform.position, playerPosition, tilemapAndPlayerMask);

        return hit.collider != null && hit.collider.gameObject.CompareTag("Player");
    }

    public void SetParent(EnemySpawner enemySpawner) {
        parent = enemySpawner;
    }

    public void OnDeath() {
        parent.ChildrenDied();

        for (int i = 0; i < Random.Range(1, 5); i++) {
            Instantiate(coinPrefab, transform.position, Quaternion.identity, coinsContainer.transform);
        }
        
        audioManager.PlayExplosionSound(transform.position);
        
        gameMaster.score += 10;
    }

    public void PushBack(float strength) {
        Vector2 force = -delta * strength;
        rigidbody.AddForce(force, ForceMode2D.Impulse);
    }

    public Vector2 GetDelta() {
        return delta;
    }
}