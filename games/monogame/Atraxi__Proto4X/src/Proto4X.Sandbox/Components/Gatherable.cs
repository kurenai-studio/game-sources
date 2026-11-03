using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using System;

namespace Proto4X.Sandbox.Components
{
    public struct Gatherable(int amount) : IDependsOnOtherComponents
    {
        public int Amount = amount;

        public readonly Type[] GetComponentDependencies => [typeof(Position)];
    }
}
