using System;

namespace MonoGameLibrary.Components.Infrastructure
{
    public interface IDependsOnOtherComponents
    {
        Type[] GetComponentDependencies { get; }
    }
}
