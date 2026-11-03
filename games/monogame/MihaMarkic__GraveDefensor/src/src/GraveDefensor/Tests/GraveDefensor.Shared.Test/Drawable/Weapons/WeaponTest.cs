using GraveDefensor.Shared.Drawable;
using GraveDefensor.Shared.Drawable.Enemies;
using GraveDefensor.Shared.Drawable.Weapons;
using GraveDefensor.Shared.Service.Abstract;
using Microsoft.Xna.Framework;
using NSubstitute;
using NUnit.Framework;
using System.Collections.Generic;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Test.Drawable.Weapons
{
    public class WeaponTest : BaseTest<Weapon<MockWeaponSettings>>
    {
        [TestFixture]
        public class GetEnemiesInRange: WeaponTest
        {
            [Test]
            public void WhenNoEnemies_NoEnemiesAreReturned()
            {
                var enemiesInTrackingRange = new List<Enemy>();
                var enemiesInFiringRange = new List<Enemy>();

                var wave1 = Substitute.For<IEnemySet>();
                wave1.Status.Returns(EnemySetStatus.Spawning);
                wave1.Enemies.Returns(new List<Enemy>());

                Weapon<MockWeaponSettings>.GetEnemiesInRange(new Vector2(0, 0), new IEnemySet[] { wave1 }, 12, 17, enemiesInTrackingRange, enemiesInFiringRange);

                Assert.That(enemiesInTrackingRange.Count, Is.Zero);
                Assert.That(enemiesInFiringRange.Count, Is.Zero);
            }
            [Test]
            public void WhenSingleEnemyOutOfTrackingRange_NoEnemiesAreReturned()
            {
                var enemiesInTrackingRange = new List<Enemy>();
                var enemiesInFiringRange = new List<Enemy>();

                var wave1 = Substitute.For<IEnemySet>();
                wave1.Status.Returns(EnemySetStatus.Spawning);
                wave1.Enemies.Returns(new List<Enemy> { new MockEnemy(30, 0) });

                Weapon<MockWeaponSettings>.GetEnemiesInRange(new Vector2(0, 0), new IEnemySet[] { wave1 }, 12, 17, enemiesInTrackingRange, enemiesInFiringRange);

                Assert.That(enemiesInTrackingRange.Count, Is.Zero);
                Assert.That(enemiesInFiringRange.Count, Is.Zero);
            }
            [Test]
            public void WhenSingleEnemyInTrackingButOutOfFiringRange_OnlyTrackingListContainsIt()
            {
                var enemiesInTrackingRange = new List<Enemy>();
                var enemiesInFiringRange = new List<Enemy>();

                var wave1 = Substitute.For<IEnemySet>();
                wave1.Status.Returns(EnemySetStatus.Spawning);
                wave1.Enemies.Returns(new List<Enemy> { new MockEnemy(15, 0) });

                Weapon<MockWeaponSettings>.GetEnemiesInRange(new Vector2(0, 0), new IEnemySet[] { wave1 }, 17, 12, enemiesInTrackingRange, enemiesInFiringRange);

                Assert.That(enemiesInTrackingRange.Count, Is.EqualTo(1));
                Assert.That(enemiesInFiringRange.Count, Is.Zero);
            }
            [Test]
            public void WhenSingleEnemyInFiringRange_BothTrackingAndFiringContainsIt()
            {
                var enemiesInTrackingRange = new List<Enemy>();
                var enemiesInFiringRange = new List<Enemy>();

                var wave1 = Substitute.For<IEnemySet>();
                wave1.Status.Returns(EnemySetStatus.Spawning);
                wave1.Enemies.Returns(new List<Enemy> { new MockEnemy(10, 0) });

                Weapon<MockWeaponSettings>.GetEnemiesInRange(new Vector2(0, 0), new IEnemySet[] { wave1 }, 17, 12, enemiesInTrackingRange, enemiesInFiringRange);

                Assert.That(enemiesInTrackingRange.Count, Is.EqualTo(1));
                Assert.That(enemiesInFiringRange.Count, Is.EqualTo(1));
            }
            [Test]
            public void WhenOneEnemyInFiringAndOtherInTrackingRange_NoEnemiesAreReturned()
            {
                var enemiesInTrackingRange = new List<Enemy>();
                var enemiesInFiringRange = new List<Enemy>();

                var wave1 = Substitute.For<IEnemySet>();
                wave1.Status.Returns(EnemySetStatus.Spawning);
                wave1.Enemies.Returns(new List<Enemy> { new MockEnemy(10, 0), new MockEnemy(15, 0) });

                Weapon<MockWeaponSettings>.GetEnemiesInRange(new Vector2(0, 0), new IEnemySet[] { wave1 }, 17, 12, enemiesInTrackingRange, enemiesInFiringRange);

                Assert.That(enemiesInTrackingRange.Count, Is.EqualTo(2));
                Assert.That(enemiesInFiringRange.Count, Is.EqualTo(1));
            }
        }
        [TestFixture]
        public class GetEnemyMostNearTheEndAndInTrackingRange: WeaponTest
        {
            [Test]
            public void WhenNoEnemies_NullIsReturned()
            {
                var enemySet = Substitute.For<IEnemySet>();
                enemySet.Status.Returns(EnemySetStatus.Spawning);
                enemySet.Enemies.Returns(new List<Enemy> ());

                var actual = Weapon<MockWeaponSettings>.GetEnemyMostNearTheEndAndInTrackingRange(Vector2.Zero, new IEnemySet[] { enemySet }, 17, 12);

                Assert.That(actual.HasValue, Is.False);
            }
            [Test]
            public void WhenSingleEnemyOutOfTrackingRange_NullIsReturned()
            {
                var enemySet = Substitute.For<IEnemySet>();
                enemySet.Status.Returns(EnemySetStatus.Spawning);
                enemySet.Enemies.Returns(new List<Enemy> { new MockEnemy(30, 0) });

                var actual = Weapon<MockWeaponSettings>.GetEnemyMostNearTheEndAndInTrackingRange(Vector2.Zero, new IEnemySet[] { enemySet }, 17, 12);

                Assert.That(actual.HasValue, Is.False);
            }
            [Test]
            public void WhenSingleEnemyInTrackingButNotFiringRange_EnemyIsReturned()
            {
                var enemySet = Substitute.For<IEnemySet>();
                enemySet.Status.Returns(EnemySetStatus.Spawning);
                enemySet.Enemies.Returns(new List<Enemy> { new MockEnemy(15, 0) });

                var actual = Weapon<MockWeaponSettings>.GetEnemyMostNearTheEndAndInTrackingRange(Vector2.Zero, new IEnemySet[] { enemySet }, 17, 12);

                Assert.That(actual.Value.Enemy, Is.Not.Null);
            }
            [Test]
            public void WhenSingleEnemyInTrackingButNotFiringRange_NotInFiringRangeIsReturned()
            {
                var enemySet = Substitute.For<IEnemySet>();
                enemySet.Status.Returns(EnemySetStatus.Spawning);
                enemySet.Enemies.Returns(new List<Enemy> { new MockEnemy(15, 0) });

                var actual = Weapon<MockWeaponSettings>.GetEnemyMostNearTheEndAndInTrackingRange(Vector2.Zero, new IEnemySet[] { enemySet }, 17, 12);

                Assert.That(actual.Value.IsInFiringRange, Is.False);
            }
            [Test]
            public void WhenSingleEnemyInFiringRange_EnemyIsReturned()
            {
                var enemySet = Substitute.For<IEnemySet>();
                enemySet.Status.Returns(EnemySetStatus.Spawning);
                enemySet.Enemies.Returns(new List<Enemy> { new MockEnemy(10, 0) });

                var actual = Weapon<MockWeaponSettings>.GetEnemyMostNearTheEndAndInTrackingRange(Vector2.Zero, new IEnemySet[] { enemySet }, 17, 12);

                Assert.That(actual.Value.Enemy, Is.Not.Null);
            }
            [Test]
            public void WhenSingleEnemyInFiringRange_InFiringRangeIsReturned()
            {
                var enemySet = Substitute.For<IEnemySet>();
                enemySet.Status.Returns(EnemySetStatus.Spawning);
                enemySet.Enemies.Returns(new List<Enemy> { new MockEnemy(10, 0) });

                var actual = Weapon<MockWeaponSettings>.GetEnemyMostNearTheEndAndInTrackingRange(Vector2.Zero, new IEnemySet[] { enemySet }, 17, 12);

                Assert.That(actual.Value.IsInFiringRange, Is.True);
            }
            [Test]
            public void WhenTwoEnemiesInTrackingRange_NearestToEndIsReturned()
            {
                var wave1 = Substitute.For<IEnemySet>();
                wave1.Status.Returns(EnemySetStatus.Spawning);
                MockEnemy first = new MockEnemy(10, 0, 100);
                MockEnemy second = new MockEnemy(15, 0, 50);
                wave1.Enemies.Returns(new List<Enemy> {
                    first,
                    second
                });

                var actual = Weapon<MockWeaponSettings>.GetEnemyMostNearTheEndAndInTrackingRange(Vector2.Zero, new IEnemySet[] { wave1 }, 17, 12);
            
                Assert.That(actual.Value.Enemy, Is.SameAs(second));
            }
            [TestCase(EnemyStatus.Done)]
            [TestCase(EnemyStatus.Finished)]
            [TestCase(EnemyStatus.Killed)]
            public void WhenEnemyIsNotLive_NullIsReturned(EnemyStatus enemyStatus)
            {
                var wave1 = Substitute.For<IEnemySet>();
                wave1.Status.Returns(EnemySetStatus.Spawning);
                MockEnemy first = new MockEnemy(10, 0, 100, enemyStatus);
                wave1.Enemies.Returns(new List<Enemy> {
                    first
                });

                var actual = Weapon<MockWeaponSettings>.GetEnemyMostNearTheEndAndInTrackingRange(Vector2.Zero, new IEnemySet[] { wave1 }, 17, 12);

                Assert.That(actual.HasValue, Is.False);
            }
        }
    }
    public class MockEnemySet: EnemySet
    {

    }
    public class MockEnemy: Enemy
    {
        public MockEnemy(float x, float y, double distanceToEnd = 0, EnemyStatus status = EnemyStatus.Walking)
        {
            Center = new Vector2(x, y);
            DistanceToEnd = distanceToEnd;
            Status = status;
        }
    }
    public class MockWeapon : Weapon<MockWeaponSettings>
    {
        public override void DrawContent(IDrawContext context)
        {
            throw new System.NotImplementedException();
        }

        internal override void DrawHud(IDrawContext context)
        {
            throw new System.NotImplementedException();
        }
    }
    public class MockWeaponSettings : Settings.Weapon
    {

    }
}
