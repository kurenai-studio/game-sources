using System;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;

[RequireComponent(typeof(Rigidbody2D))]
public class Player : MonoBehaviour
{
    public CameraController cameraController;
    public float hp = 3;
    public float speed = 1;
    public float parryTimeWindow = 0.5f;
    public float deadTime = 1;
    public Animator animator;
    public float damagePeriod = 1;
    public float attackPeriod = 1.5f;
    public float jumpTime = 1;
    public float jumpHigh = 1;
    public AnimationCurve jumpCurve;

    public float fallTime = 1;
    public float fallSpeed = 1;
    public AnimationCurve fallCurve;

    public float dashTime = 1;
    public float dashDistance = 1;
    public AnimationCurve dashCurve;

    public float attackTime = 1;
    public float attackDistance = 1;
    public AnimationCurve attackCurve;

    public float stunTime = 1;
    public float stunDistance = 1;
    public AnimationCurve stunCurve;

    public TriggerChecker jumpTrigger;
    public TriggerChecker attackTrigger;

    public AudioSource damageAudio;
    public AudioClip[] damageClips;
    public AudioClip[] attackClips;

    enum State { Jump, Fall, Walk, Dash, Attack, Stun, Dead }

    InputAction moveAction;
    InputAction jumpAction;
    InputAction dashAction;
    InputAction attackAction;

    Rigidbody2D body;

    State state = State.Fall;
    float stateTimer = 0;
    float takeDamageTimer = 0;
    float attackTimer = 0;
    float parryTimer = 0;
    Action<Transform> parryCallback = v => { };
    Transform parryTarget = null;
    bool canDash = true;
    float direction = 1;
    Vector2 velocity = Vector2.zero;

    void Start()
    {
        moveAction = InputSystem.actions.FindAction("Move");
        jumpAction = InputSystem.actions.FindAction("Jump");
        dashAction = InputSystem.actions.FindAction("Dash");
        attackAction = InputSystem.actions.FindAction("Attack");
        body = GetComponent<Rigidbody2D>();
    }

    void FixedUpdate()
    {
        stateTimer += Time.deltaTime;
        takeDamageTimer += Time.deltaTime;
        attackTimer += Time.deltaTime;
        Vector2 moveValue = moveAction.ReadValue<Vector2>();
        velocity = new Vector2(speed * moveValue.x, 0);

        switch (state)
        {
            case State.Walk: WalkUpdate(); break;
            case State.Fall: FallUpdate(); break;
            case State.Jump: JumpUpdate(); break;
            case State.Dash: DashUpdate(); break;
            case State.Stun: StunUpdate(); break;
            case State.Dead: DeadUpdate(); break;
            case State.Attack: AttackUpdate(); break;
        }

        if (state != State.Stun && state != State.Dead)
        {
            direction =
                velocity.x > 0 ? 1 :
                velocity.x < 0 ? -1 :
                direction;

            transform.localScale = new Vector3(direction < 0 ? -1 : 1, 1, 1);

            if (canDash && dashAction.IsPressed())
                Dash();

            if (state != State.Attack && attackAction.IsPressed())
                Attack();
        }

        if (parryTimer > 0 && parryTarget != null)
        {
            parryTimer -= Time.deltaTime;
            if (state == State.Attack && (direction > 0 == parryTarget.position.x - transform.position.x > 0))
            {
                parryCallback(transform);
                parryTimer = 0;
            }
            else if (parryTimer <= 0)
                TakeDamage(parryTarget);
        }

        body.linearVelocity = velocity;
        animator.SetBool("Move", Mathf.Abs(velocity.x) > 1e-5);
        animator.SetBool("Fall", state == State.Fall);
    }

    void WalkUpdate()
    {
        if (!jumpTrigger.isTriggered())
        {
            SetState(State.Fall);
            return;
        }
        if (jumpAction.IsPressed())
        {
            Jump();
            return;
        }
        canDash = true;
    }

    void FallUpdate()
    {
        if (jumpTrigger.isTriggered())
        {
            SetState(State.Walk);
            return;
        }
        float speedK = fallTime <= 0 ? -CurveTimeDerivative(fallCurve, fallTime) : 1;
        velocity.y = -speedK * fallSpeed;
    }

    void JumpUpdate()
    {
        if (stateTimer > jumpTime)
        {
            SetState(State.Fall);
            return;
        }
        velocity.y = CurveTimeDerivative(jumpCurve, jumpTime) * jumpHigh;
    }

    void DashUpdate()
    {
        if (stateTimer > dashTime)
        {
            SetState(State.Fall);
            return;
        }
        velocity.x = direction * CurveTimeDerivative(dashCurve, dashTime) * dashDistance;
    }

    void StunUpdate()
    {
        if (stateTimer > stunTime)
        {
            if (hp <= 0)
            {
                cameraController.BlackoutOn();
                animator.SetTrigger("Dead");
                SetState(State.Dead);
            }
            else
                SetState(State.Fall);
            return;
        }
        velocity.x = -direction * CurveTimeDerivative(stunCurve, stunTime) * stunDistance;
    }

    void DeadUpdate()
    {
        if (stateTimer > deadTime)
            SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
        velocity = Vector2.zero;
    }

    void AttackUpdate()
    {
        if (stateTimer > attackTime)
        {
            SetState(State.Fall);
            return;
        }
        velocity.x = direction * CurveTimeDerivative(attackCurve, attackTime) * attackDistance;
    }

    void Dash()
    {
        SetState(State.Dash);
        animator.SetTrigger("Dash");
        canDash = false;
    }

    void Attack()
    {
        if (attackTimer < attackPeriod)
            return;
        attackTimer = 0;
        animator.SetTrigger("Attack");
        SetState(State.Attack);
        damageAudio.clip = attackClips[UnityEngine.Random.Range(0, attackClips.Length - 1)];
        damageAudio.Play();
        foreach (Collider2D collider in attackTrigger.triggered)
        {
            Hittable hittable = collider.GetComponent<Hittable>();
            if (hittable != null)
                hittable.Hit(transform);
        }
    }

    void Jump()
    {
        SetState(State.Jump);
        animator.SetTrigger("Jump");
    }

    void Stun()
    {
        SetState(State.Stun);
        animator.SetTrigger("Stun");
        canDash = false;
    }

    void SetState(State newState)
    {
        // Debug.Log($"State: {newState}");
        state = newState;
        stateTimer = 0;
    }

    public void Parry(Transform from, Action<Transform> parryCallback)
    {
        parryTimer = parryTimeWindow;
        parryTarget = from;
        this.parryCallback = parryCallback;
    }

    public void TakeDamage(Transform from)
    {
        if (takeDamageTimer < damagePeriod)
            return;
        hp -= 1;
        direction = from.position.x > transform.position.x ? 1 : -1;
        takeDamageTimer = 0;
        damageAudio.clip = damageClips[UnityEngine.Random.Range(0, damageClips.Length - 1)];
        damageAudio.Play();
        Stun();
        Debug.Log($"Player damage ({hp} hp)");
    }

    float CurveTimeDerivative(AnimationCurve curve, float resolution)
    {
        float lastTime = stateTimer - Time.deltaTime;
        float h1 = curve.Evaluate(lastTime / resolution);
        float h2 = curve.Evaluate(stateTimer / resolution);
        return (h2 - h1) / Time.deltaTime;
    }
}
