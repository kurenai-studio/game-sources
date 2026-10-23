using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using System.Runtime.ConstrainedExecution;

#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem.UI;
#endif

namespace SimpleRPG
{
    public class GameUI : MonoBehaviour
    {
        public static GameUI Instance { get; private set; }

        private Font _font;
        private Canvas _canvas;

        // Top HUD
        private Image _hpFill;
        private Text _hpText;
        private Image _xpFill;
        private Text _xpText;
        private Text _goldText;
        private Text _floorText;
        private Text _enemyText;
        private Text _relicsText;

        // Skill cooldowns
        private Image _dashCdFill;
        private Image _specialCdFill;

        // Banner
        private GameObject _bannerRoot;
        private Text _bannerText;
        private float _bannerTimer = 0f;

        // Upgrade Modal
        private GameObject _upgradeModalRoot;
        private readonly List<GameObject> _upgradeCards = new List<GameObject>();

        // Game Over Modal
        private GameObject _gameOverRoot;
        private Text _gameOverStatsText;

        // Settings Panel
        private GameObject _settingsRoot;
        private Text _resolutionValueText;
        private Text _vsyncValueText;
        private Text _vibrationValueText;
        private Text _windowModeValueText;
        private bool _settingsOpen = false;
        private float _prevTimeScale = 1f;

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
            if (_font == null)
            {
                _font = Font.CreateDynamicFontFromOSFont("Arial", 20);
            }

            BuildUI();
        }

        private void BuildUI()
        {
            // Canvas setup
            _canvas = gameObject.AddComponent<Canvas>();
            _canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            _canvas.sortingOrder = 50;

            var scaler = gameObject.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);
            scaler.matchWidthOrHeight = 0.5f;

            gameObject.AddComponent<GraphicRaycaster>();

            // Ensure EventSystem
            EnsureEventSystem();

            // Build HUD sections
            BuildTopHUD();
            BuildSkillBarHUD();
            BuildBannerUI();
            BuildUpgradeModal();
            BuildGameOverModal();
            BuildSettingsPanel();
        }

        private void EnsureEventSystem()
        {
#if UNITY_6000_0_OR_NEWER
            var es = FindAnyObjectByType<UnityEngine.EventSystems.EventSystem>();
#else
            var es = FindObjectOfType<UnityEngine.EventSystems.EventSystem>();
#endif
            if (es == null)
            {
                var esGo = new GameObject("EventSystem");
                es = esGo.AddComponent<UnityEngine.EventSystems.EventSystem>();
#if ENABLE_INPUT_SYSTEM
                var uiMod = esGo.AddComponent<InputSystemUIInputModule>();
                uiMod.AssignDefaultActions();
#else
                esGo.AddComponent<UnityEngine.EventSystems.StandaloneInputModule>();
#endif
            }
            else
            {
#if ENABLE_INPUT_SYSTEM
                var uiMod = es.GetComponent<InputSystemUIInputModule>();
                if (uiMod != null && uiMod.actionsAsset == null)
                {
                    uiMod.AssignDefaultActions();
                }
#endif
            }
        }

        private void BuildTopHUD()
        {
            var hudTopLeft = CreateUIObject("TopLeftHUD", transform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(0, 1), new Vector2(20, -20), new Vector2(380, 160));
            Color lostColor = new Color(0.35f, 0.35f, 0.35f, 1f);

            // HP Bar Background
            var hpBg = CreateImage("HP_BG", hudTopLeft.transform, lostColor, new Vector2(0, 1), new Vector2(0, 1), new Vector2(0, 1), new Vector2(0, 0), new Vector2(320, 28));
            var hpFillGo = CreateImage("HP_Fill", hpBg.transform, new Color(0.92f, 0.22f, 0.25f, 1f), new Vector2(0, 0), new Vector2(0, 1), new Vector2(0, 0.5f), new Vector2(2, 0), new Vector2(316, 24));
            _hpFill = hpFillGo.GetComponent<Image>();

            var hpTextGo = CreateText("HP_Text", hpBg.transform, "HP: 100 / 100", 18, Color.white, TextAnchor.MiddleCenter);
            _hpText = hpTextGo.GetComponent<Text>();
            hpTextGo.GetComponent<RectTransform>().sizeDelta = new Vector2(320, 28);

            // XP Bar Background
            var xpBg = CreateImage("XP_BG", hudTopLeft.transform, lostColor, new Vector2(0, 1), new Vector2(0, 1), new Vector2(0, 1), new Vector2(0, -36), new Vector2(320, 20));
            var xpFillGo = CreateImage("XP_Fill", xpBg.transform, new Color(0.15f, 0.85f, 1f, 1f), new Vector2(0, 0), new Vector2(0, 1), new Vector2(0, 0.5f), new Vector2(2, 0), new Vector2(316, 16));
            _xpFill = xpFillGo.GetComponent<Image>();
            SetBar(_xpFill, 0f, 1f);

            var xpTextGo = CreateText("XP_Text", xpBg.transform, "LVL 1 - XP 0 / 50", 14, Color.white, TextAnchor.MiddleCenter);
            _xpText = xpTextGo.GetComponent<Text>();
            xpTextGo.GetComponent<RectTransform>().sizeDelta = new Vector2(320, 20);

            // Gold Display
            var goldGo = CreateText("GoldText", hudTopLeft.transform, "Gold: 0", 22, new Color(1f, 0.85f, 0.2f), TextAnchor.MiddleLeft);
            var goldRect = goldGo.GetComponent<RectTransform>();
            goldRect.anchorMin = new Vector2(0, 1);
            goldRect.anchorMax = new Vector2(0, 1);
            goldRect.pivot = new Vector2(0, 1);
            goldRect.anchoredPosition = new Vector2(5, -68);
            goldRect.sizeDelta = new Vector2(200, 28);
            _goldText = goldGo.GetComponent<Text>();

            // Relics Display row
            var relicsGo = CreateText("RelicsText", hudTopLeft.transform, "Relics: None", 16, new Color(0.7f, 0.9f, 1f), TextAnchor.MiddleLeft);
            var relicsRect = relicsGo.GetComponent<RectTransform>();
            relicsRect.anchorMin = new Vector2(0, 1);
            relicsRect.anchorMax = new Vector2(0, 1);
            relicsRect.pivot = new Vector2(0, 1);
            relicsRect.anchoredPosition = new Vector2(5, -98);
            relicsRect.sizeDelta = new Vector2(360, 26);
            _relicsText = relicsGo.GetComponent<Text>();

            // Top-Center: Floor & Enemy count
            var topCenter = CreateUIObject("TopCenterHUD", transform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -20), new Vector2(500, 90));

            var floorGo = CreateText("FloorText", topCenter.transform, "FLOOR 1", 34, new Color(1f, 0.95f, 0.8f), TextAnchor.MiddleCenter);
            var floorRect = floorGo.GetComponent<RectTransform>();
            floorRect.anchoredPosition = new Vector2(0, 0);
            floorRect.sizeDelta = new Vector2(400, 45);
            _floorText = floorGo.GetComponent<Text>();
            var outline = floorGo.AddComponent<Outline>();
            outline.effectColor = Color.black;
            outline.effectDistance = new Vector2(2, -2);

            var enemyGo = CreateText("EnemyText", topCenter.transform, "Enemies Remaining: 0", 20, new Color(0.85f, 0.85f, 0.85f), TextAnchor.MiddleCenter);
            var enemyRect = enemyGo.GetComponent<RectTransform>();
            enemyRect.anchoredPosition = new Vector2(0, -42);
            enemyRect.sizeDelta = new Vector2(400, 30);
            _enemyText = enemyGo.GetComponent<Text>();
        }

        private void BuildSkillBarHUD()
        {
            var skillBar = CreateUIObject("SkillBarHUD", transform, new Vector2(0.5f, 0), new Vector2(0.5f, 0), new Vector2(0.5f, 0), new Vector2(0, 30), new Vector2(240, 70));

            // Dash Skill Icon
            var dashSlot = CreateImage("DashSlot", skillBar.transform, new Color(0.12f, 0.15f, 0.2f, 0.85f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-45, 0), new Vector2(58, 58));
            var dashIcon = CreateImage("Icon", dashSlot.transform, Color.white, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(42, 42));
            dashIcon.GetComponent<Image>().sprite = SpriteFactory.GetSprite("player");

            var dashKeyText = CreateText("Key", dashSlot.transform, "RMB", 13, Color.yellow, TextAnchor.LowerRight);
            dashKeyText.GetComponent<RectTransform>().anchoredPosition = new Vector2(20, -18);

            var dashCd = CreateImage("CD_Overlay", dashSlot.transform, new Color(0, 0, 0, 0.7f), new Vector2(0, 0), new Vector2(1, 1), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
            _dashCdFill = dashCd.GetComponent<Image>();
            _dashCdFill.type = Image.Type.Filled;
            _dashCdFill.fillMethod = Image.FillMethod.Radial360;
            _dashCdFill.fillOrigin = (int)Image.Origin360.Top;
            _dashCdFill.fillClockwise = false;
            _dashCdFill.fillAmount = 0f;

            // Special Nova Skill Icon
            var specSlot = CreateImage("SpecialSlot", skillBar.transform, new Color(0.12f, 0.15f, 0.2f, 0.85f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(45, 0), new Vector2(58, 58));
            var specIcon = CreateImage("Icon", specSlot.transform, Color.white, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(42, 42));
            specIcon.GetComponent<Image>().sprite = SpriteFactory.GetSprite("slash");

            var specKeyText = CreateText("Key", specSlot.transform, "Q / E", 13, Color.cyan, TextAnchor.LowerRight);
            specKeyText.GetComponent<RectTransform>().anchoredPosition = new Vector2(20, -18);

            var specCd = CreateImage("CD_Overlay", specSlot.transform, new Color(0, 0, 0, 0.7f), new Vector2(0, 0), new Vector2(1, 1), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
            _specialCdFill = specCd.GetComponent<Image>();
            _specialCdFill.type = Image.Type.Filled;
            _specialCdFill.fillMethod = Image.FillMethod.Radial360;
            _specialCdFill.fillOrigin = (int)Image.Origin360.Top;
            _specialCdFill.fillClockwise = false;
            _specialCdFill.fillAmount = 0f;
        }

        private void BuildBannerUI()
        {
            _bannerRoot = CreateUIObject("BannerUI", transform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, 160), new Vector2(800, 70));
            var bannerBg = CreateImage("BG", _bannerRoot.transform, new Color(0, 0, 0, 0.75f), new Vector2(0, 0), new Vector2(1, 1), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);

            var textGo = CreateText("BannerText", _bannerRoot.transform, "", 28, new Color(1f, 0.85f, 0.2f), TextAnchor.MiddleCenter);
            textGo.GetComponent<RectTransform>().sizeDelta = new Vector2(780, 60);
            _bannerText = textGo.GetComponent<Text>();

            var outline = textGo.AddComponent<Outline>();
            outline.effectColor = Color.black;
            outline.effectDistance = new Vector2(2, -2);

            _bannerRoot.SetActive(false);
        }

        private void BuildUpgradeModal()
        {
            _upgradeModalRoot = CreateUIObject("UpgradeModal", transform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(1920, 1080));
            CreateImage("BG", _upgradeModalRoot.transform, new Color(0, 0, 0, 0.82f), new Vector2(0, 0), new Vector2(1, 1), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);

            var titleGo = CreateText("Title", _upgradeModalRoot.transform, "LEVEL UP! CHOOSE AN UPGRADE", 42, new Color(1f, 0.88f, 0.25f), TextAnchor.MiddleCenter);
            titleGo.GetComponent<RectTransform>().anchoredPosition = new Vector2(0, 240);
            titleGo.GetComponent<RectTransform>().sizeDelta = new Vector2(900, 60);

            // 3 Upgrade Cards
            float[] cardX = new float[] { -280f, 0f, 280f };
            for (int i = 0; i < 3; i++)
            {
                var card = CreateUpgradeCard(_upgradeModalRoot.transform, cardX[i]);
                _upgradeCards.Add(card);
            }

            _upgradeModalRoot.SetActive(false);
        }

        private GameObject CreateUpgradeCard(Transform parent, float xPos)
        {
            var cardGo = CreateUIObject("Card", parent, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(xPos, -20), new Vector2(250, 360));
            CreateImage("CardBG", cardGo.transform, new Color(0.12f, 0.14f, 0.2f, 0.95f), new Vector2(0, 0), new Vector2(1, 1), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);

            var border = CreateImage("Border", cardGo.transform, new Color(0.3f, 0.7f, 1f, 0.8f), new Vector2(0, 0), new Vector2(1, 1), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
            border.GetComponent<Image>().sprite = SpriteFactory.CreateRoundedRect(250, 360, 12, Color.clear, new Color(0.3f, 0.7f, 1f), 3);

            // Icon
            var iconGo = CreateImage("Icon", cardGo.transform, Color.white, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, 90), new Vector2(72, 72));

            // Name
            var nameGo = CreateText("Name", cardGo.transform, "Upgrade Name", 22, new Color(1f, 0.9f, 0.3f), TextAnchor.MiddleCenter);
            nameGo.GetComponent<RectTransform>().anchoredPosition = new Vector2(0, 25);
            nameGo.GetComponent<RectTransform>().sizeDelta = new Vector2(230, 36);

            // Description
            var descGo = CreateText("Desc", cardGo.transform, "+Bonus Stats", 16, new Color(0.8f, 0.9f, 0.95f), TextAnchor.MiddleCenter);
            descGo.GetComponent<RectTransform>().anchoredPosition = new Vector2(0, -45);
            descGo.GetComponent<RectTransform>().sizeDelta = new Vector2(220, 60);

            // Button
            var btnGo = CreateImage("SelectButton", cardGo.transform, new Color(0.18f, 0.65f, 0.95f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, -110), new Vector2(180, 44));
            var btn = btnGo.AddComponent<Button>();
            var btnColors = btn.colors;
            btnColors.highlightedColor = new Color(0.35f, 0.8f, 1f);
            btnColors.pressedColor = new Color(0.1f, 0.5f, 0.8f);
            btn.colors = btnColors;

            var btnText = CreateText("BtnText", btnGo.transform, "CHOOSE", 18, Color.white, TextAnchor.MiddleCenter);
            btnText.GetComponent<RectTransform>().sizeDelta = new Vector2(180, 44);

            return cardGo;
        }

        private void BuildGameOverModal()
        {
            _gameOverRoot = CreateUIObject("GameOverModal", transform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(1920, 1080));
            CreateImage("BG", _gameOverRoot.transform, new Color(0.05f, 0.02f, 0.02f, 0.9f), new Vector2(0, 0), new Vector2(1, 1), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);

            var titleGo = CreateText("Title", _gameOverRoot.transform, "YOU HAVE FALLEN", 52, new Color(1f, 0.25f, 0.25f), TextAnchor.MiddleCenter);
            titleGo.GetComponent<RectTransform>().anchoredPosition = new Vector2(0, 160);
            titleGo.GetComponent<RectTransform>().sizeDelta = new Vector2(900, 70);

            var statsGo = CreateText("Stats", _gameOverRoot.transform, "Floor Reached: 1\nLevel: 1\nGold Collected: 0", 24, Color.white, TextAnchor.MiddleCenter);
            statsGo.GetComponent<RectTransform>().anchoredPosition = new Vector2(0, 30);
            statsGo.GetComponent<RectTransform>().sizeDelta = new Vector2(600, 180);
            _gameOverStatsText = statsGo.GetComponent<Text>();

            // Restart Button
            var restartBtnGo = CreateImage("RestartBtn", _gameOverRoot.transform, new Color(0.85f, 0.25f, 0.3f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, -90), new Vector2(240, 56));
            var btn = restartBtnGo.AddComponent<Button>();
            btn.onClick.AddListener(() => DungeonManager.Instance?.RestartGame());

            var btnText = CreateText("Text", restartBtnGo.transform, "PLAY AGAIN (R)", 22, Color.white, TextAnchor.MiddleCenter);
            btnText.GetComponent<RectTransform>().sizeDelta = new Vector2(240, 56);

            _gameOverRoot.SetActive(false);
        }

        private void Update()
        {
            // Settings toggle (Escape)
            if (InputHelper.GetPauseDown())
            {
                if (_settingsOpen)
                    CloseSettings();
                else
                    OpenSettings();
            }

            // Banner timer
            if (_bannerTimer > 0f)
            {
                _bannerTimer -= Time.deltaTime;
                if (_bannerTimer <= 0f)
                {
                    _bannerRoot.SetActive(false);
                }
            }

            // Update cooldown rings
            if (PlayerController.Instance != null)
            {
                var player = PlayerController.Instance;
                if (_dashCdFill != null)
                {
                    float dashPct = player.dashCooldownTimer / player.stats.dashCooldown;
                    _dashCdFill.fillAmount = Mathf.Clamp01(dashPct);
                }
                if (_specialCdFill != null)
                {
                    float specPct = player.specialCooldownTimer / Mathf.Max(0.1f, player.stats.specialCooldown);
                    _specialCdFill.fillAmount = Mathf.Clamp01(specPct);
                }
            }

            // Update Relics row in Top HUD
            if (_relicsText != null && RelicSystem.Instance != null)
            {
                var relics = RelicSystem.Instance.ActiveRelics;
                if (relics.Count == 0)
                {
                    _relicsText.text = "Relics: None";
                }
                else
                {
                    string rStr = "Relics: ";
                    for (int i = 0; i < relics.Count; i++)
                    {
                        rStr += $"{relics[i].iconSymbol} {relics[i].relicName}  ";
                    }
                    _relicsText.text = rStr;
                }
            }

            // Quick restart via R key or click
            if (_gameOverRoot != null && _gameOverRoot.activeSelf)
            {
                if (InputHelper.GetRestartDown() || InputHelper.GetAttackDown())
                {
                    DungeonManager.Instance?.RestartGame();
                }
            }
        }

        public void UpdateHealth(float current, float max)
        {
            if (_hpFill != null) SetBar(_hpFill, current, max);
            if (_hpText != null) _hpText.text = $"HP: {Mathf.CeilToInt(current)} / {Mathf.CeilToInt(max)}";
        }

        public void UpdateXP(int current, int toNext, int level)
        {
            if (_xpFill != null) SetBar(_xpFill, current, toNext);
            if (_xpText != null) _xpText.text = $"LVL {level} - XP {current} / {toNext}";
        }

        public void UpdateGold(int gold)
        {
            if (_goldText != null) _goldText.text = $"Gold: {gold}";
        }

        public void UpdateFloor(int floor)
        {
            if (_floorText != null) _floorText.text = $"FLOOR {floor}";
        }

        public void UpdateEnemiesRemaining(int count)
        {
            if (_enemyText != null)
            {
                _enemyText.text = count > 0 ? $"Enemies Remaining: {count}" : "<color=#4dff88>Room Cleared! Enter Portal</color>";
            }
        }

        public void ShowBanner(string message, float duration = 3.5f)
        {
            if (_bannerRoot != null && _bannerText != null)
            {
                _bannerText.text = message;
                _bannerRoot.SetActive(true);
                _bannerTimer = duration;
            }
        }

        public void ShowLevelUpModal(UpgradeType[] options, System.Action onChosen = null)
        {
            Time.timeScale = 0f;
            _upgradeModalRoot.SetActive(true);

            for (int i = 0; i < _upgradeCards.Count; i++)
            {
                var card = _upgradeCards[i];
                if (i < options.Length)
                {
                    card.SetActive(true);
                    UpgradeType upType = options[i];

                    string title = GetUpgradeTitle(upType);
                    string desc = GetUpgradeDesc(upType);
                    Sprite icon = GetUpgradeIcon(upType);

                    card.transform.Find("Name").GetComponent<Text>().text = title;
                    card.transform.Find("Desc").GetComponent<Text>().text = desc;
                    card.transform.Find("Icon").GetComponent<Image>().sprite = icon;

                    var btn = card.transform.Find("SelectButton").GetComponent<Button>();
                    btn.onClick.RemoveAllListeners();
                    btn.onClick.AddListener(() =>
                    {
                        PlayerController.Instance?.stats.ApplyUpgrade(upType);
                        Time.timeScale = 1f;
                        _upgradeModalRoot.SetActive(false);
                        AudioManager.Instance?.PlaySound("potion");
                        onChosen?.Invoke();
                    });
                }
                else
                {
                    card.SetActive(false);
                }
            }
        }

        private string GetUpgradeTitle(UpgradeType type)
        {
            switch (type)
            {
                case UpgradeType.MaxHealth: return "Titan's Heart";
                case UpgradeType.Damage: return "Sharpened Edge";
                case UpgradeType.MoveSpeed: return "Swift Wind";
                case UpgradeType.AttackSpeed: return "Flurry";
                case UpgradeType.DashCooldown: return "Blink Step";
                case UpgradeType.Lifesteal: return "Vampiric Touch";
                case UpgradeType.Armor: return "Iron Aegis";
                case UpgradeType.CritChance: return "Eagle Eye";
                case UpgradeType.NovaCooldown: return "Arcane Focus";
                case UpgradeType.Ignite: return "Ember Edge";
                case UpgradeType.Frostbite: return "Frost Touch";
                default: return "Mystery Boon";
            }
        }

        private string GetUpgradeDesc(UpgradeType type)
        {
            switch (type)
            {
                case UpgradeType.MaxHealth: return "+25 Max Health\n& Instant Recovery";
                case UpgradeType.Damage: return "+8 Attack Damage\nFor all weapon swings";
                case UpgradeType.MoveSpeed: return "+15% Movement Speed\nOutrun dangers";
                case UpgradeType.AttackSpeed: return "+30% Attack Speed\nRapid sword strikes";
                case UpgradeType.DashCooldown: return "-0.2s Dash Cooldown\nGreater mobility";
                case UpgradeType.Lifesteal: return "+8% Lifesteal\nHeal on every hit";
                case UpgradeType.Armor: return "+2 Damage Reduction\nResist all hits";
                case UpgradeType.CritChance: return "+8% Crit Chance\nCrits deal x2 damage";
                case UpgradeType.NovaCooldown: return "-0.8s Nova Cooldown\nCast Nova more often";
                case UpgradeType.Ignite: return "Hits set enemies on fire\n+50% damage/s for 3s per level";
                case UpgradeType.Frostbite: return "Hits slow enemies\n-15% speed per level for 2s";
                default: return "+Bonus Stats";
            }
        }

        private Sprite GetUpgradeIcon(UpgradeType type)
        {
            switch (type)
            {
                case UpgradeType.MaxHealth: return SpriteFactory.GetSprite("potion_hp");
                case UpgradeType.Damage: return SpriteFactory.GetSprite("sword");
                case UpgradeType.MoveSpeed: return SpriteFactory.GetSprite("gem_xp");
                case UpgradeType.AttackSpeed: return SpriteFactory.GetSprite("slash");
                case UpgradeType.DashCooldown: return SpriteFactory.GetSprite("player");
                case UpgradeType.Lifesteal: return SpriteFactory.GetSprite("projectile_enemy");
                case UpgradeType.Armor: return SpriteFactory.GetSprite("pillar");
                case UpgradeType.CritChance: return SpriteFactory.GetSprite("slash");
                case UpgradeType.NovaCooldown: return SpriteFactory.GetSprite("gem_xp");
                case UpgradeType.Ignite: return SpriteFactory.GetSprite("sword");
                case UpgradeType.Frostbite: return SpriteFactory.GetSprite("portal");
                default: return SpriteFactory.GetSprite("coin");
            }
        }

        public void ShowGameOverModal(int floor, int level, int gold, int enemiesSlain, int bestFloor = 0, bool newRecord = false, int bestCombo = 0)
        {
            _gameOverRoot.SetActive(true);
            if (_gameOverStatsText != null)
            {
                _gameOverStatsText.text = $"Floor Reached: {floor}\nFinal Level: {level}\nEnemies Slain: {enemiesSlain}\nGold Accumulated: {gold}";
                if (bestFloor > 0)
                {
                    _gameOverStatsText.text += newRecord ? $"\nBest Floor: {bestFloor}  NEW RECORD!" : $"\nBest Floor: {bestFloor}";
                }
                if (bestCombo >= 2)
                {
                    _gameOverStatsText.text += $"\nBest Combo: x{bestCombo}";
                }
            }
        }

        public void HideGameOverModal()
        {
            if (_gameOverRoot != null)
            {
                _gameOverRoot.SetActive(false);
            }
        }

        // ── Settings Panel ────────────────────────────────────────────────

        private void BuildSettingsPanel()
        {
            _settingsRoot = CreateUIObject("SettingsPanel", transform,
                new Vector2(0, 0), new Vector2(1, 1), new Vector2(0.5f, 0.5f),
                Vector2.zero, Vector2.zero);

            CreateImage("DimBG", _settingsRoot.transform,
                new Color(0f, 0f, 0f, 0.8f),
                new Vector2(0, 0), new Vector2(1, 1), new Vector2(0.5f, 0.5f),
                Vector2.zero, Vector2.zero);

            var card = CreateImage("SettingsCard", _settingsRoot.transform,
                new Color(0.1f, 0.12f, 0.18f, 0.97f),
                new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f),
                Vector2.zero, new Vector2(520, 460));

            var border = CreateImage("Border", card.transform,
                new Color(0.35f, 0.75f, 1f, 1f),
                new Vector2(0, 0), new Vector2(1, 1), new Vector2(0.5f, 0.5f),
                Vector2.zero, Vector2.zero);
            border.GetComponent<Image>().sprite =
                SpriteFactory.CreateRoundedRect(520, 460, 14, Color.clear, new Color(0.35f, 0.75f, 1f), 3);

            var titleGo = CreateText("Title", card.transform, "SETTINGS", 36,
                new Color(1f, 0.92f, 0.4f), TextAnchor.MiddleCenter);
            var titleRect = titleGo.GetComponent<RectTransform>();
            titleRect.anchoredPosition = new Vector2(0, 180);
            titleRect.sizeDelta = new Vector2(480, 50);
            titleGo.AddComponent<Outline>().effectColor = Color.black;

            float rowY = 110f;
            float rowSpacing = -70f;

            BuildSettingsRow(card.transform, "Resolution", rowY,
                "◀", "▶",
                out _resolutionValueText,
                () => { SettingsManager.Instance?.PrevResolution(); RefreshSettingsUI(); },
                () => { SettingsManager.Instance?.NextResolution(); RefreshSettingsUI(); });

            rowY += rowSpacing;
            BuildToggleRow(card.transform, "VSync", rowY,
                out _vsyncValueText,
                () => { SettingsManager.Instance?.ToggleVSync(); RefreshSettingsUI(); });

            rowY += rowSpacing;
            BuildToggleRow(card.transform, "Vibration", rowY,
                out _vibrationValueText,
                () => { SettingsManager.Instance?.ToggleVibration(); RefreshSettingsUI(); });

            rowY += rowSpacing;
            BuildToggleRow(card.transform, "Window Mode", rowY,
                out _windowModeValueText,
                () => { SettingsManager.Instance?.ToggleFullscreen(); RefreshSettingsUI(); });

            var closeBtnGo = CreateImage("CloseBtn", card.transform,
                new Color(0.85f, 0.25f, 0.3f, 1f),
                new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f),
                new Vector2(0, -180), new Vector2(200, 48));
            var closeBtn = closeBtnGo.AddComponent<Button>();
            var closeBtnColors = closeBtn.colors;
            closeBtnColors.highlightedColor = new Color(1f, 0.4f, 0.45f);
            closeBtnColors.pressedColor = new Color(0.6f, 0.15f, 0.2f);
            closeBtn.colors = closeBtnColors;
            closeBtn.onClick.AddListener(CloseSettings);

            var closeTxt = CreateText("CloseTxt", closeBtnGo.transform, "CLOSE (ESC)", 20,
                Color.white, TextAnchor.MiddleCenter);
            closeTxt.GetComponent<RectTransform>().sizeDelta = new Vector2(200, 48);

            _settingsRoot.SetActive(false);
        }

        private void BuildSettingsRow(Transform parent, string label, float y,
            string leftChar, string rightChar,
            out Text valueText,
            UnityEngine.Events.UnityAction onLeft,
            UnityEngine.Events.UnityAction onRight)
        {
            var row = CreateUIObject("Row_" + label, parent,
                new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f),
                new Vector2(0, y), new Vector2(460, 48));

            var lblGo = CreateText("Label", row.transform, label, 22, Color.white, TextAnchor.MiddleLeft);
            var lblRect = lblGo.GetComponent<RectTransform>();
            lblRect.anchorMin = new Vector2(0, 0.5f);
            lblRect.anchorMax = new Vector2(0, 0.5f);
            lblRect.pivot = new Vector2(0, 0.5f);
            lblRect.anchoredPosition = new Vector2(0, 0);
            lblRect.sizeDelta = new Vector2(180, 48);

            var leftBtnGo = CreateImage("LeftBtn", row.transform,
                new Color(0.2f, 0.55f, 0.85f, 1f),
                new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(1, 0.5f),
                new Vector2(-210, 0), new Vector2(36, 36));
            var leftBtn = leftBtnGo.AddComponent<Button>();
            leftBtn.onClick.AddListener(onLeft);
            var leftTxt = CreateText("Txt", leftBtnGo.transform, leftChar, 22, Color.white, TextAnchor.MiddleCenter);
            leftTxt.GetComponent<RectTransform>().sizeDelta = new Vector2(36, 36);

            var valGo = CreateText("Value", row.transform, "---", 22,
                new Color(0.3f, 1f, 0.7f), TextAnchor.MiddleCenter);
            var valRect = valGo.GetComponent<RectTransform>();
            valRect.anchorMin = new Vector2(1, 0.5f);
            valRect.anchorMax = new Vector2(1, 0.5f);
            valRect.pivot = new Vector2(1, 0.5f);
            valRect.anchoredPosition = new Vector2(-40, 0);
            valRect.sizeDelta = new Vector2(170, 48);
            valueText = valGo.GetComponent<Text>();

            var rightBtnGo = CreateImage("RightBtn", row.transform,
                new Color(0.2f, 0.55f, 0.85f, 1f),
                new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(1, 0.5f),
                new Vector2(0, 0), new Vector2(36, 36));
            var rightBtn = rightBtnGo.AddComponent<Button>();
            rightBtn.onClick.AddListener(onRight);
            var rightTxt = CreateText("Txt", rightBtnGo.transform, rightChar, 22, Color.white, TextAnchor.MiddleCenter);
            rightTxt.GetComponent<RectTransform>().sizeDelta = new Vector2(36, 36);
        }

        private void BuildToggleRow(Transform parent, string label, float y,
            out Text valueText,
            UnityEngine.Events.UnityAction onToggle)
        {
            var row = CreateUIObject("Row_" + label, parent,
                new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f),
                new Vector2(0, y), new Vector2(460, 48));

            var lblGo = CreateText("Label", row.transform, label, 22, Color.white, TextAnchor.MiddleLeft);
            var lblRect = lblGo.GetComponent<RectTransform>();
            lblRect.anchorMin = new Vector2(0, 0.5f);
            lblRect.anchorMax = new Vector2(0, 0.5f);
            lblRect.pivot = new Vector2(0, 0.5f);
            lblRect.anchoredPosition = new Vector2(0, 0);
            lblRect.sizeDelta = new Vector2(220, 48);

            var btnGo = CreateImage("ToggleBtn", row.transform,
                new Color(0.2f, 0.55f, 0.85f, 1f),
                new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(1, 0.5f),
                new Vector2(0, 0), new Vector2(120, 38));
            var btn = btnGo.AddComponent<Button>();
            var btnColors = btn.colors;
            btnColors.highlightedColor = new Color(0.3f, 0.7f, 1f);
            btnColors.pressedColor = new Color(0.15f, 0.4f, 0.7f);
            btn.colors = btnColors;
            btn.onClick.AddListener(onToggle);

            var valGo = CreateText("Value", btnGo.transform, "ON", 20,
                Color.white, TextAnchor.MiddleCenter);
            valGo.GetComponent<RectTransform>().sizeDelta = new Vector2(120, 38);
            valueText = valGo.GetComponent<Text>();
        }

        private void OpenSettings()
        {
            if (_settingsRoot == null) return;
            if (_upgradeModalRoot != null && _upgradeModalRoot.activeSelf) return;

            _settingsOpen = true;
            _prevTimeScale = Time.timeScale;
            Time.timeScale = 0f;
            _settingsRoot.SetActive(true);
            RefreshSettingsUI();
        }

        private void CloseSettings()
        {
            if (_settingsRoot == null) return;
            _settingsOpen = false;
            Time.timeScale = _prevTimeScale;
            _settingsRoot.SetActive(false);
        }

        private void RefreshSettingsUI()
        {
            if (SettingsManager.Instance == null) return;

            if (_resolutionValueText != null)
                _resolutionValueText.text = SettingsManager.Instance.CurrentResolutionLabel();

            if (_vsyncValueText != null)
            {
                _vsyncValueText.text = SettingsManager.Instance.VSyncEnabled ? "ON" : "OFF";
                _vsyncValueText.color = SettingsManager.Instance.VSyncEnabled
                    ? new Color(0.3f, 1f, 0.7f) : new Color(1f, 0.4f, 0.4f);
            }

            if (_vibrationValueText != null)
            {
                _vibrationValueText.text = SettingsManager.Instance.VibrationEnabled ? "ON" : "OFF";
                _vibrationValueText.color = SettingsManager.Instance.VibrationEnabled
                    ? new Color(0.3f, 1f, 0.7f) : new Color(1f, 0.4f, 0.4f);
            }

            if (_windowModeValueText != null)
            {
                _windowModeValueText.text = SettingsManager.Instance.IsFullscreen ? "FULLSCREEN" : "WINDOWED";
                _windowModeValueText.color = SettingsManager.Instance.IsFullscreen
                    ? new Color(0.3f, 1f, 0.7f) : new Color(1f, 0.85f, 0.3f);
            }
        }

        public bool IsSettingsOpen => _settingsOpen;

        private void SetBar(Image fill, float current, float max)
        {
            if (fill == null) return;
            float pct = Mathf.Clamp01(current / Mathf.Max(0.01f, max));
            fill.rectTransform.sizeDelta = new Vector2(316f * pct, fill.rectTransform.sizeDelta.y);
        }

        private GameObject CreateUIObject(string name, Transform parent, Vector2 anchorMin, Vector2 anchorMax, Vector2 pivot, Vector2 pos, Vector2 size)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var rect = go.AddComponent<RectTransform>();
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.pivot = pivot;
            rect.anchoredPosition = pos;
            rect.sizeDelta = size;
            return go;
        }

        private GameObject CreateImage(string name, Transform parent, Color color, Vector2 anchorMin, Vector2 anchorMax, Vector2 pivot, Vector2 pos, Vector2 size)
        {
            var go = CreateUIObject(name, parent, anchorMin, anchorMax, pivot, pos, size);
            var img = go.AddComponent<Image>();
            img.color = color;
            return go;
        }

        private GameObject CreateText(string name, Transform parent, string content, int fontSize, Color color, TextAnchor align)
        {
            var go = CreateUIObject(name, parent, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(200, 40));
            var txt = go.AddComponent<Text>();
            txt.font = _font;
            txt.text = content;
            txt.fontSize = fontSize;
            txt.color = color;
            txt.alignment = align;
            txt.raycastTarget = false;
            return go;
        }
    }
}
