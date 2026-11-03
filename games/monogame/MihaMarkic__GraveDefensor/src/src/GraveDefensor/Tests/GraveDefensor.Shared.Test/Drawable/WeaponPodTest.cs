using GraveDefensor.Engine.Settings;
using Microsoft.Xna.Framework;
using NUnit.Framework;

namespace GraveDefensor.Shared.Test.Drawable
{
    public class WeaponPodTest: BaseTest<Shared.Drawable.WeaponPod>
    {
        [TestFixture]
        public class Init: WeaponPodTest
        {
            [Test]
            public void CalculatesCenterCorrectly()
            {
                Target.Init(
                    new WeaponPod
                    {
                        Center = new Engine.Settings.Point {  X = 50, Y = 50 },
                        Size = new Size { Width = 40, Height = 45 }
                    });

                Assert.That(Target.Center, Is.EqualTo(new Vector2(50, 50)));
            }
            [Test]
            public void CalculatesBoundsCorrectly()
            {
                Target.Init(
                    new WeaponPod
                    {
                        Center = new Engine.Settings.Point { X = 50, Y = 50 },
                        Size = new Size { Width = 40, Height = 30 }
                    });

                Assert.That(Target.Bounds, Is.EqualTo(new Rectangle(30, 35, 40, 30)));
            }
        }
    }
}
