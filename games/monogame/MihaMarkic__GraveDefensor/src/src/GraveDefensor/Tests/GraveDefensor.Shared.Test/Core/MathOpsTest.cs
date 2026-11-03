using GraveDefensor.Shared.Core;
using NUnit.Framework;
using System;

namespace GraveDefensor.Shared.Test.Core
{
    public class MathOpsTest
    {
        internal const double Tolerance = 1e-5;
        [TestFixture]
        public class CalculateRotation : MathOpsTest
        {
            protected readonly double MaxRotation = Math.PI / 80; // 1/160 of full rotation
            [Test]
            public void WhenTargetAndCurrentAngleAreSame_ReturnsCurrentRotation()
            {
                var actual = MathOps.CalculateRotation(1, 1, MaxRotation);

                Assert.That(actual, Is.EqualTo(1));
            }
            [Test]
            public void WhenTargetIsNegativeAndMoreThanMaxRotation_ReturnsCurrentMinusMaxRotation()
            {
                var actual = MathOps.CalculateRotation(-Math.PI / 2, 0, MaxRotation);

                Assert.That(actual, Is.EqualTo(-MaxRotation));
            }
            [Test]
            public void WhenTargetIsPositiveAndMoreThanMaxRotation_ReturnsCurrentPlusMaxRotation()
            {
                var actual = MathOps.CalculateRotation(Math.PI / 2, 0, MaxRotation);

                Assert.That(actual, Is.EqualTo(MaxRotation));
            }
            [Test]
            public void WhenTargetIsNegativeAndLessThanMaxRotation_ReturnsTargetRotation()
            {
                const double targetAngle = -Math.PI / 85;
                var actual = MathOps.CalculateRotation(targetAngle, 0, MaxRotation);

                Assert.That(actual, Is.EqualTo(targetAngle));
            }
            [Test]
            public void WhenTargetIsPositiveAndLessThanMaxRotation_ReturnsTargetRotation()
            {
                const double targetAngle = Math.PI / 85;
                var actual = MathOps.CalculateRotation(targetAngle, 0, MaxRotation);

                Assert.That(actual, Is.EqualTo(targetAngle));
            }
        }
        [TestFixture]
        public class CalculateMinAngleDifference: MathOpsTest
        {
            [Test]
            public void WhenBothAreZero_ReturnsZero()
            {
                var actual = MathOps.CalculateMinAngleDifference(0, 0);

                Assert.That(actual, Is.Zero);
            }
            [Test]
            public void WhenBothAreEqual_ReturnsZero()
            {
                var actual = MathOps.CalculateMinAngleDifference(Math.PI / 2, Math.PI / 2);

                Assert.That(actual, Is.Zero);
            }
            [TestCase(Math.PI / 2, Math.PI / 2 - .1, -.1)]
            [TestCase(Math.PI / 2, Math.PI / 2 + .1, .1)]
            public void WhenSmallDifferenceWithSameSign_ReturnsDifference(double first, double second, double expected)
            {
                var actual = MathOps.CalculateMinAngleDifference(first, second);

                Assert.That(actual, Is.EqualTo(expected).Within(Tolerance));
            }
            [Test]
            public void WhenSmallNegativeDifferenceWithDifferentSign()
            {
                var actual = MathOps.CalculateMinAngleDifference(.01, -.01);

                Assert.That(actual, Is.EqualTo(-.02).Within(Tolerance));
            }
            [Test]
            public void WhenSmallPositiveDifferenceWithDifferentSign()
            {
                var actual = MathOps.CalculateMinAngleDifference(-.01, .01);

                Assert.That(actual, Is.EqualTo(.02).Within(Tolerance));
            }
            [Test]
            public void WhenSmallAbsNegativeDifferenceButBigRelative_ReturnsSmallDifference()
            {
                var actual = MathOps.CalculateMinAngleDifference(-Math.PI +.01, Math.PI - .01);

                Assert.That(actual, Is.EqualTo(-.02).Within(Tolerance));
            }
            [Test]
            public void WhenSmallAbsPositiveDifferenceButBigRelative_ReturnsSmallDifference()
            {
                var actual = MathOps.CalculateMinAngleDifference(Math.PI - .01, -(Math.PI - .01));

                Assert.That(actual, Is.EqualTo(.02).Within(Tolerance));
            }
            /// <summary>
            /// Taken from https://gist.github.com/bradphelan/7fe21ad8ebfcb43696b8
            /// </summary>
            /// <param name="source"></param>
            /// <param name="target"></param>
            /// <param name="expected"></param>
            [TestCase(0.1, 0.2, 0.1)]
            [TestCase(0.1, 0.2 + Math.PI * 2, 0.1)]
            [TestCase(0.1, 0.2 - Math.PI * 2, 0.1)]
            [TestCase(0.1 + Math.PI * 2, 0.2, 0.1)]
            [TestCase(0.1 + Math.PI * 2, 0.2, 0.1)]
            [TestCase(0.2, 0.1, -0.1)]
            [TestCase(0.2, 0.1 - Math.PI * 2, -0.1)]
            [TestCase(0.2, 0.1 + Math.PI * 2, -0.1)]
            [TestCase(0.2 + Math.PI * 2, 0.1, -0.1)]
            [TestCase(0.2 - Math.PI * 2, 0.1, -0.1)]
            public void StandardTest(double source, double target, double expected)
            {
                var actual = MathOps.CalculateMinAngleDifference(source, target);

                Assert.That(actual, Is.EqualTo(expected).Within(Tolerance));
            }
        }
    }
}
