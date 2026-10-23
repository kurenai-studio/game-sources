using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SimpleRPG
{
    public class DungeonManager : MonoBehaviour
    {
        public static DungeonManager Instance { get; private set; }

        [Header("Progression")]
        public int currentFloor = 1;
        public int totalEnemiesSlain = 0;
        public int remainingEnemies = 0;

        [Header("Room Dimensions")]
        public int roomWidth = 22;
        public int roomHeight = 14;

        [Header("Prefabs / References")]
        public ExitPortal exitPortal;
        public Transform roomContainer;
        public Transform enemyContainer;
        public Transform lootContainer;

        private readonly List<EnemyBase> _activeEnemies = new List<EnemyBase>();
        private readonly List<Vector2> _pillarPositions = new List<Vector2>();

        // ── Đa dạng màn chơi: chủ đề (theme), bố cục (layout), biến thể tầng (modifier) ──
        private enum Layout { Scattered, Ring, Blocks, Bastion, Open }
        private enum FloorMod { None, Swarm, EliteHunt, SniperNest, Treasure }

        private struct Theme
        {
            public string name;
            public Color floor, wall, pillar, background;
            public float chaserMul, rangerMul, bruteMul;
        }

        // Đổi chủ đề mỗi 3 tầng: 1-3 Crypt, 4-6 Ruins, 7-9 Molten, 10-12 Frozen, rồi lặp lại
        private static readonly Theme[] Themes =
        {
            new Theme { name = "Ancient Crypt",
                floor = new Color(1f, 1f, 1f), wall = new Color(1f, 1f, 1f), pillar = new Color(1f, 1f, 1f),
                background = new Color(0.08f, 0.09f, 0.12f), chaserMul = 1f, rangerMul = 1f, bruteMul = 1f },
            new Theme { name = "Overgrown Ruins",
                floor = new Color(0.7f, 1f, 0.7f), wall = new Color(0.6f, 0.9f, 0.6f), pillar = new Color(0.7f, 1f, 0.6f),
                background = new Color(0.05f, 0.10f, 0.06f), chaserMul = 1.4f, rangerMul = 0.7f, bruteMul = 0.8f },
            new Theme { name = "Molten Depths",
                floor = new Color(1f, 0.65f, 0.55f), wall = new Color(0.9f, 0.5f, 0.4f), pillar = new Color(1f, 0.55f, 0.4f),
                background = new Color(0.14f, 0.05f, 0.04f), chaserMul = 0.8f, rangerMul = 1.4f, bruteMul = 1f },
            new Theme { name = "Frozen Halls",
                floor = new Color(0.7f, 0.9f, 1f), wall = new Color(0.6f, 0.8f, 1f), pillar = new Color(0.75f, 0.9f, 1f),
                background = new Color(0.05f, 0.09f, 0.15f), chaserMul = 0.8f, rangerMul = 0.9f, bruteMul = 1.5f },
        };

        private Theme _theme = Themes[0];
        private Layout _layout = Layout.Scattered;
        private Layout _lastLayout = Layout.Scattered;
        private bool _hasLastLayout = false;
        private FloorMod _mod = FloorMod.None;

        // Hàng đợi nâng cấp: lên nhiều cấp cùng lúc thì chọn lần lượt, không mất lượt nào
        private int _pendingLevelUps = 0;
        private bool _upgradeModalOpen = false;

        private const string BestFloorKey = "SimpleRPG_BestFloor";
        private const int MaxChasers = 10;
        private const int MaxRangers = 8;
        private const int MaxBrutes = 5;
        private const int MaxBombers = 4;

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

            Time.timeScale = 1f;
        }

        private void Start()
        {
            InitializeContainers();

            // Đảm bảo hệ thống Cổ vật & Quản lý Pool hoạt động
            if (GetComponent<RelicSystem>() == null)
            {
                gameObject.AddComponent<RelicSystem>();
            }
            if (GetComponent<ObjectPoolManager>() == null)
            {
                gameObject.AddComponent<ObjectPoolManager>();
            }

            StartGame();
        }

        private void InitializeContainers()
        {
            if (roomContainer == null)
            {
                roomContainer = new GameObject("Room_Container").transform;
            }
            if (enemyContainer == null)
            {
                enemyContainer = new GameObject("Enemy_Container").transform;
            }
            if (lootContainer == null)
            {
                lootContainer = new GameObject("Loot_Container").transform;
            }
        }

        private bool _eventsConnected = false;

        public void StartGame()
        {
            currentFloor = 1;
            totalEnemiesSlain = 0;
            ComboSystem.Instance?.ResetRun();
            _pendingLevelUps = 0;
            _upgradeModalOpen = false;

            // Connect player events safely
            if (PlayerController.Instance != null && !_eventsConnected)
            {
                _eventsConnected = true;
                var stats = PlayerController.Instance.stats;
                stats.OnHealthChanged += (cur, max) => GameUI.Instance?.UpdateHealth(cur, max);
                stats.OnXPChanged += (cur, next) => GameUI.Instance?.UpdateXP(cur, next, stats.level);
                stats.OnGoldChanged += (gold) => GameUI.Instance?.UpdateGold(gold);
                stats.OnLevelUp += HandleLevelUp;
            }

            if (PlayerController.Instance != null)
            {
                var stats = PlayerController.Instance.stats;
                GameUI.Instance?.UpdateHealth(stats.currentHealth, stats.maxHealth);
                GameUI.Instance?.UpdateXP(stats.currentXP, stats.xpToNextLevel, stats.level);
                GameUI.Instance?.UpdateGold(stats.gold);
            }

            BuildFloor();
        }

        private void BuildFloor()
        {
            ClearPreviousFloor();

            // Khởi tạo lưới phân vùng không gian Native C++
            NativeRoguelikeCore.InitGrid(-roomWidth / 2f - 2f, -roomHeight / 2f - 2f, roomWidth / 2f + 2f, roomHeight / 2f + 2f, 2.5f);

            ChooseFloorStyle();

            GameUI.Instance?.UpdateFloor(currentFloor);
            GameUI.Instance?.ShowBanner($"FLOOR {currentFloor} - {_theme.name}{ModLabel()}", 2.5f);

            // 1. Build Room Tiles and Walls
            GenerateRoomGeometry();

            // 2. Position Player
            if (PlayerController.Instance != null)
            {
                PlayerController.Instance.transform.position = new Vector3(0, -roomHeight / 2f + 2.5f, 0);
            }

            // 3. Spawn Exit Portal (Top Center)
            SpawnPortal();

            // 4. Spawn Chests
            SpawnChests();
            SpawnShrineMaybe();

            // 5. Spawn Enemies for Floor (hoặc Cửa hàng Thương nhân)
            if (ShopManager.IsShopFloor(currentFloor))
            {
                if (exitPortal != null) exitPortal.SetOpen(true);
                ShopManager.Instance?.OpenShop(currentFloor);
                GameUI.Instance?.UpdateEnemiesRemaining(0);
            }
            else if (_mod == FloorMod.Treasure)
            {
                ShopManager.Instance?.CloseShop();
                remainingEnemies = 0;
                if (exitPortal != null) exitPortal.SetOpen(true);
                GameUI.Instance?.UpdateEnemiesRemaining(0);
            }
            else
            {
                ShopManager.Instance?.CloseShop();
                SpawnFloorEnemies();
            }
        }

        private void ClearPreviousFloor()
        {
            _activeEnemies.Clear();
            ShopManager.Instance?.CloseShop();
            NativeRoguelikeCore.ClearGrid();

            // Destroy old room tiles, enemies, and loot
            foreach (Transform child in roomContainer) Destroy(child.gameObject);
            foreach (Transform child in enemyContainer) Destroy(child.gameObject);
            foreach (Transform child in lootContainer) Destroy(child.gameObject);
        }

        private static Color Shade(Color c, float v)
        {
            return new Color(c.r * v, c.g * v, c.b * v, 1f);
        }

        private string ModLabel()
        {
            switch (_mod)
            {
                case FloorMod.Swarm: return " - SWARM!";
                case FloorMod.EliteHunt: return " - ELITE HUNT!";
                case FloorMod.SniperNest: return " - SNIPER NEST!";
                case FloorMod.Treasure: return " - TREASURE VAULT";
                default: return "";
            }
        }

        private void ChooseFloorStyle()
        {
            bool boss = currentFloor % 5 == 0;
            bool shop = ShopManager.IsShopFloor(currentFloor);

            _theme = Themes[((currentFloor - 1) / 3) % Themes.Length];

            _mod = FloorMod.None;
            if (!boss && !shop && currentFloor >= 2)
            {
                float r = UnityEngine.Random.value;
                if (r < 0.12f) _mod = FloorMod.Treasure;
                else if (r < 0.32f) _mod = FloorMod.Swarm;
                else if (currentFloor >= 3 && r < 0.50f) _mod = FloorMod.EliteHunt;
                else if (currentFloor >= 3 && r < 0.68f) _mod = FloorMod.SniperNest;
            }

            var pool = new List<Layout> { Layout.Scattered, Layout.Ring, Layout.Blocks, Layout.Open };
            if (!boss && !shop) pool.Add(Layout.Bastion);
            if (_hasLastLayout && pool.Count > 1) pool.Remove(_lastLayout);

            _layout = currentFloor == 1 ? Layout.Scattered : pool[UnityEngine.Random.Range(0, pool.Count)];
            if (_mod == FloorMod.Treasure) _layout = Layout.Open;

            _lastLayout = _layout;
            _hasLastLayout = true;

            var cam = Camera.main;
            if (cam != null) cam.backgroundColor = _theme.background;

            // Bụi lơ lửng theo màu bioma
            VisualFX.SetAmbient(Color.Lerp(_theme.background, Color.white, 0.6f), roomWidth / 2f, roomHeight / 2f);
        }

        private void GenerateRoomGeometry()
        {
            int halfW = roomWidth / 2;
            int halfH = roomHeight / 2;

            Sprite floorSprite = SpriteFactory.GetSprite("floor_tile");
            Sprite wallSprite = SpriteFactory.GetSprite("wall_tile");
            Sprite pillarSprite = SpriteFactory.GetSprite("pillar");

            // Floor tiles
            for (int x = -halfW; x <= halfW; x++)
            {
                for (int y = -halfH; y <= halfH; y++)
                {
                    var tile = new GameObject($"Floor_{x}_{y}");
                    tile.transform.SetParent(roomContainer, false);
                    tile.transform.position = new Vector3(x, y, 0);

                    var sr = tile.AddComponent<SpriteRenderer>();
                    sr.sprite = floorSprite;
                    sr.sortingOrder = 0;
                    sr.color = Shade(_theme.floor, ((x + y) & 1) == 0 ? 1f : 0.92f);
                }
            }

            // Outer perimeter walls with colliders
            for (int x = -halfW - 1; x <= halfW + 1; x++)
            {
                CreateWallTile(new Vector3(x, halfH + 1, 0), wallSprite);
                CreateWallTile(new Vector3(x, -halfH - 1, 0), wallSprite);
            }
            for (int y = -halfH; y <= halfH; y++)
            {
                CreateWallTile(new Vector3(-halfW - 1, y, 0), wallSprite);
                CreateWallTile(new Vector3(halfW + 1, y, 0), wallSprite);
            }

            // Tactical cover pillars
            GeneratePillarPositions();

            foreach (var pos in _pillarPositions)
            {
                var pillar = new GameObject("Pillar");
                pillar.transform.SetParent(roomContainer, false);
                pillar.transform.position = pos;
                pillar.AddComponent<DungeonObstacle>();

                var sr = pillar.AddComponent<SpriteRenderer>();
                sr.sprite = pillarSprite;
                sr.sortingOrder = 8;
                sr.color = _theme.pillar;

                var col = pillar.AddComponent<CircleCollider2D>();
                col.radius = 0.5f;
            }
        }

        private void GeneratePillarPositions()
        {
            _pillarPositions.Clear();

            switch (_layout)
            {
                case Layout.Scattered: BuildScatteredLayout(); break;
                case Layout.Ring: BuildRingLayout(); break;
                case Layout.Blocks: BuildBlocksLayout(); break;
                case Layout.Bastion: BuildBastionLayout(); break;
                default: break;
            }

            RemoveReservedPillars();
        }

        private void BuildRingLayout()
        {
            const int points = 16;
            const float radius = 3.5f;
            for (int i = 0; i < points; i++)
            {
                if (i % 4 == 0) continue;
                float a = i * Mathf.PI * 2f / points;
                _pillarPositions.Add(new Vector2(Mathf.Cos(a) * radius, Mathf.Sin(a) * radius));
            }
            if (currentFloor % 5 != 0) _pillarPositions.Add(Vector2.zero);
        }

        private void BuildBlocksLayout()
        {
            Vector2[] origins = UnityEngine.Random.value < 0.5f
                ? new[] { new Vector2(-7, 1), new Vector2(6, 1), new Vector2(-4, -3), new Vector2(3, -3) }
                : new[] { new Vector2(-9, -1), new Vector2(8, -1), new Vector2(-5, 3), new Vector2(4, 3) };

            foreach (var o in origins)
            {
                _pillarPositions.Add(o);
                _pillarPositions.Add(o + new Vector2(1, 0));
                _pillarPositions.Add(o + new Vector2(0, 1));
                _pillarPositions.Add(o + new Vector2(1, 1));
            }
        }

        private void BuildBastionLayout()
        {
            int shift = UnityEngine.Random.Range(-1, 2);
            int rowOuter = -1 + shift;
            int rowCenter = 2 + shift;

            for (int x = -9; x <= -5; x++) _pillarPositions.Add(new Vector2(x, rowOuter));
            for (int x = 5; x <= 9; x++) _pillarPositions.Add(new Vector2(x, rowOuter));
            for (int x = -3; x <= 3; x++) _pillarPositions.Add(new Vector2(x, rowCenter));
        }

        private void RemoveReservedPillars()
        {
            Vector2 playerSpawn = new Vector2(0, -roomHeight / 2f + 2.5f);
            Vector2 portal = new Vector2(0, roomHeight / 2f - 1.8f);
            Vector2 chestL = new Vector2(-(roomWidth / 2f - 2.5f), roomHeight / 2f - 2.5f);
            Vector2 chestR = new Vector2(roomWidth / 2f - 2.5f, roomHeight / 2f - 2.5f);

            bool shop = ShopManager.IsShopFloor(currentFloor);
            bool boss = currentFloor % 5 == 0;
            Vector2 center = new Vector2(0, shop ? 2.5f : 2f);

            _pillarPositions.RemoveAll(p =>
                Vector2.Distance(p, playerSpawn) < 2f ||
                Vector2.Distance(p, portal) < 2f ||
                Vector2.Distance(p, chestL) < 1.5f ||
                Vector2.Distance(p, chestR) < 1.5f ||
                ((shop || boss) && Vector2.Distance(p, center) < 2.5f));
        }

        private void BuildScatteredLayout()
        {
            _pillarPositions.Clear();

            int halfW = roomWidth / 2;
            int halfH = roomHeight / 2;
            int target = UnityEngine.Random.Range(4, 8);

            Vector2 playerSpawn = new Vector2(0, -roomHeight / 2f + 2.5f);
            Vector2 portal = new Vector2(0, roomHeight / 2f - 1.8f);
            Vector2 chestL = new Vector2(-(roomWidth / 2f - 2.5f), roomHeight / 2f - 2.5f);
            Vector2 chestR = new Vector2(roomWidth / 2f - 2.5f, roomHeight / 2f - 2.5f);

            int tries = 0;
            while (_pillarPositions.Count < target && tries < 200)
            {
                tries++;
                Vector2 p = new Vector2(
                    Mathf.Round(UnityEngine.Random.Range(-halfW + 3f, halfW - 2f)),
                    Mathf.Round(UnityEngine.Random.Range(-halfH + 3f, halfH - 2f)));

                if (Vector2.Distance(p, playerSpawn) < 3.5f) continue;
                if (Vector2.Distance(p, portal) < 2.5f) continue;
                if (Vector2.Distance(p, chestL) < 2f || Vector2.Distance(p, chestR) < 2f) continue;

                bool tooClose = false;
                foreach (var q in _pillarPositions)
                {
                    if (Vector2.Distance(p, q) < 3f) { tooClose = true; break; }
                }
                if (tooClose) continue;

                _pillarPositions.Add(p);
            }
        }

        private void CreateWallTile(Vector3 pos, Sprite wallSprite)
        {
            var wall = new GameObject("Wall");
            wall.transform.SetParent(roomContainer, false);
            wall.transform.position = pos;
            wall.AddComponent<DungeonObstacle>();

            var sr = wall.AddComponent<SpriteRenderer>();
            sr.sprite = wallSprite;
            sr.sortingOrder = 7;
            sr.color = _theme.wall;

            var col = wall.AddComponent<BoxCollider2D>();
            col.size = Vector2.one;
        }

        private void SpawnPortal()
        {
            var portalGo = new GameObject("ExitPortal");
            portalGo.transform.SetParent(roomContainer, false);
            portalGo.transform.position = new Vector3(0, roomHeight / 2f - 1.8f, 0);

            exitPortal = portalGo.AddComponent<ExitPortal>();
            exitPortal.SetOpen(false);
        }

        /// <summary>Đôi khi (từ tầng 2, không phải tầng boss/cửa hàng/kho báu) có một bàn thờ máu trong phòng.</summary>
        private void SpawnShrineMaybe()
        {
            if (currentFloor < 2 || currentFloor % 5 == 0) return;
            if (ShopManager.IsShopFloor(currentFloor) || _mod == FloorMod.Treasure) return;
            if (UnityEngine.Random.value > 0.3f) return;

            var go = new GameObject("Blood_Shrine");
            go.transform.SetParent(roomContainer, false);
            go.transform.position = GetRandomSpawnPos();
            go.AddComponent<ShrineAltar>();
        }

        private void SpawnChests()
        {
            int chestCount = (currentFloor % 3 == 0 || _mod == FloorMod.Treasure) ? 2 : 1;
            float halfW = roomWidth / 2f - 2.5f;
            float halfH = roomHeight / 2f - 2.5f;

            if (chestCount >= 1)
            {
                LootManager.Instance?.SpawnChest(new Vector3(-halfW, halfH, 0));
            }
            if (chestCount >= 2)
            {
                LootManager.Instance?.SpawnChest(new Vector3(halfW, halfH, 0));
            }
            if (_mod == FloorMod.Treasure)
            {
                LootManager.Instance?.SpawnChest(new Vector3(0, 0.5f, 0));
            }
        }

        private void SpawnFloorEnemies()
        {
            _activeEnemies.Clear();

            bool isBossFloor = (currentFloor % 5 == 0);

            if (isBossFloor)
            {
                SpawnBoss(new Vector3(0, 2f, 0));
                for (int i = 0; i < 4; i++)
                {
                    SpawnChaser(GetRandomSpawnPos());
                }
            }
            else
            {
                int chaserCount = 3 + currentFloor;
                int rangerCount = Mathf.Max(0, (currentFloor - 1) * 2);
                int bruteCount = Mathf.Max(0, currentFloor - 2);
                int chaserCap = MaxChasers, rangerCap = MaxRangers, bruteCap = MaxBrutes;

                switch (_mod)
                {
                    case FloorMod.Swarm:
                        chaserCount = Mathf.RoundToInt((3 + currentFloor) * 1.8f);
                        rangerCount = Mathf.Max(0, currentFloor - 1);
                        bruteCount = 0;
                        chaserCap = 16;
                        break;
                    case FloorMod.EliteHunt:
                        chaserCount = 2 + currentFloor / 2;
                        rangerCount = currentFloor / 2;
                        bruteCount = 2 + currentFloor / 2;
                        bruteCap = 8;
                        break;
                    case FloorMod.SniperNest:
                        chaserCount = 2 + currentFloor / 2;
                        rangerCount = Mathf.RoundToInt((currentFloor + 2) * 1.5f);
                        bruteCount = 0;
                        rangerCap = 12;
                        break;
                }

                chaserCount = Mathf.Min(Mathf.RoundToInt(chaserCount * _theme.chaserMul), chaserCap);
                rangerCount = Mathf.Min(Mathf.RoundToInt(rangerCount * _theme.rangerMul), rangerCap);
                bruteCount = Mathf.Min(Mathf.RoundToInt(bruteCount * _theme.bruteMul), bruteCap);

                // Quái tự nổ xuất hiện từ tầng 4, không có ở tầng Swarm (đã quá đông)
                int bomberCount = (currentFloor >= 4 && _mod != FloorMod.Swarm)
                    ? Mathf.Min(1 + (currentFloor - 4) / 2, MaxBombers)
                    : 0;

                // Mini-boss Warden ở tầng 3 và 8
                bool wardenFloor = currentFloor == 3 || currentFloor == 8;

                // Trần tổng số quái để màn chơi luôn đọc được
                const int maxTotal = 28;
                int overflow = chaserCount + rangerCount + bruteCount + bomberCount + (wardenFloor ? 1 : 0) - maxTotal;
                if (overflow > 0) chaserCount = Mathf.Max(0, chaserCount - overflow);

                for (int i = 0; i < chaserCount; i++)
                {
                    SpawnChaser(GetRandomSpawnPos());
                }
                for (int i = 0; i < rangerCount; i++)
                {
                    SpawnRanger(GetRandomSpawnPos());
                }
                for (int i = 0; i < bruteCount; i++)
                {
                    SpawnBrute(GetRandomSpawnPos());
                }
                for (int i = 0; i < bomberCount; i++)
                {
                    SpawnBomber(GetRandomSpawnPos());
                }
                if (wardenFloor)
                {
                    SpawnWarden(GetRandomSpawnPos());
                }
            }

            remainingEnemies = _activeEnemies.Count;
            GameUI.Instance?.UpdateEnemiesRemaining(remainingEnemies);
        }

        private Vector3 GetRandomSpawnPos()
        {
            float halfW = roomWidth / 2f - 3f;
            float halfH = roomHeight / 2f - 3f;
            Vector3 pos;
            int tries = 0;
            do
            {
                pos = new Vector3(UnityEngine.Random.Range(-halfW, halfW), UnityEngine.Random.Range(-halfH + 3f, halfH), 0);
                tries++;
            }
            while ((Vector3.Distance(pos, new Vector3(0, -roomHeight / 2f + 2.5f, 0)) < 3.5f || IsNearPillar(pos)) && tries < 40);

            return pos;
        }

        private bool IsNearPillar(Vector3 pos)
        {
            foreach (var p in _pillarPositions)
            {
                if (Vector2.Distance(pos, p) < 1.5f) return true;
            }
            return false;
        }

        private void SpawnChaser(Vector3 pos)
        {
            var go = new GameObject("Slime_Chaser");
            go.transform.SetParent(enemyContainer, false);
            go.transform.position = pos;
            var enemy = go.AddComponent<ChaserEnemy>();
            ScaleEnemy(enemy);
            _activeEnemies.Add(enemy);
        }

        private void SpawnRanger(Vector3 pos)
        {
            var go = new GameObject("Crimson_Spitter");
            go.transform.SetParent(enemyContainer, false);
            go.transform.position = pos;
            var enemy = go.AddComponent<RangerEnemy>();
            ScaleEnemy(enemy);
            _activeEnemies.Add(enemy);
        }

        private void SpawnBrute(Vector3 pos)
        {
            var go = new GameObject("Armored_Slime");
            go.transform.SetParent(enemyContainer, false);
            go.transform.position = pos;
            var enemy = go.AddComponent<BruteEnemy>();
            ScaleEnemy(enemy);
            _activeEnemies.Add(enemy);
        }

        private void SpawnWarden(Vector3 pos)
        {
            var go = new GameObject("Warden_Brute");
            go.transform.SetParent(enemyContainer, false);
            go.transform.position = pos;
            var enemy = go.AddComponent<WardenEnemy>();
            ScaleEnemy(enemy);
            _activeEnemies.Add(enemy);
        }

        private void SpawnBomber(Vector3 pos)
        {
            var go = new GameObject("Bomber_Slime");
            go.transform.SetParent(enemyContainer, false);
            go.transform.position = pos;
            var enemy = go.AddComponent<BomberEnemy>();
            ScaleEnemy(enemy);
            _activeEnemies.Add(enemy);
        }

        private void SpawnBoss(Vector3 pos)
        {
            var go = new GameObject("Void_Sovereign_Boss");
            go.transform.SetParent(enemyContainer, false);
            go.transform.position = pos;
            var boss = go.AddComponent<BossEnemy>();
            ScaleEnemy(boss);
            _activeEnemies.Add(boss);
        }

        private void ScaleEnemy(EnemyBase enemy)
        {
            float hpMult = 1f + (currentFloor - 1) * 0.15f;
            float dmgMult = 1f + (currentFloor - 1) * 0.1f;
            enemy.maxHealth *= hpMult;
            enemy.currentHealth = enemy.maxHealth;
            enemy.contactDamage *= dmgMult;

            // Quái Tinh Anh (Elite Monster) xuất hiện từ tầng 3
            if (!(enemy is BossEnemy) && !(enemy is WardenEnemy) && currentFloor >= 3 && UnityEngine.Random.value < 0.20f)
            {
                enemy.MakeElite();
            }

            var sr = enemy.GetComponentInChildren<SpriteRenderer>();
            if (sr != null)
            {
                sr.sortingOrder = 10;
            }
        }

        public void OnEnemyDefeated(EnemyBase enemy)
        {
            _activeEnemies.Remove(enemy);
            totalEnemiesSlain++;
            remainingEnemies = Mathf.Max(0, _activeEnemies.Count);

            GameUI.Instance?.UpdateEnemiesRemaining(remainingEnemies);

            if (enemy is BossEnemy)
            {
                RewardBossRelic();
            }

            if (remainingEnemies <= 0)
            {
                OnRoomCleared();
            }
        }

        private void RewardBossRelic()
        {
            if (RelicSystem.Instance == null) return;
            var allRelics = (RelicType[])Enum.GetValues(typeof(RelicType));
            var unowned = new List<RelicType>();
            foreach (var r in allRelics)
            {
                if (!RelicSystem.Instance.HasRelic(r)) unowned.Add(r);
            }

            if (unowned.Count > 0)
            {
                var picked = unowned[UnityEngine.Random.Range(0, unowned.Count)];
                RelicSystem.Instance.AddRelic(picked);
            }
        }

        private void OnRoomCleared()
        {
            AudioManager.Instance?.PlaySound("portal");
            GameUI.Instance?.ShowBanner("ROOM CLEARED! DESCEND THROUGH THE PORTAL!", 4f);
            if (exitPortal != null)
            {
                exitPortal.SetOpen(true);
            }
        }

        public void GoToNextFloor()
        {
            currentFloor++;
            BuildFloor();
        }

        private void HandleLevelUp(int newLevel)
        {
            _pendingLevelUps++;
            if (PlayerController.Instance != null) VisualFX.LevelUpBurst(PlayerController.Instance.transform.position);
            if (!_upgradeModalOpen)
            {
                ShowNextUpgrade();
            }
        }

        private void ShowNextUpgrade()
        {
            if (_pendingLevelUps <= 0 || GameUI.Instance == null)
            {
                _upgradeModalOpen = false;
                return;
            }

            _pendingLevelUps--;
            _upgradeModalOpen = true;

            var allUpgrades = (UpgradeType[])Enum.GetValues(typeof(UpgradeType));
            var shuffled = new List<UpgradeType>(allUpgrades);
            for (int i = 0; i < shuffled.Count; i++)
            {
                int r = UnityEngine.Random.Range(i, shuffled.Count);
                var temp = shuffled[i];
                shuffled[i] = shuffled[r];
                shuffled[r] = temp;
            }

            var choices = new UpgradeType[] { shuffled[0], shuffled[1], shuffled[2] };
            GameUI.Instance.ShowLevelUpModal(choices, ShowNextUpgrade);
        }

        public void OnPlayerDied()
        {
            int lvl = PlayerController.Instance != null ? PlayerController.Instance.stats.level : 1;
            int gold = PlayerController.Instance != null ? PlayerController.Instance.stats.gold : 0;
            int best = PlayerPrefs.GetInt(BestFloorKey, 0);
            bool newRecord = currentFloor > best;
            if (newRecord)
            {
                best = currentFloor;
                PlayerPrefs.SetInt(BestFloorKey, best);
                PlayerPrefs.Save();
            }

            int bestCombo = ComboSystem.Instance != null ? ComboSystem.Instance.BestCombo : 0;
            GameUI.Instance?.ShowGameOverModal(currentFloor, lvl, gold, totalEnemiesSlain, best, newRecord, bestCombo);
        }

        public void RestartGame()
        {
            Time.timeScale = 1f;

            GameUI.Instance?.HideGameOverModal();
            ShopManager.Instance?.CloseShop();

            if (PlayerController.Instance == null)
            {
                GameBootstrap.SpawnPlayer();
            }
            else
            {
                PlayerController.Instance.ResetPlayer(new Vector3(0, -roomHeight / 2f + 2.5f, 0));
            }

            EquipmentManager.Instance?.ForgetAll();

            StartGame();
        }
    }
}
