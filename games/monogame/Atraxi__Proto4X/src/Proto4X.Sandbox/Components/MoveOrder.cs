using Microsoft.Xna.Framework;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using System;

namespace Proto4X.Sandbox.Components
{
    public struct MoveOrder(Vector2? destination = null) : IDependsOnOtherComponents
    {
        public Vector2? Destination = destination;

        /// <summary>
        /// This unit is parked on purpose and must not be nudged around.
        /// </summary>
        /// <remarks>
        /// A null <c>Destination</c> was doing double duty: it means both "nothing is driving this
        /// ship" and "this ship arrived and is now doing its job". <c>SeparationSystem</c> only
        /// cares about the first meaning, and without this flag it happily shoved miners off the
        /// asteroids they were mining. Anything deliberately stationary sets this.
        /// </remarks>
        public bool IsHoldingPosition = false;

        /// <summary>
        /// Seconds of quiet a unit owes the player after arriving where they sent it, before it is
        /// allowed to give itself a new job. Counts down only once the order has been spent - so
        /// it's a grace period at the destination, not a delay on the trip.
        /// </summary>
        /// <remarks>
        /// This exists because of one specific annoyance: fly a miner to the field you want a
        /// station on, and by the time you reach for the build key it has already claimed the
        /// nearest rock and turned around. The order completing is exactly the moment the player is
        /// about to issue the next one, and the gather loop was racing them to it.
        ///
        /// It lives on <c>MoveOrder</c> rather than on <c>Miner</c> because it is a property of the
        /// order, not of the unit: whoever issues a commanded move stamps it, steering ticks it
        /// down, and any unit that self-tasks checks it. Orders a unit gives itself - the gather
        /// loop's own trips to a rock and back - stamp nothing, so the economy runs at full speed.
        /// </remarks>
        public float CommandGraceRemaining = 0f;

        public readonly Type[] GetComponentDependencies => [typeof(Position), typeof(Motion)];
    }
}
