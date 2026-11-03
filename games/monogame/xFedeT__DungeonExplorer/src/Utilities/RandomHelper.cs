// ============================================
// RandomHelper.cs - Random utility functions
// ============================================
using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Linq;

namespace DungeonExplorer.Utilities
{
    /// <summary>
    /// Collection of random utility functions
    /// </summary>
    public static class RandomHelper
    {
        private static Random _random = new Random();

        /// <summary>
        /// Sets the seed for the random number generator
        /// </summary>
        public static void SetSeed(int seed)
        {
            _random = new Random(seed);
        }

        /// <summary>
        /// Returns a random float between min and max
        /// </summary>
        public static float Range(float min, float max)
        {
            return min + (float)_random.NextDouble() * (max - min);
        }

        /// <summary>
        /// Returns a random integer between min (inclusive) and max (exclusive)
        /// </summary>
        public static int Range(int min, int max)
        {
            return _random.Next(min, max);
        }

        /// <summary>
        /// Returns a random Vector2 within a circle
        /// </summary>
        public static Vector2 InsideUnitCircle()
        {
            float angle = Range(0f, MathHelper.TWO_PI);
            float radius = (float)Math.Sqrt(_random.NextDouble());
            return new Vector2(
                (float)Math.Cos(angle) * radius,
                (float)Math.Sin(angle) * radius
            );
        }

        /// <summary>
        /// Returns a random Vector2 on the edge of a unit circle
        /// </summary>
        public static Vector2 OnUnitCircle()
        {
            float angle = Range(0f, MathHelper.TWO_PI);
            return new Vector2(
                (float)Math.Cos(angle),
                (float)Math.Sin(angle)
            );
        }

        /// <summary>
        /// Returns a random Vector2 within specified bounds
        /// </summary>
        public static Vector2 InsideRect(Rectangle bounds)
        {
            return new Vector2(
                Range(bounds.Left, bounds.Right),
                Range(bounds.Top, bounds.Bottom)
            );
        }

        /// <summary>
        /// Returns a random boolean value
        /// </summary>
        public static bool Bool()
        {
            return _random.Next(2) == 0;
        }

        /// <summary>
        /// Returns true with the specified probability (0.0 to 1.0)
        /// </summary>
        public static bool Chance(float probability)
        {
            return _random.NextDouble() < probability;
        }

        /// <summary>
        /// Returns a random element from an array
        /// </summary>
        public static T Choose<T>(params T[] options)
        {
            if (options.Length == 0) throw new ArgumentException("No options provided");
            return options[_random.Next(options.Length)];
        }

        /// <summary>
        /// Returns a random element from a list
        /// </summary>
        public static T Choose<T>(List<T> list)
        {
            if (list.Count == 0) throw new ArgumentException("List is empty");
            return list[_random.Next(list.Count)];
        }

        /// <summary>
        /// Shuffles a list in place using Fisher-Yates algorithm
        /// </summary>
        public static void Shuffle<T>(List<T> list)
        {
            for (int i = list.Count - 1; i > 0; i--)
            {
                int j = _random.Next(i + 1);
                T temp = list[i];
                list[i] = list[j];
                list[j] = temp;
            }
        }

        /// <summary>
        /// Returns a shuffled copy of the list
        /// </summary>
        public static List<T> Shuffled<T>(List<T> list)
        {
            var result = new List<T>(list);
            Shuffle(result);
            return result;
        }

        /// <summary>
        /// Returns multiple unique random elements from a list
        /// </summary>
        public static List<T> Choose<T>(List<T> list, int count)
        {
            if (count > list.Count)
                throw new ArgumentException("Count cannot exceed list size");

            var shuffled = Shuffled(list);
            return shuffled.Take(count).ToList();
        }

        /// <summary>
        /// Weighted random selection
        /// </summary>
        public static T WeightedChoice<T>(Dictionary<T, float> weightedOptions)
        {
            float totalWeight = weightedOptions.Values.Sum();
            float randomWeight = Range(0f, totalWeight);
            
            float currentWeight = 0f;
            foreach (var kvp in weightedOptions)
            {
                currentWeight += kvp.Value;
                if (randomWeight <= currentWeight)
                    return kvp.Key;
            }

            // Fallback to first option
            return weightedOptions.Keys.First();
        }

        /// <summary>
        /// Returns a random color
        /// </summary>
        public static Color RandomColor()
        {
            return new Color(
                _random.Next(256),
                _random.Next(256),
                _random.Next(256)
            );
        }

        /// <summary>
        /// Returns a random color with specified alpha
        /// </summary>
        public static Color RandomColor(byte alpha)
        {
            return new Color(
                _random.Next(256),
                _random.Next(256),
                _random.Next(256),
                alpha
            );
        }

        /// <summary>
        /// Returns a random rotation (0 to 2π)
        /// </summary>
        public static float RandomRotation()
        {
            return Range(0f, MathHelper.TWO_PI);
        }

        /// <summary>
        /// Returns a random direction vector (normalized)
        /// </summary>
        public static Vector2 RandomDirection()
        {
            return OnUnitCircle();
        }
    }
}