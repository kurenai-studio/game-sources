using NUnit.Framework;
using System;

namespace GraveDefensor.Engine.Test.Core
{
    public class ActionTest: BaseTest<MockAction>
    {
        [TestFixture]
        public class Update: ActionTest
        {
            [Test]
            public void UpdateWithBeginTime_ReturnsZeroPercent()
            {
                double actual = -1;
                Target.Start(currentTime: TimeSpan.FromMilliseconds(400), duration: TimeSpan.FromMilliseconds(200));
                Target.OnUpdate = p => actual = p;

                Target.Update(TimeSpan.FromMilliseconds(400));

                Assert.That(actual, Is.Zero);
            }
            [Test]
            public void UpdateOnHalfTimeSpan_ReturnsFiftyPercent()
            {
                double actual = -1;
                Target.Start(currentTime: TimeSpan.FromMilliseconds(400), duration: TimeSpan.FromMilliseconds(200));
                Target.OnUpdate = p => actual = p;

                Target.Update(TimeSpan.FromMilliseconds(500));

                Assert.That(actual, Is.EqualTo(.5));
            }
            [Test]
            public void UpdateOverDuration_ReturnsHundredPercent()
            {
                double actual = -1;
                Target.Start(currentTime: TimeSpan.FromMilliseconds(400), duration: TimeSpan.FromMilliseconds(200));
                Target.OnUpdate = p => actual = p;

                Target.Update(TimeSpan.FromMilliseconds(1000));

                Assert.That(actual, Is.EqualTo(1));
            }
            [Test]
            public void FirstUpdateOverDuration_DoesNotSetExpired()
            {
                double actual = -1;
                Target.Start(currentTime: TimeSpan.FromMilliseconds(400), duration: TimeSpan.FromMilliseconds(200));
                Target.OnUpdate = p => actual = p;

                Target.Update(TimeSpan.FromMilliseconds(1000));

                Assert.That(Target.HasExpired, Is.False);
            }
            [Test]
            public void SecondUpdateOverDuration_SetsExpired()
            {
                double actual = -1;
                Target.Start(currentTime: TimeSpan.FromMilliseconds(400), duration: TimeSpan.FromMilliseconds(200));
                Target.OnUpdate = p => actual = p;

                Target.Update(TimeSpan.FromMilliseconds(1000));
                Target.Update(TimeSpan.FromMilliseconds(1000));

                Assert.That(Target.HasExpired, Is.True);
            }
        }
    }

    public class MockAction : GraveDefensor.Engine.Core.Action
    {
        public System.Action<double> OnUpdate { get; set; }
        public MockAction()
        {}

        public new void Start(System.TimeSpan currentTime, System.TimeSpan duration)
        {
            base.Start(currentTime, duration);
        }

        public override void Update(double percentage)
        {
            base.Update(percentage);
            OnUpdate?.Invoke(percentage);
        }
    }
}
