using Godot;
using static GlobalConstants;

/// <summary>
/// Abstract base class representing a segment of a commute,
/// which can be either a walk or a bus ride.
/// </summary>
public abstract class CommuteSegment
{
    /// <summary>
    /// The raw distance between beginning and end of the segment.
    /// </summary>
    protected abstract float Weight { get; }

    /// <summary>
    /// The distance of a segment in miles.
    /// </summary>
    public float DistanceMiles => Weight / PixelsPerMile;

    /// <summary>
    /// The estimated time in minutes required to complete the segment.
    /// </summary>
    public abstract float TimeMinutes { get; }

    // Generates the human-readable instruction (e.g. "Walk to X")
    public abstract string GetInstruction();
}