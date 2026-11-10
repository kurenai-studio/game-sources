using UnityEngine;

namespace LudumDare57.Enemy
{
    public class BouncerEnemy : AEnemy
    {
        private Vector2 _baseVelocity;

        public override bool IsBad => true;

        public override void DoAction()
        {
            _baseVelocity = Vector2.ClampMagnitude(_rb.linearVelocity + ((Vector2)(_target.transform.position - transform.position)).normalized * 5f, 7.5f);
            _rb.linearVelocity = _baseVelocity;
        }

        private void OnCollisionEnter2D(Collision2D collision)
        {
            _rb.linearVelocity = Vector2.Reflect(_baseVelocity, collision.contacts[0].normal).normalized * _baseVelocity.magnitude;
        }
    }
}