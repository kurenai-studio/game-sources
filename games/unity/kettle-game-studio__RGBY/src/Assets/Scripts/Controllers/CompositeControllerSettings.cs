using System;
using System.Linq;
using UnityEngine;


[CreateAssetMenu(menuName="Controller/CompositeController", fileName="CompositeController")]
public class CompositeControllerSettings : ControllerSettings
{
    public ControllerSettings[] controllers;

    public override IController Construct()
    {
        return new CompositeController(this);
    }
}

public class CompositeController : IController
{
    public bool Enabled {
        set {
            foreach (var controller in controllers)
                controller.Enabled = value;
        }
    }

    private IController[] controllers;

    public CompositeController(CompositeControllerSettings settings)
    {
        controllers = settings.controllers.Select(c => c.Construct()).ToArray();
        Enabled = false;
    }

    public void Iterate(ControlState state)
    {
        foreach (var controller in controllers)
            controller.Iterate(state);
    }
}
