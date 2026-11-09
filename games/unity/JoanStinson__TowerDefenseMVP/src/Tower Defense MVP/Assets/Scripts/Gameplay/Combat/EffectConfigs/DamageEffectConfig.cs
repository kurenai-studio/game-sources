using JGM.Gameplay.Combat.Effects;
using UnityEngine;

namespace JGM.Gameplay.Combat.EffectConfigs
{
    [CreateAssetMenu(fileName = "New Damage Effect Config", menuName = "Combat Effects/Damage")]
    public class DamageEffectConfig : CombatEffectConfig
    {
        public int DamageAmount = 1;

        public override ICombatEffect CreateEffect()
        {
            return new DamageEffect(DamageAmount);
        }
    }
}
