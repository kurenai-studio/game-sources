using UnityEngine;

public class Damageable : MonoBehaviour {
    public int health = 100;

    public bool ignoreBullets = false;
    public bool ignoreEnemies = false;

    private bool blink = false;
    private Color originalColor;
    private SpriteRenderer spriteRenderer;

    private Enemy enemy;
    private EnemySpawner enemySpawner;
    private Player player;
    private GameMaster gameMaster;
    private AudioManager audioManager;

    void Start() {
        spriteRenderer = GetComponent<SpriteRenderer>();

        enemy = GetComponent<Enemy>();
        enemySpawner = GetComponent<EnemySpawner>();
        player = GetComponent<Player>();
        gameMaster = GameObject.Find("GameMaster").GetComponent<GameMaster>();
        audioManager = GameObject.Find("AudioManager").GetComponent<AudioManager>();

        originalColor = spriteRenderer.color;
    }

    void Update() {
        if (health <= 0) {
            if (enemy != null) enemy.OnDeath();
            if (enemySpawner != null) enemySpawner.OnDeath();

            if (player != null) {
                gameMaster.GameOver();
            } else {
                Destroy(gameObject);   
            }
        }

        if (blink) {
            spriteRenderer.color = Color.red;
            blink = false;
        } else {
            spriteRenderer.color = originalColor;
        }
    }

    private void OnCollisionEnter2D(Collision2D other) {
        if (other.collider.CompareTag("Bullet") && ignoreBullets == false) {
            health -= 34; // 33.3 rounded up
            blink = true;
            audioManager.PlayHurtSound(transform.position);
        }

        if (other.collider.CompareTag("Enemy") && ignoreEnemies == false) {
            health -= 5;
            blink = true;
            audioManager.PlayHurtSound(transform.position);
        }
    }
}