using AutoInterfaceAttributes;
using TowerProtect.Domain.Rendering.Camera;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Model.Unions;
using TowerProtect.Domain.Model.Vectors;
using TowerProtect.App.Client.Interfaces;

namespace TowerProtect.App.Client.Camera;

partial interface ICameraControl : IUpdateAware;

[AutoInterface]
internal class CameraControl(
    IInputSystem inputSystem,
    ICameraFollow cameraFollow,
    ICameraZoom cameraZoom) : ICameraControl
{
    private Vec2 _followTarget;

    public void Tick(FrameUnion frameUnion)
    {
        frameUnion.ForPlayer(player => _followTarget = player.Position);
    }

    public void Update(double deltaTime)
    {
        cameraFollow.Follow(_followTarget, deltaTime);

        if (inputSystem.IsKeyPressed("LeftControl"))
        {
            int zoomDelta = inputSystem.ScrollSign;
            cameraZoom.ChangeZoom(zoomDelta);
        }
    }
}
