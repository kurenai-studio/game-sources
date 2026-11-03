using Microsoft.Xna.Framework;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Components;
using System;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Systems
{
    /// <summary>
    /// Counts each faction's ships once per frame, for the HUD and for the enemy AI's build
    /// decisions. Mobile + armable is the definition of "ship" here: stations have a Weapon but no
    /// Motion, so they fall out of the query on their own.
    /// </summary>
    public class FleetCensusSystem : ISystem, IUpdateSystem
    {
        private readonly int[] minerCounts = new int[Enum.GetValues<FactionId>().Length];
        private readonly int[] fighterCounts = new int[Enum.GetValues<FactionId>().Length];

        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Position>(), ComponentRef.Of<Motion>(), ComponentRef.Of<Faction>(), ComponentRef.Of<Weapon>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public int MinersFor(FactionId faction) => minerCounts[(int)faction];

        public int FightersFor(FactionId faction) => fighterCounts[(int)faction];

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            Array.Clear(minerCounts);
            Array.Clear(fighterCounts);

            foreach (var archetypeChunk in archetypeChunks)
            {
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var weaponSpan = archetypeChunk.GetSpan<Weapon>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    var faction = (int)factionSpan[i].Id;
                    if (weaponSpan[i].Range > 0f)
                    {
                        fighterCounts[faction]++;
                    }
                    else
                    {
                        minerCounts[faction]++;
                    }
                }
            }
        }
    }
}
