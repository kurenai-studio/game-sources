using Godot;
using System.Collections.Generic;
using System.Linq;

public static class Pathfinder
{
    /// <summary>
    /// Uses Dijkstra's algorithm to find the most time-efficient commute
    /// for a house.
    /// </summary>
    public static List<CommuteSegment> CalculateBestRoute(BusStop start, HashSet<Destination> validDestinations)
    {
        var validDestinationStops = validDestinations.Select(d => (BusStop)d.ReachableBusStop).ToHashSet();
        var priorityQueue = new PriorityQueue<BusStop, float>();
        var costs = new Dictionary<BusStop, float>();
        var lineageMap = new Dictionary<BusStop, (BusStop Parent, CommuteSegment Segment)>();
        var visited = new HashSet<BusStop>();

        priorityQueue.Enqueue(start, 0f);
        costs[start] = 0f;

        while (priorityQueue.Count > 0)
        {
            var current = priorityQueue.Dequeue();

            // Skip stale queue entries 
            if (!visited.Add(current)) continue;

            if (validDestinationStops.Contains(current))
            {
                var destinationNode = validDestinations.First(d => d.ReachableBusStop == current);
                return BuildTransitItinerary(start, current, destinationNode, lineageMap);
            }

            EvaluateBusConnections(current, costs, lineageMap, priorityQueue);
            EvaluateWalkConnections(current, costs, lineageMap, priorityQueue);
        }

        return null;
    }

    /// <summary>
    /// Evaluates all possible bus connections from the current bus stop and
    /// updates the costs, lineage map, and priority queue accordingly.
    /// </summary>
    /// <param name="current"></param>
    /// <param name="costs"></param>
    /// <param name="lineageMap"></param>
    /// <param name="priorityQueue"></param>
    private static void EvaluateBusConnections
    (
        BusStop current,
        Dictionary<BusStop, float> costs,
        Dictionary<BusStop, (BusStop Parent, CommuteSegment Segment)> lineageMap,
        PriorityQueue<BusStop, float> priorityQueue)
    {
        foreach (var busLine in LevelState.AllBusLines)
        {
            int currentIndex = busLine.Path.IndexOf(current);
            if (currentIndex == -1) continue;

            for (int i = currentIndex + 1; i < busLine.Path.Count; i++)
            {
                if (busLine.Path[i] is BusStop nextNode)
                {
                    var segment = new RideSegment(busLine, current, nextNode);
                    float newCost = costs[current] + segment.Cost;

                    if (!costs.ContainsKey(nextNode) || newCost < costs[nextNode])
                    {
                        costs[nextNode] = newCost;
                        lineageMap[nextNode] = (current, segment);
                        priorityQueue.Enqueue(nextNode, newCost);
                    }
                }
            }
        }
    }

    /// <summary>
    /// Evaluates all possible walking connections from the current bus stop and
    /// updates the costs, lineage map, and priority queue accordingly.
    /// </summary>
    /// <param name="current"></param>
    /// <param name="costs"></param>
    /// <param name="lineageMap"></param>
    /// <param name="priorityQueue"></param>
    private static void EvaluateWalkConnections
    (
        BusStop current,
        Dictionary<BusStop, float> costs,
        Dictionary<BusStop, (BusStop Parent, CommuteSegment Segment)> lineageMap,
        PriorityQueue<BusStop, float> priorityQueue)
    {
        foreach (var nearbyStop in current.GetNearbyBusStops())
        {
            if (!LevelState.AllBusLines.Any(r => r.Path.Contains(nearbyStop))) continue;

            var walkSegment = new WalkSegment(current, nearbyStop);
            float newCost = costs[current] + walkSegment.Cost;

            if (!costs.ContainsKey(nearbyStop) || newCost < costs[nearbyStop])
            {
                costs[nearbyStop] = newCost;
                lineageMap[nearbyStop] = (current, walkSegment);
                priorityQueue.Enqueue(nearbyStop, newCost);
            }
        }
    }

    /// <summary>
    /// Builds an itinerary comprised of walk and ride segments from the
    /// starting bus stop to the destination.
    /// 
    /// </summary>
    /// <param name="start">The bus stop that the itinerary begins from.</param>
    /// <param name="end">The bus stop that the itinerary ends at.</param>
    /// <param name="finalDestination">The destination of the commute.</param>
    /// <param name="lineageMap">A map containing the parent and segment information for each bus stop.</param>
    /// <returns>A list of commute segments representing the itinerary from start to the final destination.</returns>
    internal static List<CommuteSegment> BuildTransitItinerary
    ( 
        BusStop start, 
        BusStop end, 
        Destination finalDestination, 
        Dictionary<BusStop, (BusStop Parent, CommuteSegment Segment)> lineageMap) 
    { 
        var segments = new List<CommuteSegment>(); 
        var backtrackNode = end; 
        
        while (backtrackNode != start) 
        { 
            var lineage = lineageMap[backtrackNode]; 
            segments.Add(lineage.Segment); 
            backtrackNode = lineage.Parent; 
        } 
        
        segments.Reverse();
        segments.Add(new WalkSegment(end, finalDestination));
        return segments;
    }

    /// <summary>
    /// Uses Dijkstra's algorithm to find the shortest distance a car can drive
    /// along the road network between two road nodes. Each road edge is
    /// weighted by the straight-line distance between its two nodes.
    /// </summary>
    /// <param name="start">The road node that the car starts from.</param>
    /// <param name="end">The road node that the car drives to.</param>
    /// <returns>The shortest road distance in pixels, or null if there is no road path.</returns>
    public static float? CalculateCarDistance(RoadNode start, RoadNode end)
    {
        var priorityQueue = new PriorityQueue<RoadNode, float>();
        var distances = new Dictionary<RoadNode, float>();
        var visited = new HashSet<RoadNode>();

        priorityQueue.Enqueue(start, 0f);
        distances[start] = 0f;

        while (priorityQueue.Count > 0)
        {
            var current = priorityQueue.Dequeue();

            // Skip stale queue entries
            if (!visited.Add(current)) continue;

            if (current == end)
            {
                return distances[current];
            }

            foreach (var neighbor in current.Neighbors)
            {
                if (neighbor == null) continue;

                float newDistance = distances[current] + current.GlobalPosition.DistanceTo(neighbor.GlobalPosition);

                if (!distances.ContainsKey(neighbor) || newDistance < distances[neighbor])
                {
                    distances[neighbor] = newDistance;
                    priorityQueue.Enqueue(neighbor, newDistance);
                }
            }
        }

        return null;
    }

    /// <summary>
    /// Finds the road node in the current level that is closest to a building.
    /// </summary>
    /// <param name="building">The building to find the closest road node to.</param>
    /// <returns>The closest road node, or null if the level has no road nodes.</returns>
    public static RoadNode FindNearestRoadNode(Node2D building)
    {
        return LevelState.AllRoadNodes
            .Where(node => node != null)
            .MinBy(node => node.GlobalPosition.DistanceTo(building.GlobalPosition));
    }
}