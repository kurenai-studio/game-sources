using UnityEngine;

namespace JGM.Gameplay.Creeps
{
    [CreateAssetMenu(fileName = "New Creep Config", menuName = "Creeps/Creep Config")]
    public class CreepConfig : ScriptableObject
    {
        [Header("Movement")]
        public float MoveSpeed = 5f;
        public float StopDistance = 5f;

        [Header("Attack")]
        public float AttackSpeed = 1f;
        public int AttackDamage = 1;

        [Header("Health")]
        public int Health = 3;

        [Header("Economy")]
        public int CoinReward = 1;
    }
}
