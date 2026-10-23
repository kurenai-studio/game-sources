using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Audio;
using Escapeaway.Source.Objects;
using Escapeaway.Source.Graphics;
using Escapeaway.Source.Objects.Level;

namespace Escapeaway.Source.Objects.Level.Particles
{
    internal class DustParticle
    {
        private Character dust;
        private Point
            size = new Point(8, 8),
            sheetSize = new Point(16, 8);
        private int offsetToPlayer = -2; // How far in front of player to spawn

        private bool moveLeft;
        public int pixelsToMove = 1;

        private float
            timeExisted = 0f,
            timeToExist = 220f; // Frames to exist until deleted
        private bool draw = true;

        public DustParticle(Player player, bool moveLeft = true)
        {
            this.moveLeft = moveLeft;

            dust = new Character(
                Global.dustParticle,
                new Point(
                    player.X + (player.Width - size.X) + offsetToPlayer,
                    player.Y + (player.Height - size.Y)
                    ),
                sheetSize, size,
                Color.White);

            SetAnimations();
        }
        public DustParticle(int X, int Y, bool moveLeft = true)
        {
            this.moveLeft = moveLeft;

            dust = new Character(Global.dustParticle, new Point(X, Y), sheetSize, size, Color.White);

            SetAnimations();
        }

        public void SetAnimations()
        {
            // Animations

            dust.CreateAnimation("default", 0, 1);
        }

        public void Update(GameTime gameTime)
        {
            dust.PlayAnimation("default");
            dust.animSpeed = 100; // Slowwww

            // Move Left
            if (moveLeft) dust.X -= pixelsToMove;

            // Move Right
            else dust.X += pixelsToMove;

            timeExisted += gameTime.ElapsedGameTime.Milliseconds;

            // After Enough Time, Disappear
            if (timeExisted > timeToExist) draw = false;
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            if (draw) dust.Draw(spriteBatch);
        }
    }
}
