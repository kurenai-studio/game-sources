using PixelLeap.Core;
using UnityEngine;

namespace PixelLeap.Level
{
    public enum TriggerKind { Checkpoint, Goal, Spikes }

    /// <summary>关卡触发器：检查点、终点、尖刺。只对玩家生效。</summary>
    [RequireComponent(typeof(BoxCollider2D))]
    public class LevelTrigger : MonoBehaviour
    {
        public TriggerKind kind;
        bool activated;
        SpriteRenderer sr;

        void Awake()
        {
            GetComponent<BoxCollider2D>().isTrigger = true;
            sr = GetComponentInChildren<SpriteRenderer>();
        }

        void OnTriggerStay2D(Collider2D other)
        {
            var hp = other.GetComponentInParent<Health>();
            if (!hp || hp.Team != Team.Player || hp.IsDead) return;

            switch (kind)
            {
                case TriggerKind.Spikes:
                    hp.TakeDamage(1, Vector2.up);
                    break;
                case TriggerKind.Checkpoint when !activated:
                    activated = true;
                    if (sr) sr.color = new Color(0.4f, 1f, 0.6f);
                    GameManager.Instance?.SetCheckpoint(transform.position + Vector3.up * 0.2f);
                    break;
                case TriggerKind.Goal when !activated:
                    activated = true;
                    GameManager.Instance?.CompleteLevel();
                    break;
            }
        }
    }
}
