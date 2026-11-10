using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using JetBrains.Annotations;
using UnityEngine;

public class ImpController : MonoBehaviour
{
    public float speed = 1.0f;
    public float sightRange = 1.0f;
    public AnimationCurve floatCurve;
    public bool isEnraged = false;

    public LayerMask targetLayers;
    public LayerMask killLayers;
    public AudioClip attackSound;

    private Health health;
    private GameObject player;
    private SpriteRenderer spriteRenderer;
    private Animator animator;
    private Vector2 movement = Vector2.zero;

    private Vector2 startPosition;

    private bool isAwake = false;
    private bool isAlive = true;

    // Start is called before the first frame update
    void Start()
    {
        health = GetComponent<Health>();
        spriteRenderer = GetComponent<SpriteRenderer>();
        animator = GetComponent<Animator>();
        player = GameObject.Find("Player");
        startPosition = transform.position;
    }

    public void OnDeathAnimationEnd()
    {
        Destroy(gameObject);
    }

    public void OnAwakenAnimationEnd()
    {
        Attack();
    }

    public void OnDeath()
    {
        animator.SetTrigger("hit");
        movement = Vector2.zero;
        isAlive = false;
    }

    void Attack()
    {
        isAwake = true;
        movement = (player.transform.position - transform.position).normalized * speed;
        AudioSource.PlayClipAtPoint(attackSound, transform.position);
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (!isAlive)
        {
            return;
        }
        Debug.Log("Imp collided with " + collision.gameObject.name);
        var collisionHealth = collision.gameObject.GetComponent<Health>();

        if (targetLayers == (targetLayers | (1 << collision.gameObject.layer)))
        {
            collisionHealth.TakeDamage(1);
        }

        if (
            killLayers == (killLayers | (1 << collision.gameObject.layer))
            && (collisionHealth == null || !collisionHealth.isDead)
        )
        {
            health.TakeDamage(1);
            OnDeath();
        }
    }

    Vector2 GetSineWaveMovement()
    {
        return new Vector2(
            transform.position.x,
            startPosition.y + floatCurve.Evaluate(Time.time * floatCurve.length)
        );
    }

    // Update is called once per frame
    void Update()
    {
        if (
            (isEnraged && !health.isDead)
            || !isAwake
                && !health.isDead
                && spriteRenderer.isVisible
                && (
                    isEnraged
                    || (player.transform.position - transform.position).magnitude < sightRange
                )
        )
        {
            animator.SetTrigger("attack");
            transform.localScale = new Vector2(
                player.transform.position.x > transform.position.x ? -1 : 1,
                1
            );
        }
        else if (!isAwake)
        {
            transform.position = GetSineWaveMovement();
        }
        else
        {
            transform.Translate(movement * Time.deltaTime);
        }
    }
}
