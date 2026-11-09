using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room12Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room12.Create();

        [Test]
        public void Library_KnowsBothRooms()
        {
            Assert.IsTrue(RoomLibrary.Has("1-2"));
            Assert.IsTrue(RoomLibrary.TryCreate("1-2", out var room));
            Assert.AreEqual("Copy That", room.Title);
            Assert.IsFalse(RoomLibrary.Has("1-7"));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(4, _room.CodeLines.Count);
            Assert.AreEqual(10, _room.Trace.Count);
            Assert.AreEqual("5", _room.Predict.Options[_room.Predict.CorrectIndex]);
            Assert.AreEqual(3, _room.Hypotheses.Count);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsFalse(_room.HasSupportCode);
            Assert.IsTrue(_room.Trace.All(e => e.Line >= 1 && e.Line <= 4));
        }

        [Test]
        public void OriginalTrace_PouchesAreSeparate()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual(5, state.Guards[0].Value);
            Assert.AreEqual(8, state.Guards[1].Value);
            Assert.AreEqual("5", state.Output);
            Assert.AreEqual(0, state.Chests.Count);
            CollectionAssert.AreEqual(new[] { "coinsA = 5", "coinsB = 8" }, state.WatchLines().ToList());
        }

        [Test]
        public void BestFix_MakesCoinsAEight()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.AreEqual(8, state.Guards[0].Value);
            Assert.AreEqual("8", state.Output);
        }

        [Test]
        public void SymptomFix_PrintsEightButCoinsAStaysFive()
        {
            var state = Play(_room.Fixes[1].Consequence);

            Assert.AreEqual("8", state.Output);
            Assert.AreEqual(5, state.Guards[0].Value);
        }

        [Test]
        public void WrongFix_LeavesCoinsAAtFive()
        {
            var state = Play(_room.Fixes[2].Consequence);

            Assert.AreEqual(5, state.Guards[0].Value);
            Assert.AreEqual(3, state.Guards[1].Value);
        }

        [Test]
        public void Room11Words_AreUnchanged()
        {
            var flow = new RoomFlow(new RoomSession(Room11.Create()), new KeepState());
            var room = Room11.Create();

            Assert.AreEqual("Investigate: which chest does each guard point to?", room.InvestigatePrompt);
            Assert.AreEqual("Why does Vault B have a sword?", room.HypothesisPrompt);
            Assert.IsTrue(room.HasSupportCode);
            Assert.IsNotNull(flow.Screen);
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
            StringAssert.Contains("coinsA = 5", flow.Screen.Body);
            Assert.AreEqual("Investigate: what does each guard hold?", flow.Screen.Prompt);
            flow.Next();
            Assert.AreEqual("Why does Guard A still have 5?", flow.Screen.Prompt);
            flow.Pick(2);
            StringAssert.Contains("Guard A ends with 8 coins.", flow.Screen.Prompt);
            flow.Pick(0);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();
            flow.Next();

            Assert.AreEqual(3, session.Stars);
        }
    }
}
