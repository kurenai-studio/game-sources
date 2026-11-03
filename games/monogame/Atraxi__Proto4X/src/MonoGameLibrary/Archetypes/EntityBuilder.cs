using MonoGameLibrary.Components.Infrastructure;
using System;
using System.Collections.Generic;

namespace MonoGameLibrary.Archetypes
{
    public class EntityBuilder
    {
        private ComponentTypeMask componentTypeMask = ComponentTypeMask.Empty;
        public ComponentTypeMask ComponentTypeMask => componentTypeMask;

        private readonly List<IComponentContainer> components = [];
        internal List<IComponentContainer> Components => components;

        public static EntityBuilder CreateEntity()
        {
            return new EntityBuilder();
        }

        public EntityBuilder With<T>(T payload) where T: struct
        {
            if(payload is IDependsOnOtherComponents dependsOn && !componentTypeMask.ContainsAll(ComponentTypeMask.FromTypes(dependsOn.GetComponentDependencies)))
            {
                throw new ArgumentException($"The new component payload of type {payload.GetType()} declares it depends on other component types, however those components have not yet been registered to this EntityBuild instance. Dependencies must be registered first.");
            }

            var componentTypeId = ComponentTypeRegistry.GetId(payload.GetType());
            componentTypeMask = componentTypeMask.With(ComponentTypeMask.FromTypeId(componentTypeId));

            components.Add(new ComponentContainerDetached<T>(payload));

            return this;
        }
    }
}