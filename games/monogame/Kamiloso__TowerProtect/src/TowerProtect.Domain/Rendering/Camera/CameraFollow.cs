using AutoInterfaceAttributes;
using System;
using TowerProtect.Domain.Model.Vectors;
using static TowerProtect.Domain.Config.CameraConfig;

namespace TowerProtect.Domain.Rendering.Camera;

partial interface ICameraFollow;

[AutoInterface]
public class CameraFollow(ICameraView cameraView) : ICameraFollow
{
    private Vec2 _velocity;

    public void Follow(Vec2 target, double deltaTime)
    {
        double smoothTime = Math.Max(0.0001, SmoothTime);
        double omega = 2.0 / smoothTime;
        double x = omega * deltaTime;

        double exp = Math.Exp(-x);

        Vec2 position = cameraView.Center;
        Vec2 change = position - target;
        Vec2 temp = (_velocity + change * omega) * deltaTime;

        _velocity = (_velocity - temp * omega) * exp;
        cameraView.Center = target + (change + temp) * exp;
    }
}
