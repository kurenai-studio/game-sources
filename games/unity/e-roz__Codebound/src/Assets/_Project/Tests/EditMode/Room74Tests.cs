using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room74Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room74.Create();

        [Test]
        public void Library_KnowsRoom74()
        {
            Assert.IsTrue(RoomLibrary.Has("7-4"));
            Assert.IsTrue(RoomLibrary.TryCreate("7-4", out var room));
            Assert.AreEqual("The Flaky Guard Test", room.Title);
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room74.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(6, _room.CodeLines.Count);
            Assert.AreEqual("Fails", _room.Predict.Options[_room.Predict.CorrectIndex]);
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
        public void OriginalTrace_FailsAtNightPassesInTheMorning()
        {
            var lines = Play(_room.Trace).WatchLines().ToList();

            CollectionAssert.Contains(lines, "h = 23");
            CollectionAssert.Contains(lines, "test = failed");
            CollectionAssert.Contains(lines, "rerun at 09:00 = passed");
        }

        [Test]
        public void BestFix_TestChoosesTheHour()
        {
            var lines = Play(_room.Fixes[0].Consequence).WatchLines().ToList();

            CollectionAssert.Contains(lines, "NightShift(12) = false");
            CollectionAssert.Contains(lines, "NightShift(23) = true");
            CollectionAssert.Contains(lines, "test = passed at any time");
        }

        [Test]
        public void SymptomFix_NightRunStillFails()
        {
            var lines = Play(_room.Fixes[1].Consequence).WatchLines().ToList();

            CollectionAssert.Contains(lines, "at night = still fails if someone runs it");
        }

        [Test]
        public void WrongFix_RetryDoesNotChangeTheClock()
        {
            var lines = Play(_room.Fixes[2].Consequence).WatchLines().ToList();

            CollectionAssert.Contains(lines, "test = still fails at night");
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
