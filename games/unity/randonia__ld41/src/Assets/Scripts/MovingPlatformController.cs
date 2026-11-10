using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum PlatformState
{
    WAITING,
    MOVING
}

public class MovingPlatformController : MonoBehaviour
{
    private Rigidbody mBody;

    private PlatformState mState = PlatformState.MOVING;
    private Vector3 mPathStart;
    public Vector3 mPathEnd;
    public float kMoveSpeed = 5.0f;
    private Vector3 mVelocity = Vector3.zero;
    private bool isForward = true;

    private Vector3 TargetPosition
    { get { return (isForward) ? mPathEnd : mPathStart; } }

    // Use this for initialization
    private void Start()
    {
        mPathStart = transform.position;
        mBody = GetComponent<Rigidbody>();
    }

    // Update is called once per frame
    private void Update()
    {
        switch (mState)
        {
            case PlatformState.MOVING:
                // Bounce if moving
                if ((TargetPosition - transform.position).sqrMagnitude < 0.0125f)
                {
                    mBody.MovePosition(TargetPosition);
                    isForward = !isForward;
                    mState = PlatformState.WAITING;
                    Invoke("ResumeMovement", 2.0f);
                }
                break;
        }
    }

    private void ResumeMovement()
    {
        mState = PlatformState.MOVING;
    }

    private void FixedUpdate()
    {
        if (mState == PlatformState.MOVING)
        {
            // Move toward the player
            Vector3 targetPosition = TargetPosition;
            Debug.DrawLine(transform.position, targetPosition, Color.yellow);
            Vector3 nextStepDir = (targetPosition - transform.position).normalized;
            Vector3 nextStepPosition = transform.position + nextStepDir * Time.deltaTime * kMoveSpeed;
            mBody.MovePosition(nextStepPosition);
        }
    }

    private void OnDrawGizmos()
    {
        Gizmos.DrawWireCube(mPathEnd, transform.localScale);
    }

    private void OnDrawGizmosSelected()
    {
        Debug.DrawLine(transform.position, mPathEnd, Color.magenta);
        Debug.DrawLine(transform.position, TargetPosition, Color.green);
        Gizmos.DrawSphere(mPathEnd, 0.1f);
    }
}