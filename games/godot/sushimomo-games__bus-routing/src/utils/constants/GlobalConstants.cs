/// <summary>
/// Holds global constant values used throughout the project.
/// </summary>
public static class GlobalConstants
{
    /// <summary>
    /// The number of pixels that represent one mile in the game world.
    /// </summary>
    public const uint PixelsPerMile = 200;

    /// <summary>
    /// The number of minutes it takes a resident to walk one pixel (~3 mph,
    /// or 20 minutes per mile). Raising this value makes walking slower.
    /// </summary>
    public const float WalkMinutesPerPixel = 0.1f;

    /// <summary>
    /// The number of pixels a bus travels in one minute (~30 mph).
    /// Raising this value makes buses faster.
    /// </summary>
    public const float BusPixelsPerMinute = 100f;

    /// <summary>
    /// The time in minutes a bus spends at each stop it passes through.
    /// Raising this value makes rides with many stops slower.
    /// </summary>
    public const float DwellTimeMinutesPerStop = 0.5f;

    /// <summary>
    /// The number of pixels a car travels in one minute. Matches the current
    /// bus speed (~30 mph). Raising this value makes cars faster.
    /// </summary>
    public const float CarPixelsPerMinute = 100f;

    /// <summary>
    /// The lower bound on a car commute's time in minutes, so the bus-to-car
    /// time ratio never divides by zero.
    /// </summary>
    public const float MinimumCarMinutes = 1f;

    // Bus usage probability model (see BusUsageModel). These are the only
    // values to tune when adjusting how likely residents are to ride.

    /// <summary>
    /// The miles walked at which the walk penalty is 0.5.
    /// Lowering this value makes residents dislike walking more.
    /// </summary>
    public const float HalfPenaltyMiles = 0.5f;

    /// <summary>
    /// The extra minutes a resident tolerates on even a very short trip. This
    /// is the baseline of the time tolerance.
    /// Raising this value makes residents more patient with slow buses.
    /// </summary>
    public const float BaseToleranceMinutes = 5f;

    /// <summary>
    /// How many extra minutes of tolerance each minute of car trip adds. At
    /// 0.5, a 30-minute drive adds 15 minutes of tolerance. At 0, tolerance
    /// no longer depends on trip length.
    /// </summary>
    public const float ToleranceFraction = 0.5f;

    /// <summary>
    /// How much the walk penalty matters in the disutility, from 0 to 1.
    /// Raising this value makes walking matter more and extra travel time
    /// matter less.
    /// </summary>
    public const float WalkWeight = 0.4f;

    /// <summary>
    /// How much the time penalty matters in the disutility. This is not set
    /// independently, so that it always adds up to 1 with WalkWeight.
    /// </summary>
    public const float TimeWeight = 1f - WalkWeight;

    /// <summary>
    /// The steepness of the sigmoid. Raising this value makes the probability
    /// switch from "rides" to "doesn't ride" over a narrower range of
    /// disutility. Keep it positive.
    /// </summary>
    public const float GrowthRate = 10f;

    /// <summary>
    /// The disutility at which the probability is exactly 0.5.
    /// Raising this value makes residents more willing to ride overall.
    /// Tuned from the suggested 0.4 so that the median Middletown house is
    /// near 45% when its stops are a short walk from the nearest road.
    /// </summary>
    public const float Midpoint = 0.67f;

    /// <summary>
    /// The exponent shared by both penalty curves. This is a fixed constant
    /// and should not be tuned. At 2, small walks and delays are mostly
    /// ignored, then the penalty rises quickly around its half-point.
    /// </summary>
    public const float PenaltySteepness = 2f;
}