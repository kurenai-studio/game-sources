using QapaqInqa.Core;
using UnityEngine;

namespace QapaqInqa.Game
{
    public enum GameScreen
    {
        Title,
        LevelSelect,
        Settings,
        Codex,
        Intro,
        Playing,
        Paused,
        LevelComplete,
        GameOver,
        Victory,
    }

    /// <summary>
    /// Runs the game: menus, the level intro cards, and the fixed-step simulation of the current
    /// <see cref="Run"/>, turning its events into sound, particles, shake and hit-stop.
    /// </summary>
    public sealed class GameDirector : MonoBehaviour
    {
        [SerializeField] GameArt art;
        [SerializeField] Hud hud;
        [SerializeField] CameraRig cameraRig;

        GameInput input;
        LevelView view;
        Effects effects;
        AudioDirector audioDirector;
        IKeyValueStore store;
        Records records;
        Settings settings;
        float accumulator;
        float freeze;
        bool pendingJump;
        bool settingsFromPause;
        int codexPage;

        public GameScreen Screen { get; private set; }
        public Run Run { get; private set; }
        public Records Records => records;
        public Settings Settings => settings;
        public Hud Hud => hud;
        public LevelView View => view;
        /// <summary>For tests and the screenshot tool: ignore devices and use <see cref="ScriptedFrame"/>.</summary>
        public bool ScriptedInput { get; set; }
        public InputFrame ScriptedFrame { get; set; }

        void Awake()
        {
            input = new GameInput();
            store = new PlayerPrefsStore();
            records = new Records(store);
            settings = new Settings(store);
            view = new GameObject("Level View").AddComponent<LevelView>();
            view.Init(art);
            effects = new GameObject("Effects").AddComponent<Effects>();
            audioDirector = gameObject.AddComponent<AudioDirector>();
            audioDirector.Init();
            hud.Build(art.Icon);
            hud.ItemClicked += index => Activate(index);
            ApplySettings();
        }

        void Start() => ToTitle();

        /// <summary>Keeps records and settings in memory only (tests, screenshots).</summary>
        public void UseMemoryStore()
        {
            store = new MemoryStore();
            records = new Records(store);
            settings = new Settings(store);
            ApplySettings();
        }

        void ApplySettings()
        {
            audioDirector.SetVolumes(settings.MusicGain, settings.EffectsGain);
            cameraRig.ShakeEnabled = settings.ScreenShake;
        }

        // ---- Flow ----

        public void ToTitle()
        {
            Time.timeScale = 1f;
            Run = null;
            view.Clear();
            effects.Clear();
            hud.ClearFloaters();
            hud.HideBanner();
            hud.ShowPlay(false);
            audioDirector.SetDucked(false);
            audioDirector.PlayMusic(art.TitleMusic);
            Screen = GameScreen.Title;
            // A level stays behind the title as a living backdrop.
            var backdrop = new Stage(new LevelMap(Levels.All[0].Map));
            view.Show(backdrop, Theme.Valley);
            cameraRig.Snap(backdrop);
            ShowTitleMenu();
        }

        void ShowTitleMenu(int selected = 0)
        {
            var page = new MenuPage
            {
                Title = Levels.Title.ToUpperInvariant(),
                Subtitle = Levels.Subtitle,
                ShowEmblem = true,
                Footer = Footer(),
            };
            page.Items.Add(new MenuItem { Label = "Begin the trials", Activate = StartCampaign });
            page.Items.Add(new MenuItem { Label = "Choose a trial", Activate = ShowLevelSelect });
            page.Items.Add(new MenuItem { Label = "Codex", Activate = () => ShowCodex(0) });
            page.Items.Add(new MenuItem { Label = "Settings", Activate = () => ShowSettings(false) });
            if (Application.platform != RuntimePlatform.WebGLPlayer)
            {
                page.Items.Add(new MenuItem { Label = "Quit", Activate = Application.Quit });
            }
            string best = records.BestScore > 0 ? $"Best score {records.BestScore:N0}" : "No trials passed yet";
            if (records.BestRunTime > 0f) best += $"   -   Best run {Records.FormatTime(records.BestRunTime)}";
            page.Body = best;
            Screen = GameScreen.Title;
            hud.ShowMenu(page, selected);
        }

        void ShowLevelSelect()
        {
            Screen = GameScreen.LevelSelect;
            var page = new MenuPage { Title = "Choose a trial", Footer = Footer(), Back = () => ShowTitleMenu(1) };
            for (int i = 0; i < Levels.All.Count; i++)
            {
                int index = i;
                bool open = records.IsUnlocked(i);
                LevelInfo level = Levels.All[i];
                page.Items.Add(new MenuItem
                {
                    Label = open ? $"{i + 1}. {level.Name}" : $"{i + 1}. ???",
                    Value = () => open ? Records.FormatTime(records.BestTime(index)) : "locked",
                    Enabled = open,
                    Activate = () => StartLevel(index),
                });
            }
            page.Items.Add(new MenuItem { Label = "Back", Activate = () => ShowTitleMenu(1) });
            page.Body = "Trials open as you pass the one before. Best times are shown.";
            hud.ShowMenu(page);
        }

        void ShowCodex(int index)
        {
            Screen = GameScreen.Codex;
            codexPage = index;
            Lore[] pages = CodexPages();
            Lore lore = pages[index];
            int reached = records.LevelsReached;
            var page = new MenuPage
            {
                Title = lore.Title,
                Subtitle = $"Codex {index + 1} / {pages.Length}",
                Body = lore.Text,
                Footer = "Left / right to turn pages",
                Back = () => ShowTitleMenu(2),
            };
            page.Items.Add(new MenuItem { Label = "Page", Value = () => $"{codexPage + 1}", Adjust = step => ShowCodex((codexPage + step + pages.Length) % pages.Length) });
            page.Items.Add(new MenuItem { Label = "Back", Activate = () => ShowTitleMenu(2) });
            hud.ShowMenu(page);
        }

        static Lore[] CodexPages()
        {
            var pages = new Lore[Levels.All.Count + 2];
            pages[0] = Levels.Prologue;
            for (int i = 0; i < Levels.All.Count; i++) pages[i + 1] = Levels.All[i].Lore;
            pages[pages.Length - 1] = Levels.Epilogue;
            return pages;
        }

        void ShowSettings(bool fromPause)
        {
            settingsFromPause = fromPause;
            Screen = GameScreen.Settings;
            var page = new MenuPage { Title = "Settings", Footer = "Left / right to change", Back = CloseSettings };
            page.Items.Add(new MenuItem { Label = "Music", Value = () => Bar(settings.MusicVolume), Adjust = step => { settings.StepMusic(step); ApplySettings(); } });
            page.Items.Add(new MenuItem { Label = "Effects", Value = () => Bar(settings.EffectsVolume), Adjust = step => { settings.StepEffects(step); ApplySettings(); audioDirector.Play(art.Coin); } });
            page.Items.Add(new MenuItem { Label = "Screen shake", Value = () => settings.ScreenShake ? "On" : "Off", Adjust = _ => { settings.ToggleShake(); ApplySettings(); }, Activate = () => { settings.ToggleShake(); ApplySettings(); } });
            page.Items.Add(new MenuItem { Label = "Timer", Value = () => settings.ShowTimer ? "On" : "Off", Adjust = _ => settings.ToggleTimer(), Activate = settings.ToggleTimer });
            if (Application.platform != RuntimePlatform.WebGLPlayer)
            {
                page.Items.Add(new MenuItem { Label = "Fullscreen", Value = () => UnityEngine.Screen.fullScreen ? "On" : "Off", Adjust = _ => ToggleFullscreen(), Activate = ToggleFullscreen });
            }
            page.Items.Add(new MenuItem { Label = "Back", Activate = CloseSettings });
            hud.ShowMenu(page);
        }

        static void ToggleFullscreen() => UnityEngine.Screen.fullScreen = !UnityEngine.Screen.fullScreen;

        void CloseSettings()
        {
            if (settingsFromPause) ShowPauseMenu(2);
            else ShowTitleMenu(3);
        }

        static string Bar(int volume) => new string('|', volume) + new string('.', Settings.MaxVolume - volume);

        /// <summary>A fresh campaign from the first trial; the prologue comes first.</summary>
        public void StartCampaign() => Begin(new Run(records), prologue: true);

        public void StartLevel(int index) => Begin(new Run(records, index), prologue: false);

        void Begin(Run run, bool prologue)
        {
            Run = run;
            ShowLevel();
            ShowIntro(prologue);
        }

        /// <summary>Builds the current level's view and shows its intro card over it.</summary>
        void ShowLevel()
        {
            Time.timeScale = 1f;
            effects.Clear();
            hud.ClearFloaters();
            hud.HideBanner();
            view.Show(Run.Stage, Run.Level.Theme);
            cameraRig.Snap(Run.Stage);
            accumulator = 0f;
            freeze = 0f;
            pendingJump = false;
        }

        void ShowIntro(bool prologue)
        {
            Screen = GameScreen.Intro;
            hud.ShowPlay(false);
            audioDirector.PlayMusic(art.Music(Run.Level.Theme, false));
            if (prologue)
            {
                var first = new MenuPage { Title = Levels.Prologue.Title, Subtitle = Levels.Subtitle, Body = Levels.Prologue.Text, Back = ToTitle };
                first.Items.Add(new MenuItem { Label = "Continue", Activate = () => ShowIntro(false) });
                hud.ShowMenu(first);
                return;
            }
            LevelInfo level = Run.Level;
            var page = new MenuPage
            {
                Title = level.Name,
                Subtitle = $"Trial {Run.LevelIndex + 1}: {level.Trial}",
                Body = level.Lore.Title + "\n" + level.Lore.Text,
                Footer = Controls(),
                Back = ToTitle,
            };
            int idols = Run.Stage.ArtifactsTotal;
            string goal = Run.Stage.Boss != null
                ? $"Find {idols} golden idols and defeat the Stone Puma to open the Sun Gate."
                : $"Find {idols} golden idols to open the Sun Gate.";
            page.Body += "\n\n" + goal;
            page.Items.Add(new MenuItem { Label = "Begin", Activate = BeginLevel });
            hud.ShowMenu(page);
        }

        /// <summary>Closes the intro card and starts playing.</summary>
        public void BeginLevel()
        {
            if (Run == null) return;
            hud.HideMenu();
            hud.ShowPlay(true);
            Screen = GameScreen.Playing;
            hud.Banner(Run.Level.Name, Run.Level.Trial, 2f);
            audioDirector.Play(art.Confirm);
        }

        public void TogglePause()
        {
            if (Screen == GameScreen.Playing)
            {
                Screen = GameScreen.Paused;
                audioDirector.SetDucked(true);
                ShowPauseMenu(0);
            }
            else if (Screen == GameScreen.Paused)
            {
                Resume();
            }
        }

        void ShowPauseMenu(int selected)
        {
            Screen = GameScreen.Paused;
            hud.HideBanner();
            var page = new MenuPage { Title = "Paused", Subtitle = Run.Level.Name, Footer = Controls(), Back = Resume };
            page.Items.Add(new MenuItem { Label = "Resume", Activate = Resume });
            page.Items.Add(new MenuItem { Label = "Restart trial", Activate = RestartLevel });
            page.Items.Add(new MenuItem { Label = "Settings", Activate = () => ShowSettings(true) });
            page.Items.Add(new MenuItem { Label = "Main menu", Activate = ToTitle });
            hud.ShowMenu(page, selected);
        }

        void Resume()
        {
            hud.HideMenu();
            audioDirector.SetDucked(false);
            Screen = GameScreen.Playing;
        }

        public void RestartLevel()
        {
            if (Run == null) return;
            Run.RestartLevel();
            audioDirector.SetDucked(false);
            ShowLevel();
            hud.HideMenu();
            hud.ShowPlay(true);
            Screen = GameScreen.Playing;
        }

        void NextLevel()
        {
            Run.Continue();
            ShowLevel();
            ShowIntro(false);
        }

        void ShowLevelComplete()
        {
            Screen = GameScreen.LevelComplete;
            LevelResult r = Run.LastResult;
            audioDirector.Play(art.Clear);
            var page = new MenuPage
            {
                Title = "Trial passed",
                Subtitle = Run.Level.Name,
                Body = $"Time {Records.FormatTime(r.Time)}{(r.NewBestTime ? "   NEW BEST" : $"   (best {Records.FormatTime(records.BestTime(r.Level))})")}\n" +
                       $"Points {r.LevelPoints:N0}   Time bonus {r.TimeBonus:N0}\n" +
                       $"Score {Run.Score:N0}" + (r.ExtraLife ? "\nInti grants you another life." : ""),
            };
            page.Items.Add(new MenuItem { Label = "Next trial", Activate = NextLevel });
            page.Items.Add(new MenuItem { Label = "Main menu", Activate = ToTitle });
            hud.ShowPlay(false);
            hud.HideBanner();
            hud.ShowMenu(page);
        }

        void ShowGameOver()
        {
            Screen = GameScreen.GameOver;
            audioDirector.Play(art.GameOver);
            audioDirector.PlayMusic(art.TitleMusic);
            int level = Run.LevelIndex;
            var page = new MenuPage
            {
                Title = "The trial is lost",
                Subtitle = Run.Level.Name,
                Body = $"Score {Run.Score:N0}" + (Run.IsCampaign ? (Run.NewBestScore ? "   NEW BEST" : $"   (best {records.BestScore:N0})") : "\nScores count only for runs from the first trial."),
            };
            page.Items.Add(new MenuItem { Label = "Try this trial again", Activate = () => StartLevel(level) });
            page.Items.Add(new MenuItem { Label = "Main menu", Activate = ToTitle });
            hud.ShowPlay(false);
            hud.HideBanner();
            hud.ShowMenu(page);
        }

        void ShowVictory()
        {
            Screen = GameScreen.Victory;
            audioDirector.Play(art.Clear);
            audioDirector.PlayMusic(art.TitleMusic);
            string summary = Run.IsCampaign
                ? $"\nTotal time {Records.FormatTime(Run.TotalTime)}{(Run.NewBestRunTime ? "   NEW BEST" : "")}\nScore {Run.Score:N0}{(Run.NewBestScore ? "   NEW BEST" : "")}   (lives bonus {Run.LifeBonus:N0})"
                : $"\nScore {Run.Score:N0}";
            var page = new MenuPage
            {
                Title = "Inti has chosen",
                Subtitle = "You are Qapaq Inqa, the mighty Inca",
                Body = Levels.Epilogue.Text + "\n" + summary,
            };
            page.Items.Add(new MenuItem { Label = "Main menu", Activate = ToTitle });
            hud.ShowPlay(false);
            hud.HideBanner();
            hud.ShowMenu(page);
        }

        string Footer() => input.UsingGamepad ? "D-pad to choose  -  A to confirm  -  B to go back" : "Arrows to choose  -  Enter to confirm  -  Esc to go back";

        string Controls() => input.UsingGamepad
            ? "Stick move - A jump - X shoot - Up/Down climb - Start pause"
            : "A/D or arrows move - Space jump - J shoot - W/S climb - Esc pause";

        // ---- Frame ----

        void Update()
        {
            float dt = Time.unscaledDeltaTime;
            InputFrame frame = ScriptedInput ? ScriptedFrame : input.Read();
            hud.Tick(dt, cameraRig.View);

            if (hud.MenuOpen && !ScriptedInput)
            {
                MenuInput();
            }
            else if (Screen == GameScreen.Playing && !ScriptedInput && input.Pause)
            {
                TogglePause();
            }

            if (Screen == GameScreen.Playing)
            {
                Simulate(frame, dt);
            }
            else if (Screen == GameScreen.Title || Screen == GameScreen.LevelSelect || Screen == GameScreen.Settings && !settingsFromPause || Screen == GameScreen.Codex)
            {
                // The title backdrop: idle enemies wander behind the menu.
                view.Stage?.Step(InputFrame.None, dt);
            }

            if (view.Stage != null)
            {
                view.Sync(dt);
                cameraRig.Follow(view.Stage, dt);
                view.FollowCamera(cameraRig.transform.position);
            }
            if (Run != null && (Screen == GameScreen.Playing || Screen == GameScreen.Paused))
            {
                hud.UpdatePlay(Run, settings.ShowTimer, cameraRig.View);
            }
        }

        void MenuInput()
        {
            int v = input.Vertical();
            if (v != 0)
            {
                hud.Move(v);
                audioDirector.Play(art.Click);
            }
            int h = input.Horizontal();
            MenuPage page = hud.Page;
            if (h != 0 && page.Items.Count > 0 && page.Items[hud.Selected].Adjust != null)
            {
                page.Items[hud.Selected].Adjust(h);
                audioDirector.Play(art.Click);
                if (hud.Page == page) hud.Refresh();
            }
            if (input.Confirm)
            {
                Activate(hud.Selected);
            }
            else if (input.Back && page.Back != null)
            {
                audioDirector.Play(art.Click);
                page.Back();
            }
        }

        void Activate(int index)
        {
            MenuPage page = hud.Page;
            if (page == null || index < 0 || index >= page.Items.Count) return;
            MenuItem item = page.Items[index];
            if (!item.Enabled) return;
            if (item.Activate != null)
            {
                audioDirector.Play(art.Confirm);
                item.Activate();
                if (hud.Page == page) hud.Refresh();
            }
        }

        void Simulate(InputFrame frame, float dt)
        {
            pendingJump |= frame.JumpPressed;
            if (freeze > 0f)
            {
                freeze -= dt;
                return;
            }
            accumulator += Mathf.Min(dt, 0.1f);
            while (accumulator >= Tuning.Step && Screen == GameScreen.Playing)
            {
                accumulator -= Tuning.Step;
                var step = new InputFrame(frame.MoveX, frame.MoveY, pendingJump, frame.JumpHeld, frame.Fire);
                pendingJump = false;
                Run.Tick(step, Tuning.Step);
                React(Run.Stage);
                if (Run.Phase != RunPhase.Playing) break;
                if (freeze > 0f) break;
            }

            switch (Run.Phase)
            {
                case RunPhase.LevelComplete: ShowLevelComplete(); break;
                case RunPhase.GameOver: ShowGameOver(); break;
                case RunPhase.Victory: ShowVictory(); break;
            }

            StonePuma puma = Run.Stage.Boss;
            bool fight = puma != null && puma.Alive && puma.Move != BossMove.Dormant;
            if (Screen == GameScreen.Playing) audioDirector.PlayMusic(art.Music(Run.Level.Theme, fight));
        }

        /// <summary>Turns the last step's events into feedback.</summary>
        void React(Stage stage)
        {
            foreach (StageEvent e in stage.Events)
            {
                var at = new Vector2(e.At.X, e.At.Y);
                switch (e.Kind)
                {
                    case StageEventKind.Jump:
                        audioDirector.Play(art.Jump, 0.6f);
                        effects.Dust(at, 4);
                        view.Squash(1.25f);
                        break;
                    case StageEventKind.Land:
                        audioDirector.Play(art.Land, 0.5f);
                        effects.Dust(at);
                        view.Squash(0.75f);
                        break;
                    case StageEventKind.Shoot:
                        audioDirector.Play(art.Shoot, 0.6f);
                        view.ShotFired();
                        break;
                    case StageEventKind.ArrowBroke:
                        audioDirector.Play(art.ArrowHit, 0.4f);
                        effects.Burst(at, new Color(0.8f, 0.7f, 0.5f), 4, 3f, 15f, 0.3f);
                        break;
                    case StageEventKind.Coin:
                        audioDirector.Play(art.Coin, 0.7f);
                        effects.Sparkle(at, new Color(1f, 0.85f, 0.3f));
                        hud.Float(new Vector3(at.x, at.y + 0.4f), "+" + e.Points, null);
                        break;
                    case StageEventKind.Artifact:
                        audioDirector.Play(art.Idol);
                        effects.Sparkle(at, new Color(1f, 0.9f, 0.4f));
                        effects.Burst(at, new Color(1f, 0.95f, 0.6f), 18, 6f, 4f, 0.8f);
                        hud.Float(new Vector3(at.x, at.y + 0.6f), "+" + e.Points, "floater--big");
                        if (!stage.GateOpen) hud.Banner("Golden idol", $"{stage.ArtifactsFound} of {stage.ArtifactsTotal} found", 1.4f);
                        break;
                    case StageEventKind.Shell:
                        audioDirector.Play(art.Shell);
                        effects.Sparkle(at, new Color(1f, 0.5f, 0.35f));
                        hud.Float(new Vector3(at.x, at.y + 0.6f), "Mullu shell +" + e.Points, "floater--big");
                        break;
                    case StageEventKind.Heart:
                        audioDirector.Play(art.Heart);
                        effects.Sparkle(at, new Color(1f, 0.35f, 0.35f));
                        hud.Float(new Vector3(at.x, at.y + 0.6f), e.Points > 0 ? "+" + e.Points : "+1 heart", "floater--good");
                        break;
                    case StageEventKind.Checkpoint:
                        audioDirector.Play(art.CheckpointLit);
                        effects.Burst(at + new Vector2(0f, 1.2f), new Color(1f, 0.6f, 0.2f), 14, 4f, -2f, 0.7f);
                        hud.Banner("Checkpoint", "The huaca remembers you", 1.2f);
                        break;
                    case StageEventKind.GateOpened:
                        audioDirector.Play(art.GateOpen);
                        cameraRig.Shake(0.35f);
                        hud.Banner("The Sun Gate opens", "Find it and step into the light", 2f);
                        break;
                    case StageEventKind.Hurt:
                        audioDirector.Play(art.Hurt);
                        cameraRig.Shake(0.4f);
                        hud.Hurt();
                        freeze = 0.07f;
                        break;
                    case StageEventKind.Died:
                        audioDirector.Play(art.Die);
                        cameraRig.Shake(0.5f);
                        effects.Burst(at + new Vector2(0f, 0.7f), new Color(1f, 0.4f, 0.3f), 20, 5f, 8f, 0.9f);
                        break;
                    case StageEventKind.EnemyHit:
                        audioDirector.Play(art.ArrowHit, 0.7f);
                        effects.Burst(at, new Color(0.8f, 0.78f, 0.7f), 5, 3f, 12f, 0.3f);
                        freeze = Mathf.Max(freeze, 0.03f);
                        break;
                    case StageEventKind.EnemyDefeated:
                        audioDirector.Play(art.EnemyDie);
                        effects.Rubble(at, new Color(0.6f, 0.58f, 0.52f));
                        hud.Float(new Vector3(at.x, at.y + 0.5f), "+" + e.Points, null);
                        cameraRig.Shake(0.15f);
                        freeze = Mathf.Max(freeze, 0.05f);
                        break;
                    case StageEventKind.Stomp:
                        audioDirector.Play(art.Stomp);
                        effects.Dust(at, 8);
                        freeze = Mathf.Max(freeze, 0.06f);
                        break;
                    case StageEventKind.BossWoke:
                        audioDirector.Play(art.BossRoar);
                        cameraRig.Shake(0.5f);
                        hud.Banner("The Stone Puma wakes", "Guardian of the Sun Gate", 2f);
                        break;
                    case StageEventKind.BossSlam:
                        audioDirector.Play(art.BossSlam);
                        cameraRig.Shake(0.45f);
                        effects.Dust(at, 14);
                        break;
                    case StageEventKind.BossThrow:
                        audioDirector.Play(art.BossThrow, 0.7f);
                        break;
                    case StageEventKind.BossDefeated:
                        audioDirector.Play(art.BossDefeat);
                        cameraRig.Shake(0.9f);
                        effects.Rubble(at, new Color(0.64f, 0.6f, 0.55f));
                        effects.Rubble(at + new Vector2(0.8f, 0.3f), new Color(0.9f, 0.7f, 0.25f));
                        hud.Float(new Vector3(at.x, at.y + 1.2f), "+" + e.Points, "floater--big");
                        freeze = 0.25f;
                        break;
                    case StageEventKind.Cleared:
                        effects.Burst(at, new Color(1f, 0.9f, 0.5f), 30, 7f, 0f, 1f);
                        break;
                }
            }
        }

        // ---- Hooks for tests and screenshots ----

        public void KillPlayerNow() => Run?.Stage.Health.Kill();

        /// <summary>Picks up every idol (as if walked to) and stands the player in the open gate.</summary>
        public void CollectIdolsNow()
        {
            if (Run == null) return;
            foreach (Pickup pickup in Run.Stage.Pickups)
            {
                if (pickup.Kind != ThingKind.Artifact || pickup.Taken) continue;
                Run.Stage.PlacePlayer(new Vec2(pickup.Tile.X + 0.5f, pickup.Tile.Y));
                Run.Tick(InputFrame.None, Tuning.Step);
                React(Run.Stage);
            }
        }

        public void PlacePlayer(Vec2 feet) => Run?.Stage.PlacePlayer(feet);
    }
}
