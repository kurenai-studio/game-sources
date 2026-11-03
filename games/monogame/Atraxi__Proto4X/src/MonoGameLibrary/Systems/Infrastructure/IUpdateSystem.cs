using Microsoft.Xna.Framework;
using MonoGameLibrary.Archetypes;
using System.Collections.Generic;

namespace MonoGameLibrary.Systems.Infrastructure
{
    public interface IUpdateSystem : ISystem
    {
        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks);
    }
}