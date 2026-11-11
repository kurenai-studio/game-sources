using UnityEngine;

public class JumpCollider : MonoBehaviour
{
    public bool jumpFlag {get; private set;} = false;
    public float lastSetTime {get; private set;} = 0;
    public bool inAir {get; private set;} = false;

    public bool CanJump(float coyoteTime)
    {
        return Time.time - lastSetTime < coyoteTime;
    }

    public void Reset()
    {
        jumpFlag = false;
    }

    void OnTriggerStay(Collider collider)
    {
        inAir = false;
        if (collider.tag != "Obstacle")
        {
            jumpFlag = true;
            lastSetTime = Time.time;
        }
    }

    void OnTriggerExit(Collider collider)
    {
        inAir = true;
    }
}
