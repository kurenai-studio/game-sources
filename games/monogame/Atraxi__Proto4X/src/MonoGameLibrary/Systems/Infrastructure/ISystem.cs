using MonoGameLibrary.Components.Infrastructure;
using System.Collections.Generic;

namespace MonoGameLibrary.Systems.Infrastructure
{
    public interface ISystem
    {
        public IReadOnlyList<SystemRef> RunAfter => [];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders { get; }
    }
}
