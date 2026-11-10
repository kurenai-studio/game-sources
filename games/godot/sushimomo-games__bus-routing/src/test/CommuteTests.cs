using GdUnit4;
using Godot;
using System.Collections.Generic;
using static GdUnit4.Assertions;
using static GlobalConstants;

[TestSuite]
public class CommuteTests
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

    // SCENARIO: A resident walks to a bus stop, rides one bus line, then walks
    // from the last stop to their destination.
    [TestCase]
    public void GivenSingleRideCommute_WhenMilesWalkedCalculated_ThenBothWalksAreCounted()
    {
        // GIVEN: A house 30 px from the boarding stop, a 200 px bus ride, and
        // a destination 70 px from the exit stop.
        var house = CreateNode(new Vector2(0, 0));
        var boardingStop = CreateBusStop(new Vector2(30, 0));
        var exitStop = CreateBusStop(new Vector2(230, 0));
        var destination = CreateNode(new Vector2(230, 70));
        var line = CreateBusLine([boardingStop, exitStop]);

        var commute = new Commute(
        [
            new WalkSegment(house, boardingStop),
            new RideSegment(line, boardingStop, exitStop),
            new WalkSegment(exitStop, destination)
        ]);

        // WHEN: The total walking distance of the commute is calculated.
        float milesWalked = commute.MilesWalked;

        // THEN: Both walks are added together and converted to miles.
        float expectedMiles = (30f + 70f) / PixelsPerMile;
        AssertFloat(milesWalked).IsEqualApprox(expectedMiles, Tolerance);
    }

    // SCENARIO: A resident has to walk between two bus stops to transfer from
    // one bus line to another.
    [TestCase]
    public void GivenWalkingTransfer_WhenMilesWalkedCalculated_ThenTransferWalkIsCounted()
    {
        // GIVEN: A commute with a 40 px walk to the first stop, a 60 px walk
        // to transfer between lines, and a 100 px walk to the destination.
        var house = CreateNode(new Vector2(0, 0));
        var firstBoardingStop = CreateBusStop(new Vector2(40, 0));
        var firstExitStop = CreateBusStop(new Vector2(240, 0));
        var secondBoardingStop = CreateBusStop(new Vector2(240, 60));
        var secondExitStop = CreateBusStop(new Vector2(240, 360));
        var destination = CreateNode(new Vector2(340, 360));
        var firstLine = CreateBusLine([firstBoardingStop, firstExitStop]);
        var secondLine = CreateBusLine([secondBoardingStop, secondExitStop]);

        var commute = new Commute(
        [
            new WalkSegment(house, firstBoardingStop),
            new RideSegment(firstLine, firstBoardingStop, firstExitStop),
            new WalkSegment(firstExitStop, secondBoardingStop),
            new RideSegment(secondLine, secondBoardingStop, secondExitStop),
            new WalkSegment(secondExitStop, destination)
        ]);

        // WHEN: The total walking distance of the commute is calculated.
        float milesWalked = commute.MilesWalked;

        // THEN: The transfer walk is counted along with the first and last walks.
        float expectedMiles = (40f + 60f + 100f) / PixelsPerMile;
        AssertFloat(milesWalked).IsEqualApprox(expectedMiles, Tolerance);
    }

    // SCENARIO: Two residents walk the same distance, but one rides the bus
    // much farther than the other.
    [TestCase]
    public void GivenLongerBusRide_WhenWalkingIsUnchanged_ThenMilesWalkedIsUnchanged()
    {
        // GIVEN: Two commutes with identical 50 px walks on each end, but bus
        // rides of 100 px and 1000 px.
        var house = CreateNode(new Vector2(0, 0));
        var boardingStop = CreateBusStop(new Vector2(50, 0));

        var nearExitStop = CreateBusStop(new Vector2(150, 0));
        var nearDestination = CreateNode(new Vector2(150, 50));
        var shortLine = CreateBusLine([boardingStop, nearExitStop]);

        var farExitStop = CreateBusStop(new Vector2(1050, 0));
        var farDestination = CreateNode(new Vector2(1050, 50));
        var longLine = CreateBusLine([boardingStop, farExitStop]);

        var shortRideCommute = new Commute(
        [
            new WalkSegment(house, boardingStop),
            new RideSegment(shortLine, boardingStop, nearExitStop),
            new WalkSegment(nearExitStop, nearDestination)
        ]);
        var longRideCommute = new Commute(
        [
            new WalkSegment(house, boardingStop),
            new RideSegment(longLine, boardingStop, farExitStop),
            new WalkSegment(farExitStop, farDestination)
        ]);

        // WHEN: The total walking distance of each commute is calculated.
        float shortRideMilesWalked = shortRideCommute.MilesWalked;
        float longRideMilesWalked = longRideCommute.MilesWalked;

        // THEN: Bus rides add nothing to the walking distance, so both
        // commutes report the same miles walked.
        float expectedMiles = (50f + 50f) / PixelsPerMile;
        AssertFloat(shortRideMilesWalked).IsEqualApprox(expectedMiles, Tolerance);
        AssertFloat(longRideMilesWalked).IsEqualApprox(expectedMiles, Tolerance);
    }

    // SCENARIO: Two residents take the same bus ride, but one lives farther
    // from the boarding stop than the other.
    [TestCase]
    public void GivenLongerWalkToStop_WhenMilesWalkedCalculated_ThenMilesWalkedIsHigher()
    {
        // GIVEN: Two houses that are 20 px and 100 px from the same stop.
        var nearHouse = CreateNode(new Vector2(30, 0));
        var farHouse = CreateNode(new Vector2(-50, 0));
        var boardingStop = CreateBusStop(new Vector2(50, 0));
        var exitStop = CreateBusStop(new Vector2(250, 0));
        var destination = CreateNode(new Vector2(250, 10));
        var line = CreateBusLine([boardingStop, exitStop]);

        var nearCommute = new Commute(
        [
            new WalkSegment(nearHouse, boardingStop),
            new RideSegment(line, boardingStop, exitStop),
            new WalkSegment(exitStop, destination)
        ]);
        var farCommute = new Commute(
        [
            new WalkSegment(farHouse, boardingStop),
            new RideSegment(line, boardingStop, exitStop),
            new WalkSegment(exitStop, destination)
        ]);

        // WHEN: The total walking distance of each commute is calculated.
        float nearMilesWalked = nearCommute.MilesWalked;
        float farMilesWalked = farCommute.MilesWalked;

        // THEN: The resident who lives farther away walks more, by exactly
        // the extra distance to the stop.
        AssertFloat(farMilesWalked).IsGreater(nearMilesWalked);
        AssertFloat(farMilesWalked - nearMilesWalked).IsEqualApprox(80f / PixelsPerMile, Tolerance);
    }

    // SCENARIO: A resident rides a bus that passes through several stops.
    [TestCase]
    public void GivenRideOverThreeStops_WhenRideTimeCalculated_ThenDwellTimeIsAddedForEachStop()
    {
        // GIVEN: A 300 px bus line with a stop every 100 px.
        var boardingStop = CreateBusStop(new Vector2(0, 0));
        var firstStop = CreateBusStop(new Vector2(100, 0));
        var secondStop = CreateBusStop(new Vector2(200, 0));
        var exitStop = CreateBusStop(new Vector2(300, 0));
        var line = CreateBusLine([boardingStop, firstStop, secondStop, exitStop]);

        var ride = new RideSegment(line, boardingStop, exitStop);

        // WHEN: The time of the ride is calculated.
        float rideMinutes = ride.TimeMinutes;

        // THEN: The ride takes 3 dwell times longer than the driving time
        // alone, one for each stop after boarding.
        float drivingMinutes = 300f / BusPixelsPerMinute;
        AssertInt(ride.StopsTraveled).IsEqual(3);
        AssertFloat(rideMinutes).IsEqualApprox(drivingMinutes + 3 * DwellTimeMinutesPerStop, Tolerance);
    }

    // SCENARIO: Two bus lines cover the same distance, but one stops at every
    // stop along the way while the other only passes through intersections.
    [TestCase]
    public void GivenSameDistance_WhenRideHasFewerStops_ThenRideIsFaster()
    {
        // GIVEN: Two 300 px bus lines. The local line stops 3 times, and the
        // express line only stops where the rider gets off.
        var localBoardingStop = CreateBusStop(new Vector2(0, 0));
        var localExitStop = CreateBusStop(new Vector2(300, 0));
        var localLine = CreateBusLine(
        [
            localBoardingStop,
            CreateBusStop(new Vector2(100, 0)),
            CreateBusStop(new Vector2(200, 0)),
            localExitStop
        ]);

        var expressBoardingStop = CreateBusStop(new Vector2(0, 100));
        var expressExitStop = CreateBusStop(new Vector2(300, 100));
        var expressLine = CreateBusLine(
        [
            expressBoardingStop,
            CreateRoadNode(new Vector2(100, 100)),
            CreateRoadNode(new Vector2(200, 100)),
            expressExitStop
        ]);

        var localRide = new RideSegment(localLine, localBoardingStop, localExitStop);
        var expressRide = new RideSegment(expressLine, expressBoardingStop, expressExitStop);

        // WHEN: The time of each ride is calculated.
        float localMinutes = localRide.TimeMinutes;
        float expressMinutes = expressRide.TimeMinutes;

        // THEN: The express ride is faster by the dwell time of the 2 stops it
        // skips.
        AssertFloat(expressMinutes).IsLess(localMinutes);
        AssertFloat(localMinutes - expressMinutes).IsEqualApprox(2 * DwellTimeMinutesPerStop, Tolerance);
    }

    // SCENARIO: A resident's commute ends at the destination that the bus
    // route chose.
    [TestCase]
    public void GivenCommute_WhenBuilt_ThenDestinationIsLastWalkDestination()
    {
        // GIVEN: A commute that ends with a walk to a destination.
        var house = CreateNode(new Vector2(0, 0));
        var boardingStop = CreateBusStop(new Vector2(30, 0));
        var exitStop = CreateBusStop(new Vector2(230, 0));
        var destination = CreateNode(new Vector2(230, 70));
        var line = CreateBusLine([boardingStop, exitStop]);

        // WHEN: The commute is built.
        var commute = new Commute(
        [
            new WalkSegment(house, boardingStop),
            new RideSegment(line, boardingStop, exitStop),
            new WalkSegment(exitStop, destination)
        ]);

        // THEN: The commute starts at the house and ends at the destination.
        AssertObject(commute.Origin).IsSame(house);
        AssertObject(commute.Destination).IsSame(destination);
    }

    // SCENARIO: A resident's bus time includes walking, riding, and the dwell
    // time at each stop.
    [TestCase]
    public void GivenCommute_WhenBusMinutesCalculated_ThenAllSegmentsAndDwellTimeAreIncluded()
    {
        // GIVEN: A 30 px walk, a 200 px ride over 2 stops, and a 70 px walk.
        var house = CreateNode(new Vector2(0, 0));
        var boardingStop = CreateBusStop(new Vector2(30, 0));
        var middleStop = CreateBusStop(new Vector2(130, 0));
        var exitStop = CreateBusStop(new Vector2(230, 0));
        var destination = CreateNode(new Vector2(230, 70));
        var line = CreateBusLine([boardingStop, middleStop, exitStop]);

        var commute = new Commute(
        [
            new WalkSegment(house, boardingStop),
            new RideSegment(line, boardingStop, exitStop),
            new WalkSegment(exitStop, destination)
        ]);

        // WHEN: The bus time of the commute is calculated.
        float busMinutes = commute.BusMinutes;

        // THEN: The bus time is the walking time, the driving time, and the
        // dwell time at both stops after boarding.
        float expectedMinutes = (30f + 70f) * WalkMinutesPerPixel
            + 200f / BusPixelsPerMinute
            + 2 * DwellTimeMinutesPerStop;
        AssertFloat(busMinutes).IsEqualApprox(expectedMinutes, Tolerance);
        AssertFloat(busMinutes).IsEqualApprox(commute.TotalTimeMinutes, Tolerance);
    }

    // SCENARIO: A resident could drive to their destination along the road
    // network instead of taking the bus.
    [TestCase]
    public void GivenRoadNetwork_WhenCarMinutesCalculated_ThenCarFollowsShortestRoadPath()
    {
        // GIVEN: A house 10 px from one corner of a 300 px square of roads
        // with a diagonal, and a destination 20 px from the opposite corner.
        var house = CreateNode(new Vector2(-10, 0));
        var destination = CreateNode(new Vector2(320, 300));
        var topLeft = CreateRoadNode(new Vector2(0, 0));
        var topRight = CreateRoadNode(new Vector2(300, 0));
        var bottomRight = CreateRoadNode(new Vector2(300, 300));
        var bottomLeft = CreateRoadNode(new Vector2(0, 300));
        Connect(topLeft, topRight);
        Connect(topRight, bottomRight);
        Connect(bottomRight, bottomLeft);
        Connect(bottomLeft, topLeft);
        Connect(topLeft, bottomRight);
        Register(topLeft, topRight, bottomRight, bottomLeft);

        var boardingStop = CreateBusStop(new Vector2(0, 30));
        var exitStop = CreateBusStop(new Vector2(300, 270));
        var line = CreateBusLine([boardingStop, exitStop]);

        // WHEN: The commute is built and its car time is calculated.
        var commute = new Commute(
        [
            new WalkSegment(house, boardingStop),
            new RideSegment(line, boardingStop, exitStop),
            new WalkSegment(exitStop, destination)
        ]);
        float carMinutes = commute.CarMinutes;

        // THEN: The car drives to the nearest road, takes the diagonal, then
        // drives from the road to the destination.
        float expectedPixels = 10f + 300f * Mathf.Sqrt2 + 20f;
        AssertFloat(carMinutes).IsEqualApprox(expectedPixels / CarPixelsPerMinute, Tolerance);
    }

    // SCENARIO: A resident's house and destination are on roads that are
    // not connected to each other.
    [TestCase]
    public void GivenNoRoadPath_WhenCarMinutesCalculated_ThenStraightLineDistanceIsUsed()
    {
        // GIVEN: A house and destination 500 px apart, each next to a
        // separate road.
        var house = CreateNode(new Vector2(0, 0));
        var destination = CreateNode(new Vector2(300, 400));
        var houseRoadStart = CreateRoadNode(new Vector2(0, 10));
        var houseRoadEnd = CreateRoadNode(new Vector2(100, 10));
        var destinationRoadStart = CreateRoadNode(new Vector2(300, 390));
        var destinationRoadEnd = CreateRoadNode(new Vector2(200, 390));
        Connect(houseRoadStart, houseRoadEnd);
        Connect(destinationRoadStart, destinationRoadEnd);
        Register(houseRoadStart, houseRoadEnd, destinationRoadStart, destinationRoadEnd);

        var commute = new Commute(
        [
            new WalkSegment(house, destination)
        ]);

        // WHEN: The car time of the commute is calculated.
        float carMinutes = commute.CarMinutes;

        // THEN: The car time falls back to the straight-line distance.
        AssertFloat(carMinutes).IsEqualApprox(500f / CarPixelsPerMinute, Tolerance);
    }

    // SCENARIO: A resident's bus commute is compared to driving the same trip.
    [TestCase]
    public void GivenCommute_WhenBusToCarTimeRatioCalculated_ThenRatioIsBusMinutesOverCarMinutes()
    {
        // GIVEN: A commute with a 30 px walk, a 400 px ride, and a 70 px walk.
        var house = CreateNode(new Vector2(0, 0));
        var boardingStop = CreateBusStop(new Vector2(30, 0));
        var exitStop = CreateBusStop(new Vector2(430, 0));
        var destination = CreateNode(new Vector2(430, 70));
        var line = CreateBusLine([boardingStop, exitStop]);

        var commute = new Commute(
        [
            new WalkSegment(house, boardingStop),
            new RideSegment(line, boardingStop, exitStop),
            new WalkSegment(exitStop, destination)
        ]);

        // WHEN: The bus-to-car time ratio is calculated.
        float ratio = commute.BusToCarTimeRatio;

        // THEN: The ratio is the bus time divided by the car time.
        AssertFloat(commute.CarMinutes).IsGreater(0f);
        AssertFloat(ratio).IsEqualApprox(commute.BusMinutes / commute.CarMinutes, Tolerance);
    }

    // SCENARIO: A resident's destination is right next to their house.
    [TestCase]
    public void GivenVeryShortTrip_WhenCarMinutesCalculated_ThenCarMinutesIsNeverBelowMinimum()
    {
        // GIVEN: A house and destination only 5 px apart, which would take
        // far less than the minimum car time to drive.
        var house = CreateNode(new Vector2(0, 0));
        var destination = CreateNode(new Vector2(5, 0));

        var commute = new Commute(
        [
            new WalkSegment(house, destination)
        ]);

        // WHEN: The car time and bus-to-car time ratio are calculated.
        float carMinutes = commute.CarMinutes;
        float ratio = commute.BusToCarTimeRatio;

        // THEN: The car time is raised to the minimum, so the ratio is still a
        // finite number.
        AssertFloat(carMinutes).IsEqualApprox(MinimumCarMinutes, Tolerance);
        AssertFloat(ratio).IsEqualApprox(commute.BusMinutes / MinimumCarMinutes, Tolerance);
    }

    /// <summary>
    /// Creates a plain node at the given position to stand in for a house or
    /// destination building.
    /// </summary>
    private static Node2D CreateNode(Vector2 position)
    {
        var node = AutoFree(new Node2D());
        node.GlobalPosition = position;
        return node;
    }

    /// <summary>
    /// Creates a bus stop at the given position.
    /// </summary>
    private static BusStop CreateBusStop(Vector2 position)
    {
        var busStop = AutoFree(GD.Load<PackedScene>(Path.BusStopScene).Instantiate<BusStop>());
        busStop.GlobalPosition = position;
        return busStop;
    }

    /// <summary>
    /// Creates a bus line that travels through the given stops in order.
    /// </summary>
    private static BusLine CreateBusLine(List<RoadNode> path)
    {
        return AutoFree(new BusLine { Path = path });
    }

    /// <summary>
    /// Creates a road node at the given position to stand in for an
    /// intersection.
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
    /// Adds road nodes to LevelState so that the car route can be calculated
    /// on them. They are removed after the test.
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
