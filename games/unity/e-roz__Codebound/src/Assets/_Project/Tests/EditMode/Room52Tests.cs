using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room52Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room52.Create();

        [Test]
        public void Library_KnowsRoom52()
        {
            Assert.IsTrue(RoomLibrary.Has("5-2"));
            Assert.IsTrue(RoomLibrary.TryCreate("5-2", out var room));
            Assert.AreEqual("The Open Chest", room.Title);
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room52.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(5, _room.CodeLines.Count);
            Assert.AreEqual("-50", _room.Predict.Options[_room.Predict.CorrectIndex]);
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
        public void OriginalTrace_GoldGoesNegative()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual("-50", state.Output);
            CollectionAssert.AreEqual(new[] { "chest.Gold = -50" }, state.WatchLines().ToList());
        }

        [Test]
        public void BestFix_SpendIsRefused()
        {
            var lines = Play(_room.Fixes[0].Consequence).WatchLines().ToList();

            CollectionAssert.Contains(lines, "Spend(150) = refused, not enough Gold");
            CollectionAssert.Contains(lines, "chest.Gold = 100");
        }

        [Test]
        public void SymptomFix_OnlyThisCallIsGuarded()
        {
            Assert.AreEqual("100", Play(_room.Fixes[1].Consequence).Output);
        }

        [Test]
        public void WrongFix_PrintsZeroButGoldIsStillNegative()
        {
            var state = Play(_room.Fixes[2].Consequence);

            Assert.AreEqual("0", state.Output);
            CollectionAssert.Contains(state.WatchLines().ToList(), "chest.Gold = -50");
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
