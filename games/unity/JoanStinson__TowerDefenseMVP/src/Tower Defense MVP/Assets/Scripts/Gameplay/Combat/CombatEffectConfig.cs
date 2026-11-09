using UnityEngine;

namespace JGM.Gameplay.Combat
{
    public abstract class CombatEffectConfig : ScriptableObject
    {
        public abstract ICombatEffect CreateEffect();
    }
}
