using JGM.Gameplay.Combat;
using System;
using UnityEngine;

namespace JGM.Gameplay.Base
{
    public class PlayerBase : MonoBehaviour, IDamageable
    {
        public event Action<int> OnHealthChange;
        public event Action OnHealthDepleted;

        public int MaxHealth => maxHealth;
        public int CurrentHealth => health;

        private int maxHealth;
        private int health;

        public void Initialize(int startingHealth)
        {
            maxHealth = startingHealth;
            health = maxHealth;
        }

        public void TakeDamage(int amount)
        {
            health -= amount;
            OnHealthChange?.Invoke(health);

            if (health <= 0)
            {
                health = 0;
                OnHealthDepleted?.Invoke();
            }
        }

        public void Restart()
        {
            health = maxHealth;
            OnHealthChange?.Invoke(health);
        }
    }
}
