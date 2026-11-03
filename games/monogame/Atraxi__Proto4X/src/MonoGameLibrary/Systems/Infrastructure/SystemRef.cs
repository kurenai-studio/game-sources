using System;

namespace MonoGameLibrary.Systems.Infrastructure
{
    //TODO: This is a bit of a heavy solution, but it works and provides the desired type safety guarantees. It might be worth pivoting to an analyser later depending on where the implementation bloat ends up later
    public readonly struct SystemRef
    {
        public Type Value { get; }
        private SystemRef(Type value) => Value = value;
        public static SystemRef Of<T>() where T : ISystem => new(typeof(T));
    }
}
