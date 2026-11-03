using Microsoft.Xna.Framework.Graphics;
using System.Collections.Generic;

namespace MonoGameLibrary
{
    public static class SpriteLibrary
    {
        private static readonly List<Texture2D> textures = [];

        public static int Add(Texture2D newTexture)
        {
            var index = textures.Count;
            textures.Add(newTexture);
            return index;
        }

        public static Texture2D GetTexture(int index)
            => textures[index];
    }
}