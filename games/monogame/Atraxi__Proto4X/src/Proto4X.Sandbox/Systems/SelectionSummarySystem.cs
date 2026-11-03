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
    /// Publishes what the player currently has selected, broken down by unit kind. This is the
    /// bridge between "what did I click" and "what can I be told to do" - the build menu reads it
    /// to decide which commands to offer, so the UI always matches the selection.
    /// </summary>
    public class SelectionSummarySystem : ISystem, IUpdateSystem
    {
        private readonly int[] selectedCounts = new int[Enum.GetValues<UnitKind>().Length];

        /// <summary>
        /// The kind whose commands should be offered - the most numerous kind in the selection.
        /// <c>None</c> when nothing is selected.
        /// </summary>
        public UnitKind PrimaryKind { get; private set; } = UnitKind.None;

        public int TotalSelected { get; private set; }

        public int CountOf(UnitKind kind) => selectedCounts[(int)kind];

        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Selectable>(), ComponentRef.Of<Faction>(), ComponentRef.Of<UnitType>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            Array.Clear(selectedCounts);
            TotalSelected = 0;

            foreach (var archetypeChunk in archetypeChunks)
            {
                var selectableSpan = archetypeChunk.GetSpan<Selectable>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var unitTypeSpan = archetypeChunk.GetSpan<UnitType>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (!selectableSpan[i].IsSelected || factionSpan[i].Id != FactionId.Player)
                    {
                        continue;
                    }

                    selectedCounts[(int)unitTypeSpan[i].Kind]++;
                    TotalSelected++;
                }
            }

            PrimaryKind = UnitKind.None;
            var best = 0;
            for (var kind = 0; kind < selectedCounts.Length; kind++)
            {
                if (selectedCounts[kind] > best)
                {
                    best = selectedCounts[kind];
                    PrimaryKind = (UnitKind)kind;
                }
            }
        }
    }
}
