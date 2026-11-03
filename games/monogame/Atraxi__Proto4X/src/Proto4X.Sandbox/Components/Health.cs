using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using System;

namespace Proto4X.Sandbox.Components
{
    public struct Health(float maximum) : IDependsOnOtherComponents
    {
        public float Maximum = maximum;
        public float Current = maximum;

        // Depends on Position so a health bar always has somewhere to draw itself.
        public readonly Type[] GetComponentDependencies => [typeof(Position)];
    }
}
