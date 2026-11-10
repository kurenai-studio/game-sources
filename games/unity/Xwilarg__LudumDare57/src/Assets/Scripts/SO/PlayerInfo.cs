using UnityEngine;

namespace LudumDare57.SO
{
    [CreateAssetMenu(menuName = "ScriptableObject/PlayerInfo", fileName = "PlayerInfo")]
    public class PlayerInfo : ScriptableObject
    {
        [Header("Stats")]
        public int HealthCount;
        public float RecallDuration;

        [Header("Basic Movements")]
        public float Speed;
        public float JumpForce;
        public float JumpCooldown;
        [Tooltip("Speed at which the player is throw away when hitting an enemy")] public float HurtSpeed;
        public float HurtDuration;

        [Header("Drilling")]
        [Tooltip("After we are done drilling, amount of time we need to wait before doing it again")] public float DrillingCooldown;
        [Tooltip("Player speed while drilling")] public float DrillingSpeed;
        [Tooltip("Amount of time in which drilling effect is active")] public float DrillDuration;
    }
}