using GdUnit4;
using Godot;
using System.Collections.Generic;
using static GdUnit4.Assertions;

[TestSuite]
public class CarRouteTests
{
    private const float Tolerance = 0.0001f;

    /// <summary>
    /// Road nodes that a test added to LevelState, so they can be removed
    /// after the test finishes.
    /// </summary>
    private readonly List<RoadNode> _registeredRoadNodes = [];

    [AfterTest]
    public void UnregisterRoadNodes()
    {
        foreach (var roadNode in _registeredRoadNodes)
        {
            LevelState.AllRoadNodes.Remove(roadNode);
        }
        _registeredRoadNodes.Clear();
    }

    // SCENARIO: A car can drive around two sides of a square block, or cut
    // across it on a diagonal road.
    [TestCase]
    public void GivenSquareWithDiagonal_WhenCarDistanceCalculated_ThenShorterPathIsTaken()
    {
        // GIVEN: A 100 px square of roads with a diagonal road between two
        // opposite corners.
        var topLeft = CreateRoadNode(new Vector2(0, 0));
        var topRight = CreateRoadNode(new Vector2(100, 0));
        var bottomRight = CreateRoadNode(new Vector2(100, 100));
        var bottomLeft = CreateRoadNode(new Vector2(0, 100));
        Connect(topLeft, topRight);
        Connect(topRight, bottomRight);
        Connect(bottomRight, bottomLeft);
        Connect(bottomLeft, topLeft);
        Connect(topLeft, bottomRight);

        // WHEN: The car distance between the two diagonal corners is calculated.
        float? carDistance = Pathfinder.CalculateCarDistance(topLeft, bottomRight);

        // THEN: The car takes the diagonal instead of driving around the block.
        AssertBool(carDistance.HasValue).IsTrue();
        AssertFloat(carDistance.Value).IsEqualApprox(100f * Mathf.Sqrt2, Tolerance);
    }

    // SCENARIO: A car can only reach its destination by driving through
    // several intersections.
    [TestCase]
    public void GivenMultiStepRoad_WhenCarDistanceCalculated_ThenEveryRoadIsAdded()
    {
        // GIVEN: Three roads of 100 px, 50 px, and 30 px joined end to end.
        var start = CreateRoadNode(new Vector2(0, 0));
        var firstTurn = CreateRoadNode(new Vector2(100, 0));
        var secondTurn = CreateRoadNode(new Vector2(100, 50));
        var end = CreateRoadNode(new Vector2(130, 50));
        Connect(start, firstTurn);
        Connect(firstTurn, secondTurn);
        Connect(secondTurn, end);

        // WHEN: The car distance from one end of the road to the other is
        // calculated.
        float? carDistance = Pathfinder.CalculateCarDistance(start, end);

        // THEN: The distance is the sum of every road along the way.
        AssertBool(carDistance.HasValue).IsTrue();
        AssertFloat(carDistance.Value).IsEqualApprox(100f + 50f + 30f, Tolerance);
    }

    // SCENARIO: Two parts of the road network are not connected to each
    // other.
    [TestCase]
    public void GivenDisconnectedRoads_WhenCarDistanceCalculated_ThenNullIsReturned()
    {
        // GIVEN: Two separate roads with no road between them.
        var firstRoadStart = CreateRoadNode(new Vector2(0, 0));
        var firstRoadEnd = CreateRoadNode(new Vector2(100, 0));
        var secondRoadStart = CreateRoadNode(new Vector2(0, 200));
        var secondRoadEnd = CreateRoadNode(new Vector2(100, 200));
        Connect(firstRoadStart, firstRoadEnd);
        Connect(secondRoadStart, secondRoadEnd);

        // WHEN: The car distance between the two roads is calculated.
        float? carDistance = Pathfinder.CalculateCarDistance(firstRoadStart, secondRoadEnd);

        // THEN: There is no road path, so no distance is returned.
        AssertBool(carDistance.HasValue).IsFalse();
    }

    // SCENARIO: A car starts and ends at the same road node.
    [TestCase]
    public void GivenSameStartAndEnd_WhenCarDistanceCalculated_ThenDistanceIsZero()
    {
        // GIVEN: A single road node.
        var roadNode = CreateRoadNode(new Vector2(40, 40));

        // WHEN: The car distance from the road node to itself is calculated.
        float? carDistance = Pathfinder.CalculateCarDistance(roadNode, roadNode);

        // THEN: The car does not need to drive anywhere.
        AssertBool(carDistance.HasValue).IsTrue();
        AssertFloat(carDistance.Value).IsEqualApprox(0f, Tolerance);
    }

    // SCENARIO: A building sits near several road nodes in the level.
    [TestCase]
    public void GivenSeveralRoadNodes_WhenNearestRoadNodeFound_ThenClosestNodeIsReturned()
    {
        // GIVEN: A building with road nodes 100 px, 20 px, and 60 px away.
        var building = CreateBuilding(new Vector2(0, 0));
        var farRoadNode = CreateRoadNode(new Vector2(100, 0));
        var nearRoadNode = CreateRoadNode(new Vector2(0, 20));
        var middleRoadNode = CreateRoadNode(new Vector2(-60, 0));
        Register(farRoadNode, nearRoadNode, middleRoadNode);

        // WHEN: The road node closest to the building is found.
        var nearestRoadNode = Pathfinder.FindNearestRoadNode(building);

        // THEN: The road node 20 px away is returned.
        AssertObject(nearestRoadNode).IsSame(nearRoadNode);
    }

    /// <summary>
    /// Creates a plain node at the given position to stand in for a house or
    /// destination building.
    /// </summary>
    private static Node2D CreateBuilding(Vector2 position)
    {
        var node = AutoFree(new Node2D());
        node.GlobalPosition = position;
        return node;
    }

    /// <summary>
    /// Creates a road node at the given position.
    /// </summary>
    private static RoadNode CreateRoadNode(Vector2 position)
    {
        var roadNode = AutoFree(new RoadNode());
        roadNode.GlobalPosition = position;
        return roadNode;
    }

    /// <summary>
    /// Connects two road nodes with a road that can be driven both ways.
    /// </summary>
    private static void Connect(RoadNode nodeA, RoadNode nodeB)
    {
        nodeA.AddNeighbor(nodeB);
        nodeB.AddNeighbor(nodeA);
    }

    /// <summary>
    /// Adds road nodes to LevelState so that they can be found by
    /// Pathfinder.FindNearestRoadNode. They are removed after the test.
    /// </summary>
    private void Register(params RoadNode[] roadNodes)
    {
        foreach (var roadNode in roadNodes)
        {
            LevelState.AllRoadNodes.Add(roadNode);
            _registeredRoadNodes.Add(roadNode);
        }
    }
}
