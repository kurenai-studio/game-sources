using Godot;
using System.Collections.Generic;
using System.Linq;
using System;
using static PathGeometry;

/// <summary>
/// Holds the state of the level, including all routes.
/// Shout out to my friends Mitch, Adam, and Erik for helping me name this.
/// </summary>
public partial class LevelState : Node
{
    /// <summary>
    /// 
    /// </summary>
    public static Node CurrentLevel { get; set; }

    /// <summary>
    /// The bus stop placement UI component for the current level.
    /// </summary>
    public static LevelUI LevelUI { get; set; }
    public static InformationPanel InformationPanel { get; set; }
    public static List<BusLine> AllBusLines { get; set; } = [];
    public static List<House> AllHouses { get; set; } = [];
    public static List<Destination> AllDestinations { get; set; } = [];
    public static List<Node> AllBusStops { get; set; } = [];

    /// <summary>
    /// All road nodes in the current level which includes bus stops and
    /// intersections. This is mostly for debugging purposes.
    /// </summary>
    public static List<RoadNode> AllRoadNodes { get; set; } = [];
    public static List<RoadEdge> AllRoadEdges { get; set; } = [];
    public static event Action<uint> OnBudgetChanged;
    private static uint _budget;
    public static uint Budget
    {
        get => _budget;
        set
        {
            _budget = value;
            OnBudgetChanged?.Invoke(_budget);
        }
    }

    private static List<KeyValuePair<string, Color>> _availableColors = new(BusLineColors.ColorList);

    public static KeyValuePair<string, Color>? GetNextBusLineColor()
    {
        if (_availableColors.Count == 0)
        {
            GD.PrintErr("All available route colors have been used.");
            return null;
        }
        var colorInfo = _availableColors[0];
        _availableColors.RemoveAt(0);
        return colorInfo;
    }

    /// <summary>
    /// Returns a route color back to the pool of available colors.
    /// Call this when a route is deleted.
    /// </summary>
    public static void ReturnBusLineColor(KeyValuePair<string, Color> colorInfo)
    {
        if (!BusLineColors.ColorList.Contains(colorInfo) || _availableColors.Contains(colorInfo))
        {
            return;
        }
        _availableColors.Add(colorInfo);
    }

    /// <summary>
    /// Removes a specific route color from the pool of available colors.
    /// Call this when a previously deleted route is restored (e.g. undo).
    /// </summary>
    public static void ReserveBusLineColor(KeyValuePair<string, Color> colorInfo)
    {
        _availableColors.Remove(colorInfo);
    }

    /// <summary>
    /// Refreshes the visual representation of all routes.
    /// Call this when routes are added, removed, or modified to ensure
    /// proper offset calculations for shared road segments.
    /// </summary>
    public static void RefreshAllBusLineVisuals()
    {
        foreach (var busLine in AllBusLines)
        {
            busLine.Visual?.UpdateVisual();
        }
    }

    public static bool IsLevelComplete()
    {
        return AllHouses.All(house => house.IsChecked);
    }

    public static void UpdateAllHouseStatuses()
    {
        foreach (var house in AllHouses)
        {
            house.UpdateCheckStatus();
        }
    }

    /// <summary>
    /// Calculates just the offset amount (scalar) for a specific segment.
    /// </summary>
    public static float CalculateSegmentOffsetAmount(BusLine targetBusLine, RoadNode nodeA, RoadNode nodeB, float lineSpacing)
    {
        var busLinesOnSegment = GetBusLinesOnSegment(nodeA, nodeB);

        if (busLinesOnSegment.Count <= 1)
        {
            return 0f;
        }

        int slotIndex = busLinesOnSegment.IndexOf(targetBusLine);
        if (slotIndex < 0) return 0f;

        float totalWidth = (busLinesOnSegment.Count - 1) * lineSpacing;
        float baseOffset = -totalWidth / 2.0f + (slotIndex * lineSpacing);

        bool isCanonical = IsCanonicalDirection(nodeA, nodeB);
        return isCanonical ? baseOffset : -baseOffset;
    }

    /// <summary>
    /// Gets all busLines that pass through a given segment, sorted by busLine ID
    /// for consistent slot assignment.
    /// </summary>
    public static List<BusLine> GetBusLinesOnSegment(RoadNode nodeA, RoadNode nodeB)
    {
        var busLines = new List<BusLine>();

        foreach (var busLine in AllBusLines)
        {
            if (BusLineContainsSegment(busLine, nodeA, nodeB))
            {
                busLines.Add(busLine);
            }
        }

        // Sort by busLine ID to ensure consistent slot assignment
        busLines = busLines.OrderBy(r => r.ID).ToList();
        return busLines;
    }

    /// <summary>
    /// Checks if a busLine contains a segment between two nodes (in either direction).
    /// </summary>
    public static bool BusLineContainsSegment(BusLine busLine, RoadNode nodeA, RoadNode nodeB)
    {
        var path = busLine.Path;
        for (int i = 0; i < path.Count - 1; i++)
        {
            if ((path[i] == nodeA && path[i + 1] == nodeB) ||
                (path[i] == nodeB && path[i + 1] == nodeA))
            {
                return true;
            }
        }
        return false;
    }
}
