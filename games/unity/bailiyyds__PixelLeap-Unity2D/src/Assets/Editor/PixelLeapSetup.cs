#if UNITY_EDITOR
using System.IO;
using PixelLeap.Enemy;
using PixelLeap.Level;
using PixelLeap.Player;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace PixelLeap.EditorTools
{
    /// <summary>一键生成演示场景与全部配置资源：菜单 PixelLeap → 创建演示场景。</summary>
    public static class PixelLeapSetup
    {
        const string ConfigDir = "Assets/PixelLeap/Configs";
        const string ScenePath = "Assets/PixelLeap/PixelLeap_Demo.unity";

        [MenuItem("PixelLeap/创建演示场景")]
        public static void CreateDemoScene()
        {
            Directory.CreateDirectory(ConfigDir);

            var player = CreateOrLoad<PlayerConfig>($"{ConfigDir}/PlayerConfig.asset", () => ScriptableObject.CreateInstance<PlayerConfig>());
            var walker = CreateOrLoad($"{ConfigDir}/Enemy_Walker.asset", () => EnemyConfig.CreateDefault(EnemyKind.Walker));
            var jumper = CreateOrLoad($"{ConfigDir}/Enemy_Jumper.asset", () => EnemyConfig.CreateDefault(EnemyKind.Jumper));
            var shooter = CreateOrLoad($"{ConfigDir}/Enemy_Shooter.asset", () => EnemyConfig.CreateDefault(EnemyKind.Shooter));

            var defaults = LevelConfig.CreateDefaults();
            var levels = new LevelConfig[defaults.Length];
            for (int i = 0; i < defaults.Length; i++)
            {
                int idx = i;
                levels[i] = CreateOrLoad($"{ConfigDir}/Level_{i + 1}.asset", () => defaults[idx]);
            }

            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var camGo = new GameObject("Main Camera") { tag = "MainCamera" };
            var cam = camGo.AddComponent<Camera>();
            cam.orthographic = true;
            cam.transform.position = new Vector3(0, 0, -10);
            camGo.AddComponent<CameraFollow2D>();

            var gm = new GameObject("GameManager").AddComponent<GameManager>();
            gm.playerConfig = player;
            gm.walker = walker; gm.jumper = jumper; gm.shooter = shooter;
            gm.levels = levels;

            EditorSceneManager.SaveScene(scene, ScenePath);
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
            AssetDatabase.SaveAssets();
            Selection.activeObject = player;
            Debug.Log("[PixelLeap] 演示场景已生成：点击 Play 开始。手感参数见 Assets/PixelLeap/Configs/PlayerConfig。");
        }

        [MenuItem("PixelLeap/清除本地存档")]
        public static void ClearSave()
        {
            string path = Path.Combine(Application.persistentDataPath, "pixelleap_save.json");
            if (File.Exists(path)) File.Delete(path);
            Debug.Log("[PixelLeap] 存档已清除");
        }

        static T CreateOrLoad<T>(string path, System.Func<T> factory) where T : ScriptableObject
        {
            var existing = AssetDatabase.LoadAssetAtPath<T>(path);
            if (existing) return existing;
            var asset = factory();
            AssetDatabase.CreateAsset(asset, path);
            return asset;
        }
    }
}
#endif
