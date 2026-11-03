using GraveDefensor.Shared.Core;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input.Touch;
using NUnit.Framework;

namespace GraveDefensor.Shared.Test.Core
{
    public class TouchStateTest
    {
        [TestFixture]
        public class Constructor: TouchStateTest
        {
            [Test]
            public void WhenLocationIsPressed_StoresLocation()
            {
                var tc = new TouchLocation(1, TouchLocationState.Pressed, Vector2.Zero);
                var collection = new TouchCollection(new[] { tc });

                var actual = new TouchState(collection, trackingId: null);

                Assert.That(actual.Position.HasValue, Is.True);
            }
        }
    }
}
