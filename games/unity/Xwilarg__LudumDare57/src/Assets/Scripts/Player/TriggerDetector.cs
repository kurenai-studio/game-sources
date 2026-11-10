using UnityEngine;
using UnityEngine.Events;

namespace LudumDare57.Player
{
    public class TriggerDetector : MonoBehaviour
    {
        public UnityEvent<Collider2D> OnTriggerEnterEvt { get; } = new();
        public UnityEvent<Collider2D> OnTriggerExitEvt { get; } = new();

        public void OnTriggerEnter2D(Collider2D collision)
        {
            OnTriggerEnterEvt.Invoke(collision);
        }

        public void OnTriggerExit2D(Collider2D collision)
        {
            OnTriggerExitEvt.Invoke(collision);
        }
    }
}