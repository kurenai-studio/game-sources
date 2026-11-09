using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room34Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room34.Create();

        [Test]
        public void Library_KnowsRoom34()
        {
            Assert.IsTrue(RoomLibrary.Has("3-4"));
            Assert.IsTrue(RoomLibrary.TryCreate("3-4", out var room));
            Assert.AreEqual("The Silent Failure", room.Title);
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room34.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(6, _room.CodeLines.Count);
            Assert.AreEqual("Done", _room.Predict.Options[_room.Predict.CorrectIndex]);
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
        public void OriginalTrace_FailureIsSwallowed_LogIsEmpty_StillPrintsDone()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual("Done", state.Output);
            Assert.AreEqual(string.Empty, state.Error);
            Assert.IsTrue(state.HasReport);
            Assert.AreEqual(0, state.Report.Count);
            CollectionAssert.AreEqual(new[] { "LoadSave = throws FileNotFoundException" }, state.WatchLines().ToList());
        }

        [Test]
        public void LogEvents_BuildTheReport_AndClearForgetsIt()
        {
            var state = new KeepState();
            state.Apply(TraceEvent.LogAppended(1, "ERROR bad"));
            state.Apply(TraceEvent.LogAppended(1, "ok"));

            Assert.AreEqual(ReportKind.Error, state.Report[0].Kind);
            Assert.AreEqual(ReportKind.Log, state.Report[1].Kind);
            state.Clear();
            Assert.IsFalse(state.HasReport);
            Assert.AreEqual(0, state.Report.Count);
        }

        [Test]
        public void BestFix_LogsTheFileName()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.AreEqual("ERROR FileNotFoundException: save.dat", state.Report.Single().Text);
            Assert.AreEqual(ReportKind.Error, state.Report.Single().Kind);
        }

        [Test]
        public void SymptomFix_LogsOnlyTheWordError()
        {
            Assert.AreEqual("error", Play(_room.Fixes[1].Consequence).Report.Single().Text);
        }

        [Test]
        public void WrongFix_CrashesOnAMissingFile()
        {
            Assert.AreEqual("FileNotFoundException", Play(_room.Fixes[2].Consequence).Error);
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
