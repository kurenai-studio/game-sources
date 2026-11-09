using System.Collections;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.UI;

public class Dragon : MonoBehaviour
{
    public Arena arena;
    public NavMeshAgent navMeshAgent;
    public Rigidbody body;
    public Animator animator;
    public PlayerController _player;
    public Bullet fireBullet;
    public Transform bulletSpawnPoint;

    public RawImage healthBar;

    public bool getShot;

    public float health;
    private bool dead = false;
    public float maxHeath = 500;

    async void Start()
    {
        _player = arena.GetPlayer();
        health = maxHeath;
        await DragonCoroutine();
    }

    void Update()
    {
        animator.SetFloat("WalkSpeed", navMeshAgent.velocity.magnitude);
        healthBar.rectTransform.sizeDelta = new Vector2(500 * health / maxHeath, 15);

        if (health <= 0 && !dead)
        {
            dead = true;
            StartCoroutine(Die());
        }
    }

    IEnumerator Die()
    {
        yield return new WaitForSeconds(0.1f);
        animator.SetBool("Grounded", false);
        yield return new WaitForSeconds(0.1f);
        animator.SetBool("Dead", true);
    }

    async Awaitable DragonCoroutine()
    {
        await StartFlexing();
        while (true)
        {
            await Flexing();
            if (health <= 0) return;
            await Chepyking();
            if (health <= 0) return;
        }
    }

    async Awaitable StartFlexing()
    {
        while (!getShot) await Awaitable.NextFrameAsync();
        getShot = false;

        animator.SetBool("Unpack", true);
        _player.CameraShake(1f);
        await FlyTo(arena.NextFlyingSpot(), 20f);
    }

    async Awaitable Flexing()
    {
        while (true)
        {
            if (health <= 0) return;

            var wasShot = await FlyTo(arena.NextFlyingSpot(), 15f, true);
            if (wasShot)
            {
                Debug.Log("AAaaaa");
                await Fall();
                return;
            }

            if (Random.Range(0, 10) > 6)
            {
                animator.SetBool("Fire", true);
                await Awaitable.WaitForSecondsAsync(0.7f);
                if (health <= 0) return;
                var spawnedBullet = Instantiate(fireBullet);
                spawnedBullet.transform.position = bulletSpawnPoint.position;
                spawnedBullet.transform.rotation = Quaternion.LookRotation(_player.transform.position - bulletSpawnPoint.position);
                await Awaitable.WaitForSecondsAsync(0.8f);
                if (health <= 0) return;
            }
            else if (Random.Range(0, 10) > 7)
            {
                await Fall(true);
                return;
            }
        }
    }

    async Awaitable Chepyking()
    {
        navMeshAgent.enabled = true;
        body.isKinematic = true;

        while (true)
        {
            if (health <= 0) return;

            navMeshAgent.destination = _player.transform.position;
            if (Vector3.Distance(_player.transform.position, transform.position) < 7)
            {
                animator.SetBool("Fire", true);
                await Awaitable.WaitForSecondsAsync(1.5f);
                if (health <= 0) return;
            }
            else if (Random.Range(0f, 1f) < 0.1 * Time.deltaTime)
            {
                animator.SetBool("Ground", false);
                navMeshAgent.enabled = false;
                body.isKinematic = false;
                return;
            }

            await Awaitable.NextFrameAsync();
            if (health <= 0) return;
        }
    }

    async Awaitable Fall(bool gracefully = false)
    {
        if (Physics.Raycast(transform.position + Vector3.down * 5, Vector3.down * 1000, out var hitInfo))
        {
            if (!gracefully)
                animator.SetBool("Fall", true);
            else
                animator.SetBool("Ground", true);

            var point = hitInfo.point;

            var time = 1f;
            var startPosition = transform.position;
            var startTime = Time.time;

            while (Time.time < startTime + time)
            {
                var delta = (Time.time - startTime) / time;

                transform.position = Vector3.Lerp(startPosition, point, delta);

                await Awaitable.NextFrameAsync();
                if (health <= 0) return;
            }

            if (!gracefully)
            {
                await Awaitable.WaitForSecondsAsync(2f);
                if (health <= 0) return;
            }

            animator.SetBool("Ground", true);
            animator.SetBool("Fall", false);
        }
    }

    async Awaitable<bool> FlyTo(Transform to, float speed, bool canBeShot = false)
    {
        var time = Vector3.Distance(transform.position, to.position) / speed;

        var startPosition = transform.position;
        var startRotation = transform.rotation;
        var startTime = Time.time;

        var direction = to.position - startPosition;
        var targetRotation = Quaternion.LookRotation(direction);

        while (Time.time < startTime + time)
        {
            var delta = (Time.time - startTime) / time;
            transform.position = Vector3.Lerp(startPosition, to.position, delta);
            transform.rotation = Quaternion.Slerp(startRotation, targetRotation, Mathf.Pow(delta, 0.7f));

            await Awaitable.NextFrameAsync();
            if (health <= 0) return true;

            if (getShot)
            {
                getShot = false;
                if (canBeShot)
                    return true;
            }
        }

        return false;
    }
}
