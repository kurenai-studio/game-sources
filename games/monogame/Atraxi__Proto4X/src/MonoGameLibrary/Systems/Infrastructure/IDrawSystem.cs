using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameLibrary.Archetypes;
using System.Collections.Generic;

namespace MonoGameLibrary.Systems.Infrastructure
{
    public enum DrawSpace { World, Screen }
    public interface IDrawSystem : ISystem
    {
        DrawSpace DrawSpace { get; }

        void Draw(SpriteBatch spriteBatch, Rectangle viewport, List<ArchetypeChunk> archetypeChunks);
    }
}