using System.Collections.Generic;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class KeepCatalogSeedTests
    {
        [Test]
        public void HasSevenWings_AllPlayable()
        {
            var chapters = KeepCatalogSeed.Create();

            Assert.AreEqual(7, chapters.Count);
            Assert.AreEqual(6, chapters[0].rooms.Count);
            Assert.AreEqual(6, chapters[1].rooms.Count);
            Assert.IsFalse(chapters[0].isSealed);
            Assert.IsFalse(chapters[1].isSealed);
            Assert.AreEqual(6, chapters[2].rooms.Count);
            Assert.IsFalse(chapters[2].isSealed);
            Assert.AreEqual(6, chapters[3].rooms.Count);
            Assert.AreEqual(6, chapters[4].rooms.Count);
            Assert.IsFalse(chapters[4].isSealed);
            Assert.IsFalse(chapters[3].isSealed);
            Assert.AreEqual(6, chapters[5].rooms.Count);
            Assert.IsFalse(chapters[5].isSealed);
            Assert.AreEqual(6, chapters[6].rooms.Count);
            for (var i = 0; i < chapters.Count; i++) Assert.IsFalse(chapters[i].isSealed, chapters[i].name);
        }

        [Test]
        public void EveryRoomHasUniqueIdAndFullDetails()
        {
            var seen = new HashSet<string>();
            foreach (var chapter in KeepCatalogSeed.Create())
            {
                Assert.IsNotEmpty(chapter.name);
                foreach (var room in chapter.rooms)
                {
                    Assert.IsTrue(seen.Add(room.id), "Duplicate id " + room.id);
                    Assert.IsNotEmpty(room.title, room.id);
                    Assert.IsNotEmpty(room.roomType, room.id);
                    Assert.IsNotEmpty(room.concept, room.id);
                }
            }
            Assert.AreEqual(42, seen.Count);
        }
    }
}
