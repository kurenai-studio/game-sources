using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room14Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room14.Create();

        [Test]
        public void Library_KnowsRoom14()
        {
            Assert.IsTrue(RoomLibrary.Has("1-4"));
            Assert.IsTrue(RoomLibrary.TryCreate("1-4", out var room));
            Assert.AreEqual("Copy of a Copy", room.Title);
            Assert.IsFalse(RoomLibrary.Has("1-7"));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(5, _room.CodeLines.Count);
            Assert.AreEqual(15, _room.Trace.Count);
            Assert.AreEqual("9", _room.Predict.Options[_room.Predict.CorrectIndex]);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsTrue(_room.HasSupportCode);
            StringAssert.Contains("class Sword", _room.SupportCode);
            Assert.IsTrue(_room.Fixes.All(f => f.CodeLines.Count == 5));
            Assert.IsTrue(_room.Trace.All(e => e.Line >= 1 && e.Line <= 5));
        }

        [Test]
        public void OriginalTrace_TwoListsShareOneSword()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual(2, state.Chests.Count);
            CollectionAssert.AreEqual(new[] { "Sword #2 (Damage 9)" }, state.DescribeItems(state.Chests[0]).ToList());
            CollectionAssert.AreEqual(new[] { "Sword #2 (Damage 9)" }, state.DescribeItems(state.Chests[1]).ToList());
            Assert.AreEqual("9", state.Output);
        }

        [Test]
        public void WatchList_NamesTheSharedSword()
        {
            var lines = Play(_room.Trace).WatchLines();

            CollectionAssert.AreEqual(new[]
            {
                "hero -> list #1", "rogue -> list #3", "sword #2: Damage 9 (in list #1 and list #3)"
            }, lines.ToList());
        }

        [Test]
        public void CopyingTheList_DoesNotCopyTheSword_BeforeLineFour()
        {
            var state = Play(_room.Trace.Take(11).ToList());

            Assert.AreEqual(1, state.Chests[0].ItemCount);
            Assert.AreEqual(1, state.Chests[1].ItemCount);
            StringAssert.Contains("Damage 5", state.DescribeItems(state.Chests[1])[0]);
        }

        [Test]
        public void BestFix_GivesTheRogueItsOwnSword()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.AreEqual("Sword #2 (Damage 5)", state.DescribeItems(state.Chests[0])[0]);
            Assert.AreEqual("Sword #4 (Damage 9)", state.DescribeItems(state.Chests[1])[0]);
            Assert.AreEqual("5", state.Output);
        }

        [Test]
        public void SymptomFix_PrintsFiveButStillSharesTheSword()
        {
            var state = Play(_room.Fixes[1].Consequence);

            Assert.AreEqual("5", state.Output);
            Assert.AreEqual("Sword #2 (Damage 9)", state.DescribeItems(state.Chests[0])[0]);
        }

        [Test]
        public void WrongFix_ThrowsOutOfRange()
        {
            var state = Play(_room.Fixes[2].Consequence);

            Assert.AreEqual("ArgumentOutOfRangeException", state.Error);
            Assert.AreEqual(0, state.Chests[1].ItemCount);
        }

        [Test]
        public void Clear_ForgetsItemObjects()
        {
            var state = Play(_room.Trace);

            state.Clear();

            Assert.AreEqual(0, state.WatchLines().Count);
            Assert.AreEqual(0, state.Chests.Count);
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
            StringAssert.Contains("sword #2", flow.Screen.Body);
            Assert.AreEqual("Investigate: what does each list hold?", flow.Screen.Prompt);
            flow.Next();
            Assert.AreEqual("Why did the hero's sword change?", flow.Screen.Prompt);
            flow.Pick(2);
            flow.Pick(0);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();
            flow.Next();

            Assert.AreEqual(3, session.Stars);
        }
    }
}
