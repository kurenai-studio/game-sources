using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class KeepStateTests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        [Test]
        public void OriginalTrace_TwoGuardsShareOneChestWithOneItem()
        {
            var state = Play(Room11.Create().Trace);

            Assert.AreEqual(2, state.Guards.Count);
            Assert.AreEqual(1, state.Chests.Count);
            Assert.IsTrue(state.Guards.All(g => g.ObjectId == 1));
            Assert.AreEqual(1, state.Chests[0].ItemCount);
            Assert.AreEqual("1", state.Output);
            Assert.AreEqual(4, state.CurrentLine);
        }

        [Test]
        public void BestFix_GivesTwoChests_AndSecondGuardPointsToEmptyOne()
        {
            var state = Play(Room11.Create().Fixes[0].Consequence);

            Assert.AreEqual(2, state.Chests.Count);
            Assert.AreEqual(1, state.Guards[0].ObjectId);
            Assert.AreEqual(2, state.Guards[1].ObjectId);
            Assert.AreEqual(1, state.Chests[0].ItemCount);
            Assert.AreEqual(0, state.Chests[1].ItemCount);
            Assert.AreEqual("0", state.Output);
        }

        [Test]
        public void SymptomFix_EndsWithEmptySharedChest()
        {
            var state = Play(Room11.Create().Fixes[1].Consequence);

            Assert.AreEqual(1, state.Chests.Count);
            Assert.AreEqual(0, state.Chests[0].ItemCount);
        }

        [Test]
        public void NullFix_MarksGuardNullAndRecordsError()
        {
            var state = Play(Room11.Create().Fixes[2].Consequence);

            Assert.IsTrue(state.Guards[1].IsNull);
            Assert.AreEqual(0, state.Guards[1].ObjectId);
            Assert.AreEqual("NullReferenceException", state.Error);
        }

        [Test]
        public void Clear_ResetsEverything()
        {
            var state = Play(Room11.Create().Trace);

            state.Clear();

            Assert.AreEqual(0, state.Guards.Count);
            Assert.AreEqual(0, state.Chests.Count);
            Assert.AreEqual(0, state.CurrentLine);
            Assert.AreEqual(string.Empty, state.Output);
            Assert.AreEqual(string.Empty, state.Caption);
        }

        [Test]
        public void ReplayingTheSameTrace_AfterClear_GivesTheSameState()
        {
            var room = Room11.Create();
            var state = Play(room.Trace);
            state.Clear();
            foreach (var e in room.Trace) state.Apply(e);

            Assert.AreEqual(2, state.Guards.Count);
            Assert.AreEqual(1, state.Chests.Count);
        }

        [Test]
        public void EveryEvent_SetsACaption()
        {
            var state = new KeepState();
            foreach (var e in Room11.Create().Trace)
            {
                state.Apply(e);
                Assert.IsNotEmpty(state.Caption);
            }
        }
    }

    public class RoomLibraryTests
    {
        [Test]
        public void Room11_IsAvailable_OthersAreNot()
        {
            Assert.IsTrue(RoomLibrary.Has("1-1"));
            Assert.IsTrue(RoomLibrary.TryCreate("1-1", out var room));
            Assert.AreEqual("The Twin Guards", room.Title);
            Assert.IsFalse(RoomLibrary.Has("1-7"));
            Assert.IsFalse(RoomLibrary.TryCreate("1-7", out _));
        }

        [Test]
        public void Room11Id_MatchesKeepCatalogEntry()
        {
            var catalog = KeepCatalogSeed.Create();
            Assert.IsTrue(catalog.SelectMany(c => c.rooms).Any(r => r.id == Room11.Id));
        }
    }
}
