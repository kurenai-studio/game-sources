using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room24Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room24.Create();

        [Test]
        public void Library_KnowsRoom24()
        {
            Assert.IsTrue(RoomLibrary.Has("2-4"));
            Assert.IsTrue(RoomLibrary.TryCreate("2-4", out var room));
            Assert.AreEqual("The Toll Boundary", room.Title);
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room24.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(3, _room.CodeLines.Count);
            Assert.AreEqual(7, _room.Trace.Count);
            Assert.AreEqual("False", _room.Predict.Options[_room.Predict.CorrectIndex]);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.Verdict == Verdict.Close));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsFalse(_room.HasSupportCode);
            Assert.IsTrue(_room.CodeLines.All(l => l.Length <= 35));
            Assert.IsTrue(_room.Fixes.All(f => f.CodeLines.Count <= 5 && f.CodeLines.All(l => l.Length <= 35)));
            Assert.IsTrue(_room.Fixes.All(f => f.Consequence.All(e => e.Line >= 1 && e.Line <= f.CodeLines.Count)));
        }

        [Test]
        public void OriginalTrace_HundredIsNotMoreThanHundred_SoItPrintsFalse()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual("False", state.Output);
            CollectionAssert.AreEqual(new[] { "discount = false", "total = 100", "step 1: 100 > 100 = false" },
                state.WatchLines().ToList());
        }

        [Test]
        public void BestFix_GivesTheDiscountAtExactlyHundred()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.AreEqual("True", state.Output);
            Assert.AreEqual("step 1: 100 >= 100 = true", state.WatchLines().Last());
        }

        [Test]
        public void SymptomFix_AlwaysTrue_HasNoCheck()
        {
            var state = Play(_room.Fixes[1].Consequence);

            Assert.AreEqual("True", state.Output);
            CollectionAssert.AreEqual(new[] { "discount = true", "total = 100" }, state.WatchLines().ToList());
        }

        [Test]
        public void WrongFix_StillNoDiscountAtHundred()
        {
            Assert.AreEqual("False", Play(_room.Fixes[2].Consequence).Output);
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
