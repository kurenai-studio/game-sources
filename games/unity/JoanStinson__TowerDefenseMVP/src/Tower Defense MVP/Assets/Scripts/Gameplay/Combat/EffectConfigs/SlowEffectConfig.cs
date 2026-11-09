using JGM.Gameplay.Combat.Effects;
using UnityEngine;

namespace JGM.Gameplay.Combat.EffectConfigs
{
    [CreateAssetMenu(fileName = "New Slow Effect Config", menuName = "Combat Effects/Slow")]
    public class SlowEffectConfig : CombatEffectConfig
    {
        public float SlowMultiplier = 0.5f;
        public float Duration = 2f;

        public override ICombatEffect CreateEffect()
        {
            return new SlowEffect(SlowMultiplier, Duration);
        }
    }
}
