using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room62Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room62.Create();

        [Test]
        public void Library_KnowsRoom62()
        {
            Assert.IsTrue(RoomLibrary.Has("6-2"));
            Assert.IsTrue(RoomLibrary.TryCreate("6-2", out var room));
            Assert.AreEqual("The Missing WHERE", room.Title);
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room62.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(3, _room.CodeLines.Count);
            Assert.AreEqual("500", _room.Predict.Options[_room.Predict.CorrectIndex]);
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
        public void OriginalTrace_EveryRowChanges()
        {
            CollectionAssert.Contains(Play(_room.Trace).WatchLines().ToList(), "rows changed = 500");
        }

        [Test]
        public void BestFix_OnlyOneRowChanges()
        {
            var lines = Play(_room.Fixes[0].Consequence).WatchLines().ToList();

            CollectionAssert.Contains(lines, "rows changed = 1");
            CollectionAssert.Contains(lines, "result = reset for Thea only");
        }

        [Test]
        public void SymptomFix_LimitDoesNotPickThea()
        {
            CollectionAssert.Contains(Play(_room.Fixes[1].Consequence).WatchLines().ToList(), "result = any one row, maybe not Thea");
        }

        [Test]
        public void WrongFix_StillChangesAlmostEveryone()
        {
            CollectionAssert.Contains(Play(_room.Fixes[2].Consequence).WatchLines().ToList(), "rows changed = 499");
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
