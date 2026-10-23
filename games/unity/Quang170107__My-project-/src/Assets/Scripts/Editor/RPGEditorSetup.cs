#if UNITY_EDITOR
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace SimpleRPG.Editor
{
    public static class RPGEditorSetup
    {
        [MenuItem("RPG Game/Setup Playable Scene", false, 1)]
        public static void SetupScene()
        {
            var activeScene = SceneManager.GetActiveScene();

            // Setup Camera
            var cam = Camera.main;
            if (cam == null)
            {
                var camGo = new GameObject("Main Camera");
                cam = camGo.AddComponent<Camera>();
                cam.tag = "MainCamera";
                camGo.AddComponent<AudioListener>();
            }
            cam.orthographic = true;
            cam.orthographicSize = 7.5f;
            cam.backgroundColor = new Color(0.08f, 0.09f, 0.12f);
            cam.clearFlags = CameraClearFlags.SolidColor;

            var follow = cam.GetComponent<CameraFollow>();
            if (follow == null)
            {
                follow = cam.gameObject.AddComponent<CameraFollow>();
            }

            // Ensure Managers in scene
            EnsureSceneObject<AudioManager>("AudioManager");
            EnsureSceneObject<DamageNumberManager>("DamageNumberManager");
            EnsureSceneObject<LootManager>("LootManager");
            EnsureSceneObject<GameUI>("GameUI");
            EnsureSceneObject<DungeonManager>("DungeonManager");

            // Ensure Player
#if UNITY_6000_0_OR_NEWER
            var player = Object.FindAnyObjectByType<PlayerController>();
#else
            var player = Object.FindObjectOfType<PlayerController>();
#endif
            if (player == null)
            {
                var playerGo = GameBootstrap.SpawnPlayer();
                follow.SetTarget(playerGo.transform);
                Undo.RegisterCreatedObjectUndo(playerGo, "Create Player");
            }
            else
            {
                follow.SetTarget(player.transform);
            }

            EditorSceneManager.MarkSceneDirty(activeScene);
            Debug.Log("<color=#00ff88>[RPG Game]</color> Playable RPG Scene setup complete! Press Play to enjoy!");
        }

        [MenuItem("RPG Game/Export Sprites to Assets", false, 2)]
        public static void ExportSprites()
        {
            string folder = "Assets/Sprites";
            if (!Directory.Exists(folder))
            {
                Directory.CreateDirectory(folder);
            }

            string[] keys = new string[]
            {
                "player", "sword", "chaser", "ranger", "brute", "boss",
                "projectile_player", "projectile_enemy", "gem_xp", "coin",
                "potion_hp", "chest", "portal", "floor_tile", "wall_tile",
                "pillar", "slash"
            };

            foreach (var key in keys)
            {
                var sprite = SpriteFactory.GetSprite(key);
                if (sprite != null && sprite.texture != null)
                {
                    byte[] png = sprite.texture.EncodeToPNG();
                    string path = Path.Combine(folder, key + ".png");
                    File.WriteAllBytes(path, png);
                }
            }

            AssetDatabase.Refresh();
            Debug.Log($"<color=#00ff88>[RPG Game]</color> Exported {keys.Length} sprites to {folder}!");
        }

        [MenuItem("RPG Game/Build Windows Executable (.exe)", false, 3)]
        public static void BuildWindowsGame()
        {
            string projectRoot = Directory.GetCurrentDirectory();
            string buildFolder = Path.Combine(projectRoot, "Builds", "Windows");
            if (!Directory.Exists(buildFolder))
            {
                Directory.CreateDirectory(buildFolder);
            }
            string exePath = Path.Combine(buildFolder, "GeometricDungeon.exe");

            Debug.Log($"<color=#00ff88>[RPG Game]</color> Starting standalone Windows build: {exePath}...");

            BuildPlayerOptions opt = new BuildPlayerOptions();
            opt.scenes = new[] { "Assets/Scenes/SampleScene.unity" };
            opt.locationPathName = exePath;
            opt.target = BuildTarget.StandaloneWindows64;
            opt.options = BuildOptions.None;

            UnityEditor.Build.Reporting.BuildReport report = BuildPipeline.BuildPlayer(opt);
            var summary = report.summary;

            if (summary.result == UnityEditor.Build.Reporting.BuildResult.Succeeded)
            {
                Debug.Log($"<color=#00ff88>[RPG Game]</color> Build successful! Size: {summary.totalSize / (1024 * 1024)} MB at: {exePath}");
                EditorUtility.RevealInFinder(exePath);
            }
            else
            {
                Debug.LogError($"<color=#ff4444>[RPG Game]</color> Build failed with {summary.totalErrors} errors!");
            }
        }

        private static T EnsureSceneObject<T>(string name) where T : Component
        {
#if UNITY_6000_0_OR_NEWER
            var obj = Object.FindAnyObjectByType<T>();
#else
            var obj = Object.FindObjectOfType<T>();
#endif
            if (obj != null) return obj;

            var go = new GameObject(name);
            var comp = go.AddComponent<T>();
            Undo.RegisterCreatedObjectUndo(go, "Create " + name);
            return comp;
        }
    }
}
#endif
