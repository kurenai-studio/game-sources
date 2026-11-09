using System.Collections;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.AI;

public class Enemy : MonoBehaviour
{
    private float _health;
    private PlayerController _player;

    public Arena arena;
    public NavMeshAgent navMeshAgent;
    public float startHealth = 50f;
    public Rigidbody body;
    public bool isArcher;
    float firePeriod = 2;
    public ParticleSystem gunParticles;
    public Bullet bullet;
    public Transform bulletSpawnTransform;

    public float immortalityCooldown = 0f;

    public Animator animator;
    float fireTimer = 0;

    // Todo: fear mechanics ???
    enum States
    {
        Chasing,
        RunningAway,
    }

    private States _state = States.Chasing;

    void Start()
    {
        _health = startHealth;
        _player = arena.GetPlayer();
        body.isKinematic = true;
    }

    void Update()
    {
        immortalityCooldown = Mathf.Max(immortalityCooldown - Time.deltaTime, 0f);

        if (!navMeshAgent.enabled)
        {
            animator.SetFloat("Speed", 0);
            return;
        }

        if (isArcher)
            ArcherBrain();
        else
            KnightBrain();

        animator.SetFloat("Speed", navMeshAgent.velocity.magnitude);
    }

    void KnightBrain()
    {
        if (Vector3.Distance(transform.position, _player.transform.position) < 1.5f)
        {
            navMeshAgent.destination = transform.position;
            animator.SetBool("Hit", true);
        }
        else
        {
            navMeshAgent.destination = _player.transform.position;
        }
    }

    void ArcherBrain()
    {
        if (fireTimer > 0)
            fireTimer -= Time.deltaTime;

        var dist = Vector3.Distance(transform.position, _player.transform.position);
        switch (_state)
        {
            case States.Chasing:
                if (dist < 5f)
                {
                    _state = States.RunningAway;
                    animator.SetBool("Aim", false);
                }
                else if (dist > 20f)
                {
                    navMeshAgent.destination = _player.transform.position;
                }
                else
                {
                    navMeshAgent.destination = transform.position;
                    var look = _player.transform.position - transform.position;
                    look = new Vector3(look.x, 0, look.z);
                    transform.rotation = Quaternion.LookRotation(look);
                    animator.SetBool("Aim", true);
                    if (fireTimer <= 0)
                    {
                        var spawnedBulled = Instantiate(bullet);
                        spawnedBulled.transform.position = bulletSpawnTransform.position;
                        spawnedBulled.transform.rotation = bulletSpawnTransform.rotation;
                        animator.SetBool("Fire", true);
                        gunParticles.Play();
                        fireTimer = firePeriod;
                    }
                }

                break;
            case States.RunningAway:
                if (dist > 15f)
                {
                    _state = States.Chasing;
                    animator.SetBool("Aim", true);
                }
                else
                {
                    navMeshAgent.destination = transform.position + (transform.position - _player.transform.position).normalized * 20;
                }
                break;
        }
    }

    public void GetHit(Transform hitter, float damage)
    {
        if (immortalityCooldown > 0) return;


        StartCoroutine(HitCoroutine(hitter, damage));
    }

    IEnumerator HitCoroutine(Transform hitter, float damage)
    {
        body.isKinematic = false;
        navMeshAgent.enabled = false;

        immortalityCooldown = 1f;
        _health -= damage;

        body.AddForce((transform.position - hitter.position).normalized * 5 + Vector3.up * 5, ForceMode.Impulse);

        yield return new WaitForSeconds(1f);

        if (_health <= 0)
            Destroy(this.gameObject);

        body.isKinematic = true;
        navMeshAgent.enabled = true;
    }
}
