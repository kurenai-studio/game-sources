using System;
using System.IO;
using QapaqInqa.Game;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UIElements;

namespace QapaqInqa.EditorTools
{
    /// <summary>
    /// Sets the import options of the generated art and audio, creates the GameArt asset, the UI
    /// panel settings, the scene and the player settings from code, and builds the players. Batch mode:
    /// <code>
    /// Unity -batchmode -quit -projectPath . -executeMethod QapaqInqa.EditorTools.ProjectBuilder.SetUpProject
    /// Unity -batchmode -quit -projectPath . -executeMethod QapaqInqa.EditorTools.ProjectBuilder.BuildWindows -buildOutput &lt;folder&gt;
    /// Unity -batchmode -quit -projectPath . -executeMethod QapaqInqa.EditorTools.ProjectBuilder.BuildWebGL -buildOutput &lt;folder&gt;
    /// Unity -batchmode -projectPath . -executeMethod QapaqInqa.EditorTools.ProjectBuilder.CaptureScreenshots -screenshot &lt;folder&gt;
    /// </code>
    /// Run <c>python tools/art/build.py</c> and <c>python tools/audio/build.py</c> first to regenerate the sources.
    /// </summary>
    public static class ProjectBuilder
    {
        const string ScenePath = "Assets/Scenes/QapaqInqa.unity";
        const string ArtFolder = "Assets/Art";
        const string ArtPath = "Assets/Art/GameArt.asset";
        const string AudioFolder = "Assets/Audio";
        const string ThemePath = "Assets/UI/HudTheme.tss";
        const string PanelSettingsPath = "Assets/UI/HudPanelSettings.asset";
        static readonly string[] Themes = { "valley", "mountain", "cave", "temple" };

        [UnityEditor.MenuItem("Qapaq Inqa/Regenerate Art Asset, Scene and Player Settings")]
        public static void SetUpProject()
        {
            AssetDatabase.Refresh();
            GameArt art = CreateArt();
            PanelSettings panel = CreatePanelSettings();
            CreateScene(art, panel);
            ConfigurePlayer(art.Icon);
            AssetDatabase.SaveAssets();
            Debug.Log("Qapaq Inqa project set up.");
        }

        /// <summary>Enters play mode so ScreenshotScenarios captures the README screenshots, then exits. Run without -quit.</summary>
        public static void CaptureScreenshots()
        {
            EditorSceneManager.OpenScene(ScenePath);
            EditorApplication.isPlaying = true;
        }

        public static void BuildWindows() => Build(BuildTarget.StandaloneWindows64, "QapaqInqa.exe");

        public static void BuildWebGL() => Build(BuildTarget.WebGL, string.Empty);

        // ---- Art ----

        static GameArt CreateArt()
        {
            var art = AssetDatabase.LoadAssetAtPath<GameArt>(ArtPath);
            if (art == null)
            {
                art = ScriptableObject.CreateInstance<GameArt>();
                AssetDatabase.CreateAsset(art, ArtPath);
            }
            art.Player = Texture("Player");
            art.Walker = Texture("Walker");
            art.Bat = Texture("Bat");
            art.StonePuma = Texture("StonePuma");
            art.Items = Texture("Items");
            art.Checkpoint = Texture("Checkpoint");
            art.SunGate = Texture("SunGate");
            art.Tiles = Texture("Tiles", readable: true);
            art.Icon = Texture("AppIcon");
            for (int i = 0; i < Themes.Length; i++)
            {
                art.FarBackgrounds[i] = Texture($"Background_{Themes[i]}_far");
                art.NearBackgrounds[i] = Texture($"Background_{Themes[i]}_near");
            }

            art.TitleMusic = Clip("title_theme", music: true);
            art.ValleyMusic = Clip("valley_theme", music: true);
            art.MountainMusic = Clip("mountain_theme", music: true);
            art.CaveMusic = Clip("cave_theme", music: true);
            art.BossMusic = Clip("boss_theme", music: true);
            art.Jump = Clip("jump");
            art.Land = Clip("land");
            art.Shoot = Clip("shoot");
            art.ArrowHit = Clip("arrow_hit");
            art.Coin = Clip("coin");
            art.Idol = Clip("idol");
            art.Shell = Clip("shell");
            art.Heart = Clip("heart");
            art.CheckpointLit = Clip("checkpoint");
            art.GateOpen = Clip("gate_open");
            art.Hurt = Clip("hurt");
            art.Die = Clip("die");
            art.Stomp = Clip("stomp");
            art.EnemyDie = Clip("enemy_die");
            art.BossRoar = Clip("boss_roar");
            art.BossSlam = Clip("boss_slam");
            art.BossThrow = Clip("boss_throw");
            art.BossDefeat = Clip("boss_defeat");
            art.Clear = Clip("clear");
            art.GameOver = Clip("game_over");
            art.Click = Clip("click");
            art.Confirm = Clip("confirm");
            EditorUtility.SetDirty(art);
            return art;
        }

        /// <summary>Pixel art: point filtering, no compression, no mipmaps, any size.</summary>
        static Texture2D Texture(string name, bool readable = false)
        {
            string path = $"{ArtFolder}/{name}.png";
            var importer = AssetImporter.GetAtPath(path) as TextureImporter;
            if (importer == null)
            {
                throw new FileNotFoundException($"Missing {path}: run python tools/art/build.py first.");
            }
            importer.textureType = TextureImporterType.Default;
            importer.filterMode = FilterMode.Point;
            importer.textureCompression = TextureImporterCompression.Uncompressed;
            importer.mipmapEnabled = false;
            importer.alphaIsTransparency = true;
            importer.npotScale = TextureImporterNPOTScale.None;
            importer.wrapMode = TextureWrapMode.Clamp;
            importer.isReadable = readable;
            importer.maxTextureSize = 2048;
            importer.SaveAndReimport();
            return AssetDatabase.LoadAssetAtPath<Texture2D>(path);
        }

        static AudioClip Clip(string name, bool music = false)
        {
            string path = $"{AudioFolder}/{name}.ogg";
            var importer = AssetImporter.GetAtPath(path) as AudioImporter;
            if (importer == null)
            {
                throw new FileNotFoundException($"Missing {path}: run python tools/audio/build.py first.");
            }
            AudioImporterSampleSettings settings = importer.defaultSampleSettings;
            settings.loadType = music ? AudioClipLoadType.Streaming : AudioClipLoadType.DecompressOnLoad;
            importer.defaultSampleSettings = settings;
            importer.forceToMono = true;
            importer.SaveAndReimport();
            return AssetDatabase.LoadAssetAtPath<AudioClip>(path);
        }

        // ---- UI ----

        static PanelSettings CreatePanelSettings()
        {
            var panel = AssetDatabase.LoadAssetAtPath<PanelSettings>(PanelSettingsPath);
            if (panel == null)
            {
                panel = ScriptableObject.CreateInstance<PanelSettings>();
                AssetDatabase.CreateAsset(panel, PanelSettingsPath);
            }
            panel.themeStyleSheet = AssetDatabase.LoadAssetAtPath<ThemeStyleSheet>(ThemePath);
            panel.scaleMode = PanelScaleMode.ScaleWithScreenSize;
            panel.referenceResolution = new Vector2Int(1280, 720);
            panel.screenMatchMode = PanelScreenMatchMode.MatchWidthOrHeight;
            panel.match = 0.5f;
            panel.clearColor = false;
            EditorUtility.SetDirty(panel);
            return panel;
        }

        // ---- Scene ----

        static void CreateScene(GameArt art, PanelSettings panel)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(ScenePath));
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            var cameraObject = new GameObject("Main Camera") { tag = "MainCamera" };
            var camera = cameraObject.AddComponent<Camera>();
            camera.orthographic = true;
            camera.orthographicSize = CameraRig.HalfHeight;
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = new Color(0.08f, 0.05f, 0.07f);
            camera.nearClipPlane = 0.1f;
            camera.farClipPlane = 50f;
            cameraObject.transform.position = new Vector3(0f, 0f, -10f);
            cameraObject.AddComponent<AudioListener>();
            CameraRig rig = cameraObject.AddComponent<CameraRig>();

            var ui = new GameObject("HUD");
            var document = ui.AddComponent<UIDocument>();
            document.panelSettings = panel;
            Hud hud = ui.AddComponent<Hud>();

            var game = new GameObject("Game");
            var director = game.AddComponent<GameDirector>();
            var serialized = new SerializedObject(director);
            serialized.FindProperty("art").objectReferenceValue = art;
            serialized.FindProperty("hud").objectReferenceValue = hud;
            serialized.FindProperty("cameraRig").objectReferenceValue = rig;
            serialized.ApplyModifiedPropertiesWithoutUndo();

            EditorSceneManager.SaveScene(scene, ScenePath);
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
        }

        static void ConfigurePlayer(Texture2D icon)
        {
            PlayerSettings.companyName = "Trysac";
            PlayerSettings.productName = "Qapaq Inqa";
            PlayerSettings.SetIcons(NamedBuildTarget.Unknown, new[] { icon }, IconKind.Any);
            int[] sizes = PlayerSettings.GetIconSizes(NamedBuildTarget.Standalone, IconKind.Any);
            var standaloneIcons = new Texture2D[sizes.Length];
            Array.Fill(standaloneIcons, icon);
            PlayerSettings.SetIcons(NamedBuildTarget.Standalone, standaloneIcons, IconKind.Any);
            PlayerSettings.colorSpace = ColorSpace.Gamma;
            PlayerSettings.fullScreenMode = FullScreenMode.Windowed;
            PlayerSettings.defaultScreenWidth = 1280;
            PlayerSettings.defaultScreenHeight = 720;
            PlayerSettings.resizableWindow = true;
            PlayerSettings.runInBackground = false;
            PlayerSettings.defaultWebScreenWidth = 1280;
            PlayerSettings.defaultWebScreenHeight = 720;
            // Static hosts such as GitHub Pages do not send Content-Encoding for .br/.gz files.
            PlayerSettings.WebGL.compressionFormat = WebGLCompressionFormat.Disabled;
            PlayerSettings.WebGL.decompressionFallback = false;
        }

        // ---- Builds ----

        static void Build(BuildTarget target, string fileName)
        {
            string folder = Argument("-buildOutput");
            if (string.IsNullOrEmpty(folder))
            {
                throw new ArgumentException("Pass -buildOutput <folder> outside the repository.");
            }
            var options = new BuildPlayerOptions
            {
                scenes = new[] { ScenePath },
                target = target,
                locationPathName = string.IsNullOrEmpty(fileName) ? folder : Path.Combine(folder, fileName),
                options = BuildOptions.None,
            };
            BuildReport report = BuildPipeline.BuildPlayer(options);
            BuildSummary summary = report.summary;
            Debug.Log($"Build {target}: {summary.result}, {summary.totalSize / (1024 * 1024f):0.0} MB, {summary.totalErrors} errors.");
            if (Application.isBatchMode)
            {
                EditorApplication.Exit(summary.result == BuildResult.Succeeded ? 0 : 1);
            }
        }

        static string Argument(string name)
        {
            string[] args = Environment.GetCommandLineArgs();
            int index = Array.IndexOf(args, name);
            return index >= 0 && index + 1 < args.Length ? args[index + 1] : null;
        }
    }
}
