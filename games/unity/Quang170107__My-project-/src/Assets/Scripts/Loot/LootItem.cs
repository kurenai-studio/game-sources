using UnityEngine;

namespace SimpleRPG
{
    public enum LootType
    {
        XP,
        Coin,
        Potion,
        Chest
    }

    [RequireComponent(typeof(CircleCollider2D))]
    public class LootItem : MonoBehaviour
    {
        public LootType lootType = LootType.XP;
        public int value = 10;
        public float healAmount = 30f;
        public bool isChestOpened = false;

        private Transform _playerTransform;
        private SpriteRenderer _sr;
        private bool _isAttracted = false;
        private const float MagnetRadius = 3.0f;
        private const float FlySpeed = 9.0f;
        private Vector3 _initPos;
        private float _bobTimer = 0f;

        private void Awake()
        {
            _sr = GetComponent<SpriteRenderer>();
            if (_sr == null) _sr = gameObject.AddComponent<SpriteRenderer>();

            var col = GetComponent<CircleCollider2D>();
            col.isTrigger = true;
            col.radius = 0.5f;

            _initPos = transform.position;
            _bobTimer = Random.Range(0f, 6.28f);
        }

        private void Start()
        {
            if (PlayerController.Instance != null)
            {
                _playerTransform = PlayerController.Instance.transform;
            }

            SetupVisual();
        }

        public void SetupVisual()
        {
            if (_sr == null) _sr = GetComponent<SpriteRenderer>();

            switch (lootType)
            {
                case LootType.XP:
                    _sr.sprite = SpriteFactory.GetSprite("gem_xp");
                    _sr.sortingOrder = 5;
                    break;
                case LootType.Coin:
                    _sr.sprite = SpriteFactory.GetSprite("coin");
                    _sr.sortingOrder = 5;
                    break;
                case LootType.Potion:
                    _sr.sprite = SpriteFactory.GetSprite("potion_hp");
                    _sr.sortingOrder = 5;
                    break;
                case LootType.Chest:
                    _sr.sprite = SpriteFactory.GetSprite("chest");
                    _sr.sortingOrder = 6;
                    break;
            }
        }

        private void Update()
        {
            if (_playerTransform == null && PlayerController.Instance != null)
            {
                _playerTransform = PlayerController.Instance.transform;
            }

            if (_playerTransform == null) return;

            // Idle floating bob
            if (!_isAttracted && lootType != LootType.Chest)
            {
                _bobTimer += Time.deltaTime * 3.5f;
                transform.position = _initPos + new Vector3(0, Mathf.Sin(_bobTimer) * 0.08f, 0);
            }

            // Magnetic attraction for XP and Coins
            if (lootType == LootType.XP || lootType == LootType.Coin)
            {
                float dist = Vector2.Distance(transform.position, _playerTransform.position);
                if (dist <= MagnetRadius)
                {
                    _isAttracted = true;
                }

                if (_isAttracted)
                {
                    transform.position = Vector3.MoveTowards(transform.position, _playerTransform.position, FlySpeed * Time.deltaTime);
                    if (dist < 0.35f)
                    {
                        Collect();
                    }
                }
            }
            else if (lootType == LootType.Chest)
            {
                float dist = Vector2.Distance(transform.position, _playerTransform.position);
                if (dist <= 1.2f && !isChestOpened)
                {
                    OpenChest();
                }
            }
        }

        private void OnTriggerEnter2D(Collider2D collision)
        {
            if (collision.CompareTag("Player"))
            {
                if (lootType == LootType.Potion)
                {
                    var player = collision.GetComponent<PlayerController>();
                    if (player != null)
                    {
                        player.stats.Heal(healAmount);
                        VisualFX.Burst(transform.position, new Color(1f, 0.4f, 0.5f), 8, 3f, 0.45f);
                        Destroy(gameObject);
                    }
                }
                else if (lootType == LootType.XP || lootType == LootType.Coin)
                {
                    Collect();
                }
            }
        }

        private void Collect()
        {
            if (PlayerController.Instance == null) return;

            if (lootType == LootType.XP)
            {
                PlayerController.Instance.stats.AddXP(value);
                VisualFX.Burst(transform.position, new Color(0.45f, 0.9f, 1f), 3, 2f, 0.3f);
            }
            else if (lootType == LootType.Coin)
            {
                PlayerController.Instance.stats.AddGold(value);
                VisualFX.Burst(transform.position, new Color(1f, 0.85f, 0.2f), 4, 2.5f, 0.35f);
            }

            Destroy(gameObject);
        }

        public void OpenChest()
        {
            if (isChestOpened) return;
            isChestOpened = true;

            AudioManager.Instance?.PlaySound("portal");

            // Pop animation
            transform.localScale = Vector3.one * 1.3f;
            VisualFX.Burst(transform.position + Vector3.up * 0.2f, new Color(1f, 0.85f, 0.25f), 24, 5.5f, 0.7f);

            // Spew rewards
            LootManager.Instance?.SpawnCoin(transform.position + Vector3.left * 0.5f, 15);
            LootManager.Instance?.SpawnCoin(transform.position + Vector3.right * 0.5f, 15);
            LootManager.Instance?.SpawnPotion(transform.position + Vector3.up * 0.6f, 40f);
            LootManager.Instance?.SpawnXP(transform.position + Vector3.down * 0.5f, 50);

            // Pop floating reward note
            DamageNumberManager.Instance?.SpawnNumber(transform.position + Vector3.up * 0.8f, 30, Color.yellow, "+GOLD ");

            Destroy(gameObject, 0.4f);
        }
    }
}
