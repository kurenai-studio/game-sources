using MonoGameLibrary.Components.Infrastructure;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;

namespace MonoGameLibrary.Archetypes
{
    public class ArchetypeChunk : IArchetype
    {
        internal readonly ReadOnlyDictionary<Type, IComponentColumn> Components;

        public readonly int EntityCount;
        private readonly Archetype archetype;

        internal ArchetypeChunk(Dictionary<Type, IComponentColumn> components, int entityCount, Archetype archetype)
        {
            this.archetype = archetype;
            Components = components.AsReadOnly();
            EntityCount = entityCount;
        }

        public ref T Get<T>(int index) where T : struct
        {
            return ref ((ComponentColumn<T>)Components[typeof(T)]).Values[index];
        }

        public Span<T> GetSpan<T>() where T : struct
        {
            return new Span<T>(((ComponentColumn<T>)Components[typeof(T)]).Values, 0, EntityCount);
        }

        public void QueueEntityForRemovalById(int entityId)
        {
            archetype.QueueEntityForRemovalById(entityId);
        }

        public void QueueEntityForRemovalByIndex(int entityIndex)
        {
            archetype.QueueEntityForRemovalByIndex(entityIndex);
        }

        public int GetEntityId(int entityIndex)
        {
            return archetype.GetEntityId(entityIndex);
        }
    }
}