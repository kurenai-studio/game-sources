using System;
using UnityEngine;

namespace SimpleRPG
{
    /// <summary>
    /// Bàn thờ máu (Blood Shrine) - sự kiện ngẫu nhiên kiểu Hades: chạm vào để đổi một phần máu
    /// lấy một nâng cấp ngẫu nhiên miễn phí. Chỉ dùng được một lần mỗi bàn thờ và không bao giờ
    /// giết người chơi (nếu quá yếu thì từ chối và không tốn gì).
    /// </summary>
    public class ShrineAltar : MonoBehaviour
    {
        private const float TouchRadius = 1.15f;
        private const float HintRadius = 3f;
        private const float CostFraction = 0.15f;
        private const float MinCost = 10f;

        private SpriteRenderer _body;
        private SpriteRenderer _crystal;
        private bool _used;
        private bool _hinted;
        private float _refuseCooldown;
        private float _pulse;

        private static Sprite _pillarSprite;
        private static Sprite _crystalSprite;

        private void Awake()
        {
            if (_pillarSprite == null) _pillarSprite = CreatePillarSprite();
            if (_crystalSprite == null)
                _crystalSprite = SpriteFactory.CreateCircle(16, new Color(1f, 0.15f, 0.2f, 1f), new Color(1f, 0.6f, 0.65f, 1f), 2);

            _body = gameObject.AddComponent<SpriteRenderer>();
            _body.sprite = _pillarSprite;
            _body.sortingOrder = 10;

            var crystalGo = new GameObject("Crystal");
            crystalGo.transform.SetParent(transform, false);
            crystalGo.transform.localPosition = new Vector3(0f, 1.3f, 0f);
            crystalGo.transform.localScale = Vector3.one * 0.8f;
            _crystal = crystalGo.AddComponent<SpriteRenderer>();
            _crystal.sprite = _crystalSprite;
            _crystal.sortingOrder = 11;

            _pulse = UnityEngine.Random.value * 6f;
        }

        private void Start()
        {
            VisualFX.AddShadow(transform, _body);
        }

        private void Update()
        {
            if (_refuseCooldown > 0f) _refuseCooldown -= Time.deltaTime;

            if (!_used)
            {
                _pulse += Time.deltaTime * 3f;
                float k = 0.75f + 0.25f * Mathf.Sin(_pulse);
                _crystal.color = new Color(1f, k * 0.35f, k * 0.4f, 1f);
                _crystal.transform.localScale = Vector3.one * (0.8f + 0.1f * Mathf.Sin(_pulse));
            }

            if (_used || PlayerController.Instance == null) return;

            float dist = Vector2.Distance(transform.position, PlayerController.Instance.transform.position);

            if (!_hinted && dist <= HintRadius)
            {
                _hinted = true;
                GameUI.Instance?.ShowBanner("Blood Shrine - touch it to trade HP for a free upgrade", 3f);
            }

            if (dist <= TouchRadius && _refuseCooldown <= 0f)
                TryActivate(PlayerController.Instance.stats);
        }

        private void TryActivate(CombatStats stats)
        {
            if (stats == null) return;

            float cost = Mathf.Round(Mathf.Max(MinCost, stats.maxHealth * CostFraction));

            // Không bao giờ giết người chơi
            if (stats.currentHealth <= cost + 5f)
            {
                _refuseCooldown = 2f;
                DamageNumberManager.Instance?.SpawnNumber(transform.position + Vector3.up * 1.6f, Mathf.RoundToInt(cost), new Color(0.8f, 0.8f, 0.8f), "NEED HP ");
                return;
            }

            _used = true;
            stats.currentHealth -= cost;

            Array values = Enum.GetValues(typeof(UpgradeType));
            UpgradeType type = (UpgradeType)values.GetValue(UnityEngine.Random.Range(0, values.Length));
            stats.ApplyUpgrade(type);

            GameUI.Instance?.ShowBanner($"BLOOD SHRINE: -{Mathf.RoundToInt(cost)} HP  ->  {FriendlyName(type)}", 3f);
            DamageNumberManager.Instance?.SpawnNumber(PlayerController.Instance.transform.position + Vector3.up * 0.9f, Mathf.RoundToInt(cost), new Color(0.9f, 0.1f, 0.15f), "-");

            AudioManager.Instance?.PlaySound("special");
            CameraFollow.Instance?.Shake(0.2f, 0.3f);
            VisualFX.Burst(transform.position + Vector3.up * 1.3f, new Color(1f, 0.2f, 0.25f), 28, 6f, 0.8f);
            VisualFX.DamagePulse(0.6f);

            // Tắt đèn pha lê: đã dùng
            _crystal.color = new Color(0.25f, 0.2f, 0.22f, 1f);
            _crystal.transform.localScale = Vector3.one * 0.6f;
            _body.color = new Color(0.65f, 0.62f, 0.68f, 1f);
        }

        private static string FriendlyName(UpgradeType type)
        {
            switch (type)
            {
                case UpgradeType.MaxHealth: return "Vitality (+max HP)";
                case UpgradeType.Damage: return "Power Strike (+damage)";
                case UpgradeType.MoveSpeed: return "Swift Boots (+speed)";
                case UpgradeType.AttackSpeed: return "Rapid Slash (+attack speed)";
                case UpgradeType.DashCooldown: return "Quick Step (-dash cooldown)";
                case UpgradeType.Lifesteal: return "Vampiric Edge (+lifesteal)";
                case UpgradeType.Armor: return "Iron Aegis (+armor)";
                case UpgradeType.CritChance: return "Eagle Eye (+crit)";
                case UpgradeType.NovaCooldown: return "Arcane Focus (-Nova cooldown)";
                case UpgradeType.Ignite: return "Ember Edge (burn)";
                case UpgradeType.Frostbite: return "Frost Touch (slow)";
                default: return type.ToString();
            }
        }

        /// <summary>Cột đá pixel-art: đế, thân gạch, mũ cột, đổ bóng 3 mức.</summary>
        private static Sprite CreatePillarSprite()
        {
            const int w = 28, h = 40;
            var px = new Color32[w * h];

            Color32 outline = new Color32(34, 30, 44, 255);
            Color32 light = new Color32(150, 144, 168, 255);
            Color32 mid = new Color32(110, 104, 130, 255);
            Color32 dark = new Color32(76, 70, 96, 255);
            Color32 rune = new Color32(226, 60, 80, 255);

            void Put(int x, int y, Color32 c)
            {
                if (x >= 0 && y >= 0 && x < w && y < h) px[y * w + x] = c;
            }

            void Block(int x0, int x1, int y0, int y1)
            {
                for (int y = y0; y <= y1; y++)
                {
                    for (int x = x0; x <= x1; x++)
                    {
                        bool edge = x == x0 || x == x1 || y == y0 || y == y1;
                        if (edge) { Put(x, y, outline); continue; }
                        float t = (x - x0) / (float)(x1 - x0);
                        Put(x, y, t < 0.3f ? light : (t < 0.7f ? mid : dark));
                    }
                }
            }

            Block(1, 26, 0, 6);    // đế
            Block(6, 21, 7, 28);   // thân
            Block(3, 24, 29, 35);  // mũ cột

            // Gạch trên thân
            for (int y = 11; y <= 25; y += 5)
                for (int x = 7; x <= 20; x++) Put(x, y, outline);

            // Rune đỏ khắc ở giữa thân
            Put(13, 18, rune); Put(14, 18, rune);
            Put(13, 19, rune); Put(14, 19, rune);
            Put(12, 20, rune); Put(15, 20, rune);
            Put(13, 16, rune); Put(14, 16, rune);

            var tex = new Texture2D(w, h, TextureFormat.RGBA32, false);
            tex.filterMode = FilterMode.Point;
            tex.SetPixels32(px);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, w, h), new Vector2(0.5f, 0.1f), 32f);
        }
    }
}
