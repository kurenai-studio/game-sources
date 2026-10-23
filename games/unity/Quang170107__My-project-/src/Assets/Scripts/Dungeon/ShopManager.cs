using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SimpleRPG
{
    /// <summary>
    /// Quản lý phòng cửa hàng xuất hiện sau mỗi 3 tầng.
    /// Hiện UI bán 4 món trang bị ngẫu nhiên + 1 Potion hồi máu.
    /// Người chơi dùng Gold để mua, sau đó bước vào portal để tiếp tục.
    /// </summary>
    public class ShopManager : MonoBehaviour
    {
        public static ShopManager Instance { get; private set; }

        // ── Data ─────────────────────────────────────────────────
        private readonly List<ShopSlot> _slots = new List<ShopSlot>();
        private bool _shopActive = false;

        // ── UI ───────────────────────────────────────────────────
        private Canvas _canvas;
        private GameObject _shopRoot;
        private Font _font;

        // UI per-slot
        private class ShopSlotUI
        {
            public GameObject root;
            public Image icon;
            public Text nameText;
            public Text statsText;
            public Text priceText;
            public Button buyButton;
            public Text buyBtnText;
        }
        private readonly List<ShopSlotUI> _slotUIs = new List<ShopSlotUI>();
        private Text _goldDisplayText;

        // ── World objects ────────────────────────────────────────
        private GameObject _merchantGo;

        private void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
            }
            else
            {
                Destroy(gameObject);
                return;
            }

            _font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            if (_font == null) _font = Font.CreateDynamicFontFromOSFont("Arial", 20);

            BuildShopUI();
        }

        // ── Public API ───────────────────────────────────────────

        /// <summary>Kiểm tra tầng hiện tại có xuất hiện cửa hàng không.</summary>
        public static bool IsShopFloor(int floor)
        {
            // Cửa hàng mở sau mỗi 3 tầng chiến đấu (tầng 3, 6, 9 …)
            // Tầng boss (5, 10, 15...) luôn là tầng chiến đấu, không thành cửa hàng
            return floor > 1 && floor % 3 == 0 && floor % 5 != 0;
        }

        /// <summary>Mở phòng cửa hàng: sinh NPC, tạo danh sách hàng, mở UI.</summary>
        public void OpenShop(int floor)
        {
            _shopActive = true;
            GenerateStock(floor);
            RefreshUI();
            _shopRoot.SetActive(true);

            // Sinh NPC thương nhân ở giữa phòng (phía trên)
            SpawnMerchant();

            GameUI.Instance?.ShowBanner("MERCHANT'S SHOP — Spend your Gold!", 3f);
        }

        /// <summary>Đóng UI shop (khi bước vào portal).</summary>
        public void CloseShop()
        {
            _shopActive = false;
            _shopRoot.SetActive(false);
            _slots.Clear();

            if (_merchantGo != null) Destroy(_merchantGo);
        }

        public bool IsShopOpen => _shopActive;

        // ── Stock generation ─────────────────────────────────────

        private void GenerateStock(int floor)
        {
            _slots.Clear();

            // 4 trang bị ngẫu nhiên
            for (int i = 0; i < 4; i++)
            {
                var item = EquipmentGenerator.Generate(floor);
                int price = CalculatePrice(item);
                _slots.Add(new ShopSlot { item = item, price = price, sold = false });
            }

            // 1 potion hồi máu
            float healAmount = 40f + floor * 5f;
            int potionPrice = 15 + floor * 3;
            _slots.Add(new ShopSlot
            {
                item = null,
                isPotionSlot = true,
                potionHeal = healAmount,
                price = potionPrice,
                sold = false
            });
        }

        private int CalculatePrice(EquipmentItem item)
        {
            // Giá dựa trên Score + modifier theo rarity
            float baseCost = item.Score * 1.2f + 10f;
            switch (item.rarity)
            {
                case Rarity.Rare:      baseCost *= 1.3f; break;
                case Rarity.Epic:      baseCost *= 1.8f; break;
                case Rarity.Legendary: baseCost *= 2.5f; break;
            }
            return Mathf.Max(10, Mathf.RoundToInt(baseCost));
        }

        // ── Buy logic ────────────────────────────────────────────

        private void TryBuy(int slotIndex)
        {
            if (slotIndex < 0 || slotIndex >= _slots.Count) return;
            var slot = _slots[slotIndex];
            if (slot.sold) return;

            var stats = PlayerController.Instance?.stats;
            if (stats == null) return;

            // Không cho mua thứ vô ích: potion khi đầy máu, trang bị không mạnh hơn đồ đang mặc
            if (slot.isPotionSlot && stats.currentHealth >= stats.maxHealth)
            {
                GameUI.Instance?.ShowBanner("HP is already full!", 1.5f);
                return;
            }

            if (!slot.isPotionSlot && slot.item != null)
            {
                var current = EquipmentManager.Get()?.GetEquipped(slot.item.slot);
                if (current != null && slot.item.Score <= current.Score)
                {
                    GameUI.Instance?.ShowBanner("Not an upgrade - you already wear better!", 2f);
                    return;
                }
            }

            if (stats.gold < slot.price)
            {
                GameUI.Instance?.ShowBanner("Not enough Gold!", 1.5f);
                AudioManager.Instance?.PlaySound("hurt");
                return;
            }

            // Trừ gold (không phát sound coin vì ta sẽ phát sound riêng)
            stats.gold -= slot.price;
            GameUI.Instance?.UpdateGold(stats.gold);

            if (slot.isPotionSlot)
            {
                stats.Heal(slot.potionHeal);
                GameUI.Instance?.ShowBanner($"Healed {Mathf.RoundToInt(slot.potionHeal)} HP!", 2f);
            }
            else
            {
                // Trang bị tự động mặc nếu mạnh hơn, không thì cộng gold lại (sell)
                var mgr = EquipmentManager.Get();
                if (mgr != null && mgr.TryEquip(slot.item))
                {
                    GameUI.Instance?.ShowBanner("EQUIPPED: " + slot.item.Describe(), 2.5f);
                }
                else
                {
                    // Không mạnh hơn đồ hiện tại → vẫn nhận nhưng bán ngay
                    int sellVal = slot.item.SellValue;
                    stats.gold += sellVal;
                    GameUI.Instance?.UpdateGold(stats.gold);

                    GameUI.Instance?.ShowBanner($"Bought & sold {slot.item.itemName} (+{sellVal}g)", 2f);
                }
            }

            AudioManager.Instance?.PlaySound("coin");
            slot.sold = true;
            RefreshUI();
        }

        // ── Merchant NPC ─────────────────────────────────────────

        private void SpawnMerchant()
        {
            if (_merchantGo != null) Destroy(_merchantGo);

            _merchantGo = new GameObject("Merchant_NPC");
            if (DungeonManager.Instance != null && DungeonManager.Instance.roomContainer != null)
                _merchantGo.transform.SetParent(DungeonManager.Instance.roomContainer, false);

            _merchantGo.transform.position = new Vector3(0, 2.5f, 0);

            var sr = _merchantGo.AddComponent<SpriteRenderer>();
            sr.sprite = SpriteFactory.CreateDiamond(56, new Color(1f, 0.85f, 0.3f), new Color(0.95f, 0.7f, 0.15f), 4);
            sr.sortingOrder = 10;

            // Tên NPC hiển thị phía trên
            var labelGo = new GameObject("Label");
            labelGo.transform.SetParent(_merchantGo.transform, false);
            labelGo.transform.localPosition = new Vector3(0, 1.2f, 0);

            var labelSr = labelGo.AddComponent<SpriteRenderer>();
            // Tạo 1 text mesh thay vì sprite label (giữ cho đơn giản, dùng TextMesh)
            Destroy(labelSr);
            var tm = labelGo.AddComponent<TextMesh>();
            tm.text = "MERCHANT";
            tm.fontSize = 42;
            tm.characterSize = 0.12f;
            tm.anchor = TextAnchor.MiddleCenter;
            tm.alignment = TextAlignment.Center;
            tm.color = new Color(1f, 0.9f, 0.4f);
            tm.GetComponent<MeshRenderer>().sortingOrder = 11;

            // Nhấp nhô nhẹ
            _merchantGo.AddComponent<MerchantBob>();
        }

        // ── UI Building ──────────────────────────────────────────

        private void BuildShopUI()
        {
            _canvas = gameObject.AddComponent<Canvas>();
            _canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            _canvas.sortingOrder = 55; // giữa GameUI (50) và InventoryUI (60)

            var scaler = gameObject.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);
            scaler.matchWidthOrHeight = 0.5f;

            gameObject.AddComponent<GraphicRaycaster>();

            // Khung chính
            _shopRoot = new GameObject("ShopRoot");
            _shopRoot.transform.SetParent(transform, false);
            var rootRt = _shopRoot.AddComponent<RectTransform>();
            rootRt.anchorMin = Vector2.zero;
            rootRt.anchorMax = Vector2.one;
            rootRt.offsetMin = Vector2.zero;
            rootRt.offsetMax = Vector2.zero;

            // Panel nền (phía dưới màn hình)
            var panelGo = MakeImage("ShopPanel", _shopRoot.transform,
                new Vector2(0.5f, 0), new Vector2(0.5f, 0), new Vector2(0.5f, 0),
                new Vector2(0, 10), new Vector2(1200, 260),
                new Color(0.08f, 0.1f, 0.16f, 0.92f));

            // Viền panel
            var borderGo = MakeImage("Border", panelGo.transform,
                Vector2.zero, Vector2.one, new Vector2(0.5f, 0.5f),
                Vector2.zero, Vector2.zero,
                Color.clear);
            borderGo.GetComponent<Image>().sprite =
                SpriteFactory.CreateRoundedRect(1200, 260, 12, Color.clear, new Color(1f, 0.8f, 0.2f, 0.8f), 3);

            // Tiêu đề
            var titleGo = MakeText("Title", panelGo.transform,
                new Vector2(0, 1), new Vector2(0, 1), new Vector2(0, 1),
                new Vector2(20, -10), new Vector2(300, 40),
                "MERCHANT'S WARES", 28, new Color(1f, 0.9f, 0.3f));
            titleGo.AddComponent<Outline>().effectColor = Color.black;

            // Gold hiển thị
            var goldGo = MakeText("GoldDisplay", panelGo.transform,
                new Vector2(1, 1), new Vector2(1, 1), new Vector2(1, 1),
                new Vector2(-20, -10), new Vector2(250, 40),
                "Gold: 0", 24, new Color(1f, 0.85f, 0.2f));
            _goldDisplayText = goldGo.GetComponent<Text>();

            // Hint text
            MakeText("Hint", panelGo.transform,
                new Vector2(1, 0), new Vector2(1, 0), new Vector2(1, 0),
                new Vector2(-20, 8), new Vector2(400, 28),
                "Enter the PORTAL to continue", 16, new Color(0.6f, 0.65f, 0.75f));

            // Tạo 5 slot (4 equipment + 1 potion)
            float startX = 30f;
            float slotW = 220f;
            float gap = 10f;

            for (int i = 0; i < 5; i++)
            {
                var slotUI = BuildSlotUI(panelGo.transform, startX + i * (slotW + gap), i);
                _slotUIs.Add(slotUI);
            }

            _shopRoot.SetActive(false);
        }

        private ShopSlotUI BuildSlotUI(Transform parent, float xPos, int index)
        {
            var sui = new ShopSlotUI();

            // Slot card
            var card = MakeImage("Slot_" + index, parent,
                new Vector2(0, 0), new Vector2(0, 0), new Vector2(0, 0),
                new Vector2(xPos, 8), new Vector2(220, 192),
                new Color(0.14f, 0.16f, 0.22f, 1f));
            sui.root = card;

            // Icon
            var iconGo = MakeImage("Icon", card.transform,
                new Vector2(0, 1), new Vector2(0, 1), new Vector2(0, 1),
                new Vector2(10, -8), new Vector2(48, 48),
                Color.white);
            sui.icon = iconGo.GetComponent<Image>();
            sui.icon.preserveAspect = true;

            // Name
            var nameGo = MakeText("Name", card.transform,
                new Vector2(0, 1), new Vector2(0, 1), new Vector2(0, 1),
                new Vector2(64, -10), new Vector2(148, 24),
                "Item Name", 17, Color.white);
            sui.nameText = nameGo.GetComponent<Text>();

            // Stats
            var statsGo = MakeText("Stats", card.transform,
                new Vector2(0, 1), new Vector2(0, 1), new Vector2(0, 1),
                new Vector2(10, -58), new Vector2(200, 60),
                "+stats", 14, new Color(0.75f, 0.8f, 0.88f));
            sui.statsText = statsGo.GetComponent<Text>();
            sui.statsText.alignment = TextAnchor.UpperLeft;

            // Price
            var priceGo = MakeText("Price", card.transform,
                new Vector2(0, 0), new Vector2(0, 0), new Vector2(0, 0),
                new Vector2(10, 46), new Vector2(100, 28),
                "50 G", 18, new Color(1f, 0.85f, 0.2f));
            sui.priceText = priceGo.GetComponent<Text>();

            // Buy button
            var btnGo = MakeImage("BuyBtn", card.transform,
                new Vector2(1, 0), new Vector2(1, 0), new Vector2(1, 0),
                new Vector2(-10, 40), new Vector2(90, 38),
                new Color(0.15f, 0.65f, 0.3f, 1f));
            var btn = btnGo.AddComponent<Button>();
            var btnColors = btn.colors;
            btnColors.highlightedColor = new Color(0.2f, 0.8f, 0.4f);
            btnColors.pressedColor = new Color(0.1f, 0.5f, 0.25f);
            btnColors.disabledColor = new Color(0.3f, 0.3f, 0.3f);
            btn.colors = btnColors;
            sui.buyButton = btn;

            int capturedIndex = index;
            btn.onClick.AddListener(() => TryBuy(capturedIndex));

            var btnTextGo = MakeText("BtnText", btnGo.transform,
                new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f),
                Vector2.zero, new Vector2(90, 38),
                "BUY", 18, Color.white);
            btnTextGo.GetComponent<Text>().alignment = TextAnchor.MiddleCenter;
            sui.buyBtnText = btnTextGo.GetComponent<Text>();

            return sui;
        }

        // ── Refresh ──────────────────────────────────────────────

        private void RefreshUI()
        {
            var stats = PlayerController.Instance?.stats;
            int playerGold = stats != null ? stats.gold : 0;

            if (_goldDisplayText != null)
                _goldDisplayText.text = $"Gold: {playerGold}";

            for (int i = 0; i < _slotUIs.Count; i++)
            {
                var ui = _slotUIs[i];
                if (i >= _slots.Count)
                {
                    ui.root.SetActive(false);
                    continue;
                }

                ui.root.SetActive(true);
                var slot = _slots[i];

                if (slot.sold)
                {
                    ui.nameText.text = "SOLD";
                    ui.nameText.color = new Color(0.5f, 0.5f, 0.5f);
                    ui.statsText.text = "";
                    ui.priceText.text = "";
                    ui.icon.color = new Color(1f, 1f, 1f, 0.2f);
                    ui.buyButton.interactable = false;
                    ui.buyBtnText.text = "—";
                    continue;
                }

                if (slot.isPotionSlot)
                {
                    ui.icon.sprite = SpriteFactory.GetSprite("potion_hp");
                    ui.icon.color = Color.white;
                    ui.nameText.text = "Health Potion";
                    ui.nameText.color = new Color(0.9f, 0.3f, 0.4f);
                    ui.statsText.text = $"Heal {Mathf.RoundToInt(slot.potionHeal)} HP instantly";
                    ui.priceText.text = $"{slot.price} G";
                    ui.buyButton.interactable = playerGold >= slot.price;
                    ui.buyBtnText.text = "BUY";
                }
                else
                {
                    var item = slot.item;
                    ui.icon.sprite = EquipmentIcons.Get(item);
                    ui.icon.color = item.RarityColor;
                    ui.nameText.text = $"[{item.rarity}] {item.itemName}";
                    ui.nameText.color = item.RarityColor;
                    ui.statsText.text = BuildStatsText(item);
                    ui.priceText.text = $"{slot.price} G";
                    ui.buyButton.interactable = playerGold >= slot.price;
                    ui.buyBtnText.text = "BUY";
                }
            }
        }

        private string BuildStatsText(EquipmentItem it)
        {
            var parts = new List<string>();
            if (it.damage > 0)     parts.Add($"+{it.damage:0.#} DMG");
            if (it.maxHealth > 0)  parts.Add($"+{it.maxHealth:0.#} HP");
            if (it.armor > 0)      parts.Add($"+{it.armor:0.#} ARM");
            if (it.moveSpeed > 0)  parts.Add($"+{it.moveSpeed:0.#} SPD");
            if (it.attackRate > 0) parts.Add($"+{it.attackRate:0.#} ATK/s");
            if (it.lifesteal > 0)  parts.Add($"+{Mathf.RoundToInt(it.lifesteal * 100f)}% LS");
            if (it.critChance > 0) parts.Add($"+{Mathf.RoundToInt(it.critChance * 100f)}% CRIT");
            return string.Join("\n", parts);
        }

        private void Update()
        {
            // Cập nhật gold display liên tục khi shop mở
            if (_shopActive && _goldDisplayText != null && PlayerController.Instance != null)
            {
                _goldDisplayText.text = $"Gold: {PlayerController.Instance.stats.gold}";
            }
        }

        // ── UI Helpers (giống GameUI pattern) ────────────────────

        private GameObject MakeImage(string name, Transform parent,
            Vector2 anchorMin, Vector2 anchorMax, Vector2 pivot,
            Vector2 pos, Vector2 size, Color color)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var rt = go.AddComponent<RectTransform>();
            rt.anchorMin = anchorMin;
            rt.anchorMax = anchorMax;
            rt.pivot = pivot;
            rt.anchoredPosition = pos;
            rt.sizeDelta = size;
            var img = go.AddComponent<Image>();
            img.color = color;
            return go;
        }

        private GameObject MakeText(string name, Transform parent,
            Vector2 anchorMin, Vector2 anchorMax, Vector2 pivot,
            Vector2 pos, Vector2 size,
            string content, int fontSize, Color color)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var rt = go.AddComponent<RectTransform>();
            rt.anchorMin = anchorMin;
            rt.anchorMax = anchorMax;
            rt.pivot = pivot;
            rt.anchoredPosition = pos;
            rt.sizeDelta = size;
            var txt = go.AddComponent<Text>();
            txt.font = _font;
            txt.text = content;
            txt.fontSize = fontSize;
            txt.color = color;
            txt.alignment = TextAnchor.MiddleLeft;
            txt.horizontalOverflow = HorizontalWrapMode.Overflow;
            txt.verticalOverflow = VerticalWrapMode.Overflow;
            txt.raycastTarget = false;
            return go;
        }
    }

    // ── Data ─────────────────────────────────────────────────────

    internal class ShopSlot
    {
        public EquipmentItem item;
        public int price;
        public bool sold;
        public bool isPotionSlot;
        public float potionHeal;
    }

    // ── Merchant bob animation ───────────────────────────────────

    public class MerchantBob : MonoBehaviour
    {
        private float _baseY;
        private float _timer;

        private void Start()
        {
            _baseY = transform.position.y;
            _timer = Random.Range(0f, Mathf.PI * 2f);
        }

        private void Update()
        {
            _timer += Time.deltaTime * 2.5f;
            var p = transform.position;
            p.y = _baseY + Mathf.Sin(_timer) * 0.12f;
            transform.position = p;
        }
    }
}
