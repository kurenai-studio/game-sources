using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using System.Collections.Generic;

namespace MonoGameLibrary.Systems
{
    public class Renderer : IDrawSystem
    {
        public DrawSpace DrawSpace => DrawSpace.World;

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => [ComponentRef.Of<Position>(), ComponentRef.Of<Drawable>()];

        public void Draw(SpriteBatch spriteBatch, Rectangle cullingBounds, List<ArchetypeChunk> archetypeChunks)
        {
            foreach(var archetypeChunk in archetypeChunks)
            {
                for (var entityIndex = 0; entityIndex < archetypeChunk.EntityCount; entityIndex++)
                {
                    ref var drawable = ref archetypeChunk.Get<Drawable>(entityIndex);
                    ref var position = ref archetypeChunk.Get<Position>(entityIndex);

                    //if(!cullingBounds.Contains(position.Location))
                    //{
                    //    continue;
                    //}
                    var sprite = SpriteLibrary.GetTexture(drawable.SpriteId);
                    spriteBatch.Draw(sprite, position.Location, drawable.TextureRegion, Color.White, position.Rotation, new Vector2(sprite.Width / 2, sprite.Height / 2), 1, SpriteEffects.None, 1);
                }
            }
        }
    }
}