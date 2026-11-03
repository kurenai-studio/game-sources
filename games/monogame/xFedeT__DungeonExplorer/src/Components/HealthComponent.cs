// ============================================
// HealthComponent.cs - Health and damage system
// ============================================
using Microsoft.Xna.Framework;
using DungeonExplorer.Components;
using System;

namespace DungeonExplorer.Components
{
    /// <summary>
    /// Component that handles entity health and damage
    /// </summary>
    public class HealthComponent : IComponent
    {
        public int MaxHealth { get; private set; }
        public int CurrentHealth { get; set; }
        public bool IsAlive => CurrentHealth > 0;
        public bool IsInvulnerable { get; set; }
        public float InvulnerabilityDuration { get; set; }
        private float _invulnerabilityTimer;

        public event Action<int> OnHealthChanged;
        public event Action OnDeath;

        public HealthComponent(int maxHealth)
        {
            MaxHealth = maxHealth;
            CurrentHealth = maxHealth;
            IsInvulnerable = false;
            InvulnerabilityDuration = 1f; // 1 second of invulnerability after taking damage
        }

        public void Update(GameTime gameTime)
        {
            if (IsInvulnerable)
            {
                _invulnerabilityTimer -= (float)gameTime.ElapsedGameTime.TotalSeconds;
                if (_invulnerabilityTimer <= 0)
                {
                    IsInvulnerable = false;
                }
            }
        }

        public bool TakeDamage(int damage)
        {
            if (IsInvulnerable || !IsAlive || damage <= 0)
                return false;

            CurrentHealth = Math.Max(0, CurrentHealth - damage);
            OnHealthChanged?.Invoke(CurrentHealth);

            if (CurrentHealth <= 0)
            {
                OnDeath?.Invoke();
                return true; // Entity died
            }
            else
            {
                // Start invulnerability period
                IsInvulnerable = true;
                _invulnerabilityTimer = InvulnerabilityDuration;
            }

            return false; // Entity survived
        }

        public void Heal(int amount)
        {
            if (amount <= 0) return;

            CurrentHealth = Math.Min(MaxHealth, CurrentHealth + amount);
            OnHealthChanged?.Invoke(CurrentHealth);
        }

        public void SetMaxHealth(int newMaxHealth)
        {
            MaxHealth = newMaxHealth;
            if (CurrentHealth > MaxHealth)
                CurrentHealth = MaxHealth;
            OnHealthChanged?.Invoke(CurrentHealth);
        }
    }
}