using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class EnemyBase : MonoBehaviour
{
    [SerializeField] private int health = 2;
    [SerializeField] private int bodyshotDamage = 1;
    [SerializeField] private int headshotDamage = 2;
    [SerializeField] private Transform playerTransform;
    private FirstPersonController playerController;
    [SerializeField] private Transform headTransform;
    [SerializeField] private NavMeshAgent agent;
    [SerializeField] private Animator animator;
    [SerializeField] private float attackTime = 3.0f;
    [SerializeField] private float attackFreezeTime = 2.5f;
    [SerializeField] private float attackRange = 3.0f;
    private Vector3 startingPosition;
    [SerializeField] private float playerChaseTime = 10.0f;
    private float distanceToStartingPointError = 2.0f;
    private float timeSincePlayerSeen = 100.0f;
    private float timeSinceAttackStart = 0.0f;
    private bool canSeePlayer = false;
    private bool isAttacking = false;
    [SerializeField] private AudioSource attackSource;

    private void Start()
    {
        playerTransform = GameObject.FindWithTag("Player").transform;
        playerController = playerTransform.GetComponent<FirstPersonController>();
        startingPosition = transform.position;
    }

    public void TakeDamage(bool headshot)
    {
        if(headshot)
        {
            health -= headshotDamage;
        }
        else
        {
            health -= bodyshotDamage;
        }
        if(health <= 0)
        {
            Destroy(gameObject);
        }
    }

    private void Update()
    {
        RaycastHit hit;
        if(Physics.Linecast(headTransform.position, playerTransform.position, out hit))
        {
            if(hit.collider.CompareTag("Player"))
            {
                canSeePlayer = true;
            }
            else
            {
                canSeePlayer = false;
            }
        }

        if(isAttacking)
        {
            timeSinceAttackStart += Time.deltaTime;
            if(timeSinceAttackStart >= attackTime)
            {
                isAttacking = false;
                animator.SetBool("IsAttacking", false);
                agent.isStopped = false;
            }
        }

        if(canSeePlayer)
        {
            timeSincePlayerSeen = 0.0f;
            if(!isAttacking)
            {
                agent.SetDestination(playerTransform.position);
                if(Vector3.Distance(transform.position, playerTransform.position) < attackRange)
                {
                    Vector3 directionOfEnemy = playerTransform.position - transform.position;
                    playerController.DamagePlayer(attackFreezeTime, headTransform.position);
                    attackSource.Play();
                    isAttacking = true;
                    animator.SetBool("IsAttacking", true);
                    agent.isStopped = true;
                    timeSinceAttackStart = 0.0f;
                }
            }
        }
        else if(!canSeePlayer && timeSincePlayerSeen < playerChaseTime)
        {
            timeSincePlayerSeen += Time.deltaTime;
            agent.SetDestination(playerTransform.position);
        }
        else if(Vector3.Distance(transform.position, startingPosition) > distanceToStartingPointError)
        {
            agent.SetDestination(startingPosition);
        }
    }
}
