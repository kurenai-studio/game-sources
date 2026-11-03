using Proto4X.Sandbox.Components;
using System;

namespace Proto4X.Sandbox.Game
{
    /// <summary>
    /// Per-faction mineral stockpile. Not a component: it belongs to a faction, not an entity, and
    /// nothing about it wants to be iterated. Shared by reference between the systems that earn
    /// minerals (MinerSystem) and the ones that spend them (BuildCommandSystem, EnemyAiSystem).
    /// </summary>
    public class Economy
    {
        private readonly float[] mineralsByFaction = new float[Enum.GetValues<FactionId>().Length];

        /// <summary>
        /// Everyone who plays starts with the same stockpile - iterating <c>Faction.Playing</c>
        /// rather than naming factions, so a fourth one on the map is funded by existing.
        /// </summary>
        public Economy(int startingMinerals)
        {
            foreach (var faction in Faction.Playing)
            {
                mineralsByFaction[(int)faction] = startingMinerals;
            }
        }

        public int GetMinerals(FactionId faction) => (int)mineralsByFaction[(int)faction];

        public void Deposit(FactionId faction, float amount) => mineralsByFaction[(int)faction] += amount;

        public bool TrySpend(FactionId faction, int cost)
        {
            if (mineralsByFaction[(int)faction] < cost)
            {
                return false;
            }

            mineralsByFaction[(int)faction] -= cost;
            return true;
        }
    }
}
