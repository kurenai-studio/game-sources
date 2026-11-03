using System.Collections.Generic;
using QapaqInqa.Core;
using UnityEngine;

namespace QapaqInqa.Game
{
    /// <summary>
    /// Draws a <see cref="Stage"/>: the tile map baked into one texture, the parallax backdrop,
    /// and a sprite for every pickup, enemy, arrow and rock, synced from the rules each frame.
    /// </summary>
    public sealed class LevelView : MonoBehaviour
    {
        const int Tile = 16;

        GameArt art;
        Stage stage;
        Theme theme;
        Transform root;
        Texture2D levelTexture;
        SpriteRenderer player;
        SpriteRenderer gate;
        Transform farLayer;
        Transform nearLayer;
        float nearWidth;
        float farWidth;
        readonly Dictionary<int, SpriteRenderer> pickups = new Dictionary<int, SpriteRenderer>();
        readonly Dictionary<int, SpriteRenderer> enemies = new Dictionary<int, SpriteRenderer>();
        readonly List<SpriteRenderer> arrows = new List<SpriteRenderer>();
        readonly List<SpriteRenderer> rocks = new List<SpriteRenderer>();
        float playerSquash = 1f;
        float shootPose;
        float time;

        public Stage Stage => stage;

        public void Init(GameArt gameArt) => art = gameArt;

        /// <summary>Throws away the previous level's objects and builds this one.</summary>
        public void Show(Stage newStage, Theme newTheme)
        {
            Clear();
            stage = newStage;
            theme = newTheme;
            root = new GameObject("Level").transform;
            root.SetParent(transform, false);

            BuildBackdrop();
            BuildTiles();

            gate = Sprite("Sun Gate", art.Frames(art.SunGate, 32)[0], 1);
            gate.transform.position = new Vector3(stage.Map.Gate.X + 1f, stage.Map.Gate.Y, 0f);

            Sprite[] items = art.Frames(art.Items, 16, new Vector2(0.5f, 0.5f));
            Sprite[] checkpoints = art.Frames(art.Checkpoint, 16);
            foreach (Pickup pickup in stage.Pickups)
            {
                SpriteRenderer sprite = pickup.Kind == ThingKind.Checkpoint
                    ? Sprite("Checkpoint", checkpoints[0], 2)
                    : Sprite(pickup.Kind.ToString(), items[0], 3);
                sprite.transform.position = pickup.Kind == ThingKind.Checkpoint
                    ? new Vector3(pickup.Tile.X + 0.5f, pickup.Tile.Y, 0f)
                    : new Vector3(pickup.Center.X, pickup.Center.Y, 0f);
                pickups[pickup.Id] = sprite;
            }

            foreach (Enemy enemy in stage.Enemies)
            {
                enemies[enemy.Id] = Sprite(enemy.Kind.ToString(), null, 4);
            }
            player = Sprite("Player", art.Frames(art.Player, 16)[0], 6);
            Sync(0f);
        }

        public void Clear()
        {
            if (root != null) Destroy(root.gameObject);
            if (levelTexture != null) Destroy(levelTexture);
            pickups.Clear();
            enemies.Clear();
            arrows.Clear();
            rocks.Clear();
            stage = null;
        }

        /// <summary>A little squash when landing and a stretch when jumping.</summary>
        public void Squash(float amount) => playerSquash = amount;

        public void ShotFired() => shootPose = 0.18f;

        public void Sync(float dt)
        {
            if (stage == null) return;
            time += dt;
            SyncPlayer(dt);
            SyncPickups();
            SyncEnemies();
            SyncShots(arrows, stage.Arrows.Count, i => stage.Arrows[i].Position, i => stage.Arrows[i].Direction, Frame.Arrow);
            SyncShots(rocks, stage.Rocks.Count, i => stage.Rocks[i].Position, i => 1, Frame.Rock);
            Sprite[] gateFrames = art.Frames(art.SunGate, 32);
            gate.sprite = stage.GateOpen ? gateFrames[1 + (int)(time * 4f) % 2] : gateFrames[0];
        }

        /// <summary>Keeps the backdrop behind the camera with parallax.</summary>
        public void FollowCamera(Vector3 camera)
        {
            if (farLayer == null) return;
            farLayer.position = new Vector3(camera.x - Mathf.Repeat(camera.x * 0.05f, farWidth), camera.y, 10f);
            float nearY = camera.y - (camera.y - stage.Map.Height * 0.4f) * 0.25f;
            nearLayer.position = new Vector3(camera.x - Mathf.Repeat(camera.x * 0.3f, nearWidth), nearY, 9f);
        }

        void SyncPlayer(float dt)
        {
            PlayerMotor motor = stage.Player;
            Sprite[] frames = art.Frames(art.Player, 16);
            int frame;
            shootPose = Mathf.Max(0f, shootPose - dt);
            if (stage.Phase == StagePhase.Dying) frame = Frame.PlayerHurt;
            else if (motor.Climbing) frame = Frame.PlayerClimb + ((int)(motor.Y * 3f) & 1);
            else if (!motor.Grounded) frame = motor.VelocityY > 0f ? Frame.PlayerJump : Frame.PlayerFall;
            else if (shootPose > 0f) frame = Frame.PlayerShoot;
            else if (Mathf.Abs(motor.VelocityX) > 0.5f) frame = Frame.PlayerRun + (int)(time * 12f) % Frame.PlayerRunFrames;
            else frame = Frame.PlayerIdle + (int)(time * 2f) % 2;
            if (shootPose > 0f && !motor.Grounded && !motor.Climbing) frame = Frame.PlayerShoot;
            player.sprite = frames[frame];
            player.flipX = motor.Facing < 0;
            playerSquash = Mathf.MoveTowards(playerSquash, 1f, dt * 4f);
            player.transform.localScale = new Vector3(2f - playerSquash, playerSquash, 1f);
            player.transform.position = new Vector3(motor.X, motor.Y, 0f);
            bool blink = stage.Health.Invulnerable > 0f && ((int)(time * 20f) & 1) == 0;
            player.color = stage.Phase == StagePhase.Dying ? new Color(1f, 0.55f, 0.5f, 1f - stage.PhaseTime / Tuning.DyingTime) : new Color(1f, 1f, 1f, blink ? 0.35f : 1f);
            if (stage.Phase == StagePhase.Dying)
            {
                player.transform.position += new Vector3(0f, stage.PhaseTime * 1.2f, 0f);
                player.transform.rotation = Quaternion.Euler(0f, 0f, stage.PhaseTime * 220f * (motor.Facing > 0 ? 1f : -1f));
            }
            else
            {
                player.transform.rotation = Quaternion.identity;
            }
        }

        void SyncPickups()
        {
            Sprite[] items = art.Frames(art.Items, 16, new Vector2(0.5f, 0.5f));
            Sprite[] checkpoints = art.Frames(art.Checkpoint, 16);
            foreach (Pickup pickup in stage.Pickups)
            {
                SpriteRenderer sprite = pickups[pickup.Id];
                if (pickup.Kind == ThingKind.Checkpoint)
                {
                    sprite.sprite = pickup.Taken ? checkpoints[1 + (int)(time * 6f) % 2] : checkpoints[0];
                    continue;
                }
                sprite.enabled = !pickup.Taken;
                if (pickup.Taken) continue;
                float phase = pickup.Id * 0.7f;
                float bob = Mathf.Sin(time * 3f + phase) * 0.08f;
                switch (pickup.Kind)
                {
                    case ThingKind.Coin:
                        sprite.sprite = items[Frame.Coin + (int)(time * 10f + pickup.Id) % Frame.CoinFrames];
                        break;
                    case ThingKind.Artifact:
                        sprite.sprite = items[Frame.Idol + ((int)(time * 2f + phase) % 3 == 0 ? 1 : 0)];
                        bob *= 2f;
                        break;
                    case ThingKind.Shell:
                        sprite.sprite = items[Frame.Shell];
                        break;
                    case ThingKind.Heart:
                        sprite.sprite = items[Frame.Heart];
                        float beat = 1f + Mathf.Max(0f, Mathf.Sin(time * 6f)) * 0.12f;
                        sprite.transform.localScale = new Vector3(beat, beat, 1f);
                        break;
                }
                sprite.transform.position = new Vector3(pickup.Center.X, pickup.Center.Y + bob, 0f);
            }
        }

        void SyncEnemies()
        {
            foreach (Enemy enemy in stage.Enemies)
            {
                SpriteRenderer sprite = enemies[enemy.Id];
                sprite.enabled = enemy.Alive || (enemy is StonePuma && enemy.Flash > 0f);
                if (!sprite.enabled) continue;
                sprite.transform.position = new Vector3(enemy.X, enemy.Y, 0f);
                sprite.flipX = enemy.Facing < 0;
                sprite.color = enemy.Flash > 0f ? new Color(1f, 0.45f, 0.4f) : Color.white;
                switch (enemy)
                {
                    case Walker walker:
                        sprite.sprite = art.Frames(art.Walker, 16)[(int)(walker.Age * 6f) % 4];
                        break;
                    case Bat bat:
                        sprite.sprite = art.Frames(art.Bat, 16)[(int)(bat.Age * 10f) % 3];
                        break;
                    case StonePuma puma:
                        sprite.sprite = PumaFrame(puma);
                        break;
                }
            }
        }

        Sprite PumaFrame(StonePuma puma)
        {
            Sprite[] frames = art.Frames(art.StonePuma, 48);
            if (puma.Flash > 0f) return frames[Frame.PumaHurt];
            switch (puma.Move)
            {
                case BossMove.Prowl: return frames[Frame.PumaRun + (int)(puma.Age * 10f) % 4];
                case BossMove.Crouch: return frames[Frame.PumaCrouch];
                case BossMove.Leap: return frames[Frame.PumaLeap];
                case BossMove.Throw: return frames[(int)(puma.MoveTime * 8f) % 2 == 0 ? Frame.PumaCrouch : Frame.PumaIdle];
                default: return frames[Frame.PumaIdle + (int)(puma.Age * 1.5f) % 2];
            }
        }

        void SyncShots(List<SpriteRenderer> pool, int count, System.Func<int, Vec2> position, System.Func<int, int> direction, int frame)
        {
            Sprite[] items = art.Frames(art.Items, 16, new Vector2(0.5f, 0.5f));
            while (pool.Count < count) pool.Add(Sprite("Shot", items[frame], 5));
            for (int i = 0; i < pool.Count; i++)
            {
                bool on = i < count;
                pool[i].enabled = on;
                if (!on) continue;
                Vec2 p = position(i);
                pool[i].transform.position = new Vector3(p.X, p.Y, 0f);
                pool[i].flipX = direction(i) < 0;
                if (frame == Frame.Rock) pool[i].transform.rotation = Quaternion.Euler(0f, 0f, time * -540f);
            }
        }

        SpriteRenderer Sprite(string name, Sprite sprite, int order)
        {
            var go = new GameObject(name);
            go.transform.SetParent(root, false);
            var renderer = go.AddComponent<SpriteRenderer>();
            renderer.sprite = sprite;
            renderer.sortingOrder = order;
            return renderer;
        }

        // ---- Tiles ----

        void BuildTiles()
        {
            LevelMap map = stage.Map;
            Color32[] sheet = art.Tiles.GetPixels32();
            int sheetWidth = art.Tiles.width;
            int themeRow = art.Tiles.height / Tile - 1 - (int)theme;
            var pixels = new Color32[map.Width * Tile * map.Height * Tile];
            int width = map.Width * Tile;
            for (int ty = 0; ty < map.Height; ty++)
            {
                for (int tx = 0; tx < map.Width; tx++)
                {
                    int index = TileIndex(map, tx, ty);
                    if (index < 0) continue;
                    // Stone deep inside a wall is darker, so edges read clearly.
                    float shade = map.At(tx, ty) == Core.Tile.Solid && Buried(map, tx, ty) ? 0.72f : 1f;
                    for (int py = 0; py < Tile; py++)
                    {
                        for (int px = 0; px < Tile; px++)
                        {
                            Color32 c = sheet[(themeRow * Tile + py) * sheetWidth + index * Tile + px];
                            if (c.a == 0) continue;
                            if (shade < 1f) c = new Color32((byte)(c.r * shade), (byte)(c.g * shade), (byte)(c.b * shade), c.a);
                            pixels[(ty * Tile + py) * width + tx * Tile + px] = c;
                        }
                    }
                }
            }
            levelTexture = new Texture2D(width, map.Height * Tile, TextureFormat.RGBA32, false)
            {
                filterMode = FilterMode.Point,
                wrapMode = TextureWrapMode.Clamp,
                name = "Level",
            };
            levelTexture.SetPixels32(pixels);
            levelTexture.Apply(false, true);
            var sprite = UnityEngine.Sprite.Create(levelTexture, new Rect(0, 0, levelTexture.width, levelTexture.height), Vector2.zero, Tile, 0, SpriteMeshType.FullRect);
            Sprite("Tiles", sprite, 0);
        }

        static bool Buried(LevelMap map, int x, int y)
        {
            for (int dy = -1; dy <= 1; dy++)
            {
                for (int dx = -1; dx <= 1; dx++)
                {
                    if (!map.IsSolid(x + dx, y + dy) && y + dy >= 0) return false;
                }
            }
            return true;
        }

        /// <summary>Column in the tile sheet: 0-1 stone with a top, 2-4 plain stone, 5 ledge, 6 ladder, 7 spikes.</summary>
        static int TileIndex(LevelMap map, int x, int y)
        {
            int hash = (x * 73856093) ^ (y * 19349663);
            switch (map.At(x, y))
            {
                case Core.Tile.Solid:
                    bool open = !map.IsSolid(x, y + 1) && y + 1 < map.Height;
                    return open ? (hash & 1) : 2 + (int)((uint)hash % 3);
                case Core.Tile.Platform: return 5;
                case Core.Tile.Ladder: return 6;
                case Core.Tile.Spikes: return 7;
                default: return -1;
            }
        }

        // ---- Backdrop ----

        void BuildBackdrop()
        {
            Texture2D far = art.FarBackgrounds[(int)theme];
            Texture2D near = art.NearBackgrounds[(int)theme];
            // 180 px tall over the camera's 15 units, with some spare height.
            float ppu = far.height / 16.5f;
            farWidth = far.width / ppu;
            nearWidth = near.width / ppu;
            farLayer = new GameObject("Far").transform;
            farLayer.SetParent(root, false);
            nearLayer = new GameObject("Near").transform;
            nearLayer.SetParent(root, false);
            Sprite farSprite = art.Whole(far, ppu);
            Sprite nearSprite = art.Whole(near, ppu);
            for (int i = -2; i <= 2; i++)
            {
                SpriteRenderer f = Sprite("Far", farSprite, -100);
                f.transform.SetParent(farLayer, false);
                f.transform.localPosition = new Vector3(i * farWidth, 0f, 0f);
                SpriteRenderer n = Sprite("Near", nearSprite, -90);
                n.transform.SetParent(nearLayer, false);
                n.transform.localPosition = new Vector3(i * nearWidth, 0f, 0f);
            }
        }
    }
}
