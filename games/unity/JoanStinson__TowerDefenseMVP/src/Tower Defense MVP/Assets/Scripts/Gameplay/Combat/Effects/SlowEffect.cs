using UnityEngine;

namespace JGM.Gameplay.Combat.Effects
{
    public class SlowEffect : ICombatEffect
    {
        private readonly float slowMultiplier;
        private readonly float duration;

        public SlowEffect(float slowMultiplier, float duration)
        {
            this.slowMultiplier = slowMultiplier;
            this.duration = duration;
        }

        public void Apply(GameObject target)
        {
            if (target.TryGetComponent<IMovable>(out var movable))
            {
                movable.ApplySpeedModifier(slowMultiplier, duration);
            }
        }
    }
}
