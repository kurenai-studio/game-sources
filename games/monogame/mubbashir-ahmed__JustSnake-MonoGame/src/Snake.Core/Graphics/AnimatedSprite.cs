using Microsoft.Xna.Framework;
using System;

namespace Snake.Core.Graphics
{
    /// <summary>
    /// Represents a sprite with animation capabilities.
    /// </summary>
    public class AnimatedSprite : Sprite
    {
        /// <summary>
        /// The current frame of the animation.
        /// </summary>
        private int currentFrame;

        /// <summary>
        /// The elapsed time of the animation.
        /// </summary>
        private TimeSpan elapsed;

        /// <summary>
        /// The animation of the sprite.
        /// </summary>
        private Animation animation;

        /// <summary>
        /// Gets or sets the animation of the sprite.
        /// </summary>
        public Animation Animation
        {
            get => animation;
            set
            {
                animation = value;
                if (animation?.Frames != null && animation.Frames.Count > 0)
                {
                    Region = animation.Frames[0];
                    currentFrame = 0;
                    elapsed = TimeSpan.Zero;
                }
            }
        }

        /// <summary>
        /// Initializes a new instance of the AnimatedSprite class.
        /// </summary>
        public AnimatedSprite() { }

        /// <summary>
        /// Initializes a new instance of the AnimatedSprite class with an animation.
        /// </summary>
        /// <param name="animation">The animation to use.</param>
        public AnimatedSprite(Animation animation) 
        {
            Animation = animation;
        }

        /// <summary>
        /// Updates the animation of the sprite.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        public void Update(GameTime gameTime)
        {
            // Check if the animation has frames
            if (animation?.Frames == null || animation.Frames.Count == 0)
            {
                return;
            }

            // Update the elapsed time
            elapsed += gameTime.ElapsedGameTime;

            // Check if the elapsed time is greater than or equal to the delay
            if (elapsed >= animation.Delay)
            {
                // Subtract the delay from the elapsed time
                elapsed -= animation.Delay;
                currentFrame++;

                // Check if the current frame is greater than or equal to the number of frames
                if (currentFrame >= animation.Frames.Count)
                {
                    // Reset the current frame to 0
                    currentFrame = 0;
                }

                // Set the region to the current frame
                Region = animation.Frames[currentFrame];
            }
        }
    }
}
