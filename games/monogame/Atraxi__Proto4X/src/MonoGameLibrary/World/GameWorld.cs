using Microsoft.Xna.Framework;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components.Infrastructure;
using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;

namespace MonoGameLibrary.World
{
    public class GameWorld(int xPos, int yPos, int width, int height)
    {
        internal readonly Dictionary<ComponentTypeMask, Archetype> Archetypes = [];
        public readonly Rectangle Bounds = new(xPos, yPos, width, height);

        internal List<ArchetypeChunk> QueryRelevantComponentArrays(ComponentTypeMask componentProviderTypes)
        {
            List<ArchetypeChunk> result = [];

            if (componentProviderTypes == ComponentTypeMask.Empty)
            {
                return result;
            }

            foreach (var (componentTypeMask, archetype) in Archetypes)
            {
                if (componentTypeMask.ContainsAll(componentProviderTypes))
                {
                    var archetypeChunk = archetype.GetMatchingComponents(componentProviderTypes);

                    result.Add(archetypeChunk);
                }
            }
            return result;
        }

        public void AddEntity(EntityBuilder entityBuilder)
        {
            Archetypes.TryGetValue(entityBuilder.ComponentTypeMask, out var archetype);
            if (archetype == null)
            {
                archetype = new Archetype(50, entityBuilder);
                Archetypes.Add(entityBuilder.ComponentTypeMask, archetype);
            }
            else
            {
                archetype.QueueEntityForAddition(entityBuilder);
            }
        }

        public void RemoveEntity(int entityId)
        {
            foreach (var (_, archetype) in Archetypes)
            {
                if(archetype.HasEntity(entityId))
                {
                    archetype.QueueEntityForRemovalById(entityId);
                }
            }
        }

        public bool HasEntity(int entityId)
        {
            return Archetypes.Any(archetype => archetype.Value.HasEntity(entityId));
        }

        internal Dictionary<Type, IComponentContainer> GetComponentsForEntity(int entityId)
        {
            foreach (var (_, archetype) in Archetypes)
            {
                if(archetype.HasEntity(entityId))
                {
                    return archetype.GetComponentsForEntity(entityId);
                }
            }
            throw new InvalidOperationException($"An entity with the id {entityId} doesn't exist");
        }

        public bool TryGetComponent<T>(int entityId, [NotNullWhen(true)]out T componentData) where T : struct
        {
            componentData = default;
            foreach (var (_, archetype) in Archetypes)
            {
                if (archetype.HasEntity(entityId))
                {
                    componentData = archetype.GetComponentTForEntityId<T>(entityId);
                    return true;
                }
            }
            return false;
        }

        public delegate void ComponentMutator<T>(ref T component);
        public bool MutateComponent<T>(int entityId, ComponentMutator<T> mutator) where T : struct
        {
            foreach (var (_, archetype) in Archetypes)
            {
                if (archetype.HasEntity(entityId))
                {
                    mutator.Invoke(ref archetype.GetComponentRefTForEntityId<T>(entityId));
                    return true;
                }
            }
            return false;
        }
    }
}