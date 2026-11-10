using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class CommandStreamCharacter : MonoBehaviour
{

    public enum Action
    {
        LeftDown,
        LeftUp,
        RightDown,
        RightUp,
        Jump,
        Slide,
        Attack,
        Disable,
        Status,
    }

    public struct Event
    {
        public float time;
        public Action action;
        public Vector2 position;
        public Vector2 velocity;

        public Event(float time, Action action, Vector2 position, Vector2 velocity)
        {
            this.time = time;
            this.action = action;
            this.position = position;
            this.velocity = velocity;
        }
    }

    public bool activePlayer = false;
    // public float positionPingInterval = 0.1f;
    public ParticleSystem moveFX;

    [Header("Horisontal Movement")]
    public float runSpeed = 10f;
    public float smoothTime = 0.1f;
    public float smoothTimeAir = 0.8f;

    [Header("Vertical Movement")]
    public bool canJump = true;
    public float jumpSpeed = 10f;
    [SerializeField] Vector2 groundCheckPoint = Vector2.zero;
    [SerializeField] LayerMask groundCheckMask;
    [SerializeField] float groundCheckRadius = 0.05f;
    public bool canDoubleJump = true;
    public bool canWallJump = true;
    [SerializeField] Vector2 wallCheckPointLeft = new Vector2(-0.5f, 1f);
    [SerializeField] Vector2 wallCheckPointRight = new Vector2(0.5f, 1f);

    [Header("Sliding")]
    public bool canSlide = true;
    public float slideSpeed = 18f;

    [Header("Attacking")]
    public bool canAttack = true;
    public float attackDuration = 0.5f;
    public float attackCooldown = 0.2f;
    public Vector2 attackOrigin = Vector2.up;
    public float attackDistance = 0.8f;
    [SerializeField] TrailRenderer attackFX;

    // Privates
    private float startTime;
    private Vector3 startPos;
    private List<Event> stream;
    private int index;
    private Rigidbody2D rb;
    private float horisontalMovement = 0;
    private Vector2 velocity;
    private float slideTime;
    private bool hasDoubleJumped;
    private bool atGround;
    private bool atLeftWall;
    private bool atRightWall;
    private float attackTime;
    private Collider2D[] raycastCache;
    private AudioSource attackAudio;

    private void Start()
    {
        if (stream == null)
            stream = new List<Event>();
        rb = GetComponent<Rigidbody2D>();
        startPos = transform.position;
        Reset();
        if (GameManager.instance != null)
            GameManager.instance.RegisterCharacter(this);
        raycastCache = new Collider2D[10];
        attackAudio = attackFX.GetComponent<AudioSource>();
    }

    void Update()
    {
        if (activePlayer)
        {
            if (Input.GetKeyDown(KeyCode.A) || Input.GetKeyDown(KeyCode.LeftArrow))
            {
                RecordAction(Action.LeftDown);
            }
            if (Input.GetKeyUp(KeyCode.A) || Input.GetKeyUp(KeyCode.LeftArrow))
            {
                RecordAction(Action.LeftUp);
            }
            if (Input.GetKeyDown(KeyCode.D) || Input.GetKeyDown(KeyCode.RightArrow))
            {
                RecordAction(Action.RightDown);
            }
            if (Input.GetKeyUp(KeyCode.D) || Input.GetKeyUp(KeyCode.RightArrow))
            {
                RecordAction(Action.RightUp);
            }
            if (Input.GetKeyDown(KeyCode.Space) || Input.GetKeyDown(KeyCode.W) || Input.GetKeyDown(KeyCode.UpArrow))
            {
                if (canJump)
                    RecordAction(Action.Jump);
            }
            if (Input.GetKeyDown(KeyCode.S) || Input.GetKeyDown(KeyCode.DownArrow))
            {
                if (canSlide && Time.time > slideTime)
                {
                    RecordAction(Action.Slide);
                }
            }
            if (Input.GetKeyDown(KeyCode.LeftShift) || Input.GetKeyDown(KeyCode.RightShift))
            {
                if (canAttack && Time.time > attackTime + attackDuration + attackCooldown)
                    RecordAction(Action.Attack);
            }
            // if (stream.Count > 0)
            // {
            //     if (Time.time - stream[stream.Count - 1].time - startTime > positionPingInterval)
            //         AddActionToStreamNow(Action.Status);
            // }
        }
        else
        {
            if (stream.Count > index && Time.time - startTime >= stream[index].time)
            {
                if (Vector3.Distance(stream[index].position, rb.position) < groundCheckRadius * 0.8)
                {
                    rb.position = stream[index].position;
                    rb.velocity = stream[index].velocity;
                }
                TakeAction(stream[index].action);
                index++;
            }
        }
    }

    private void OnDisable()
    {
        if (activePlayer)
            AddActionToStreamNow(Action.Disable);
        horisontalMovement = 0;
        velocity = Vector2.zero;
        rb.velocity = Vector2.zero;
    }

    internal Vector3 GetSpawn()
    {
        return startPos;
    }

    internal bool SetSpawn(Vector3 pos)
    {
        if (Vector3.Distance(startPos, pos) < 1f)
            return false;
        startPos = pos;
        if (rb != null)
            Reset();
        return true;
    }

    void TakeAction(Action action)
    {
        switch (action)
        {
            case Action.LeftDown:
                horisontalMovement--;
                MaybeFlip();
                break;
            case Action.LeftUp:
                horisontalMovement++;
                MaybeFlip();
                break;
            case Action.RightDown:
                horisontalMovement++;
                MaybeFlip();
                break;
            case Action.RightUp:
                horisontalMovement--;
                MaybeFlip();
                break;
            case Action.Jump:
                if (atGround)
                {
                    var vel = rb.velocity;
                    vel.y = jumpSpeed;
                    rb.velocity = vel;
                    velocity = Vector2.zero;
                    if (moveFX)
                        moveFX.Play();
                }
                else if (canWallJump && atLeftWall)
                {
                    rb.velocity = new Vector2(jumpSpeed, jumpSpeed);
                    velocity = Vector2.zero;
                    if (moveFX)
                        moveFX.Play();
                }
                else if (canWallJump && atRightWall)
                {
                    rb.velocity = new Vector2(-jumpSpeed, jumpSpeed);
                    velocity = Vector2.zero;
                    if (moveFX)
                        moveFX.Play();
                }
                else if (canDoubleJump && !hasDoubleJumped)
                {
                    var vel = rb.velocity;
                    vel.y = jumpSpeed;
                    rb.velocity = vel;
                    velocity = Vector2.zero;
                    hasDoubleJumped = true;
                    if (moveFX)
                        moveFX.Play();
                }
                break;
            case Action.Slide:
                {
                    if (moveFX)
                        moveFX.Play();
                    slideTime = Time.time + smoothTimeAir - 0.1f;
                    var vel = rb.velocity;
                    vel.x += horisontalMovement * slideSpeed;
                    rb.velocity = vel;
                    velocity = Vector2.zero;
                }
                break;
            case Action.Attack:
                attackTime = Time.time;
                StartCoroutine(AttackCoroutine());
                break;
            case Action.Disable:
                gameObject.SetActive(false);
                break;
            case Action.Status:
                break;
            default:
                Debug.LogError("Action not implemented");
                break;
        }
    }

    void MaybeFlip()
    {
        if (horisontalMovement < 0)
        {
            var scale = transform.localScale;
            scale.x = -1f;
            transform.localScale = scale;
        }
        else if (horisontalMovement > 0)
        {
            var scale = transform.localScale;
            scale.x = 1f;
            transform.localScale = scale;
        }
    }

    void RecordAction(Action action)
    {
        stream.Add(new Event(Time.time - startTime, action, rb.position, rb.velocity));
        TakeAction(action);
    }

    public void AddActionToStreamNow(Action action)
    {
        stream.Add(new Event(Time.time - startTime, action, rb.position, rb.velocity));
    }

    private void FixedUpdate()
    {
        bool wasGrounded = atGround;
        atGround = Physics2D.OverlapCircle(rb.position + groundCheckPoint, groundCheckRadius, groundCheckMask);
        if (!wasGrounded & atGround && moveFX)
            moveFX.Play();
        if (atGround)
            hasDoubleJumped = false;
        atRightWall = Physics2D.OverlapCircle(rb.position + wallCheckPointRight, groundCheckRadius, groundCheckMask);
        atLeftWall = Physics2D.OverlapCircle(rb.position + wallCheckPointLeft, groundCheckRadius, groundCheckMask);
        var vel = rb.velocity;
        vel.x = horisontalMovement * runSpeed;
        if (atGround && Time.time > slideTime)
            vel = Vector2.SmoothDamp(rb.velocity, vel, ref velocity, smoothTime);
        else
            vel = Vector2.SmoothDamp(rb.velocity, vel, ref velocity, smoothTimeAir);
        if (atRightWall && !atGround && horisontalMovement > 0)
            vel.y = Mathf.Max(vel.y, 0f);
        if (atLeftWall && !atGround && horisontalMovement < 0)
            vel.y = Mathf.Max(vel.y, 0f);
        rb.velocity = vel;
    }

    IEnumerator AttackCoroutine()
    {
        float dir = transform.localScale.x;
        attackFX.transform.position = rb.position + attackOrigin + new Vector2(dir * Mathf.Cos(-1.22f), Mathf.Sin(-1.22f)) * attackDistance;
        //TODO: sound
        yield return new WaitForFixedUpdate();
        attackFX.Clear();
        attackFX.gameObject.SetActive(true);
        if (attackAudio)
            attackAudio.Play();
        var frac = (Time.time - attackTime) / attackDuration;
        while (frac < 1.0)
        {
            float angle = 1.22f; // = 70 degrees
            angle *= 2 * frac - 1f;
            var pos = rb.position + attackOrigin + new Vector2(dir * Mathf.Cos(angle), Mathf.Sin(angle)) * attackDistance;
            attackFX.transform.position = pos;
            int hits = Physics2D.OverlapCircleNonAlloc(pos, 0.1f, raycastCache);
            if (hits > 0)
            {
                for (int i = 0; i < hits; i++)
                {
                    if (raycastCache[i].attachedRigidbody != null && raycastCache[i].attachedRigidbody != rb)
                    {
                        var d = raycastCache[i].attachedRigidbody.GetComponent<Destructable>();
                        if (d != null)
                            d.Die();
                    }
                }
            }
            yield return new WaitForFixedUpdate();
            frac = (Time.time - attackTime) / attackDuration;
        }
        yield return new WaitForSeconds(0.1f);
        attackFX.gameObject.SetActive(false);
    }

    public void Reset()
    {
        startTime = Time.time;
        index = 0;
        transform.position = startPos;
        rb.position = startPos;
        rb.velocity = Vector2.zero;
        velocity = Vector2.zero;
        rb.WakeUp();
        slideTime = -10f;
        hasDoubleJumped = false;
        atGround = true;
        atRightWall = false;
        atLeftWall = false;
        gameObject.SetActive(true);
        horisontalMovement = 0f;
        if (activePlayer)
        {
            stream.Clear();
            if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow))
                RecordAction(Action.RightDown);
            if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow))
                RecordAction(Action.LeftDown);
        }
        attackTime = -10f;
        attackFX.gameObject.SetActive(false);
        StopAllCoroutines();
    }

    public void SetStream(List<Event> stream)
    {
        this.stream = stream;
    }

    public List<Event> GetStream()
    {
        return stream;
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.cyan;
        Gizmos.DrawWireSphere(transform.position + (Vector3)groundCheckPoint, groundCheckRadius);
        Gizmos.DrawWireSphere(transform.position + (Vector3)wallCheckPointLeft, groundCheckRadius);
        Gizmos.DrawWireSphere(transform.position + (Vector3)wallCheckPointRight, groundCheckRadius);
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position + (Vector3)attackOrigin, attackDistance);
    }

    public void EnableAttacking()
    {
        canAttack = true;
    }
}
