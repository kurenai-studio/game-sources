using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Snake.Core.Effects
{
    public class Particle
    {
        /// <summary>
        /// The random number generator.
        /// </summary>
        private readonly Random random = new Random();

        /// <summary>
        /// The position of the particle.
        /// </summary>
        public Vector2 Position { get; set; }
        
        /// <summary>
        /// The velocity of the particle.
        /// </summary>
        public Vector2 Velocity { get; set; }

        /// <summary>
        /// The color of the particle.
        /// </summary>
        public Color Color { get; set; }

        /// <summary>
        /// The lifetime of the particle.
        /// </summary>
        public float Lifetime { get; set; }
        
        /// <summary>
        /// The maximum lifetime of the particle.
        /// </summary>
        public float MaxLifetime { get; set; }

        /// <summary>
        /// The width of the particle.
        /// </summary>
        public int Width { get; set; } = 8;

        /// <summary>
        /// The height of the particle.
        /// </summary>
        public int Height { get; set; } = 8;

        /// <summary>
        /// The rectangle of the particle.
        /// </summary>
        /// <returns>The rectangle of the particle.</returns>
        public Rectangle Rectangle => new Rectangle((int)Position.X, (int)Position.Y, Width, Height);
    }
}
