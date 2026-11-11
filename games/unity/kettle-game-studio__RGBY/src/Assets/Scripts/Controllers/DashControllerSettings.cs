using System;
using UnityEngine;
using UnityEngine.InputSystem;


[CreateAssetMenu(menuName="Controller/DashController", fileName="DashController")]
public class DashControllerSettings : ControllerSettings
{
    public float time = 1;
    public float length = 5;
    public Vector3 direction = Vector3.forward;
    public AnimationCurve curve;

    public override IController Construct()
    {
        return new DashController(this);
    }
}

public class DashController : IController
{
    public bool Enabled { get; set; } = false;
    DashControllerSettings settings;
    InputAction dashAction;

    float dashTime = 0;
    bool isDashing = false;
    Vector3 direction;

    public DashController(DashControllerSettings settings)
    {
        this.settings = settings;
        dashAction = InputSystem.actions.FindAction("Jump");
    }

    public void Iterate(ControlState state)
    {
        if (isDashing)
        {
            state.flying = true;
            float h1 = settings.curve.Evaluate(dashTime / settings.time);
            dashTime += Time.deltaTime;
            float h2 = settings.curve.Evaluate(dashTime / settings.time);

            var velocity = (h2 - h1) * direction * settings.length / Time.deltaTime;

            state.velocity = new Vector3(
                velocity.x + state.velocity.x,
                velocity.y,
                velocity.z + state.velocity.z
            );

            state.gravity = false;

            if (dashTime > settings.time)
                isDashing = false;

            return;
        }

        if (!Enabled) return;

        if (dashAction.IsPressed())
        {
            isDashing = true;
            state.flying = true;
            direction = state.forwardRotation * settings.direction;
            dashTime = 0;
        }
    }
}
