using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room26Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room26.Create();

        [Test]
        public void Library_KnowsRoom26_AndNothingAfterIt()
        {
            Assert.IsTrue(RoomLibrary.Has("2-6"));
            Assert.IsTrue(RoomLibrary.TryCreate("2-6", out var room));
            Assert.AreEqual("The Visitor Form", room.Title);
            Assert.IsFalse(RoomLibrary.Has("9-1"));
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry_AsTheLastGateRoom()
        {
            var gates = KeepCatalogSeed.Create().First(c => c.id == "gates");
            Assert.AreEqual(Room26.Id, gates.rooms.Last().id);
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(3, _room.CodeLines.Count);
            Assert.AreEqual(4, _room.Trace.Count);
            Assert.AreEqual("It crashes with an error", _room.Predict.Options[_room.Predict.CorrectIndex]);
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
        public void OriginalTrace_ParseOfAbcCrashes()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual("FormatException", state.Error);
            Assert.AreEqual(string.Empty, state.Output);
            CollectionAssert.AreEqual(new[] { "t = \"abc\"" }, state.WatchLines().ToList());
        }

        [Test]
        public void BestFix_ChecksFirst_AndSaysInvalidAge()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.AreEqual("Bad age", state.Output);
            Assert.AreEqual(string.Empty, state.Error);
            Assert.AreEqual("step 1: TryParse(abc) = false", state.WatchLines().Last());
        }

        [Test]
        public void SymptomFix_NoCrash_ButAgeSilentlyBecomesZero()
        {
            var state = Play(_room.Fixes[1].Consequence);

            Assert.AreEqual("0", state.Output);
            Assert.AreEqual(string.Empty, state.Error);
            Assert.AreEqual(0, state.NumberVariables.Single(v => v.Name == "age").Value);
        }

        [Test]
        public void WrongFix_ConvertAlsoCrashes()
        {
            Assert.AreEqual("FormatException", Play(_room.Fixes[2].Consequence).Error);
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
