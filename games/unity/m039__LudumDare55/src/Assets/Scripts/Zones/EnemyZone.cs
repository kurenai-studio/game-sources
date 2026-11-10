using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace LD55
{
    public class EnemyZone : MonoBehaviour
    {
        #region Inspector

        [SerializeField] Enemy[] _Enemies;

        #endregion

        public Enemy[] Enemies => _Enemies;

        void OnTriggerEnter(Collider other)
        {
            if (other.GetComponentInParent<Player>() is Player player)
            {
                player.OnEnter(this);
            }
        }

        void OnTriggerExit(Collider other)
        {
            if (other.GetComponentInParent<Player>() is Player player)
            {
                player.OnExit(this);
            }
        }
    }
}
