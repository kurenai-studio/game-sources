using System;
using UnityEngine;
using UnityEngine.InputSystem;


[CreateAssetMenu(menuName="Controller/GravityController", fileName="GravityController")]
public class GravityControllerSettings : ControllerSettings
{
    public override IController Construct()
    {
        return new GravityController(this);
    }
}

public class GravityController : IController
{
    private bool enabled;
    public bool Enabled {
        get => enabled;
        set {
            enabled = value;
            Physics.gravity = Vector3.down * Mathf.Abs(Physics.gravity.y);
        }
    }

    GravityControllerSettings settings;
    InputAction jumpAction;
    bool alreadyPressed = false;

    public GravityController(GravityControllerSettings settings)
    {
        this.settings = settings;
        jumpAction = InputSystem.actions.FindAction("Jump");
    }

    public void Iterate(ControlState state)
    {
        if (!Enabled) return;

        if (!jumpAction.IsPressed())
        {
            alreadyPressed = false;
            return;
        }

        if (!alreadyPressed)
        {
            alreadyPressed = true;
            Physics.gravity = -Physics.gravity;
        }
    }
}
