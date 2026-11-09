using System;
using System.Collections.Generic;
using Debug = UnityEngine.Debug;

namespace JGM.Gameplay
{
    public class ServiceLocator
    {
        public static ServiceLocator Instance
        {
            get
            {
                if (isShuttingDown)
                {
                    return null;
                }

                if (instance == null)
                {
                    instance = new ServiceLocator();
                }

                return instance;
            }
        }

        private static ServiceLocator instance;
        private static bool isShuttingDown;

        private Dictionary<Type, object> services = new();

        private ServiceLocator() { }

        public void Register<T>(T service) where T : class
        {
            var type = typeof(T);

            if (!services.TryGetValue(type, out var _))
            {
                services.Add(type, service);
            }
            else
            {
                Debug.LogWarning($"Service of type {type} is already registered.");
            }
        }

        public T Get<T>() where T : class
        {
            var type = typeof(T);

            if (services.TryGetValue(type, out var service))
            {
                return service as T;
            }

            throw new NullReferenceException($"Service of type {type} is not registered.");
        }

        private void OnDestroy()
        {
            isShuttingDown = true;
        }

        private void OnApplicationQuit()
        {
            isShuttingDown = true;
        }
    }
}
