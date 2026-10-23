using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TheIsland
{
    public class MapData
    {
        public float Height { get; private set; }

        public MapData(float height)
        {
            Height = height;
        }
    }
}
