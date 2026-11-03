using GraveDefensor.Engine.Services.Abstract;
using GraveDefensor.Shared.Drawable;
using GraveDefensor.Shared.Drawable.Scenes;
using GraveDefensor.Shared.Drawable.Weapons;
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
    public class BattleSceneTest: BaseTest<BattleScene>
    {
        [DebuggerStepThrough]
        protected IInitContext GetContext()
        {
            var context = Substitute.For<IInitContext>();
            var objectPool = Substitute.For<IObjectPool>();
            objectPool.GetObject<EnemyWave>().Returns(c => new EnemyWave());
            context.ObjectPool.Returns(objectPool);
            return context;
        }
        public static UpdateContext CreateUpdateContext(double elapsed)
        {
            var objectPool = Substitute.For<IObjectPool>();
            return new UpdateContext(new GameTime(default, TimeSpan.FromMilliseconds(elapsed)), default, default, default, objectPool);
        }
        [TestFixture]
        public class Init: BattleSceneTest
        {
            [Test]
            public void AfterInit_FirstWaveIsCurrent()
            {
                Target.Init(GetContext(),
                        new Settings.Battle
                        {
                            Waves = new Settings.EnemyWave[]
                            {
                                new Settings.EnemyWave
                                {
                                    Id = "First",
                                    Sets = new Settings.EnemySet[0],
                                    TimeOffsetToPrevious = 0
                                },
                                new Settings.EnemyWave
                                {
                                    Id = "Second",
                                    Sets = new Settings.EnemySet[0],
                                    TimeOffsetToPrevious = 0
                                }
                            },
                            WeaponPlaces = new Settings.WeaponPod[0]
                        },
                        new Settings.Enemies(),
                        new Settings.Weapon[0],
                        new Settings.Size { Width = 100, Height = 200 }
                );

                Assert.That(Target.CurrentWave, Is.SameAs(Target.Waves[0]));
            }
        }

        [TestFixture]
        public class UpdateEnemyWaves : BattleSceneTest
        {
            [Test]
            public void IfCurrentWaveStatusIsNotDone_NewStatusIsNullAndNextWaveIsFalse()
            {
                var currentWave = Substitute.For<IEnemyWave>();
                currentWave.Status.Returns(EnemyWaveStatus.Spawning);
                var nextWave = Substitute.For<IEnemyWave>();
                nextWave.Status.Returns(EnemyWaveStatus.Ready);
                var waves = new IEnemyWave[] { currentWave, nextWave };

                var actual = BattleScene.UpdateEnemyWaves(new UpdateContext(), currentWaveIndex: 0, currentWave, waves);

                Assert.That(actual.NewStatus.HasValue, Is.False);
                Assert.That(actual.IsNextWave, Is.False);
            }
            [Test]
            public void IfCurrentWaveStatusIsDoneAndThereIsNoNextWave_NewStatusIsFinishingAndNextWaveIsFalse()
            {
                var currentWave = Substitute.For<IEnemyWave>();
                currentWave.Status.Returns(EnemyWaveStatus.Done);
                var waves = new IEnemyWave[] { currentWave };

                var actual = BattleScene.UpdateEnemyWaves(new UpdateContext(), currentWaveIndex: 0, currentWave, waves);

                Assert.That(actual.NewStatus, Is.EqualTo(BattleSceneStatus.Finishing));
                Assert.That(actual.IsNextWave, Is.False);
            }
            [Test]
            public void IfCurrentWaveStatusIsDoneAndThereIsNextWave_NewStatusIsNullAndNextWaveIsTrue()
            {
                var currentWave = Substitute.For<IEnemyWave>();
                currentWave.Status.Returns(EnemyWaveStatus.Done);
                var nextWave = Substitute.For<IEnemyWave>();
                nextWave.Status.Returns(EnemyWaveStatus.Ready);
                var waves = new IEnemyWave[] { currentWave, nextWave };

                var actual = BattleScene.UpdateEnemyWaves(new UpdateContext(), currentWaveIndex: 0, currentWave, waves);

                Assert.That(actual.NewStatus.HasValue, Is.False);
                Assert.That(actual.IsNextWave, Is.True);
            }
        }
        [TestFixture]
        public class UpdateActiveDialog : BattleSceneTest
        {
            [Test]
            public void WhenActiveDialogIsNull_ReturnsFalse()
            {
                var actual = BattleScene.UpdateActiveDialog(new UpdateContext(), new UpdateContext(), 0, activeDialog: null);

                Assert.That(actual, Is.False);
            }
            [Test]
            public void WhenActiveDialogIsNotClosing_ReturnsFalse()
            {
                var activeDialog = new MockDialog();
                var actual = BattleScene.UpdateActiveDialog(new UpdateContext(), new UpdateContext(), 0, activeDialog);

                Assert.That(actual, Is.False);
            }
            [Test]
            public void WhenActiveDialogIsClosing_ReturnsTrue()
            {
                var activeDialog = new MockDialog();
                activeDialog.Close();
                var actual = BattleScene.UpdateActiveDialog(CreateUpdateContext(0), new UpdateContext(), 0, activeDialog);

                Assert.That(actual, Is.True);
            }
        }
        [TestFixture]
        public class UpdateWeaponPods : BattleSceneTest
        {
            [Test]
            public void WhenNoWeaponPods_ReturnsNull()
            {
                var enemyWave = Substitute.For<IEnemyWave>();

                var actual = BattleScene.UpdateWeaponPods(CreateUpdateContext(0), new IWeaponPod[0], enemyWave, canEntityClick: true);

                Assert.That(actual, Is.Null);
            }
            [Test]
            public void WhenSinglePodAndCanClickAndPodClickedAndNoWeaponAssigned_ReturnsIt()
            {
                var enemyWave = Substitute.For<IEnemyWave>();
                var pod = Substitute.For<IWeaponPod>();
                pod.ClickState.Returns(ClickState.Clicked);
                pod.Weapon.Returns((IWeapon)null);

                var actual = BattleScene.UpdateWeaponPods(CreateUpdateContext(0), new IWeaponPod[] { pod }, enemyWave, canEntityClick: true);

                Assert.That(actual, Is.SameAs(pod)); 
            }
            [TestCase(ClickState.Clicked, false)]
            [TestCase(ClickState.None, true)]
            [TestCase(ClickState.Pressed, true)]
            public void WhenSinglePod_ReturnsNull(ClickState clickState, bool canEntityClick)
            {
                var enemyWave = Substitute.For<IEnemyWave>();
                var pod = Substitute.For<IWeaponPod>();
                pod.ClickState.Returns(clickState);
                pod.Weapon.Returns((IWeapon)null);

                var actual = BattleScene.UpdateWeaponPods(CreateUpdateContext(0), new IWeaponPod[] { pod }, enemyWave, canEntityClick: canEntityClick);

                Assert.That(actual, Is.Null);
            }
            [Test]
            public void WhenSinglePodAndCanClickAndPodClickedButWeaponAssigned_ReturnsNull()
            {
                var enemyWave = Substitute.For<IEnemyWave>();
                var pod = Substitute.For<IWeaponPod>();
                pod.ClickState.Returns(ClickState.Clicked);
                pod.Weapon.Returns(Substitute.For<IWeapon>());

                var actual = BattleScene.UpdateWeaponPods(CreateUpdateContext(0), new IWeaponPod[] { pod }, enemyWave, canEntityClick: true);

                Assert.That(actual, Is.Null);
            }
        }
    }
    public class MockDialog : Dialog
    {
        internal override void DrawContent(IDrawContext context)
        {}
    }
}
