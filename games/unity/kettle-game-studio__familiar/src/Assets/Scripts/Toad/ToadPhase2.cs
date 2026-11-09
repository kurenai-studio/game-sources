using System.Collections.Generic;
using UnityEngine;


[RequireComponent(typeof(Toad))]
public class ToadPhase3 : BattlePhase
{
    public float jumpTime = 1;
    public float jumpHigh = 1;
    public float fallTime = 1;
    public AnimationCurve jumpCurve;
    public AnimationCurve fallCurve;
    public int flyCount = 10;
    public GameObject flyPrefab;

    enum State { Jump, Fall, Wait };
    Toad toad;
    State state;
    float stateTimer;
    List<Fly> flyContainer = new();

    protected override void Start()
    {
        base.Start();
        toad = GetComponent<Toad>();
        SetState(State.Jump);
    }

    protected void Update()
    {
        stateTimer += Time.deltaTime;

        switch (state)
        {
            case State.Jump: JumpUpdate(); break;
            case State.Fall: FallUpdate(); break;
            case State.Wait: WaitUpdate(); break;
        }
    }

    void JumpUpdate()
    {
        if (stateTimer > jumpTime)
        {
            for (int i = 0; i < flyCount; ++i)
            {
                GameObject flyObject = Instantiate(flyPrefab);
                Fly fly = flyObject.GetComponent<Fly>();
                fly.transform.position = new Vector3(
                    Random.Range(toad.leftSide.position.x, toad.rightSide.position.x),
                    15, fly.transform.position.z
                );
                if (fly != null)
                {
                    // fly.player = toad.player;
                    flyContainer.Add(fly);
                }
            }
            toad.animator.SetBool("Jump", false);
            SetState(State.Wait);
            return;
        }
        float curveValue = jumpCurve.Evaluate(stateTimer / jumpTime);
        toad.position.y = jumpHigh * curveValue;
        toad.shadowTransparency = curveValue;
    }

    void FallUpdate()
    {
        if (stateTimer > fallTime)
        {
            toad.position.y = 0;
            phaseOver = true;
            return;
        }
        float curveValue = 1 - fallCurve.Evaluate(stateTimer / fallTime);
        toad.position.y = jumpHigh * curveValue;
        toad.shadowTransparency = curveValue;
        toad.scaleDirection = Mathf.Sign(toad.position.x - toad.player.transform.position.x);
    }

    void WaitUpdate()
    {
        foreach (Fly fly in flyContainer)
            if (fly != null)
                return;
        toad.position.x = (toad.leftSide.position.x + toad.rightSide.position.x) / 2;
        SetState(State.Fall);
    }

    void SetState(State newState)
    {
        Debug.Log($"Toad (phase 2) state: {newState}");
        state = newState;
        stateTimer = 0;
    }

    public override void PhaseEnter()
    {
        toad.animator.SetBool("Jump", true);
        SetState(State.Jump);
    }
}
