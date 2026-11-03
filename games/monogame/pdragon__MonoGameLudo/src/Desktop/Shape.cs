using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Desktop
{
    public static  class Shape
    {
        public static bool CheckCollisionPointRec(Point point, Rectangle rect)
        {
            return rect.Contains(point);
        }
    }
}
