using Godot;

/// <summary>
/// A stub implementation of the House class for testing purposes.
/// This class allows you to specify a forced reachable bus stop,
/// which will be returned when the ReachableBusStop property is accessed.
/// This is for ease of testing to avoid the physics logic in the real House class.
/// </summary>
public partial class HouseStub : House
{
    /// <summary>
    /// The stop to return as the reachable bus stop. Set it to null to
    /// simulate the house losing its bus stop.
    /// </summary>
    public Node ForcedStop { get; set; }

    /// <summary>
    /// Creates a HouseStub that always returns the specified stop as the reachable bus stop.
    /// </summary>
    /// <param name="stop">The stop to return as the reachable bus stop.</param>
    public HouseStub(Node stop)
    {
        ForcedStop = stop;
    }

    public override Node ReachableBusStop => ForcedStop;
}
