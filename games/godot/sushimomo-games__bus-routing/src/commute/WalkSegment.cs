using Godot;

/// <summary>
/// Represents a segment of a commute where a passenger walks from one point to another.
/// </summary>
public class WalkSegment : CommuteSegment
{
    /// <summary>
    /// The starting point of the walk segment.
    /// </summary>
    public Node2D Origin { get; private set; }

    /// <summary>
    /// The ending point of the walk segment.
    /// </summary>
    public Node2D Destination { get; private set; }

    public WalkSegment(Node2D origin, Node2D destination)
    {
        Origin = origin;
        Destination = destination;
    }

    /// <summary>
    /// The raw distance between the origin and destination of the walk
    /// segment. The player should never be shown this value directly. Use the
    /// TimeMinutes property for player-facing calls.
    /// </summary>
    protected override float Weight => Origin.GlobalPosition.DistanceTo(Destination.GlobalPosition);

    /// <summary>
    /// The weighted distance of the walk segment, taking into account walking
    /// speed or difficulty. This is different from RawDistance in that it can
    /// be adjusted to reflect the actual time required to walk the distance.
    /// </summary>
    public override float TimeMinutes => Weight * GlobalConstants.WalkMinutesPerPixel;

    /// <summary>
    /// The cost of the walk segment, which is equivalent to the time in
    /// minutes for now. This exists to make the Pathfinder code more readable.
    /// </summary>
    public float Cost => TimeMinutes;

    /// <summary>
    /// Generates a human-readable instruction for the walk segment, indicating
    /// where the resident should walk to. The instruction changes based on
    /// whether the resident is walking to a bus stop or to their destination.
    /// For example: "Walk to the bus stop." or "Walk to your destination."
    /// </summary>
    /// <returns></returns>
    public override string GetInstruction()
    {
        string destName = Destination is BusStop ? "the bus stop" : "your destination";

        int roundedMinutes = Mathf.Max(1, Mathf.RoundToInt(TimeMinutes));
        return $"Walk {roundedMinutes} min ({DistanceMiles:F1} mi).";
    }
}