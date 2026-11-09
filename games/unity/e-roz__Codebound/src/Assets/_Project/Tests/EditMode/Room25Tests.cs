using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room25Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room25.Create();

        [Test]
        public void Library_KnowsRoom25()
        {
            Assert.IsTrue(RoomLibrary.Has("2-5"));
            Assert.IsTrue(RoomLibrary.TryCreate("2-5", out var room));
            Assert.AreEqual("The Split Treasure", room.Title);
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room25.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(4, _room.CodeLines.Count);
            Assert.AreEqual(8, _room.Trace.Count);
            Assert.AreEqual("3", _room.Predict.Options[_room.Predict.CorrectIndex]);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.Verdict == Verdict.Close));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsFalse(_room.HasSupportCode);
            Assert.IsTrue(_room.CodeLines.All(l => l.Length <= 35));
            Assert.IsTrue(_room.Fixes.All(f => f.CodeLines.Count == 4 && f.CodeLines.All(l => l.Length <= 35)));
            Assert.IsTrue(_room.Trace.All(e => e.Line >= 1 && e.Line <= 4));
        }

        [Test]
        public void OriginalTrace_SevenDividedByTwoIsThree_ACoinVanishes()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual("3", state.Output);
            CollectionAssert.AreEqual(new[] { "coins = 7", "guards = 2", "share = 3" }, state.WatchLines().ToList());
        }

        [Test]
        public void TextSet_UpdatesInPlace_AndClearForgetsIt()
        {
            var state = new KeepState();
            state.Apply(TraceEvent.TextSet(1, "share", "3"));
            state.Apply(TraceEvent.TextSet(1, "share", "3.5"));

            Assert.AreEqual(1, state.ArrayVariables.Count);
            Assert.AreEqual("3.5", state.ArrayVariables[0].Contents);
            Assert.AreEqual("share is 3.5.", state.Caption);
            state.Clear();
            Assert.IsFalse(state.HasRows);
        }

        [Test]
        public void BestFix_DecimalKeepsTheHalf()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.AreEqual("3.5", state.Output);
            Assert.AreEqual("share = 3.5", state.WatchLines().Last());
        }

        [Test]
        public void SymptomFix_DoubleGivesTheSameOutput_ButIsTheWrongTypeForMoney()
        {
            Assert.AreEqual("3.5", Play(_room.Fixes[1].Consequence).Output);
            StringAssert.Contains("decimal", _room.Fixes[1].TestMessage);
        }

        [Test]
        public void WrongFix_PrintsFour()
        {
            Assert.AreEqual("4", Play(_room.Fixes[2].Consequence).Output);
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
