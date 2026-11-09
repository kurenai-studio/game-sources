using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room31Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room31.Create();

        [Test]
        public void Library_KnowsRoom31()
        {
            Assert.IsTrue(RoomLibrary.Has("3-1"));
            Assert.IsTrue(RoomLibrary.TryCreate("3-1", out var room));
            Assert.AreEqual("The Healer Machine", room.Title);
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room31.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(7, _room.CodeLines.Count);
            Assert.AreEqual(7, _room.Trace.Count);
            Assert.AreEqual("50", _room.Predict.Options[_room.Predict.CorrectIndex]);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.Verdict == Verdict.Close));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsTrue(_room.CodeLines.Count <= 8 && _room.CodeLines.All(l => l.Length <= 35));
            Assert.IsTrue(_room.Fixes.All(f => f.CodeLines.Count <= 8 && f.CodeLines.All(l => l.Length <= 35)));
            Assert.IsTrue(_room.Trace.All(e => e.Line >= 1 && e.Line <= _room.CodeLines.Count));
            Assert.IsTrue(_room.Fixes.All(f => f.Consequence.All(e => e.Line >= 1 && e.Line <= f.CodeLines.Count)));
        }

        [Test]
        public void OriginalTrace_HealReturnsSeventy_ButHpStaysFifty()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual("50", state.Output);
            CollectionAssert.AreEqual(new[] { "hp = 50", "Heal(50) returns 70" }, state.WatchLines().ToList());
        }

        [Test]
        public void CallReturned_ShowsAsARow_AndClearForgetsIt()
        {
            var state = new KeepState();
            state.Apply(TraceEvent.CallReturned(1, "F(1)", "2"));

            Assert.IsTrue(state.HasRows);
            Assert.AreEqual("F(1) returns 2.", state.Caption);
            state.Clear();
            Assert.IsFalse(state.HasRows);
            Assert.AreEqual(0, state.Calls.Count);
        }

        [Test]
        public void BestFix_StoresTheResult()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.AreEqual("70", state.Output);
            Assert.AreEqual(70, state.NumberVariables.Single(v => v.Name == "hp").Value);
        }

        [Test]
        public void SymptomFix_PrintsSeventy_ButHpIsStillFifty()
        {
            var state = Play(_room.Fixes[1].Consequence);

            Assert.AreEqual("70", state.Output);
            Assert.AreEqual(50, state.NumberVariables.Single(v => v.Name == "hp").Value);
        }

        [Test]
        public void WrongFix_ResultStillThrownAway()
        {
            var state = Play(_room.Fixes[2].Consequence);

            Assert.AreEqual("50", state.Output);
            StringAssert.Contains("Heal(70) returns 90", string.Join("|", state.WatchLines()));
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
