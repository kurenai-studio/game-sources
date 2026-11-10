using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum Direction

{
    LEFT = 0,
    RIGHT = 1
}

public enum PlayerState
{
    RUNNING,
    IDLE
}

public enum AnimationState
{
    Idle = 0,
    Jump = 1,
    Running = 2
}

public enum JumpForce
{
    LOW,
    HIGH
}

public class PlayerController : MonoBehaviour
{
    private Rigidbody body;
    public float kJumpPower = 30f;
    public float kRunSpeed = 1.0f;
    public float kPlayerCastSizeX = 0.25f;
    private Animator mAnimator;
    private float mDistToRun;
    private float mTimeAtWall;
    private Vector3 mRunStartPos;
    private Direction mRunDir;
    private PlayerState mState = PlayerState.IDLE;

    public float kControlCheckDist = 0.5f;
    private bool mIsGrounded = false;
    private bool mIsStillJumping = false;
    private LayerMask mGroundedIgnoreMask;

    // Use this for initialization
    private void Start()
    {
        Debug.Log("Hello player here");
        body = GetComponent<Rigidbody>();
        mGroundedIgnoreMask = ~LayerMask.GetMask("player");
        mAnimator = GetComponent<Animator>();
    }

    // Update is called once per frame
    private void Update()
    {
        Vector3 dirVec = -transform.up;
        const float kGroundCheckDist = 1.0f;
        Vector3 castPointLeft = transform.position + Vector3.left * kPlayerCastSizeX;
        Vector3 castPointCenter = transform.position;
        Vector3 castPointRight = transform.position + Vector3.right * kPlayerCastSizeX;
        Debug.DrawRay(castPointLeft, dirVec * kGroundCheckDist, Color.red);
        Debug.DrawRay(castPointCenter, dirVec * kGroundCheckDist, Color.red);
        Debug.DrawRay(castPointRight, dirVec * kGroundCheckDist, Color.red);
        bool leftGround = Physics.Raycast(castPointLeft, dirVec, kGroundCheckDist, mGroundedIgnoreMask);
        bool centerGround = Physics.Raycast(castPointCenter, dirVec, kGroundCheckDist, mGroundedIgnoreMask);
        bool rightGround = Physics.Raycast(castPointRight, dirVec, kGroundCheckDist, mGroundedIgnoreMask);
        mIsGrounded = leftGround || centerGround || rightGround;
        SetAnimationState();
    }

    private void SetAnimationState()
    {
        if (!mIsStillJumping)
            switch (mState)
            {
                case PlayerState.IDLE:
                    mAnimator.SetInteger("State", (int)AnimationState.Idle);
                    break;
                case PlayerState.RUNNING:
                    mAnimator.SetInteger("State", (int)AnimationState.Running);
                    break;
            }
    }

    private void DoRun()
    {
        // Check if we've run far enough
        if (mDistToRun <= Mathf.Abs(transform.position.x - mRunStartPos.x))
        {
            // We've run exactly far enough, stop running
            Debug.Log("Exactly enough running");
            Vector3 newPos = transform.position;
            newPos.x = Mathf.Round(transform.position.x);
            transform.position = newPos;
            mState = PlayerState.IDLE;
        }
        else if (mTimeAtWall >= 1)
        {
            // Test if we've been at a wall too long
            mState = PlayerState.IDLE;
            mDistToRun = 0;
        }
        else
        {
            // Finally, just keep moving
            MoveDirection(mRunDir);
        }
    }

    private void MoveDirection(Direction dir)
    {
        // Cast a capsule toward the direction
        Vector3 dirVec = Vector3.zero;
        Vector3 newPosition = transform.position;
        switch (mRunDir)
        {
            case Direction.LEFT:
                dirVec = Vector3.left;
                break;
            case Direction.RIGHT:
                dirVec = Vector3.right;
                break;
        }
        // Instead of doing a capsule just #CLAMJAM it
        Vector3 castPointBottom = transform.position + (-transform.up * 0.35f);
        Vector3 castPointCenter = transform.position;
        Vector3 castPointTop = transform.position + transform.up * 0.45f;
        Debug.DrawRay(castPointBottom, dirVec * kControlCheckDist, Color.blue);
        Debug.DrawRay(castPointCenter, dirVec * kControlCheckDist, Color.blue);
        Debug.DrawRay(castPointTop, dirVec * kControlCheckDist, Color.blue);
        bool bottomCastHit = Physics.Raycast(castPointBottom, dirVec, kControlCheckDist, mGroundedIgnoreMask);
        bool centerCastHit = Physics.Raycast(castPointBottom, dirVec, kControlCheckDist, mGroundedIgnoreMask);
        bool topCastHit = Physics.Raycast(castPointBottom, dirVec, kControlCheckDist, mGroundedIgnoreMask);
        newPosition += dirVec * kRunSpeed * Time.deltaTime;
        if (bottomCastHit || centerCastHit || topCastHit)
        {
            // Increase the time spent at the wall
            mTimeAtWall += Time.deltaTime;
        }
        else // We're free to run!
        {
            body.MovePosition(newPosition);
        }
    }

    private void FixedUpdate()
    {
        if (mState == PlayerState.RUNNING)
        {
            DoRun();
        }
        Debug.DrawRay(transform.position, Vector3.left * kControlCheckDist, Color.yellow);
        Debug.DrawRay(transform.position, Vector3.right * kControlCheckDist, Color.yellow);
    }

    public void ActOnCard(PlayingCardController card, int multiplier = 1)
    {
        Debug.Log("Player acting on card: " + card.gameObject.name);
        switch (card.cardType)
        {
            case CardType.RunLeft:
                ActionRunLeft(card.cardPower * multiplier);
                break;
            case CardType.RunRight:
                ActionRunRight(card.cardPower * multiplier);
                break;
            case CardType.JumpLow:
                ActionJumpLow();
                break;
            case CardType.JumpHigh:
                ActionJumpHigh();
                break;
            case CardType.Block:
                break;
        }
    }

    public void ActOnCardPair(PlayingCardController card1, PlayingCardController card2)
    {
        // Handle two run cards
        if ((card1.cardType == CardType.RunLeft || card1.cardType == CardType.RunRight) &&
                (card2.cardType == CardType.RunLeft || card2.cardType == CardType.RunRight))
        {
            // Sum up the powers and make them the end result
            float card1RelPower = ((card1.cardType == CardType.RunLeft) ? -1 : 1) * card1.cardPower;
            float card2RelPower = ((card2.cardType == CardType.RunLeft) ? -1 : 1) * card2.cardPower;
            float relativeSumPower = card1RelPower + card2RelPower;
            Direction sumDirection = (relativeSumPower < 0) ? Direction.LEFT : Direction.RIGHT;
            if (relativeSumPower == 0)
            {
                // Do nothing for zero sum
                return;
            }
            ActionRun(sumDirection, Mathf.Abs(relativeSumPower));
        }
        else
        {
            int multiplier = 1;
            // Jump level 2 doubles a move
            if (card1.cardType == CardType.JumpHigh || card2.cardType == CardType.JumpHigh)
            {
                multiplier = 2;
            }
            ActOnCard(card1, multiplier);
            ActOnCard(card2, multiplier);
        }
    }

    private void CheckIsStillJumpingRecursive()
    {
        if (mIsGrounded)
        {
            mIsStillJumping = false;
        }
        else
        {
            // CLAMJAM
            Invoke("CheckIsStillJumpingRecursive", 0.125f);
        }
    }

    #region User Actions

    public void ActionJumpLow()
    {
        Debug.Log("Player Jumpin Low");
        ActionJump(JumpForce.LOW);
    }

    public void ActionJumpHigh()
    {
        Debug.Log("Player Jumpin High");
        ActionJump(JumpForce.HIGH);
    }

    public void ActionJump(JumpForce jumpForce)
    {
        if (mIsGrounded)
        {
            float jumpMod = (jumpForce == JumpForce.LOW) ? 0.75f : 1.0f;
            body.AddForce(Vector3.up * kJumpPower * jumpMod, ForceMode.Impulse);
            mAnimator.SetInteger("State", (int)AnimationState.Jump);
            mIsStillJumping = true;
            Invoke("CheckIsStillJumpingRecursive", 0.5f);
        }
    }

    public void ActionRunLeft(float dist)
    {
        ActionRun(Direction.LEFT, dist);
    }

    public void ActionRunRight(float dist)
    {
        ActionRun(Direction.RIGHT, dist);
    }

    private void ActionRun(Direction dir, float dist)
    {
        Debug.Log("Moving card power: " + dist);
        mState = PlayerState.RUNNING;
        mRunDir = dir;
        mRunStartPos = transform.position;
        mTimeAtWall = 0;
        mDistToRun = dist;
    }

    #endregion User Actions

    public void OnDrawGizmos()
    {
        string[] stringsToDraw = new string[]
        {
            mState.ToString(),
            string.Format("isGrounded: {0}", mIsGrounded),
            string.Format("mDistToRun: {0}", mDistToRun),
            string.Format("distanceRun: {0}", Mathf.Abs(transform.position.x - mRunStartPos.x)),
            string.Format("wallTime: {0}", mTimeAtWall.ToString())
        };

        Vector3 drawStart = transform.position;
        Vector3 drawStep = transform.up * 0.2f;
        for (int count = 0; count < stringsToDraw.Length; ++count)
        {
            TextGizmo.Instance.DrawText(drawStart + (count * drawStep), stringsToDraw[count]);
        }
    }
}