using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SimpleRPG
{
    /// <summary>
    /// Tactical Mini-Map Radar HUD.
    /// Real-time top-down overview of player, enemies, boss, portal, chests, and pillars.
    /// Can be toggled on/off with 'M' key.
    /// </summary>
    public class MiniMapUI : MonoBehaviour
    {
        public static MiniMapUI Instance { get; private set; }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void AutoCreate()
        {
            if (Instance != null) return;
            var go = new GameObject("MiniMapUI");
            go.AddComponent<MiniMapUI>();
        }

        private Canvas _canvas;
        private RectTransform _mapRoot;
        private RectTransform _playerDot;
        private RectTransform _portalDot;
        private readonly List<RectTransform> _enemyDots = new List<RectTransform>();
        private readonly List<RectTransform> _chestDots = new List<RectTransform>();

        private const float MapWidth = 160f;
        private const float MapHeight = 110f;
        private bool _visible = true;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;

            BuildMiniMapCanvas();
        }

        private void BuildMiniMapCanvas()
        {
            _canvas = gameObject.AddComponent<Canvas>();
            _canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            _canvas.sortingOrder = 55; // above GameUI (50), below Inventory (60)

            var scaler = gameObject.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);
            scaler.matchWidthOrHeight = 0.5f;

            // Container in top-right
            var container = new GameObject("MiniMap_Frame");
            container.transform.SetParent(transform, false);
            _mapRoot = container.AddComponent<RectTransform>();
            _mapRoot.anchorMin = new Vector2(1f, 1f);
            _mapRoot.anchorMax = new Vector2(1f, 1f);
            _mapRoot.pivot = new Vector2(1f, 1f);
            _mapRoot.anchoredPosition = new Vector2(-25f, -95f);
            _mapRoot.sizeDelta = new Vector2(MapWidth, MapHeight);

            // Background
            var bgImg = container.AddComponent<Image>();
            bgImg.color = new Color(0.06f, 0.08f, 0.12f, 0.85f);

            var outline = container.AddComponent<Outline>();
            outline.effectColor = new Color(0.3f, 0.5f, 0.7f, 0.6f);
            outline.effectDistance = new Vector2(1.5f, -1.5f);

            // Title label
            var titleGo = new GameObject("MapTitle");
            titleGo.transform.SetParent(_mapRoot, false);
            var titleRect = titleGo.AddComponent<RectTransform>();
            titleRect.anchorMin = new Vector2(0f, 1f);
            titleRect.anchorMax = new Vector2(1f, 1f);
            titleRect.pivot = new Vector2(0.5f, 1f);
            titleRect.anchoredPosition = new Vector2(0f, 18f);
            titleRect.sizeDelta = new Vector2(MapWidth, 20f);

            var titleText = titleGo.AddComponent<Text>();
            titleText.text = "RADAR [M]";
            titleText.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf") ?? Font.CreateDynamicFontFromOSFont("Arial", 12);
            titleText.fontSize = 11;
            titleText.fontStyle = FontStyle.Bold;
            titleText.alignment = TextAnchor.MiddleCenter;
            titleText.color = new Color(0.6f, 0.8f, 1f, 0.75f);

            // Player Marker (green dot)
            _playerDot = CreateDot("PlayerMarker", new Color(0.2f, 1f, 0.4f), new Vector2(8f, 8f));

            // Portal Marker (cyan glowing diamond)
            _portalDot = CreateDot("PortalMarker", new Color(0.2f, 0.9f, 1f), new Vector2(9f, 9f));
        }

        private RectTransform CreateDot(string name, Color color, Vector2 size)
        {
            var dotGo = new GameObject(name);
            dotGo.transform.SetParent(_mapRoot, false);
            var rect = dotGo.AddComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.sizeDelta = size;

            var img = dotGo.AddComponent<Image>();
            img.color = color;
            return rect;
        }

        private void Update()
        {
            // Toggle with 'M'
            if (Input.GetKeyDown(KeyCode.M))
            {
                _visible = !_visible;
                _mapRoot.gameObject.SetActive(_visible);
            }

            if (!_visible || DungeonManager.Instance == null) return;

            UpdatePositions();
        }

        private void UpdatePositions()
        {
            float roomW = DungeonManager.Instance.roomWidth;
            float roomH = DungeonManager.Instance.roomHeight;
            float scaleX = (MapWidth - 16f) / Mathf.Max(1f, roomW);
            float scaleY = (MapHeight - 16f) / Mathf.Max(1f, roomH);

            // 1. Player
            if (PlayerController.Instance != null && _playerDot != null)
            {
                Vector3 pPos = PlayerController.Instance.transform.position;
                _playerDot.anchoredPosition = new Vector2(pPos.x * scaleX, pPos.y * scaleY);
            }

            // 2. Portal
            if (DungeonManager.Instance.exitPortal != null && _portalDot != null)
            {
                Vector3 ptPos = DungeonManager.Instance.exitPortal.transform.position;
                _portalDot.anchoredPosition = new Vector2(ptPos.x * scaleX, ptPos.y * scaleY);
                _portalDot.gameObject.SetActive(DungeonManager.Instance.exitPortal.gameObject.activeInHierarchy);
            }

            // 3. Enemies
            var enemyContainer = DungeonManager.Instance.enemyContainer;
            if (enemyContainer != null)
            {
                int activeCount = 0;
                foreach (Transform child in enemyContainer)
                {
                    var enemy = child.GetComponent<EnemyBase>();
                    if (enemy != null && enemy.IsAlive)
                    {
                        if (activeCount >= _enemyDots.Count)
                        {
                            var dot = CreateDot($"EnemyDot_{_enemyDots.Count}", new Color(1f, 0.25f, 0.25f), new Vector2(6f, 6f));
                            _enemyDots.Add(dot);
                        }

                        var enemyDot = _enemyDots[activeCount];
                        enemyDot.gameObject.SetActive(true);
                        Vector3 ePos = enemy.transform.position;
                        enemyDot.anchoredPosition = new Vector2(ePos.x * scaleX, ePos.y * scaleY);

                        // If boss, make it larger and golden-red
                        bool isBoss = enemy is BossEnemy;
                        enemyDot.sizeDelta = isBoss ? new Vector2(12f, 12f) : new Vector2(6f, 6f);
                        enemyDot.GetComponent<Image>().color = isBoss ? new Color(1f, 0.85f, 0.1f) : new Color(1f, 0.25f, 0.25f);

                        activeCount++;
                    }
                }

                // Hide remaining
                for (int i = activeCount; i < _enemyDots.Count; i++)
                {
                    _enemyDots[i].gameObject.SetActive(false);
                }
            }
        }
    }
}
