using Microsoft.Xna.Framework;

namespace Snake.Core.Graphics
{
    /// <summary>
    /// Represents a segment of the snake with position and movement information.
    /// </summary>
    public struct SnakeSegment
    {
        /// <summary>
        /// Gets or sets the current position of the segment.
        /// </summary>
        public Vector2 At;

        /// <summary>
        /// Gets or sets the target position of the segment.
        /// </summary>
        public Vector2 To;

        /// <summary>
        /// Gets or sets the direction vector of the segment.
        /// </summary>
        public Vector2 Direction;

        /// <summary>
        /// Gets the reverse direction of the segment.
        /// </summary>
        public Vector2 ReverseDirection => new Vector2(-Direction.X, -Direction.Y);
    }
}
