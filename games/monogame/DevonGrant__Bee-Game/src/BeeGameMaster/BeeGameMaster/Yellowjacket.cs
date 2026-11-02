using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace BeeGameMaster
{
    class Yellowjacket : Enemy, Dies
    {
        public Yellowjacket(Texture2D newTexture, int x, int y, int wHeight, Color newColor, int newSpeed) : base(newTexture, x, y, wHeight, newColor, 5)
        {
            Speed = newSpeed;
            Rect = new Rectangle(x, y, Texture.Width / 2, Texture.Height / 2);
        }
    }
}
