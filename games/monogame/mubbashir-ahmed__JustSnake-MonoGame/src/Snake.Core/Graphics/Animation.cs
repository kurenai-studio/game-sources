using System;
using System.Collections.Generic;

namespace Snake.Core.Graphics
{
    /// <summary>
    /// Represents an animation sequence with frames and timing.
    /// </summary>
    public class Animation
    {
        /// <summary>
        /// The default delay between frames in milliseconds.
        /// </summary>
        private const int DefaultDelayMilliseconds = 100;

        /// <summary>
        /// Gets or sets the frames of the animation.
        /// </summary>
        public List<TextureRegion> Frames { get; set; } = new List<TextureRegion>();

        /// <summary>
        /// Gets or sets the delay between frames.
        /// </summary>
        public TimeSpan Delay { get; set; } = TimeSpan.FromMilliseconds(DefaultDelayMilliseconds);

        /// <summary>
        /// Initializes a new instance of the Animation class.
        /// </summary>
        public Animation() { }

        /// <summary>
        /// Initializes a new instance of the Animation class with frames and delay.
        /// </summary>
        /// <param name="frames">The frames of the animation.</param>
        /// <param name="delay">The delay between frames.</param>
        public Animation(List<TextureRegion> frames, TimeSpan delay)
        {
            ArgumentNullException.ThrowIfNull(frames);

            Frames = frames;
            Delay = delay;
        }
    }
}
