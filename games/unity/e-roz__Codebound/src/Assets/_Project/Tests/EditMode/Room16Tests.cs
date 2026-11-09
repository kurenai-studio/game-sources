using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room16Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room16.Create();

        [Test]
        public void Library_KnowsRoom16()
        {
            Assert.IsTrue(RoomLibrary.Has("1-6"));
            Assert.IsTrue(RoomLibrary.TryCreate("1-6", out var room));
            Assert.AreEqual("Who Changed My Guard?", room.Title);
            Assert.IsFalse(RoomLibrary.Has("1-7"));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(4, _room.CodeLines.Count);
            Assert.AreEqual(17, _room.Trace.Count);
            Assert.AreEqual("1", _room.Predict.Options[_room.Predict.CorrectIndex]);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.Verdict == Verdict.Close));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsTrue(_room.HasSupportCode);
            StringAssert.Contains("void Reset(Chest c)", _room.SupportCode);
            Assert.IsTrue(_room.Trace.All(e => e.Line >= 1 && e.Line <= 4));
        }

        [Test]
        public void ScopeEnded_RemovesTheHelperGuard()
        {
            var state = new KeepState();
            foreach (var e in _room.Trace.Take(8)) state.Apply(e);
            Assert.AreEqual(2, state.Guards.Count);
            Assert.AreEqual("c", state.Guards[1].Name);

            state.Apply(_room.Trace[8]);

            Assert.AreEqual(1, state.Guards.Count);
            Assert.AreEqual("vault", state.Guards[0].Name);
            StringAssert.Contains("c goes away", state.Caption);
        }

        [Test]
        public void ScopeEnded_ForAnUnknownVariable_DoesNothing()
        {
            var state = Play(_room.Trace.Take(4).ToList());

            state.Apply(TraceEvent.ScopeEnded(1, "nobody"));

            Assert.AreEqual(1, state.Guards.Count);
        }

        [Test]
        public void OriginalTrace_VaultStillPointsToTheFullChest_AndChestTwoIsOrphaned()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual(1, state.Guards.Count);
            Assert.AreEqual(1, state.Guards[0].ObjectId);
            Assert.AreEqual(2, state.Chests.Count);
            CollectionAssert.AreEqual(new[] { "Gem" }, state.Chests[0].Items.ToList());
            Assert.AreEqual(0, state.Chests[1].ItemCount);
            Assert.AreEqual("1", state.Output);
            CollectionAssert.AreEqual(new[] { "vault -> chest #1" }, state.WatchLines().ToList());
        }

        [Test]
        public void HelperGuard_PointsToTheNewChest_WhileResetRuns()
        {
            var state = Play(_room.Trace.Take(14).ToList());

            Assert.AreEqual("c", state.Guards[1].Name);
            Assert.AreEqual(2, state.Guards[1].ObjectId);
            Assert.AreEqual(1, state.Guards[0].ObjectId);
        }

        [Test]
        public void BestFix_VaultPointsToTheNewEmptyChest()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.AreEqual(2, state.Guards[0].ObjectId);
            Assert.AreEqual(0, state.Chests[1].ItemCount);
            Assert.AreEqual("0", state.Output);
        }

        [Test]
        public void SymptomAndWrongFixes_ShowTheirOwnOutput()
        {
            Assert.AreEqual(1, Play(_room.Fixes[1].Consequence).Guards[0].ObjectId);
            Assert.AreEqual("0", Play(_room.Fixes[1].Consequence).Output);
            Assert.AreEqual(2, Play(_room.Fixes[2].Consequence).Chests[0].ItemCount);
        }

        [Test]
        public void PerfectRun_ThroughTheFlow_GivesThreeStars()
        {
            var state = new KeepState();
            var session = new RoomSession(_room);
            session.Trace.EventPlayed += state.Apply;
            var flow = new RoomFlow(session, state);

            flow.Next();
            flow.Pick(1);
            session.Trace.RunToEnd();
            flow.Next();
            StringAssert.Contains("vault -> chest #1", flow.Screen.Body);
            Assert.AreEqual("Investigate: which chest does vault point to?", flow.Screen.Prompt);
            flow.Next();
            Assert.AreEqual("Why is the vault not empty?", flow.Screen.Prompt);
            flow.Pick(2);
            StringAssert.Contains("After line 3, the vault is empty.", flow.Screen.Prompt);
            flow.Pick(0);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();
            flow.Next();

            Assert.AreEqual(3, session.Stars);
        }
    }
}
