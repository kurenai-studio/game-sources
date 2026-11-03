// ============================================
// MathHelper.cs - Mathematical utility functions
// ============================================
using Microsoft.Xna.Framework;
using System;

namespace DungeonExplorer.Utilities
{
    /// <summary>
    /// Collection of mathematical helper functions
    /// </summary>
    public static class MathHelper
    {
        public const float PI = (float)Math.PI;
        public const float TWO_PI = PI * 2f;
        public const float HALF_PI = PI * 0.5f;
        public const float DEG_TO_RAD = PI / 180f;
        public const float RAD_TO_DEG = 180f / PI;

        /// <summary>
        /// Clamps a value between a minimum and maximum
        /// </summary>
        public static float Clamp(float value, float min, float max)
        {
            if (value < min) return min;
            if (value > max) return max;
            return value;
        }

        /// <summary>
        /// Returns the sign of a value (-1, 0, or 1)
        /// </summary>
        public static float Sign(float value)
        {
            if (value > 0f) return 1f;
            if (value < 0f) return -1f;
            return 0f;
        }

        /// <summary>
        /// Linear interpolation between two values
        /// </summary>
        public static float Lerp(float a, float b, float t)
        {
            return a + (b - a) * t;
        }

        /// <summary>
        /// Repeats a value within a given range
        /// </summary>
        public static float Repeat(float t, float length)
        {
            return Clamp(t - (float)Math.Floor(t / length) * length, 0f, length);
        }

        /// <summary>
        /// Ping-pong a value between 0 and length
        /// </summary>
        public static float PingPong(float t, float length)
        {
            t = Repeat(t, length * 2f);
            return length - Math.Abs(t - length);
        }

        /// <summary>
        /// Inverse linear interpolation - finds t for lerp(a, b, t) = value
        /// </summary>
        public static float InverseLerp(float a, float b, float value)
        {
            if (Math.Abs(a - b) < 0.0001f) return 0f;
            return (value - a) / (b - a);
        }

        /// <summary>
        /// Remaps a value from one range to another
        /// </summary>
        public static float Remap(float value, float fromMin, float fromMax, float toMin, float toMax)
        {
            float t = InverseLerp(fromMin, fromMax, value);
            return Lerp(toMin, toMax, t);
        }

        /// <summary>
        /// Returns the next power of 2 greater than or equal to the input
        /// </summary>
        public static int NextPowerOfTwo(int value)
        {
            value--;
            value |= value >> 1;
            value |= value >> 2;
            value |= value >> 4;
            value |= value >> 8;
            value |= value >> 16;
            value++;
            return value;
        }

        /// <summary>
        /// Checks if a number is a power of 2
        /// </summary>
        public static bool IsPowerOfTwo(int value)
        {
            return value > 0 && (value & (value - 1)) == 0;
        }

        /// <summary>
        /// Calculates the distance squared between two points (faster than Distance)
        /// </summary>
        public static float DistanceSquared(Vector2 a, Vector2 b)
        {
            float dx = b.X - a.X;
            float dy = b.Y - a.Y;
            return dx * dx + dy * dy;
        }

        /// <summary>
        /// Moves a value towards a target by a maximum step
        /// </summary>
        public static float MoveTowards(float current, float target, float maxDelta)
        {
            if (Math.Abs(target - current) <= maxDelta)
                return target;
            return current + Math.Sign(target - current) * maxDelta;
        }
    }
}