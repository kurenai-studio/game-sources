using GraveDefensor.Shared.Core;
using GraveDefensor.Shared.Drawable.Enemies;
using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Services.Implementation;
using Microsoft.Xna.Framework;
using NSubstitute;
using NUnit.Framework;
using System;
using System.Diagnostics;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Test.Drawable
{
    public class EnemyTest: BaseTest<MockEnemy>
    {

        [TestFixture]
        public class Init: EnemyTest
        {
            [Test]
            public void AfterInit_StatusIsReady()
            {
                var path = new Path();
                path.Init(new Settings.Path
                {
                    Points = new Settings.Point[]
                    {
                            new Settings.Point { X = 0, Y = 0},
                            new Settings.Point { X = 100, Y = 0},
                    }
                });
                Target.Init(Substitute.For<IInitContext>(),
                new MockEnemySettings
                {
                    Name = "Enemy",
                    Speed = 40
                }, path
                );

                Assert.That(Target.Status, Is.EqualTo(EnemyStatus.Ready));
            }
        }
        [TestFixture]
        public class Start: EnemyTest
        {
            [SetUp]
            public new void SetUp()
            {
                var path = new Path();
                path.Init(new Settings.Path
                {
                    Points = new Settings.Point[]
                        {
                            new Settings.Point { X = 0, Y = 0},
                            new Settings.Point { X = 100, Y = 0},
                            new Settings.Point { X = 120, Y = 20},
                            new Settings.Point { X = 120, Y = 50}
                        }
                });
                Target.Init(Substitute.For<IInitContext>(),
                    new MockEnemySettings
                    {
                        Name = "Enemy",
                        Speed = 40
                    }, path);
                base.SetUp();
            }
            [Test]
            public void AfterStart_StatusIsWalking()
            {
                Target.Start();

                Assert.That(Target.Status, Is.EqualTo(EnemyStatus.Walking));
            }
            [Test]
            public void AfterStart_LastPointIsZero()
            {
                Target.Start();

                Assert.That(Target.LastPoint, Is.Zero);
            }
            [Test]
            public void AfterStart_SegmentLengthIsCorrect()
            {
                Target.Start();

                Assert.That(Target.SegmentLength, Is.EqualTo(100));
            }
            [Test]
            public void AfterStart_AngleIsCorrect()
            {
                Target.Start();

                Assert.That(Target.Angle, Is.Zero);
            }
        }
        [TestFixture]
        public class Update: EnemyTest
        {
            [SetUp]
            public new void SetUp()
            {
                var path = new Path();
                path.Init(new Settings.Path
                {
                    Points = new Settings.Point[]
                        {
                            new Settings.Point { X = 0, Y = 0},
                            new Settings.Point { X = 100, Y = 0},   // length is 100
                            new Settings.Point { X = 110, Y = 10},  // length is Sqrt(200)
                            new Settings.Point { X = 110, Y = 40}   // length is 30
                        }
                });
                Target.Init(Substitute.For<IInitContext>(),
                    new MockEnemySettings
                    {
                        Name = "Enemy",
                        Speed = 1000
                    }, path);
                base.SetUp();
            }
            [DebuggerStepThrough]
            public static UpdateContext CreateUpdateContext(int elapsed)
            {
                return new UpdateContext(new GameTime(default, TimeSpan.FromMilliseconds(elapsed)), default, default, default, null);
            }
            
            [Test]
            public void WhenNotActiveAndUpdate_CenterIsZero()
            {
                Target.Update(CreateUpdateContext(2));

                Assert.That(Target.Center, Is.EqualTo(Vector2.Zero));
            }
            [Test]
            public void WhenHalfWay_CenterIsHalf()
            {
                Target.Start();

                Target.Update(CreateUpdateContext(50));

                Assert.That(Target.Center, Is.EqualTo(new Vector2(50, 0)));
            }
            [Test]
            public void WhenNextSegmentHalfWay_CenterIsHalfOfNextSegment()
            {
                Target.Start();
                Target.Update(CreateUpdateContext(50));

                Target.Update(CreateUpdateContext(50 + 10));

                float pos = 10 / (float)Math.Sqrt(200);

                Assert.That(Target.Center, Is.EqualTo(new Vector2(100 + 10 * pos, 10 * pos)));
            }
            [Test]
            public void WhenOnNextSegment_AngleIsCorrect()
            {
                Target.Start();

                Target.Update(CreateUpdateContext(110));

                float pos = 10 / (float)Math.Sqrt(200);

                Assert.That(Target.Angle, Is.EqualTo((float)(Math.PI / 4)));
            }
            [Test]
            public void WhenDoneLastSegment_StateIsFinished()
            {
                Target.Start();
                Target.Update(CreateUpdateContext(50));
                Target.Update(CreateUpdateContext((int)(50 + Math.Sqrt(200)/2)));
                Target.Update(CreateUpdateContext((int)(Math.Sqrt(200) / 2 + 15)));

                Target.Update(CreateUpdateContext(20));

                Assert.That(Target.Status, Is.EqualTo(EnemyStatus.Finished));
            }
        }
        [TestFixture]
        public class TransitionToKilled: EnemyTest
        {
            [SetUp]
            public new void SetUp()
            {
                var path = new Path();
                path.Init(new Settings.Path
                {
                    Points = new Settings.Point[]
                        {
                            new Settings.Point { X = 0, Y = 0},
                            new Settings.Point { X = 100, Y = 0},   // length is 100
                            new Settings.Point { X = 110, Y = 10},  // length is Sqrt(200)
                            new Settings.Point { X = 110, Y = 40}   // length is 30
                        }
                });
                Target.Init(Substitute.For<IInitContext>(),
                    new MockEnemySettings
                    {
                        Name = "Enemy",
                        Speed = 1000
                    }, path);
                base.SetUp();
            }
            [Test]
            public void AfterTransition_StateIsKilled()
            {
                Target.TransitionToKilled();

                Assert.That(Target.Status, Is.EqualTo(EnemyStatus.Killed));
            }
            [Test]
            public void AfterTransition_KilledStatusSpanIsVisibleKilledBeforeDone()
            {
                Target.TransitionToKilled();

                Assert.That(Target.KilledStatusSpan, Is.EqualTo(Enemy.VisibleKilledBeforeDone));
            }
        }

        [TestFixture]
        public class DistanceToEnd : EnemyTest
        {
            [SetUp]
            public new void SetUp()
            {
                var path = new Path();
                path.Init(new Settings.Path
                {
                    Points = new Settings.Point[]
                    {
                        new Settings.Point {  X = 0, Y = 0},
                        new Settings.Point { X = 100, Y = 0 },
                        new Settings.Point { X = 103, Y = 4 },
                        new Settings.Point { X = 103, Y = 10 }
                    }
                });
                Target.Init(Substitute.For<IInitContext>(),
                    new MockEnemySettings
                    {
                        Name = "Enemy",
                        Speed = 1000
                    }, path);
                base.SetUp();
            }
            [DebuggerStepThrough]
            public static UpdateContext CreateUpdateContext(int elapsed)
            {
                return new UpdateContext(new GameTime(default, TimeSpan.FromMilliseconds(elapsed)), default, default, default, null);
            }
            [Test]
            public void WhenHalfDoneFirstSegment_ReturnsCorrectValue()
            {
                Target.Start();
                Target.Update(CreateUpdateContext(50));

                var actual = Target.DistanceToEnd;

                Assert.That(actual, Is.EqualTo(50 + 5 + 6).Within(0.001));
            }
        }
    }

    public  class MockEnemy: Enemy
    {

    }

    public class MockEnemySettings: Settings.Enemy
    {

    }
}
