using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room21Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room21.Create();

        [Test]
        public void Library_KnowsRoom21()
        {
            Assert.IsTrue(RoomLibrary.Has("2-1"));
            Assert.IsTrue(RoomLibrary.TryCreate("2-1", out var room));
            Assert.AreEqual("The Gate Rules", room.Title);
            Assert.IsFalse(RoomLibrary.Has("9-1"));
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room21.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(5, _room.CodeLines.Count);
            Assert.AreEqual(12, _room.Trace.Count);
            Assert.AreEqual("True", _room.Predict.Options[_room.Predict.CorrectIndex]);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.Verdict == Verdict.Close));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsFalse(_room.HasSupportCode);
            Assert.IsTrue(_room.Fixes.All(f => f.CodeLines.Count == 5));
            Assert.IsTrue(_room.Trace.All(e => e.Line >= 1 && e.Line <= 5));
        }

        [Test]
        public void OriginalTrace_AndGoesFirst_ThenOr()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual(0, state.Guards.Count);
            Assert.AreEqual(4, state.BoolVariables.Count);
            Assert.IsTrue(state.BoolVariables.First(v => v.Name == "ok").Value);
            Assert.AreEqual("guest && pass", state.Steps[0].Expression);
            Assert.IsFalse(state.Steps[0].Result);
            Assert.AreEqual("member || false", state.Steps[1].Expression);
            Assert.IsTrue(state.Steps[1].Result);
            Assert.AreEqual("True", state.Output);
        }

        [Test]
        public void WatchList_ListsVariablesThenTheStepsInOrder()
        {
            CollectionAssert.AreEqual(new[]
            {
                "member = true", "guest = false", "pass = false", "ok = true",
                "step 1: guest && pass = false", "step 2: member || false = true"
            }, Play(_room.Trace).WatchLines().ToList());
        }

        [Test]
        public void BoolSet_UpdatesAnExistingVariable_InsteadOfAddingAnother()
        {
            var state = new KeepState();
            state.Apply(TraceEvent.BoolSet(1, "x", true));

            state.Apply(TraceEvent.BoolSet(2, "x", false));

            Assert.AreEqual(1, state.BoolVariables.Count);
            Assert.IsFalse(state.BoolVariables[0].Value);
            StringAssert.Contains("x is false", state.Caption);
        }

        [Test]
        public void Clear_ForgetsVariablesAndSteps()
        {
            var state = Play(_room.Trace);

            state.Clear();

            Assert.AreEqual(0, state.BoolVariables.Count);
            Assert.AreEqual(0, state.Steps.Count);
            Assert.AreEqual(0, state.WatchLines().Count);
        }

        [Test]
        public void BestFix_ParenthesesMakeTheMemberStayOut()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.IsFalse(state.BoolVariables.First(v => v.Name == "ok").Value);
            Assert.AreEqual("False", state.Output);
            Assert.AreEqual("member || guest", state.Steps[0].Expression);
        }

        [Test]
        public void SymptomFix_ChangesTheVisitor_NotTheRule()
        {
            var state = Play(_room.Fixes[1].Consequence);

            Assert.IsFalse(state.BoolVariables.First(v => v.Name == "member").Value);
            Assert.AreEqual("False", state.Output);
            StringAssert.Contains("member || guest && pass", _room.Fixes[1].CodeLines[3]);
        }

        [Test]
        public void WrongFix_LetsEveryoneIn()
        {
            Assert.AreEqual("True", Play(_room.Fixes[2].Consequence).Output);
        }

        [Test]
        public void PerfectRun_ThroughTheFlow_GivesThreeStars()
        {
            var state = new KeepState();
            var session = new RoomSession(_room);
            session.Trace.EventPlayed += state.Apply;
            var flow = new RoomFlow(session, state);

            flow.Next();
            flow.Pick(0);
            session.Trace.RunToEnd();
            flow.Next();
            StringAssert.Contains("step 1: guest && pass = false", flow.Screen.Body);
            Assert.AreEqual("Investigate: which part of line 4 runs first?", flow.Screen.Prompt);
            flow.Next();
            Assert.AreEqual("Why did the member get in?", flow.Screen.Prompt);
            flow.Pick(2);
            StringAssert.Contains("Everyone needs a pass.", flow.Screen.Prompt);
            flow.Pick(0);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();
            flow.Next();

            Assert.AreEqual(3, session.Stars);
        }
    }
}
