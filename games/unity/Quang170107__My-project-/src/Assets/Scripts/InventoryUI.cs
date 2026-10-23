using System.Collections.Generic;
using UnityEngine;
using UI = UnityEngine.UI;

namespace SimpleRPG
{
    /// <summary>
    /// Màn hình kho đồ: bấm I để mở/đóng (Esc cũng đóng).
    /// Hiện 4 ô trang bị đang mặc (hình, tên, chỉ số) và bảng chỉ số tổng của nhân vật.
    /// Tự tạo khi vào game, không cần gắn vào object nào.
    /// </summary>
    public class InventoryUI : MonoBehaviour
    {
        public static InventoryUI Instance { get; private set; }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void AutoCreate()
        {
            if (Instance != null) return;
            var go = new GameObject("InventoryUI");
            go.AddComponent<InventoryUI>();
        }

        private class SlotRow
        {
            public UI.Image icon;
            public UI.Text nameText;
            public UI.Text statsText;
        }

        private Font _font;
        private GameObject _panelRoot;
        private UI.Text _summaryText;
        private readonly SlotRow[] _rows = new SlotRow[4];
        private bool _open;
        private float _prevTimeScale = 1f;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;

            _font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            if (_font == null) _font = Font.CreateDynamicFontFromOSFont("Arial", 20);

            BuildUI();
            _panelRoot.SetActive(false);
        }

        private void OnDisable()
        {
            if (_open) Close();
        }

        private void Update()
        {
            if (TogglePressed())
            {
                if (_open) Close();
                else if (Time.timeScale > 0f && PlayerController.Instance != null) Open();
            }
            else if (_open && EscapePressed())
            {
                Close();
            }
        }

        // ---------------- Input (hỗ trợ cả Input System mới và cũ) ----------------

        private static bool TogglePressed()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = UnityEngine.InputSystem.Keyboard.current;
            return kb != null && kb.iKey.wasPressedThisFrame;
#else
            return Input.GetKeyDown(KeyCode.I);
#endif
        }

        private static bool EscapePressed()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = UnityEngine.InputSystem.Keyboard.current;
            return kb != null && kb.escapeKey.wasPressedThisFrame;
#else
            return Input.GetKeyDown(KeyCode.Escape);
#endif
        }

        // ---------------- Open / Close ----------------

        private void Open()
        {
            _prevTimeScale = Time.timeScale;
            Time.timeScale = 0f;
            Refresh();
            _panelRoot.SetActive(true);
            _open = true;
        }

        private void Close()
        {
            _panelRoot.SetActive(false);
            Time.timeScale = _prevTimeScale <= 0f ? 1f : _prevTimeScale;
            _open = false;
        }

        // ---------------- Build UI ----------------

        private void BuildUI()
        {
            var canvas = gameObject.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 60; // trên GameUI (50)

            var scaler = gameObject.AddComponent<UI.CanvasScaler>();
            scaler.uiScaleMode = UI.CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);
            scaler.matchWidthOrHeight = 0.5f;

            // Gợi ý phím ở góc dưới phải (luôn hiện)
            var hint = MakeText("InventoryHint", transform, new Vector2(1, 0), new Vector2(-20, 20), new Vector2(260, 30),
                18, new Color(1f, 1f, 1f, 0.7f), TextAnchor.LowerRight);
            hint.text = "[I] Inventory";

            // Lớp phủ tối toàn màn hình
            var overlay = MakeImage("Overlay", transform, new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero, new Color(0f, 0f, 0f, 0.6f));
            var overlayRt = overlay.rectTransform;
            overlayRt.anchorMin = Vector2.zero;
            overlayRt.anchorMax = Vector2.one;
            overlayRt.offsetMin = Vector2.zero;
            overlayRt.offsetMax = Vector2.zero;
            overlay.raycastTarget = true; // chặn click xuống game phía sau
            _panelRoot = overlay.gameObject;

            // Khung chính
            var panel = MakeImage("Panel", _panelRoot.transform, new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(760, 650),
                new Color(0.1f, 0.12f, 0.16f, 0.97f));

            var title = MakeText("Title", panel.transform, new Vector2(0, 1), new Vector2(30, -20), new Vector2(700, 50),
                36, new Color(1f, 0.95f, 0.8f), TextAnchor.MiddleLeft);
            title.text = "INVENTORY";

            string[] slotNames = { "WEAPON", "ARMOR", "BOOTS", "RING" };
            for (int i = 0; i < 4; i++)
            {
                float y = -90f - i * 100f;
                var rowBg = MakeImage("Row_" + slotNames[i], panel.transform, new Vector2(0, 1), new Vector2(30, y), new Vector2(700, 88),
                    new Color(0.16f, 0.19f, 0.25f, 1f));

                var row = new SlotRow();
                row.icon = MakeImage("Icon", rowBg.transform, new Vector2(0, 1), new Vector2(12, -12), new Vector2(64, 64), Color.white);
                row.icon.preserveAspect = true;

                row.nameText = MakeText("Name", rowBg.transform, new Vector2(0, 1), new Vector2(92, -10), new Vector2(480, 34),
                    24, Color.white, TextAnchor.MiddleLeft);
                row.statsText = MakeText("Stats", rowBg.transform, new Vector2(0, 1), new Vector2(92, -46), new Vector2(590, 30),
                    18, new Color(0.75f, 0.78f, 0.85f), TextAnchor.MiddleLeft);

                var slotLabel = MakeText("SlotLabel", rowBg.transform, new Vector2(1, 1), new Vector2(-14, -12), new Vector2(150, 28),
                    16, new Color(0.55f, 0.6f, 0.7f), TextAnchor.MiddleRight);
                slotLabel.text = slotNames[i];

                _rows[i] = row;
            }

            _summaryText = MakeText("Summary", panel.transform, new Vector2(0, 1), new Vector2(30, -500), new Vector2(700, 110),
                20, new Color(0.92f, 0.92f, 0.92f), TextAnchor.UpperLeft);

            var close = MakeText("CloseHint", panel.transform, new Vector2(0, 1), new Vector2(30, -612), new Vector2(700, 28),
                16, new Color(0.55f, 0.6f, 0.7f), TextAnchor.MiddleLeft);
            close.text = "Press I or Esc to close";
        }

        // ---------------- Refresh ----------------

        private void Refresh()
        {
            var mgr = EquipmentManager.Instance;

            foreach (EquipSlot slot in System.Enum.GetValues(typeof(EquipSlot)))
            {
                var row = _rows[(int)slot];
                var item = mgr != null ? mgr.GetEquipped(slot) : null;

                row.icon.sprite = item != null ? EquipmentIcons.Get(item) : EquipmentIcons.Get(slot);

                if (item == null)
                {
                    row.icon.color = new Color(1f, 1f, 1f, 0.25f);
                    row.nameText.text = "- empty -";
                    row.nameText.color = new Color(0.5f, 0.54f, 0.62f);
                    row.statsText.text = "";
                }
                else
                {
                    row.icon.color = item.RarityColor;
                    row.nameText.text = $"[{item.rarity}] {item.itemName}";
                    row.nameText.color = item.RarityColor;
                    row.statsText.text = StatsLine(item);
                }
            }

            RefreshSummary();
        }

        private void RefreshSummary()
        {
            var player = PlayerController.Instance;
            if (player == null || player.stats == null)
            {
                _summaryText.text = "";
                return;
            }

            var s = player.stats;
            _summaryText.text =
                $"Level {s.level}     Gold {s.gold}     HP {Mathf.CeilToInt(s.currentHealth)} / {Mathf.CeilToInt(s.maxHealth)}\n" +
                $"Damage {s.baseDamage:0.#}     Armor {s.armor:0.#}     Attack Rate {s.attackRate:0.#}/s\n" +
                $"Move Speed {s.moveSpeed:0.#}     Lifesteal {Mathf.RoundToInt(s.lifesteal * 100f)}%     Dash Cooldown {s.dashCooldown:0.#}s\n" +
                $"Crit Chance {Mathf.RoundToInt(Mathf.Min(s.critChance, CombatStats.MaxCritChance) * 100f)}%     Crit Damage x{s.critMultiplier:0.#}     Nova Cooldown {s.specialCooldown:0.#}s";
        }

        private static string StatsLine(EquipmentItem it)
        {
            var parts = new List<string>();
            if (it.damage > 0) parts.Add($"+{it.damage:0.#} Damage");
            if (it.maxHealth > 0) parts.Add($"+{it.maxHealth:0.#} HP");
            if (it.armor > 0) parts.Add($"+{it.armor:0.#} Armor");
            if (it.moveSpeed > 0) parts.Add($"+{it.moveSpeed:0.#} Speed");
            if (it.attackRate > 0) parts.Add($"+{it.attackRate:0.#} Attack/s");
            if (it.lifesteal > 0) parts.Add($"+{Mathf.RoundToInt(it.lifesteal * 100f)}% Lifesteal");
            if (it.critChance > 0) parts.Add($"+{Mathf.RoundToInt(it.critChance * 100f)}% Crit");
            return string.Join("     ", parts);
        }

        // ---------------- UI helpers ----------------

        private static RectTransform MakeRect(string name, Transform parent, Vector2 anchor, Vector2 pos, Vector2 size)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = anchor;
            rt.anchorMax = anchor;
            rt.pivot = anchor;
            rt.anchoredPosition = pos;
            rt.sizeDelta = size;
            return rt;
        }

        private static UI.Image MakeImage(string name, Transform parent, Vector2 anchor, Vector2 pos, Vector2 size, Color color)
        {
            var rt = MakeRect(name, parent, anchor, pos, size);
            var img = rt.gameObject.AddComponent<UI.Image>();
            img.color = color;
            img.raycastTarget = false;
            return img;
        }

        private UI.Text MakeText(string name, Transform parent, Vector2 anchor, Vector2 pos, Vector2 size,
            int fontSize, Color color, TextAnchor align)
        {
            var rt = MakeRect(name, parent, anchor, pos, size);
            var t = rt.gameObject.AddComponent<UI.Text>();
            t.font = _font;
            t.fontSize = fontSize;
            t.color = color;
            t.alignment = align;
            t.horizontalOverflow = HorizontalWrapMode.Wrap;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            t.raycastTarget = false;
            return t;
        }
    }
}
