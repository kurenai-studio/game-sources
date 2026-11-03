using Microsoft.Xna.Framework;
using System;

namespace Snake.Core.Collisions
{
    /// <summary>
    /// Represents a circle for collision detection.
    /// </summary>
    public readonly struct Circle : IEquatable<Circle>
    {
        /// <summary>
        /// Gets an empty circle at the origin with zero radius.
        /// </summary>
        public static Circle Empty { get; } = new Circle(0, 0, 0);

        /// <summary>
        /// Gets the X coordinate of the circle's center.
        /// </summary>
        public readonly int X { get; }

        /// <summary>
        /// Gets the Y coordinate of the circle's center.
        /// </summary>
        public readonly int Y { get; }

        /// <summary>
        /// Gets the radius of the circle.
        /// </summary>
        public readonly int Radius { get; }

        /// <summary>
        /// Gets the center point of the circle.
        /// </summary>
        public readonly Point Location => new Point(X, Y);

        /// <summary>
        /// Gets a value indicating whether this circle is empty.
        /// </summary>
        public readonly bool IsEmpty => X == 0 && Y == 0 && Radius == 0;

        /// <summary>
        /// Gets the top edge of the circle.
        /// </summary>
        public readonly int Top => Y - Radius;

        /// <summary>
        /// Gets the bottom edge of the circle.
        /// </summary>
        public readonly int Bottom => Y + Radius;

        /// <summary>
        /// Gets the left edge of the circle.
        /// </summary>
        public readonly int Left => X - Radius;

        /// <summary>
        /// Gets the right edge of the circle.
        /// </summary>
        public readonly int Right => X + Radius;

        /// <summary>
        /// Initializes a new instance of the Circle struct.
        /// </summary>
        /// <param name="x">The X coordinate of the center.</param>
        /// <param name="y">The Y coordinate of the center.</param>
        /// <param name="radius">The radius of the circle.</param>
        public Circle(int x, int y, int radius)
        {
            X = x;
            Y = y;
            Radius = radius;
        }

        /// <summary>
        /// Initializes a new instance of the Circle struct.
        /// </summary>
        /// <param name="location">The center point of the circle.</param>
        /// <param name="radius">The radius of the circle.</param>
        public Circle(Point location, int radius)
        {
            X = location.X;
            Y = location.Y;
            Radius = radius;
        }

        /// <summary>
        /// Checks if this circle intersects with another circle.
        /// </summary>
        /// <param name="other">The other circle to check intersection with.</param>
        /// <returns>True if the circles intersect, false otherwise.</returns>
        public readonly bool Intersect(Circle other)
        {
            // Check if the circles are empty
            if (IsEmpty || other.IsEmpty)
            {
                return false;
            }

            // Calculate the combined radius squared
            int combinedRadius = Radius + other.Radius;
            int radiiSquared = combinedRadius * combinedRadius;
            
            // Calculate the distance between the centers squared
            float dx = X - other.X;
            float dy = Y - other.Y;
            float distanceSquared = dx * dx + dy * dy;
            
            // Check if the distance between the centers is less than or equal to the combined radius squared
            return distanceSquared <= radiiSquared;
        }

        /// <summary>
        /// Determines whether the specified object is equal to this circle.
        /// </summary>
        public override readonly bool Equals(object obj) => obj is Circle other && Equals(other);

        /// <summary>
        /// Determines whether the specified circle is equal to this circle.
        /// </summary>
        public readonly bool Equals(Circle other) => X == other.X && Y == other.Y && Radius == other.Radius;

        /// <summary>
        /// Returns the hash code for this circle.
        /// </summary>
        public override readonly int GetHashCode() => HashCode.Combine(X, Y, Radius);

        /// <summary>
        /// Compares two circles for equality.
        /// </summary>
        public static bool operator ==(Circle lhs, Circle rhs) => lhs.Equals(rhs);

        /// <summary>
        /// Compares two circles for inequality.
        /// </summary>
        public static bool operator !=(Circle lhs, Circle rhs) => !lhs.Equals(rhs);
    }
}
