using UnityEngine;

namespace JGM.Gameplay.Combat.Effects
{
    public class DamageEffect : ICombatEffect
    {
        private readonly int damage;

        public DamageEffect(int damage)
        {
            this.damage = damage;
        }

        public void Apply(GameObject target)
        {
            if (target.TryGetComponent<IDamageable>(out var damageable))
            {
                damageable.TakeDamage(damage);
            }
        }
    }
}
