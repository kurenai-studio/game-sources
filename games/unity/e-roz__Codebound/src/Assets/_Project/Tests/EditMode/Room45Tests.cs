using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room45Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room45.Create();

        [Test]
        public void Library_KnowsRoom45()
        {
            Assert.IsTrue(RoomLibrary.Has("4-5"));
            Assert.IsTrue(RoomLibrary.TryCreate("4-5", out var room));
            Assert.AreEqual("Searching the Whole Shelf", room.Title);
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room45.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(4, _room.CodeLines.Count);
            Assert.AreEqual("Up to 1000", _room.Predict.Options[_room.Predict.CorrectIndex]);
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
        public void OriginalTrace_ListScansAThousandItems()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual("True", state.Output);
            CollectionAssert.AreEqual(new[] { "found = true", "id = 999", "checks = 1000" }, state.WatchLines().ToList());
        }

        [Test]
        public void BestFix_HashSetNeedsOneCheck()
        {
            CollectionAssert.Contains(Play(_room.Fixes[0].Consequence).WatchLines().ToList(), "checks = 1");
        }

        [Test]
        public void SymptomFix_IsStillAScan()
        {
            CollectionAssert.Contains(Play(_room.Fixes[1].Consequence).WatchLines().ToList(), "checks = 1000");
        }

        [Test]
        public void WrongFix_SortingDoublesTheWork()
        {
            CollectionAssert.Contains(Play(_room.Fixes[2].Consequence).WatchLines().ToList(), "checks = 2000");
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
