using GdUnit4;
using Godot;
using System.Collections.Generic;
using static GdUnit4.Assertions;

[TestSuite]
public class PathfinderTests
{
    // SCENARIO: There are two possible routes that the player can take to
    // reach a destination. The previously optimal route is deleted, and the
    // player adds a new route that is more optimal than the remaining route.
    [TestCase]
    public void GivenDeletedOptimalRoute_WhenBetterRouteAdded_ThenPathfinderPicksNewRoute()
    {
        // GIVEN: A house is neear a bus stop with two possible routes to reach a
        // destination.       
        var busStopScene = GD.Load<PackedScene>(Path.BusStopScene);
        var startStop = busStopScene.Instantiate<BusStop>();
        startStop.GlobalPosition = new Vector2(0, 0);
        var endStop = busStopScene.Instantiate<BusStop>();
        endStop.GlobalPosition = new Vector2(100, 0);

        var houseScene = GD.Load<PackedScene>(Path.HouseScene);
        var house = houseScene.Instantiate<House>();
        house.GlobalPosition = new Vector2(5, 0);
        house.Modulate = Colors.Red;

        var destination = new DestinationStub(endStop)
        {
            GlobalPosition = new Vector2(105, 0),
            Modulate = Colors.Red
        };

        var validDestinations = new HashSet<Destination> { destination };

        var lineA = new BusLine
        {
            Path = [startStop, endStop]
        };
        LevelState.AllBusLines.Add(lineA);

        var cornerNode = busStopScene.Instantiate<BusStop>();
        cornerNode.GlobalPosition = new Vector2(0, 500);
        var lineB = new BusLine
        {
            Path = [startStop, cornerNode, endStop]
        };
        LevelState.AllBusLines.Add(lineB);

        // Prove Line A is currently the best before we delete it
        var initialRoute = Pathfinder.CalculateBestRoute(startStop, validDestinations);
        var initialRide = initialRoute[0] as RideSegment;
        AssertObject(initialRide.Line).IsEqual(lineA);

        // WHEN: The player deletes the previously optimal route and adds a new 
        // route that is more optimal than the remaining route.
        LevelState.AllBusLines.Remove(lineA);

        var midStop = busStopScene.Instantiate<BusStop>();
        midStop.GlobalPosition = new Vector2(50, 0);
        var newOptimalLine = new BusLine
        {
            Path = [startStop, midStop, endStop]
        };
        LevelState.AllBusLines.Add(newOptimalLine);


        // THEN: The pathfinding algorithm should correctly identify the new optimal 
        // route and return it as the best route to reach the destination.
        var newRoute = Pathfinder.CalculateBestRoute(startStop, validDestinations);

        AssertObject(newRoute).IsNotNull();

        var newRide = newRoute[0] as RideSegment;
        AssertObject(newRide).IsNotNull();
        AssertObject(newRide.Line).IsEqual(newOptimalLine);
    }
}