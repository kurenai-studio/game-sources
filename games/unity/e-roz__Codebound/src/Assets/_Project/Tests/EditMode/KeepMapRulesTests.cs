using System.Collections.Generic;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class KeepMapRulesTests
    {
        readonly List<KeepChapter> _chapters = KeepCatalogSeed.Create();

        [Test]
        public void RoomLabel_UsesChapterLocalNumbers()
        {
            Assert.AreEqual("1.1", KeepMapRules.RoomLabel(0, 0));
            Assert.AreEqual("2.4", KeepMapRules.RoomLabel(1, 3));
        }

        [Test]
        public void LockedRooms_HideTitleTypeAndConcept()
        {
            var room = _chapters[0].rooms[2];

            Assert.AreEqual("???", KeepMapRules.DisplayTitle(room, RoomState.Locked));
            Assert.AreEqual("???", KeepMapRules.DisplayType(room, RoomState.Locked));
            Assert.AreEqual("???", KeepMapRules.DisplayConcept(room, RoomState.Locked));
        }

        [Test]
        public void UnlockedRooms_ShowTheirDetails()
        {
            var room = _chapters[0].rooms[0];

            Assert.AreEqual("The Twin Guards", KeepMapRules.DisplayTitle(room, RoomState.Open));
            Assert.AreEqual("Predict", KeepMapRules.DisplayType(room, RoomState.Completed));
            Assert.AreEqual("Reference types", KeepMapRules.DisplayConcept(room, RoomState.Open));
        }

        [Test]
        public void RoomStatus_DescribesEachState()
        {
            Assert.AreEqual("Locked", KeepMapRules.RoomStatus(RoomState.Locked, 0));
            Assert.AreEqual("Next", KeepMapRules.RoomStatus(RoomState.Open, 0));
            Assert.AreEqual("1 star", KeepMapRules.RoomStatus(RoomState.Completed, 1));
            Assert.AreEqual("3 stars", KeepMapRules.RoomStatus(RoomState.Completed, 3));
        }

        [Test]
        public void WingStatus_DescribesEachState()
        {
            var progress = new List<RoomProgress> { new RoomProgress { roomId = "1-1", bestStars = 2 } };

            Assert.AreEqual("1 / 6 rooms", KeepMapRules.WingStatus(_chapters, 0, progress));
            Assert.AreEqual("Locked: finish The Vaults", KeepMapRules.WingStatus(_chapters, 1, progress));
            Assert.AreEqual("Locked: finish The Gates", KeepMapRules.WingStatus(_chapters, 2, progress));
            Assert.AreEqual("Locked: finish The Workshop", KeepMapRules.WingStatus(_chapters, 3, progress));
            Assert.AreEqual("Locked: finish The Archive", KeepMapRules.WingStatus(_chapters, 4, progress));
            Assert.AreEqual("Locked: finish The Great Hall", KeepMapRules.WingStatus(_chapters, 5, progress));
            Assert.AreEqual("Locked: finish The Towers", KeepMapRules.WingStatus(_chapters, 6, progress));
        }

        [Test]
        public void TalaLine_FollowsTheThreeStates()
        {
            StringAssert.Contains("Start with The Vaults", KeepMapRules.TalaLine("Jean", 0, false));
            StringAssert.Contains("next room", KeepMapRules.TalaLine("Jean", 3, false));
            StringAssert.Contains("fixed the Keep", KeepMapRules.TalaLine("Jean", 10, true));
            StringAssert.Contains("Jean", KeepMapRules.TalaLine("Jean", 3, false));
        }

        [Test]
        public void IsMvpComplete_NeedsEveryPlayableRoom()
        {
            var some = new List<RoomProgress> { new RoomProgress { roomId = "1-1", bestStars = 1 } };
            var all = new List<RoomProgress>();
            foreach (var chapter in _chapters)
                foreach (var room in chapter.rooms)
                    all.Add(new RoomProgress { roomId = room.id, bestStars = 1 });

            Assert.IsFalse(KeepMapRules.IsMvpComplete(_chapters, some));
            Assert.IsTrue(KeepMapRules.IsMvpComplete(_chapters, all));
        }
    }
}
