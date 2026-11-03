using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Effects;
using System;
using System.Collections.Generic;

namespace Snake.Core.Managers
{
    public class ParticleManager
    {
        private readonly Random random = new Random();
        private readonly Texture2D pixel;
        private readonly float speed = 100f;

        public List<Particle> Particles { get; set; }

        public ParticleManager(GraphicsDevice graphicsDevice)
        {
            Particles = new List<Particle>();

            pixel = new Texture2D(graphicsDevice, 1, 1);
            pixel.SetData([Color.White]);
        }

        public void Spawn(int count, Vector2 foodPosition)
        {
            for (int i = 0; i < count; i++)
            {
                float randomX = (float)random.NextDouble() * 2 - 1;
                float randomY = (float)random.NextDouble() * 2 - 1;

                Vector2 velocity = new Vector2(randomX, randomY);
                if (velocity != Vector2.Zero)
                {
                    velocity.Normalize();
                }

                Particles.Add(new Particle
                {
                    Position = foodPosition,
                    Velocity = velocity * speed,
                    Color = Color.White,
                    Lifetime = 0f,
                    MaxLifetime = 0.5f,
                });
            }
        }

        public void Update(GameTime gameTime) 
        {
            List<Particle> particlesToRemove = new List<Particle>();
            foreach(Particle particle in Particles)
            {
                float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;

                particle.Position += particle.Velocity * deltaTime;
                float fadeAlpha = 1.0f - (particle.Lifetime / particle.MaxLifetime);

                Color color = particle.Color;
                color.A = (byte)(fadeAlpha * 255);
                particle.Color = color;

                particle.Lifetime += deltaTime;

                if (particle.Lifetime >= particle.MaxLifetime)
                {
                    particlesToRemove.Add(particle);
                }
            }

            foreach(Particle particle in particlesToRemove)
            {
                Particles.Remove(particle);
            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            foreach(Particle particle in Particles)
            {
                spriteBatch.Draw(
                    pixel,
                    particle.Rectangle,
                    particle.Color
                );
            }
        }
    }
}
