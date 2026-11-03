using System;
using System.Collections;
using System.IO;
using QapaqInqa.Core;
using UnityEngine;
using UnityEngine.UIElements;

namespace QapaqInqa.Game
{
    /// <summary>
    /// Opt-in capture of README screenshots: <c>-screenshot &lt;folder&gt; -scenario title,valley,...</c>.
    /// Without the -screenshot argument nothing is created, so normal runs and WebGL builds are
    /// unaffected. Inside the editor (ProjectBuilder.CaptureScreenshots) the camera and the HUD are
    /// rendered off screen at 1280x720 and blended, for machines that cannot run the player.
    /// </summary>
    public sealed class ScreenshotScenarios : MonoBehaviour
    {
        public const string AllScenarios = "title,intro,valley,mountain,cave,boss,pause,complete,gameover,victory";
        const int Width = 1280;
        const int Height = 720;

        string folder;
        string[] scenarios;
        RenderTexture sceneTarget;
        RenderTexture uiTarget;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void StartWhenRequested()
        {
            string target = Argument("-screenshot");
            if (string.IsNullOrEmpty(target)) return;
            var host = new GameObject(nameof(ScreenshotScenarios)).AddComponent<ScreenshotScenarios>();
            host.folder = target;
            host.scenarios = (Argument("-scenario") ?? AllScenarios).Split(',');
        }

        IEnumerator Start()
        {
            Directory.CreateDirectory(folder);
            var director = FindAnyObjectByType<GameDirector>();
            director.UseMemoryStore();
            director.Records.SubmitScore(18450);
            director.Records.SubmitClear(0, 71.4f);
            director.Records.SubmitClear(1, 98.2f);
            if (Application.isEditor) RenderOffscreen(director);
            yield return new WaitForSecondsRealtime(0.5f);
            foreach (string raw in scenarios)
            {
                string scenario = raw.Trim();
                UnityEngine.Random.InitState(scenario.GetHashCode());
                yield return Stage(director, scenario);
                Texture2D shot;
                if (Application.isEditor)
                {
                    yield return null;
                    shot = CaptureOffscreen();
                }
                else
                {
                    yield return new WaitForEndOfFrame();
                    shot = ScreenCapture.CaptureScreenshotAsTexture();
                }
                File.WriteAllBytes(Path.Combine(folder, scenario + ".png"), shot.EncodeToPNG());
                Destroy(shot);
                Debug.Log($"Saved screenshot {scenario}.png");
            }
#if UNITY_EDITOR
            UnityEditor.EditorApplication.Exit(0);
#else
            Application.Quit();
#endif
        }

        static IEnumerator Stage(GameDirector director, string scenario)
        {
            director.ScriptedInput = true;
            director.ScriptedFrame = InputFrame.None;
            switch (scenario)
            {
                case "title":
                    director.ToTitle();
                    yield return Wait(1.5f);
                    break;
                case "intro":
                    director.StartLevel(1);
                    yield return Wait(1f);
                    break;
                case "valley":
                    yield return Play(director, 0, new Vec2(19.5f, 4f));
                    director.Run.Stage.Invincible = true;
                    yield return Act(director, new InputFrame(1f, 0f, false, false, false), 0.5f);
                    yield return Act(director, new InputFrame(1f, 0f, true, true, false), 0.35f);
                    break;
                case "mountain":
                    yield return Play(director, 1, new Vec2(49.5f, 9f));
                    director.Run.Stage.Invincible = true;
                    yield return Act(director, new InputFrame(1f, 0f, false, false, true), 0.6f);
                    yield return Act(director, new InputFrame(1f, 0f, true, true, true), 0.3f);
                    break;
                case "cave":
                    yield return Play(director, 2, new Vec2(44.5f, 12f));
                    director.Run.Stage.Invincible = true;
                    yield return Act(director, new InputFrame(1f, 0f, false, false, true), 0.9f);
                    break;
                case "boss":
                    yield return Play(director, 3, new Vec2(66.5f, 3f));
                    director.Run.Stage.Invincible = true;
                    yield return Act(director, new InputFrame(0.25f, 0f, false, false, true), 2.6f);
                    yield return Act(director, new InputFrame(-1f, 0f, true, true, true), 0.35f);
                    break;
                case "pause":
                    yield return Play(director, 0, new Vec2(58.5f, 8f));
                    yield return Act(director, InputFrame.None, 0.4f);
                    director.TogglePause();
                    yield return Wait(0.5f);
                    break;
                case "complete":
                    yield return Play(director, 0, new Vec2(3.5f, 2f));
                    director.CollectIdolsNow();
                    LevelMap map = director.Run.Stage.Map;
                    director.PlacePlayer(new Vec2(map.Gate.X - 1f, map.Gate.Y));
                    yield return Act(director, new InputFrame(1f, 0f, false, false, false), 1.5f);
                    yield return Wait(0.6f);
                    break;
                case "gameover":
                    yield return Play(director, 2, new Vec2(20.5f, 3f));
                    for (int i = 0; i < Tuning.StartingLives; i++)
                    {
                        director.KillPlayerNow();
                        yield return Wait(Tuning.DyingTime + 0.3f);
                    }
                    yield return Wait(0.6f);
                    break;
                case "victory":
                    yield return Play(director, 3, new Vec2(66.5f, 3f));
                    director.Run.Stage.Invincible = true;
                    director.CollectIdolsNow();
                    director.Run.Stage.Strike(director.Run.Stage.Boss, Tuning.BossHealth);
                    LevelMap court = director.Run.Stage.Map;
                    yield return Act(director, InputFrame.None, 0.5f);
                    director.PlacePlayer(new Vec2(court.Gate.X - 1f, court.Gate.Y));
                    yield return Act(director, new InputFrame(1f, 0f, false, false, false), 1.5f);
                    yield return Wait(0.6f);
                    break;
                default:
                    Debug.LogWarning($"Unknown screenshot scenario '{scenario}'.");
                    break;
            }
        }

        static IEnumerator Play(GameDirector director, int level, Vec2 feet)
        {
            director.StartLevel(level);
            yield return null;
            director.BeginLevel();
            director.Hud.HideBanner();
            director.PlacePlayer(feet);
            yield return Wait(0.3f);
        }

        static IEnumerator Act(GameDirector director, InputFrame frame, float seconds)
        {
            director.ScriptedFrame = frame;
            yield return null;
            if (frame.JumpPressed) director.ScriptedFrame = new InputFrame(frame.MoveX, frame.MoveY, false, frame.JumpHeld, frame.Fire);
            yield return Wait(seconds);
            director.ScriptedFrame = InputFrame.None;
        }

        static IEnumerator Wait(float seconds)
        {
            float t = 0f;
            while (t < seconds)
            {
                t += Time.unscaledDeltaTime;
                yield return null;
            }
        }

        void RenderOffscreen(GameDirector director)
        {
            sceneTarget = new RenderTexture(Width, Height, 24, RenderTextureFormat.ARGB32);
            uiTarget = new RenderTexture(Width, Height, 24, RenderTextureFormat.ARGB32);
            Camera.main.targetTexture = sceneTarget;
            var document = director.Hud.GetComponent<UIDocument>();
            PanelSettings panel = Instantiate(document.panelSettings);
            panel.targetTexture = uiTarget;
            panel.clearColor = true;
            panel.colorClearValue = Color.clear;
            document.panelSettings = panel;
        }

        Texture2D CaptureOffscreen()
        {
            Color[] scene = Read(sceneTarget);
            Color[] ui = Read(uiTarget);
            for (int i = 0; i < scene.Length; i++)
            {
                Color over = ui[i];
                Color result = Color.Lerp(scene[i], new Color(over.r, over.g, over.b), over.a);
                result.a = 1f;
                scene[i] = result;
            }
            var shot = new Texture2D(Width, Height, TextureFormat.RGBA32, false);
            shot.SetPixels(scene);
            shot.Apply();
            return shot;
        }

        static Color[] Read(RenderTexture target)
        {
            RenderTexture previous = RenderTexture.active;
            RenderTexture.active = target;
            var texture = new Texture2D(target.width, target.height, TextureFormat.RGBA32, false);
            texture.ReadPixels(new Rect(0, 0, target.width, target.height), 0, 0);
            texture.Apply();
            RenderTexture.active = previous;
            Color[] pixels = texture.GetPixels();
            Destroy(texture);
            return pixels;
        }

        static string Argument(string name)
        {
            string[] args = Environment.GetCommandLineArgs();
            int index = Array.IndexOf(args, name);
            return index >= 0 && index + 1 < args.Length ? args[index + 1] : null;
        }
    }
}
