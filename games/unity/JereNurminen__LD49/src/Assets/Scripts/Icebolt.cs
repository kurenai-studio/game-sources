using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Icebolt : MonoBehaviour, IProjectileSpell
{
    public PlayerController caster { get; set; }

    private Vector2 _target;
    public Vector2 target {
        get { return _target; }
        set {
            _target = value;
            direction = (_target - (Vector2)transform.position).normalized;
        }
    }
    public LayerMask layers;
    public int damage;
    public float freezeDuration;

    [SerializeField]
    private float _speed;
    public float speed { get { return _speed; } set { _speed = value; } }

    Vector2 direction;
    Animator animator;
    bool disabled = false;

    AudioSource audioSource;
    public AudioClip castSound;
    public AudioClip hitSound;

    // Start is called before the first frame update
    void Start()
    {
        direction = (_target - (Vector2)transform.position).normalized;
        animator = gameObject.GetComponent<Animator>();
        audioSource = GetComponent<AudioSource>();
        audioSource.PlayOneShot(castSound, 1);
    }

    public void Hit(GameObject hitTarget)
    {
        audioSource.PlayOneShot(hitSound, 1);
        direction = Vector2.zero;
        animator.SetTrigger("Hit");
        Health health = hitTarget.GetComponent<Health>();
        Goblin goblin = hitTarget.GetComponent<Goblin>();
        if (health != null) {
            health.TakeDamage(damage);
        }
        if (goblin) {
            goblin.Freeze(freezeDuration);
        }
        disabled = true;
    }

    public void CheckForHit(Vector2 newPos) {

    }

    public void Kill()
    {
        Destroy(gameObject);
    }

    public void Move()
    {
        if (!disabled) {
            Vector2 newPos = (Vector2)transform.position + direction * speed * Time.deltaTime;
            RaycastHit2D hit = Physics2D.Linecast(transform.position, newPos, layers);
            if (hit.collider != null) {
                newPos = hit.point;
                Hit(hit.collider.gameObject);
            }
            transform.position = newPos;
        }
    }

    public void AnimationDone() {
        Kill();
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        Move();
    }
}
