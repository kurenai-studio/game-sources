using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room23Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room23.Create();

        [Test]
        public void Library_KnowsRoom23()
        {
            Assert.IsTrue(RoomLibrary.Has("2-3"));
            Assert.IsTrue(RoomLibrary.TryCreate("2-3", out var room));
            Assert.AreEqual("The Gate That Never Closes", room.Title);
            Assert.IsFalse(RoomLibrary.Has("9-1"));
        }

        [Test]
        public void RoomId_MatchesKeepCatalogEntry_BetweenRoom22AndRoom24()
        {
            var ids = KeepCatalogSeed.Create().SelectMany(c => c.rooms).Select(r => r.id).ToList();
            Assert.AreEqual(ids.IndexOf("2-2") + 1, ids.IndexOf(Room23.Id));
            Assert.AreEqual(ids.IndexOf(Room23.Id) + 1, ids.IndexOf("2-4"));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(4, _room.CodeLines.Count);
            Assert.AreEqual(15, _room.Trace.Count);
            Assert.AreEqual("Knocks forever", _room.Predict.Options[_room.Predict.CorrectIndex]);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.Verdict == Verdict.Close));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsFalse(_room.HasSupportCode);
            Assert.IsTrue(_room.CodeLines.Count <= 5);
            Assert.IsTrue(_room.Fixes.All(f => f.CodeLines.Count <= 5));
            Assert.IsTrue(_room.CodeLines.All(l => l.Length <= 35));
            Assert.IsTrue(_room.Fixes.All(f => f.CodeLines.All(l => l.Length <= 35)));
            Assert.IsTrue(_room.Trace.All(e => e.Line >= 1 && e.Line <= 4));
            Assert.IsTrue(_room.Fixes.All(f => f.Consequence.All(e => e.Line >= 1 && e.Line <= f.CodeLines.Count)));
        }

        [Test]
        public void OriginalTrace_KnocksThreeTimes_ThenTimesOut_WithTriesStillThree()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual("Knock, Knock, Knock", state.Output);
            StringAssert.StartsWith("Timed out", state.Error);
            Assert.AreEqual(3, state.NumberVariables.Single(v => v.Name == "tries").Value);
        }

        [Test]
        public void WatchList_ShowsTriesAndThreeIdenticalChecks()
        {
            CollectionAssert.AreEqual(new[]
            {
                "tries = 3", "step 1: 3 > 0 = true", "step 2: 3 > 0 = true", "step 3: 3 > 0 = true"
            }, Play(_room.Trace).WatchLines().ToList());
        }

        [Test]
        public void BestFix_CountsDown_KnocksThree_AndStops()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.AreEqual("Knock, Knock, Knock", state.Output);
            Assert.AreEqual(string.Empty, state.Error);
            Assert.AreEqual(0, state.NumberVariables.Single(v => v.Name == "tries").Value);
            Assert.AreEqual("step 4: 0 > 0 = false", state.WatchLines().Last());
        }

        [Test]
        public void SymptomFix_StopsAfterOneKnock()
        {
            var state = Play(_room.Fixes[1].Consequence);

            Assert.AreEqual("Knock", state.Output);
            Assert.AreEqual(string.Empty, state.Error);
        }

        [Test]
        public void WrongFix_StillTimesOut()
        {
            var state = Play(_room.Fixes[2].Consequence);

            Assert.AreEqual("Knock, Knock, Knock", state.Output);
            StringAssert.StartsWith("Timed out", state.Error);
            Assert.AreEqual(3, state.NumberVariables.Single(v => v.Name == "tries").Value);
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
            StringAssert.Contains("tries = 3", flow.Screen.Body);
            Assert.AreEqual("Investigate: which line changes tries?", flow.Screen.Prompt);
            flow.Next();
            Assert.AreEqual("Why does it never stop?", flow.Screen.Prompt);
            flow.Pick(2);
            StringAssert.Contains("Knock 3 times", flow.Screen.Prompt);
            flow.Pick(0);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();
            flow.Next();

            Assert.AreEqual(3, session.Stars);
        }
    }
}
