using System.Collections.Generic;
using PixelLeap.Core;
using PixelLeap.Enemy;
using PixelLeap.Player;
using UnityEngine;

namespace PixelLeap.Level
{
    /// <summary>
    /// 根据 LevelConfig 的字符画在运行时生成关卡。
    /// 优化点：同一行里连续的地面格合并成一个 BoxCollider2D，
    /// 64×11 的关卡碰撞体从数百个降到几十个，减少物理宽相检测开销。
    /// </summary>
    public class LevelBuilder
    {
        public Vector3 PlayerStart { get; private set; }
        public Rect Bounds { get; private set; }
        public int EnemyCount { get; private set; }
        public int ColliderCount { get; private set; }
        public int TileCount { get; private set; }

        public Transform Build(LevelConfig level, Transform parent, Transform player,
                               Dictionary<EnemyKind, EnemyConfig> enemyConfigs, Bullet projectile)
        {
            var root = new GameObject($"Level_{level.displayName}").transform;
            root.SetParent(parent, false);
            string[] rows = level.Rows;
            int height = rows.Length, width = 0;
            foreach (var r in rows) width = Mathf.Max(width, r.Length);
            Bounds = new Rect(-0.5f, -0.5f - 4f, width, height + 4f);   // 下方留出坠落空间
            EnemyCount = ColliderCount = TileCount = 0;

            for (int row = 0; row < height; row++)
            {
                string line = rows[row].PadRight(width, '.');
                float y = height - 1 - row;
                int runStart = -1;
                for (int x = 0; x <= width; x++)
                {
                    char ch = x < width ? line[x] : '.';
                    // ---- 地面合批 ----
                    if (ch == '#') { if (runStart < 0) runStart = x; TileCount++; }
                    else if (runStart >= 0) { CreateGround(root, runStart, x - 1, y, level.groundColor); runStart = -1; }

                    var pos = new Vector3(x, y, 0f);
                    switch (ch)
                    {
                        case 'P': PlayerStart = pos; break;
                        case '^': CreateTrigger(root, "Spikes", pos, TriggerKind.Spikes, new Color(0.9f, 0.9f, 0.95f), SpriteFactory.Triangle(), new Vector2(0.8f, 0.5f), -0.2f); break;
                        case 'C': CreateTrigger(root, "Checkpoint", pos, TriggerKind.Checkpoint, new Color(1f, 0.85f, 0.3f), SpriteFactory.Circle(), new Vector2(0.6f, 1.6f), 0.3f); break;
                        case 'G': CreateTrigger(root, "Goal", pos, TriggerKind.Goal, new Color(0.3f, 1f, 0.9f), SpriteFactory.Square(), new Vector2(0.8f, 2f), 0.5f); break;
                        case 'W': SpawnEnemy(root, pos, enemyConfigs[EnemyKind.Walker], player, projectile); break;
                        case 'J': SpawnEnemy(root, pos, enemyConfigs[EnemyKind.Jumper], player, projectile); break;
                        case 'S': SpawnEnemy(root, pos, enemyConfigs[EnemyKind.Shooter], player, projectile); break;
                    }
                }
            }
            return root;
        }

        void CreateGround(Transform root, int x0, int x1, float y, Color color)
        {
            var go = new GameObject($"Ground_{x0}_{x1}_{y}");
            go.transform.SetParent(root, false);
            int len = x1 - x0 + 1;
            go.transform.position = new Vector3((x0 + x1) * 0.5f, y, 0f);
            var col = go.AddComponent<BoxCollider2D>();
            col.size = new Vector2(len, 1f);
            ColliderCount++;
            // 视觉：一个拉伸的 SpriteRenderer（Tiled 模式保持像素比例）
            var sr = SpriteFactory.AddVisual(go, SpriteFactory.Square(), color, -1);
            sr.drawMode = SpriteDrawMode.Tiled;
            sr.size = new Vector2(len, 1f);
        }

        static void CreateTrigger(Transform root, string name, Vector3 pos, TriggerKind kind, Color color, Sprite sprite, Vector2 size, float yOffset)
        {
            var go = new GameObject(name);
            go.transform.SetParent(root, false);
            go.transform.position = pos + Vector3.up * yOffset;
            go.layer = 2;
            var vis = new GameObject("Visual");
            vis.transform.SetParent(go.transform, false);
            vis.transform.localScale = new Vector3(size.x, size.y, 1f);
            SpriteFactory.AddVisual(vis, sprite, color, 1);
            go.AddComponent<BoxCollider2D>().size = size;
            go.AddComponent<LevelTrigger>().kind = kind;
        }

        void SpawnEnemy(Transform root, Vector3 pos, EnemyConfig config, Transform player, Bullet projectile)
        {
            var go = new GameObject($"Enemy_{config.kind}");
            go.transform.SetParent(root, false);
            go.transform.position = pos;
            go.layer = 2;
            var vis = new GameObject("Visual");
            vis.transform.SetParent(go.transform, false);
            vis.transform.localScale = new Vector3(0.8f, 0.8f, 1f);
            SpriteFactory.AddVisual(vis, config.kind == EnemyKind.Jumper ? SpriteFactory.Circle() : SpriteFactory.Square(), config.color, 2);
            go.AddComponent<Rigidbody2D>();
            go.AddComponent<BoxCollider2D>().size = new Vector2(0.8f, 0.8f);
            go.AddComponent<Health>();
            go.AddComponent<EnemyBrain>().Init(config, player, config.kind == EnemyKind.Shooter ? projectile : null);
            EnemyCount++;
        }
    }
}
