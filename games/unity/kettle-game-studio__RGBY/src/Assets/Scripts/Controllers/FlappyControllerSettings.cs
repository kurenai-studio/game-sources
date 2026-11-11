using System;
using UnityEngine;
using UnityEngine.InputSystem;


[CreateAssetMenu(menuName = "Controller/FlappyController", fileName = "FlappyController")]
public class FlappyControllerSettings : ControllerSettings
{
    public float period = 1;
    public float height = 1;

    public override IController Construct()
    {
        return new FlappyController(this);
    }
}

public class FlappyController : IController
{
    public bool Enabled { get; set; } = false;
    FlappyControllerSettings settings;
    InputAction jumpAction;
    float lastJumpTime = 0;

    public FlappyController(FlappyControllerSettings settings)
    {
        this.settings = settings;
        jumpAction = InputSystem.actions.FindAction("Jump");
    }

    public void Iterate(ControlState state)
    {
        if (!Enabled) return;

        if (jumpAction.IsPressed() && Time.time - lastJumpTime > settings.period)
        {
            state.flying = true;
            lastJumpTime = Time.time;
            float yVelocity = Mathf.Sqrt(Mathf.Abs(2 * Physics.gravity.y * settings.height));
            state.velocity = new Vector3(state.velocity.x, yVelocity, state.velocity.z);
        }
    }
}
