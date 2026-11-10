using UnityEngine;

namespace LudumDare57.GizmosDebug
{
    public class CircleColliderDebug : MonoBehaviour
    {
        private void OnDrawGizmos()
        {
            Gizmos.color = Color.green;
            var coll = GetComponent<CircleCollider2D>();
            Gizmos.DrawWireSphere(coll.transform.position, coll.radius * transform.localScale.x);
        }
    }
}