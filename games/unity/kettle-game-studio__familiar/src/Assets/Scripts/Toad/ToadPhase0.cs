using UnityEngine;


[RequireComponent(typeof(Toad))]
public class ToadPhase0 : BattlePhase
{
    public float waitTime = 1;
    enum State { Idle, Wait };
    Toad toad;
    State state;
    float stateTimer;

    protected override void Start()
    {
        base.Start();
        toad = GetComponent<Toad>();
        SetState(State.Idle);
    }

    protected void Update()
    {
        stateTimer += Time.deltaTime;

        switch (state)
        {
            case State.Idle: IdleUpdate(); break;
            case State.Wait: WaitUpdate(); break;
        }
    }

    void IdleUpdate()
    { }

    void WaitUpdate()
    {
        if (stateTimer > waitTime)
            phaseOver = true;
    }

    void Hit(Transform from)
    {
        if (state != State.Idle) return;
        Debug.Log($"Hit (phase 0)!");
        toad.animator.SetBool("Sleep", false);
        SetState(State.Wait);
    }

    void SetState(State newState)
    {
        Debug.Log($"Toad (phase 0) state: {newState}");
        state = newState;
        stateTimer = 0;
    }

    public override void PhaseEnter() => toad.hittable.callback += Hit;
    public override void PhaseExit() => toad.hittable.callback -= Hit;
}
