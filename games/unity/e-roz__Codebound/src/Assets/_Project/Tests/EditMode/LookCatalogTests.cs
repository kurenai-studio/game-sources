using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class LookCatalogTests
    {
        [Test]
        public void HasTwoLooks_WithIdsZeroAndOne()
        {
            Assert.AreEqual(2, LookCatalog.Looks.Count);
            Assert.AreEqual(0, LookCatalog.Looks[0].Id);
            Assert.AreEqual(1, LookCatalog.Looks[1].Id);
        }

        [Test]
        public void LabelFor_ReturnsLookNames()
        {
            Assert.AreEqual("Look 1", LookCatalog.LabelFor(0));
            Assert.AreEqual("Look 2", LookCatalog.LabelFor(1));
        }

        [TestCase(0, true)]
        [TestCase(1, true)]
        [TestCase(-1, false)]
        [TestCase(2, false)]
        public void IsValid_OnlyAcceptsKnownIds(int id, bool expected)
        {
            Assert.AreEqual(expected, LookCatalog.IsValid(id));
        }

        [TestCase(1, 1)]
        [TestCase(-5, LookCatalog.DefaultId)]
        [TestCase(99, LookCatalog.DefaultId)]
        public void Normalize_FallsBackToDefaultForUnknownIds(int id, int expected)
        {
            Assert.AreEqual(expected, LookCatalog.Normalize(id));
        }
    }
}
