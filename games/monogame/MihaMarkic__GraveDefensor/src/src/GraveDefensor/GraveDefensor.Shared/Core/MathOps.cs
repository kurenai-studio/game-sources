using System;

namespace GraveDefensor.Shared.Core
{
    public static class MathOps
    {
        internal static double CalculateMinAngleDifference(double source, double target)
        {
            double result = target - source;
            if (result > Math.PI)
            {
                return result - 2 * Math.PI;
            }
            else if (result < -Math.PI)
            {
                return result + 2 * Math.PI;
            }
            else
            {
                return result;
            }
        }
        internal static double CalculateMaxRotation(TimeSpan elapsed, double speed) => elapsed.TotalMinutes * speed;
        internal static double CalculateRotation(double targetAngle, double rotation, double maxRotation)
        {
            double result;
            if (targetAngle < rotation)
            {
                result = Math.Max(rotation - maxRotation, targetAngle);
            }
            else if (targetAngle > rotation)
            {
                result = Math.Min(rotation + maxRotation, targetAngle);
            }
            else
            {
                result = rotation;
            }
            return result;
        }
    }
}
