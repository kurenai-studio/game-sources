using System;
using UnityEngine;
using UnityEngine.InputSystem;


[CreateAssetMenu(menuName="Controller/JumpController", fileName="JumpController")]
public class JumpControllerSettings : ControllerSettings
{
    public float height = 1;
    public float time = 1;
    public float coyoteTime = 0.1f;
    public AnimationCurve curve;

    public override IController Construct()
    {
        return new JumpController(this);
    }
}

public class JumpController : IController
{
    public bool Enabled { get; set; } = false;
    JumpControllerSettings settings;
    InputAction jumpAction;

    float jumpTime = 0;
    bool isJumping = false;

    public JumpController(JumpControllerSettings settings)
    {
        this.settings = settings;
        jumpAction = InputSystem.actions.FindAction("Jump");
    }

    public void Iterate(ControlState state)
    {
        if (isJumping)
        {
            float h1 = settings.curve.Evaluate(jumpTime / settings.time);
            jumpTime += Time.deltaTime;
            float h2 = settings.curve.Evaluate(jumpTime / settings.time);

            float yVelocity = (h2 - h1) * settings.height / Time.deltaTime;

            state.velocity = new Vector3(state.velocity.x, yVelocity, state.velocity.z);
            state.gravity = false;

            if (jumpTime > settings.time)
                isJumping = false;

            return;
        }

        if (!Enabled) return;

        if (jumpAction.IsPressed() && state.jumper.CanJump(settings.coyoteTime))
        {
            isJumping = true;
            jumpTime = 0;
            state.jumper.Reset();
        }
    }
}
