using MonoGameLibrary.Archetypes;
using System;

namespace MonoGameLibrary.Components.Infrastructure
{
    internal interface IComponentContainer
    {
        internal void WriteComponentByIndex(Archetype archetype, int entityIndex);
        internal void CreateComponentColumn(Archetype archetype, int columnIndex, int initialCapacity);
        Type GetComponentType();
    }

    internal class ComponentContainerDetached<T>(T payload) : IComponentContainer where T : struct
    {
        protected readonly T Payload = payload;

        public T Component => Payload;

        public Type GetComponentType() => typeof(T);

        void IComponentContainer.CreateComponentColumn(Archetype archetype, int columnIndex, int initialCapacity)
        {
            archetype.CreateComponentColumn<T>(columnIndex, initialCapacity);
        }

        void IComponentContainer.WriteComponentByIndex(Archetype archetype, int entityIndex)
        {
            archetype.WriteComponentByIndex(Payload, entityIndex);
        }
    }

    internal class ComponentContainerAttached<T> : ComponentContainerDetached<T> where T : struct
    {
        private readonly Archetype _archetype;

        internal ComponentContainerAttached(T payload, Archetype archetype) : base(payload)
        {
            _archetype = archetype;
        }

        public void WriteComponentById(int entityId, T newPayload)
        {
            _archetype.WriteComponentById(newPayload, entityId);
        }

        public void CreateComponentColumn(int columnIndex, int initialCapacity)
        {
            _archetype.CreateComponentColumn<T>(columnIndex, initialCapacity);
        }

        public void WriteComponentByIndex(int entityIndex)
        {
            _archetype.WriteComponentByIndex(Payload, entityIndex);
        }
    }
}
