using UnityEngine;

namespace JGM.Gameplay.Combat
{
    public interface ICombatEffect
    {
        void Apply(GameObject target);
    }
}
