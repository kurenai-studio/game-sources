using Godot;

/// <summary>
/// A stub implementation of the Destination class for testing purposes.
/// This class allows you to specify a forced reachable bus stop,
/// which will be returned when the ReachableBusStop property is accessed.
/// This is for ease of testing to avoid the physics logic in the real Destination class.
/// </summary>
public partial class DestinationStub : Destination
{
    /// <summary>
    /// The stop to return as the reachable bus stop.
    /// </summary>
    private Node _forcedStop;

    /// <summary>
    /// Creates a DestinationStub that always returns the specified stop as the reachable bus stop.
    /// </summary>
    /// <param name="stop">The stop to return as the reachable bus stop.</param>
    public DestinationStub(Node stop)
    {
        _forcedStop = stop;
    }

    public override Node ReachableBusStop => _forcedStop;
}