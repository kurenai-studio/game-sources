using UnityEngine;

namespace LudumDare57.Enemy
{
    public class JumperEnemy : AEnemy
    {
        private const float MaxX = 20f;
        public override bool IsBad => false;

        public override void DoAction()
        {
            var xDiff = _target.transform.position.x - transform.position.x;
            var xDir = Mathf.Clamp(xDiff, -MaxX, MaxX);
            _rb.AddForce(new Vector2(xDir, 3f * MaxX / 4f).normalized * 60f, ForceMode2D.Impulse);
        }
    }
}