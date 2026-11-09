using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room22Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room22.Create();

        [Test]
        public void Library_KnowsRoom22()
        {
            Assert.IsTrue(RoomLibrary.Has("2-2"));
            Assert.IsTrue(RoomLibrary.TryCreate("2-2", out var room));
            Assert.AreEqual("The Last Guard", room.Title);
            Assert.IsFalse(RoomLibrary.Has("9-1"));
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room22.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(4, _room.CodeLines.Count);
            Assert.AreEqual(21, _room.Trace.Count);
            Assert.AreEqual("3 names, then a crash", _room.Predict.Options[_room.Predict.CorrectIndex]);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.Verdict == Verdict.Close));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsFalse(_room.HasSupportCode);
            Assert.IsTrue(_room.Fixes.All(f => f.CodeLines.Count == 4));
            Assert.IsTrue(_room.CodeLines.All(l => l.Length <= 35));
            Assert.IsTrue(_room.Fixes.All(f => f.CodeLines.All(l => l.Length <= 35)));
            Assert.IsTrue(_room.Trace.All(e => e.Line >= 1 && e.Line <= 4));
        }

        [Test]
        public void OriginalTrace_PrintsThreeNames_ThenCrashesWhenIReachesThree()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual("Thea, Jean, Coco", state.Output);
            Assert.AreEqual("IndexOutOfRangeException", state.Error);
            Assert.AreEqual(3, state.NumberVariables.First(v => v.Name == "i").Value);
            Assert.AreEqual(3, state.NumberVariables.First(v => v.Name == "n").Value);
            Assert.IsTrue(state.HasRows);
            Assert.AreEqual(0, state.Guards.Count);
        }

        [Test]
        public void WatchList_ShowsTheArrayThenTheNumbersThenTheLastCheck()
        {
            CollectionAssert.AreEqual(new[]
            {
                "g = [Thea, Jean, Coco] (slots 0 to 2)", "n = 3", "i = 3", "step 1: 3 <= 3 = true"
            }, Play(_room.Trace).WatchLines().ToList());
        }

        [Test]
        public void OutputAppended_KeepsEveryPrintedItem()
        {
            var state = new KeepState();
            state.Apply(TraceEvent.OutputAppended(4, "Thea"));
            state.Apply(TraceEvent.OutputAppended(4, "Jean"));

            Assert.AreEqual("Thea, Jean", state.Output);
            state.Clear();
            Assert.AreEqual(string.Empty, state.Output);
        }

        [Test]
        public void IntSetAndArraySet_UpdateInPlace_AndClearForgetsThem()
        {
            var state = new KeepState();
            state.Apply(TraceEvent.IntSet(1, "i", 0));
            state.Apply(TraceEvent.IntSet(1, "i", 1));
            state.Apply(TraceEvent.ArraySet(1, "g", "[A]"));
            state.Apply(TraceEvent.ArraySet(1, "g", "[A, B]"));

            Assert.AreEqual(1, state.NumberVariables.Count);
            Assert.AreEqual(1, state.NumberVariables[0].Value);
            Assert.AreEqual("[A, B]", state.ArrayVariables[0].Contents);

            state.Clear();
            Assert.AreEqual(0, state.NumberVariables.Count);
            Assert.AreEqual(0, state.ArrayVariables.Count);
            Assert.IsFalse(state.HasRows);
        }

        [Test]
        public void BestFix_PrintsAllThree_WithoutACrash()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.AreEqual("Thea, Jean, Coco", state.Output);
            Assert.AreEqual(string.Empty, state.Error);
        }

        [Test]
        public void SymptomFix_WorksForThreeGuards_ButHardCodesTheLimit()
        {
            var state = Play(_room.Fixes[1].Consequence);

            Assert.AreEqual("Thea, Jean, Coco", state.Output);
            Assert.AreEqual(string.Empty, state.Error);
            Assert.AreEqual(2, state.NumberVariables.First(v => v.Name == "n").Value);
        }

        [Test]
        public void WrongFix_SkipsAna_AndStillCrashes()
        {
            var state = Play(_room.Fixes[2].Consequence);

            Assert.AreEqual("Jean, Coco", state.Output);
            Assert.AreEqual("IndexOutOfRangeException", state.Error);
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
            StringAssert.Contains("g = [Thea, Jean, Coco]", flow.Screen.Body);
            Assert.AreEqual("Investigate: what is the last slot of g?", flow.Screen.Prompt);
            flow.Next();
            Assert.AreEqual("Why does it crash after Coco?", flow.Screen.Prompt);
            flow.Pick(2);
            StringAssert.Contains("Call every guard once.", flow.Screen.Prompt);
            flow.Pick(0);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();
            flow.Next();

            Assert.AreEqual(3, session.Stars);
        }
    }
}
