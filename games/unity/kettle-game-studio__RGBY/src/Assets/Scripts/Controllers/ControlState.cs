using UnityEngine;


public class ControlState
{
    // Global state
    public JumpCollider jumper;
    public Transform transform;
    public Animator animator;

    // Frame state
    public Quaternion forwardRotation;
    public Quaternion lookRotation;

    // Output
    public bool gravity;
    public Vector3 velocity;
    public bool flying;
}
