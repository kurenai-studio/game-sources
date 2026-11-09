using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room13Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room13.Create();

        [Test]
        public void Library_KnowsRoom13()
        {
            Assert.IsTrue(RoomLibrary.Has("1-3"));
            Assert.IsTrue(RoomLibrary.TryCreate("1-3", out var room));
            Assert.AreEqual("The Shared Inventory", room.Title);
            Assert.IsFalse(RoomLibrary.Has("1-7"));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(5, _room.CodeLines.Count);
            Assert.AreEqual(13, _room.Trace.Count);
            Assert.AreEqual("2", _room.Predict.Options[_room.Predict.CorrectIndex]);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsFalse(_room.HasSupportCode);
            Assert.IsTrue(_room.Fixes.All(f => f.CodeLines.Count == 5));
            Assert.IsTrue(_room.Trace.All(e => e.Line >= 1 && e.Line <= 5));
        }

        [Test]
        public void OriginalTrace_OneListHoldsBothItems()
        {
            var state = Play(_room.Trace);

            Assert.AreEqual(1, state.Chests.Count);
            Assert.AreEqual("List", state.Chests[0].TypeName);
            Assert.AreEqual(2, state.Chests[0].ItemCount);
            Assert.AreEqual("2", state.Output);
            CollectionAssert.AreEqual(new[] { "hero -> list #1", "rogue -> list #1" }, state.WatchLines().ToList());
            StringAssert.Contains("list #1", Play(_room.Trace.Take(7).ToList()).Caption);
        }

        [Test]
        public void ItemsAreNamed_OneListHasBoth_AfterTheFixEachHasOne()
        {
            CollectionAssert.AreEqual(new[] { "Potion", "Dagger" }, Play(_room.Trace).Chests[0].Items.ToList());

            var fixedState = Play(_room.Fixes[0].Consequence);
            CollectionAssert.AreEqual(new[] { "Potion" }, fixedState.Chests[0].Items.ToList());
            CollectionAssert.AreEqual(new[] { "Dagger" }, fixedState.Chests[1].Items.ToList());
        }

        [Test]
        public void RemovedItems_LeaveTheList()
        {
            var state = Play(Room11.Create().Fixes[1].Consequence);

            Assert.AreEqual(0, state.Chests[0].ItemCount);
        }

        [Test]
        public void BestFix_GivesEachGuardItsOwnList()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.AreEqual(2, state.Chests.Count);
            Assert.AreEqual(1, state.Chests[0].ItemCount);
            Assert.AreEqual(1, state.Chests[1].ItemCount);
            Assert.AreEqual("1", state.Output);
        }

        [Test]
        public void SymptomAndWrongFixes_StillShareOneList()
        {
            Assert.AreEqual(1, Play(_room.Fixes[1].Consequence).Chests.Count);
            Assert.AreEqual("1", Play(_room.Fixes[1].Consequence).Output);
            Assert.AreEqual(2, Play(_room.Fixes[2].Consequence).Chests[0].ItemCount);
        }

        [Test]
        public void Room11Words_StayTheSame()
        {
            var state = Play(Room11.Create().Trace.Take(7).ToList());

            StringAssert.Contains("chest #1", state.Caption);
            Assert.AreEqual("vaultA -> chest #1", state.WatchLines()[0]);
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
            StringAssert.Contains("hero -> list #1", flow.Screen.Body);
            flow.Next();
            Assert.AreEqual("Why does the hero hold a Dagger?", flow.Screen.Prompt);
            flow.Pick(2);
            flow.Pick(0);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();
            flow.Next();

            Assert.AreEqual(3, session.Stars);
        }
    }
}
