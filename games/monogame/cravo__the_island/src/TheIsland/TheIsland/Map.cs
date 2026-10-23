using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace TheIsland
{
    public class Map
    {
        public int Width { get; private set; }
        public int Height { get; private set; }
        public float GenerationProgress { get; private set; }
        public bool Generated { get; private set; }
        MapData[,] Data;
        Random Rand = new Random();
        Perlin Noise;
        float Radius;

        class GenData
        {
            public Rectangle Area;
            public bool Generated;

            public GenData(Rectangle area)
            {
                Area = area;
                Generated = false;
            }
        }

        public Map(int width, int height)
        {
            Width = width;
            Height = height;
            GenerationProgress = 0;
            Generated = false;
        }

        public void BeginGeneration()
        {
            ThreadPool.QueueUserWorkItem(Generate, null);
        }

        public MapData GetMapDataAt(int x, int y)
        {
            return Data[x, y];
        }

        void Generate(object o)
        {
            Radius = (float)Height / 2.0f;

            Generated = false;

            Data = new MapData[Width, Height];
            Noise = new Perlin();

            List<GenData> genData = new List<GenData>();

            int cellSize = 8;
            for(int y = 0; y < Height; y += cellSize)
            {
                for(int x = 0; x < Width; x += cellSize)
                {
                    genData.Add(new GenData(new Rectangle(x, y, cellSize, cellSize)));
                }
            }

            foreach(GenData data in genData)
            {
                ThreadPool.QueueUserWorkItem(GenerateRegion, data);
            }

            int numGenerated = 0;
            do
            {
                numGenerated = 0;
                foreach (GenData d in genData)
                {
                    if (d.Generated)
                    {
                        numGenerated++;
                    }
                }

                GenerationProgress = (float)numGenerated / (float)genData.Count;

            } while (numGenerated < genData.Count);

            GenerationProgress = 1.0f;
            Generated = true;
        }

        private void GenerateRegion(object o)
        {
            GenData genData = o as GenData;

            for(int y = genData.Area.Top; y < genData.Area.Bottom;++y)
            {
                for(int x = genData.Area.Left; x < genData.Area.Right; ++x)
                {
                    float height = GenerateHeight(x, y);

                    Data[x, y] = new MapData(height);
                }
            }

            genData.Generated = true;
        }

        // from https://en.wikipedia.org/wiki/Smoothstep
        private float smootherstep(float edge0, float edge1, float x)
        {
            // Scale, and clamp x to 0..1 range
            x = MathHelper.Clamp((x - edge0) / (edge1 - edge0), 0.0f, 1.0f);
            // Evaluate polynomial
            return x * x * x * (x * (x * 6 - 15) + 10);
        }

        private float GenerateHeight(int x, int y)
        {
            float scale = 2.0f;
            float height = Noise.OctaveNoise(scale * new Microsoft.Xna.Framework.Vector3((float)x / (float)Width, (float)y / (float)Height, 0), 8);

            float dx = (Width / 2) - x;
            float dy = (Height / 2) - y;

            float dist = (float)Math.Sqrt(dx * dx + dy * dy);

            //float maxHeight = (dist / (float)(Width/2));
            float maxHeight = smootherstep(1.0f, 0.0f, dist / Radius);

            height *= maxHeight;

            return height;
        }
    }
}
