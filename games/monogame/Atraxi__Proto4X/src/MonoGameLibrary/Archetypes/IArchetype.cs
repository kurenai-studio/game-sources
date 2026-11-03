using System;

namespace MonoGameLibrary.Archetypes
{
    public interface IArchetype
    {
        void QueueEntityForRemovalById(int entityId);
        void QueueEntityForRemovalByIndex(int entityIndex);
        int GetEntityId(int entityIndex);
    }
}