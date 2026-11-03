// ============================================
// Vector2Extensions.cs - Extensions for Vector2
// ============================================
using Microsoft.Xna.Framework;
using System;

namespace DungeonExplorer.Utilities
{
    /// <summary>
    /// Extension methods for Vector2
    /// </summary>
    public static class Vector2Extensions
    {
        /// <summary>
        /// Rotates a vector by the specified angle (in radians)
        /// </summary>
        public static Vector2 Rotate(this Vector2 vector, float angle)
        {
            float cos = (float)Math.Cos(angle);
            float sin = (float)Math.Sin(angle);

            return new Vector2(
                vector.X * cos - vector.Y * sin,
                vector.X * sin + vector.Y * cos
            );
        }

        /// <summary>
        /// Rotates a vector around a pivot point
        /// </summary>
        public static Vector2 RotateAround(this Vector2 vector, Vector2 pivot, float angle)
        {
            Vector2 offset = vector - pivot;
            float cos = (float)Math.Cos(angle);
            float sin = (float)Math.Sin(angle);
    
            Vector2 rotatedOffset = new Vector2(
                offset.X * cos - offset.Y * sin,
                offset.X * sin + offset.Y * cos
            );
    
            return rotatedOffset + pivot;
        }

        /// <summary>
        /// Gets the angle of the vector in radians
        /// </summary>
        public static float ToAngle(this Vector2 vector)
        {
            return (float)Math.Atan2(vector.Y, vector.X);
        }

        /// <summary>
        /// Creates a vector from an angle and magnitude
        /// </summary>
        public static Vector2 FromAngle(float angle, float magnitude = 1f)
        {
            return new Vector2(
                (float)Math.Cos(angle) * magnitude,
                (float)Math.Sin(angle) * magnitude
            );
        }

        /// <summary>
        /// Returns the perpendicular vector (rotated 90 degrees)
        /// </summary>
        public static Vector2 Perpendicular(this Vector2 vector)
        {
            return new Vector2(-vector.Y, vector.X);
        }

        /// <summary>
        /// Projects one vector onto another
        /// </summary>
        public static Vector2 Project(this Vector2 vector, Vector2 onto)
        {
            float dot = Vector2.Dot(vector, onto);
            float lengthSquared = onto.LengthSquared();

            if (lengthSquared < 0.0001f) return Vector2.Zero;

            return onto * (dot / lengthSquared);
        }

        /// <summary>
        /// Reflects a vector off a surface with the given normal
        /// </summary>
        public static Vector2 Reflect(this Vector2 vector, Vector2 normal)
        {
            return vector - 2f * Vector2.Dot(vector, normal) * normal;
        }

        /// <summary>
        /// Clamps the magnitude of a vector
        /// </summary>
        public static Vector2 ClampMagnitude(this Vector2 vector, float maxLength)
        {
            if (vector.LengthSquared() > maxLength * maxLength)
            {
                vector.Normalize();
                return vector * maxLength;
            }

            return vector;
        }

        /// <summary>
        /// Sets the magnitude of a vector
        /// </summary>
        public static Vector2 SetMagnitude(this Vector2 vector, float magnitude)
        {
            if (vector.LengthSquared() < 0.0001f) return Vector2.Zero;
            vector.Normalize();
            return vector * magnitude;
        }

        /// <summary>
        /// Linear interpolation between two vectors
        /// </summary>
        public static Vector2 Lerp(this Vector2 from, Vector2 to, float t)
        {
            return Vector2.Lerp(from, to, MathHelper.Clamp(t, 0f, 1f));
        }

        /// <summary>
        /// Spherical linear interpolation between two vectors
        /// </summary>
        public static Vector2 Slerp(this Vector2 from, Vector2 to, float t)
        {
            t = MathHelper.Clamp(t, 0f, 1f);

            float dot = Vector2.Dot(from.Normalized(), to.Normalized());
            dot = MathHelper.Clamp(dot, -1f, 1f);

            float theta = (float)Math.Acos(dot) * t;
            Vector2 relative = (to - from * dot).Normalized();

            return from * (float)Math.Cos(theta) + relative * (float)Math.Sin(theta);
        }

        /// <summary>
        /// Returns a normalized version of the vector without modifying the original
        /// </summary>
        public static Vector2 Normalized(this Vector2 vector)
        {
            if (vector.LengthSquared() < 0.0001f) return Vector2.Zero;

            Vector2 result = vector;
            result.Normalize();
            return result;
        }

        /// <summary>
        /// Checks if the vector is approximately zero
        /// </summary>
        public static bool IsZero(this Vector2 vector, float epsilon = 0.0001f)
        {
            return vector.LengthSquared() < epsilon * epsilon;
        }

        /// <summary>
        /// Rounds the vector components to the nearest integer
        /// </summary>
        public static Vector2 Round(this Vector2 vector)
        {
            return new Vector2(
                (float)Math.Round(vector.X),
                (float)Math.Round(vector.Y)
            );
        }

        /// <summary>
        /// Floors the vector components
        /// </summary>
        public static Vector2 Floor(this Vector2 vector)
        {
            return new Vector2(
                (float)Math.Floor(vector.X),
                (float)Math.Floor(vector.Y)
            );
        }

        /// <summary>
        /// Ceils the vector components
        /// </summary>
        public static Vector2 Ceiling(this Vector2 vector)
        {
            return new Vector2(
                (float)Math.Ceiling(vector.X),
                (float)Math.Ceiling(vector.Y)
            );
        }

        /// <summary>
        /// Returns the absolute value of each component
        /// </summary>
        public static Vector2 Abs(this Vector2 vector)
        {
            return new Vector2(Math.Abs(vector.X), Math.Abs(vector.Y));
        }

        /// <summary>
        /// Converts to Point (useful for grid coordinates)
        /// </summary>
        public static Point ToPoint(this Vector2 vector)
        {
            return new Point((int)vector.X, (int)vector.Y);
        }

        /// <summary>
        /// Gets the distance to another vector
        /// </summary>
        public static float DistanceTo(this Vector2 from, Vector2 to)
        {
            return Vector2.Distance(from, to);
        }

        /// <summary>
        /// Gets the squared distance to another vector (faster than DistanceTo)
        /// </summary>
        public static float DistanceSquaredTo(this Vector2 from, Vector2 to)
        {
            return Vector2.DistanceSquared(from, to);
        }

        /// <summary>
        /// Moves towards a target position by a maximum distance
        /// </summary>
        public static Vector2 MoveTowards(this Vector2 current, Vector2 target, float maxDistance)
        {
            Vector2 direction = target - current;
            float distance = direction.Length();

            if (distance <= maxDistance || distance < 0.0001f)
                return target;

            return current + direction / distance * maxDistance;
        }

        /// <summary>
        /// Checks if two vectors are approximately equal
        /// </summary>
        public static bool Approximately(this Vector2 a, Vector2 b, float epsilon = 0.0001f)
        {
            return (a - b).LengthSquared() < epsilon * epsilon;
        }

        /// <summary>
        /// Returns the component-wise minimum of two vectors
        /// </summary>
        public static Vector2 Min(this Vector2 a, Vector2 b)
        {
            return new Vector2(Math.Min(a.X, b.X), Math.Min(a.Y, b.Y));
        }

        /// <summary>
        /// Returns the component-wise maximum of two vectors
        /// </summary>
        public static Vector2 Max(this Vector2 a, Vector2 b)
        {
            return new Vector2(Math.Max(a.X, b.X), Math.Max(a.Y, b.Y));
        }

        /// <summary>
        /// Clamps each component of the vector between corresponding components of min and max
        /// </summary>
        public static Vector2 Clamp(this Vector2 vector, Vector2 min, Vector2 max)
        {
            return new Vector2(
                MathHelper.Clamp(vector.X, min.X, max.X),
                MathHelper.Clamp(vector.Y, min.Y, max.Y)
            );
        }

        /// <summary>
        /// Returns a vector with the sign of each component (-1, 0, or 1)
        /// </summary>
        public static Vector2 Sign(this Vector2 vector)
        {
            return new Vector2(MathHelper.Sign(vector.X), MathHelper.Sign(vector.Y));
        }

        /// <summary>
        /// Scales one vector by another component-wise
        /// </summary>
        public static Vector2 Scale(this Vector2 a, Vector2 b)
        {
            return new Vector2(a.X * b.X, a.Y * b.Y);
        }

        /// <summary>
        /// Returns the angle between two vectors in radians
        /// </summary>
        public static float AngleTo(this Vector2 from, Vector2 to)
        {
            Vector2 diff = to - from;
            return diff.ToAngle();
        }

        /// <summary>
        /// Returns the angle between two vectors (considering them as directions)
        /// </summary>
        public static float AngleBetween(this Vector2 from, Vector2 to)
        {
            from.Normalize();
            to.Normalize();

            float dot = Vector2.Dot(from, to);
            dot = MathHelper.Clamp(dot, -1f, 1f);

            return (float)Math.Acos(dot);
        }

        /// <summary>
        /// Checks if a point is inside a rectangle
        /// </summary>
        public static bool IsInsideRect(this Vector2 point, Rectangle rect)
        {
            return point.X >= rect.Left && point.X <= rect.Right &&
                   point.Y >= rect.Top && point.Y <= rect.Bottom;
        }

        /// <summary>
        /// Checks if a point is inside a circle
        /// </summary>
        public static bool IsInsideCircle(this Vector2 point, Vector2 center, float radius)
        {
            return Vector2.DistanceSquared(point, center) <= radius * radius;
        }

        /// <summary>
        /// Returns the closest point on a line segment to the given point
        /// </summary>
        public static Vector2 ClosestPointOnLineSegment(this Vector2 point, Vector2 lineStart, Vector2 lineEnd)
        {
            Vector2 lineDirection = lineEnd - lineStart;
            float lineLength = lineDirection.Length();

            if (lineLength < 0.0001f)
                return lineStart;

            lineDirection /= lineLength;

            Vector2 toPoint = point - lineStart;
            float projectionLength = Vector2.Dot(toPoint, lineDirection);

            projectionLength = MathHelper.Clamp(projectionLength, 0f, lineLength);

            return lineStart + lineDirection * projectionLength;
        }

        /// <summary>
        /// Converts world coordinates to grid coordinates
        /// </summary>
        public static Vector2 ToGridCoordinates(this Vector2 worldPosition, float tileSize = 32f)
        {
            return new Vector2(
                (float)Math.Floor(worldPosition.X / tileSize),
                (float)Math.Floor(worldPosition.Y / tileSize)
            );
        }

        /// <summary>
        /// Converts grid coordinates to world coordinates (centered in tile)
        /// </summary>
        public static Vector2 ToWorldCoordinates(this Vector2 gridPosition, float tileSize = 32f)
        {
            return new Vector2(
                gridPosition.X * tileSize + tileSize * 0.5f,
                gridPosition.Y * tileSize + tileSize * 0.5f
            );
        }

        /// <summary>
        /// Snaps a vector to a grid
        /// </summary>
        public static Vector2 SnapToGrid(this Vector2 vector, float gridSize)
        {
            return new Vector2(
                (float)Math.Round(vector.X / gridSize) * gridSize,
                (float)Math.Round(vector.Y / gridSize) * gridSize
            );
        }

        /// <summary>
        /// Creates a string representation with specified decimal places
        /// </summary>
        public static string ToString(this Vector2 vector, int decimalPlaces)
        {
            string format = "F" + decimalPlaces.ToString();
            return $"({vector.X.ToString(format)}, {vector.Y.ToString(format)})";
        }

        /// <summary>
        /// Bounces a vector off a surface with the given normal (with damping)
        /// </summary>
        public static Vector2 Bounce(this Vector2 vector, Vector2 normal, float bounciness = 1f)
        {
            return vector.Reflect(normal) * bounciness;
        }

        /// <summary>
        /// Gets the dominant axis (X or Y) of the vector
        /// </summary>
        public static Vector2 DominantAxis(this Vector2 vector)
        {
            if (Math.Abs(vector.X) > Math.Abs(vector.Y))
                return new Vector2(Math.Sign(vector.X), 0);
            else
                return new Vector2(0, Math.Sign(vector.Y));
        }
    }
}