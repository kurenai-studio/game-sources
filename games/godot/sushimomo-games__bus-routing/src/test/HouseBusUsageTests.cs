using GdUnit4;
using Godot;
using static GdUnit4.Assertions;

[TestSuite]
public class HouseBusUsageTests
{
    private const float Tolerance = 0.0001f;

    private BusLine _line;
    private DestinationStub _destination;

    [AfterTest]
    public void UnregisterLevelState()
    {
        LevelState.AllBusLines.Remove(_line);
        LevelState.AllDestinations.Remove(_destination);
        _line = null;
        _destination = null;
    }

    // SCENARIO: A resident's house is connected to their destination by a
    // bus line.
    [TestCase]
    public void GivenConnectedHouse_WhenCheckStatusUpdated_ThenProbabilityComesFromModel()
    {
        // GIVEN: A red house next to a bus stop, with a bus line to a stop
        // next to a red destination.
        var house = CreateConnectedHouse(Colors.Red, Colors.Red);

        // WHEN: The house updates its check status.
        house.UpdateCheckStatus();

        // THEN: The house is connected, and its probability is the model's
        // probability for its commute.
        AssertBool(house.IsChecked).IsTrue();
        AssertObject(house.CurrentItinerary).IsNotNull();
        AssertFloat(house.BusUsageProbability)
            .IsEqualApprox(BusUsageModel.CalculateProbability(house.CurrentItinerary), Tolerance);
        AssertFloat(house.BusUsageProbability).IsGreater(0f);
    }

    // SCENARIO: A resident's house has no bus stop within walking distance.
    [TestCase]
    public void GivenHouseWithoutReachableStop_WhenCheckStatusUpdated_ThenProbabilityIsZero()
    {
        // GIVEN: A house with no reachable bus stop.
        var house = AutoFree(new HouseStub(null));

        // WHEN: The house updates its check status.
        house.UpdateCheckStatus();

        // THEN: The house is not connected and the resident never rides.
        AssertBool(house.IsChecked).IsFalse();
        AssertObject(house.CurrentItinerary).IsNull();
        AssertFloat(house.BusUsageProbability).IsEqual(0f);
    }

    // SCENARIO: A resident's bus line reaches a destination, but not one of
    // the resident's color.
    [TestCase]
    public void GivenNoMatchingDestination_WhenCheckStatusUpdated_ThenProbabilityIsZero()
    {
        // GIVEN: A red house connected by bus to a blue destination.
        var house = CreateConnectedHouse(Colors.Red, Colors.Blue);

        // WHEN: The house updates its check status.
        house.UpdateCheckStatus();

        // THEN: The house is not connected and the resident never rides.
        AssertBool(house.IsChecked).IsFalse();
        AssertFloat(house.BusUsageProbability).IsEqual(0f);
    }

    // SCENARIO: The player removes the bus stop that a connected resident
    // was using.
    [TestCase]
    public void GivenConnectedHouse_WhenStopIsLost_ThenProbabilityDropsToZero()
    {
        // GIVEN: A connected house with a probability above 0.
        var house = CreateConnectedHouse(Colors.Red, Colors.Red);
        house.UpdateCheckStatus();
        AssertFloat(house.BusUsageProbability).IsGreater(0f);

        // WHEN: The house loses its bus stop and updates its check status.
        house.ForcedStop = null;
        house.UpdateCheckStatus();

        // THEN: The probability drops back to 0.
        AssertBool(house.IsChecked).IsFalse();
        AssertFloat(house.BusUsageProbability).IsEqual(0f);
    }

    /// <summary>
    /// Creates a house 5 px from a bus stop, with a 100 px bus line to a stop
    /// that is 5 px from a destination. The bus line and destination are
    /// added to LevelState and removed after the test.
    /// </summary>
    /// <param name="houseColor">The color of the house.</param>
    /// <param name="destinationColor">The color of the destination.</param>
    private HouseStub CreateConnectedHouse(Color houseColor, Color destinationColor)
    {
        var busStopScene = GD.Load<PackedScene>(Path.BusStopScene);
        var startStop = AutoFree(busStopScene.Instantiate<BusStop>());
        startStop.GlobalPosition = new Vector2(0, 0);
        var endStop = AutoFree(busStopScene.Instantiate<BusStop>());
        endStop.GlobalPosition = new Vector2(100, 0);

        _destination = AutoFree(new DestinationStub(endStop)
        {
            GlobalPosition = new Vector2(105, 0),
            Modulate = destinationColor
        });
        LevelState.AllDestinations.Add(_destination);

        _line = AutoFree(new BusLine { Path = [startStop, endStop] });
        LevelState.AllBusLines.Add(_line);

        var house = AutoFree(new HouseStub(startStop)
        {
            GlobalPosition = new Vector2(5, 0),
            Modulate = houseColor
        });
        return house;
    }
}
