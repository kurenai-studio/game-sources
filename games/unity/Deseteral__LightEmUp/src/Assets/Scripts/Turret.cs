using UnityEngine;

public enum Direction {
    Front, Back, Left, Right,
}

public class Turret : MonoBehaviour {
    public Sprite frontSprite;
    public Sprite backSprite;
    public Sprite leftSprite;
    public Sprite rightSprite;
    
    private ElectricalDevice electricalDevice;
    private AudioManager audioManager;
    private Tool tool;
    private Direction targetingDirection = Direction.Front;
    private SpriteRenderer spriteRenderer;
    
    private void Start() {
        electricalDevice = GetComponent<ElectricalDevice>();
        audioManager = GameObject.Find("AudioManager").GetComponent<AudioManager>();
        spriteRenderer = GetComponent<SpriteRenderer>();
        tool = GetComponent<Tool>();
        tool.toolType = ToolType.Gun;
    }

    private void Update() {
        if (electricalDevice.hasPower == false) return; // TODO: POTENTIAL PREF PROBLEM
        
        var position = transform.position;
        
        // Find closest enemy
        GameObject[] enemyGameObjects = GameObject.FindGameObjectsWithTag("Enemy");

        float maxDistance = 10f;

        Vector2 shootingDirection = Vector2.zero;
        foreach (var e in enemyGameObjects) {
            var targetPosition = e.transform.position;
            var distanceToTarget = Vector2.Distance(targetPosition, position);
            if (distanceToTarget > maxDistance) continue;

            if (CanSeeTarget(targetPosition)) {
                var directionToTarget = (targetPosition - position).normalized;
                shootingDirection = directionToTarget;
                break;
            }
        }

        if (shootingDirection != Vector2.zero) {
            bool didShoot = tool.Use(shootingDirection);
            if (didShoot) {
                audioManager.PlayShootingGunSound(transform.position);
            }

            if (Mathf.Abs(shootingDirection.x) > Mathf.Abs(shootingDirection.y)) {
                if (shootingDirection.x > 0) {
                    targetingDirection = Direction.Right;
                } else {
                    targetingDirection = Direction.Left;
                }
            } else {
                if (shootingDirection.y > 0) {
                    targetingDirection = Direction.Back;
                } else {
                    targetingDirection = Direction.Front;
                }
            }
        }

        switch (targetingDirection) {
            case Direction.Back: spriteRenderer.sprite = backSprite; break;
            case Direction.Front: spriteRenderer.sprite = frontSprite; break;
            case Direction.Left: spriteRenderer.sprite = leftSprite; break;
            case Direction.Right: spriteRenderer.sprite = rightSprite; break;
        }
    }
    
    private bool CanSeeTarget(Vector2 targetPosition) {
        int tilemapAndEnemiesMask = (1 << 6) | (1 << 8);
        RaycastHit2D hit = Physics2D.Linecast(transform.position, targetPosition, tilemapAndEnemiesMask);
        
        return hit.collider != null && hit.collider.gameObject.CompareTag("Enemy");
    }
}