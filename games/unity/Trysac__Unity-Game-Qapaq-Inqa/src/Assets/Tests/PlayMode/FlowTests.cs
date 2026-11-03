using System.Collections;
using NUnit.Framework;
using QapaqInqa.Core;
using QapaqInqa.Game;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.TestTools;

namespace QapaqInqa.Tests
{
    /// <summary>The game's flow in the real scene: start, death and respawn, a level clear and pause.</summary>
    public class FlowTests
    {
        GameDirector director;

        IEnumerator Load()
        {
            SceneManager.LoadScene("QapaqInqa");
            yield return null;
            yield return null;
            director = Object.FindAnyObjectByType<GameDirector>();
            Assert.That(director, Is.Not.Null);
            director.UseMemoryStore();
            director.ScriptedInput = true;
            Assert.That(director.Screen, Is.EqualTo(GameScreen.Title));
            Assert.That(director.Hud.MenuOpen, Is.True, "the title menu is showing");
        }

        IEnumerator Play(int level)
        {
            director.StartLevel(level);
            Assert.That(director.Screen, Is.EqualTo(GameScreen.Intro));
            yield return null;
            director.BeginLevel();
            yield return null;
            Assert.That(director.Screen, Is.EqualTo(GameScreen.Playing));
            Assert.That(director.Hud.MenuOpen, Is.False);
        }

        static IEnumerator Wait(float seconds)
        {
            float start = Time.realtimeSinceStartup;
            while (Time.realtimeSinceStartup - start < seconds) yield return null;
        }

        [UnityTest]
        public IEnumerator StartingTheCampaignShowsThePrologueThenTheFirstTrial()
        {
            yield return Load();
            director.StartCampaign();
            Assert.That(director.Screen, Is.EqualTo(GameScreen.Intro));
            Assert.That(director.Hud.Page.Title, Is.EqualTo(Levels.Prologue.Title));
            director.Hud.Page.Items[0].Activate();
            Assert.That(director.Hud.Page.Title, Is.EqualTo(Levels.All[0].Name));
            director.BeginLevel();
            Assert.That(director.Screen, Is.EqualTo(GameScreen.Playing));
            Assert.That(director.Run.LevelIndex, Is.EqualTo(0));
            Assert.That(director.Run.Lives, Is.EqualTo(Tuning.StartingLives));

            director.ScriptedFrame = new InputFrame(1f, 0f, false, false, false);
            yield return Wait(0.5f);
            Assert.That(director.Run.Stage.Player.X, Is.GreaterThan(Levels.All.Count > 0 ? new LevelMap(Levels.All[0].Map).Start.X + 1f : 0f), "the player runs right");
            Assert.That(director.Run.Stage.Elapsed, Is.GreaterThan(0.3f));
        }

        [UnityTest]
        public IEnumerator DyingCostsALifeAndRespawnsAtTheLastCheckpoint()
        {
            yield return Load();
            yield return Play(0);
            Stage stage = director.Run.Stage;
            Pickup checkpoint = null;
            foreach (Pickup p in stage.Pickups) if (p.Kind == ThingKind.Checkpoint) { checkpoint = p; break; }
            director.PlacePlayer(new Vec2(checkpoint.Tile.X + 0.5f, checkpoint.Tile.Y));
            yield return Wait(0.2f);
            Assert.That(stage.RespawnPoint, Is.EqualTo(new Vec2(checkpoint.Tile.X + 0.5f, checkpoint.Tile.Y)));

            director.PlacePlayer(stage.Map.Start);
            yield return Wait(0.1f);
            director.KillPlayerNow();
            yield return Wait(0.1f);
            Assert.That(stage.Phase, Is.EqualTo(StagePhase.Dying));
            yield return Wait(Tuning.DyingTime + 0.3f);
            Assert.That(director.Run.Lives, Is.EqualTo(Tuning.StartingLives - 1));
            Assert.That(stage.Phase, Is.EqualTo(StagePhase.Playing));
            Assert.That(stage.Health.Hearts, Is.EqualTo(Tuning.MaxHearts));
            Assert.That(stage.Player.X, Is.EqualTo(checkpoint.Tile.X + 0.5f).Within(0.5f), "back at the checkpoint");
        }

        [UnityTest]
        public IEnumerator LosingTheLastLifeShowsTheGameOverMenu()
        {
            yield return Load();
            yield return Play(1);
            for (int i = 0; i < Tuning.StartingLives; i++)
            {
                director.KillPlayerNow();
                yield return Wait(Tuning.DyingTime + 0.3f);
            }
            Assert.That(director.Screen, Is.EqualTo(GameScreen.GameOver));
            Assert.That(director.Hud.MenuOpen, Is.True);
            director.Hud.Page.Items[0].Activate(); // try again
            Assert.That(director.Screen, Is.EqualTo(GameScreen.Intro));
            Assert.That(director.Run.LevelIndex, Is.EqualTo(1));
            Assert.That(director.Run.Lives, Is.EqualTo(Tuning.StartingLives));
        }

        [UnityTest]
        public IEnumerator EnteringTheOpenGateCompletesTheLevelAndRecordsIt()
        {
            yield return Load();
            yield return Play(0);
            director.CollectIdolsNow();
            Stage stage = director.Run.Stage;
            Assert.That(stage.GateOpen, Is.True);
            director.PlacePlayer(new Vec2(stage.Map.Gate.X - 1f, stage.Map.Gate.Y));
            director.ScriptedFrame = new InputFrame(1f, 0f, false, false, false);
            float start = Time.realtimeSinceStartup;
            while (director.Screen == GameScreen.Playing && Time.realtimeSinceStartup - start < 3f) yield return null;
            Assert.That(director.Screen, Is.EqualTo(GameScreen.LevelComplete));
            Assert.That(director.Run.Phase, Is.EqualTo(RunPhase.LevelComplete));
            Assert.That(director.Records.IsUnlocked(1), Is.True);
            Assert.That(director.Records.BestTime(0), Is.GreaterThan(0f));
            Assert.That(director.Run.Lives, Is.EqualTo(Tuning.StartingLives + 1));

            director.Hud.Page.Items[0].Activate(); // next trial
            Assert.That(director.Screen, Is.EqualTo(GameScreen.Intro));
            Assert.That(director.Run.LevelIndex, Is.EqualTo(1));
        }

        [UnityTest]
        public IEnumerator PauseFreezesTheTrialAndResumeContinuesIt()
        {
            yield return Load();
            yield return Play(0);
            director.ScriptedFrame = new InputFrame(1f, 0f, false, false, false);
            yield return Wait(0.3f);
            director.TogglePause();
            Assert.That(director.Screen, Is.EqualTo(GameScreen.Paused));
            Assert.That(director.Hud.MenuOpen, Is.True);
            float elapsed = director.Run.Stage.Elapsed;
            float x = director.Run.Stage.Player.X;
            yield return Wait(0.4f);
            Assert.That(director.Run.Stage.Elapsed, Is.EqualTo(elapsed), "the clock stops");
            Assert.That(director.Run.Stage.Player.X, Is.EqualTo(x), "the player stops");

            director.TogglePause();
            Assert.That(director.Screen, Is.EqualTo(GameScreen.Playing));
            Assert.That(director.Hud.MenuOpen, Is.False);
            yield return Wait(0.3f);
            Assert.That(director.Run.Stage.Elapsed, Is.GreaterThan(elapsed));
        }

        [UnityTest]
        public IEnumerator SettingsChangedFromThePauseMenuAreKept()
        {
            yield return Load();
            yield return Play(0);
            director.TogglePause();
            director.Hud.Page.Items[2].Activate(); // Settings
            Assert.That(director.Screen, Is.EqualTo(GameScreen.Settings));
            int music = director.Settings.MusicVolume;
            director.Hud.Page.Items[0].Adjust(-1);
            Assert.That(director.Settings.MusicVolume, Is.EqualTo(music - 1));
            director.Hud.Page.Back();
            Assert.That(director.Screen, Is.EqualTo(GameScreen.Paused), "back returns to the pause menu");
        }
    }
}
