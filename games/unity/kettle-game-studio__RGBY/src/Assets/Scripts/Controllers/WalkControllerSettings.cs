using System;
using UnityEngine;
using UnityEngine.InputSystem;


[CreateAssetMenu(menuName="Controller/WalkController", fileName="WalkController")]
public class WalkControllerSettings : ControllerSettings
{
    public float speed = 10;
    public float inertia = 0.1f;

    public override IController Construct()
    {
        return new WalkController(this);
    }
}

public class WalkController : IController
{
    public bool Enabled { get; set; } = false;
    InputAction moveAction;
    WalkControllerSettings settings;

    Vector2 velocity = Vector2.zero;


    public WalkController(WalkControllerSettings settings)
    {
        this.settings = settings;
        moveAction = InputSystem.actions.FindAction("Move");
    }

    public void Iterate(ControlState state)
    {
        if (!Enabled && velocity.magnitude < 0.01f) return;

        Vector2 moveValue = Enabled ? moveAction.ReadValue<Vector2>() : Vector2.zero;

        velocity = velocity  * settings.inertia + moveValue * (1 - settings.inertia);

        state.velocity += state.forwardRotation * (
            Vector3.forward * velocity.y +
            Vector3.right   * velocity.x
        ) * settings.speed;
    }
}
