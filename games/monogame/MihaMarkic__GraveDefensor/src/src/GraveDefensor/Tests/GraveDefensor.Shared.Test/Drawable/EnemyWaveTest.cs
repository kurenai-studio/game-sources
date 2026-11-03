using GraveDefensor.Engine.Services.Abstract;
using GraveDefensor.Shared.Core;
using GraveDefensor.Shared.Drawable;
using GraveDefensor.Shared.Drawable.Enemies;
using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Services.Implementation;
using Microsoft.Xna.Framework;
using NSubstitute;
using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Test.Drawable
{
    public class EnemySetTest: BaseTest<EnemySet>
    {
        [DebuggerStepThrough]
        protected IInitContext GetContext()
        {
            var context = Substitute.For<IInitContext>();
            var objectPool = Substitute.For<IObjectPool>();
            objectPool.GetObject<List<Enemy>>().Returns(c => new List<Enemy>());
            objectPool.GetObject<CreepyWorm>().Returns(c => new CreepyWorm());
            objectPool.GetObject<Path>().Returns(c => new Path());
            context.ObjectPool.Returns(objectPool);
            return context;
        }
        //[DebuggerStepThrough]
        public static UpdateContext CreateUpdateContext(double elapsed)
        {

            var objectPool = Substitute.For<IObjectPool>();
            objectPool.GetObject<CreepyWorm>().Returns(c => new CreepyWorm());
            objectPool.GetObject<List<Enemy>>().Returns(c => new List<Enemy>());
            return new UpdateContext(new GameTime(default, TimeSpan.FromMilliseconds(elapsed)), default, default, default, objectPool);
        }
        [DebuggerStepThrough]
        public static Settings.Path GetPath() => new Settings.Path
        {
            Points = new Settings.Point[]
            {
                    new Settings.Point { X = 0, Y = 0 },
                    new Settings.Point { X = 100, Y = 0 },
            }
        };
        [TestFixture]
        public class Init: EnemySetTest
        {
            [Test]
            public void AfterInit_EnemiesCountIsZero()
            {
                Target.Init(GetContext(), new Settings.EnemySet
                {
                    EnemyId = nameof(Settings.CreepyWorm)
                }, new Settings.CreepyWorm(), GetPath());

                Assert.That(Target.Enemies.Count, Is.Zero);
            }
            [Test]
            public void AfterInit_CompletedEnemiesCountIsZero()
            {
                Target.Init(GetContext(), new Settings.EnemySet
                {
                    EnemyId = nameof(Settings.CreepyWorm)
                }, new Settings.CreepyWorm(), GetPath());

                Assert.That(Target.CompletedEnemies.Count, Is.Zero);
            }
        }
        [TestFixture]
        public class Update: EnemySetTest
        {
            [SetUp]
            public new void SetUp()
            {
                Target.Init(GetContext(), new Settings.EnemySet
                {
                    EnemyId = nameof(Settings.CreepyWorm),
                    StartTimeOffset = 100,
                    Interval = 50,
                    EnemiesCount = 2,
                }, new Settings.CreepyWorm { Speed = 100 }, GetPath());
            }
            [TestCase(0)]
            [TestCase(90)]
            public void WhenSpawnTimeElapsedIsWithinStartOffset_StatusIsReady(int elapsed)
            {
                Target.Update(CreateUpdateContext(elapsed));

                Assert.That(Target.Status, Is.EqualTo(EnemySetStatus.Ready));
            }
            [Test]
            public void WhenSpawnTimeElapsedIsOverStartOffset_StatusIsSpawning()
            {
                Target.Update(CreateUpdateContext(120));

                Assert.That(Target.Status, Is.EqualTo(EnemySetStatus.Spawning));
            }
            [Test]
            public void WhenSpawnTimeElapsesForSecondEnemy_EnemiesCountIsTwo()
            {
                Target.Update(CreateUpdateContext(120));
                Target.Update(CreateUpdateContext(40));

                Assert.That(Target.Enemies.Count, Is.EqualTo(2));
            }
            [Test]
            public void WhenFirstEnemyIsDone_EnemiesCountIsOneAndCompletedIsAlsoOne()
            {
                Target.Update(CreateUpdateContext(120));
                Target.Update(CreateUpdateContext(40));
                // at this point enemy traversed 40
                Target.Update(CreateUpdateContext(1100));
                // at this point enemy is finished (100 overflow just in case)
                Target.Update(CreateUpdateContext(Enemy.VisibleBeforeDone.TotalMilliseconds + 10));

                Assert.That(Target.Enemies.Count, Is.EqualTo(1));
                Assert.That(Target.CompletedEnemies.Count, Is.EqualTo(1));
            }
        }
        public class Transitions: EnemySetTest
        {
            [SetUp]
            public new void SetUp()
            {
                Target.Init(GetContext(), new Settings.EnemySet
                {
                    EnemyId = nameof(Settings.CreepyWorm),
                    StartTimeOffset = 100,
                    Interval = 50,
                    EnemiesCount = 2,
                }, new Settings.CreepyWorm(), GetPath());
            }
        }
        [TestFixture]
        public class TransitionToSpawning : Transitions
        {
            [Test]
            public void AfterCall_StatusIsSpawning()
            {
                Target.TransitionToSpawning(CreateUpdateContext(10));

                Assert.That(Target.Status, Is.EqualTo(EnemySetStatus.Spawning));
            }
            [Test]
            public void AfterCall_EnemiesCountIsOne()
            {
                Target.TransitionToSpawning(CreateUpdateContext(10));

                Assert.That(Target.Enemies.Count, Is.EqualTo(1));
            }
            [Test]
            public void WhenElapsedTimeOverflowsOffset_RelativeTimeSpanSubtractsOverflow()
            {
                Target.Update(CreateUpdateContext(80)); // relative should be 20

                Target.TransitionToSpawning(CreateUpdateContext(0));

                // in reality relative should be negative
                Assert.That(Target.RelativeSpawnTime, Is.EqualTo(TimeSpan.FromMilliseconds(20 + 50)));
            }
        }
        [TestFixture]
        public class TransitionToWaitingForFinish : Transitions
        {
            [Test]
            public void AfterCall_StatusIsFinished()
            {
                Target.TransitionToWaitingForFinish();

                Assert.That(Target.Status, Is.EqualTo(EnemySetStatus.WaitingForFinish));
            }
        }
        [TestFixture]
        public class TransitionToDone : Transitions
        {
            [Test]
            public void AfterCall_StatusIsDone()
            {
                Target.TransitionToDone();

                Assert.That(Target.Status, Is.EqualTo(EnemySetStatus.Done));
            }
        }
    }
}
