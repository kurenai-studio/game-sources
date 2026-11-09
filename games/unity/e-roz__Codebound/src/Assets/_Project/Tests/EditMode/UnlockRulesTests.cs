using System.Collections.Generic;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class UnlockRulesTests
    {
        List<KeepChapter> _chapters;

        [SetUp]
        public void SetUp()
        {
            _chapters = KeepCatalogSeed.Create();
        }

        static List<RoomProgress> Done(params string[] ids)
        {
            var list = new List<RoomProgress>();
            foreach (var id in ids) list.Add(new RoomProgress { roomId = id, bestStars = 1 });
            return list;
        }

        static readonly string[] Chapter1 = { "1-1", "1-2", "1-3", "1-4", "1-5", "1-6" };

        [Test]
        public void FreshGame_OnlyFirstVaultRoomIsOpen()
        {
            var progress = new List<RoomProgress>();

            Assert.AreEqual(RoomState.Open, UnlockRules.GetRoomState(_chapters, 0, 0, progress));
            for (var r = 1; r < 6; r++)
                Assert.AreEqual(RoomState.Locked, UnlockRules.GetRoomState(_chapters, 0, r, progress));
        }

        [Test]
        public void FreshGame_VaultsOpen_EveryOtherWingLocked()
        {
            var progress = new List<RoomProgress>();

            Assert.AreEqual(WingState.Open, UnlockRules.GetWingState(_chapters, 0, progress));
            Assert.AreEqual(WingState.Locked, UnlockRules.GetWingState(_chapters, 1, progress));
            Assert.AreEqual(WingState.Locked, UnlockRules.GetWingState(_chapters, 2, progress));
            Assert.AreEqual(WingState.Locked, UnlockRules.GetWingState(_chapters, 3, progress));
            Assert.AreEqual(WingState.Locked, UnlockRules.GetWingState(_chapters, 4, progress));
            Assert.AreEqual(WingState.Locked, UnlockRules.GetWingState(_chapters, 5, progress));
            Assert.AreEqual(WingState.Locked, UnlockRules.GetWingState(_chapters, 6, progress));
        }

        [Test]
        public void CompletingARoom_UnlocksTheNextOne()
        {
            var progress = Done("1-1");

            Assert.AreEqual(RoomState.Completed, UnlockRules.GetRoomState(_chapters, 0, 0, progress));
            Assert.AreEqual(RoomState.Open, UnlockRules.GetRoomState(_chapters, 0, 1, progress));
            Assert.AreEqual(RoomState.Locked, UnlockRules.GetRoomState(_chapters, 0, 2, progress));
        }

        [Test]
        public void CompletingChapterOne_UnlocksTheGates()
        {
            var progress = Done(Chapter1);

            Assert.AreEqual(WingState.Completed, UnlockRules.GetWingState(_chapters, 0, progress));
            Assert.AreEqual(WingState.Open, UnlockRules.GetWingState(_chapters, 1, progress));
            Assert.AreEqual(RoomState.Open, UnlockRules.GetRoomState(_chapters, 1, 0, progress));
        }

        [Test]
        public void SealedWing_RoomsAreAlwaysLocked()
        {
            var chapters = new List<KeepChapter>
            {
                _chapters[0],
                new KeepChapter { id = "x", name = "X", isSealed = true, rooms = new List<KeepRoom> { new KeepRoom { id = "x-1" } } }
            };
            var progress = Done(Chapter1);

            Assert.AreEqual(WingState.Sealed, UnlockRules.GetWingState(chapters, 1, progress));
            Assert.AreEqual(RoomState.Locked, UnlockRules.GetRoomState(chapters, 1, 0, progress));
        }

        [Test]
        public void CompletedRoomInsideLockedWing_StaysLocked()
        {
            var progress = Done("2-1");

            Assert.AreEqual(RoomState.Locked, UnlockRules.GetRoomState(_chapters, 1, 0, progress));
        }

        [Test]
        public void NullProgress_IsTreatedAsNothingCompleted()
        {
            Assert.AreEqual(RoomState.Open, UnlockRules.GetRoomState(_chapters, 0, 0, null));
            Assert.AreEqual(0, UnlockRules.TotalStars(_chapters, null));
        }

        [Test]
        public void CorruptedEntries_DoNotCrashOrCountAsCompleted()
        {
            var progress = new List<RoomProgress>
            {
                null,
                new RoomProgress { roomId = null, bestStars = 3 },
                new RoomProgress { roomId = "", bestStars = 3 },
                new RoomProgress { roomId = "no-such-room", bestStars = 3 },
                new RoomProgress { roomId = "1-1", bestStars = -4 },
                new RoomProgress { roomId = "1-2", bestStars = 0 }
            };

            Assert.AreEqual(RoomState.Open, UnlockRules.GetRoomState(_chapters, 0, 0, progress));
            Assert.AreEqual(RoomState.Locked, UnlockRules.GetRoomState(_chapters, 0, 1, progress));
            Assert.AreEqual(0, UnlockRules.TotalStars(_chapters, progress));
        }

        [Test]
        public void StarsAboveThree_AreClamped()
        {
            var progress = new List<RoomProgress> { new RoomProgress { roomId = "1-1", bestStars = 99 } };

            Assert.AreEqual(3, UnlockRules.GetStars(progress, "1-1"));
        }

        [Test]
        public void DuplicateEntries_UseTheBestStars()
        {
            var progress = new List<RoomProgress>
            {
                new RoomProgress { roomId = "1-1", bestStars = 1 },
                new RoomProgress { roomId = "1-1", bestStars = 3 }
            };

            Assert.AreEqual(3, UnlockRules.GetStars(progress, "1-1"));
        }

        [Test]
        public void OutOfRangeIndexes_AreLockedNotCrashes()
        {
            var progress = new List<RoomProgress>();

            Assert.AreEqual(RoomState.Locked, UnlockRules.GetRoomState(_chapters, 0, 99, progress));
            Assert.AreEqual(RoomState.Locked, UnlockRules.GetRoomState(_chapters, 99, 0, progress));
            Assert.AreEqual(RoomState.Locked, UnlockRules.GetRoomState(_chapters, 0, -1, progress));
            Assert.AreEqual(WingState.Sealed, UnlockRules.GetWingState(_chapters, -1, progress));
        }

        [Test]
        public void TotalAndMaxStars_CountOnlyPlayableRooms()
        {
            var progress = new List<RoomProgress>
            {
                new RoomProgress { roomId = "1-1", bestStars = 3 },
                new RoomProgress { roomId = "1-2", bestStars = 2 }
            };

            Assert.AreEqual(5, UnlockRules.TotalStars(_chapters, progress));
            Assert.AreEqual(126, UnlockRules.MaxStars(_chapters));
            Assert.AreEqual(2, UnlockRules.CompletedRooms(_chapters, progress));
        }

        [Test]
        public void TryFindNextRoom_FollowsProgress()
        {
            Assert.IsTrue(UnlockRules.TryFindNextRoom(_chapters, new List<RoomProgress>(), out var c, out var r));
            Assert.AreEqual((0, 0), (c, r));

            Assert.IsTrue(UnlockRules.TryFindNextRoom(_chapters, Done("1-1", "1-2"), out c, out r));
            Assert.AreEqual((0, 2), (c, r));

            Assert.IsTrue(UnlockRules.TryFindNextRoom(_chapters, Done(Chapter1), out c, out r));
            Assert.AreEqual((1, 0), (c, r));
        }

        [Test]
        public void TryFindNextRoom_ReturnsFalseWhenEverythingPlayableIsDone()
        {
            var all = Done("1-1", "1-2", "1-3", "1-4", "1-5", "1-6", "2-1", "2-2", "2-3", "2-4", "2-5", "2-6", "3-1", "3-2", "3-3", "3-4", "3-5", "3-6", "4-1", "4-2", "4-3", "4-4", "4-5", "4-6", "5-1", "5-2", "5-3", "5-4", "5-5", "5-6", "6-1", "6-2", "6-3", "6-4", "6-5", "6-6", "7-1", "7-2", "7-3", "7-4", "7-5", "7-6");

            Assert.IsFalse(UnlockRules.TryFindNextRoom(_chapters, all, out _, out _));
        }

        [Test]
        public void Record_KeepsTheBestStarsAndNeverLowersThem()
        {
            var progress = new List<RoomProgress>();

            Assert.IsTrue(UnlockRules.Record(progress, "1-1", 2));
            Assert.IsFalse(UnlockRules.Record(progress, "1-1", 1));
            Assert.AreEqual(2, UnlockRules.GetStars(progress, "1-1"));
            Assert.IsTrue(UnlockRules.Record(progress, "1-1", 3));
            Assert.AreEqual(3, UnlockRules.GetStars(progress, "1-1"));
            Assert.AreEqual(1, progress.Count);
        }

        [Test]
        public void Record_IgnoresZeroStarsAndEmptyIds()
        {
            var progress = new List<RoomProgress>();

            Assert.IsFalse(UnlockRules.Record(progress, "1-1", 0));
            Assert.IsFalse(UnlockRules.Record(progress, "", 3));
            Assert.IsFalse(UnlockRules.Record(null, "1-1", 3));
            Assert.IsEmpty(progress);
        }
    }
}
