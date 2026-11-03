using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using System;

namespace Proto4X.Sandbox.Components
{
    /// <summary>
    /// Selection state lives on the entity rather than in a list of selected entity ids, because
    /// there is currently no way to obtain an entity id during chunk iteration. Storing the flag as
    /// component data turns "select these units" and "order every selected unit" into plain system
    /// passes, which is the shape the engine is actually good at.
    /// </summary>
    public struct Selectable(float pickRadius) : IDependsOnOtherComponents
    {
        public float PickRadius = pickRadius;
        public bool IsSelected = false;

        public readonly Type[] GetComponentDependencies => [typeof(Position)];
    }
}
