using LudumDare57.Manager;
using LudumDare57.Player;
using LudumDare57.Prop;
using System.Collections;
using UnityEngine;

namespace LudumDare57.Enemy
{
    public abstract class AEnemy : MonoBehaviour, IDestructible
    {
        protected Rigidbody2D _rb;

        protected PlayerController _target;

        [SerializeField]
        private Transform _eye;

        public int MoneyGained => Random.Range(10, 25);

        public float ReactionTime { set; protected get; } = 1f;

        public GameObject GameObject => gameObject;

        protected bool _isStunned;

        protected virtual void Awake()
        {
            _rb = GetComponent<Rigidbody2D>();
            StartCoroutine(Act());
        }

        private void Start()
        {
            EnemyManager.Instance.Register(this);
        }

        public abstract void DoAction();

        public virtual float DistanceSeeMultiplier => 1f;

        private IEnumerator Act()
        {
            yield return new WaitForSeconds(Random.Range(0f, 2f));
            while (true)
            {
                yield return new WaitForSeconds(ReactionTime);

                if (_isStunned) continue;

                _target = PlayerManager.Instance.GetClosest(transform.position);
                if (_target != null && Vector2.Distance(transform.position, _target.transform.position) < 15f * DistanceSeeMultiplier)
                {
                    DoAction();
                }
            }
        }

        public abstract bool IsBad { get; }

        public bool CanDestroy => !EnemyManager.Instance.OnlyKillBads || IsBad;

        private void Update()
        {
            if (_target == null)
            {
                _eye.transform.localPosition = Vector3.zero;
                return;
            }

            var dir = (_target.transform.position - transform.position).normalized;
            _eye.localPosition = dir * .25f;
        }

        public virtual void OnDestroy()
        { }

        public void ToggleHighlight(bool _)
        { }

        public void Stun(Transform player)
        {
            StartCoroutine(WaitStun());
            _rb.linearVelocity = (transform.position - player.position).normalized * 20f;
        }

        private IEnumerator WaitStun()
        {
            _isStunned = true;
            yield return new WaitForSeconds(1f);
            _isStunned = false;
        }
    }
}