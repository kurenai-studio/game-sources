using UnityEngine;

namespace LD55
{
    public class Projectile : MonoBehaviour
    {
        public static Projectile Create(Vector3 origin, Vector3 direction)
        {
            var projectile = Instantiate(GameConfig.Instance.projectile, origin, Quaternion.identity);
            projectile._direction = direction;
            return projectile;
        }

        Vector3 _direction;

        #region Inspector

        [SerializeField] float _TTL = 5;

        [SerializeField] float _Speed = 7;

        #endregion

        float _ttlTimer = 0;

        public bool Consumed { get; set; }

        void Update()
        {
            ProcessMove();
        }

        void ProcessMove()
        {
            _ttlTimer += Time.deltaTime;
            if (_ttlTimer > _TTL)
            {
                Destroy(gameObject);
                return;
            }

            transform.position += _Speed * Time.deltaTime * _direction;
        }
    }
}
