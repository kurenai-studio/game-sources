using Microsoft.Xna.Framework;
using MonoGameLibrary.Components.Infrastructure;
using System;

namespace MonoGameLibrary.Components
{
    public struct Drawable(int spriteId, Rectangle? textureRegion) : IDependsOnOtherComponents
    {
        public int SpriteId { get; set; } = spriteId;
        public Rectangle? TextureRegion { get; set; } = textureRegion;

        public readonly Type[] GetComponentDependencies => [typeof(Position)];
    }
}
