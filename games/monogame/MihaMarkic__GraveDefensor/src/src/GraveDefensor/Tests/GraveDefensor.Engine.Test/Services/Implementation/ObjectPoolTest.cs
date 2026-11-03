using GraveDefensor.Engine.Services.Implementation;
using NUnit.Framework;

namespace GraveDefensor.Engine.Test.Services.Implementation
{
    public class ObjectPoolTest: BaseTest<ObjectPool>
    {
        public class Item
        {
            public int Index { get; set; }
        }

        [TestFixture]
        public class GetObject: ObjectPoolTest
        {
            [Test]
            public void WhenEmpty_ReturnsNewInstanceOfItem()
            {
                var item = Target.GetObject<Item>();

                Assert.That(item, Is.Not.Null);
            }
            [Test]
            public void WhenNotEmpty_ReturnsExistingInstanceOfItem()
            {
                var item = Target.GetObject<Item>();
                item.Index = 1;
                Target.ReleaseObject(item);
                item = Target.GetObject<Item>();

                Assert.That(item.Index, Is.EqualTo(1));
            }
            [Test]
            public void SecondCallOnSameType_ShouldReturnNewInstance()
            {
                var first = Target.GetObject<Item>();
                var second = Target.GetObject<Item>();

                Assert.That(first, Is.Not.SameAs(second));
            }
        }
    }

    
}
