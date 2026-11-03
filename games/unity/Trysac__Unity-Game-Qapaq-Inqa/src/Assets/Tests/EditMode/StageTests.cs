using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;
using QapaqInqa.Core;

namespace QapaqInqa.Core.Tests
{
    public class StageTests
    {
        readonly List<StageEvent> seen = new List<StageEvent>();

        Stage Make(params string[] rows) => new Stage(Sim.Map(rows));

        /// <summary>Steps and remembers every event, since <see cref="Stage.Events"/> only holds the last step's.</summary>
        void Play(Stage stage, InputFrame input, int frames)
        {
            for (int i = 0; i < frames; i++)
            {
                stage.Step(input, Sim.Dt);
                seen.AddRange(stage.Events);
            }
        }

        int Count(StageEventKind kind) => seen.Count(e => e.Kind == kind);

        [SetUp]
        public void Clear() => seen.Clear();

        [Test]
        public void CoinsScoreOnceAndAreCounted()
        {
            Stage stage = Make(Sim.Flat(40, "  o o"));
            Play(stage, Sim.Hold(x: 1f), Sim.Seconds(1.5f));
            Assert.That(stage.CoinsFound, Is.EqualTo(2));
            Assert.That(stage.Points, Is.EqualTo(2 * Tuning.CoinPoints));
            Assert.That(Count(StageEventKind.Coin), Is.EqualTo(2));
            Assert.That(stage.Pickups.All(p => p.Taken), Is.True);
            Play(stage, Sim.Hold(x: -1f), Sim.Seconds(1.5f));
            Assert.That(stage.Points, Is.EqualTo(2 * Tuning.CoinPoints), "walking back over them pays nothing");
        }

        [Test]
        public void TheSunGateOpensOnlyOnceEveryIdolIsFound()
        {
            Stage stage = Make(
                "                ",
                "                ",
                "                ",
                "                ",
                "A P         E   ",
                "################");
            Assert.That(stage.ArtifactsTotal, Is.EqualTo(1));
            Assert.That(stage.GateOpen, Is.False);
            Play(stage, Sim.Hold(x: 1f), Sim.Seconds(2.5f));
            Assert.That(stage.Phase, Is.EqualTo(StagePhase.Playing), "a closed gate is just a wall painting");
            Assert.That(stage.Player.X, Is.GreaterThan(stage.GateBounds.Right));

            Play(stage, Sim.Hold(x: -1f), Sim.Seconds(2.5f));
            Assert.That(stage.ArtifactsFound, Is.EqualTo(1));
            Assert.That(stage.GateOpen, Is.True);
            Assert.That(Count(StageEventKind.GateOpened), Is.EqualTo(1));
            Assert.That(stage.Points, Is.EqualTo(Tuning.ArtifactPoints));

            Play(stage, Sim.Hold(x: 1f), Sim.Seconds(2.2f));
            Assert.That(stage.Phase, Is.EqualTo(StagePhase.Cleared));
            Assert.That(Count(StageEventKind.Cleared), Is.EqualTo(1));
        }

        [Test]
        public void SpikesHurtThrowThePlayerUpAndMercyTimeStopsASecondHit()
        {
            Stage stage = Make(Sim.Flat(40, "   ^^^^^^^^"));
            Play(stage, Sim.Hold(x: 1f), Sim.Seconds(0.6f));
            Assert.That(stage.Health.Hearts, Is.EqualTo(Tuning.MaxHearts - 1));
            Assert.That(Count(StageEventKind.Hurt), Is.EqualTo(1));
            Assert.That(stage.Health.Invulnerable, Is.GreaterThan(0f));
        }

        [Test]
        public void TouchingAWalkerHurtsOneHeart()
        {
            Stage stage = Make(Sim.Flat(40, "     w"));
            Play(stage, Sim.Hold(x: 1f), Sim.Seconds(0.8f));
            Assert.That(stage.Health.Hearts, Is.EqualTo(Tuning.MaxHearts - 1));
            Assert.That(stage.Enemies[0].Alive, Is.True);
        }

        [Test]
        public void StompingAWalkerDefeatsItAndBounces()
        {
            Stage stage = Make(
                "          ",
                "     P    ",
                "          ",
                "          ",
                "    #w# E ",
                "##########");
            Play(stage, InputFrame.None, Sim.Seconds(0.6f));
            Assert.That(stage.Enemies[0].Alive, Is.False);
            Assert.That(Count(StageEventKind.Stomp), Is.EqualTo(1));
            Assert.That(Count(StageEventKind.EnemyDefeated), Is.EqualTo(1));
            Assert.That(stage.Health.Hearts, Is.EqualTo(Tuning.MaxHearts), "a stomp does not hurt");
            Assert.That(stage.Points, Is.EqualTo(Tuning.StompBonus + Tuning.WalkerPoints));
        }

        [Test]
        public void TwoArrowsDefeatAWalkerAndEachArrowHitsOnce()
        {
            Stage stage = Make(Sim.Flat(40, "            w"));
            Play(stage, Sim.Hold(fire: true), 1);
            Assert.That(stage.Arrows.Count, Is.EqualTo(1));
            Assert.That(Count(StageEventKind.Shoot), Is.EqualTo(1));
            Play(stage, InputFrame.None, Sim.Seconds(1f));
            Assert.That(stage.Enemies[0].HealthLeft, Is.EqualTo(Tuning.WalkerHealth - 1));
            Assert.That(Count(StageEventKind.EnemyHit), Is.EqualTo(1));
            Assert.That(stage.Arrows.Count, Is.EqualTo(0));

            Play(stage, Sim.Hold(fire: true), 1);
            Play(stage, InputFrame.None, Sim.Seconds(1f));
            Assert.That(stage.Enemies[0].Alive, Is.False);
            Assert.That(Count(StageEventKind.EnemyDefeated), Is.EqualTo(1));
            Assert.That(stage.Points, Is.EqualTo(Tuning.WalkerPoints));
        }

        [Test]
        public void HoldingFireShootsAtTheCooldownRate()
        {
            Stage stage = Make(Sim.Flat(60));
            Play(stage, Sim.Hold(fire: true), Sim.Seconds(1f) + 1);
            Assert.That(Count(StageEventKind.Shoot), Is.EqualTo(4), "at 0, 1/3, 2/3 and 1 second");
        }

        [Test]
        public void ArrowsBreakOnStone()
        {
            Stage stage = Make(
                "          ",
                "          ",
                " P   # E  ",
                "##########");
            Play(stage, Sim.Hold(fire: true), 1);
            Play(stage, InputFrame.None, 30);
            Assert.That(stage.Arrows.Count, Is.EqualTo(0));
            Assert.That(Count(StageEventKind.ArrowBroke), Is.EqualTo(1));
        }

        [Test]
        public void WalkersTurnAtTheEdgeOfTheirLedge()
        {
            Stage stage = Make(
                "            ",
                "  P       E ",
                "            ",
                "     w      ",
                "   #####    ",
                "############");
            Enemy walker = stage.Enemies[0];
            float min = walker.X, max = walker.X;
            for (int i = 0; i < Sim.Seconds(6f); i++)
            {
                stage.Step(InputFrame.None, Sim.Dt);
                min = System.Math.Min(min, walker.X);
                max = System.Math.Max(max, walker.X);
            }
            Assert.That(min, Is.GreaterThanOrEqualTo(3f));
            Assert.That(max, Is.LessThanOrEqualTo(8f));
            Assert.That(max - min, Is.GreaterThan(3f), "it paces the whole ledge");
            Assert.That(walker.Y, Is.EqualTo(2f));
        }

        [Test]
        public void FallingIntoAPitLosesAllHearts()
        {
            Stage stage = Make(
                "            ",
                "            ",
                " P        E ",
                "###      ###");
            Play(stage, Sim.Hold(x: 1f), Sim.Seconds(1.5f));
            Assert.That(stage.Phase, Is.EqualTo(StagePhase.Dying));
            Assert.That(stage.Health.IsDead, Is.True);
            Assert.That(stage.Deaths, Is.EqualTo(1));
            Assert.That(Count(StageEventKind.Died), Is.EqualTo(1));
        }

        [Test]
        public void ACheckpointBecomesTheRespawnPointWithFullHearts()
        {
            Stage stage = Make(Sim.Flat(40, "    C    ^"));
            Play(stage, Sim.Hold(x: 1f), Sim.Seconds(0.8f));
            Assert.That(stage.RespawnPoint, Is.EqualTo(new Vec2(6.5f, 1f)));
            Assert.That(Count(StageEventKind.Checkpoint), Is.EqualTo(1));

            stage.Health.Kill();
            Play(stage, InputFrame.None, 1);
            Assert.That(stage.Phase, Is.EqualTo(StagePhase.Dying));
            stage.Respawn();
            Assert.That(stage.Phase, Is.EqualTo(StagePhase.Playing));
            Assert.That(stage.Player.Feet, Is.EqualTo(new Vec2(6.5f, 1f)));
            Assert.That(stage.Health.Hearts, Is.EqualTo(Tuning.MaxHearts));
        }

        /// <summary>
        /// The original game reloaded the scene after a death but kept the score, so every coin,
        /// gem and artifact came back and could be collected again for more points.
        /// </summary>
        [Test]
        public void PickupsTakenBeforeDyingStayTakenAfterRespawn()
        {
            Stage stage = Make(Sim.Flat(40, "  o A"));
            Play(stage, Sim.Hold(x: 1f), Sim.Seconds(0.8f));
            Assert.That(stage.Points, Is.EqualTo(Tuning.CoinPoints + Tuning.ArtifactPoints));

            stage.Health.Kill();
            Play(stage, InputFrame.None, 1);
            stage.Respawn();
            Play(stage, Sim.Hold(x: 1f), Sim.Seconds(0.8f));
            Assert.That(stage.Points, Is.EqualTo(Tuning.CoinPoints + Tuning.ArtifactPoints), "no points for collecting twice");
            Assert.That(stage.CoinsFound, Is.EqualTo(1));
            Assert.That(stage.ArtifactsFound, Is.EqualTo(1));
            Assert.That(stage.GateOpen, Is.True);
        }

        [Test]
        public void HeartsHealOrPayPointsWhenFull()
        {
            Stage stage = Make(Sim.Flat(40, "  + +"));
            stage.Health.TryHurt(1);
            Play(stage, Sim.Hold(x: 1f), Sim.Seconds(1f));
            Assert.That(stage.Health.Hearts, Is.EqualTo(Tuning.MaxHearts));
            Assert.That(stage.Points, Is.EqualTo(Tuning.SpareHeartPoints), "the second heart found full health");
            Assert.That(Count(StageEventKind.Heart), Is.EqualTo(2));
        }

        static string[] Court() => new[]
        {
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            " P               B        E     ",
            "################################",
        };

        [Test]
        public void TheStonePumaSleepsUntilThePlayerComesCloseThenThrowsRocks()
        {
            Stage stage = Make(Court());
            stage.Invincible = true;
            Play(stage, InputFrame.None, 30);
            Assert.That(stage.Boss.Move, Is.EqualTo(BossMove.Dormant));
            Assert.That(stage.GateOpen, Is.False, "the gate stays shut while the guardian lives");

            stage.PlacePlayer(new Vec2(9.5f, 1f));
            Play(stage, InputFrame.None, Sim.Seconds(6f));
            Assert.That(Count(StageEventKind.BossWoke), Is.EqualTo(1));
            Assert.That(Count(StageEventKind.BossSlam), Is.GreaterThanOrEqualTo(1));
            Assert.That(Count(StageEventKind.BossThrow), Is.GreaterThanOrEqualTo(3));
        }

        [Test]
        public void RocksAndTheBossHurtThePlayer()
        {
            Stage stage = Make(Court());
            stage.PlacePlayer(new Vec2(9.5f, 1f));
            Play(stage, InputFrame.None, Sim.Seconds(5f));
            Assert.That(Count(StageEventKind.Hurt), Is.GreaterThanOrEqualTo(1));
            Assert.That(stage.Health.Hearts, Is.LessThan(Tuning.MaxHearts));
        }

        [Test]
        public void DefeatingTheStonePumaOpensTheGate()
        {
            Stage stage = Make(Court());
            stage.Invincible = true;
            int frames = 0;
            while (stage.Boss.Alive && frames++ < Sim.Seconds(40f))
            {
                float toBoss = stage.Boss.X - stage.Player.X;
                stage.Step(new InputFrame(toBoss > 0f ? 0.25f : -0.25f, 0f, false, false, true), Sim.Dt);
                seen.AddRange(stage.Events);
            }
            Assert.That(stage.Boss.Alive, Is.False);
            Assert.That(stage.Boss.Move, Is.EqualTo(BossMove.Defeated));
            Assert.That(Count(StageEventKind.BossDefeated), Is.EqualTo(1));
            Assert.That(stage.GateOpen, Is.True);
            Assert.That(stage.Rocks.Count, Is.EqualTo(0));
            Assert.That(stage.Points, Is.GreaterThanOrEqualTo(Tuning.BossPoints));
        }

        [Test]
        public void LosingALifeMidFightPutsTheBossBackToSleepAtFullHealth()
        {
            Stage stage = Make(Court());
            stage.Boss.Hurt(5);
            Assert.That(stage.Boss.Move, Is.EqualTo(BossMove.Prowl), "a hit wakes it");
            stage.Health.Kill();
            Play(stage, InputFrame.None, 1);
            stage.Respawn();
            Assert.That(stage.Boss.HealthLeft, Is.EqualTo(Tuning.BossHealth));
            Assert.That(stage.Boss.Move, Is.EqualTo(BossMove.Dormant));
        }

        [Test]
        public void TheTimerOnlyRunsWhilePlaying()
        {
            Stage stage = Make(Sim.Flat());
            Play(stage, InputFrame.None, 60);
            Assert.That(stage.Elapsed, Is.EqualTo(1f).Within(0.001f));
            stage.Health.Kill();
            Play(stage, InputFrame.None, 60);
            Assert.That(stage.Elapsed, Is.EqualTo(1f + Sim.Dt).Within(0.001f));
        }

        static string[] BossCourt() => new[]
        {
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            " P   A           B        E     ",
            "################################",
        };

        [Test]
        public void ADefeatedBossStaysDefeatedAfterARespawn()
        {
            Stage stage = Make(BossCourt());
            stage.Strike(stage.Boss, Tuning.BossHealth);
            int pointsAfterKill = stage.Points;
            stage.Health.Kill();
            Play(stage, InputFrame.None, 1);
            stage.Respawn();
            Assert.That(stage.Boss.Alive, Is.False, "the defeated boss must not come back");
            stage.Strike(stage.Boss, Tuning.BossHealth);
            Assert.That(stage.Points, Is.EqualTo(pointsAfterKill), "the boss points are paid once");
        }

        [Test]
        public void TheLastIdolOpensTheGateWhenTheBossFellBeforeARespawn()
        {
            Stage stage = Make(BossCourt());
            stage.Strike(stage.Boss, Tuning.BossHealth);
            stage.Health.Kill();
            Play(stage, InputFrame.None, 1);
            stage.Respawn();
            stage.PlacePlayer(new Vec2(5.5f, 1f));
            Play(stage, InputFrame.None, 2);
            Assert.That(stage.ArtifactsFound, Is.EqualTo(stage.ArtifactsTotal));
            Assert.That(stage.GateOpen, Is.True);
        }
    }
}
