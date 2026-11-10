using System.Collections.Generic;
using System.Linq;
using Godot;
using static GlobalConstants;

public partial class Commute
{
    public List<CommuteSegment> Itinerary { get; private set; }

    /// <summary>
    /// The building where the commute begins, which is the origin of the
    /// first walk segment (usually the resident's house).
    /// </summary>
    public Node2D Origin { get; private set; }

    /// <summary>
    /// The building where the commute ends, which is the destination of the
    /// last walk segment. This is the destination that the bus route chose,
    /// and the car route is calculated to the same destination.
    /// </summary>
    public Node2D Destination { get; private set; }

    /// <summary>
    /// The estimated time that a commute should take a resident in minutes.
    /// </summary>
    public float TotalTimeMinutes => Itinerary.Sum(segment => segment.TimeMinutes);

    /// <summary>
    /// The estimated time in minutes that the commute takes by bus, including
    /// walking, riding, and dwell time at bus stops. This is an alias for
    /// TotalTimeMinutes.
    /// </summary>
    public float BusMinutes => TotalTimeMinutes;

    /// <summary>
    /// The estimated time in minutes that the same trip would take by car,
    /// from the origin to the destination along the road network. This is
    /// calculated once when the commute is built, and is never lower than
    /// MinimumCarMinutes.
    /// </summary>
    public float CarMinutes { get; private set; }

    /// <summary>
    /// How many times longer the commute takes by bus than by car. A ratio of
    /// 1.0 means the bus is as fast as driving.
    /// </summary>
    public float BusToCarTimeRatio => BusMinutes / CarMinutes;

    /// <summary>
    /// The total distance in miles that a resident walks during a commute.
    /// This includes the walk to the first bus stop, any walking transfers
    /// between stops, and the walk from the last stop to the destination.
    /// </summary>
    public float MilesWalked => Itinerary.OfType<WalkSegment>().Sum(segment => segment.DistanceMiles);

    public int TransferCount => Itinerary.OfType<WalkSegment>().Count() - 1;

    public Commute(List<CommuteSegment> segments)
    {
        Itinerary = segments;

        var walkSegments = Itinerary.OfType<WalkSegment>();
        Origin = walkSegments.First().Origin;
        Destination = walkSegments.Last().Destination;

        CarMinutes = CalculateCarMinutes(Origin, Destination);
    }

    /// <summary>
    /// Returns a list of sequential instructions for the UI.
    /// </summary>
    public List<string> GetDirections()
    {
        return [.. Itinerary.Select(segment => segment.GetInstruction())];
    }

    /// <summary>
    /// Calculates the time in minutes it takes to drive from the origin to the
    /// destination. The car travels in a straight line from the origin to its
    /// nearest road node, along the road network to the destination's nearest
    /// road node, then in a straight line to the destination. If there is no
    /// road path, the straight-line distance from the origin to the
    /// destination is used instead.
    /// </summary>
    /// <param name="origin">The building where the car trip begins.</param>
    /// <param name="destination">The building where the car trip ends.</param>
    /// <returns>The car travel time in minutes, never lower than MinimumCarMinutes.</returns>
    private static float CalculateCarMinutes(Node2D origin, Node2D destination)
    {
        float carDistancePixels = origin.GlobalPosition.DistanceTo(destination.GlobalPosition);

        var originRoadNode = Pathfinder.FindNearestRoadNode(origin);
        var destinationRoadNode = Pathfinder.FindNearestRoadNode(destination);

        if (originRoadNode != null && destinationRoadNode != null
            && Pathfinder.CalculateCarDistance(originRoadNode, destinationRoadNode) is float roadDistancePixels)
        {
            carDistancePixels = origin.GlobalPosition.DistanceTo(originRoadNode.GlobalPosition)
                + roadDistancePixels
                + destinationRoadNode.GlobalPosition.DistanceTo(destination.GlobalPosition);
        }

        return Mathf.Max(carDistancePixels / CarPixelsPerMinute, MinimumCarMinutes);
    }
}
