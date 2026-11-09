using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room36Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room36.Create();

        [Test]
        public void Library_KnowsRoom36()
        {
            Assert.IsTrue(RoomLibrary.Has("3-6"));
            Assert.IsTrue(RoomLibrary.TryCreate("3-6", out var room));
            Assert.AreEqual("The Forty-Line Monster", room.Title);
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry()
        {
            Assert.IsTrue(KeepCatalogSeed.Create().SelectMany(c => c.rooms).Any(r => r.id == Room36.Id));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(8, _room.CodeLines.Count);
            Assert.AreEqual("4", _room.Predict.Options[_room.Predict.CorrectIndex]);
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
        public void OriginalTrace_ShowsFourJobs()
        {
            CollectionAssert.AreEqual(new[]
            {
                "job 1 = validate the order", "job 2 = work out the price",
                "job 3 = save to the database", "job 4 = send the receipt"
            }, Play(_room.Trace).WatchLines().ToList());
        }

        [Test]
        public void BestFix_CallsFourNamedMethods()
        {
            var lines = Play(_room.Fixes[0].Consequence).WatchLines();

            Assert.AreEqual(4, lines.Count);
            Assert.AreEqual("Validate(o) returns done", lines[0]);
            Assert.AreEqual("SendReceipt(o) returns done", lines[3]);
        }

        [Test]
        public void SymptomFix_HasTwoVagueMethods()
        {
            CollectionAssert.AreEqual(new[] { "Part1(o) returns done", "Part2(o) returns done" },
                Play(_room.Fixes[1].Consequence).WatchLines().ToList());
        }

        [Test]
        public void WrongFix_OneMethodStillDoesEverything()
        {
            CollectionAssert.AreEqual(new[] { "DoEverything(o) returns done" },
                Play(_room.Fixes[2].Consequence).WatchLines().ToList());
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
