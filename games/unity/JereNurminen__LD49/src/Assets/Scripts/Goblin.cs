using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Goblin : MonoBehaviour
{
    public float walkSpeed;
    public float runSpeed;
    public Vector2 patrolStartPos;
    public Vector2 patrolEndPos;
    public LayerMask layersThatBlockVision;
    public LayerMask wallLayers;
    public float polymorphSpeed;
    public float polymorphHealth;

    private bool isComingBackToStart = false;
    private Vector2 lastSeenPlayerPos;
    private Vector2 moveTarget;
    private bool hasSeenPlayer = false;
    private bool seesPlayer = false;
    private bool isPatrolling = true;
    private GameObject player;
    private PlayerController playerController;
    private Melee melee;
    private List<RaycastHit2D> lastFrameHits = new List<RaycastHit2D>();
    private Vector2 lastPos;
    private Animator animator;
    private Health health;
    private BoxCollider2D boxCollider;
    private bool frozen;

    public bool alive = true;
    public bool polymorphed;

    AudioSource audioSource;
    public AudioClip dieSound;

    public void OnDrawGizmos() {
        #if UNITY_EDITOR
        Utils.DrawCrossOnPoint(
            patrolStartPos,
            1,
            Color.green
            );
        Debug.DrawLine((Vector2)transform.position + patrolStartPos, (Vector2)transform.position + patrolEndPos, Color.green);
        Utils.DrawCrossOnPoint(
            patrolStartPos + patrolEndPos,
            1,
            Color.green
            );
        #endif
    }

    // Start is called before the first frame update
    void Start()
    {
        patrolStartPos = transform.position;
        patrolEndPos = (Vector2)transform.position + patrolEndPos;
        player = GameObject.FindWithTag("Player");
        playerController = player.GetComponent<PlayerController>();
        health = GetComponent<Health>();
        melee = GetComponentInChildren<Melee>();
        animator = GetComponent<Animator>();
        boxCollider = GetComponent<BoxCollider2D>();
        audioSource = GetComponent<AudioSource>();
        InvokeRepeating("CheckSightToPlayer", 1f, .25f);
    }

    public void Polymorph() {
        polymorphed = true;
        animator.SetBool("Polymorphed", true);
        health.currentHealth = 2;
    }

    void UnFreeze() {
        frozen = false;
        animator.SetBool("Frozen", false);
    }

    IEnumerator UnFreezeCoroutine(float duration) {
        yield return new WaitForSeconds(duration);
        UnFreeze();
    }

    public void Freeze(float duration) {
        frozen = true;
        animator.SetBool("Frozen", true);
        StartCoroutine(UnFreezeCoroutine(duration));
    }

    public void Die() {
        alive = false;
        animator.SetTrigger("Death");
        boxCollider.enabled = false;
        audioSource.PlayOneShot(dieSound, 1f);
        CancelInvoke();
    }

    void CheckSightToPlayer()
    {
        if (alive && !frozen && !polymorphed && playerController.visible) {
            RaycastHit2D hit = Physics2D.Linecast(transform.position, player.transform.position, layersThatBlockVision);
            Debug.DrawLine(transform.position, player.transform.position, Color.green, .25f);

            if (hit.collider.gameObject.tag == "Player") {
                hasSeenPlayer = true;
                seesPlayer = true;
                lastSeenPlayerPos = hit.point;
                moveTarget = lastSeenPlayerPos;
                isPatrolling = false;
            } else {
                seesPlayer = false;
            }
        }
    }

    void Move()
    {
        Vector2 target =
            hasSeenPlayer
                ? lastSeenPlayerPos
                : isComingBackToStart
                    ? patrolStartPos
                    : patrolEndPos;

        Vector2 move = ( target - (Vector2)transform.position ).normalized;
        List<RaycastHit2D> hits = Utils.Move(gameObject, !hasSeenPlayer ? walkSpeed : runSpeed, wallLayers, move);

        if (!hasSeenPlayer && Vector2.Distance(transform.position, isComingBackToStart ? patrolStartPos : patrolEndPos) < 8) {
            isComingBackToStart = !isComingBackToStart;
        } 
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        if (alive && !frozen && !polymorphed) { 
            animator.SetBool("Walking", true);
            if ( hasSeenPlayer ) {
                CheckSightToPlayer();
            }
            Move();
            if (
                Vector2.Distance(transform.position, player.transform.position) <= melee.meleeRange &&
                !playerController.dead &&
                playerController.visible
            ) {
                melee.Swing(player.transform.position);
            }
            
            if ( lastPos.x < transform.position.x) {
                transform.localScale = new Vector2(1, 1); 
            } else {
                transform.localScale = new Vector2(-1, 1); 
            }

            lastPos = transform.position;
        }
    }

    void Update()
    {
    }
}
