// ============================================
// Entity.cs - Base entity class
// ============================================
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using DungeonExplorer.Components;
using System.Collections.Generic;
using System;

namespace DungeonExplorer.Entities
{
    /// <summary>
    /// Base entity class using Entity-Component pattern
    /// All game objects inherit from this class
    /// </summary>
    public abstract class Entity
    {
        protected Dictionary<Type, IComponent> _components;
        public bool IsActive { get; set; }

        // Quick access to commonly used components
        public TransformComponent Transform => GetComponent<TransformComponent>();
        public RenderComponent Render => GetComponent<RenderComponent>();
        public MovementComponent Movement => GetComponent<MovementComponent>();
        public HealthComponent Health => GetComponent<HealthComponent>();
        public AIComponent AI => GetComponent<AIComponent>();

        protected Entity()
        {
            _components = new Dictionary<Type, IComponent>();
            IsActive = true;
        }

        public virtual void Update(GameTime gameTime)
        {
            if (!IsActive) return;

            foreach (var component in _components.Values)
            {
                component.Update(gameTime);
            }
        }

        public void AddComponent<T>(T component) where T : IComponent
        {
            _components[typeof(T)] = component;
        }

        public T GetComponent<T>() where T : IComponent
        {
            _components.TryGetValue(typeof(T), out IComponent component);
            return (T)component;
        }

        public bool HasComponent<T>() where T : IComponent
        {
            return _components.ContainsKey(typeof(T));
        }

        public void RemoveComponent<T>() where T : IComponent
        {
            _components.Remove(typeof(T));
        }

        public Rectangle GetBounds()
        {
            if (Transform == null || Render == null) return Rectangle.Empty;
            
            return Transform.GetBounds(
                Render.Texture?.Width ?? 32, 
                Render.Texture?.Height ?? 32
            );
        }
    }
}