using UnityEngine;
using UnityEngine.UI;

namespace SimpleRPG
{
    /// <summary>
    /// Chuỗi hạ gục liên tiếp (kill combo), lấy cảm hứng từ Hades / Dead Cells.
    /// Hạ gục kẻ địch trong vòng ComboWindow giây để nối combo. Cứ mỗi 5 combo
    /// nhận thêm vàng thưởng. Bị trúng đòn sẽ làm đứt combo.
    /// Tự tạo khi có kill đầu tiên nên không cần sửa GameBootstrap.
    /// </summary>
    public class ComboSystem : MonoBehaviour
    {
        public const float ComboWindow = 3f;
        public const int BonusEvery = 5;

        public static ComboSystem Instance { get; private set; }

        public int CurrentCombo { get; private set; }
        public int BestCombo { get; private set; }

        private float _timer;
        private Text _text;
        private Image _timerBar;
        private GameObject _root;
        private float _punch;

        public static void RegisterKill(Vector3 worldPos)
        {
            if (Instance == null)
            {
                var go = new GameObject("ComboSystem");
                go.AddComponent<ComboSystem>();
            }
            Instance.AddKill(worldPos);
        }

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            BuildUI();
        }

        private void OnDestroy()
        {
            if (Instance == this) Instance = null;
        }

        private void BuildUI()
        {
            var canvasGo = new GameObject("ComboCanvas");
            canvasGo.transform.SetParent(transform, false);
            var canvas = canvasGo.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 40;

            _root = new GameObject("ComboRoot");
            _root.transform.SetParent(canvasGo.transform, false);
            var rootRect = _root.AddComponent<RectTransform>();
            rootRect.anchorMin = rootRect.anchorMax = new Vector2(1f, 0.5f);
            rootRect.pivot = new Vector2(1f, 0.5f);
            rootRect.anchoredPosition = new Vector2(-30f, 60f);
            rootRect.sizeDelta = new Vector2(260f, 90f);

            var textGo = new GameObject("ComboText");
            textGo.transform.SetParent(_root.transform, false);
            _text = textGo.AddComponent<Text>();
            _text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            _text.fontSize = 34;
            _text.fontStyle = FontStyle.BoldAndItalic;
            _text.alignment = TextAnchor.MiddleRight;
            _text.raycastTarget = false;
            _text.horizontalOverflow = HorizontalWrapMode.Overflow;
            _text.verticalOverflow = VerticalWrapMode.Overflow;
            var outline = textGo.AddComponent<Outline>();
            outline.effectColor = new Color(0f, 0f, 0f, 0.9f);
            outline.effectDistance = new Vector2(2f, -2f);
            var textRect = textGo.GetComponent<RectTransform>();
            textRect.anchorMin = new Vector2(0f, 0.3f);
            textRect.anchorMax = Vector2.one;
            textRect.offsetMin = textRect.offsetMax = Vector2.zero;

            var barBg = new GameObject("TimerBG");
            barBg.transform.SetParent(_root.transform, false);
            var bgImg = barBg.AddComponent<Image>();
            bgImg.color = new Color(0f, 0f, 0f, 0.55f);
            bgImg.raycastTarget = false;
            var bgRect = barBg.GetComponent<RectTransform>();
            bgRect.anchorMin = new Vector2(0f, 0.08f);
            bgRect.anchorMax = new Vector2(1f, 0.22f);
            bgRect.offsetMin = bgRect.offsetMax = Vector2.zero;

            var barFill = new GameObject("TimerFill");
            barFill.transform.SetParent(barBg.transform, false);
            _timerBar = barFill.AddComponent<Image>();
            _timerBar.color = new Color(1f, 0.75f, 0.15f, 1f);
            _timerBar.raycastTarget = false;
            _timerBar.type = Image.Type.Filled;
            _timerBar.fillMethod = Image.FillMethod.Horizontal;
            _timerBar.fillOrigin = (int)Image.OriginHorizontal.Right;
            var fillRect = barFill.GetComponent<RectTransform>();
            fillRect.anchorMin = Vector2.zero;
            fillRect.anchorMax = Vector2.one;
            fillRect.offsetMin = fillRect.offsetMax = Vector2.zero;

            _root.SetActive(false);
        }

        public void AddKill(Vector3 worldPos)
        {
            CurrentCombo++;
            if (CurrentCombo > BestCombo) BestCombo = CurrentCombo;
            _timer = ComboWindow;
            _punch = 1f;

            if (CurrentCombo % BonusEvery == 0 && PlayerController.Instance != null)
            {
                int bonus = CurrentCombo / BonusEvery;
                PlayerController.Instance.stats.AddGold(bonus);
                DamageNumberManager.Instance?.SpawnNumber(worldPos + Vector3.up * 0.8f, bonus, new Color(1f, 0.85f, 0.2f), "COMBO +");
                AudioManager.Instance?.PlaySound("combo", 0.8f);
            }
            Refresh();
        }

        /// <summary>Gọi khi bắt đầu lượt chơi mới: xoá combo và kỷ lục combo của lượt trước.</summary>
        public void ResetRun()
        {
            BreakCombo();
            BestCombo = 0;
        }

        public void BreakCombo()
        {
            if (CurrentCombo == 0) return;
            CurrentCombo = 0;
            _timer = 0f;
            if (_root != null) _root.SetActive(false);
        }

        private void Update()
        {
            if (CurrentCombo == 0) return;

            // Chết hoặc game over: xoá combo
            if (PlayerController.Instance != null && PlayerController.Instance.stats.currentHealth <= 0f)
            {
                BreakCombo();
                return;
            }

            _timer -= Time.deltaTime;
            if (_timer <= 0f)
            {
                BreakCombo();
                return;
            }

            if (_timerBar != null) _timerBar.fillAmount = Mathf.Clamp01(_timer / ComboWindow);
            if (_punch > 0f)
            {
                _punch = Mathf.Max(0f, _punch - Time.unscaledDeltaTime * 6f);
                float s = 1f + _punch * 0.35f;
                _root.transform.localScale = new Vector3(s, s, 1f);
            }
        }

        private void Refresh()
        {
            if (_root == null || _text == null) return;
            _root.SetActive(CurrentCombo >= 2);
            if (CurrentCombo < 2) return;

            // Màu nóng dần theo combo
            Color c = CurrentCombo >= 20 ? new Color(1f, 0.3f, 0.3f)
                    : CurrentCombo >= 10 ? new Color(1f, 0.55f, 0.15f)
                    : new Color(1f, 0.9f, 0.3f);
            _text.color = c;
            _text.text = "x" + CurrentCombo + " COMBO";
        }
    }
}
