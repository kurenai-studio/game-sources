namespace TowerProtect.Domain.Config;

public static class CameraConfig
{
    public const double DefaultSide = 20.0;
    public const double CullingRangeMultiplier = 1.5;
    public const double SmoothTime = 0.2;

    public const double ZoomStep = 0.2;
    public const int MinZoomPoint = -4;
    public const int MaxZoomPoint = 4;
}
