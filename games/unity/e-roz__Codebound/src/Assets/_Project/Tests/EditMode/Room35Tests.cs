using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room35Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room35.Create();

        [Test]
        public void Library_KnowsRoom35()
        {
            Assert.IsTrue(RoomLibrary.Has("3-5"));
            Assert.IsTrue(RoomLibrary.TryCreate("3-5", out var room));
            Assert.AreEqual("Red, Then Green", room.Title);
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room35.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(5, _room.CodeLines.Count);
            Assert.AreEqual("-1", _room.Predict.Options[_room.Predict.CorrectIndex]);
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
        public void OriginalTrace_AddSubtracts()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual("-1", state.Output);
            CollectionAssert.AreEqual(new[] { "Add(2, 3) returns -1" }, state.WatchLines().ToList());
        }

        [Test]
        public void TestRan_AddsRedAndGreenLines()
        {
            var state = new KeepState();
            state.Apply(TraceEvent.TestRan(1, "t", false));
            state.Apply(TraceEvent.TestRan(1, "t", true));

            Assert.AreEqual(ReportKind.Red, state.Report[0].Kind);
            Assert.AreEqual(ReportKind.Green, state.Report[1].Kind);
            Assert.AreEqual("Test t is green.", state.Caption);
        }

        [Test]
        public void BestFix_IsRedBeforeAndGreenAfter()
        {
            var state = Play(_room.Fixes[0].Consequence);

            CollectionAssert.AreEqual(new[] { ReportKind.Red, ReportKind.Green }, state.Report.Select(r => r.Kind).ToList());
            Assert.AreEqual("5", state.Output);
        }

        [Test]
        public void SymptomFix_IsGreenWithoutEverBeingRed()
        {
            var state = Play(_room.Fixes[1].Consequence);

            CollectionAssert.AreEqual(new[] { ReportKind.Green }, state.Report.Select(r => r.Kind).ToList());
        }

        [Test]
        public void WrongFix_TheTestIsGreenWhileTheBugRemains()
        {
            var state = Play(_room.Fixes[2].Consequence);

            Assert.AreEqual(ReportKind.Green, state.Report.Single().Kind);
            Assert.AreEqual("-1", state.Output);
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
