namespace Clong.Core.Domain.Dto;

public class GameTime
{
    public required TimeSpan DeltaTime { internal get; init; }
    public required TimeSpan TotalTime { internal get; init; }
    internal float TotalSeconds => (float)TotalTime.TotalSeconds;
    internal float DeltaSeconds => (float)DeltaTime.TotalSeconds;
}