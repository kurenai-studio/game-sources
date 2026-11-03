using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Components;
using Proto4X.Sandbox.Game;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Rendering
{
    /// <summary>
    /// Draws the beam between each shooter and whatever CombatSystem decided it was shooting this
    /// frame. Nothing is simulated here - <c>Weapon.FiringAt</c> is already the answer.
    /// </summary>
    public class WeaponBeamRenderer(Texture2D pixel) : ISystem, IDrawSystem
    {
        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Position>(), ComponentRef.Of<Faction>(), ComponentRef.Of<Weapon>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public DrawSpace DrawSpace => DrawSpace.World;

        public void Draw(SpriteBatch spriteBatch, Rectangle cullingBounds, List<ArchetypeChunk> archetypeChunks)
        {
            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var weaponSpan = archetypeChunk.GetSpan<Weapon>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (weaponSpan[i].FiringAt is not Vector2 target)
                    {
                        continue;
                    }

                    Primitives.DrawLine(
                        spriteBatch,
                        pixel,
                        positionSpan[i].Location,
                        target,
                        SpriteSet.FactionColour(factionSpan[i].Id),
                        thickness: 1.5f);
                }
            }
        }
    }
}
