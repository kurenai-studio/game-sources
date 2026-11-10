using GdUnit4;
using Godot;
using static GdUnit4.Assertions;
using static GlobalConstants;

[TestSuite]
public class BusUsageModelTests
{
    private const float Tolerance = 0.0001f;

    // SCENARIO: A resident's commute has exactly the disutility at which the
    // model is undecided.
    [TestCase]
    public void GivenDisutilityAtMidpoint_WhenProbabilityCalculated_ThenProbabilityIsHalf()
    {
        // GIVEN: A disutility equal to the Midpoint.
        float disutility = Midpoint;

        // WHEN: The probability is calculated.
        float probability = BusUsageModel.CalculateProbability(disutility);

        // THEN: The resident is equally likely to ride or not ride.
        AssertFloat(probability).IsEqualApprox(0.5f, Tolerance);
    }

    // SCENARIO: Residents' commutes range from no friction to the most
    // friction the model allows.
    [TestCase]
    public void GivenIncreasingDisutility_WhenProbabilityCalculated_ThenProbabilityDecreasesWithinZeroAndOne()
    {
        // GIVEN: Disutilities from 0 to 1 in steps of 0.1.
        float previousProbability = float.MaxValue;

        for (int step = 0; step <= 10; step++)
        {
            float disutility = step / 10f;

            // WHEN: The probability is calculated.
            float probability = BusUsageModel.CalculateProbability(disutility);

            // THEN: The probability is strictly lower than the previous one
            // and stays between 0 and 1.
            AssertFloat(probability).IsLess(previousProbability);
            AssertFloat(probability).IsGreater(0f);
            AssertFloat(probability).IsLess(1f);
            previousProbability = probability;
        }
    }

    // SCENARIO: A resident walks exactly the distance at which walking
    // becomes half of its maximum penalty.
    [TestCase]
    public void GivenHalfPenaltyMilesWalked_WhenWalkPenaltyCalculated_ThenPenaltyIsHalf()
    {
        // GIVEN: A walk of HalfPenaltyMiles.
        float milesWalked = HalfPenaltyMiles;

        // WHEN: The walk penalty is calculated.
        float walkPenalty = BusUsageModel.CalculateWalkPenalty(milesWalked);

        // THEN: The walk penalty is 0.5.
        AssertFloat(walkPenalty).IsEqualApprox(0.5f, Tolerance);
    }

    // SCENARIO: A resident does not walk at all.
    [TestCase]
    public void GivenNoWalking_WhenWalkPenaltyCalculated_ThenPenaltyIsZero()
    {
        // WHEN: The walk penalty of a 0 mile walk is calculated.
        float walkPenalty = BusUsageModel.CalculateWalkPenalty(0f);

        // THEN: There is no walk penalty.
        AssertFloat(walkPenalty).IsEqual(0f);
    }

    // SCENARIO: Longer car trips make residents more tolerant of extra time.
    [TestCase]
    public void GivenCarMinutes_WhenToleranceCalculated_ThenToleranceGrowsWithCarMinutes()
    {
        // GIVEN: A 30 minute car trip.
        float carMinutes = 30f;

        // WHEN: The tolerance is calculated.
        float toleranceMinutes = BusUsageModel.CalculateToleranceMinutes(carMinutes);

        // THEN: The tolerance is the base tolerance plus a fraction of the
        // car trip.
        AssertFloat(toleranceMinutes).IsEqualApprox(BaseToleranceMinutes + ToleranceFraction * carMinutes, Tolerance);
    }

    // SCENARIO: The bus takes exactly as many extra minutes as the resident
    // tolerates.
    [TestCase]
    public void GivenTimeDifferenceAtTolerance_WhenTimePenaltyCalculated_ThenPenaltyIsHalf()
    {
        // GIVEN: A 20 minute car trip and a bus trip that is longer by the
        // tolerance.
        float carMinutes = 20f;
        float busMinutes = carMinutes + BusUsageModel.CalculateToleranceMinutes(carMinutes);

        // WHEN: The time penalty is calculated.
        float timePenalty = BusUsageModel.CalculateTimePenalty(busMinutes, carMinutes);

        // THEN: The time penalty is 0.5.
        AssertFloat(timePenalty).IsEqualApprox(0.5f, Tolerance);
    }

    // SCENARIO: The bus is faster than driving.
    [TestCase]
    public void GivenBusFasterThanCar_WhenTimePenaltyCalculated_ThenPenaltyIsZero()
    {
        // WHEN: The time penalty of a 10 minute bus trip and a 15 minute car
        // trip is calculated.
        float timePenalty = BusUsageModel.CalculateTimePenalty(10f, 15f);

        // THEN: There is no time penalty.
        AssertFloat(timePenalty).IsEqual(0f);
    }

    // SCENARIO: Two buses are each 10 minutes slower than driving, but one
    // trip is much longer than the other.
    [TestCase]
    public void GivenSameDelay_WhenCarTripIsLonger_ThenTimePenaltyIsLower()
    {
        // GIVEN: A 5 minute and a 40 minute car trip, each with a bus trip
        // that takes 10 minutes longer.
        float shortTripPenalty = BusUsageModel.CalculateTimePenalty(15f, 5f);
        float longTripPenalty = BusUsageModel.CalculateTimePenalty(50f, 40f);

        // THEN: The same delay matters less on the longer trip.
        AssertFloat(longTripPenalty).IsLess(shortTripPenalty);
    }

    // SCENARIO: A resident has an extremely long walk and an extremely slow
    // bus.
    [TestCase]
    public void GivenExtremeFriction_WhenPenaltiesCalculated_ThenPenaltiesStayBelowOne()
    {
        // WHEN: The penalties of a 50 mile walk and a bus 1000 minutes slower
        // than the car are calculated.
        float walkPenalty = BusUsageModel.CalculateWalkPenalty(50f);
        float timePenalty = BusUsageModel.CalculateTimePenalty(1010f, 10f);
        float disutility = BusUsageModel.CalculateDisutility(50f, 1010f, 10f);

        // THEN: The penalties approach 1 without exceeding it, so the
        // disutility never exceeds 1.
        AssertFloat(walkPenalty).IsGreater(0.99f);
        AssertFloat(walkPenalty).IsLessEqual(1f);
        AssertFloat(timePenalty).IsGreater(0.99f);
        AssertFloat(timePenalty).IsLessEqual(1f);
        AssertFloat(disutility).IsLessEqual(1f);
    }

    // SCENARIO: Disutility combines the walk and time penalties.
    [TestCase]
    public void GivenCommuteValues_WhenDisutilityCalculated_ThenPenaltiesAreWeighted()
    {
        // GIVEN: A 0.3 mile walk, a 25 minute bus trip, and a 10 minute car trip.
        float milesWalked = 0.3f;
        float busMinutes = 25f;
        float carMinutes = 10f;

        // WHEN: The disutility is calculated.
        float disutility = BusUsageModel.CalculateDisutility(milesWalked, busMinutes, carMinutes);

        // THEN: The disutility is the weighted sum of both penalties.
        float expected = WalkWeight * BusUsageModel.CalculateWalkPenalty(milesWalked)
            + TimeWeight * BusUsageModel.CalculateTimePenalty(busMinutes, carMinutes);
        AssertFloat(disutility).IsEqualApprox(expected, Tolerance);
        AssertFloat(WalkWeight + TimeWeight).IsEqualApprox(1f, Tolerance);
    }

    // SCENARIO: A commute with no walking and a bus as fast as the car has no
    // friction at all.
    [TestCase]
    public void GivenNoFriction_WhenDisutilityCalculated_ThenDisutilityIsZero()
    {
        // WHEN: The disutility of a commute with no walking and equal bus and
        // car times is calculated.
        float disutility = BusUsageModel.CalculateDisutility(0f, 10f, 10f);

        // THEN: The disutility is 0.
        AssertFloat(disutility).IsEqual(0f);
    }

    // SCENARIO: Two residents have the same trip, but one walks farther.
    [TestCase]
    public void GivenLongerWalk_WhenProbabilityCalculated_ThenProbabilityIsLower()
    {
        // GIVEN: Walks of 0.2 and 0.8 miles with the same bus and car times.
        float shortWalkDisutility = BusUsageModel.CalculateDisutility(0.2f, 20f, 10f);
        float longWalkDisutility = BusUsageModel.CalculateDisutility(0.8f, 20f, 10f);

        // WHEN: The probability of each is calculated.
        float shortWalkProbability = BusUsageModel.CalculateProbability(shortWalkDisutility);
        float longWalkProbability = BusUsageModel.CalculateProbability(longWalkDisutility);

        // THEN: The resident who walks farther is less likely to ride.
        AssertFloat(longWalkProbability).IsLess(shortWalkProbability);
    }

    // SCENARIO: Two residents have the same walk and car trip, but one bus
    // trip is slower.
    [TestCase]
    public void GivenSlowerBus_WhenProbabilityCalculated_ThenProbabilityIsLower()
    {
        // GIVEN: Bus trips of 15 and 30 minutes with the same walk and car time.
        float fastBusDisutility = BusUsageModel.CalculateDisutility(0.3f, 15f, 10f);
        float slowBusDisutility = BusUsageModel.CalculateDisutility(0.3f, 30f, 10f);

        // WHEN: The probability of each is calculated.
        float fastBusProbability = BusUsageModel.CalculateProbability(fastBusDisutility);
        float slowBusProbability = BusUsageModel.CalculateProbability(slowBusDisutility);

        // THEN: The resident with the slower bus is less likely to ride.
        AssertFloat(slowBusProbability).IsLess(fastBusProbability);
    }

    // SCENARIO: A resident cannot reach any destination by bus.
    [TestCase]
    public void GivenNullCommute_WhenProbabilityCalculated_ThenProbabilityIsZero()
    {
        // WHEN: The probability of a missing commute is calculated.
        float probability = BusUsageModel.CalculateProbability((Commute)null);

        // THEN: The resident never rides the bus.
        AssertFloat(probability).IsEqual(0f);
    }

    // SCENARIO: A resident has a full bus commute.
    [TestCase]
    public void GivenCommute_WhenProbabilityCalculated_ThenCommuteValuesAreUsed()
    {
        // GIVEN: A commute with a 30 px walk, a 200 px ride, and a 70 px walk.
        var house = CreateNode(new Vector2(0, 0));
        var boardingStop = CreateBusStop(new Vector2(30, 0));
        var exitStop = CreateBusStop(new Vector2(230, 0));
        var destination = CreateNode(new Vector2(230, 70));
        var line = AutoFree(new BusLine { Path = [boardingStop, exitStop] });

        var commute = new Commute(
        [
            new WalkSegment(house, boardingStop),
            new RideSegment(line, boardingStop, exitStop),
            new WalkSegment(exitStop, destination)
        ]);

        // WHEN: The probability of the commute is calculated.
        float probability = BusUsageModel.CalculateProbability(commute);

        // THEN: The probability comes from the commute's miles walked, bus
        // time, and car time.
        float disutility = BusUsageModel.CalculateDisutility(commute.MilesWalked, commute.BusMinutes, commute.CarMinutes);
        AssertFloat(probability).IsEqualApprox(BusUsageModel.CalculateProbability(disutility), Tolerance);
        AssertFloat(commute.MilesWalked).IsEqualApprox((30f + 70f) / PixelsPerMile, Tolerance);
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
}
