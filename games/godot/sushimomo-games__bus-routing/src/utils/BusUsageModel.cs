using Godot;
using static GlobalConstants;

/// <summary>
/// Calculates the probability that a resident uses the bus for their commute,
/// based on how far they walk and how much longer the bus takes than a car.
/// All tunable values live in GlobalConstants.
/// </summary>
public static class BusUsageModel
{
    /// <summary>
    /// Converts the miles walked during a commute to a 0-1 scale, where 0
    /// means no walking and values near 1 mean a very long walk.
    /// </summary>
    /// <param name="milesWalked">The total miles walked during the commute.</param>
    /// <returns>The walk penalty, from 0 to just under 1.</returns>
    public static float CalculateWalkPenalty(float milesWalked)
    {
        return CalculatePenalty(milesWalked, HalfPenaltyMiles);
    }

    /// <summary>
    /// Calculates the extra minutes at which the time penalty is 0.5. Longer
    /// car trips have a larger tolerance.
    /// </summary>
    /// <param name="carMinutes">The time in minutes the trip takes by car.</param>
    /// <returns>The tolerance in minutes.</returns>
    public static float CalculateToleranceMinutes(float carMinutes)
    {
        return BaseToleranceMinutes + ToleranceFraction * carMinutes;
    }

    /// <summary>
    /// Converts the minutes the bus takes beyond the car to a 0-1 scale,
    /// relative to the tolerance. The penalty is 0 if the bus is as fast as
    /// the car or faster.
    /// </summary>
    /// <param name="busMinutes">The time in minutes the trip takes by bus.</param>
    /// <param name="carMinutes">The time in minutes the trip takes by car.</param>
    /// <returns>The time penalty, from 0 to just under 1.</returns>
    public static float CalculateTimePenalty(float busMinutes, float carMinutes)
    {
        float timeDifferenceMinutes = Mathf.Max(0f, busMinutes - carMinutes);
        return CalculatePenalty(timeDifferenceMinutes, CalculateToleranceMinutes(carMinutes));
    }

    /// <summary>
    /// Calculates the weighted total friction of a commute.
    /// </summary>
    /// <param name="milesWalked">The total miles walked during the commute.</param>
    /// <param name="busMinutes">The time in minutes the trip takes by bus.</param>
    /// <param name="carMinutes">The time in minutes the trip takes by car.</param>
    /// <returns>The disutility, from 0 (no friction) to just under 1.</returns>
    public static float CalculateDisutility(float milesWalked, float busMinutes, float carMinutes)
    {
        return WalkWeight * CalculateWalkPenalty(milesWalked)
            + TimeWeight * CalculateTimePenalty(busMinutes, carMinutes);
    }

    /// <summary>
    /// Converts a disutility to the probability that a resident uses the bus.
    /// A higher disutility gives a lower probability, and the probability is
    /// exactly 0.5 when the disutility equals the Midpoint.
    /// </summary>
    /// <param name="disutility">The weighted total friction of the commute.</param>
    /// <returns>The probability, between 0 and 1.</returns>
    public static float CalculateProbability(float disutility)
    {
        return 1f / (1f + Mathf.Exp(GrowthRate * (disutility - Midpoint)));
    }

    /// <summary>
    /// Calculates the probability that a resident uses the bus for the given
    /// commute.
    /// </summary>
    /// <param name="commute">The resident's commute, or null if the resident cannot reach a destination by bus.</param>
    /// <returns>The probability, between 0 and 1. Returns 0 if the commute is null.</returns>
    public static float CalculateProbability(Commute commute)
    {
        if (commute == null)
        {
            return 0f;
        }

        return CalculateProbability(CalculateDisutility(commute.MilesWalked, commute.BusMinutes, commute.CarMinutes));
    }

    /// <summary>
    /// Converts a value to a 0-1 scale with the curve
    /// value^k / (value^k + halfPoint^k), where k is the PenaltySteepness.
    /// </summary>
    /// <param name="value">The value to convert. Values of 0 or less give a penalty of 0.</param>
    /// <param name="halfPoint">The value at which the penalty is 0.5.</param>
    /// <returns>The penalty, from 0 to just under 1.</returns>
    private static float CalculatePenalty(float value, float halfPoint)
    {
        // Checked first so that a value and half point of 0 do not divide 0 by 0.
        if (value <= 0f)
        {
            return 0f;
        }

        float scaledValue = Mathf.Pow(value, PenaltySteepness);
        return scaledValue / (scaledValue + Mathf.Pow(halfPoint, PenaltySteepness));
    }
}
