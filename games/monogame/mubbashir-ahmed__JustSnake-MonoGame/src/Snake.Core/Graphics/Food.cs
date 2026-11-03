using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Collisions;
using Snake.Core.Common;
using Snake.Core.Models;
using System;
using System.Collections.Generic;

namespace Snake.Core.Graphics
{
    /// <summary>
    /// Represents food that the snake can consume.
    /// </summary>
    public class Food
    {
        /// <summary>
        /// The half size factor.
        /// </summary>
        private const float HalfSizeFactor = 0.5f;

        /// <summary>
        /// The radius factor.
        /// </summary>
        private const float RadiusFactor = 0.25f;

        /// <summary>
        /// The maximum number of reposition retries.
        /// </summary>
        private const int MaxRepositionRetries = 50;

        /// <summary>
        /// The random number generator.
        /// </summary>
        private static readonly Random random = new Random();

        /// <summary>
        /// The list of available food types.
        /// </summary>
        private readonly List<FoodType> foodTypes;

        /// <summary>
        /// The currently active food type.
        /// </summary>
        private FoodType currentFoodType;

        /// <summary>
        /// The velocity of the food.
        /// </summary>
        private Vector2 velocity;
        
        /// <summary>
        /// The position of the food.
        /// </summary>
        private Vector2 position;

        /// <summary>
        /// Initializes a new instance of the Food class with multiple food types.
        /// </summary>
        /// <param name="foodTypes">The list of food types to randomly choose from.</param>
        /// <param name="tilemap">The tilemap to spawn the food on.</param>
        public Food(List<FoodType> foodTypes, Tilemap tilemap)
        {
            ArgumentNullException.ThrowIfNull(foodTypes);
            ArgumentNullException.ThrowIfNull(tilemap);

            if (foodTypes.Count == 0)
                throw new ArgumentException("Food types list cannot be empty.", nameof(foodTypes));

            // Initialize the food types list with the provided food types
            this.foodTypes = new List<FoodType>(foodTypes);

            // Select a random food type from the available food types
            SelectRandomFoodType();

            // Set the position of the food to a random valid position
            position = Helper.GetRandomVector2(tilemap);
        }

        /// <summary>
        /// Selects a random food type from the available food types.
        /// </summary>
        private void SelectRandomFoodType()
        {
            // Check if there are any food types
            if (foodTypes.Count > 0)
            {
                // Select a random food type from the available food types
                int randomIndex = random.Next(foodTypes.Count);

                // Set the current food type to the selected food type
                currentFoodType = foodTypes[randomIndex];
            }
        }

        /// <summary>
        /// Gets the points value for the currently active food.
        /// </summary>
        /// <returns>The points value for the current food.</returns>
        public int GetPoints()
        {
            return currentFoodType?.Points ?? 0;
        }

        /// <summary>
        /// Gets the position of the food.
        /// </summary>
        /// <returns>The position of the food.</returns>
        public Vector2 GetPosition()
        {
            // Return the position of the food
            return position;
        }

        /// <summary>
        /// Gets the collision bounds of the food.
        /// </summary>
        /// <returns>A circle representing the collision bounds.</returns>
        public Circle GetBounds()
        {
            // Calculate the radius of the food
            float radius = currentFoodType.Sprite.Width * RadiusFactor;

            // Return the collision bounds of the food
            return new Circle(
                (int)(position.X + currentFoodType.Sprite.Width * HalfSizeFactor),
                (int)(position.Y + currentFoodType.Sprite.Height * HalfSizeFactor),
                (int)radius
            );
        }

        /// <summary>
        /// Repositions the food to a random valid location and selects a random sprite.
        /// </summary>
        /// <param name="tilemap">The tilemap to find a position on.</param>
        /// <param name="snake">The snake to avoid overlapping with.</param>
        public void Reposition(Tilemap tilemap, Snake snake)
        {
            ArgumentNullException.ThrowIfNull(tilemap);
            ArgumentNullException.ThrowIfNull(snake);

            // Select a random food type when repositioning
            SelectRandomFoodType();

            // Initialize the retries counter
            int retries = 0;

            // Initialize the new position
            Vector2 newPosition;
            bool isValidPosition = false;

            do
            {
                newPosition = Helper.GetRandomVector2(tilemap);

                // Check if the new position is valid
                isValidPosition = !Helper.IsPositionOnAnySnakeSegment(newPosition, snake, currentFoodType.Sprite);

                // Increment the retries counter
                retries++;
            }
            while (!isValidPosition && retries < MaxRepositionRetries);

            // Set the position and velocity of the food
            position = newPosition;
            velocity = Vector2.Zero;
        }

        /// <summary>
        /// Updates the food's animation and position.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        public void Update(GameTime gameTime)
        {
            // Update the animation of the food
            currentFoodType.Sprite.Update(gameTime);

            // Update the position of the food
            position += velocity;
        }

        /// <summary>
        /// Draws the food to the sprite batch.
        /// </summary>
        /// <param name="spriteBatch">The sprite batch to draw to.</param>
        public void Draw(SpriteBatch spriteBatch)
        {
            // Set the position of the food and draw it
            currentFoodType.Sprite.Position = position;
            currentFoodType.Sprite.Draw(spriteBatch);
        }
    }
}
