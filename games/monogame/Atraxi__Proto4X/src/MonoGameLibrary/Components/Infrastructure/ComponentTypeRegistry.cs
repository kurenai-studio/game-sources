using System;
using System.Collections.Generic;

namespace MonoGameLibrary.Components.Infrastructure
{
    public static class ComponentTypeRegistry
    {
        private static int _nextId = 0;
        private static readonly Dictionary<Type, int> _typeToId = [];

        public static int GetId(Type type)
        {
            if (_typeToId.TryGetValue(type, out var id))
            {
                return id;
            }
            else
            {
                id = _nextId;
                if(id > 128)
                {
                    throw new InvalidOperationException("Only 128 component type ids can be allocated. Expand ComponentTypeMask before raising this limit");
                }
                _nextId++;
                _typeToId[type] = id;
                return id;
            }
        }

        internal static Dictionary<Type, int> GetRegisteredTypesAndIds()
        {
            return new Dictionary<Type, int>(_typeToId);
        }
    }
}
