using Microsoft.Xna.Framework;
using System.Collections.Generic;
using System.Linq;

namespace MonoGameLibrary.Utils
{
    public static class Vector2Extensions
    {
        public static Vector2 Normalize(this Vector2 vector)
        => Vector2.Normalize(vector);

        public static Vector2 Transform(this Vector2 vector, Matrix matrix)
        {
            return Vector2.Transform(vector, matrix);
        }

        public static IEnumerable<Vector2> Transform(this IEnumerable<Vector2> vectors, Matrix matrix)
        {
            foreach (var vector in vectors)
            {
                yield return Vector2.Transform(vector, matrix);
            }
        }

        public static Rectangle ToAABB(this IEnumerable<Vector2> vectors)
        {
            var minX = (int)vectors.Min(vector =>  vector.X);
            var minY = (int)vectors.Min(vector => vector.Y);
            var maxX = (int)vectors.Max(vector => vector.X);
            var maxY = (int)vectors.Max(vector => vector.Y);

            return new Rectangle(minX, minY, maxX - minX, maxY - minY);
        }
    }
}
