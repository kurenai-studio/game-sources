using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Escapeaway.Source.Graphics;
using Microsoft.Xna.Framework.Graphics;

namespace Escapeaway.Source.Objects.Level.Rooms
{
    internal class RoomGround
    {
        public List<StaticSprite> sprites = new List<StaticSprite>();
        public List<int> Y = new List<int>();

        public RoomGround(List<StaticSprite> sprites)
        {
            this.sprites = sprites;

            foreach (var sprite in sprites) Y.Add(sprite.GetDestRect().Y);
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            foreach (StaticSprite sprite in sprites) sprite.Draw(spriteBatch);
        }
    }
}
