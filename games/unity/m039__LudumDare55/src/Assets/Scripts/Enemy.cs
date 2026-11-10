using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace LD55
{
    public class Enemy : MonoBehaviour
    {
        #region Inspector

        [SerializeField] float _Speed = 5f;

        [SerializeField] Transform _Visual;

        #endregion

        void Update()
        {
            FollowPlayer();
        }

        void FollowPlayer()
        {
            if (Player.Instance == null)
                return;

            var direction = Player.Instance.transform.position - transform.position;
            direction.y = 0;
            direction.Normalize();

            if (direction.sqrMagnitude <= 0.1)
                return;

            transform.position += _Speed * Time.deltaTime * direction;
            _Visual.rotation = Quaternion.LookRotation(direction, Vector3.up);
        }

        void OnTriggerEnter(Collider other)
        {
            if (other.GetComponentInParent<Projectile>() is Projectile projectile &&
                !projectile.Consumed)
            {
                projectile.Consumed = true;
                Destroy(projectile.gameObject);
                Destroy(gameObject);
            }
        }
    }
}
