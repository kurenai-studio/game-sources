using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TheIsland
{
    // This perlin noise class is primarily based on Peter Shirley's implementation
    // found in his book, "Raytracing - The next week", which is in turn based on
    // Andrew Kensler's description of how Perlin Noise works.

    public class Perlin
    {
        Random Rand = new Random(Guid.NewGuid().GetHashCode());
        Vector3[] RanVec;
        int[] PermX;
        int[] PermY;
        int[] PermZ;

        public Perlin()
        {
            RanVec = Generate();
            PermX = GeneratePerm();
            PermY = GeneratePerm();
            PermZ = GeneratePerm();
        }

        public float Noise(Vector3 p)
        {
            int i = (int)(Math.Floor(p.X));
            int j = (int)(Math.Floor(p.Y));
            int k = (int)(Math.Floor(p.Z));

            float u = p.X - (float)i;
            float v = p.Y - (float)j;
            float w = p.Z - (float)k;

            Vector3[,,] c = new Vector3[2, 2, 2];
            for(int di = 0; di < 2; ++di)
            {
                for(int dj = 0; dj < 2; ++dj)
                {
                    for(int dk = 0; dk < 2; ++dk)
                    {
                        c[di, dj, dk] = RanVec[PermX[(i + di) & 255] ^ PermY[(j + dj) & 255] ^ PermZ[(k + dk) & 255]];
                    }
                }
            }

            return Interp(c, u, v, w);
        }

        public float OctaveNoise(Vector3 p, int octaves)
        {
            float accum = 0;
            float weight = 1.0f;

            for(var i = 0; i < octaves; ++i)
            {
                accum += weight * Noise(p);
                weight *= 0.5f;
                p *= 2.0f;
            }

            return Math.Abs(accum);
        }

        float Interp(Vector3[,,] c, float u, float v, float w)
        {
            float uu = u * u * (3.0f - 2.0f * u);
            float vv = v * v * (3.0f - 2.0f * v);
            float ww = w * w * (3.0f - 2.0f * w);

            float accum = 0;
            for(int i = 0; i < 2; ++i)
            {
                for(int j = 0; j < 2; ++j)
                {
                    for(int k = 0; k < 2; ++k)
                    {
                        Vector3 weightV = new Vector3(u - (float)i, v - (float)j, w - (float)k);
                        accum += ((float)i * uu + (1 - (float)i) * (1 - uu)) *
                                 ((float)j * vv + (1 - (float)j) * (1 - vv)) *
                                 ((float)k * ww + (1 - (float)k) * (1 - ww)) *
                                 Vector3.Dot(c[i, j, k], weightV);
                    }
                }
            }

            return accum;
        }

        Vector3 [] Generate()
        {
            var p = new Vector3[256];
            for(var i = 0; i < 256; ++i )
            {
                p[i] = new Vector3(-1.0f + 2.0f * (float)Rand.NextDouble(), -1.0f + 2.0f * (float)Rand.NextDouble(), -1.0f + 2.0f * (float)Rand.NextDouble());
                p[i].Normalize();
            }
            return p;
        }

        void Permute(ref int[] p)
        {
            var n = p.Length;

            for(var i = n - 1; i > 0; --i)
            {
                var target = (int)(Rand.NextDouble() * (i + 1));
                var tmp = p[i];
                p[i] = p[target];
                p[target] = tmp;
            }
        }

        int [] GeneratePerm()
        {
            var p = new int[256];
            for(var i = 0; i < 256; ++i)
            {
                p[i] = i;
            }

            Permute(ref p);

            return p;
        }
    }
}
