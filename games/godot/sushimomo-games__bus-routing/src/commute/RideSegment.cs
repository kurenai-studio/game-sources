using Godot;
using System.Linq;
using System.Collections.Generic;

/// <summary>
/// Represents a segment of a route where the user takes a bus.
/// Contains details about the bus line, boarding and alighting stops,
/// and calculates estimated time and instructions for this segment.
/// </summary>
public class RideSegment : CommuteSegment
{
    /// <summary>
    /// The bus line being taken for this segment,
    /// which contains the path and color information.
    /// </summary>
    public BusLine Line { get; private set; }

    /// <summary>
    /// The bus stop where the user boards the bus for this segment.
    /// This is the first stop in the of the segment.
    /// </summary>
    public BusStop BoardingStop { get; private set; }

    /// <summary>
    /// The bus stop where the user gets off for this segment.
    /// This is the last stop in the of the segment.
    /// </summary>
    public BusStop ExitStop { get; private set; }

    public int StopsTraveled { get; private set; }

    public RideSegment(BusLine line, BusStop boardingStop, BusStop exitStop)
    {
        Line = line;
        BoardingStop = boardingStop;
        ExitStop = exitStop;

        CalculateRideStats();
    }

    private void CalculateRideStats()
    {
        // Filter the BusLine's path to only actual BusStops
        var stopsOnLine = Line.Path.OfType<BusStop>().ToList();

        int startIndex = stopsOnLine.IndexOf(BoardingStop);
        int endIndex = stopsOnLine.IndexOf(ExitStop);

        StopsTraveled = Mathf.Abs(endIndex - startIndex);
    }

    // For RideSegment, distance along nodes
    protected override float Weight
    {
        get
        {
            float totalDist = 0;
            bool counting = false;
            foreach (var node in Line.Path)
            {
                if (node == BoardingStop || node == ExitStop)
                {
                    if (counting)
                    {
                        // We hit the end node
                        break;
                    }
                    else
                    {
                        // We hit the start node
                        counting = true;
                    }
                }

                if (counting)
                {
                    var nextNode = Line.Path[Line.Path.IndexOf(node) + 1];
                    totalDist += node.GlobalPosition.DistanceTo(nextNode.GlobalPosition);
                }
            }
            return totalDist;
        }
    }

    /// <summary>
    /// The estimated time in minutes for the ride, including the time the bus
    /// spends driving and the dwell time at every stop after boarding,
    /// including the stop where the rider gets off.
    /// </summary>
    public override float TimeMinutes =>
        Weight / GlobalConstants.BusPixelsPerMinute
        + StopsTraveled * GlobalConstants.DwellTimeMinutesPerStop;

    public float Cost => TimeMinutes;

    /// <summary>
    /// Returns a user-friendly instruction for this RideSegment, e.g.,
    /// "Take the Orange Line for 3 stops."
    /// </summary>
    /// <returns></returns>
    public override string GetInstruction()
    {
        string plural = StopsTraveled == 1 ? "stop" : "stops";
        // E.g., "Take the Orange Line for 3 stops."
        return $"Ride {Line.ColorName} line for {StopsTraveled} {plural} ({DistanceMiles:F1} mi).";
    }

    /// <summary>
    /// Returns the list of RoadNodes that this RideSegment traverses,
    /// starting from the BoardingStop and ending at the ExitStop.
    /// </summary>
    /// <returns></returns>
    public List<RoadNode> GetPathNodes()
    {
        var nodes = new List<RoadNode>();
        bool adding = false;
        foreach (var node in Line.Path)
        {
            if (node == BoardingStop || node == ExitStop)
            {
                if (adding)
                {
                    nodes.Add(node);
                    break;
                }
                else
                {
                    adding = true;
                }
            }

            if (adding)
            {
                nodes.Add(node);
            }
        }
        return nodes;
    }
}
