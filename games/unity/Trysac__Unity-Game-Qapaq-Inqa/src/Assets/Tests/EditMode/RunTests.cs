using System.Collections.Generic;
using NUnit.Framework;
using QapaqInqa.Core;

namespace QapaqInqa.Core.Tests
{
    public class RunTests
    {
        MemoryStore store;
        Records records;

        [SetUp]
        public void Fresh()
        {
            store = new MemoryStore();
            records = new Records(store);
        }

        static LevelInfo Level(string name, float par, string[] map) =>
            new LevelInfo(name, "Trial", Theme.Valley, par, new Lore("t", "x"), map);

        /// <summary>Two flat levels with coins on the way to the gate.</summary>
        static IReadOnlyList<LevelInfo> TwoLevels(float par = 60f) => new[]
        {
            Level("One", par, Sim.Flat(20, "  o o")),
            Level("Two", par, Sim.Flat(20, "  o")),
        };

        static void Walk(Run run, float seconds, float x = 1f)
        {
            for (int i = 0; i < Sim.Seconds(seconds); i++) run.Tick(Sim.Hold(x: x), Sim.Dt);
        }

        static void Die(Run run)
        {
            run.Stage.Health.Kill();
            for (int i = 0; i < Sim.Seconds(Tuning.DyingTime) + 2; i++) run.Tick(InputFrame.None, Sim.Dt);
        }

        [Test]
        public void ARunStartsWithThreeLivesAndNoScore()
        {
            var run = new Run(records);
            Assert.That(run.Lives, Is.EqualTo(Tuning.StartingLives));
            Assert.That(run.Score, Is.EqualTo(0));
            Assert.That(run.LevelIndex, Is.EqualTo(0));
            Assert.That(run.Phase, Is.EqualTo(RunPhase.Playing));
            Assert.That(run.IsCampaign, Is.True);
        }

        [Test]
        public void LosingAllHeartsCostsALifeAndRespawns()
        {
            var run = new Run(records, TwoLevels());
            Die(run);
            Assert.That(run.Lives, Is.EqualTo(Tuning.StartingLives - 1));
            Assert.That(run.Phase, Is.EqualTo(RunPhase.Playing));
            Assert.That(run.Stage.Phase, Is.EqualTo(StagePhase.Playing));
            Assert.That(run.Stage.Health.Hearts, Is.EqualTo(Tuning.MaxHearts));
        }

        [Test]
        public void TheLastLifeEndsTheRunAndRecordsTheBestCampaignScore()
        {
            var run = new Run(records, TwoLevels());
            Walk(run, 0.8f);
            Assert.That(run.Score, Is.EqualTo(2 * Tuning.CoinPoints));
            for (int i = 0; i < Tuning.StartingLives; i++) Die(run);
            Assert.That(run.Phase, Is.EqualTo(RunPhase.GameOver));
            Assert.That(run.Lives, Is.EqualTo(0));
            Assert.That(run.Score, Is.EqualTo(2 * Tuning.CoinPoints));
            Assert.That(run.NewBestScore, Is.True);
            Assert.That(records.BestScore, Is.EqualTo(2 * Tuning.CoinPoints));
        }

        [Test]
        public void ARunFromTheLevelSelectDoesNotSetTheCampaignBest()
        {
            var run = new Run(records, TwoLevels(), firstLevel: 1);
            Assert.That(run.IsCampaign, Is.False);
            Walk(run, 0.8f);
            for (int i = 0; i < Tuning.StartingLives; i++) Die(run);
            Assert.That(run.Phase, Is.EqualTo(RunPhase.GameOver));
            Assert.That(run.NewBestScore, Is.False);
            Assert.That(records.BestScore, Is.EqualTo(0));
        }

        [Test]
        public void ClearingALevelBanksPointsAndATimeBonusGrantsALifeAndUnlocksTheNext()
        {
            var run = new Run(records, TwoLevels(par: 30f));
            Walk(run, 4f);
            Assert.That(run.Phase, Is.EqualTo(RunPhase.LevelComplete));
            LevelResult result = run.LastResult;
            Assert.That(result.Level, Is.EqualTo(0));
            Assert.That(result.LevelPoints, Is.EqualTo(2 * Tuning.CoinPoints));
            Assert.That(result.Time, Is.GreaterThan(1f).And.LessThan(4f));
            int expectedBonus = (int)System.Math.Floor(30f - result.Time) * Tuning.TimeBonusPerSecond;
            Assert.That(result.TimeBonus, Is.EqualTo(expectedBonus));
            Assert.That(run.Score, Is.EqualTo(2 * Tuning.CoinPoints + expectedBonus));
            Assert.That(result.ExtraLife, Is.True);
            Assert.That(run.Lives, Is.EqualTo(Tuning.StartingLives + 1));
            Assert.That(result.NewBestTime, Is.True);
            Assert.That(records.BestTime(0), Is.EqualTo(result.Time));
            Assert.That(records.IsUnlocked(1), Is.True);

            run.Continue();
            Assert.That(run.Phase, Is.EqualTo(RunPhase.Playing));
            Assert.That(run.LevelIndex, Is.EqualTo(1));
            Assert.That(run.Score, Is.EqualTo(2 * Tuning.CoinPoints + expectedBonus), "the banked score carries over");
        }

        [Test]
        public void ClearingTheLastLevelIsVictoryWithALifeBonusAndRecords()
        {
            var run = new Run(records, TwoLevels(par: 1f));
            Walk(run, 4f);
            run.Continue();
            int lives = run.Lives;
            Walk(run, 4f);
            Assert.That(run.Phase, Is.EqualTo(RunPhase.Victory));
            Assert.That(run.LastResult.ExtraLife, Is.False, "no extra life after the last trial");
            Assert.That(run.Lives, Is.EqualTo(lives));
            Assert.That(run.LifeBonus, Is.EqualTo(lives * Tuning.LifeBonus));
            Assert.That(run.Score, Is.EqualTo(3 * Tuning.CoinPoints + run.LifeBonus), "no time bonus over par");
            Assert.That(run.NewBestScore, Is.True);
            Assert.That(run.NewBestRunTime, Is.True);
            Assert.That(records.BestScore, Is.EqualTo(run.Score));
            Assert.That(records.BestRunTime, Is.EqualTo(run.TotalTime));
        }

        [Test]
        public void RestartingALevelDropsItsPointsButKeepsTheBankedScoreAndLives()
        {
            var run = new Run(records, TwoLevels());
            Walk(run, 0.8f);
            Assert.That(run.Score, Is.EqualTo(2 * Tuning.CoinPoints));
            run.RestartLevel();
            Assert.That(run.Score, Is.EqualTo(0));
            Assert.That(run.Lives, Is.EqualTo(Tuning.StartingLives));
            Assert.That(run.Stage.Player.Feet, Is.EqualTo(run.Stage.Map.Start));
        }

        [Test]
        public void TheRealCampaignHasFourTrialsEndingWithTheStonePuma()
        {
            Assert.That(Levels.All.Count, Is.EqualTo(4));
            var last = new Stage(new LevelMap(Levels.All[3].Map));
            Assert.That(last.Boss, Is.Not.Null);
            for (int i = 0; i < 3; i++)
            {
                Assert.That(new Stage(new LevelMap(Levels.All[i].Map)).Boss, Is.Null);
            }
        }

        [Test]
        public void RestartingWhileDyingStillCostsTheLife()
        {
            var run = new Run(records, TwoLevels());
            run.Stage.Health.Kill();
            run.Tick(InputFrame.None, Sim.Dt);
            run.RestartLevel();
            Assert.That(run.Stage.Phase, Is.EqualTo(StagePhase.Dying), "a restart is ignored during the death beat");
            for (int i = 0; i < Sim.Seconds(Tuning.DyingTime) + 2; i++) run.Tick(InputFrame.None, Sim.Dt);
            Assert.That(run.Lives, Is.EqualTo(Tuning.StartingLives - 1));
        }
    }
}
