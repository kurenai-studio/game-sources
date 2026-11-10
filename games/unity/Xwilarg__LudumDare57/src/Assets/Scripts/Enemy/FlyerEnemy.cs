using UnityEngine;

namespace LudumDare57.Enemy
{
    public class FlyerEnemy : AEnemy
    {
        public override bool IsBad => false;

        public override void DoAction()
        {
            _rb.linearVelocity = Vector2.ClampMagnitude(_rb.linearVelocity + ((Vector2)(_target.transform.position - transform.position)).normalized * 5f, 10f);
        }
    }
}