using UnityEngine;

namespace PixelLeap.Player
{
    /// <summary>
    /// 角色手感参数。全部放在 ScriptableObject 里，策划可以在 Inspector 中实时调整，无需改代码。
    /// 跳跃采用"高度 + 到顶时间"反推重力与初速度，比直接调重力更直观。
    /// </summary>
    [CreateAssetMenu(menuName = "PixelLeap/Player Config", fileName = "PlayerConfig")]
    public class PlayerConfig : ScriptableObject
    {
        [Header("水平移动")]
        public float maxSpeed = 8f;
        public float groundAcceleration = 90f;
        public float groundDeceleration = 110f;
        public float airAcceleration = 55f;

        [Header("跳跃")]
        [Tooltip("按住跳跃键时的最大跳跃高度（单位：格）")] public float jumpHeight = 3.2f;
        [Tooltip("从起跳到最高点的时间（秒）")] public float timeToApex = 0.36f;
        [Tooltip("下落时的重力倍率，让下落更干脆")] public float fallGravityMultiplier = 1.9f;
        [Tooltip("提前松开跳跃键时的重力倍率，实现小跳")] public float jumpCutGravityMultiplier = 2.6f;
        public float maxFallSpeed = 22f;
        [Tooltip("空中额外跳跃次数（二段跳）")] public int extraJumps = 1;
        [Range(0.5f, 1f)] public float extraJumpRatio = 0.85f;

        [Header("输入容错")]
        [Tooltip("土狼时间：离开平台后仍可起跳的时间窗口")] public float coyoteTime = 0.1f;
        [Tooltip("跳跃缓冲：落地前提前按跳跃也会生效")] public float jumpBufferTime = 0.12f;

        [Header("射击")]
        public float fireInterval = 0.16f;
        public float bulletSpeed = 20f;
        public int bulletDamage = 1;
        public float bulletLifetime = 0.9f;

        [Header("生命")]
        public int maxHp = 5;
        public float invincibleTime = 0.8f;
        public Vector2 knockback = new Vector2(7f, 6f);

        /// <summary>g = 2h / t²</summary>
        public float Gravity => 2f * jumpHeight / (timeToApex * timeToApex);
        /// <summary>v0 = g · t</summary>
        public float JumpVelocity => Gravity * timeToApex;
    }
}
