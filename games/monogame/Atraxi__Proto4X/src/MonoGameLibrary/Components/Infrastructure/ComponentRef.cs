using System;

namespace MonoGameLibrary.Components.Infrastructure
{
    public readonly struct ComponentRef
    {
        public Type Value { get; }
        private ComponentRef(Type value) => Value = value;
        public static ComponentRef Of<T>() where T : struct => new(typeof(T));
    }
}
