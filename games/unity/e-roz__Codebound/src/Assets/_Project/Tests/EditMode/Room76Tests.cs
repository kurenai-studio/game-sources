using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room76Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room76.Create();

        [Test]
        public void Library_KnowsRoom76()
        {
            Assert.IsTrue(RoomLibrary.Has("7-6"));
            Assert.IsTrue(RoomLibrary.TryCreate("7-6", out var room));
            Assert.AreEqual("The Smallest Safe Change", room.Title);
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room76.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(4, _room.CodeLines.Count);
            Assert.AreEqual("3", _room.Predict.Options[_room.Predict.CorrectIndex]);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.Verdict == Verdict.Close));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsTrue(_room.CodeLines.All(l => l.Length <= 35));
            Assert.IsTrue(_room.Fixes.All(f => f.CodeLines.Count <= 8 && f.CodeLines.All(l => l.Length <= 35)));
            Assert.IsTrue(_room.Trace.All(e => e.Line >= 1 && e.Line <= _room.CodeLines.Count));
            Assert.IsTrue(_room.Fixes.All(f => f.Consequence.All(e => e.Line >= 1 && e.Line <= f.CodeLines.Count)));
        }

        [Test]
        public void OriginalTrace_AllThreeShareTheKey()
        {
            var lines = Play(_room.Trace).WatchLines().ToList();

            CollectionAssert.Contains(lines, "vaults sharing MASTER = 3");
        }

        [Test]
        public void BestFix_SmallChangeWithATest()
        {
            var lines = Play(_room.Fixes[0].Consequence).WatchLines().ToList();

            CollectionAssert.Contains(lines, "vaults sharing MASTER = 0");
            CollectionAssert.Contains(lines, "tests = 3 passed");
        }

        [Test]
        public void SymptomFix_VaultOneOnlyNoTest()
        {
            var lines = Play(_room.Fixes[1].Consequence).WatchLines().ToList();

            CollectionAssert.Contains(lines, "vaults sharing MASTER = 2");
            CollectionAssert.Contains(lines, "tests = none");
        }

        [Test]
        public void WrongFix_RewriteIsTooBig()
        {
            var lines = Play(_room.Fixes[2].Consequence).WatchLines().ToList();

            CollectionAssert.Contains(lines, "files changed = 40");
        }

        [Test]
        public void Ending_ShowsOnTheCompleteScreenWithTheName()
        {
            var state = new KeepState();
            var session = new RoomSession(_room);
            session.Trace.EventPlayed += state.Apply;
            var flow = new RoomFlow(session, state) { PlayerName = "Thea" };

            flow.Next();
            flow.Pick(2);
            session.Trace.RunToEnd();
            flow.Next();
            flow.Next();
            flow.Pick(2);
            flow.Pick(0);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();

            Assert.AreEqual(_room.Debrief, flow.Screen.Body);
            flow.Next();
            StringAssert.Contains("Thea", flow.Screen.Body);
            StringAssert.Contains("That's the job", flow.Screen.Body);
            Assert.AreEqual(RoomStep.Complete, session.Step);
        }

        [Test]
        public void Ending_IsOnlyInRoom76()
        {
            Assert.IsTrue(_room.HasEnding);
            StringAssert.Contains("{name}", _room.Ending);
            Assert.AreEqual(1, new[] { "7-1", "7-2", "7-3", "7-4", "7-5", "7-6" }.Count(id =>
                RoomLibrary.TryCreate(id, out var r) && r.HasEnding));
            Assert.IsFalse(Room75.Create().HasEnding);
        }

        [Test]
        public void Ending_WithoutAName_UsesApprentice()
        {
            var state = new KeepState();
            var session = new RoomSession(_room);
            session.Trace.EventPlayed += state.Apply;
            var flow = new RoomFlow(session, state);

            flow.Next();
            flow.Pick(2);
            session.Trace.RunToEnd();
            flow.Next();
            flow.Next();
            flow.Pick(2);
            flow.Pick(0);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();
            flow.Next();

            StringAssert.Contains("Apprentice", flow.Screen.Body);
            StringAssert.DoesNotContain("{name}", flow.Screen.Body);
            Assert.IsEmpty(flow.Screen.Notice);
            Assert.IsEmpty(flow.Screen.VerdictTitle);
        }

        [Test]
        public void PerfectRun_ThroughTheFlow_GivesThreeStars()
        {
            var state = new KeepState();
            var session = new RoomSession(_room);
            session.Trace.EventPlayed += state.Apply;
            var flow = new RoomFlow(session, state);

            flow.Next();
            flow.Pick(2);
            session.Trace.RunToEnd();
            flow.Next();
            flow.Next();
            flow.Pick(2);
            flow.Pick(0);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();
            flow.Next();

            Assert.AreEqual(3, session.Stars);
        }
    }
}
