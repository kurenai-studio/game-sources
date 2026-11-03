using AutoInterfaceAttributes;
using static TowerProtect.Domain.Config.CameraConfig;

namespace TowerProtect.Domain.Rendering.Camera;

partial interface ICameraZoom;

[AutoInterface]
public class CameraZoom(ICameraView cameraView) : ICameraZoom
{
    private int _zoomLevel = 0;

    public void ChangeZoom(int zoomDelta)
    {
        if (zoomDelta > 0 && _zoomLevel < MaxZoomPoint)
        {
            _zoomLevel++;
            cameraView.Zoom += ZoomStep;
        }

        if (zoomDelta < 0 && _zoomLevel > MinZoomPoint)
        {
            _zoomLevel--;
            cameraView.Zoom -= ZoomStep;
        }
    }
}
