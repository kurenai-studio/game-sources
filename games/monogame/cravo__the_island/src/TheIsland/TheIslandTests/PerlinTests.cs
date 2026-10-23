using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TheIsland;

namespace TheIslandTests
{
    [TestClass]
    public class PerlinTests
    {
        [TestMethod]
        public void NoiseInRange()
        {
            var noise = new Perlin();
            Random rand = new Random();

            for(var i = 0; i < 10000; ++i)
            {
                var v = new Vector3((float)(rand.NextDouble() * 4096), (float)(rand.NextDouble() * 4096), (float)(rand.NextDouble() * 4096));
                var result = noise.Noise(v);

                Assert.IsTrue(result >= -1.0f);
                Assert.IsTrue(result <= 1.0f);
            }
        }

        [TestMethod]
        public void OctaveNoiseInRange()
        {
            var noise = new Perlin();
            Random rand = new Random();

            for (var i = 0; i < 10000; ++i)
            {
                var v = new Vector3((float)(rand.NextDouble() * 4096), (float)(rand.NextDouble() * 4096), (float)(rand.NextDouble() * 4096));
                var result = noise.OctaveNoise(v,8);

                Assert.IsTrue(result >= 0.0f);
                Assert.IsTrue(result <= 1.0f);
            }
        }
    }
}
