using Microsoft.Xna.Framework;
using Proto4X.Sandbox.Components;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Game
{
    /// <summary>
    /// Things that have finished being built and are waiting to become real entities.
    /// </summary>
    /// <remarks>
    /// Systems can't add entities, so they describe what they want built and the game loop creates
    /// it after <c>SystemScheduler.Update</c> returns (see ENGINE_REQUESTS.md). This used to be a
    /// list owned by <c>ProductionSystem</c>; it moved out when miners gained the ability to build
    /// stations, because two unrelated systems now produce entities and one drain point is simpler
    /// than two.
    /// </remarks>
    /// <param name="InitialDestination">
    /// Where the new unit should head immediately - a station's rally point. Null means it idles
    /// where it appeared, which for a miner means starting the gather loop on its own.
    /// </param>
    public readonly record struct SpawnRequest(UnitKind Kind, FactionId Faction, Vector2 Location, Vector2? InitialDestination = null);

    public class SpawnQueue
    {
        private readonly List<SpawnRequest> pending = [];

        public IReadOnlyList<SpawnRequest> Pending => pending;

        public void Enqueue(SpawnRequest request) => pending.Add(request);

        public void Clear() => pending.Clear();
    }
}
