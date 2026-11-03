using GraveDefensor.Shared.Drawable.Scenes;
using Microsoft.Xna.Framework;
using NUnit.Framework;

namespace GraveDefensor.Shared.Test.Scenes
{
    public class BattleSceneTest: BaseTest<BattleScene>
    {
        [TestFixture]
        public class GetDialogTopLeft: BattleSceneTest
        {
            [Test]
            public void WhenViewIsNotOffsetAndPodIsOnLeft_ReturnsPodTopRight()
            {
                var actual = BattleScene.GetDialogTopLeft(
                    new Rectangle(0, 0, 32, 32),
                    view: new Rectangle(0, 0, 200, 150),
                    dialogSize: new Point(50, 80)
                    );

                Assert.That(actual, Is.EqualTo(new Point(32, 0)));
            }
            [Test]
            public void WhenViewIsNotOffsetAndPodIsOnRight_ReturnsPodTopLeftMinusDialogWidth()
            {
                var actual = BattleScene.GetDialogTopLeft(
                    new Rectangle(200 - 32, 0, 32, 32),
                    view: new Rectangle(0, 0, 200, 150),
                    dialogSize: new Point(50, 80)
                    );

                Assert.That(actual, Is.EqualTo(new Point(200 - 32 - 50, 0)));
            }
            [Test]
            public void WhenOffsetIsNotZeroAndPodIsOnRight_TakesIntoAccountOffset()
            {
                var actual = BattleScene.GetDialogTopLeft(
                    new Rectangle(200-32, 0, 32, 32),
                    view: new Rectangle(100, 0, 300, 150),
                    dialogSize: new Point(50, 80)
                    );

                Assert.That(actual, Is.EqualTo(new Point(200, 0)));
            }
        }
    }
}
