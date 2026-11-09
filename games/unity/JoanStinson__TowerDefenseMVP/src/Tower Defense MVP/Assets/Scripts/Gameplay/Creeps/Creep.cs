using JGM.Gameplay.Base;
using JGM.Gameplay.Combat;
using System;
using System.Collections;
using UnityEngine;

namespace JGM.Gameplay.Creeps
{
    public class Creep : MonoBehaviour, ICreep, IDamageable, IMovable
    {
        public event Action<int> OnTakeDamage;
        public int MaxHealth { get; private set; }
        public int CoinReward { get; private set; }
        public GameObject GameObject => gameObject;

        [SerializeField]
        private CreepConfig config;

        private CreepSpawner creepSpawner;
        private PlayerBase playerBase;
        private float moveSpeed;
        private int health;
        private bool initialized;
        private bool isAttacking;
        private bool isDead;
        private bool isSlowedDown;

        public void Initialize(CreepSpawner creepSpawner, PlayerBase playerBase)
        {
            this.creepSpawner = creepSpawner;
            this.playerBase = playerBase;
            moveSpeed = config.MoveSpeed;
            health = config.Health;
            MaxHealth = config.Health;
            CoinReward = config.CoinReward;
            transform.LookAt(playerBase.transform.position);
            initialized = true;
        }

        private void Update()
        {
            if (!initialized)
            {
                return;
            }

            if (!ReachedPlayerBase())
            {
                MoveTowardsPlayerBase();
            }
            else
            {
                AttackPlayerBase();
            }
        }

        private bool ReachedPlayerBase()
        {
            return Vector3.Distance(transform.position, playerBase.transform.position) <= config.StopDistance;
        }

        private void MoveTowardsPlayerBase()
        {
            transform.position = Vector3.MoveTowards(transform.position, playerBase.transform.position, moveSpeed * Time.deltaTime);
        }

        private void AttackPlayerBase()
        {
            if (!isAttacking)
            {
                StartCoroutine(Attack());
            }
        }

        private IEnumerator Attack()
        {
            isAttacking = true;

            while (playerBase.CurrentHealth > 0 && !isDead)
            {
                playerBase.TakeDamage(config.AttackDamage);
                yield return new WaitForSeconds(config.AttackSpeed);
            }

            isAttacking = false;
        }

        public void TakeDamage(int amount)
        {
            if (isDead)
            {
                return;
            }

            health -= amount;
            OnTakeDamage?.Invoke(health);

            if (health <= 0)
            {
                isDead = true;
                creepSpawner.KillCreep(this);
            }
        }

        public void ApplySpeedModifier(float multiplier, float duration)
        {
            if (!isSlowedDown)
            {
                StartCoroutine(ApplySlowEffect(multiplier, duration));
            }
        }

        private IEnumerator ApplySlowEffect(float multiplier, float duration)
        {
            isSlowedDown = true;
            moveSpeed = config.MoveSpeed * multiplier;
            yield return new WaitForSeconds(duration);
            moveSpeed = config.MoveSpeed;
            isSlowedDown = false;
        }
    }
}
