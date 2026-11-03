using System.Collections.Generic;
using PixelLeap.Core;
using PixelLeap.Enemy;
using PixelLeap.Player;
using UnityEngine;

namespace PixelLeap.Level
{
    /// <summary>
    /// 游戏流程：加载关卡 → 检查点 / 死亡复活 → 通关存档 → 下一关。
    /// 场景中只需要一个挂了本组件的空物体，其余对象全部由代码生成。
    /// </summary>
    public class GameManager : MonoBehaviour
    {
        public static GameManager Instance { get; private set; }

        [Header("配置（可留空，自动使用内置默认值）")]
        public PlayerConfig playerConfig;
        public LevelConfig[] levels;
        public EnemyConfig walker, jumper, shooter;

        public int CurrentLevel { get; private set; }
        public float LevelTime { get; private set; }
        public int Deaths { get; private set; }
        public int Kills { get; private set; }
        public bool Cleared { get; private set; }

        PlayerController2D player;
        Bullet bulletTemplate, enemyBulletTemplate;
        Transform levelRoot;
        Vector3 checkpoint;
        LevelBuilder builder = new LevelBuilder();
        SaveData save;
        Camera cam;
        CameraFollow2D follow;
        Dictionary<EnemyKind, EnemyConfig> enemyConfigs;

        void Awake()
        {
            Instance = this;
            Application.targetFrameRate = 120;
            save = SaveSystem.Load();
            if (levels == null || levels.Length == 0) levels = LevelConfig.CreateDefaults();
            enemyConfigs = new Dictionary<EnemyKind, EnemyConfig>
            {
                [EnemyKind.Walker] = walker ? walker : EnemyConfig.CreateDefault(EnemyKind.Walker),
                [EnemyKind.Jumper] = jumper ? jumper : EnemyConfig.CreateDefault(EnemyKind.Jumper),
                [EnemyKind.Shooter] = shooter ? shooter : EnemyConfig.CreateDefault(EnemyKind.Shooter),
            };
            bulletTemplate = CreateBulletTemplate("PlayerBullet", new Color(1f, 0.95f, 0.5f), 0.3f);
            enemyBulletTemplate = CreateBulletTemplate("EnemyBullet", new Color(0.8f, 0.5f, 1f), 0.35f);
            CreatePlayer();
            SetupCamera();
        }

        void Start() => LoadLevel(Mathf.Clamp(save.unlockedLevel, 0, levels.Length - 1));

        void Update()
        {
            if (!Cleared && !player.Health.IsDead) LevelTime += Time.deltaTime;
            if (player.transform.position.y < builder.Bounds.yMin) Die();          // 掉出关卡
            if (Input.GetKeyDown(KeyCode.R)) LoadLevel(CurrentLevel);
            if (Cleared && Input.GetKeyDown(KeyCode.Return)) LoadLevel((CurrentLevel + 1) % levels.Length);
        }

        // ---------------- 流程 ----------------
        public void LoadLevel(int index)
        {
            CurrentLevel = index;
            if (levelRoot) Destroy(levelRoot.gameObject);
            EnemyBrain.ResetSharedPool();
            levelRoot = builder.Build(levels[index], transform, player.transform, enemyConfigs, enemyBulletTemplate);
            checkpoint = builder.PlayerStart;
            player.Respawn(checkpoint);
            follow.bounds = builder.Bounds;
            cam.backgroundColor = levels[index].background;
            LevelTime = 0f; Kills = 0; Cleared = false;
        }

        public void SetCheckpoint(Vector3 pos) => checkpoint = pos;

        public void OnEnemyKilled()
        {
            Kills++;
            CameraFollow2D.Shake(0.08f, 0.12f);
        }

        public void CompleteLevel()
        {
            if (Cleared) return;
            Cleared = true;
            save.totalDeaths += Deaths;
            SaveSystem.RecordClear(save, CurrentLevel, LevelTime);
        }

        void Die()
        {
            Deaths++;
            player.Respawn(checkpoint);
        }

        void OnPlayerDied() => Invoke(nameof(Die), 0.5f);

        // ---------------- 生成 ----------------
        void CreatePlayer()
        {
            var go = new GameObject("Player") { layer = 2 };
            var vis = new GameObject("Visual");
            vis.transform.SetParent(go.transform, false);
            vis.transform.localScale = new Vector3(1f, 1f, 1f);
            var body = new GameObject("Body");
            body.transform.SetParent(vis.transform, false);
            body.transform.localScale = new Vector3(0.8f, 0.95f, 1f);
            SpriteFactory.AddVisual(body, SpriteFactory.Square(), new Color(0.35f, 0.85f, 1f), 5);
            var eye = new GameObject("Eye");
            eye.transform.SetParent(vis.transform, false);
            eye.transform.localPosition = new Vector3(0.2f, 0.18f, 0f);
            eye.transform.localScale = new Vector3(0.18f, 0.22f, 1f);
            SpriteFactory.AddVisual(eye, SpriteFactory.Square(), new Color(0.05f, 0.08f, 0.15f), 6);

            go.AddComponent<Rigidbody2D>();
            var box = go.AddComponent<BoxCollider2D>();
            box.size = new Vector2(0.78f, 0.94f);
            box.edgeRadius = 0.02f;                      // 圆角，避免卡在地块接缝
            go.AddComponent<Health>();
            player = go.AddComponent<PlayerController2D>();
            player.Init(playerConfig, bulletTemplate);
            player.Health.Died += OnPlayerDied;
        }

        Bullet CreateBulletTemplate(string name, Color color, float size)
        {
            var go = new GameObject(name) { layer = 2 };
            go.SetActive(false);                         // 模板本身不参与游戏
            go.transform.SetParent(transform, false);
            go.transform.localScale = Vector3.one * size;
            SpriteFactory.AddVisual(go, SpriteFactory.Circle(), color, 8);
            go.AddComponent<Rigidbody2D>();
            go.AddComponent<CircleCollider2D>().radius = 0.5f;
            return go.AddComponent<Bullet>();
        }

        void SetupCamera()
        {
            cam = Camera.main;
            if (!cam) cam = new GameObject("Main Camera") { tag = "MainCamera" }.AddComponent<Camera>();
            cam.orthographic = true;
            cam.orthographicSize = 6.5f;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.transform.position = new Vector3(0, 0, -10);
            follow = cam.GetComponent<CameraFollow2D>();
            if (!follow) follow = cam.gameObject.AddComponent<CameraFollow2D>();   // 注意：UnityEngine.Object 不要用 ?? 判空
            follow.target = player.transform;
        }

        // ---------------- HUD（OnGUI，原型阶段无需搭建 UI 预制体） ----------------
        void OnGUI()
        {
            if (player == null) return;
            var style = new GUIStyle(GUI.skin.label) { fontSize = 18, richText = true };
            var hp = player.Health;
            string hearts = new string('♥', hp.Hp) + new string('♡', hp.MaxHp - hp.Hp);
            GUI.Label(new Rect(16, 12, 600, 30), $"<b>{levels[CurrentLevel].displayName}</b>   <color=#ff7a7a>{hearts}</color>", style);
            GUI.Label(new Rect(16, 40, 600, 30), $"时间 {LevelTime:0.0}s   击杀 {Kills}/{builder.EnemyCount}   死亡 {Deaths}", style);
            var pool = player.BulletPool;
            var small = new GUIStyle(style) { fontSize = 13 };
            if (pool != null)
                GUI.Label(new Rect(16, 66, 700, 24),
                    $"<color=#9fb3c8>子弹池 活跃 {pool.CountActive} / 总数 {pool.CountAll}   碰撞体 {builder.ColliderCount}（合并前 {builder.TileCount}）</color>", small);
            GUI.Label(new Rect(16, Screen.height - 30, 900, 24), "<color=#9fb3c8>A/D 移动 · 空格 跳跃（可二段跳）· J/左键 射击 · R 重开</color>", small);

            if (Cleared)
            {
                float best = save.bestTimes.Length > CurrentLevel ? save.bestTimes[CurrentLevel] : LevelTime;
                var big = new GUIStyle(style) { fontSize = 32, alignment = TextAnchor.MiddleCenter };
                GUI.Label(new Rect(0, Screen.height * 0.35f, Screen.width, 50), "<b>关卡完成！</b>", big);
                GUI.Label(new Rect(0, Screen.height * 0.35f + 50, Screen.width, 40),
                    $"用时 {LevelTime:0.00}s   最佳 {best:0.00}s   按 Enter 进入下一关", new GUIStyle(style) { alignment = TextAnchor.MiddleCenter });
            }
        }
    }
}
