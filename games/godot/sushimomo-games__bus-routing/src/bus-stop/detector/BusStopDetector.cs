using Godot;

/// <summary>
/// Detects whether a bus stop is in range using raycast.
/// </summary>
public partial class BusStopDetector : RayCast2D
{
    /// <summary>
    /// Gets the bus stop node that this detector can reach.
    /// Returns null if no bus stop is currently in range.
    /// Preview bus stops are ignored.
    /// </summary>
    public Node ReachableBusStop
    {
        get
        {
            ForceRaycastUpdate();
            if (IsColliding())
            {
                var busStopArea = GetCollider() as Node;
                return busStopArea?.GetParent();
            }
            return null;
        }
    }
}
