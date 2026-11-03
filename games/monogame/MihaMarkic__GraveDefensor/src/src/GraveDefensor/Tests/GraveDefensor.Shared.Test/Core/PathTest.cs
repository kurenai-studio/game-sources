using GraveDefensor.Shared.Core;
using NUnit.Framework;
using System.Diagnostics;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Test.Core
{
    public class PathTest: BaseTest<Path>
    {
        [DebuggerStepThrough]
        internal static Settings.Point[] GetTestPoints()
        {
            return new Settings.Point[] {
                        new Settings.Point {  X = 0, Y = 0},
                        new Settings.Point { X = 100, Y = 0 },
                        new Settings.Point { X = 103, Y = 4 },
                        new Settings.Point { X = 103, Y = 10 }
                    };
        }
        [DebuggerStepThrough]
        internal static Settings.Path GetTestPath() => new Settings.Path { Points = GetTestPoints() };

        [TestFixture]
        public class DistanceBetweenPoints : PathTest
        {
            [TestCase(0, 0, 100, 0, ExpectedResult = 100)]
            [TestCase(0, 0, 3, 4, ExpectedResult = 5)]
            [TestCase(0, 0, -3, 4, ExpectedResult = 5)]
            [TestCase(0, 0, 3, -4, ExpectedResult = 5)]
            [TestCase(0, 0, -3, -4, ExpectedResult = 5)]
            public double CalculateDistanceProperly(int ax, int ay, int bx, int by)
            {
                return Path.DistanceBetweenPoints(new Settings.Point { X = ax, Y = ay }, new Settings.Point { X = bx, Y = by });
            }
        }
        [TestFixture]
        public class CalculateSegmentsLengths : PathTest
        {
            [Test]
            public void CalculatesAllSegments()
            {
                var actual = Path.CalculateSegmentsLengths(GetTestPoints());

                Assert.That(actual.Length, Is.EqualTo(3));
            }
            [Test]
            public void SegmentsAreCorrectlyCalculated()
            {
                var actual = Path.CalculateSegmentsLengths(GetTestPoints());

                Assert.That(actual, Is.EqualTo(new double[] { 100, 5, 6 }));
            }
        }
        [TestFixture]
        public class CalculateLengthFromSegment: PathTest
        {
            [SetUp]
            public new void SetUp()
            {
                Target.Init(GetTestPath());
            }
            [Test]
            public void WhenStartingWithZeroSegment_SumsAll()
            {
                var actual = Target.CalculateLengthFromSegment(0);

                Assert.That(actual, Is.EqualTo(111));
            }
            [Test]
            public void WhenStartingWithPreLastSegment_SumsAll()
            {
                var actual = Target.CalculateLengthFromSegment(1);

                Assert.That(actual, Is.EqualTo(11));
            }
            [Test]
            public void WhenStartingWithLastSegment_ReturnsLast()
            {
                var actual = Target.CalculateLengthFromSegment(2);

                Assert.That(actual, Is.EqualTo(6));
            }
        }
    }
}
