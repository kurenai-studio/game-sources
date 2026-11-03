namespace Snake.Core.Graphics
{
    /// <summary>
    /// Represents a type of food with its sprite and point value.
    /// </summary>
    public class FoodType
    {
        /// <summary>
        /// Gets the animated sprite for this food type.
        /// </summary>
        public AnimatedSprite Sprite { get; }

        /// <summary>
        /// Gets the points awarded for consuming this food type.
        /// </summary>
        public int Points { get; }

        /// <summary>
        /// Initializes a new instance of the FoodType class.
        /// </summary>
        /// <param name="sprite">The animated sprite for this food type.</param>
        /// <param name="points">The points awarded for consuming this food type.</param>
        public FoodType(AnimatedSprite sprite, int points)
        {
            Sprite = sprite;
            Points = points;
        }
    }
}

