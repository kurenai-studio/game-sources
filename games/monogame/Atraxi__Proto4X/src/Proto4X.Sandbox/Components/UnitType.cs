using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using System;

namespace Proto4X.Sandbox.Components
{
    public enum UnitKind
    {
        None = 0,
        Miner,
        Fighter,
        Station,
    }

    /// <summary>
    /// What an entity <em>is</em>, as data rather than as an inferred property of its archetype.
    /// </summary>
    /// <remarks>
    /// Everything here previously distinguished unit types by proxy - "has a Miner component",
    /// "Weapon.Range &gt; 0", "Health.Maximum is large". Those proxies each worked for exactly one
    /// caller and quietly disagreed with each other at the edges. Once the game needed "select every
    /// unit of this kind" and "what can this selection be told to do", it needed one answer that all
    /// callers share, and that answer is a field.
    ///
    /// This also carries the per-kind command set - see <c>Commands.For</c> - which is what makes
    /// build hotkeys mean different things depending on what you have selected.
    /// </remarks>
    public struct UnitType(UnitKind kind) : IDependsOnOtherComponents
    {
        public UnitKind Kind = kind;

        public readonly Type[] GetComponentDependencies => [typeof(Position)];
    }
}
