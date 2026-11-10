using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Blink : MonoBehaviour, IProjectileSpell
{
    public Vector2 target { get; set; }
    public PlayerController caster { get; set; }
    public LayerMask layers;
    public int damage;

    [SerializeField]
    private float _speed;
    public float speed { get { return _speed; } set { _speed = value; } }

    Vector2 direction;
    bool disabled = false;

    AudioSource audioSource;
    public AudioClip castSound;

    // Start is called before the first frame update
    void Start()
    {
        direction = (target - (Vector2)transform.position).normalized;
        caster.TeleportOut();
        audioSource = GetComponent<AudioSource>();
        audioSource.PlayOneShot(castSound, 1);
    }

    public void Hit(GameObject hitTarget)
    {
        disabled = true;
        direction = Vector2.zero;
        caster.TeleportIn();
        Kill();
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
            Vector2 oldPos = transform.position;
            Vector2 newPos = (Vector2)oldPos + direction * speed * Time.deltaTime;
            RaycastHit2D hit = Physics2D.Linecast(oldPos, newPos, layers);
            float distanceToTarget = Vector2.Distance(target, newPos);
            if (hit.collider != null) {
                newPos = oldPos;
                Hit(hit.collider.gameObject);
            } else if (distanceToTarget <= 8 ) {
                newPos = oldPos;
                Hit(gameObject);
            }
            transform.position = newPos;
            caster.transform.position = transform.position;
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
