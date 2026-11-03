using Microsoft.Xna.Framework;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using System;

namespace Proto4X.Sandbox.Components
{
    /// <summary>
    /// A continuous-beam weapon: while a hostile is inside <see cref="Range"/>, it takes
    /// <see cref="DamagePerSecond"/> every second. No projectiles, no reload bookkeeping.
    /// </summary>
    /// <remarks>
    /// Unarmed things (miners) still carry a <c>Range = 0</c> Weapon. That looks wasteful, and is:
    /// a system gets exactly one AND-mask query, so the only way for CombatSystem to see both
    /// shooters and their victims in the same call is for every combat participant to share one
    /// component set. See "Systems can only declare one AND-mask query" in ENGINE_REQUESTS.md.
    /// </remarks>
    public struct Weapon(float damagePerSecond, float range) : IDependsOnOtherComponents
    {
        public float DamagePerSecond = damagePerSecond;
        public float Range = range;

        /// <summary>Where this weapon is firing right now, for the beam renderer. Rewritten every frame by CombatSystem.</summary>
        public Vector2? FiringAt = null;

        // Declaring the whole combat quad as a dependency means "can be shot at" and "can be shot"
        // are the same archetype by construction - an entity can't accidentally be half-eligible.
        public readonly Type[] GetComponentDependencies => [typeof(Position), typeof(Faction), typeof(Health)];
    }
}
