using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room43Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room43.Create();

        [Test]
        public void Library_KnowsRoom43()
        {
            Assert.IsTrue(RoomLibrary.Has("4-3"));
            Assert.IsTrue(RoomLibrary.TryCreate("4-3", out var room));
            Assert.AreEqual("The Missing Key", room.Title);
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room43.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(4, _room.CodeLines.Count);
            Assert.AreEqual("It throws an error", _room.Predict.Options[_room.Predict.CorrectIndex]);
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
        public void OriginalTrace_MissingKeyThrows()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual("KeyNotFoundException", state.Error);
            CollectionAssert.AreEqual(new[] { "shop = {Sword: 10, Shield: 20}", "key = Potion" }, state.WatchLines().ToList());
        }

        [Test]
        public void BestFix_ChecksFirstAndPrintsNoPotion()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.AreEqual("No Potion", state.Output);
            Assert.AreEqual(string.Empty, state.Error);
        }

        [Test]
        public void SymptomFix_HidesTheErrorAndPrintsZero()
        {
            var state = Play(_room.Fixes[1].Consequence);

            Assert.AreEqual("0", state.Output);
            Assert.AreEqual(string.Empty, state.Error);
            CollectionAssert.Contains(state.WatchLines().ToList(), "shop[key] = throws KeyNotFoundException");
        }

        [Test]
        public void WrongFix_StillThrows()
        {
            Assert.AreEqual("KeyNotFoundException", Play(_room.Fixes[2].Consequence).Error);
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
