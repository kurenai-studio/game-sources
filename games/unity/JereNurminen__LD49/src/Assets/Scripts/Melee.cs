using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Melee : MonoBehaviour
{
    public LayerMask targetLayers;
    public int meleeRange;
    public float cooldown;
    public float knockback;
    public int damage;

    BoxCollider2D boxCollider;
    Animator animator;
    float cooldownLeft;
    bool hasHitSomething = false;

    // Start is called before the first frame update
    void Start()
    {
        animator = GetComponent<Animator>();
        boxCollider = GetComponent<BoxCollider2D>();
    }

    public void Swing(Vector2 targetPos)
    {
        if (cooldownLeft > 0) {
            return;
        }

        float angle = -Vector2.SignedAngle(Vector2.down, ( (Vector2)transform.position - targetPos ).normalized);

        if ( angle >= -22.5 && angle < 22.5 ) {
            animator.SetTrigger("Up");
        } else if ( angle >= 22.5 && angle < 67.5 ) {
            animator.SetTrigger("UpRight");
        } else if ( angle >= 67.5 && angle < 112.5 ) {
            animator.SetTrigger("Right");
        } else if ( angle >= 112.5 && angle < 157.5 ) {
            animator.SetTrigger("DownRight");
        } else if ( angle >= 157.5 || angle <= -157.5 ) { // angles larger than 180 will be negative
            animator.SetTrigger("Down");
        } else if ( angle > -157.5 && angle < -112.5 ) {
            animator.SetTrigger("DownLeft");
        } else if ( angle >= -112.5 && angle < -67.5 ) {
            animator.SetTrigger("Left");
        } else if ( angle >= -67.5 && angle < -22.5) {
            animator.SetTrigger("UpLeft");
        }

        cooldownLeft = cooldown;
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        if ( !hasHitSomething && Utils.IsLayerInLayerMask(other.gameObject.layer, targetLayers) ) {
            Debug.Log(other.gameObject.name + " hit!");
            Health health = other.gameObject.GetComponent<Health>();
            health.TakeDamage(damage);
            hasHitSomething = true;
        }
    }

    // Update is called once per frame
    void Update()
    {
        if ( cooldownLeft > 0 ) {
            cooldownLeft -= Time.deltaTime;
        } else {
            hasHitSomething = false;
        }
    }
}
